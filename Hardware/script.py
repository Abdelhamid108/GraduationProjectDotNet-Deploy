#!/usr/bin/env python3
"""
SAFE Raspberry Pi 4 + Camera Module 2 Sign Language Translator (minimal + resource-guarded)

Required logic:
- Capture frames from Pi Camera Module 2 (Picamera2)
- POST each frame to /api/SignLanguageTranslator -> append detected letters/words
- Beep on detection
- Sentence completion after SENTENCE_TIMEOUT with no new detection:
    Plan A: ONLY call /api/SignLanguageTranslator/text-to-audio
            If success -> play backend audio
            If fails -> Plan B
    Plan B: finalize using Groq LLM -> generate speech using gTTS -> play MP3
- Global idle timeout -> shutdown Pi (or exit in PI_TEST_MODE)

Resource safety:
- Low resolution & moderate JPEG quality
- Base loop uses low FPS; adaptive backoff when no detections
- Network error backoff
- Deletes temp audio files after playback
- Optional periodic resource logging (no extra deps)
"""
import sys
import base64
import io
import os
import time
import tempfile
import subprocess
from typing import Optional, Tuple, List

import requests
import urllib3
from PIL import Image
from picamera2 import Picamera2


# ======================
# CONFIG (safe defaults)
# ======================
BASE_URL = "https://ema2a.ddnsgeek.com"
TRANSLATE_URL = f"{BASE_URL}/api/SignLanguageTranslator"
TEXT_TO_AUDIO_URL = f"{BASE_URL}/api/SignLanguageTranslator/text-to-audio"

VERIFY_SSL = False
TIMEOUT = 15

# Timing
SENTENCE_TIMEOUT = 30
GLOBAL_IDLE_TIMEOUT = 60

# Safe capture settings
CAMERA_SIZE = (480, 360)     # lower than VGA -> lighter CPU/network
JPEG_QUALITY = 75            # reduce CPU + payload size

# Loop pacing (resource guarded)
BASE_FRAME_DELAY = 0.7       # ~1.4 fps
IDLE_BACKOFF_MAX = 2.0       # slows down when idle (no detections)
ERROR_BACKOFF_MAX = 3.0      # slows down on network errors

# Plan B (Groq finalize + gTTS)
api_key = "YOUR_API_KEY_HERE"
GROQ_BASE = "https://api.groq.com/openai/v1"
PLANB_LLM_MODEL = os.getenv("PLANB_LLM_MODEL", "llama-3.1-8b-instant")
GROQ_MODEL_FALLBACKS: List[str] = [
    PLANB_LLM_MODEL,
    "llama-3.3-70b-versatile",
    "allam-2-7b",
]

# Shutdown behavior
PI_TEST_MODE = os.getenv("PI_TEST_MODE", "0") == "1"

# Optional resource log (no extra deps)
RESOURCE_LOG_EVERY_SEC = 60  # set 0 to disable

if not VERIFY_SSL:
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

session = requests.Session()
session.verify = VERIFY_SSL
session.headers.update({"Accept": "application/json"})


# ======================
# Helpers
# ======================
def beep():
    print("\a", end="", flush=True)


def which(cmd: str) -> bool:
    from shutil import which as _which
    return _which(cmd) is not None


def safe_remove(path: Optional[str]):
    if not path:
        return
    try:
        if os.path.exists(path):
            os.remove(path)
    except Exception:
        pass


def play_wav(path: str):
    # Prefer aplay (alsa-utils). If missing, user can install it.
    if which("aplay"):
        subprocess.run(["aplay", "-q", path], check=False)
    elif which("ffplay"):
        subprocess.run(["ffplay", "-autoexit", "-nodisp", "-loglevel", "quiet", path], check=False)
    else:
        print("⚠ No WAV player found. Install: sudo apt install -y alsa-utils")


def play_mp3(path: str):
    # mpg123 is light and reliable
    if which("mpg123"):
        subprocess.run(["mpg123", "-q", path], check=False)
    elif which("ffplay"):
        subprocess.run(["ffplay", "-autoexit", "-nodisp", "-loglevel", "quiet", path], check=False)
    else:
        print("⚠ No MP3 player found. Install: sudo apt install -y mpg123")


def pcm_to_wav_file(pcm: bytes, rate: int) -> str:
    import wave
    out = tempfile.NamedTemporaryFile(delete=False, suffix=".wav").name
    with wave.open(out, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(rate)
        wf.writeframes(pcm)
    return out


def decode_audio_to_wav(audio_b64: str, sample_rate: int) -> Optional[str]:
    """
    backend may return base64 WAV or base64 raw PCM
    """
    try:
        audio_bytes = base64.b64decode(audio_b64)
    except Exception as e:
        print(f"⚠ Audio base64 decode failed: {e}")
        return None

    # WAV header?
    if len(audio_bytes) >= 12 and audio_bytes[0:4] == b"RIFF" and audio_bytes[8:12] == b"WAVE":
        out = tempfile.NamedTemporaryFile(delete=False, suffix=".wav").name
        with open(out, "wb") as f:
            f.write(audio_bytes)
        return out

    # assume raw PCM
    return pcm_to_wav_file(audio_bytes, sample_rate)


def shutdown_pi():
    print("\n🔌 Idle timeout reached. Exiting script...")
    time.sleep(1.0)
    sys.exit(0) # <--- This stops the script, but keeps the Pi on


def log_resources():
    """
    Lightweight resource logging (no extra deps):
    - CPU load averages
    - MemAvailable from /proc/meminfo
    """
    try:
        load1, load5, load15 = os.getloadavg()
    except Exception:
        load1 = load5 = load15 = -1

    mem_avail_kb = None
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemAvailable:"):
                    mem_avail_kb = int(line.split()[1])
                    break
    except Exception:
        pass

    if mem_avail_kb is not None:
        print(f"📊 Resource: load={load1:.2f},{load5:.2f},{load15:.2f}  MemAvailable={mem_avail_kb/1024:.0f} MB")
    else:
        print(f"📊 Resource: load={load1:.2f},{load5:.2f},{load15:.2f}")


# ======================
# API
# ======================
def post_json(url: str, payload: dict) -> Tuple[Optional[requests.Response], Optional[dict]]:
    try:
        r = session.post(url, json=payload, timeout=TIMEOUT)
    except requests.RequestException as e:
        print(f"⚠ Request error: {e}")
        return None, None
    try:
        js = r.json()
    except Exception:
        js = None
    return r, js


def translate_frame(img_b64: str) -> Tuple[Optional[str], bool]:
    """
    returns (translation, network_error)
    """
    r, js = post_json(TRANSLATE_URL, {"imageData": img_b64})
    if r is None:
        return None, True  # network error
    if not js:
        return None, True

    if js.get("success"):
        return (js.get("data") or {}).get("translation"), False

    # translate failures are not fatal; treat as no detection
    em = js.get("errorMessage")
    if em:
        print(f"⚠ Translate error ({js.get('statusCode', r.status_code)}): {em}")
    return None, False


def text_to_audio(sentence: str) -> Optional[str]:
    """
    PLAN A: Only this endpoint after sentence completion.
    """
    r, js = post_json(TEXT_TO_AUDIO_URL, {"sentence": sentence})

    # If server expects Sentence, retry once
    if js and not js.get("success") and isinstance(js.get("errorMessage"), str):
        if "Missing" in js["errorMessage"] or "Sentence" in js["errorMessage"]:
            r, js = post_json(TEXT_TO_AUDIO_URL, {"Sentence": sentence})

    if js and js.get("success"):
        try:
            data = js["data"]
            wav = decode_audio_to_wav(data["audioData"], int(data.get("sampleRate", 24000)))
            return wav
        except Exception as e:
            print(f"⚠ text-to-audio parse/decode error: {e}")
            return None

    if js and js.get("errorMessage"):
        status = r.status_code if r else "?"
        print(f"❌ text-to-audio error ({status}): {js['errorMessage']}")
    elif r is not None:
        print(f"❌ text-to-audio error ({r.status_code}): {r.text[:200]}")
    else:
        print("❌ text-to-audio error (?): no response")

    return None


# ======================
# PLAN B: Groq finalize + gTTS
# ======================
def groq_finalize(sentence: str) -> Optional[str]:
    if not GROQ_API_KEY:
        print("ℹ GROQ_API_KEY not set — Plan-B finalize cannot run.")
        return None

    messages = [
        {"role": "system", "content": "أنت مدقق لغوي عربي محترف. أرجِع الجملة المصححة فقط بدون أي شرح."},
        {
            "role": "user",
            "content": (
                "أعِد كتابة الجملة العربية التالية بإضافة المسافات الصحيحة بين الكلمات، "
                "وتصحيح الأخطاء الإملائية البسيطة فقط. أعد الجملة المصححة فقط بدون أي شرح.\n\n"
                f"النص: {sentence}"
            ),
        },
    ]

    for model in GROQ_MODEL_FALLBACKS:
        try:
            r = requests.post(
                f"{GROQ_BASE}/chat/completions",
                headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
                json={"model": model, "messages": messages, "temperature": 0.2, "max_tokens": 128},
                timeout=TIMEOUT,
            )
            j = r.json()

            if r.status_code == 200 and j.get("choices"):
                return j["choices"][0]["message"]["content"].strip()

            err = j.get("error") or {}
            code = str(err.get("code", "")).lower()
            if code in ("model_decommissioned", "model_not_found"):
                print(f"ℹ Groq model '{model}' unavailable → trying next model.")
                continue

            msg = err.get("message") or str(j)[:200]
            print(f"❌ Plan-B LLM error ({r.status_code}) [{model}]: {msg}")
            return None

        except Exception as e:
            print(f"⚠ Groq request failed [{model}]: {e}")
            continue

    return None


def gtts_speak(text: str) -> bool:
    try:
        from gtts import gTTS
    except Exception:
        print("⚠ gTTS not installed. Run: python3 -m pip install gTTS")
        return False

    mp3 = None
    try:
        mp3 = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3").name
        gTTS(text=text, lang="ar").save(mp3)
        play_mp3(mp3)
        return True
    except Exception as e:
        print(f"⚠ gTTS error: {e}")
        return False
    finally:
        safe_remove(mp3)


# ======================
# Camera (Picamera2)
# ======================
def init_camera() -> Picamera2:
    cam = Picamera2()
    cfg = cam.create_video_configuration(main={"size": CAMERA_SIZE, "format": "RGB888"})
    cam.configure(cfg)
    cam.start()
    time.sleep(1.0)
    return cam


def capture_jpeg_b64(cam: Picamera2) -> str:
    frame = cam.capture_array()
    img = Image.fromarray(frame)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=JPEG_QUALITY)
    jpg = buf.getvalue()
    return "data:image/jpeg;base64," + base64.b64encode(jpg).decode("ascii")


# ======================
# MAIN LOOP
# ======================
def main():
    print("🚀 Sign Language Translator Started (Pi SAFE)")
    print(f"🌐 Server: {BASE_URL}")
    if PI_TEST_MODE:
        print("🧪 PI_TEST_MODE=1 — no shutdown on idle (safe testing).")

    if not GROQ_API_KEY:
        print("ℹ GROQ_API_KEY not set — Plan-B will not correct sentence (may speak letters).")

    cam = init_camera()

    sentence = ""
    last_detection: Optional[float] = None
    last_activity = time.time()

    idle_backoff = 0.0
    error_backoff = 0.0

    last_resource_log = time.time()

    try:
        while True:
            # Optional periodic resource log
            if RESOURCE_LOG_EVERY_SEC > 0 and (time.time() - last_resource_log) >= RESOURCE_LOG_EVERY_SEC:
                log_resources()
                last_resource_log = time.time()

            img_b64 = capture_jpeg_b64(cam)

            word, net_err = translate_frame(img_b64)
            if net_err:
                # network issue -> slow down a bit
                error_backoff = min(ERROR_BACKOFF_MAX, error_backoff + 0.5)
            else:
                # network OK -> decay error backoff
                error_backoff = max(0.0, error_backoff - 0.2)

            if word and "no sign" not in word.lower():
                sentence += word
                last_detection = time.time()
                last_activity = last_detection
                idle_backoff = 0.0  # reset idle backoff on detection
                print(f"✋ Detected: {word}")
                print(f"📜 Sentence: {sentence}")
                beep()
            else:
                # no detection -> slowly increase idle backoff up to max
                idle_backoff = min(IDLE_BACKOFF_MAX, idle_backoff + 0.1)

            # Sentence completed?
            if sentence and last_detection and (time.time() - last_detection) > SENTENCE_TIMEOUT:
                print("🧠 Sentence completed")

                # PLAN A: ONLY text-to-audio
                print("🧠 Finalizing & generating audio (combined endpoint if available)...")
                wav = text_to_audio(sentence)
                if wav:
                    play_wav(wav)
                    safe_remove(wav)
                    print("✅ Audio played (backend)")
                else:
                    # PLAN B: Groq finalize + gTTS
                    print("🧠 Finalizing sentence...")
                    final_sentence = groq_finalize(sentence)
                    if final_sentence:
                        print("✅ Plan-B LLM finalize succeeded")
                    else:
                        print("⚠ Using offline sentence correction")
                        final_sentence = " ".join(sentence)

                    print(f"📜 Final sentence: {final_sentence}")
                    print("🔊 Generating audio (Plan-B gTTS)...")
                    if gtts_speak(final_sentence):
                        print("✅ Audio played (Plan-B gTTS)")
                    else:
                        print("🔇 Could not play audio (Plan-B gTTS failed).")

                sentence = ""
                last_detection = None
                print("✋ Ready for next sentence...")

            # Global idle shutdown?
            if (time.time() - last_activity) > GLOBAL_IDLE_TIMEOUT:
                shutdown_pi()
                return

            # Safe pacing: base delay + idle backoff + error backoff
            time.sleep(BASE_FRAME_DELAY + idle_backoff + error_backoff)

    finally:
        try:
            cam.stop()
        except Exception:
            pass


if __name__ == "__main__":
    main()
