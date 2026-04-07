# 1. Use a lightweight Python base image
FROM python:3.10-slim

# 2. Set the working directory
WORKDIR /app

# 3. Install the exact dependencies
RUN apt-get update && apt-get install -y git gcc python3-dev && \
    pip install --no-cache-dir fastapi uvicorn pydantic gdown onnxruntime psutil && \
    pip install --no-cache-dir git+https://github.com/mahmoudibrahim2002/tts_arabic.git && \
    apt-get purge -y --auto-remove gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

# 5. Pre-download the AI models into the image layer
RUN python -c "import os; from tts_arabic import tts; tts('مرحبا', speaker=1, vowelizer='shakkelha', save_to='dummy.wav', play=False); os.remove('dummy.wav') if os.path.exists('dummy.wav') else None"

# 6. Copy your actual code files
COPY . .

# 7. Expose the port
EXPOSE 8000

# 8. Start the FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
