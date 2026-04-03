# main.py
from contextlib import asynccontextmanager

from fastapi import FastAPI
import os

from tts_arabic import tts
# ADDED: Import your router from the app folder
from app.routes.tts import router as tts_router

app = FastAPI(title="Ema2a Local TTS Service")

# ADDED: Wire up the router so FastAPI knows the endpoints exist
app.include_router(tts_router)

@asynccontextmanager
async def startup_event():
    print("Loading Arabic TTS and Vowelizer Models into memory...")
    dummy_path = "dummy.wav"
    try:
        tts("مرحبا", speaker=1, vowelizer='shakkelha', save_to=dummy_path, play=False)
        if os.path.exists(dummy_path):
            os.remove(dummy_path)
        print("Models loaded successfully!")
    except Exception as e:
        print(f"Error loading model: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)