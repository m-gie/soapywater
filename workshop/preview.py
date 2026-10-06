"""Draws workshop/preview.png (256x256, required by the PZ Workshop uploader).

Drawn at 4x and scaled down for smooth edges. Run: python workshop/preview.py
"""
import math
import pathlib
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 1024
OUT = pathlib.Path(__file__).with_name("preview.png")
FONT = "C:/Windows/Fonts/seguibl.ttf"


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(size[1]):
        t = y / (size[1] - 1)
        d.line([(0, y), (size[0], y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def bubble(layer, cx, cy, r, alpha=255):
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(235, 248, 255, int(alpha * 0.35)), outline=(255, 255, 255, alpha), width=max(3, r // 9))
    # Highlight.
    hr = r * 0.32
    hx, hy = cx - r * 0.38, cy - r * 0.38
    d.ellipse([hx - hr, hy - hr * 0.7, hx + hr, hy + hr * 0.7], fill=(255, 255, 255, int(alpha * 0.9)))


def main():
    random.seed(7)
    img = vertical_gradient((S, S), (28, 92, 140), (10, 32, 58)).convert("RGBA")

    # Soft light behind the bucket.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([170, 200, 854, 820], fill=(120, 200, 240, 90))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90)))

    d = ImageDraw.Draw(img)

    # Mop handle leaning into the bucket.
    d.line([(690, 120), (560, 560)], fill=(196, 150, 96), width=34)
    d.line([(690, 120), (560, 560)], fill=(222, 182, 128), width=12)

    # Soft shadow under the bucket.
    shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shade).ellipse([300, 785, 724, 835], fill=(0, 0, 0, 120))
    img.alpha_composite(shade.filter(ImageFilter.GaussianBlur(14)), (0, 0))

    d = ImageDraw.Draw(img)

    # Bucket: tapered body, rim, handle, bands.
    top_y, bot_y = 470, 800
    d.polygon([(300, top_y), (724, top_y), (680, bot_y), (344, bot_y)], fill=(150, 165, 178))
    d.polygon([(300, top_y), (400, top_y), (430, bot_y), (344, bot_y)], fill=(176, 190, 202))
    d.polygon([(640, top_y), (724, top_y), (680, bot_y), (620, bot_y)], fill=(118, 132, 146))
    for y in (590, 720):
        t = (y - top_y) / (bot_y - top_y)
        x1, x2 = 300 + 44 * t, 724 - 44 * t
        d.line([(x1, y), (x2, y)], fill=(104, 118, 132), width=14)
    d.arc([300, 330, 724, 640], start=200, end=340, fill=(90, 100, 112), width=16)
    d.rounded_rectangle([284, top_y - 22, 740, top_y + 22], radius=22, fill=(196, 208, 218))

    # Foam: a mound of overlapping bubbles over the rim.
    foam = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fd = ImageDraw.Draw(foam)
    for cx, cy, r in [(330, 440, 70), (420, 400, 95), (530, 380, 105), (640, 405, 90), (712, 445, 64),
                      (470, 455, 70), (600, 460, 66), (380, 470, 50), (680, 475, 46)]:
        fd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(248, 252, 255, 255), outline=(200, 225, 240, 255), width=6)
    img.alpha_composite(foam)

    # Floating bubbles.
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    for cx, cy, r in [(205, 300, 46), (150, 470, 28), (830, 260, 58), (880, 470, 30), (760, 150, 26),
                      (290, 170, 32), (450, 230, 22), (610, 215, 30), (110, 640, 22), (905, 650, 24)]:
        bubble(layer, cx, cy, r)
    img.alpha_composite(layer)

    # Title with a soft shadow.
    font = ImageFont.truetype(FONT, 124)
    text = "SOAPY WATER"
    w = d.textlength(text, font=font)
    x, y = (S - w) / 2, 858
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((x + 6, y + 10), text, font=font, fill=(0, 0, 0, 170))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    ImageDraw.Draw(img).text((x, y), text, font=font, fill=(245, 251, 255), stroke_width=4, stroke_fill=(20, 60, 96))

    img.convert("RGB").resize((256, 256), Image.Resampling.LANCZOS).save(OUT, optimize=True)
    print(OUT, OUT.stat().st_size, "bytes")


if __name__ == "__main__":
    main()
