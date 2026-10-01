"""Remove banding from the dark background art: smooth in float, re-dither to 8-bit.

Usage: python scripts/deband_backgrounds.py <source_dir> <out_dir>

<source_dir> holds the undithered masters: signin_bg_2x.png (1608x3496) and
onboarding_bg.jpeg. Never feed the script its own output. The originals are
in git history, as of commit a42284b:
  git show a42284b:assets/images/background.png > <source_dir>/signin_bg_2x.png
  git show a42284b:assets/images/onboarding_bg.jpeg > <source_dir>/onboarding_bg.jpeg
Copy the outputs to assets/images/signin_bg.png (from signin_bg_1x.png),
assets/images/2.0x/signin_bg.png and assets/images/onboarding_bg.jpeg.
Needs Pillow and NumPy (pip install pillow numpy).

Keep the sign-in art as PNG: JPEG/WebP re-quantize the smoothed tones and
bring the bands back. An ordered (Bayer) dither keeps the PNG small.
"""
import sys
import numpy as np
from PIL import Image

ORIG, OUT = sys.argv[1], sys.argv[2]
rng = np.random.default_rng(7)

def box_blur(a, r, axis):
    pad = [(0, 0)] * a.ndim
    pad[axis] = (r + 1, r)
    p = np.pad(a, pad, mode='edge')
    c = np.cumsum(p, axis=axis)
    hi = np.take(c, range(2 * r + 1, p.shape[axis]), axis=axis)
    lo = np.take(c, range(0, p.shape[axis] - 2 * r - 1), axis=axis)
    return (hi - lo) / (2 * r + 1)

def gauss(a, sigma):
    r = max(1, int(round(sigma)))
    for _ in range(3):  # three box passes ~ Gaussian
        a = box_blur(box_blur(a, r, 0), r, 1)
    return a

def dither(a):
    # TPDF noise in [-1, 1] LSB, then round: kills contour steps.
    shape = a.shape[:2] + (1,)
    n = rng.random(shape) + rng.random(shape) - 1.0
    return np.clip(np.round(a + n), 0, 255).astype(np.uint8)

def bayer_dither(a):
    # 8x8 ordered dither: as effective as noise, but compresses far better.
    m = np.array([[0]])
    while m.shape[0] < 8:
        m = np.block([[4 * m, 4 * m + 2], [4 * m + 3, 4 * m + 1]])
    t = (m + 0.5) / m.size
    h, w = a.shape[:2]
    t = np.tile(t, (h // 8 + 1, w // 8 + 1))[:h, :w][..., None]
    return np.clip(np.floor(a + t), 0, 255).astype(np.uint8)

def resize_float(a, size):
    chans = [np.asarray(Image.fromarray(a[..., i].astype(np.float32), 'F')
                        .resize(size, Image.LANCZOS)) for i in range(3)]
    return np.stack(chans, -1).astype(np.float64)

# Sign-in background: fully blurred art, so a broad float blur is invisible
# except that it dissolves the 8-bit steps.
master = np.asarray(Image.open(f'{ORIG}/signin_bg_2x.png').convert('RGB')).astype(np.float64)
smooth2x = gauss(master, 24)
Image.fromarray(bayer_dither(smooth2x)).save(f'{OUT}/signin_bg_2x.png', optimize=True)
smooth1x = resize_float(smooth2x, (804, 1748))
Image.fromarray(bayer_dither(smooth1x)).save(f'{OUT}/signin_bg_1x.png', optimize=True)

# Onboarding photo: deband only flat regions (|orig - blur| small), keep detail.
on = np.asarray(Image.open(f'{ORIG}/onboarding_bg.jpeg').convert('RGB')).astype(np.float64)
blur = gauss(on, 3)
diff = np.abs(on - blur).max(-1, keepdims=True)
w = np.clip((2.0 - diff) / 1.0, 0, 1)  # 1 where flat (<1 level), 0 at detail (>2)
mixed = on * (1 - w) + blur * w
Image.fromarray(dither(mixed)).save(f'{OUT}/onboarding_bg.jpeg', quality=95, subsampling=0, optimize=True)
print('done')
