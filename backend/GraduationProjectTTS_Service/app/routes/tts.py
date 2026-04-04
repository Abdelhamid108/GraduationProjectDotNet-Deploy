# app/routes/tts.py
from fastapi import HTTPException, BackgroundTasks, APIRouter
from fastapi.responses import FileResponse
from app.schemas import TTSRequest
import uuid
import os
import psutil
import time

# GPU (safe optional)
try:
    import pynvml
    pynvml.nvmlInit()
    GPU_AVAILABLE = True
except:
    GPU_AVAILABLE = False


def get_ram_mb():
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / 1024 / 1024


def get_gpu_mb():
    if not GPU_AVAILABLE:
        return 0
    handle = pynvml.nvmlDeviceGetHandleByIndex(0)
    mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
    return mem_info.used / 1024 / 1024

# ADDED: You must import tts in the exact file where it is used
from tts_arabic import tts

# FIX: Set the prefix here...
router = APIRouter(prefix="/tts", tags=["TTS"])

# FIX: Moved this helper function to the top so it's ready when the route calls it
def remove_file(path: str):
    try:
        if os.path.exists(path):
            os.remove(path)
    except Exception as e:
        pass

# FIX: Added the '@' symbol and changed path to "/" to avoid "/api/tts/api/tts"
@router.post("/")
async def generate_audio(request: TTSRequest, background_tasks: BackgroundTasks):
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    unique_filename = f"output_{uuid.uuid4().hex}.wav"
    file_path = os.path.join(os.getcwd(), unique_filename)

    # ✅ BEFORE request
    start_time = time.time()
    ram_before = get_ram_mb()
    gpu_before = get_gpu_mb()

    print("\n===== REQUEST START =====")
    print(f"RAM Before: {ram_before:.2f} MB")
    print(f"GPU Before: {gpu_before:.2f} MB")

    try:
        tts(
            text=request.text,
            speaker=request.speaker,
            pace=request.pace,
            vowelizer='shakkelha',
            save_to=file_path,
            play=False
        )

        # ✅ AFTER generation
        ram_after = get_ram_mb()
        gpu_after = get_gpu_mb()
        elapsed = time.time() - start_time

        print("----- REQUEST END -----")
        print(f"RAM After: {ram_after:.2f} MB")
        print(f"GPU After: {gpu_after:.2f} MB")
        print(f"RAM Delta: {ram_after - ram_before:.2f} MB")
        print(f"GPU Delta: {gpu_after - gpu_before:.2f} MB")
        print(f"Time Taken: {elapsed:.2f} sec")

        if not os.path.exists(file_path):
            raise HTTPException(status_code=500, detail="Audio file was not generated.")

        background_tasks.add_task(remove_file, file_path)

        return FileResponse(
            path=file_path,
            media_type="audio/wav",
            filename="arabic_speech.wav"
        )

    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=str(e))