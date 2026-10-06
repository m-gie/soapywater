"""Reads Project Zomboid .pack texture packs (PZPK v1): pages of PNGs with named sub-images."""
import io
import struct
import sys

from PIL import Image


def read_pack(path):
    data = open(path, "rb").read()
    pos = 0

    def i32():
        nonlocal pos
        v = struct.unpack_from("<i", data, pos)[0]
        pos += 4
        return v

    def s():
        nonlocal pos
        n = i32()
        v = data[pos:pos + n].decode("utf-8", "replace")
        pos += n
        return v

    if data[:4] == b"PZPK":
        pos = 4
        version = i32()
    else:
        version = 0  # old packs: no header, each PNG ends with 0xDEADBEEF
    pages = i32()
    for _ in range(pages):
        page_name = s()
        count = i32()
        i32()  # mask flag
        entries = []
        for _ in range(count):
            name = s()
            x, y, w, h, ox, oy, fw, fh = (i32() for _ in range(8))
            entries.append((name, x, y, w, h, ox, oy, fw, fh))
        if version >= 1:
            n = i32()
            png = data[pos:pos + n]
            pos += n
        else:
            end = data.index(bytes.fromhex("efbeadde"), pos)
            png = data[pos:end]
            pos = end + 4
        yield page_name, Image.open(io.BytesIO(png)).convert("RGBA"), entries


def extract(path, wanted, out_dir):
    found = {}
    for _, page, entries in read_pack(path):
        for name, x, y, w, h, ox, oy, fw, fh in entries:
            if name in wanted:
                full = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
                full.paste(page.crop((x, y, x + w, y + h)), (ox, oy))
                full.save(f"{out_dir}/{name}.png")
                found[name] = full.size
    return found


if __name__ == "__main__":
    pack, out = sys.argv[1], sys.argv[2]
    print(extract(pack, set(sys.argv[3:]), out))
