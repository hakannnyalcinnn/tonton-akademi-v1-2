#!/usr/bin/env python3
"""Original deterministic synthesized audio; no third-party recordings."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 22050


def write(name, duration, notes, gain=0.3, noise=0.0):
    rng = random.Random(42)
    samples = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        value = 0.0
        for start, frequency, length in notes:
            u = t - start
            if 0 <= u < length:
                envelope = min(1, u / 0.009) * math.exp(-5.0 * u / length)
                envelope *= min(1, (length - u) / 0.025)
                value += (math.sin(2 * math.pi * frequency * u)
                          + 0.22 * math.sin(2 * math.pi * frequency * 2 * u)) * envelope
        if noise:
            value += noise * rng.uniform(-1, 1) * math.exp(-22 * t)
        samples.append(struct.pack("<h", int(max(-0.95, min(0.95, value * gain)) * 32767)))
    with wave.open(str(ROOT / (name + ".wav")), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b"".join(samples))


if __name__ == "__main__":
    ROOT.mkdir(parents=True, exist_ok=True)
    write("click", .10, [(0, 880, .09)], .16)
    write("pop", .22, [(0, 523.25, .16), (.03, 1046.5, .17)], .28, .12)
    write("large", .38, [(0, 392, .23), (.05, 523.25, .24), (.1, 783.99, .26)], .28, .2)
    write("resonance", .62, [(i * .09, f, .32) for i, f in enumerate([523.25, 659.25, 783.99, 1046.5])], .27)
    write("power", .55, [(0, 130.81, .25), (.06, 261.63, .25), (.14, 523.25, .3), (.24, 1046.5, .28)], .3, .3)
    write("gravity", .33, [(i * .04, f, .15) for i, f in enumerate([392, 440, 523.25, 659.25])], .24)
    write("win", 1.25, [(i * .13, f, .5) for i, f in enumerate([523.25, 659.25, 783.99, 1046.5, 1318.5])], .23)
    write("lose", .75, [(0, 392, .32), (.23, 329.63, .48)], .2)
    write("invalid", .18, [(0, 220, .16)], .15)
    write("rocket", .27, [(0, 196, .2), (.025, 784, .22), (.07, 1568, .17)], .23, .28)
    write("color", .44, [(i*.035, f, .3) for i, f in enumerate([587.33,739.99,880,1174.66,1479.98])], .20, .14)
    write("cascade", .24, [(0, 659.25, .18), (.04, 987.77, .19), (.09, 1318.5, .14)], .20, .09)
    melody = [261.63, 329.63, 392, 493.88, 440, 392, 329.63, 293.66,
              261.63, 392, 523.25, 493.88, 440, 329.63, 293.66, 392]
    notes = [(i * 1.5, f, 1.3) for i, f in enumerate(melody)]
    notes += [(i * 6, f, 5.8) for i, f in enumerate([130.81, 110, 146.83, 130.81])]
    write("garden", 24, notes, .16)
    print("13 original WAV assets generated")
