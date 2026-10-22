"""Render our original vector-like mascot as an opaque PNG, using only Python."""
from pathlib import Path
import json
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024

def make():
    pixels = bytearray(SIZE * SIZE * 3)
    for y in range(SIZE):
        for x in range(SIZE):
            t = y / SIZE
            offset = (y * SIZE + x) * 3
            pixels[offset:offset + 3] = bytes((int(236 - 17 * t), int(228 + 8 * t), int(252 - 13 * t)))

    def ellipse(cx, cy, rx, ry, color):
        for y in range(max(0, int(cy - ry - 1)), min(SIZE, int(cy + ry + 2))):
            for x in range(max(0, int(cx - rx - 1)), min(SIZE, int(cx + rx + 2))):
                distance = math.sqrt(((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2)
                alpha = min(1., max(0., (1 - distance) * min(rx, ry) + .5))
                if alpha:
                    i = (y * SIZE + x) * 3
                    pixels[i:i+3] = bytes(round(pixels[i+c] * (1-alpha) + color[c] * alpha) for c in range(3))

    ellipse(512, 854, 249, 27, (200, 200, 217))
    ellipse(392, 249, 47, 161, (169, 131, 222))
    ellipse(624, 249, 47, 161, (169, 131, 222))
    ellipse(392, 232, 22, 113, (142, 211, 184))
    ellipse(624, 232, 22, 113, (142, 211, 184))
    ellipse(270, 634, 65, 112, (164, 125, 216))
    ellipse(752, 634, 65, 112, (164, 125, 216))
    ellipse(400, 814, 65, 34, (159, 119, 209))
    ellipse(622, 814, 65, 34, (159, 119, 209))
    # A continuously curved pear silhouette, with a soft top-left highlight.
    for y in range(308, 821):
        ty = (y - 308) / 513
        half = math.sin(math.pi * ty) ** .48 * (168 + 122 * ty)
        for x in range(max(0, int(512-half-1)), min(SIZE, int(512+half+2))):
            edge = half - abs(x + .5 - 512)
            alpha = min(1., max(0., edge + .5))
            highlight = max(0, 1 - math.hypot((x-399)/360, (y-392)/400))
            color = (int(160+26*highlight), int(121+26*highlight), int(213+19*highlight))
            i = (y*SIZE+x)*3
            pixels[i:i+3] = bytes(round(pixels[i+c]*(1-alpha)+color[c]*alpha) for c in range(3))
    ellipse(516, 744, 121, 65, (175, 150, 224))
    ellipse(356, 623, 39, 23, (222, 146, 191))
    ellipse(671, 623, 39, 23, (222, 146, 191))
    for cx in (419, 604):
        ellipse(cx, 546, 68, 77, (255, 253, 251))
        ellipse(cx+4, 554, 31, 43, (61, 49, 84))
        ellipse(cx-7, 536, 12, 15, (255, 255, 255))
        ellipse(cx+16, 567, 5, 6, (255, 255, 255))
    ellipse(512, 650, 63, 45, (61, 49, 84))
    ellipse(512, 623, 72, 24, (169, 132, 220))
    ellipse(520, 681, 34, 13, (244, 144, 172))
    for cx, cy in [(212, 295), (819, 380), (756, 168)]:
        ellipse(cx, cy, 5, 20, (255, 255, 255)); ellipse(cx, cy, 20, 5, (255, 255, 255))
    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload))
    raw = b''.join(b'\0' + pixels[y*SIZE*3:(y+1)*SIZE*3] for y in range(SIZE))
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', SIZE, SIZE, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    folder = ROOT / 'FantasiVen.swiftpm/Resources/Assets.xcassets/AppIcon.appiconset'
    folder.mkdir(parents=True, exist_ok=True)
    (folder/'AppIcon.png').write_bytes(png)
    (folder/'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2)+'\n')
    (folder.parent/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
    print('Created original 1024px app icon')

if __name__ == '__main__':
    make()
