import math

with open("sine.mem", "w") as f:
    for i in range(256):
        val = int(127 * math.sin(2 * math.pi * i / 256))
        if val < 0:
            val = (1 << 8) + val  # two's complement
        f.write(f"{val:02x}\n")