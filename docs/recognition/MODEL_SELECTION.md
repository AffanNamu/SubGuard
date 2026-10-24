# Model selection

What was evaluated, what was not and why, and the plan for what comes next.
Nothing here is a claim about examiners' handwriting in general: the only real
photograph is one (see `DATASET.md`).

## Constraints that decide

* Fully offline on the phone; nothing downloaded silently.
* Android 8+ arm64, low-end phones included; iOS 16+.
* A wrong confident answer is worse than "I don't know": models that generate
  plausible text are a poor fit for marks and registration numbers.
* Licences must allow shipping inside the app.

## Candidates

| candidate | licence | size | on a phone | evidence here | verdict |
|---|---|---|---|---|---|
| **PP-OCRv6 small** det + rec (shipped via `paddle_ocr_native` 0.1.1, ONNX Runtime 1.21.1) | Apache-2.0 | 9,880,512 + 21,159,378 bytes | yes, offline | PP-OCRv4 via ONNX measured (`AUDIT.md`): reads printed text; registration number 0/5 exact, marks 1/25 | **kept** for printed text and close-ups. Not a handwriting reader. The package's experimental `handwrittenRows` preset has not been tried: device test |
| Google ML Kit text recognition (Latin) | Google ML Kit terms | on-device (Play services) | yes, offline | not runnable in the sandbox; not measured | **kept as printed-text fallback only**; documented as not reading handwriting |
| Tesseract 5 (eng) | Apache-2.0 | ~15 MB + native build | possible, heavy to integrate | measured: worse than PP-OCR on every field kind (`AUDIT.md`) | rejected |
| **`unimarkly-digits` v1**: small CNN, pure Dart | weights trained here on MNIST (CC BY-SA 3.0 data) | 131,564 bytes | yes, no native code, same answer on every phone | MNIST test: clean 97.2%, distorted 89.3%; distorted answered at p ≥ 0.9: 66% coverage, 99.5% correct; rejects 99.0% of junk. Dart matches PyTorch to 1e-4. **On the real cells: 1 of 4 marks exact, 3–4 of 4 question labels** | **shipped as a suggester**, never an authority |
| TrOCR (`trocr-small-handwritten`, MIT) | MIT | ~60M parameters, ~240 MB fp32 | needs an ONNX export and a mobile runtime; latency on low-end CPUs unknown | **not evaluated**: the model host was unreachable from the build sandbox | candidate for phase B; trained on English prose lines, so digits and registration-number formats are out of domain and it can output fluent wrong text |
| Document VLMs (Florence-2, Qwen2-VL, SmolVLM, PaliGemma …) | various | 0.5–2 B parameters, 1–4 GB | memory and latency prohibitive on low-end Android | **not evaluated** | rejected for on-device use: size, and they generate plausible text, which is the failure this project forbids |
| Digit network fine-tuned on real exam handwriting | ours | same size as v1 | yes | **cannot be done yet**: no labelled real data beyond one photograph | the main route to real accuracy; see plan |
| NNAPI / GPU delegates | — | — | — | not used: nothing here is compute-bound enough to need them; CPU is the baseline | revisit only if a measured model needs it |

## Why the digit network is a pure-Dart CNN

It runs in a few hundredths of a millisecond a character, needs no native
library, behaves identically on every phone, and is small enough to ship, verify
by SHA-256 and test against PyTorch to 1e-4. Its limits are the training data
(MNIST, US writers) and the segmentation in front of it (broken zeros and a raised
decimal tick on the real photograph defeat it). Those are data problems, not
architecture problems.

## Plan, in phases

**A. Done:** conservative engine; quality gate; layout and row finding; MNIST
digit suggester; human review with evidence; labelled examples captured on every
confirmation.

**B. Needs data and a decision from the product owner:**
1. Collect authorised full-resolution booklet photographs with confirmed values
   (see `DATASET.md`); build an export of consenting examiners' labelled examples.
2. Re-run `tool/bench/run_benchmark.sh` on the larger set; report with denominators.
3. Evaluate TrOCR-small (ONNX, int8) and a fine-tuned digit network on that set,
   on a real low-end Android phone, for accuracy, latency and memory.
4. Only then consider `autoAcceptHandwriting` for a field, per field, with a
   calibration report whose false-acceptance rate is committed beside the change.

**C. If the data never comes:** the engine stays a fast, honest assistant: it finds
the rows, places suggestions at the right spot and flags what is wrong with the
photo. That is useful, and it is what is claimed.

## What would change this table

A measured result on a real low-end phone and on a labelled set of at least a few
hundred booklets. Until then, no phone figure and no handwriting-accuracy figure
should be quoted.
