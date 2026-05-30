#!/usr/bin/env python3
"""Generate all required PNG sizes for Khatir logo distribution."""
import cairosvg
from pathlib import Path

SRC = Path("/home/claude/khatir/logos/assets")
OUT = SRC

# Files to rasterize at multiple sizes
EXPORTS = [
    # (source SVG, output prefix, sizes, description)
    ("khatir-logo-primary.svg", "khatir-icon",        [16, 32, 48, 64, 128, 192, 256, 512, 1024], "main app icon - all sizes"),
    ("khatir-logo-solid.svg",   "khatir-icon-solid",  [256, 512],                                  "solid no-gradient"),
    ("khatir-logo-mono-dark.svg","khatir-icon-mono",  [256, 512],                                  "monochrome dark tile"),
    ("khatir-logo-light-tile.svg","khatir-icon-light",[256, 512],                                  "light tile"),
    ("favicon.svg",             "favicon",            [16, 32, 48],                                "tiny favicon"),
    ("khatir-lockup-horizontal.svg","khatir-lockup-h",[600, 1200],                                 "horizontal lockup"),
    ("khatir-lockup-stacked.svg","khatir-lockup-v",   [320, 640],                                  "stacked lockup"),
    ("khatir-og-image.svg",     "khatir-og",          [1200],                                      "OG social image"),
]

print(f"Generating PNG exports → {OUT}/")
total = 0
for src, prefix, sizes, desc in EXPORTS:
    src_path = SRC / src
    if not src_path.exists():
        print(f"  ✗ missing {src}")
        continue
    with open(src_path, "rb") as f:
        svg_bytes = f.read()
    for size in sizes:
        out = OUT / f"{prefix}-{size}.png"
        cairosvg.svg2png(bytestring=svg_bytes, write_to=str(out), output_width=size)
        total += 1
        print(f"  ✓ {out.name:35s}  ({desc})")

print(f"\nDone. {total} PNG files generated.")
