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
  are a smoke test with the denominators shown. A rate from 1, 4 or 7 trials is not
  a rate.
* Reader: PP-OCRv4 through ONNX Runtime on a Linux x86-64 development machine with
  4 CPUs. The phone runs PP-OCRv6 through its own plugin. **Times and memory are
  not phone figures.**
* No target (such as "99% exact registration numbers") has been set or claimed.
  Targets need a baseline on representative labelled data, which does not exist yet.

## Results (7 runs: 1 original + 6 derived)

| metric | result |
|---|---|
| registration number, exact (raw reading) | 0/7 |
| registration number, read at all | 0/7 |
| registration number, right one among the candidates | 1/7 |
| registration number, top candidate right (class list of 60) | 1/7 |
| registration number, character error rate | 84 edits / 84 chars (100%): nothing valid was read |
| marks, exact with the right question | 2/28 |
| marks, right value among candidates with the right question | 2/28 |
| mark rows found at the right place | 15/28 |
| question labels read correctly | 11/28 |
| printed booklet number, exact | 5/7 (the other two: not read; none wrong) |
| written total correct (a blank box counts when blank) | 5/7 |
| whole document exact | 0/7 |
| documents needing review | 7/7 |
| fields needing review | 61/66 |
| **false acceptance** (accepted and wrong) | **0 of 5** accepted fields with ground truth |
| time per page | median 5.7 s (min 1.0, max 6.6) on this machine |
| peak resident memory | 217 MB on this machine |
| batch reliability | 2 read, 4 refused with a reason, 0 crashed, of 6 inputs |

By picture quality (one run each): clear and shadow read 1 of 4 marks exactly
(the `5.5`); every other category read none. Heavy blur is correctly judged
`poor` (blocking) and every field is `unreadable`, not guessed.

Where the time goes on the original (ms): decode 33, quality + page outline 832,
printed text 1,588, close-up readings 3,340 (three OCR calls through the Python
stand-in), marks 750, validation 18.

## What the numbers do show

* **The safety property held:** no field was accepted and wrong. Handwriting is
  never accepted; the five accepted fields were blank Total boxes that were
  blank. Every document needed review, as the policy requires today.
* **Reading failed safe:** blurred, dark and noisy variants came back
  `unreadable` or `needs_review`, never as a confident wrong number; the picture
  quality report named the cause (`blurry`, `too_dark`, `noisy`, `faint`,
  `uneven_light`, `page_not_found`).
* **Handwriting is not solved.** The registration number was never read: the
  stand-in's PP-OCR reads fragments (`L0/0538`, `Hon`). The class list recovered
  the right number once as a *candidate*, with a note, never entered. Marks: 2 of 28.
* **A batch survives bad inputs**: a corrupt file, a text file, an empty file and a
  missing file were each refused with a reason, and the good photos still read.
* The booklet number is the only thing read well, and only in 5 of 7 runs.

## What the numbers do not show

Accuracy on real exam handwriting; behaviour on full-resolution phone photographs
(the sample is an 810 × 1080 scaled copy); anything about a real phone's speed or
memory; how any of this varies across pens, examiners and lighting. The next
measurement that matters is on a larger authorised set; `DATASET.md` says what is
needed and `MODEL_SELECTION.md` the plan.
