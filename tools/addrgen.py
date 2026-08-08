#!/usr/bin/env python3
import random

sr = random.SystemRandom()

print(f"Twoja sieć IPv4: 10.{sr.randrange(256)}.{sr.randrange(16)*16}.0/20")
print(
    f"Twoja sieć IPv6: fd{sr.randrange(256):02x}:{sr.randrange(65536):04x}:{sr.randrange(65536):04x}:{sr.randrange(256):02x}00::/56"
)
