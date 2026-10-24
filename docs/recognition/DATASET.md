# Dataset, ground truth and the learning loop

## What exists today

`eval/dataset/booklet-001`: **one** photograph of one real booklet cover,
supplied by the product owner for development, annotated by the engineer who built
the engine (not independently double-annotated). It is the only independent
photograph in the evaluation set. Everything measured on it is a development
smoke test. No claim about accuracy on examiners' handwriting in general can be
made from it, and none is made.

Its registration number is a real candidate's. Confirm authorisation before the
repository or the photograph is shared outside the product owner's control.

## Format

```
eval/dataset/<doc_id>/image.jpg      the photograph, unmodified
eval/dataset/<doc_id>/truth.json     ground truth
```

`truth.json` (schema 1): `doc_id`, `image`, `source`, `authorisation`, `annotator`,
`split` (`dev`, `test`; a document is never in two splits), `quality_category`,
`layout`, `fields[]` (`key`, `kind`, `text` or null for blank, `box` as fractions
of the photograph, `question` for marks) and `totals`.

Rules for adding documents:

1. Only photographs the owner is authorised to use. Record the authorisation.
2. **Split by document**, never by field or by variant. A photograph's derived
   variants stay in its split.
3. Protect personal data: do not commit names; registration numbers only where
   the authorisation covers it.
4. Annotate from the photograph, not from the machine's reading. A second person
   should annotate independently and disagreements be resolved and recorded.
5. Cover the spread that matters: different examiners, pens (red, blue, black),
   lighting, tilt, blur, and quality categories (`clear`, `faint_ink`, `blurred`,
   `dark`, `glare`, `cropped`, `small`).

## Derived variants

`test/support/degrade.dart` applies known damage (blur, noise, under-exposure,
faint ink, shadow, glare) to a photograph. These measure how the **stages** behave
under damage whose size is known. They are not independent documents and say
nothing new about handwriting variety.

## The learning loop

Every time an examiner confirms a booklet, `field_review` records, per field, the
machine's value, the final value, the decision and its time, and the field's region
on the photograph. `RecognitionRepository.labelledExamples()` returns those with a
region as (photo, region, confirmed text) triples: the raw material for measuring
the reader and, later, fine-tuning it.

Not done, on purpose: nothing retrains on its own; nothing leaves the phone by
itself. **Settings → Training examples** shows how many confirmed values are kept and
makes a zip (a cropped picture of each piece of handwriting, `labels.json` with the
confirmed text, what the machine had read and what the examiner decided, and a
README) only when the examiner ticks that the people concerned agree and presses
Export; the examiner then shares the file. The crops are pictures of real handwriting
and, for exam numbers, real registration numbers.

## Asking for data

To turn this from a smoke test into a measurement, the project needs, from
authorised sources, full-resolution phone photographs (not scaled copies) of
booklets from several examiners, with the confirmed values. Order of magnitude
needed before any threshold is calibrated: hundreds of booklets, tens of
examiners. That is a rule of thumb, not a measured requirement.
