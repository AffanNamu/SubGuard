"""Shared pieces of the recognition benchmark (Python side).

The Dart pipeline is benchmarked by `tool/bench/run_benchmark.sh` (test/bench); this side compares
candidate *recognisers* on the same ground truth, because the on-device engines
(PaddleOCR native, ML Kit) cannot run in a development sandbox but their model
families can (PP-OCR through ONNX Runtime, Tesseract).
"""
import json, os, glob, subprocess, tempfile
import cv2
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DATASET = os.path.join(ROOT, "eval", "dataset")


# ---------------------------------------------------------------- dataset ----
def load_dataset(only=None):
    docs = []
    for path in sorted(glob.glob(os.path.join(DATASET, "*", "truth.json"))):
        d = json.load(open(path))
        if only and d["doc_id"] not in only:
            continue
        d["_dir"] = os.path.dirname(path)
        d["_image"] = cv2.imread(os.path.join(d["_dir"], d["image"]))
        docs.append(d)
    return docs


def field_crop(doc, field, pad=0.0):
    img = doc["_image"]
    h, w = img.shape[:2]
    l, t, r, b = field["box"]
    pw, ph = (r - l) * pad, (b - t) * pad
    x0, y0 = max(0, int((l - pw) * w)), max(0, int((t - ph) * h))
    x1, y1 = min(w, int((r + pw) * w)), min(h, int((b + ph) * h))
    return img[y0:y1, x0:x1]


# --------------------------------------------------------------- metrics ----
def levenshtein(a, b):
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def norm(kind, s):
    s = (s or "").upper().replace(" ", "")
    if kind == "mark":
        s = s.replace(",", ".").replace("·", ".").replace("'", ".")
    return s


def score(kind, truth, read):
    t, r = norm(kind, truth), norm(kind, read)
    return {"exact": t == r, "cer": (levenshtein(t, r) / max(1, len(t))) if t else (0.0 if not r else 1.0)}


# ------------------------------------------------------------- variants ----
def upscale(img, min_h=96):
    h = img.shape[0]
    s = max(1.0, min_h / max(1, h))
    return cv2.resize(img, None, fx=s, fy=s, interpolation=cv2.INTER_CUBIC) if s > 1 else img


def gray(img):
    return cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if img.ndim == 3 else img


def v_color(c):
    return upscale(c)


def v_clahe(c):
    g = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(4, 4)).apply(gray(upscale(c)))
    return cv2.cvtColor(g, cv2.COLOR_GRAY2BGR)


def v_illum(c):
    """Divide by a heavily blurred copy: removes shadows and paper tint."""
    g = gray(upscale(c)).astype(np.float32) + 1
    bg = cv2.GaussianBlur(g, (0, 0), max(g.shape) / 6)
    out = np.clip(g / bg * 200, 0, 255).astype(np.uint8)
    return cv2.cvtColor(out, cv2.COLOR_GRAY2BGR)


def v_sauvola(c):
    g = gray(upscale(c))
    out = cv2.adaptiveThreshold(g, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 12)
    return cv2.cvtColor(out, cv2.COLOR_GRAY2BGR)


def v_red_ink(c):
    """Keeps only red/orange pen strokes (examiner marks), drops the blue form."""
    u = upscale(c)
    lab = cv2.cvtColor(u, cv2.COLOR_BGR2LAB).astype(np.float32)
    a = lab[:, :, 1]  # green..red axis
    a = (a - a.min()) / max(1e-6, a.max() - a.min())
    out = (255 - np.clip(a * 255, 0, 255)).astype(np.uint8)
    out = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(4, 4)).apply(out)
    return cv2.cvtColor(out, cv2.COLOR_GRAY2BGR)


VARIANTS = {"color": v_color, "clahe": v_clahe, "illum": v_illum, "sauvola": v_sauvola, "red_ink": v_red_ink}


# --------------------------------------------------------------- engines ----
class RapidDet:
    name = "ppocr_v4 det+rec"

    def __init__(self):
        from rapidocr_onnxruntime import RapidOCR
        self.e = RapidOCR()

    def read(self, img, kind):
        res, _ = self.e(img)
        if not res:
            return "", 0.0
        res = sorted(res, key=lambda r: (min(p[1] for p in r[0]) // 20, min(p[0] for p in r[0])))
        return " ".join(r[1] for r in res), float(np.mean([float(r[2]) for r in res]))


class RapidRec:
    name = "ppocr_v4 rec-only"

    def __init__(self):
        from rapidocr_onnxruntime import RapidOCR
        self.e = RapidOCR()

    def read(self, img, kind):
        res, _ = self.e(img, use_det=False, use_cls=False)
        if not res:
            return "", 0.0
        r = res[0]
        return (r[1], float(r[2])) if len(r) == 3 else (r[0], float(r[1]))


class Tess:
    def __init__(self, whitelist_for_marks=True):
        self.name = "tesseract 5 (eng)"
        self.wl = whitelist_for_marks

    def read(self, img, kind):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "x.png")
            cv2.imwrite(p, gray(img))
            cmd = ["tesseract", p, "-", "--psm", "7"]
            if kind == "mark" and self.wl:
                cmd += ["-c", "tessedit_char_whitelist=0123456789."]
            out = subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
        return out, 0.0


def engines():
    return [RapidDet(), RapidRec(), Tess()]
