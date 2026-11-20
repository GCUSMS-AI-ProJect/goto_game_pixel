"""Render the driving battle music and the punchy combat sounds.

    python3 tools/compose_battle.py

Needs numpy, scipy and an ffmpeg with libvorbis on PATH.
Writes music/voyage.ogg (fight loop) and music/boss.ogg (a heavier layer that plays on top
of the fight loop when the boss is out; same tempo, key and length so they stay locked),
plus sfx hit, thump, crush, blast and heal.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile
import wave

import numpy as np
from scipy.signal import butter, sosfilt

RATE = 32000
BPM = 152
BEAT = 60 / BPM
BARS = 16
LOOP = round(BARS * 4 * BEAT * RATE)
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RNG = np.random.default_rng(2077)
# D minor: Dm - Bb - F - C, twice per 8 bars. Roots in the bass octave.
ROOTS = [38, 34, 41, 36]
CHORDS = [(62, 65, 69), (58, 62, 65), (65, 69, 72), (60, 64, 67)]


def seconds(length):
    return np.arange(round(RATE * length)) / RATE


def hz(pitch):
    return 440 * 2 ** ((pitch - 69) / 12)


def filt(signal, kind, cutoff, order=2):
    return sosfilt(butter(order, cutoff, fs=RATE, btype=kind, output="sos"), signal)


def noise(n):
    return RNG.uniform(-1, 1, n)


def saw(phase):
    return 2 * (phase % 1) - 1


def square(phase, duty=0.5):
    return np.where(phase % 1 < duty, 1.0, -1.0)


def add(track, sound, beat, gain, pan=0.0):
    """Mix a mono sound into a stereo loop at a beat position, wrapping at the end."""
    start = round(beat * BEAT * RATE) % len(track)
    stereo = sound[:, None] * gain * np.sqrt([(1 - pan) / 2, (1 + pan) / 2])
    first = min(len(track) - start, len(stereo))
    track[start:start + first] += stereo[:first]
    track[:len(stereo) - first] += stereo[first:]


def kick(length=0.32, punch=1.0):
    t = seconds(length)
    freq = 46 + 150 * np.exp(-t * 32)
    body = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t * 7.5)
    click = filt(noise(len(t)), "highpass", 2500) * np.exp(-t * 400) * 0.6
    return np.tanh((body + click) * 2.2 * punch)


def snare(length=0.24):
    t = seconds(length)
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 28)
    hiss = filt(noise(len(t)), "bandpass", [1200, 7000]) * np.exp(-t * 15)
    clap = sum(filt(noise(len(t)), "bandpass", [900, 3000]) * np.exp(-np.maximum(t - d, 0) * 90) * (t >= d)
               for d in (0, 0.011, 0.022))
    return np.tanh((tone * 0.7 + hiss * 1.1 + clap * 0.6) * 1.8)


def hat(length, bright=7000):
    t = seconds(length)
    return filt(noise(len(t)), "highpass", bright) * np.exp(-t * (60 if length < 0.1 else 14))


def crash(length=1.6):
    t = seconds(length)
    return filt(noise(len(t)), "highpass", 3500) * np.exp(-t * 2.6)


def tom(pitch_hz, length=0.3):
    t = seconds(length)
    freq = pitch_hz * (1 + 0.6 * np.exp(-t * 25))
    return np.tanh(np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t * 9) * 1.6)


def bass_note(pitch, length, grit=2.6, cutoff=1100):
    t = seconds(length)
    phase = t * hz(pitch)
    tone = saw(phase) * 0.7 + saw(phase * 1.006) * 0.5 + np.sin(2 * np.pi * phase * 0.5) * 0.6
    tone = filt(tone, "lowpass", cutoff)
    env = np.minimum(t / 0.004, 1) * np.exp(-t * 5)
    return np.tanh(tone * env * grit)


def lead(pitch, length, duty=0.25, vibrato=0.0):
    t = seconds(length)
    freq = hz(pitch) * (1 + vibrato * np.sin(2 * np.pi * 6 * t) * np.minimum(t / 0.15, 1))
    phase = np.cumsum(freq) / RATE
    env = np.minimum(t / 0.004, 1) * np.exp(-t * 3.2)
    return square(phase, duty) * env


def power_chord(root, length):
    """Distorted saw stack (root, fifth, octave), like an overdriven guitar chug."""
    t = seconds(length)
    tone = sum(saw(t * hz(root + iv) * d) for iv in (0, 7, 12) for d in (1.0, 1.004))
    env = np.minimum(t / 0.003, 1) * np.exp(-t * 6)
    return filt(np.tanh(tone * env * 3.0), "lowpass", 2600)


def siren(length):
    t = seconds(length)
    freq = 620 + 260 * np.sin(2 * np.pi * t / length * 2)
    phase = np.cumsum(freq) / RATE
    env = np.sin(np.pi * t / length) ** 0.6
    return square(phase, 0.5) * env


def riser(length):
    t = seconds(length)
    sweep = filt(noise(len(t)), "highpass", 800) * (t / length) ** 2
    return sweep


def sidechain(track, depth=0.55):
    """Pump the track down on every beat, like a compressor keyed by the kick."""
    t = (np.arange(len(track)) / RATE) % BEAT
    gain = 1 - depth * np.exp(-t * 14)
    return track * gain[:, None]


def master(track, peak):
    loud = np.tanh(track * 1.6)
    return loud * (peak / np.max(np.abs(loud)))


def fight_loop():
    drums = np.zeros((LOOP, 2))
    music = np.zeros_like(drums)
    for bar in range(BARS):
        at = bar * 4
        root = ROOTS[(bar // 2) % 4]
        chord = CHORDS[(bar // 2) % 4]
        intro = bar < 2
        for b in range(4):
            add(drums, kick(), at + b, 0.9)
            if not intro:
                add(drums, hat(0.16, 6000), at + b + 0.5, 0.32, 0.25)
        if not intro:
            for b in (1, 3):
                add(drums, snare(), at + b, 0.62, -0.05)
        for s in range(16):
            add(drums, hat(0.05), at + s / 4, 0.16 if s % 2 else 0.1, -0.35 if s % 2 else 0.35)
        if bar % 4 == 0:
            add(drums, crash(), at, 0.32, 0.3)
        if bar % 8 == 7:
            for s in range(8):
                add(drums, snare(0.12), at + 2 + s / 4, 0.25 + 0.05 * s)
            add(music, riser(4 * BEAT), at, 0.22)
        # Rolling 16th bass with octave pops on the off-beats.
        for s in range(16):
            pitch = root + (12 if s % 4 == 3 else 0)
            add(music, bass_note(pitch, BEAT / 4 * 0.9), at + s / 4, 0.36)
        if bar >= 2:
            # 16th arpeggio across the chord, alternating ears.
            arp = [chord[0], chord[1], chord[2], chord[0] + 12]
            for s in range(16):
                add(music, lead(arp[s % 4] + 12, BEAT / 4 * 0.85, 0.125), at + s / 4, 0.055,
                    -0.5 if s % 2 else 0.5)
        if bar >= 4 and bar % 2 == 0:
            # Short hook: two stabbing notes and a run up.
            hook = [(0, chord[2]), (0.75, chord[2]), (1.5, chord[1] + 12), (2.0, chord[2] + 12),
                    (2.5, chord[0] + 12), (3.0, chord[1] + 12)]
            for offset, pitch in hook:
                add(music, lead(pitch, BEAT * 0.55, 0.5, 0.01), at + offset, 0.11, 0.1)
    music = sidechain(music, 0.5)
    return master(drums + music, 0.92)


def boss_layer():
    track = np.zeros((LOOP, 2))
    for bar in range(BARS):
        at = bar * 4
        root = ROOTS[(bar // 2) % 4] + 12
        # Eighth-note power-chord chugs, palm-muted except the downbeat.
        for e in range(8):
            length = BEAT * (0.9 if e == 0 else 0.4)
            add(track, power_chord(root - 12, length), at + e / 2, 0.20 if e else 0.28, -0.4)
            add(track, power_chord(root - 12, length), at + e / 2 + 0.01, 0.16 if e else 0.24, 0.4)
        # Tom gallop on the last beat of each bar.
        for s, pitch in zip(range(4), (180, 150, 120, 95)):
            add(track, tom(pitch), at + 3 + s / 4, 0.32, (s - 1.5) * 0.2)
        if bar % 2 == 1:
            add(track, siren(BEAT * 2), at + 2, 0.06, 0.2)
        if bar % 4 == 0:
            add(track, kick(0.6, 1.4), at, 0.55)
    return master(sidechain(track, 0.35), 0.86)


def write_wave(path, signal):
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1 if signal.ndim == 1 else 2)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes((np.clip(signal, -0.98, 0.98) * 32767).astype("<i2").tobytes())


def to_ogg(signal, path):
    with tempfile.TemporaryDirectory() as folder:
        scratch = Path(folder) / "loop.wav"
        write_wave(scratch, signal)
        subprocess.run([shutil.which("ffmpeg"), "-loglevel", "error", "-y", "-i", str(scratch),
                        "-c:a", "libvorbis", "-q:a", "5", str(path)], check=True)


def crunch(signal, bits=5, hold=3):
    """Bit-crush and sample-hold: the gritty arcade edge on impacts."""
    held = np.repeat(signal[::hold], hold)[:len(signal)]
    levels = 2 ** (bits - 1)
    return np.round(held * levels) / levels


def normalise(signal, peak=0.95):
    return signal * (peak / max(1e-9, np.max(np.abs(signal))))


def sfx_hit():
    t = seconds(0.13)
    freq = 120 + 380 * np.exp(-t * 45)
    body = square(np.cumsum(freq) / RATE, 0.4) * np.exp(-t * 30)
    snap = filt(noise(len(t)), "bandpass", [1500, 6500]) * np.exp(-t * 85)
    click = noise(len(t)) * np.exp(-t * 900)
    return normalise(np.tanh((body * 0.8 + crunch(snap, 4, 2) * 0.9 + click * 0.5) * 2.4))


def sfx_thump():
    t = seconds(0.24)
    freq = 42 + 140 * np.exp(-t * 30)
    body = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t * 14)
    knock = filt(noise(len(t)), "bandpass", [300, 2400]) * np.exp(-t * 60)
    return normalise(np.tanh((body * 1.2 + knock * 0.7) * 3.0))


def sfx_crush():
    """Enemy destroyed: a crunchy pop that falls in pitch, with debris noise."""
    t = seconds(0.3)
    freq = 900 * np.exp(-t * 11) + 70
    pop = square(np.cumsum(freq) / RATE, 0.5) * np.exp(-t * 16)
    debris = crunch(filt(noise(len(t)), "bandpass", [600, 5000]), 4, 4) * np.exp(-t * 13)
    sub = np.sin(2 * np.pi * np.cumsum(55 + 90 * np.exp(-t * 25)) / RATE) * np.exp(-t * 12)
    return normalise(np.tanh((pop * 0.6 + debris * 0.8 + sub * 0.9) * 2.0))


def sfx_blast():
    t = seconds(0.6)
    boom = np.sin(2 * np.pi * np.cumsum(35 + 120 * np.exp(-t * 18)) / RATE) * np.exp(-t * 6)
    roar = crunch(filt(noise(len(t)), "lowpass", 2600), 5, 3) * np.exp(-t * 5.5)
    crack = filt(noise(len(t)), "highpass", 3000) * np.exp(-t * 70)
    return normalise(np.tanh((boom * 1.3 + roar * 0.9 + crack * 0.6) * 2.2))


def sfx_heal():
    """Enemy heal pulse: a rising two-note shimmer, clearly 'not good for you'."""
    t = seconds(0.42)
    out = np.zeros(len(t))
    for start, pitch in ((0.0, 76), (0.09, 83)):
        local = np.maximum(t - start, 0)
        tone = square(local * hz(pitch) * (1 + 0.25 * local), 0.25) * np.exp(-local * 9) * (t >= start)
        out += tone
    return normalise(filt(out, "lowpass", 5000) * 0.8, 0.8)


if __name__ == "__main__":
    to_ogg(fight_loop(), OUTPUT / "music" / "voyage.ogg")
    to_ogg(boss_layer(), OUTPUT / "music" / "boss.ogg")
    sfx = OUTPUT / "sfx"
    for name, maker in (("hit", sfx_hit), ("thump", sfx_thump), ("crush", sfx_crush),
                        ("blast", sfx_blast), ("heal", sfx_heal)):
        write_wave(sfx / f"{name}.wav", maker())
    print("wrote battle music and impact sounds")
