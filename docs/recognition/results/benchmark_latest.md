# Benchmark (generated)

Pipeline 1.0.0, digit model 1.0.0 (05bb539c040c…).
Reader: PP-OCRv4 via ONNX Runtime (test stand-in for PaddleOCR). Platform: linux, 4 CPUs. **Not a phone.**

**Data: 1 independent photograph(s), 7 runs (6 derived by known damage).** With this little data none of the rates below is statistically meaningful. Read the denominators.

| metric | result |
|---|---|
| registration number, exact (raw reading) | 0/7 (0%) |
| registration number, read at all | 0/7 (0%) |
| registration number, right one among candidates | 1/7 (14%) |
| registration number, top candidate right (class list of 60) | 1/7 (14%) |
| registration number, character error rate | 84 edits / 84 chars (100%) |
| marks, exact with the right question | 2/28 (7%) |
| marks, right value among candidates with the right question | 2/28 (7%) |
| mark rows found at the right place | 15/28 (54%) |
| question labels read correctly | 11/28 (39%) |
| printed booklet number, exact | 5/7 (71%) |
| written total correct (blank counts when blank) | 5/7 (71%) |
| whole document exact | 0/7 (0%) |
| documents needing review | 7/7 (100%) |
| fields needing review | 61/66 (92%) |
| false acceptance (accepted and wrong) | 0 of 5 accepted fields with ground truth |
| time per page | median 5724 ms (min 1007, max 6570) on this machine |
| peak resident memory | 217 MB on this machine |
| batch reliability | 2 read, 4 refused with a reason, 0 crashed, of 6 inputs |

## By picture quality

| category | runs | registration no. exact | marks exact | document exact | needing review |
|---|---|---|---|---|---|
| clear | 1 | 0/1 (0%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
| blur_mild | 1 | 0/1 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| blur_heavy | 1 | 0/1 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| underexposed | 1 | 0/1 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| noisy | 1 | 0/1 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| faint_ink | 1 | 0/1 (0%) | 0/4 (0%) | 0/1 (0%) | 1/1 (100%) |
| shadow | 1 | 0/1 (0%) | 1/4 (25%) | 0/1 (0%) | 1/1 (100%) |
