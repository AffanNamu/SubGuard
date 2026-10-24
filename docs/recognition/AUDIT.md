# Recognition audit: where the errors came from

Written before the engine was rebuilt, from measurements, and updated with what
the rebuild found. Everything here was measured on **one** real booklet
photograph (`eval/dataset/booklet-001`). That is the honest limit of this audit:
see `eval/README.md`. Where a number comes from that one photograph it says so.

## What the app did before

1. Whole-photo OCR (Google ML Kit, later PaddleOCR) to find the printed labels.
2. A close-up of the exam-number area read by the same OCR engine.
3. The reading matched against the class list; a close match was **put in the
   field** as "Read automatically".
4. Marks were typed by the examiner (no handwriting reader existed).

## Measured error sources (Phase 1, `tool/bench/audit.py`, 150 readings)

Every candidate reader on every picture variant (colour, illumination-flattened,
CLAHE, Sauvola, red-ink), on the annotated field boxes, so this isolates the
*reader* from the layout step.

| field kind | reader | readings | exact (best variant) | best mean CER |
|---|---|---|---|---|
| printed number (booklet no.) | PP-OCRv4 det+rec | 5 | 1 of 5 | 0.00 |
| printed number | Tesseract 5 | 5 | 0 of 5 | 0.17 |
| registration number (handwritten) | PP-OCRv4 det+rec | 5 | **0 of 5** | 0.58 |
| registration number | Tesseract 5 | 5 | 0 of 5 | 0.92 |
| mark (handwritten, red) | PP-OCRv4 det+rec | 25 | 1 of 25 | 0.80 |
| mark | Tesseract 5 | 25 | 1 of 25 | 0.53 |
| handwritten text | PP-OCRv4 / Tesseract | 15 each | 0 of 15 | 0.83 / 0.93 |

(Raw rows: `docs/recognition/results/audit_baseline.json`. "Exact" counts the best
single picture variant; "readings" are field × variant pairs, so 5 readings is one
field in five variants.)

Findings:

* **Handwriting is not read by general OCR.** The registration number was never
  read exactly by any reader on any variant. Printed text is read.
* **The old "Read automatically" was the dangerous part.** A reading that was
  wrong in the prefix (`FWM/24U/` is the hard part) could be snapped to a
  class-list number by its last digits and entered in the field with a
  confidence badge. That is a plausible number the writing does not support. It
  is now a labelled candidate the examiner taps, and the raw reading is shown
  beside it.
* **The original exam-number crop included the handwritten title line** under the
  label (fixed earlier, commit 86e59ff).
* **Photo quality was never assessed.** A blurred or tiny photo was read as if it
  were good, and every reading from it looked as confident as any other.
* **The development photo is a small scaled copy** (810 × 1080, digit height about
  25 px, faint pink ink), cropped at the page edge. It cannot show how the engine
  behaves on full-resolution phone photographs; more authorised photos are needed.

## What the rebuild found, in the order it found it

Each of these was invisible until a test or a picture exposed it.

1. **Colour-only red-pen separation is destroyed by JPEG.** Phone JPEGs store
   colour at half resolution in blocks, so a "how red is this pixel" map of the
   marks was unreadable blocks. Taking the stroke *shape* from brightness and only
   the *decision* "is this red ink" from colour (`Enhancer.redInk`) turned the
   same cells into clean strokes and removed the printed teal rules. The two pictures of the real cells are
   `results/marks_ink_colour_only.png` (before) and
   `results/marks_ink_brightness_shaped.png` (after).
2. **A digit network trained only on distorted digits misreads clean ones.** The
   first training run applied faint-ink, grain and paper-tone to *every* picture;
   clean MNIST accuracy was 71% and 27% of clean digits were called "not a digit",
   while distorted accuracy was 88%. The app's ink maps have exactly the clean
   background it had never seen. Fixed by applying each distortion to only some
   pictures; the training script now measures clean accuracy every epoch and
   **refuses to export a model below 97%** (it exports at 97.2%).
3. **A long straight stroke looks like the digit "1" to a digit network.** The
   examiner's strike-through of unused rows was read as `1` with 100% confidence.
   Strokes longer than three character-heights, and fragmented lines found by a
   Hough transform, are removed before reading and reported ("3 long lines were
   ignored"). The first Hough version stopped at its first unsuccessful candidate
   and missed the strike-through; a test caught it.
4. **A paper level taken as the mean of the picture is biased by ink.** A blue pen
   made the paper "look red" and the red-pen map picked up blue strokes. The paper
   level is now a median-held blur.
5. **The strike-through also made the Total box "read" a 5.** Lines are now found
   over the whole table at once, so a line is removed at its full length everywhere.
6. **Handing a background isolate the pipeline hands it the platform text reader**
   (not sendable). Isolate entry points are static and take plain data.

## Where the engine stands on the real photograph

The same one photograph; read it as a smoke test, not a result.

* Picture quality: correctly flagged `text_small` and `cropped`.
* Page outline: not rectifiable (the page is cropped by the frame), so the photo is
  read as it is.
* Printed booklet number: read as 292011, at 0.76 confidence, therefore
  `needs_review` (the policy accepts printed numbers only at 0.90 with two
  agreeing variants).
* Registration number: no valid reading; a class-list candidate is offered with a
  note, the raw reading is shown, nothing is entered.
* Marks table: the four rows were found at the right place and the diagonal and
  underline ignored. Question labels read correctly for three or four of the
  four rows (it varied with small, principled changes to the ink map, which is
  itself a measure of how fragile this reading is). Marks: **one of four
  exact** (5.5); the others were read as `140`, `141` and `2.61` for `1.0`, `1.0`
  and `2.0`. Broken zeros and a raised decimal tick defeat a digit network trained
  on MNIST. Every row is `needs_review`.
* The blank Total box: seen as blank.

## What this does and does not mean

* The handwriting reader is **not** reliable enough to be trusted on its own, and
  the app does not trust it: handwritten values are never accepted automatically.
  Its value today is to find the right rows and place suggestions at the right
  spot on the photo so checking is fast.
* Improving it needs real data, not more cleverness on one photograph. Every
  confirmed booklet now yields labelled examples (the cell's region on the photo
  and the confirmed text). See `DATASET.md` and the phased plan in
  `MODEL_SELECTION.md`.
