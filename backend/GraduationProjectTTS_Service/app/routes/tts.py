# app/routes/tts.py
from fastapi import HTTPException, BackgroundTasks, APIRouter
from fastapi.responses import FileResponse
from app.schemas import TTSRequest
import uuid
import os

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

    try:
        # Generate the audio file using the tts_arabic package
        tts(
            text=request.text,
            speaker=request.speaker,
            pace=request.pace,
            vowelizer='shakkelha',
            save_to=file_path,
            play=False
        )

        if not os.path.exists(file_path):
            raise HTTPException(status_code=500, detail="Audio file was not generated.")

        # Schedule the file to be deleted AFTER the response is sent to .NET
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