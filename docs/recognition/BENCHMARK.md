# Benchmark: measured results and what they mean

Reproduce: `tool/bench/run_benchmark.sh` (needs `pip install rapidocr-onnxruntime
opencv-python-headless`). It writes `results/benchmark_latest.json` (every run, every
field, every candidate) and `results/benchmark_latest.md`. The table below is that
file as of pipeline 1.2.1 (question numbers and marks as separate, rule-checked suggestions; `QUESTION_MARKS.md`), digit model 1.0.0.

## Read this first

* **One** independent photograph (`eval/dataset/booklet-001`), annotated by the
  engineer who built the engine, and **the pipeline was developed while looking at
  it**. Sixteen more runs are the same photograph with known changes applied: damage
  (blur, noise, under-exposure, faint ink, shadow), placement at an angle, and turning
  it a quarter, a half and three quarters round. They test how the *stages* behave;
  they add nothing about handwriting variety. **The turned variants are exact (lossless)
  turns, and the pipeline reads them exactly as it reads the upright photo, so they
  repeat the same four marks: the pooled "marks exact" rate is the original photo's
  1 of 4 counted six times (the upright photo, the three turned ones, and the
  straightened keystone and rotated ones), not a better reader.**
* So **none of these rates estimates accuracy on examiners' handwriting.** They
  are a smoke test with the denominators shown. A rate from 1, 4 or 11 trials is not
  a rate.
* Reader: PP-OCRv4 through ONNX Runtime on a Linux x86-64 development machine with
  4 CPUs. The phone runs PP-OCRv6 through its own plugin. **Times and memory are
  not phone figures.**
* No target (such as "99% exact registration numbers") has been set or claimed.
  Targets need a baseline on representative labelled data, which does not exist yet.

## Results (17 runs: 1 original + 16 derived)

| metric | result |
|---|---|
| registration number, exact (raw reading) | 0/17 |
| registration number, read at all | 0/17 |
| registration number, right one among the candidates | 6/17 |
| registration number, top candidate right (class list of 60) | 6/17 |
| registration number, character error rate | 204 edits / 204 chars (100%): nothing valid was read |
| marks, exact with the right question | 6/68 (the original: 1/4; see the note above) |
| marks, right value among candidates with the right question | 10/68 |
| mark rows found at the right place | 42/68 |
| question labels read correctly | 31/68 |
| mark rows where the true mark is among the suggestions shown | 10/42 |
| mark rows where the true mark is the first suggestion | 10/42 |
| mark rows with no mark suggested (the examiner is asked to enter it) | 32/42 |
| rows where the first suggested question number is right | 31/42 |
| **suggested marks that break the rules** (above the maximum, off the step) | **0 of 28** |
| printed booklet number, exact | 12/17 (the other five: not read; none wrong) |
| written total correct (a blank box counts when blank) | 13/17 |
| whole document exact | 0/17 |
| documents needing review | 17/17 |
| fields needing review | 141/154 |
| **false acceptance** (accepted and wrong) | **0 of 13** accepted fields with ground truth |
| time per page | median 7.4 s (min 1.3, max 10.5) on this machine; see the note on timings below |
| peak resident memory | 369 MB on this machine |
| batch reliability | 2 read, 4 refused with a reason, 0 crashed, of 6 inputs |

By picture condition (one run each; a run has four marks):

| condition | mark rows found at the right place | marks exact |
|---|---|---|
| original (clear) | 4/4 | 1/4 |
| mild blur | 4/4 | 0/4 |
| heavy blur (judged `poor`, every field `unreadable`) | 0/4 | 0/4 |
| under-exposed | 3/4 | 0/4 |
| noisy | 4/4 | 0/4 |
| faint ink | 3/4 | 0/4 |
| shadow | 3/4 | 0/4 |
| keystone, **straightened** | **4/4** | 1/4 |
| keystone, **as taken** (straightening off) | **0/4** | 0/4 |
| rotated 12°, **straightened** | **4/4** | 1/4 |
| rotated 12°, **as taken** | **1/4** | 0/4 |
| photographed top to the right, **turned upright** | **4/4** | 1/4 |
| photographed top to the right, **read as taken** (orientation off) | **0/4** | 0/4 |
| photographed upside down, **turned upright** | **4/4** | 1/4 |
| photographed upside down, **read as taken** | **0/4** | 0/4 |
| photographed top to the left, **turned upright** | **4/4** | 1/4 |
| photographed top to the left, **read as taken** | **0/4** | 0/4 |

Straightening is the one stage whose benefit is measured here, and it is large for
finding the table on a photograph taken at an angle. It costs about 1–2 s on this
machine. It is used only when the page is found with confidence, all four corners
are in the picture, and the page is visibly tilted or foreshortened.

Orientation correction (`ARCHITECTURE.md`, stage 3c) is the other stage whose benefit is
measured: a booklet photographed on its side or upside down is found nowhere as taken
(0 of 4 rows) and everywhere once turned (4 of 4, and the same values as the upright
photo). It costs 0.8–1.9 s here, only on a photo that looks wrong; the upright photo
pays nothing for it.

Where the time goes on the original (ms): decode 12, quality + page outline 379,
printed text 751, close-up readings 1,593 (three OCR calls through the Python
stand-in), marks 343, validation 8. On the photo turned a quarter: orientation
1,871 (three extra readings of the whole page; the half-turn and the other quarter
need only two), the rest as above. These timings were
taken on a different machine load from the earlier table in this file's history, so do not
compare them with it; they are not phone figures either. This run's median per page
(7.4 s) is higher than the earlier table's (2.8 s) on the same photographs. I have not
investigated why: this development machine is shared and its load varies, and the
per-stage figures above are from the earlier run.

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
  among the candidates in 6 of 17 runs, with a note, never entered. Marks: 1 of 4 on the
  original photo (the pooled 6 of 68 repeats it).
* **Finding the rows is far better than reading them**: the right place in 42 of 68
  tries (4 of 4 on every straightened or turned variant), against 6 of 68 values read
  exactly (the same photo's 1 of 4 repeated). That is why the app uses the engine to
  place suggestions beside the right part of the photo, not to fill values in.
* **Suggestions follow the rules, and say nothing rather than guess:** of the 41 rows
  found, 32 are offered no mark at all (the examiner is asked to enter it, with the
  raw reading and the reason it was left out shown as evidence). The other 10 rows
  are offered 28 mark values between them, and none is above the question's maximum
  or off the step: **0 of 28 break the rules.** In all 10 of those rows the true mark
  is among the values offered, and first in each; 10 of 42 rows overall. Before this change the same photo produced `147`, `141`,
  `140`, `2.61` and a fifth row from a pen stroke; those are the failures this
  measures against (`QUESTION_MARKS.md`). The question numbers offered first are right
  in 31 of 42 rows. All of this is the one photograph again.
* **A batch survives bad inputs**: a corrupt file, a text file, an empty file and a
  missing file were each refused with a reason, and the good photos still read.
* The booklet number is the only thing read well, and only in 12 of 17 runs.

## What the numbers do not show

Accuracy on real exam handwriting; behaviour on full-resolution phone photographs
(the sample is an 810 × 1080 scaled copy); anything about a real phone's speed or
memory; how any of this varies across pens, examiners and lighting. The next
measurement that matters is on a larger authorised set; `DATASET.md` says what is
needed and `MODEL_SELECTION.md` the plan.
