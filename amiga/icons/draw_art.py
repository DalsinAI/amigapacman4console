#!/usr/bin/env python3
"""Pacman For Console's picture for its GlowIcons (art/pacman.png), drawn
here: upstream has none. Pacman after a row of pellets, a ghost behind, on
the console's black, in the game's own colours. 64 x 64, RGBA.
    python3 amiga/icons/draw_art.py amiga/icons/art
Pure Python. MIT, Copyright (c) 2026 AmiCradle Team."""
import math, struct, sys, zlib
from pathlib import Path

W = H = 64
INK = (16, 18, 22, 255)
YELLOW = (240, 210, 40, 255)
RED = (220, 50, 50, 255)
WHITE = (235, 235, 235, 255)
BLUE = (60, 90, 220, 255)


def png(px, path):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def draw():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    def rect(x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                px[y][x] = c
    rect(2, 2, 62, 62, INK)
    rect(4, 4, 60, 60, (8, 8, 12, 255))
    rect(4, 8, 60, 10, BLUE)                     # the maze's walls
    rect(4, 54, 60, 56, BLUE)
    cx, cy, r = 22, 32, 15                       # Pacman, mouth to the right
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r * r and not (dx > 0 and abs(dy) < dx * 0.7):
                px[y][x] = YELLOW
    rect(20, 22, 24, 26, INK)                    # his eye
    for x0 in (40, 50):                          # pellets
        rect(x0, 30, x0 + 4, 34, WHITE)
    gx, gy = 44, 40                              # a ghost, small, behind
    for y in range(gy, gy + 12):
        for x in range(gx, gx + 12):
            dx, dy = x - gx - 6, y - gy - 6
            if (dy < 0 and dx * dx + dy * dy <= 36) or (dy >= 0 and not (y == gy + 11 and (x - gx) % 4 == 1)):
                px[y][x] = RED
    rect(gx + 2, gy + 3, gx + 5, gy + 6, WHITE)
    rect(gx + 7, gy + 3, gx + 10, gy + 6, WHITE)
    return px


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "art")
    out.mkdir(parents=True, exist_ok=True)
    png(draw(), out / "pacman.png")
