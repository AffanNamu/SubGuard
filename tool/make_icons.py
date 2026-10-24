"""Builds the app icon assets from design/icon/source.png.

The source is a navy squircle on a white square. This script produces:

  assets/icon/app_icon.png             1024 px, full-bleed, no alpha (iOS, legacy Android)
  assets/icon/adaptive_background.png  1024 px, the navy gradient only
  assets/icon/adaptive_foreground.png  1024 px, the mark on transparency, sized for the
                                       Android adaptive-icon safe zone
  assets/icon/logo.png                 256 px, shown in the app bar

Run from the repo root:  python3 tool/make_icons.py
Needs Pillow and numpy. Then run:  dart run flutter_launcher_icons
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "icon" / "source.png"
OUT = ROOT / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)

img = Image.open(SRC).convert("RGB")
W, H = img.size


def fill_outside_corners(im: Image.Image) -> np.ndarray:
    """Replace the white corners of the squircle with the navy next to them."""
    marker = (255, 0, 255)
    work = im.copy()
    for xy in [(1, 1), (W - 2, 1), (1, H - 2), (W - 2, H - 2)]:
        ImageDraw.floodfill(work, xy, marker, thresh=150)
    mask = np.all(np.array(work) == marker, axis=2)
    # Cover the anti-aliased fringe too.
    grown = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(9))
    mask = np.array(grown) > 0

    a = np.array(im).astype(np.float32)
    known = ~mask
    a[mask] = 0
    # Grow the known navy outwards, one pixel ring at a time.
    for _ in range(400):
        if known.all():
            break
        total = np.zeros_like(a)
        count = np.zeros(mask.shape, np.float32)
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            k = np.roll(known, (dy, dx), (0, 1))
            c = np.roll(a, (dy, dx), (0, 1))
            total += c * k[..., None]
            count += k
        ring = (~known) & (count > 0)
        a[ring] = total[ring] / count[ring][:, None]
        known = known | ring
    return a


full = fill_outside_corners(img)  # float32 H x W x 3, full-bleed square
Image.fromarray(full.round().astype(np.uint8)).resize((1024, 1024), Image.LANCZOS).save(OUT / "app_icon.png")
Image.fromarray(full.round().astype(np.uint8)).resize((256, 256), Image.LANCZOS).save(OUT / "logo.png")

# ---- adaptive icon: separate the mark from the navy background ----
# Estimate the background by smoothing it across the area the mark covers.
small = 314
bg_small = np.array(Image.fromarray(full.round().astype(np.uint8)).resize((small, small), Image.LANCZOS)).astype(np.float32)
x0, y0, x1, y1 = int(150 / W * small), int(110 / H * small), int(1105 / W * small), int(1105 / H * small)
region = np.zeros((small, small), bool)
region[y0:y1, x0:x1] = True
est = bg_small.copy()
est[region] = est[~region].mean(axis=0)
for _ in range(1500):  # Laplace smoothing: the region takes the shape of its surroundings
    avg = (np.roll(est, 1, 0) + np.roll(est, -1, 0) + np.roll(est, 1, 1) + np.roll(est, -1, 1)) / 4
    est[region] = avg[region]
bg = np.array(Image.fromarray(est.round().astype(np.uint8)).resize((W, H), Image.BICUBIC)).astype(np.float32)
# Outside the mark's area keep the real pixels, so the layers match exactly.
region_full = np.zeros((H, W), bool)
region_full[110:1105, 150:1110] = True
bg = np.where(region_full[..., None], bg, full)

diff = np.abs(full - bg).max(axis=2)
alpha = np.clip((diff - 10) / (55 - 10), 0, 1)
alpha[~region_full] = 0
alpha3 = alpha[..., None]
color = np.where(alpha3 > 0.02, (full - (1 - alpha3) * bg) / np.maximum(alpha3, 0.02), 0)
color = np.clip(color, 0, 255)
fg = np.dstack([color, alpha * 255]).round().astype(np.uint8)
fg_img = Image.fromarray(fg, "RGBA")

ys, xs = np.where(alpha > 0.2)
bbox = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
mark = fg_img.crop(bbox)
cx, cy = (bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2
# Farthest point of the mark from the canvas centre decides the scale: it
# must stay inside the circle every launcher mask leaves visible.
radius = np.sqrt((xs - W / 2) ** 2 + (ys - H / 2) ** 2).max()
scale = (0.31 * 1024) / (radius * 1024 / W)
canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
full_scaled = fg_img.resize((round(W * 1024 / W * scale), round(H * 1024 / H * scale)), Image.LANCZOS)
ox = round(512 - (W / 2) * (1024 / W) * scale)
oy = round(512 - (H / 2) * (1024 / H) * scale)
canvas.alpha_composite(full_scaled, (ox, oy))
canvas.save(OUT / "adaptive_foreground.png")

Image.fromarray(bg.round().astype(np.uint8)).resize((1024, 1024), Image.LANCZOS).save(OUT / "adaptive_background.png")
print("mark bbox", bbox, "scale", round(scale, 3))
