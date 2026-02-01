# Arabic Text-to-Speech (TTS) API Documentation

## Overview

The Arabic TTS API converts Arabic text to natural-sounding speech audio using AI models. The service returns MP3 audio files that can be played directly in the browser or downloaded.

## Base URL

| Environment | URL |
|------------|-----|
| Production (via nginx) | `https://ema2a.ddnsgeek.com/tts/` |
| Direct access | `http://localhost:8000/` |
| Docker Compose | `http://tts-service:8000/` |

## Interactive Documentation

When the service is running, you can access interactive API documentation at:
- **Swagger UI**: `/tts/docs` (or `/docs` for direct access)
- **ReDoc**: `/tts/redoc` (or `/redoc` for direct access)

---

## Endpoints

### 1. Convert Text to Speech (POST)

**Endpoint:** `POST /tts`

Convert Arabic text to speech audio. This is the recommended endpoint for frontend applications.

#### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
    "text": "مرحبا بكم في خدمة تحويل النص إلى كلام",
    "speaker": 1,
    "pace": 1.0,
    "volume": 0.9
}
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `text` | string | ✅ Yes | - | Arabic text to convert (1-5000 characters) |
| `speaker` | integer | No | 1 | Voice style ID (0-3) |
| `pace` | float | No | 1.0 | Speech speed (0.1-2.0). 1.0 = normal |
| `volume` | float | No | 0.9 | Audio volume (0-1) |

#### Response

- **Success (200):** MP3 audio file (`audio/mpeg`)
- **Validation Error (422):** Invalid parameters
- **Server Error (500):** TTS generation failed

---

### 2. Convert Text to Speech (GET)

**Endpoint:** `GET /tts`

Alternative endpoint using query parameters. Useful for simple requests or HTML audio elements.

#### Request

```
GET /tts?text=مرحبا&speaker=1&pace=1.0&volume=0.9
```

#### Parameters

Same as POST endpoint, but passed as query parameters.

#### Example

```html
<audio controls>
    <source src="/tts/tts?text=مرحبا بكم" type="audio/mpeg">
</audio>
```

---

### 3. Health Check

**Endpoint:** `GET /health`

Check if the service is running.

#### Response

```json
{
    "status": "healthy",
    "service": "arabic-tts"
}
```

---

### 4. List Speakers

**Endpoint:** `GET /speakers`

Get information about available speaker voices.

#### Response

```json
{
    "speakers": [
        {"id": 0, "description": "Speaker 0 - Male voice style 1"},
        {"id": 1, "description": "Speaker 1 - Male voice style 2 (default)"},
        {"id": 2, "description": "Speaker 2 - Male voice style 3"},
        {"id": 3, "description": "Speaker 3 - Male voice style 4"}
    ],
    "default": 1
}
```

---

## Frontend Integration

### JavaScript - Play Audio

```javascript
async function playArabicTTS(text, options = {}) {
    const { speaker = 1, pace = 1.0, volume = 0.9 } = options;
    
    try {
        const response = await fetch('/tts/tts', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ text, speaker, pace, volume })
        });
        
        if (!response.ok) {
            throw new Error(`TTS failed: ${response.status}`);
        }
        
        const audioBlob = await response.blob();
        const audioUrl = URL.createObjectURL(audioBlob);
        const audio = new Audio(audioUrl);
        
        audio.onended = () => URL.revokeObjectURL(audioUrl);
        await audio.play();
        
        return audio;
    } catch (error) {
        console.error('TTS Error:', error);
        throw error;
    }
}

// Usage
playArabicTTS('مرحبا بكم في تطبيقنا');
playArabicTTS('مرحبا', { speaker: 2, pace: 0.8 });
```

### JavaScript - Download MP3

```javascript
async function downloadTTS(text, filename = 'speech.mp3', options = {}) {
    const { speaker = 1, pace = 1.0, volume = 0.9 } = options;
    
    const response = await fetch('/tts/tts', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text, speaker, pace, volume })
    });
    
    if (!response.ok) {
        throw new Error(`TTS failed: ${response.status}`);
    }
    
    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    
    URL.revokeObjectURL(url);
}

// Usage
downloadTTS('مرحبا بكم', 'greeting.mp3');
```

### HTML Audio Element

```html
<!-- Simple audio player -->
<audio id="tts-audio" controls></audio>

<script>
async function speak(text) {
    const response = await fetch('/tts/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text })
    });
    const blob = await response.blob();
    document.getElementById('tts-audio').src = URL.createObjectURL(blob);
}
</script>

<button onclick="speak('مرحبا بكم')">تشغيل</button>
```

### React Component

```jsx
import { useState, useRef } from 'react';

function ArabicTTS() {
    const [text, setText] = useState('');
    const [loading, setLoading] = useState(false);
    const [speaker, setSpeaker] = useState(1);
    const audioRef = useRef(null);
    
    const speak = async () => {
        if (!text.trim()) return;
        
        setLoading(true);
        try {
            const response = await fetch('/tts/tts', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text, speaker })
            });
            
            const blob = await response.blob();
            const url = URL.createObjectURL(blob);
            
            if (audioRef.current) {
                audioRef.current.src = url;
                await audioRef.current.play();
            }
        } catch (error) {
            console.error('TTS Error:', error);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div>
            <textarea
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder="أدخل النص العربي هنا"
                dir="rtl"
            />
            <select value={speaker} onChange={(e) => setSpeaker(Number(e.target.value))}>
                <option value={0}>صوت 1</option>
                <option value={1}>صوت 2 (افتراضي)</option>
                <option value={2}>صوت 3</option>
                <option value={3}>صوت 4</option>
            </select>
            <button onClick={speak} disabled={loading}>
                {loading ? 'جاري التحويل...' : 'تشغيل'}
            </button>
            <audio ref={audioRef} controls />
        </div>
    );
}
```

### Vue.js Component

```vue
<template>
  <div>
    <textarea v-model="text" placeholder="أدخل النص العربي هنا" dir="rtl"></textarea>
    <select v-model="speaker">
      <option :value="0">صوت 1</option>
      <option :value="1">صوت 2 (افتراضي)</option>
      <option :value="2">صوت 3</option>
      <option :value="3">صوت 4</option>
    </select>
    <button @click="speak" :disabled="loading">
      {{ loading ? 'جاري التحويل...' : 'تشغيل' }}
    </button>
    <audio ref="audio" controls></audio>
  </div>
</template>

<script>
export default {
  data() {
    return {
      text: '',
      speaker: 1,
      loading: false
    };
  },
  methods: {
    async speak() {
      if (!this.text.trim()) return;
      
      this.loading = true;
      try {
        const response = await fetch('/tts/tts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ text: this.text, speaker: this.speaker })
        });
        
        const blob = await response.blob();
        this.$refs.audio.src = URL.createObjectURL(blob);
        await this.$refs.audio.play();
      } catch (error) {
        console.error('TTS Error:', error);
      } finally {
        this.loading = false;
      }
    }
  }
};
</script>
```

---

## cURL Examples

### Basic Request

```bash
curl -X POST "https://ema2a.ddnsgeek.com/tts/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "مرحبا بكم"}' \
  -o speech.mp3
```

### With Options

```bash
curl -X POST "https://ema2a.ddnsgeek.com/tts/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "مرحبا بكم", "speaker": 2, "pace": 0.8, "volume": 1.0}' \
  -o speech.mp3
```

### GET Request

```bash
curl "https://ema2a.ddnsgeek.com/tts/tts?text=مرحبا" -o speech.mp3
```

---

## Error Handling

### Validation Error (422)

```json
{
    "detail": [
        {
            "type": "string_too_short",
            "loc": ["body", "text"],
            "msg": "String should have at least 1 character",
            "input": ""
        }
    ]
}
```

### Server Error (500)

```json
{
    "detail": "TTS generation failed: [error message]"
}
```

---

## Performance Notes

1. **First request** may be slower due to model loading (~2-3 seconds)
2. **Subsequent requests** are faster (~0.5-2 seconds depending on text length)
3. **Text length** affects generation time - longer text takes more time
4. **Recommended** for texts up to 5000 characters

---

## Docker Deployment

### Run Standalone

```bash
docker run -d -p 8000:8000 --name arabic-tts arabic-tts-service
```

### With Docker Compose

```bash
docker-compose up tts-service
```

The service will be available at:
- Direct: `http://localhost:8000`
- Via nginx: `https://ema2a.ddnsgeek.com/tts/`

---

## Architecture

```
┌─────────────┐     ┌───────────┐     ┌─────────────┐
│   Frontend  │────▶│   Nginx   │────▶│ TTS Service │
│  (Browser)  │     │  (Proxy)  │     │  (FastAPI)  │
└─────────────┘     └───────────┘     └─────────────┘
                          │
                          ▼
                    ┌───────────┐
                    │  Backend  │
                    │   (.NET)  │
                    └───────────┘
```

The TTS service is accessible via:
- `/tts/*` - Through nginx proxy (recommended for production)
- `:8000/*` - Direct access (for development/testing)
