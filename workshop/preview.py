"""Draws workshop/preview.png (256x256, required by the PZ Workshop uploader).

Uses the game's own item icons, read from your Project Zomboid install and scaled
by whole numbers so the pixel art stays crisp. Run: python workshop/preview.py [game dir]
"""
import pathlib
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from pzpack import read_pack  # noqa: E402

GAME = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "E:/SteamLibrary/steamapps/common/ProjectZomboid")
OUT = pathlib.Path(__file__).with_name("preview.png")
FONT = "C:/Windows/Fonts/seguibl.ttf"
S = 256


def icons(*names):
    wanted, found = set(names), {}
    for pack in ("UI2.pack", "UI.pack"):
        for _, page, entries in read_pack(GAME / "media/texturepacks" / pack):
            for name, x, y, w, h, ox, oy, fw, fh in entries:
                if name in wanted and name not in found:
                    full = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
                    full.paste(page.crop((x, y, x + w, y + h)), (ox, oy))
                    found[name] = full
    missing = wanted - found.keys()
    assert not missing, f"icons not found: {missing}"
    return found


def scaled(img, k):
    return img.resize((img.width * k, img.height * k), Image.Resampling.NEAREST)


def place(canvas, img, x, y, shadow=True):
    """Pastes img with its bottom-centre at (x, y), with a soft ground shadow."""
    left, top = x - img.width // 2, y - img.height
    if shadow:
        sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ImageDraw.Draw(sh).ellipse([x - img.width * 0.42, y - 7, x + img.width * 0.42, y + 5], fill=(0, 0, 0, 120))
        canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)))
    canvas.alpha_composite(img, (left, top))


def pixel_bubble(d, cx, cy, r):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(225, 245, 255, 255), width=1)
    d.point([(cx - r // 2, cy - r // 2), (cx - r // 2 + 1, cy - r // 2)], fill=(255, 255, 255, 255))


def main():
    ic = icons("Item_MetalBucket_Water", "Item_Mop", "Item_Soap", "Item_Sponge")
    random.seed(3)
    img = Image.new("RGBA", (S, S))
    d = ImageDraw.Draw(img)
    # Night-blue wall, then a checkered kitchen floor from y=150.
    for y in range(S):
        t = y / S
        d.line([(0, y), (S, y)], fill=(int(24 + 16 * t), int(46 + 22 * t), int(70 + 18 * t), 255))
    tile = 16
    for ty in range(150, S, tile):
        for tx in range(0, S, tile):
            light = ((tx // tile) + (ty // tile)) % 2 == 0
            d.rectangle([tx, ty, tx + tile - 1, ty + tile - 1], fill=(170, 172, 160, 255) if light else (120, 124, 116, 255))
    d.line([(0, 149), (S, 149)], fill=(60, 50, 44, 255), width=3)

    # Blood stain in front: dirty on the left, a scrubbed-clean streak on the right.
    for _ in range(260):
        x = int(random.gauss(150, 34))
        y = int(random.gauss(236, 8))
        if 222 < y < 252 and 90 < x < 215:
            r = random.choice((1, 2, 2, 3))
            col = (122, 16, 16, 255) if x < 170 else (160, 96, 90, 120)
            d.rectangle([x, y, x + r, y + r], fill=col)

    place(img, scaled(ic["Item_Mop"], 4), 214, 206)
    place(img, scaled(ic["Item_MetalBucket_Water"], 4), 108, 214)
    place(img, scaled(ic["Item_Soap"], 2), 44, 240)
    place(img, scaled(ic["Item_Sponge"], 2), 206, 250)

    # Bubbles rising from the bucket.
    b = ImageDraw.Draw(img)
    for cx, cy, r in [(96, 96, 9), (124, 78, 6), (82, 70, 5), (140, 100, 4), (110, 52, 7), (150, 64, 4),
                      (70, 58, 4), (168, 56, 6), (40, 82, 5), (196, 76, 4), (232, 64, 6),
                      (24, 130, 3), (176, 110, 3)]:
        pixel_bubble(b, cx, cy, r)

    # Title with a dark outline, like the game's UI text.
    font = ImageFont.truetype(FONT, 30)
    text = "SOAPY WATER"
    w = b.textlength(text, font=font)
    b.text(((S - w) / 2, 8), text, font=font, fill=(240, 248, 255, 255), stroke_width=3, stroke_fill=(16, 28, 44, 255))

    img.convert("RGB").save(OUT, optimize=True)
    print(OUT, OUT.stat().st_size, "bytes")


if __name__ == "__main__":
    main()
