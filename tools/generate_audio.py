"""Sons sintetizados originais do jogo, sem dependências externas."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "assets" / "audio"
DEST.mkdir(parents=True, exist_ok=True)
rng = random.Random(7)


def save(name, seconds, sample):
    frames = bytearray()
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = max(-1.0, min(1.0, sample(t, seconds)))
        frames.extend(struct.pack("<h", int(value * 26000)))
    with wave.open(str(DEST / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)


save("hum", 4, lambda t, d: .13 * math.sin(math.tau * 55 * t) + .06 * math.sin(math.tau * 82.5 * t) + .02 * rng.uniform(-1, 1))
save("step", .17, lambda t, d: (.5 * rng.uniform(-1, 1) + .3 * math.sin(math.tau * 90 * t)) * math.exp(-t * 35))
save("hurt", .45, lambda t, d: (.4 * rng.uniform(-1, 1) + .3 * math.sin(math.tau * (150 * t - 90 * t * t))) * (1 - t / d) ** 2)
save("pickup", .4, lambda t, d: .4 * math.sin(math.tau * (660 if t < .18 else 990) * t) * math.sin(math.pi * t / d) ** 2)
save("ruan", 1.3, lambda t, d: (.45 * math.sin(math.tau * (60 * t + 140 * t * t)) + .15 * rng.uniform(-1, 1)) * math.sin(math.pi * t / d) ** 2)
save("win", 1.6, lambda t, d: .35 * math.sin(math.tau * [440, 554.37, 659.25, 880][min(3, int(t / .4))] * t) * math.sin(math.pi * ((t % .4) / .4)) ** 2)
save("lose", 1.6, lambda t, d: .4 * math.sin(math.tau * (160 * t - 32 * t * t)) * math.sin(math.pi * t / d) ** 2)
print(f"Audio salvo em {DEST}")
