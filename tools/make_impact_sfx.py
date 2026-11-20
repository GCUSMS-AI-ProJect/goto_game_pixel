"""Generate the layered impact sounds used by the combat feedback.

Standard library only, so it runs anywhere:  python tools/make_impact_sfx.py
Writes assets/audio/sfx/thump.wav (low body layer under hits and kills)
and assets/audio/sfx/coin.wav (pickup ding).
"""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 32000
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s / peak * 0.92)) * 32767)) for s in samples)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)


def thump():
    # Pitch-dropping sine (150 Hz -> 48 Hz) with a short noise click on top.
    rng = random.Random(7)
    length = int(RATE * 0.16)
    phase = 0.0
    out = []
    for i in range(length):
        t = i / RATE
        freq = 48 + 102 * math.exp(-t * 38)
        phase += 2 * math.pi * freq / RATE
        body = math.sin(phase) * math.exp(-t * 22)
        click = (rng.random() * 2 - 1) * math.exp(-t * 900) * 0.55
        out.append(math.tanh((body + click) * 1.8))
    return out


def coin():
    # Two bright partials, the second a fifth above, entering 35 ms later.
    length = int(RATE * 0.22)
    out = []
    for i in range(length):
        t = i / RATE
        a = math.sin(2 * math.pi * 1568 * t) * math.exp(-t * 26)
        b = math.sin(2 * math.pi * 2349 * t) * math.exp(-max(0.0, t - 0.035) * 22) if t > 0.035 else 0.0
        attack = min(1.0, t / 0.002)
        out.append((a * 0.6 + b * 0.5) * attack)
    return out


if __name__ == "__main__":
    write("thump.wav", thump())
    write("coin.wav", coin())
    print("wrote", OUT / "thump.wav", OUT / "coin.wav")
