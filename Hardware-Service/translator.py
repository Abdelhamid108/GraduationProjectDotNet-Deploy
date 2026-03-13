#!/usr/bin/env python3


from __future__ import annotations

import base64
import io
import os
import time
import tempfile
import subprocess
import sys
import math
import struct
import wave
from typing import Optional, Tuple, List

import requests
import urllib3
from picamera2 import Picamera2

# ======================
# CONFIG
# ======================
BASE_URL = os.getenv("SIGN_BASE_URL", "https://ema2a.mooo.com").rstrip("/")

TRANSLATE_URL = f"{BASE_URL}/api/signlanguagetranslator"
FINALIZE_URL = f"{BASE_URL}/api/signlanguagetranslator/finalize-sentence?client=hardware"
HARDWARE_TTS_URL = f"{BASE_URL}/api/signlanguagetranslator/text-to-speech/hardware?format=base64"
LOGIN_URL = f"{BASE_URL}/api/auth/login-user"

VERIFY_SSL = os.getenv("VERIFY_SSL", "0") == "1"
TIMEOUT = int(os.getenv("HTTP_TIMEOUT", "50"))

SENTENCE_TIMEOUT = float(os.getenv("SENTENCE_TIMEOUT", "90"))
GLOBAL_IDLE_TIMEOUT = float(os.getenv("GLOBAL_IDLE_TIMEOUT", "320"))

CAMERA_WIDTH = int(os.getenv("CAM_W", "640"))
CAMERA_HEIGHT = int(os.getenv("CAM_H", "480"))
JPEG_QUALITY = int(os.getenv("JPEG_QUALITY", "80"))

BASE_FRAME_DELAY = float(os.getenv("BASE_FRAME_DELAY", "0.085"))
IDLE_BACKOFF_MAX = float(os.getenv("IDLE_BACKOFF_MAX", "1.0"))
ERROR_BACKOFF_MAX = float(os.getenv("ERROR_BACKOFF_MAX", "2.0"))

AUDIO_RETRIES = int(os.getenv("AUDIO_RETRIES", "2"))

USERNAME = os.getenv("SIGN_API_USERNAME", "").strip()
PASSWORD = os.getenv("SIGN_API_PASSWORD", "").strip()

GROQ_API_KEY = "GROQ_API_KEY"  # Must be set in environment for Groq usage
GROQ_BASE = os.getenv("GROQ_BASE", "https://api.groq.com/openai/v1").rstrip("/")
PLANB_LLM_MODEL = os.getenv("PLANB_LLM_MODEL", "llama-3.3-70b-versatile")
GROQ_MODEL_FALLBACKS: List[str] = [
    PLANB_LLM_MODEL,
    "llama-3.1-8b-instant",
    "allam-2-7b",
]

STABLE_FRAMES = int(os.getenv("STABLE_FRAMES", "1"))
RESET_NO_SIGN_FRAMES = int(os.getenv("RESET_NO_SIGN_FRAMES", "1"))
SAME_LETTER_COOLDOWN = float(os.getenv("SAME_LETTER_COOLDOWN", "0.6"))

BEEP_MIN_INTERVAL = float(os.getenv("BEEP_MIN_INTERVAL", "0.18"))
BEEP_FREQ_HZ = float(os.getenv("BEEP_FREQ_HZ", "1150"))
BEEP_DURATION_SEC = float(os.getenv("BEEP_DURATION_SEC", "0.14"))

if not VERIFY_SSL:
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

session = requests.Session()
session.verify = VERIFY_SSL
session.headers.update({"Accept": "application/json"})

# ======================
# Helpers
# ======================
def safe_remove(path: Optional[str]):
    if path and os.path.exists(path):
        try:
            os.remove(path)
        except Exception:
            pass

def exit_script():
    print("\n🛑 Idle timeout reached. Exiting script...")
    sys.exit(0)

def play_audio_file(path: str):
    if path.endswith(".wav"):
        subprocess.run(["aplay", "-q", "-D", "plughw:2,0", path], check=False)
    elif path.endswith(".mp3"):
        subprocess.run(["mpg123", "-q", path], check=False)

def beep():
    sr = 22050
    n = int(sr * BEEP_DURATION_SEC)
    amp = 0.95
    path = tempfile.NamedTemporaryFile(delete=False, suffix=".wav").name
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        for i in range(n):
            sample = int(amp * 32767 * math.sin(2 * math.pi * BEEP_FREQ_HZ * (i / sr)))
            wf.writeframes(struct.pack("<h", sample))
    subprocess.run(["aplay", "-q", "-D", "plughw:2,0", path], check=False)
    safe_remove(path)

# ======================
# Audio decode helpers
# ======================
def decode_audio_to_file(audio_b64: str) -> Optional[str]:
    try:
        audio_bytes = base64.b64decode(audio_b64)
    except Exception:
        return None
    out = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3").name
    with open(out, "wb") as f:
        f.write(audio_bytes)
    return out

# ======================
# Optional Auth
# ======================
ACCESS_TOKEN: Optional[str] = None

def have_credentials() -> bool:
    return bool(USERNAME and PASSWORD)

def login_and_get_token() -> Optional[str]:
    global ACCESS_TOKEN
    if not have_credentials():
        return None
    try:
        r = session.post(LOGIN_URL, json={"userName": USERNAME, "password": PASSWORD}, timeout=TIMEOUT)
        js = None
        try:
            js = r.json()
        except Exception:
            js = None
        if not r.ok or not js or not js.get("success", False):
            msg = (js or {}).get("errorMessage") or r.text[:200]
            print(f"❌ Login failed ({r.status_code}): {msg}")
            return None
        ACCESS_TOKEN = js["data"]["accessToken"]
        return ACCESS_TOKEN
    except Exception as e:
        print(f"❌ Login error: {e}")
        return None

def post_json(url: str, payload: dict, need_auth: bool) -> Tuple[Optional[requests.Response], Optional[dict]]:
    global ACCESS_TOKEN
    for attempt in range(2):
        headers = {"Content-Type": "application/json"}
        if need_auth:
            if ACCESS_TOKEN is None:
                ACCESS_TOKEN = login_and_get_token()
            if ACCESS_TOKEN:
                headers["Authorization"] = f"Bearer {ACCESS_TOKEN}"
        try:
            r = session.post(url, json=payload, headers=headers, timeout=TIMEOUT)
        except Exception:
            return None, None
        try:
            js = r.json()
        except Exception:
            js = None
        if need_auth and r.status_code == 401 and attempt == 0 and have_credentials():
            ACCESS_TOKEN = None
            continue
        return r, js
    return None, None

# ======================
# API
# ======================
def translate_frame(img_b64: str) -> Tuple[Optional[str], bool]:
    r, js = post_json(TRANSLATE_URL, {"imageData": img_b64}, need_auth=False)
    if r is None or js is None:
        return None, True
    if js.get("success"):
        return (js.get("data") or {}).get("translation"), False
    return None, False

def finalize_sentence_backend(sentence: str) -> Optional[str]:
   
    need_auth = have_credentials()
    r, js = post_json(FINALIZE_URL, {"Sentence": sentence}, need_auth=need_auth)
    if js and js.get("success"):
        return js.get("data")
    if r is None:
        print("❌ Finalize: request failed (timeout/network).")
    elif js and js.get("errorMessage"):
        print(f"❌ Finalize error ({r.status_code}): {js.get('errorMessage')}")
    else:
        print(f"❌ Finalize error ({r.status_code}): {r.text[:200]}")
    return None

def hardware_tts_backend(text: str) -> Optional[str]:
    for attempt in range(1, AUDIO_RETRIES + 1):
        r, js = post_json(HARDWARE_TTS_URL, {"text": text}, need_auth=have_credentials())
        if js and js.get("success"):
            try:
                data = js["data"]
                return decode_audio_to_file(data["audioData"])
            except Exception:
                return None
    return None

def groq_finalize(sentence: str) -> Optional[str]:
    if not GROQ_API_KEY:
        return None
    messages = [
        {
            "role": "system",
            "content": (
                "أنت نظام متخصص في إعادة بناء الجمل العربية من مخرجات التعرف على لغة الإشارة حرفًا بحرف."
                "\nقد يحتوي النص على: حروف مكررة، ناقصة، أو مسافات خاطئة"
                "\nمهمتك: إعادة بناء الجملة العربية الصحيحة، إصلاح المسافات، إزالة التكرارات، تصحيح الأخطاء البسيطة"
                "\nأرجع الجملة المصححة فقط بدون شرح أو علامات اقتباس"
            )
        },
        {"role": "user", "content": sentence},
    ]
    for model in GROQ_MODEL_FALLBACKS:
        try:
            r = requests.post(
                f"{GROQ_BASE}/chat/completions",
                headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
                json={"model": model, "messages": messages, "temperature": 0.2, "max_tokens": 128},
                timeout=8,
            )
            if r.status_code == 200:
                j = r.json()
                return j["choices"][0]["message"]["content"].strip()
        except Exception:
            continue
    return None

def gtts_speak(text: str) -> bool:
    try:
        from gtts import gTTS
        mp3 = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3").name
        gTTS(text=text, lang="ar").save(mp3)
        play_audio_file(mp3)
        safe_remove(mp3)
        return True
    except Exception:
        return False

# ======================
# Camera
# ======================
def init_camera() -> Picamera2:
    cam = Picamera2()
    config = cam.create_still_configuration(main={"size": (CAMERA_WIDTH, CAMERA_HEIGHT), "format": "RGB888"})
    cam.configure(config)
    try:
        cam.options["quality"] = JPEG_QUALITY
    except Exception:
        pass
    cam.start()
    time.sleep(0.3)
    return cam

def capture_jpeg_fast(cam: Picamera2) -> str:
    stream = io.BytesIO()
    cam.capture_file(stream, format="jpeg")
    return "data:image/jpeg;base64," + base64.b64encode(stream.getvalue()).decode("ascii")

# ======================
# MAIN LOOP
# ======================
def main():
    print("🚀 FAST Sign Translator Started (Pi 4 Optimized, PlanA removed)")
    cam = init_camera()

    sentence = ""
    last_detection: Optional[float] = None
    last_activity = time.time()
    current_delay = BASE_FRAME_DELAY

    stable_word: Optional[str] = None
    stable_count = 0
    no_sign_count = 0

    last_committed_word: Optional[str] = None
    last_commit_ts = 0.0

    try:
        while True:
            img_b64 = capture_jpeg_fast(cam)
            word, net_err = translate_frame(img_b64)

            if net_err:
                current_delay = min(ERROR_BACKOFF_MAX, current_delay + 0.5)
                stable_word = None
                stable_count = 0
            else:
                valid = bool(word and isinstance(word, str) and ("no sign" not in word.lower()))
                if valid:
                    no_sign_count = 0
                    if stable_word == word:
                        stable_count += 1
                    else:
                        stable_word = word
                        stable_count = 1
                    if stable_count >= STABLE_FRAMES:
                        now = time.time()
                        if (word != last_committed_word) or ((now - last_commit_ts) >= SAME_LETTER_COOLDOWN):
                            sentence += word
                            last_detection = now
                            last_activity = now
                            current_delay = BASE_FRAME_DELAY
                            print(f"✋ Detected: {word} | Sentence: {sentence}")
                            beep()
                            last_committed_word = word
                            last_commit_ts = now
                        stable_word = None
                        stable_count = 0
                else:
                    stable_word = None
                    stable_count = 0
                    no_sign_count += 1
                    if no_sign_count >= RESET_NO_SIGN_FRAMES:
                        last_committed_word = None
                    current_delay = min(IDLE_BACKOFF_MAX, current_delay + 0.05)

            if sentence and last_detection and (time.time() - last_detection) > SENTENCE_TIMEOUT:
                print(f"🧠 Sentence finished: {sentence}")
                last_activity = time.time()

                final_s = finalize_sentence_backend(sentence)
                if final_s:
                    print(f"🧠 Finalized (backend): {final_s}")
                else:
                    final_s = groq_finalize(sentence)
                    if final_s:
                        print(f"🧠 Finalized (Groq): {final_s}")
                    else:
                        final_s = sentence
                        print(f"🧠 Finalized (fallback): {final_s}")

                wav = hardware_tts_backend(final_s)
                if wav:
                    print("🔊 Playing Audio (Hardware TTS)")
                    play_audio_file(wav)
                    safe_remove(wav)
                else:
                    print("🔊 Playing Audio (gTTS fallback)")
                    gtts_speak(final_s)

                sentence = ""
                last_detection = None
                stable_word = None
                stable_count = 0
                no_sign_count = 0
                last_committed_word = None
                last_commit_ts = 0.0
                last_activity = time.time()
                current_delay = BASE_FRAME_DELAY
                print("\n👂 Listening for new sentence...")

            if (time.time() - last_activity) > GLOBAL_IDLE_TIMEOUT:
                exit_script()

            time.sleep(current_delay)

    except KeyboardInterrupt:
        print("\n👋 Exiting...")
    finally:
        try:
            cam.stop()
        except Exception:
            pass

if __name__ == "__main__":
    main()
