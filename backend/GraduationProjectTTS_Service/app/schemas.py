from pydantic import BaseModel

class TTSRequest(BaseModel):
    text: str
    speaker: int = 1   # Allowed values: 0, 1, 2, 3
    pace: float = 1.0