# Question numbers, marks and the total

How a booklet's marks table becomes a confirmed result, and what the app does and does not
claim at each step. The rule from `POLICY.md` still holds: **a machine reading is a
suggestion, kept apart from what the examiner has confirmed.** This document is about four
things that were being mixed up, and how they are kept apart.

## Four different things

| | where it is on the booklet | what it is in the app |
|---|---|---|
| the **question number** | the Question column, written by the examiner ("Q-4") | a whole number, confirmed per row |
| the **mark** | the Marks column ("2.0") | a decimal, confirmed per row |
| the **attempted-questions list** | bottom left ("4, 5, 1, 2") | evidence only: compared with the marks, never added to them |
| the **total** | the Total box, often blank | two separate numbers: *calculated* (from the confirmed marks) and *written* (what the examiner wrote, if recorded) |

They are separate fields everywhere: in the pipeline's output (`question_row_N` beside
`mark_row_N`), in the review screen, and in the database.

## What was wrong (audit, from the real photograph)

Measured on `eval/dataset/booklet-001` (Q1 1.0, Q2 1.0, Q4 2.0, Q5 5.5, blank Total):

* The handwritten "1·0" has a *raised* dot. The reader took the dot for a digit, so row 1
  came back as `147`, with `187`, `140`, `180` offered beside it as alternatives, and row 2
  as `141`. Those are digit strings, not marks, and they were shown as tappable chips.
* The end of the examiner's strike-through survived as a fifth "row" and was read as `24`.
* A course with no question list was shown Q1 to Q6 whether or not they existed, and
  "Add a question" counted on from the last number without any evidence.
* The setup stepper made Q1..Qn (to 30) and could not make a paper with Q1, Q2, Q4, Q5.

There was no literal list of 100 questions in the code. The behaviours above are what produced
long lists of invented numbers and implausible marks, and all of them are gone.

## What changed

### Reading (`MarkReader`, `marks_stage.dart`)

* A **raised dot** is a decimal point when it is a small narrow blob standing *between two
  digit-sized characters* (about half the height of the digits). A blob at the start or end of
  a mark is not a point. **No point is ever added** where there was no dot: two digits with
  nothing between them are reported as such ("No decimal point was seen between the digits;
  none has been added").
* A flat stroke (far wider than tall) is not a digit, whatever the network says about it.
* A pen stroke left below the last row, a fraction of the size of the writing, is not a row.
  It is reported in the notes and left out.

On the real photograph: four rows, not five; row 1 reads as three characters, the middle one
a point (`1 . 7`, with `0` as the network's second choice for the last).

### Suggestions (`RowSuggestions`, `MarkRules`, `QuestionRules`)

For each row the app builds **two** lists of alternatives, one for the question number and one
for the mark. An alternative is offered only if it can be what it claims to be, judged by the
course's own scheme:

* a **mark** is a number of up to three digits and two decimals, no more than the question's
  maximum (or the exam's, when the question is not on the list), and a multiple of the exam
  part's step. `147` and `141` fail (above 70). `2.61` fails (not a multiple of 0.5). A reading
  with a `?` fails.
* a **question number** is a whole number from 1 to the *highest question number* setting
  (Settings; 60 until changed).

A reading that fails is **not repaired** (no decimal point inserted, nothing rounded or pulled
into range) and **not hidden**: it stays in "How this was read" with the reason ("Not offered as
a mark: "147" (147 is above the most this can be (70))"). The mark is never used to guess the
question number, or the question number to guess the mark.

When nothing can be offered the card says: *"Unable to read this mark confidently. Please
check the photograph and enter the correct mark."* (and the same for the question number).

On the real photograph the examiner is offered: Q1 → `1.0` (and a weak `9.0`), Q5 → `5.5`;
nothing for rows 2 and 3 (their readings, `141` and `2.61`, are not marks); question numbers
1, 2, 4 and 5 for the four rows. See `results/benchmark_latest.md` for the measured rates.

### The review screen (`MarkRecordCard`, `MarkSheet`)

One card per row the machine found, plus one for each question the examiner adds. Each card has:

* the crop of the row (question and mark cells) and *Show on photo*;
* **Question number**: the confirmed value (tap to type), and *below it, in its own band*,
  "Suggested question number (not confirmed)" with the alternatives as chips;
* **Mark**: the same, separately;
* *Use these suggestions* (confirms the top suggestion for each field not yet confirmed,
  only when the examiner taps it), *Not a mark* (takes the row out of everything; it can be put
  back), and, for added questions, *Remove*;
* "How this was read": what each cell was read as, what was left out and why.

A row is **confirmed** when both fields are. Until then it does not count in the total and
Confirm waits (a row with no question number, a row with no mark, two rows with the same
question number). There is no fixed list: the cards are the rows found and the questions the
examiner added. Questions on the course's list that have no card are shown as chips ("On this
paper and not marked. They count as zero. Tap one to add its mark").

### The total (`ExamTally`, `TotalComparison`)

The **calculated total** is worked out from the confirmed marks only, and recalculated on every
change: confirming, correcting, clearing, dismissing or adding a mark.

* each question counts once; a number given twice counts its first mark and is reported;
* a mark counts as `mark × weight` (weight 1 unless the course says otherwise);
* the **counting rule** decides what is added: all, the best N, or compulsory plus the best N of
  the rest. Marks left out by the rule are listed, never dropped silently. Ties are settled by
  question number so the answer is always the same;
* a question on the list with no mark adds nothing; whether that is acceptable is the course's
  rule for **a question with no mark**: *counts as zero* (default) or *ask me about each one*
  (each needs a mark, 0 if none, before Confirm);
* whatever had to be assumed is written under the total ("Q3 on the paper has no mark and
  counts as zero", "no question list, so every question you confirmed is counted").

The **written total** is what the examiner wrote in the Total box, recorded only if they choose
to. A blank Total box is normal and changes nothing. When both exist they are compared; if they
differ the card says so with the size of the difference and **neither is changed**.

The total card shows: calculated total (of the exam maximum), the counting rule and the most the
questions can add (when the course has a question list), anything still unresolved, the
assumptions, the written total and how it compares.

Scaling ("marked out of / counts for") is a property of the exam *part* and is applied by the
score grid when it adds parts up, as before; the calculated total here is the raw exam score.

### What is stored (schema v5)

| table | new |
|---|---|
| `question_mark` | `recognised_mark`, `recognised_question` (what the reader returned, apart from the confirmed `mark`), `max_mark`, `status` (`accepted`, `suggestion`, `edited`, `entered`), `region`, `question_region` (where on the photograph) |
| `booklet` | `calculated_total` (derived; can always be recomputed), `written_total` (null when none recorded), `max_total`, `total_notes` (the assumptions) |
| `exam_question` | `weight` |
| `course` | `unmarked_rule` |

The migration (v4 → v5) adds columns only; every existing row keeps its values, new columns are
empty or take the previous behaviour as their default (weight 1, unmarked counts as zero). A
booklet confirmed before v5 opens with its marks as added questions (they had no place on the
photograph recorded) and its total computed from them.

## Limits, stated plainly

* Handwriting reading is still weak. On the one real photograph, 2 of the 4 marks are offered
  correctly (1.0 and 5.5) and 2 are not offered at all; the question numbers are all right. That
  is one photograph. No rate for real examiners' handwriting can be claimed.
* The plausibility rules decide what can be *offered*; they do not make a reading right. A weak
  alternative that passes the rules (like `9.0` for a `1`) is still shown, below the better one,
  and still needs the examiner to tap it.
* The highest question number (60 by default) is a safety limit on what the app accepts, set in
  Settings. It is not a list of questions.
* The review crops of a booklet photographed sideways are not yet turned upright (the full-photo
  viewer and the training export are).
