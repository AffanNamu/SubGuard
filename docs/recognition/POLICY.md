# When a machine reading may be trusted

The rule: **uncertain means "check this", never a plausible guess.** Policy lives
in one place, `RecognitionPolicy` (`lib/domain/recognition.dart`), and is
deliberately conservative. Loosening anything needs a calibration report on
labelled data, with its numbers, committed in the same change.

## Field states

| state | meaning |
|---|---|
| `recognized` | supported by enough visual evidence under a validated threshold |
| `needs_review` | a reading exists but is ambiguous, inconsistent or not yet validated |
| `unreadable` | not enough ink or detail to offer any reading |
| `failed` | the pipeline could not process the field (an error, not a judgement) |

## Rules in force

| field | rule |
|---|---|
| handwritten (registration number, marks, question labels, answered line) | **never** `recognized` by the machine. `autoAcceptHandwriting` is false and is not loosened until a calibration set exists |
| printed booklet number | `recognized` only if at least two picture variants agree, confidence ≥ 0.90, no warnings |
| blank Total box | `recognized` with no value ("blank" is a finding); capped to `needs_review` when picture quality is blocking |
| any field when picture quality is blocking | at most `needs_review` |
| a field with a validation warning | at most `needs_review` |
| no reading and no ink | `unreadable` |
| a stage that threw | `failed`, with the reason |

**Agreement is not proof.** Two picture variants of one photograph read by the
same model are correlated; their agreement is shown as evidence of stability and
changes nothing about handwriting.

**Confidence is not a probability.** `rawConfidence` is the reader's own score.
`calibratedConfidence` is empty on purpose: calibrating needs labelled data this
project does not yet have. The review screen never shows a percentage as if it
were the chance of being right.

## Constrained decoding, and what is not done

* The registration-number pattern (`DEPT/YYU/NNNN`) and the common letter/digit
  confusions (`O`↔`0`, …) are used to tidy a reading, and the candidate says what
  was changed.
* The class list is used as a constraint on interpretation **in the open**: a
  reading within two characters of exactly one class-list number, or whose last
  digits match exactly one, is offered as that number beside the raw reading with
  a note. It is never entered for the examiner and never replaces the raw
  reading. A reading equally close to two class-list numbers offers neither.
* A mark is read character by character. **No decimal point is inserted** when
  none was seen; an unreadable character is `?`, and a reading with a `?` is shown
  as partial, never as a number.
* A validator never rewrites a mark. A handwritten sum of 38 against a written
  total of 36 keeps both numbers and raises a discrepancy.

## What the examiner sees

Every field has a state chip. Handwriting is offered as tappable suggestions with
their source ("read from the photo", "from the class list"). The photo part is
beside the field; "Show on photo" outlines the field's place on the whole photo,
zoomed. Confirmed values are marked "Confirmed by you" and show what the machine
read beside what was confirmed.
