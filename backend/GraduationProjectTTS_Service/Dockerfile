# 1. Base image
FROM python:3.10-slim

# 2. Set working directory
WORKDIR /app

# 3. Install system deps (needed for git repo)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# 4. Copy ONLY requirements first (for caching)
COPY requirements.txt .

# 5. Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 6. Preload AI models (important for faster startup)
RUN python -c "import os; from tts_arabic import tts; tts('مرحبا', speaker=1, vowelizer='shakkelha', save_to='dummy.wav', play=False); os.remove('dummy.wav') if os.path.exists('dummy.wav') else None"

# 7. Copy the rest of the project
COPY . .

# 8. Expose port
EXPOSE 8000

# 9. Run FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]