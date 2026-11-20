"""Render the game's original seamless stereo music and effects."""
from pathlib import Path
import subprocess
import sys
import tempfile
import wave

import imageio_ffmpeg
import numpy as np
from scipy.signal import butter, sosfilt

RATE = 32000
BEAT = 60 / 124
LOOP = round(48 * BEAT * RATE)
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
MUSIC = OUTPUT / "music"
SFX = OUTPUT / "sfx"
CHORDS = [(38, 45, 53, 62), (34, 41, 53, 58), (43, 50, 58, 62), (45, 52, 55, 61)]
MELODY = [(74, 69, 77, 76), (70, 65, 74, 69), (67, 74, 70, 77), (76, 73, 67, 69)]
RNG = np.random.default_rng(1921)


def seconds(length):
    return np.arange(round(RATE * length)) / RATE


def sine(phase):
    return np.sin(2 * np.pi * phase)


def band_noise(t, low, high):
    noise = RNG.uniform(-1, 1, len(t))
    return sosfilt(butter(2, [low, high], fs=RATE, btype="bandpass", output="sos"), noise)


def add(track, sound, beat, gain, pan=0):
    start = round(beat * BEAT * RATE) % len(track)
    stereo = sound[:, None] * gain * np.sqrt([(1 - pan) / 2, (1 + pan) / 2])
    first = min(len(track) - start, len(stereo))
    track[start:start + first] += stereo[:first]
    track[:len(stereo) - first] += stereo[first:]


def note(pitch, length, instrument):
    t = seconds(length)
    freq = 440 * 2 ** ((pitch - 69) / 12)
    phase = t * freq
    if instrument == "pad":
        envelope = np.sin(np.pi * t / length) ** 1.6
        return envelope * (sine(phase) * 0.64 + sine(phase * 1.003) * 0.22 + sine(phase * 2) * 0.14)
    if instrument == "bass":
        return np.minimum(t / 0.045, 1) * np.exp(-t * 4.5) * (sine(phase) + 0.24 * sine(2 * phase))
    return np.minimum(t / 0.035, 1) * np.exp(-t * 4.8) * (
        sine(phase + 0.04 * sine(phase * 2.001)) + 0.14 * sine(phase * 3) * np.exp(-t * 7)
    )


def pulse(pitch, length):
    t = seconds(length)
    phase = t * 440 * 2 ** ((pitch - 69) / 12)
    return np.minimum(t / 0.012, 1) * np.exp(-11 * t) * (
        sine(phase) + 0.28 * sine(2 * phase) + 0.18 * sine(3 * phase)
    )


def drum(length, body, noise, low_pass, decay):
    t = seconds(length)
    tone = sine(body * t + 2.8 * (1 - np.exp(-t * 38)))
    return np.minimum(t / 0.005, 1) * np.exp(-decay * t) * (
        tone + noise * band_noise(t, 170, low_pass)
    )


def finish_mix(track, peak):
    saturated = np.tanh(track * 1.32)
    return saturated * (peak / np.max(np.abs(saturated)))


def music():
    harbor = np.zeros((LOOP, 2))
    search = np.zeros_like(harbor)
    voyage = np.zeros_like(harbor)
    boss = np.zeros_like(harbor)
    for bar in range(12):
        at = bar * 4
        chord = CHORDS[bar % 4]
        motif = MELODY[bar % 4]
        for index, pitch in enumerate(chord[1:]):
            pan = (index - 1) * 0.47
            add(harbor, note(pitch, 4, "pad"), at - 1.4, 0.091, pan)
            add(search, note(pitch - 12, 3.9, "pad"), at - 1, 0.072, pan)
            add(voyage, note(pitch, 3.4, "pad"), at - 0.65, 0.073, pan)
        for step, pitch in zip([0, 1.5, 2.5, 3.5], motif):
            if bar % 2 == 0 or step in (0, 2.5):
                add(harbor, note(pitch - 12, 1.35, "pluck"), at + step, 0.118, -0.22)
                add(harbor, note(pitch - 12, 1.02, "pluck"), at + step + 0.75, 0.030, 0.54)
            add(voyage, pulse(pitch - 12, 0.38), at + step + 0.25, 0.094, 0.30)
            add(voyage, pulse(pitch, 0.33), at + step + 0.70, 0.032, -0.44)
        for offset, pitch in zip([0, 0.75, 1.5, 2, 2.75, 3.5],
                                 [chord[0], chord[0] + 12, chord[1], chord[0], chord[2] - 12, chord[1]]):
            add(voyage, note(pitch, 0.58, "bass"), at + offset, 0.24)
        for offset in ([0, 1.5, 2.5, 3.5] if bar % 2 else [0, 0.75, 2, 3.25]):
            add(voyage, drum(0.34, 62, 0.20, 1200, 15.5), at + offset, 0.31)
        for offset in [1, 3]:
            add(voyage, drum(0.27, 132, 2.2, 3200, 17), at + offset, 0.14, 0.18)
        for step in range(8):
            t = seconds(0.10)
            tick = band_noise(t, 1700, 4800) * np.minimum(t * 280, 1) * np.exp(-t * 42)
            add(voyage, tick, at + step / 2, 0.08 if step % 2 == 0 else 0.11, (-1) ** step * 0.34)
        add(search, note(chord[0], 0.75, "bass"), at + 0.5, 0.10)
        if bar % 2 == 0:
            add(search, sonar(554, 1.25), at + 0.75, 0.086, -0.38)
            add(search, sonar(554, 1.0), at + 1.55, 0.031, 0.49)
        for offset in [0, 1.25, 2.75, 3.5]:
            add(boss, drum(0.46, 46, 0.61, 1350, 10), at + offset, 0.28)
            add(boss, pulse(chord[0] + 12, 0.55), at + offset + 0.18, 0.16)
        for pitch, pan in [(chord[0], -0.46), (chord[2] + 1, 0.46)]:
            add(boss, note(pitch, 3.1, "pad"), at - 0.7, 0.24, pan)
    for beat, pan in [(0, -0.45), (9, 0.30), (19, -0.28), (28, 0.48), (39, 0.10)]:
        t = seconds(7.5)
        wash = band_noise(t, 145, 1750) * np.sin(np.pi * t / 7.5) ** 2
        add(harbor, wash, beat, 0.12, pan)
        add(search, wash, beat + 0.25, 0.18, -pan)
    return tuple(finish_mix(track, peak) for track, peak in (
        (harbor, 0.63), (search, 0.59), (voyage, 0.82), (boss, 0.74)
    ))


def sonar(frequency, length):
    t = seconds(length)
    envelope = np.minimum(1, t / 0.042) * (1 - t / length) ** 2.7
    phase = frequency * t - 12 * t * t
    return (sine(phase) + 0.12 * sine(phase * 1.51)) * envelope


def effect(name, start, end, duration, noise_band, brightness, grit):
    t = seconds(duration)
    progress = t / duration
    frequency = start + (end - start) * np.sqrt(progress)
    phase = np.cumsum(frequency) / RATE
    envelope = np.minimum(1, t / 0.009) * (1 - progress) ** 3.1
    sound = (0.74 * sine(phase) + brightness * sine(phase * 1.47) +
             grit * band_noise(t, *noise_band)) * envelope
    write_wave(SFX / f"{name}.wav", sound * 0.78)


def write_wave(path, signal):
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1 if signal.ndim == 1 else 2)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes((np.clip(signal, -0.98, 0.98) * 32767).astype("<i2").tobytes())


if __name__ == "__main__":
    MUSIC.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as folder:
        scratch = Path(folder) / "loop.wav"
        for name, signal in zip(("harbor", "search", "voyage", "boss"), music()):
            write_wave(scratch, signal)
            subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-loglevel", "error", "-y",
                            "-i", str(scratch), "-c:a", "libvorbis", "-q:a", "5",
                            str(MUSIC / f"{name}.ogg")], check=True)
    if "--score-only" in sys.argv:
        sys.exit(0)
    SFX.mkdir(parents=True, exist_ok=True)
    effect("hit", 430, 265, 0.102, (490, 1450), 0.14, 0.24)
    effect("rail", 780, 490, 0.096, (500, 1500), 0.10, 0.13)
    effect("ice", 1580, 1070, 0.17, (900, 2600), 0.12, 0.24)
    effect("arc", 940, 340, 0.22, (680, 2200), 0.20, 0.38)
    effect("blast", 255, 63, 0.39, (110, 950), 0.13, 0.60)
    effect("surge", 520, 755, 0.31, (440, 1300), 0.22, 0.12)
    effect("ui", 603, 494, 0.145, (440, 1350), 0.13, 0.07)
    effect("motion", 393, 604, 0.22, (310, 1600), 0.16, 0.43)
    effect("hurt", 275, 112, 0.21, (210, 1040), 0.18, 0.29)
    effect("alert", 278, 181, 0.38, (210, 1040), 0.25, 0.16)
    departure = sonar(584, 0.83) * 0.55
    departure[6720:] += sonar(740, 0.62) * 0.19
    write_wave(SFX / "departure.wav", departure)
    effect("contact", 476, 298, 0.30, (260, 1050), 0.18, 0.11)
