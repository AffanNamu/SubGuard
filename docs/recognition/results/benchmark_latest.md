# Benchmark (generated)

Pipeline 1.2.1, digit model 1.0.0 (05bb539c040c…).
Reader: PP-OCRv4 via ONNX Runtime (test stand-in for PaddleOCR). Platform: linux, 4 CPUs. **Not a phone.**

**Data: 1 independent photograph(s), 17 runs (16 derived by known damage).** With this little data none of the rates below is statistically meaningful. Read the denominators.

| metric | result |
|---|---|
| registration number, exact (raw reading) | 0/17 (0%) |
| registration number, read at all | 0/17 (0%) |
| registration number, right one among candidates | 6/17 (35%) |
| registration number, top candidate right (class list of 60) | 6/17 (35%) |
| registration number, character error rate | 204 edits / 204 chars (100%) |
| marks, exact with the right question | 6/68 (9%) |
| marks, right value among candidates with the right question | 10/68 (15%) |
| mark rows found at the right place | 42/68 (62%) |
| question labels read correctly | 31/68 (46%) |
| mark rows where the true mark is among the suggestions shown | 10/42 (24%) |
| mark rows where the true mark is the first suggestion | 10/42 (24%) |
| mark rows with no mark suggested (the examiner is asked to enter it) | 32/42 (76%) |
| rows where the first suggested question number is right | 31/42 (74%) |
| suggested marks that break the rules (above the maximum, off the step) | 0 of 28 |
| printed booklet number, exact | 12/17 (71%) |
| written total correct (blank counts when blank) | 13/17 (76%) |
| whole document exact | 0/17 (0%) |
| documents needing review | 17/17 (100%) |
| fields needing review | 141/154 (92%) |
| false acceptance (accepted and wrong) | 0 of 13 accepted fields with ground truth |
| time per page | median 7439 ms (min 1313, max 10465) on this machine |
| peak resident memory | 369 MB on this machine |
| batch reliability | 2 read, 4 refused with a reason, 0 crashed, of 6 inputs |

## By picture quality

| category | runs | registration no. exact | mark rows found at the right place | marks exact | document exact | needing review |
|---|---|---|---|---|---|---|
| clear | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| blur_mild | 1 | 0/1 (0%) | 4/4 (100%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| blur_heavy | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| underexposed | 1 | 0/1 (0%) | 3/4 (75%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| noisy | 1 | 0/1 (0%) | 4/4 (100%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| faint_ink | 1 | 0/1 (0%) | 3/4 (75%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| shadow | 1 | 0/1 (0%) | 3/4 (75%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| keystone (straightened) | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| keystone (as taken) | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| rotated_12deg (straightened) | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| rotated_12deg (as taken) | 1 | 0/1 (0%) | 1/4 (25%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| photographed top to the right (turned upright) | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| photographed top to the right (read as taken) | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| photographed upside down (turned upright) | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| photographed upside down (read as taken) | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| photographed top to the left (turned upright) | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| photographed top to the left (read as taken) | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
