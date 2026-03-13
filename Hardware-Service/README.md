# Sign Language to Speech Translator (Raspberry Pi)

A real-time **Sign Language Translation System** built using:

- Raspberry Pi 4
- Raspberry Pi Camera Module 2
- AI Sign Recognition API
- Arabic Language Reconstruction
- Text-to-Speech Audio Output

The system translates **hand gestures into spoken Arabic sentences**.

---

# 📌 Project Overview

Communication barriers exist between deaf or hard-of-hearing individuals and people who do not understand sign language.

This project provides a **portable AI-powered translator** that:

1. Detects sign language gestures using a camera
2. Converts gestures into letters
3. Builds words and sentences
4. Corrects the sentence using AI
5. Converts the final sentence into **spoken Arabic audio**

The system runs **entirely on a Raspberry Pi device**.

---

# 🧠 System Architecture

```
Camera → Image Capture → API Recognition
           ↓
     Letter Detection
           ↓
     Sentence Builder
           ↓
    AI Sentence Correction
           ↓
       Text To Speech
           ↓
        Audio Output
```

---

# ⚙ Hardware Requirements

| Component | Description |
|--------|-------------|
| Raspberry Pi 4 | Main computing device |
| Camera Module 2 | Gesture capture |
| MicroSD Card | Operating system |
| Speaker | Audio output |
| Power Supply | 5V 3A recommended |

---

# 💻 Software Requirements

- Raspberry Pi OS
- Python 3.9+
- picamera2
- requests
- gTTS
- mpg123
- ALSA audio utilities

Install dependencies:

```bash
sudo apt update
sudo apt install python3-picamera2 mpg123 alsa-utils
pip install requests gTTS
```

---

# 🚀 How the System Works

## 1️⃣ Camera Capture

The Raspberry Pi camera continuously captures frames.

```python
cam.capture_file(stream, format="jpeg")
```

Images are converted to Base64 and sent to the backend API.

---

## 2️⃣ Gesture Recognition

Each frame is sent to:

```
/api/signlanguagetranslator
```

The API returns a detected letter.

Example:

```
Detected: A
Detected: B
Detected: C
```

---

## 3️⃣ Sentence Construction

Detected letters are appended:

```
Sentence = "مرحبا"
```

The system waits until **no gesture is detected for a period**.

```
SENTENCE_TIMEOUT = 90 seconds
```

Then the sentence is finalized.

---

## 4️⃣ Sentence Correction (AI)

The system sends the raw sentence to:

```
/api/signlanguagetranslator/finalize-sentence
```

If backend fails, it uses:

```
Groq LLM
Model: llama-3.3-70b
```

Example correction:

```
Input: مرحببا كيف ححاللك
Output: مرحبا كيف حالك
```

---

## 5️⃣ Text-to-Speech

The corrected sentence is converted into speech.

Primary method:

```
/api/signlanguagetranslator/text-to-speech/hardware
```

Fallback:

```
gTTS
```

Audio is played using:

```
aplay
```

or

```
mpg123
```

---

# 🔊 Audio Feedback

A short **beep sound** is played whenever a gesture is detected.

This confirms to the user that the system recognized a sign.

---

# 🔁 Automatic Startup (systemd Service)

The system runs automatically when Raspberry Pi boots.

Service file:

```
/etc/systemd/system/sign-translator.service
```

Key settings:

```
ExecStart=/usr/bin/python3 translator.py
ExecStartPre=/bin/sleep 20
```

This ensures:

- Camera initializes
- Network is available
- Audio device is ready

---

# 👤 How the User Uses the System

1️⃣ Power on Raspberry Pi  
2️⃣ Camera starts automatically  
3️⃣ User performs sign language gestures  
4️⃣ Each gesture is recognized  
5️⃣ Sentence is built automatically  
6️⃣ After pause → sentence is finalized  
7️⃣ Audio is played through speaker

The user hears the **spoken translation**.

---

# 🧪 Example Usage

User signs:

```
مرحبا كيف حالك
```

System output:

```
Detected: م
Detected: ر
Detected: ح
Detected: ب
Detected: ا
```

Final output:

```
🔊 "مرحبا كيف حالك"
```

---

# 🧩 Key Configuration Parameters

| Parameter | Purpose |
|--------|--------|
| SENTENCE_TIMEOUT | Wait time before sentence finalize |
| GLOBAL_IDLE_TIMEOUT | Script exit timeout |
| BASE_FRAME_DELAY | Frame processing speed |
| STABLE_FRAMES | Frames required to confirm a gesture |

---

# 📡 Backend APIs Used

### Gesture Recognition

```
POST /api/signlanguagetranslator
```

### Sentence Finalization

```
POST /api/signlanguagetranslator/finalize-sentence
```

### Hardware Text To Speech

```
POST /api/signlanguagetranslator/text-to-speech/hardware
```

---

# 🔐 Authentication

Optional API authentication is supported.

```
/api/auth/login-user
```

If credentials are provided, a **JWT access token** is used.

---

# 🛠 Debugging

Check service logs:

```
journalctl -u sign-translator.service -f
```

Run script manually:

```
python3 translator.py
```

Check audio devices:

```
aplay -l
```

---

# Auto Start Using Systemd Service

The translator automatically starts when the Raspberry Pi boots using a systemd service.

Service file:


sign-translator.service


Service responsibilities:

- Start translator automatically after boot
- Wait for network and audio initialization
- Run the Python translation script in the background
- Log execution output to system logs

---

# Service Installation

Copy the service file:


sudo cp sign-translator.service /etc/systemd/system/


Reload services:


sudo systemctl daemon-reload


Enable the service:


sudo systemctl enable sign-translator.service


Start the service:


sudo systemctl start sign-translator.service


Check status:


sudo systemctl status sign-translator.service


View logs:


journalctl -u sign-translator.service -f


---

# How to Use the System

1. Power on the Raspberry Pi
2. Wait for the system to boot
3. The translator service will start automatically
4. Stand in front of the camera
5. Perform sign language gestures
6. The system detects letters and constructs a sentence
7. After a short pause, the sentence is spoken through the speaker

---

# Idle Behavior

If no interaction occurs for a configured time period, the script exits automatically to conserve resources.

---


# 🚀 Future Improvements

## 1️⃣ Text to Sign Language (Reverse Translation)

Future versions could allow:

```
Text → Sign Language Animation
```

Example:

User types:

```
مرحبا كيف حالك
```

System shows **animated hand gestures on a screen**.

Possible implementation:

- 3D hand animation
- Pre-recorded gesture videos
- AI pose generation

---

## 2️⃣ Offline AI Recognition

Currently gesture recognition uses a backend API.

Future improvement:

- Run **local AI model**
- Reduce latency
- Work without internet

---

## 3️⃣ Mobile App Integration

Allow translation via:

- Mobile camera
- Bluetooth connection to Raspberry Pi

---

## 4️⃣ Multi-Language Support

Expand translation to:

- English
- French
- Sign Language variants

---

# 📚 Academic Contribution

This system demonstrates the integration of:

- Embedded systems
- Computer vision
- Artificial intelligence
- Natural language processing
- Human-computer interaction

The project aims to **reduce communication barriers for deaf individuals**.

---

# 👨‍💻 Author

Graduation Project Team

Hardware Module Developer:
Ahmed Moustafa Kandil
