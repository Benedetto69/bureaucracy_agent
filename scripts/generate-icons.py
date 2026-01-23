#!/usr/bin/env python3
"""
Genera icone gradient oro per iOS/Android nel layout "Bureaucracy Agent".
"""
import os

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "icons" / "generated"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

GOLD = (200, 161, 92)
LIGHT_GOLD = (244, 215, 138)
BACKGROUND = (3, 3, 3)

IOS_ICON_SIZES = {
    "Icon-App-20x20@1x": 20,
    "Icon-App-20x20@2x": 40,
    "Icon-App-20x20@3x": 60,
    "Icon-App-29x29@1x": 29,
    "Icon-App-29x29@2x": 58,
    "Icon-App-29x29@3x": 87,
    "Icon-App-40x40@1x": 40,
    "Icon-App-40x40@2x": 80,
    "Icon-App-40x40@3x": 120,
    "Icon-App-60x60@2x": 120,
    "Icon-App-60x60@3x": 180,
    "Icon-App-76x76@1x": 76,
    "Icon-App-76x76@2x": 152,
    "Icon-App-83.5x83.5@2x": 167,
    "Icon-App-1024x1024@1x": 1024,
}

ANDROID_ICON_SIZES = {
    "icon_1024": 1024,
    "icon_512": 512,
    "icon_180": 180,
    "icon_152": 152,
    "icon_120": 120,
    "icon_76": 76,
    "icon_60": 60,
    "icon_mdpi": 48,
    "icon_hdpi": 72,
    "icon_xhdpi": 96,
    "icon_xxhdpi": 144,
    "icon_xxxhdpi": 192,
}

ICON_SIZES = {**IOS_ICON_SIZES, **ANDROID_ICON_SIZES}

FONT_PATHS = [
    "/System/Library/Fonts/SFNSDisplay-Bold.otf",
    "/System/Library/Fonts/SFNSDisplay-Regular.otf",
]


def create_icon(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), BACKGROUND)
    draw = ImageDraw.Draw(img)
    center = size // 2
    radius = int(size * 0.4)

    for i in range(radius, 0, -1):
        factor = i / radius
        r = int(GOLD[0] * factor + LIGHT_GOLD[0] * (1 - factor))
        g = int(GOLD[1] * factor + LIGHT_GOLD[1] * (1 - factor))
        b = int(GOLD[2] * factor + LIGHT_GOLD[2] * (1 - factor))
        draw.ellipse(
            [
                (center - i, center - i),
                (center + i, center + i),
            ],
            outline=(r, g, b),
            width=max(1, int(size * 0.01)),
        )

    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        [(center - radius - 10, center - radius - 10), (center + radius + 10, center + radius + 10)],
        fill=(244, 215, 138, 50),
    )
    img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")

    font = None
    for path in FONT_PATHS:
        if Path(path).exists():
            font = ImageFont.truetype(path, int(radius * 1.2))
            break
    if font is None:
        font = ImageFont.load_default()

    text = "B"
    bbox = font.getbbox(text)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text(
        (center - w / 2, center - h / 2 - size * 0.05),
        text,
        font=font,
        fill=LIGHT_GOLD,
    )

    wave_height = int(size * 0.05)
    wave_width = int(size * 0.6)
    start_x = center - wave_width // 2
    for i in range(wave_width):
        val = 1 - abs((i - wave_width / 2) / (wave_width / 2))
        wave_y = int(center + radius * 0.6 + val * wave_height)
        draw.line(
            [(start_x + i, wave_y), (start_x + i, wave_y - int(val * wave_height / 2))],
            fill=LIGHT_GOLD,
        )

    return img


def main() -> None:
    print("Generazione icone Bureaucracy Agent...")
    for name, size in ICON_SIZES.items():
        img = create_icon(size)
        target = OUTPUT_DIR / f"{name}.png"
        img.save(target, optimize=True)
        print(f"  ✅ {target.name} ({size}px)")
    print(f"Icone generate in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
