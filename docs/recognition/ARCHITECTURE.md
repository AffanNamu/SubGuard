# Recognition architecture

How UniMarkLy reads a photographed examination booklet, entirely on the phone,
and what it does and does not claim about the result.

**The rule everything else follows:** a value read by a machine is a *suggestion*.
It is kept apart from what an examiner has confirmed, it carries the evidence it
came from, and it never becomes a record, a score or an export row until the
examiner confirms it. When the machine is unsure it says so and shows the photo;
it never fills in a plausible number.

## The pipeline

`BookletPipeline` (`lib/services/recognition/booklet_pipeline.dart`) runs these
stages on one photograph. Every stage is an interface
(`lib/services/recognition/interfaces.dart`), so it can be replaced on its own.

| # | Stage | What it does | Interface → implementation |
|---|-------|--------------|----------------------------|
| 1 | Intake guard | file exists, under 40 MB, decodes, under 12,000 px a side; decoded once at ≤ 2,400 px | `PipelineLimits` |
| 2 | Quality assessment | blur, noise, exposure, ink contrast, shadow, glare, text size, tilt, perspective, page cropped — each with a plain message and an instruction ("retake…") | `DocumentQualityAnalyzer` → `QualityAnalyzer` |
| 3 | Page outline | 2-means paper mask → hull → four corners; confidence and "fully visible" | `DocumentBoundaryDetector` → `PageDetector` |
| 3b | Straightening | when the page is found with confidence, all four corners are in the picture, and it is visibly tilted (≥ 2°) or foreshortened (≥ 6°), it is warped to a rectangle and everything after reads the straightened page; regions are mapped back onto the original photograph | `PageStraightener` (`straighten.dart`) |
| 4 | Printed text | whole-photo text with boxes | `PrintedTextRecognizer` (= `OcrEngine`) → PaddleOCR PP-OCRv6 on the phone |
| 5 | Layout | where the exam number, marks table, total and answered line are, found from the printed labels (so tilt and zoom matter less) | `LayoutAnalyzer` → `BookletExtractor` |
| 6 | Close-ups | the printed booklet number and the handwritten exam number re-read at higher magnification, in more than one picture variant | `RegionOcrEngine` |
| 7 | Marks table | one ink picture over the whole table (brightness shape, red-pen colour gate); strike-throughs and underlines removed (Hough transform); rows found from the ink; each mark and question label read character by character | `HandwritingRecognizer` → `MarkReader` + digit network |
| 8 | Validation | marks against question maxima, the mark step, the part maximum; the written total against the sum; the "questions answered" line; duplicate or unreadable rows | `ExaminationValidator` → `SchemeExaminationValidator` |
| 9 | Field states | each field is `recognized`, `needs_review`, `unreadable` or `failed` | `FieldConfidencePolicy` → `RecognitionPolicy` |

Not done: the orientation of a page photographed sideways or upside down is not corrected (a phone's rotation flag is honoured when the photo is decoded), and a page cropped by the frame is read as it is, not straightened.

Heavy stages (2, 3, 3b, 7) run in background isolates; the platform text reader is
called through its own channel. Nothing blocks the UI thread. Photos are read one
at a time on purpose: a phone cannot hold several full-size photos in memory.

### What a field carries

`ExtractedField` (`lib/domain/recognition.dart`): key, kind, **state**, value,
**candidates** (each with its source and, where relevant, a note on how it was
reached), raw confidence, **region** on the original photo (fractions of its width
and height), **attempts** (reader, reader version, picture variant, text,
confidence), and warnings. `calibratedConfidence` stays empty: no labelled set large
enough exists to calibrate one, and the code does not pretend otherwise.

### Per-field policy (`docs/recognition/POLICY.md`)

* Handwriting (exam number, marks, question labels, the answered line) is **never**
  `recognized` by the machine. Agreement between two picture variants of the same
  photograph read by the same model is evidence of stability, not an independent
  check, so it does not change that.
* A printed value is `recognized` only when two variants agree *and* the reader's
  confidence is at least 0.90 and nothing warns about it.
* A blank Total box is `recognized` with no value: blank is a finding, not a read.
* A blocking picture-quality fault caps every field at `needs_review`.

### The class list is a constraint on interpretation, in the open

A registration number close to exactly one class-list number is offered as that
number *beside* what was read, with a note ("the only class-list number within 1
character of what was read"). It is never entered for the examiner. When the
reading is equally close to two class-list numbers, none is offered and the screen
says so.

## What is stored

Schema v3 adds two tables and changes none (`drift_schemas/drift_schema_v3.json`,
migration tested from v2 with data in it):

* `recognition_run` — one row per run: pipeline version, status, duration, and the
  machine's output exactly as produced (fields, quality report, findings, models,
  timings, notes). Never edited. A photo read again adds a row.
* `field_review` — what the examiner decided about each field when confirming, with
  when: `accepted`, `suggestion` (another of the machine's candidates), `edited`,
  `entered`, `rejected` or `blank`; the machine's value and state beside the final
  value; and the field's region. Each row with a region is a **labelled example**
  (`RecognitionRepository.labelledExamples`) — the data needed to measure and later
  improve the reader. Nothing is retrained silently.

Originals are never changed. The booklet's confirmed marks and the score grid are
written only by `BookletRepository.confirm`, in one transaction with the reviews.
Exports read the grid, so **only confirmed values are ever exported**.

## Failure handling

* A photo that cannot be processed at all (missing, too large, not a picture) is
  marked failed with the reason; the batch carries on.
* A stage that fails leaves its fields `failed` (not guessed) and a note says why.
* A missing or damaged handwriting model is a `failed` marks field with the reason
  ("Reinstall UniMarkLy, or enter the marks by hand"). It does not fall back to
  another reader. Model files are verified by size and SHA-256 before use.
* An interrupted app re-queues photos that were mid-read; a confirmed booklet is
  never overwritten by re-reading.
* Pausing stops after the photo in hand; the rest stay queued.

## Models, sizes, licences

| Model | Used for | Size | Licence |
|-------|----------|------|---------|
| PP-OCRv6 small detection (bundled by `paddle_ocr_native` 0.1.1, ONNX Runtime 1.21.1) | printed text, close-up readings | 9,880,512 bytes | Apache-2.0 |
| PP-OCRv6 small recognition (same package) | printed text, close-up readings | 21,159,378 bytes | Apache-2.0 |
| `unimarkly-digits` v1.0.0 (`assets/models/digits_v1.bin`) | handwritten digits in the marks table | 131,564 bytes | weights trained here on MNIST (CC BY-SA 3.0 data); attribute MNIST |
| Google ML Kit text recognition (Latin) | printed-text fallback only | on-device, via Google Play services | Google ML Kit terms |

Nothing is downloaded at run time. No image or text leaves the phone.

## Supported devices

Android 8.0+ (API 26), arm64; iOS 16+, physical device. Pure-Dart stages need no
native library. **Not measured on any phone yet:** peak memory and latency of the
whole pipeline on a low-end Android device. `docs/DEVICE_TESTS.md` lists what to
measure; until it has been, no figure for a phone should be quoted.

## Replacing a stage

Implement the interface and hand it to `BookletPipeline`:

```dart
BookletPipeline(
  ocr: myEngine,                       // any OcrEngine
  digits: loadedModel,                 // verified weights
  quality: MyQualityAnalyzer(),        // DocumentQualityAnalyzer
  boundary: MyPageDetector(),          // DocumentBoundaryDetector
  layout: MyDepartmentLayout(),        // LayoutAnalyzer
  policy: RecognitionPolicy(...),      // only loosened with a calibration report
);
```

`ScanProcessor` depends only on `RecognitionOrchestrator`, so the whole pipeline
can be swapped as well.
