from contextlib import asynccontextmanager
from fastapi import FastAPI
import os

from tts_arabic import tts
from app.routes.tts import router as tts_router

# ✅ NEW: memory libs
import psutil

# ✅ GPU (optional)
try:
    import pynvml
    pynvml.nvmlInit()
    GPU_AVAILABLE = True
except:
    GPU_AVAILABLE = False


app = FastAPI(title="Ema2a Local TTS Service")
app.include_router(tts_router)


# ✅ Helper functions
def get_ram_mb():
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / 1024 / 1024


def get_gpu_mb():
    if not GPU_AVAILABLE:
        return 0
    handle = pynvml.nvmlDeviceGetHandleByIndex(0)
    mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
    return mem_info.used / 1024 / 1024


@asynccontextmanager
async def startup_event(app: FastAPI):  
    print("===== MEMORY BEFORE LOADING =====")
    print(f"RAM: {get_ram_mb():.2f} MB")
    print(f"GPU: {get_gpu_mb():.2f} MB")

    print("\nLoading Arabic TTS and Vowelizer Models into memory...")

    dummy_path = "dummy.wav"
    try:
        tts("مرحبا", speaker=1, vowelizer='shakkelha', save_to=dummy_path, play=False)

        if os.path.exists(dummy_path):
            os.remove(dummy_path)

        print("\n===== MEMORY AFTER LOADING =====")
        print(f"RAM: {get_ram_mb():.2f} MB")
        print(f"GPU: {get_gpu_mb():.2f} MB")

        print("Models loaded successfully!")

    except Exception as e:
        print(f"Error loading model: {e}")

    yield


# ✅ IMPORTANT: attach lifespan
app.router.lifespan_context = startup_event


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)