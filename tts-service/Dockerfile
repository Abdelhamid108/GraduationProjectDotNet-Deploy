# Arabic TTS Service Dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the local tts_arabic package and install it
COPY tts_arabic/ ./tts_arabic/
RUN pip install --no-cache-dir ./tts_arabic/

# Pre-download the TTS models during build to avoid download at runtime
RUN python -c "from tts_arabic import tts; tts('test', play=False, save_to='/tmp/test.wav')" || true

# Copy the application
COPY app.py .

# Expose the port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
