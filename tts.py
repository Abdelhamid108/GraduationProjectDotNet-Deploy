from tts_arabic import tts

text = "إِحْنَا تِيمْ (إِيمَاءَة) مُكَوَّنْ مِنْ إثنتا عشرة شَخْصْ، مَشْرُوعْنَا لِتَرْجَمَةِ إِشَارَاتِ الصُّمِّ وَالْبُكْمِ بِالذَّكَاءِ الِاصْطِنَاعِيِّ."
wave = tts(
    text,  # input text
    speaker=1,  # speaker id; choose between 0,1,2,3
    pace=1,  # speaker pace
    denoise=0.005,  # vocoder denoiser strength
    volume=0.9,  # Max amplitude (between 0 and 1)
    play=False,  # play audio? (requires sounddevice package)
    pitch_mul=1,  # pitch multiplier
    pitch_add=0,  # pitch offset
    vowelizer=None,  # vowelizer model
    # Model ID for Text->Mel model # Options: 'fastpitch', 'mixer128', 'mixer80'
    model_id='fastpitch',
    vocoder_id='hifigan',  # Model ID for vocoder model
    cuda=None,  # Optional; CUDA device index
    save_to='./test.mp3',  # Optionally; save audio WAV file
    bits_per_sample=32,  # when save_to is specified (8, 16 or 32 bits)
)
