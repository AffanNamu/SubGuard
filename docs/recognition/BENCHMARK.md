# Benchmark: measured results and what they mean

Reproduce: `tool/bench/run_benchmark.sh` (needs `pip install rapidocr-onnxruntime
opencv-python-headless`). It writes `results/benchmark_latest.json` (every run, every
field, every candidate) and `results/benchmark_latest.md`. The table below is that
file as of pipeline 1.0.0, digit model 1.0.0.

## Read this first

* **One** independent photograph (`eval/dataset/booklet-001`), annotated by the
  engineer who built the engine, and **the pipeline was developed while looking at
  it**. Six more runs are the same photograph with known damage applied (blur,
  noise, under-exposure, faint ink, shadow). They test how the *stages* behave;
  they add nothing about handwriting variety.
* So **none of these rates estimates accuracy on examiners' handwriting.** They
  are a smoke test with the denominators shown. A rate from 1, 4 or 11 trials is not
  a rate.
* Reader: PP-OCRv4 through ONNX Runtime on a Linux x86-64 development machine with
  4 CPUs. The phone runs PP-OCRv6 through its own plugin. **Times and memory are
  not phone figures.**
* No target (such as "99% exact registration numbers") has been set or claimed.
  Targets need a baseline on representative labelled data, which does not exist yet.

## Results (11 runs: 1 original + 10 derived)

| metric | result |
|---|---|
| registration number, exact (raw reading) | 0/11 |
| registration number, read at all | 0/11 |
| registration number, right one among the candidates | 3/11 |
| registration number, top candidate right (class list of 60) | 3/11 |
| registration number, character error rate | 132 edits / 132 chars (100%): nothing valid was read |
| marks, exact with the right question | 1/44 |
| marks, right value among candidates with the right question | 1/44 |
| mark rows found at the right place | 30/44 |
| question labels read correctly | 19/44 |
| printed booklet number, exact | 9/11 (the other two: not read; none wrong) |
| written total correct (a blank box counts when blank) | 10/11 |
| whole document exact | 0/11 |
| documents needing review | 11/11 |
| fields needing review | 118/128 |
| **false acceptance** (accepted and wrong) | **0 of 10** accepted fields with ground truth |
| time per page | median 6.5 s (min 1.0, max 10.4) on this machine |
| peak resident memory | 316 MB on this machine |
| batch reliability | 2 read, 4 refused with a reason, 0 crashed, of 6 inputs |

By picture condition (one run each; a run has four marks):

| condition | mark rows found at the right place | marks exact |
|---|---|---|
| original (clear) | 4/4 | 1/4 |
| mild blur | 4/4 | 0/4 |
| heavy blur (judged `poor`, every field `unreadable`) | 0/4 | 0/4 |
| under-exposed | 3/4 | 0/4 |
| noisy | 3/4 | 0/4 |
| faint ink | 3/4 | 0/4 |
| shadow | 4/4 | 0/4 |
| keystone, **straightened** | **4/4** | 0/4 |
| keystone, **as taken** (straightening off) | **0/4** | 0/4 |
| rotated 12°, **straightened** | **4/4** | 0/4 |
| rotated 12°, **as taken** | **1/4** | 0/4 |

Straightening is the one stage whose benefit is measured here, and it is large for
finding the table on a photograph taken at an angle. It costs about 1–2 s on this
machine. It is used only when the page is found with confidence, all four corners
are in the picture, and the page is visibly tilted or foreshortened.

Where the time goes on the original (ms): decode 33, quality + page outline 832,
printed text 1,588, close-up readings 3,340 (three OCR calls through the Python
stand-in), marks 750, validation 18.

## What the numbers do show

* **The safety property held:** no field was accepted and wrong. Handwriting is
  never accepted; the ten accepted fields were blank Total boxes that were
  blank. Every document needed review, as the policy requires today.
* **Reading failed safe:** blurred, dark and noisy variants came back
  `unreadable` or `needs_review`, never as a confident wrong number; the picture
  quality report named the cause (`blurry`, `too_dark`, `noisy`, `faint`,
  `uneven_light`, `page_not_found`).
* **Handwriting is not solved.** The registration number was never read: the
  stand-in's PP-OCR reads fragments (`L0/0538`). The class list put the right number
  among the candidates in 3 of 11 runs, with a note, never entered. Marks: 1 of 44.
* **Finding the rows is far better than reading them**: the right place in 30 of 44
  tries, against 1 of 44 values read exactly. That is why the app uses the engine to
  place suggestions beside the right part of the photo, not to fill values in.
* **A batch survives bad inputs**: a corrupt file, a text file, an empty file and a
  missing file were each refused with a reason, and the good photos still read.
* The booklet number is the only thing read well, and only in 9 of 11 runs.

## What the numbers do not show

Accuracy on real exam handwriting; behaviour on full-resolution phone photographs
(the sample is an 810 × 1080 scaled copy); anything about a real phone's speed or
memory; how any of this varies across pens, examiners and lighting. The next
measurement that matters is on a larger authorised set; `DATASET.md` says what is
needed and `MODEL_SELECTION.md` the plan.
