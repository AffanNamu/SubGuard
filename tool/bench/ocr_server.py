"""A development stand-in for the on-device PaddleOCR reader.

The Dart pipeline runs its OcrEngine interface against this process in tests, so
the whole pipeline can be exercised in a sandbox with a real PP-OCR model
(rapidocr-onnxruntime: PP-OCRv4 detection and recognition through ONNX
Runtime). The phone uses paddle_ocr_native (PP-OCRv6); the model family is the
same, the version is newer, so phone numbers can differ either way.

Protocol: one JSON object per line on stdin, {"path": "/abs/file.png"};
one JSON line back: {"width": W, "height": H, "lines": [{"text", "left", "top",
"right", "bottom", "confidence"}]} with boxes as fractions of the picture.
"""
import json, sys
import cv2
from rapidocr_onnxruntime import RapidOCR

engine = RapidOCR()
print("ready", flush=True)
for raw in sys.stdin:
    raw = raw.strip()
    if not raw:
        continue
    req = json.loads(raw)
    img = cv2.imread(req["path"])
    if img is None:
        print(json.dumps({"error": "unreadable", "width": 0, "height": 0, "lines": []}), flush=True)
        continue
    h, w = img.shape[:2]
    res, _ = engine(img)
    lines = []
    for box, text, conf in res or []:
        xs = [p[0] for p in box]
        ys = [p[1] for p in box]
        lines.append({"text": text, "left": min(xs) / w, "top": min(ys) / h, "right": max(xs) / w,
                      "bottom": max(ys) / h, "confidence": float(conf)})
    lines.sort(key=lambda l: (round(l["top"] * 50), l["left"]))
    print(json.dumps({"width": w, "height": h, "lines": lines}), flush=True)
