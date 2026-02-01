"""
Arabic Text-to-Speech API Service
Exposes an endpoint that converts Arabic text to speech and returns an MP3 file.

API Documentation:
- POST /tts - Convert Arabic text to speech (JSON body)
- GET /tts - Convert Arabic text to speech (query parameters)
- GET /health - Health check endpoint
- GET /docs - Interactive API documentation (Swagger UI)
- GET /redoc - Alternative API documentation (ReDoc)
"""

import io
import tempfile
import os
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from tts_arabic import tts
from pydub import AudioSegment

app = FastAPI(
    title="Arabic Text-to-Speech API",
    description="""
## Arabic TTS Service

This API converts Arabic text to natural-sounding speech audio using AI models.

### Features
- **Multiple speakers**: Choose from 4 different voice styles (0-3)
- **Adjustable pace**: Control speech speed (0.1x to 2x)
- **Volume control**: Set output volume (0 to 1)
- **MP3 output**: Returns high-quality 192kbps MP3 audio

### Usage Examples

**JavaScript (Fetch API):**
```javascript
// Play audio directly
const response = await fetch('/tts/tts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: 'مرحبا بكم' })
});
const audioBlob = await response.blob();
const audioUrl = URL.createObjectURL(audioBlob);
const audio = new Audio(audioUrl);
audio.play();
```

**Download MP3:**
```javascript
const response = await fetch('/tts/tts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: 'مرحبا بكم' })
});
const blob = await response.blob();
const url = URL.createObjectURL(blob);
const a = document.createElement('a');
a.href = url;
a.download = 'speech.mp3';
a.click();
```
    """,
    version="1.0.0",
    contact={
        "name": "Graduation Project Team",
    },
    license_info={
        "name": "MIT",
    },
)

# CORS configuration - Allow frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition", "Content-Length"],
)


class TTSRequest(BaseModel):
    """Request model for TTS endpoint"""
    text: str = Field(
        ..., 
        description="Arabic text to convert to speech",
        min_length=1,
        max_length=5000,
        examples=["مرحبا بكم في خدمة تحويل النص إلى كلام"]
    )
    speaker: int = Field(
        default=1,
        ge=0,
        le=3,
        description="Speaker voice ID. Each ID represents a different voice style.",
        examples=[0, 1, 2, 3]
    )
    pace: float = Field(
        default=1.0,
        gt=0,
        le=2,
        description="Speech pace/speed multiplier. 1.0 is normal speed, 0.5 is half speed, 2.0 is double speed.",
        examples=[0.8, 1.0, 1.2]
    )
    volume: float = Field(
        default=0.9,
        gt=0,
        le=1,
        description="Audio volume level from 0 (silent) to 1 (maximum).",
        examples=[0.5, 0.9, 1.0]
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "text": "مرحبا بكم",
                    "speaker": 1,
                    "pace": 1.0,
                    "volume": 0.9
                }
            ]
        }
    }


class HealthResponse(BaseModel):
    """Health check response model"""
    status: str = Field(description="Service status", examples=["healthy"])
    service: str = Field(description="Service name", examples=["arabic-tts"])


class ErrorResponse(BaseModel):
    """Error response model"""
    detail: str = Field(description="Error message")


@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["Health"],
    summary="Health Check",
    description="Check if the TTS service is running and healthy."
)
async def health_check():
    """
    Health check endpoint.
    
    Returns the service status. Use this endpoint to verify the service is running.
    """
    return {"status": "healthy", "service": "arabic-tts"}


@app.get(
    "/speakers",
    tags=["Info"],
    summary="List Available Speakers",
    description="Get information about available speaker voices."
)
async def list_speakers():
    """
    Get list of available speaker voices.
    
    Returns information about each available speaker ID and their characteristics.
    """
    return {
        "speakers": [
            {"id": 0, "description": "Speaker 0 - Male voice style 1"},
            {"id": 1, "description": "Speaker 1 - Male voice style 2 (default)"},
            {"id": 2, "description": "Speaker 2 - Male voice style 3"},
            {"id": 3, "description": "Speaker 3 - Male voice style 4"},
        ],
        "default": 1
    }


@app.post(
    "/tts",
    response_class=StreamingResponse,
    tags=["Text-to-Speech"],
    summary="Convert Text to Speech (POST)",
    description="Convert Arabic text to speech audio. Returns an MP3 file.",
    responses={
        200: {
            "description": "MP3 audio file",
            "content": {"audio/mpeg": {}}
        },
        422: {
            "description": "Validation error",
            "model": ErrorResponse
        },
        500: {
            "description": "TTS generation failed",
            "model": ErrorResponse
        }
    }
)
async def text_to_speech(request: TTSRequest):
    """
    Convert Arabic text to speech.
    
    Returns an MP3 audio file of the spoken text.
    """
    try:
        # Create a temporary file for the WAV output
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_path = tmp_file.name
        
        # Generate the audio (WAV format)
        tts(
            request.text,
            speaker=request.speaker,
            pace=request.pace,
            denoise=0.005,
            volume=request.volume,
            play=False,
            pitch_mul=1,
            pitch_add=0,
            vowelizer=None,
            model_id='fastpitch',
            vocoder_id='hifigan',
            cuda=None,
            save_to=tmp_path,
            bits_per_sample=32,
        )
        
        # Convert WAV to MP3 using pydub
        audio = AudioSegment.from_wav(tmp_path)
        mp3_buffer = io.BytesIO()
        audio.export(mp3_buffer, format="mp3", bitrate="192k")
        mp3_buffer.seek(0)
        audio_data = mp3_buffer.read()
        
        # Clean up the temporary WAV file
        os.unlink(tmp_path)
        
        # Return the audio as a streaming response
        return StreamingResponse(
            io.BytesIO(audio_data),
            media_type="audio/mpeg",
            headers={
                "Content-Disposition": "attachment; filename=speech.mp3",
                "Content-Length": str(len(audio_data))
            }
        )
    
    except Exception as e:
        # Clean up temp file if it exists
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise HTTPException(status_code=500, detail=f"TTS generation failed: {str(e)}")


@app.get(
    "/tts",
    response_class=StreamingResponse,
    tags=["Text-to-Speech"],
    summary="Convert Text to Speech (GET)",
    description="Convert Arabic text to speech using query parameters. Useful for simple requests or direct browser access.",
    responses={
        200: {
            "description": "MP3 audio file",
            "content": {"audio/mpeg": {}}
        },
        422: {
            "description": "Validation error",
            "model": ErrorResponse
        },
        500: {
            "description": "TTS generation failed",
            "model": ErrorResponse
        }
    }
)
async def text_to_speech_get(
    text: str = Query(
        ...,
        description="Arabic text to convert to speech",
        min_length=1,
        max_length=5000,
        examples=["مرحبا بكم"]
    ),
    speaker: int = Query(
        default=1,
        ge=0,
        le=3,
        description="Speaker voice ID (0-3)"
    ),
    pace: float = Query(
        default=1.0,
        gt=0,
        le=2,
        description="Speech pace multiplier"
    ),
    volume: float = Query(
        default=0.9,
        gt=0,
        le=1,
        description="Audio volume (0-1)"
    )
):
    """
    Convert Arabic text to speech (GET endpoint).
    
    This endpoint is useful for:
    - Simple requests from the browser address bar
    - Audio elements with src attribute
    - Cases where POST is not convenient
    
    Example: `/tts?text=مرحبا&speaker=1&pace=1.0`
    """
    request = TTSRequest(text=text, speaker=speaker, pace=pace, volume=volume)
    return await text_to_speech(request)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
