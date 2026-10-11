#!/usr/bin/env python3
"""Draws the placeholder app icon and writes every macOS size.

A stack of three cards on an indigo squircle, laid out on Apple's macOS icon
grid (an 824 pt body centred in a 1024 pt canvas, with a soft drop shadow).
Replace it with a designed icon before release.

Usage: python3 scripts/make_icon.py   (requires Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SS = 2  # supersample factor for smooth edges
C = 1024 * SS
OUT = Path(__file__).resolve().parent.parent / "App/Resources/Assets.xcassets/AppIcon.appiconset"


def s(v: float) -> int:
    return round(v * SS)


def vertical_gradient(size, top, bottom):
    w, h = size
    grad = Image.new("RGBA", (1, h))
    for y in range(h):
        t = y / (h - 1)
        grad.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return grad.resize((w, h))


def rounded_mask(size, box, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=radius, fill=255)
    return mask


def draw_icon() -> Image.Image:
    canvas = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    body = (s(100), s(100), s(924), s(924))
    radius = s(185)

    shadow = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (body[0], body[1] + s(12), body[2], body[3] + s(12)), radius=radius, fill=(0, 0, 0, 90)
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(s(18))))

    bg = vertical_gradient((C, C), (99, 102, 241), (76, 29, 149))
    canvas.paste(bg, (0, 0), rounded_mask((C, C), body, radius))

    # Three stacked cards, back to front.
    cards = [
        ((300, 250, 760, 610), (255, 255, 255, 90)),
        ((280, 320, 740, 680), (255, 255, 255, 150)),
        ((260, 390, 720, 770), (255, 255, 255, 255)),
    ]
    for (x0, y0, x1, y1), fill in cards:
        layer = Image.new("RGBA", (C, C), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        if fill[3] == 255:
            d.rounded_rectangle((s(x0), s(y0 + 10), s(x1), s(y1 + 10)), radius=s(48), fill=(30, 10, 80, 80))
            layer = layer.filter(ImageFilter.GaussianBlur(s(10)))
            d = ImageDraw.Draw(layer)
        d.rounded_rectangle((s(x0), s(y0), s(x1), s(y1)), radius=s(48), fill=fill)
        canvas.alpha_composite(layer)

    # Text lines on the front card.
    d = ImageDraw.Draw(canvas)
    for i, width in enumerate((340, 280, 320, 200)):
        y = 460 + i * 72
        d.rounded_rectangle((s(320), s(y), s(320 + width), s(y + 30)), radius=s(15), fill=(99, 102, 241, 255))

    return canvas.resize((1024, 1024), Image.LANCZOS)


def main():
    master = draw_icon()
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            px = pt * scale
            name = f"icon_{pt}x{pt}{'@2x' if scale == 2 else ''}.png"
            master.resize((px, px), Image.LANCZOS).save(OUT / name)
    print(f"Wrote icons to {OUT}")


if __name__ == "__main__":
    main()
