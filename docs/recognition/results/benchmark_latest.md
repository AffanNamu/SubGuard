# Benchmark (generated)

Pipeline 1.0.0, digit model 1.0.0 (05bb539c040c…).
Reader: PP-OCRv4 via ONNX Runtime (test stand-in for PaddleOCR). Platform: linux, 4 CPUs. **Not a phone.**

**Data: 1 independent photograph(s), 11 runs (10 derived by known damage).** With this little data none of the rates below is statistically meaningful. Read the denominators.

| metric | result |
|---|---|
| registration number, exact (raw reading) | 0/11 (0%) |
| registration number, read at all | 0/11 (0%) |
| registration number, right one among candidates | 3/11 (27%) |
| registration number, top candidate right (class list of 60) | 3/11 (27%) |
| registration number, character error rate | 132 edits / 132 chars (100%) |
| marks, exact with the right question | 1/44 (2%) |
| marks, right value among candidates with the right question | 1/44 (2%) |
| mark rows found at the right place | 30/44 (68%) |
| question labels read correctly | 19/44 (43%) |
| printed booklet number, exact | 9/11 (82%) |
| written total correct (blank counts when blank) | 10/11 (91%) |
| whole document exact | 0/11 (0%) |
| documents needing review | 11/11 (100%) |
| fields needing review | 118/128 (92%) |
| false acceptance (accepted and wrong) | 0 of 10 accepted fields with ground truth |
| time per page | median 6505 ms (min 1026, max 10448) on this machine |
| peak resident memory | 316 MB on this machine |
| batch reliability | 2 read, 4 refused with a reason, 0 crashed, of 6 inputs |

## By picture quality

| category | runs | registration no. exact | mark rows found at the right place | marks exact | document exact | needing review |
|---|---|---|---|---|---|---|
| clear | 1 | 0/1 (0%) | 4/4 (100%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| blur_mild | 1 | 0/1 (0%) | 4/4 (100%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| blur_heavy | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| underexposed | 1 | 0/1 (0%) | 3/4 (75%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| noisy | 1 | 0/1 (0%) | 3/4 (75%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| faint_ink | 1 | 0/1 (0%) | 3/4 (75%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| shadow | 1 | 0/1 (0%) | 4/4 (100%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| keystone (straightened) | 1 | 0/1 (0%) | 4/4 (100%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| keystone (as taken) | 1 | 0/1 (0%) | 0/4 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| rotated_12deg (straightened) | 1 | 0/1 (0%) | 4/4 (100%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| rotated_12deg (as taken) | 1 | 0/1 (0%) | 1/4 (25%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
