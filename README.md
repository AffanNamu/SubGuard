# UniMarkLy

Exam scores, added up for you. UniMarkLy turns a class list and a set of marks into one
result table per course, and exports it as Word, Excel, PDF or CSV. It works offline and
keeps everything on the phone.

Build steps 1 and 2 of the Exam Score Scanner brief (courses, grading scheme, class list, typed
score grid, export) are done, and the **photo workflow** is in: upload booklet photos, read the
printed parts on the phone, check every value against the photo, confirm, and the exam score
lands in the grid and the exports. Handwriting is **not** read automatically yet (see
"What it does not do").

## What works now

- **Courses** with a setup wizard in plain words and a running total at the top
  ("Exam 70 + Attendance 10 + Assignment 10 + Test 10 = 100").
  Every number is editable at any time; warnings guide and nothing is blocked.
  - Parts you can rename, add, remove and reorder, each with a maximum, minimum, optional
    pass mark, step (1, 0.5, 0.25), "marked out of / counts for" scaling, and a source.
  - Exam paper: number of questions, a maximum for each, compulsory questions, and a counting
    rule (all answered, best N, or compulsory plus best N). Warns when the questions cannot
    reach the Exam maximum.
  - Grade scale: editable ranges, letters and points. The Nigerian scale is built in.
  - Saved templates. The Nigerian default (Exam 70 + 30 for the other parts) is built in.
- **Class list** import from CSV, Excel (.xlsx) or pasted text, with a column-matching step and
  a summary before anything is written. Numbers are tidied up as they come in
  (`244` becomes `24U`).
- **Typed score grid** with totals and grades calculated as you type, a number pad with a
  `.5` key, "enter by number" with class-list checking, and import of Attendance, Assignment
  and Test from CSV or Excel.
- **Checks**, all taken from the course's own scheme: registration number against
  `DEPT/YYU/NNNN` (with an optional extra middle part) and the class list; duplicates; marks
  below the minimum or above the maximum; marks off the step; totals above the maximum.
  They are shown, never enforced.
- **Export** to `.docx`, `.xlsx`, `.pdf` and `.csv` with a column chooser and three presets
  (Exam sheet, Continuous assessment sheet, Full result). Several courses can be exported
  at once, one file each, through the phone's share sheet.
- **Home** with real numbers counted from stored uploads (batches, students extracted,
  completed, need review), recent batches with a course filter, and a raised upload button.
- **Scan & Extract**: take a photo, choose several, or pick image files (JPG, PNG, WebP, HEIC).
  Originals are kept untouched in the app folder with a content fingerprint; the same photo
  twice is caught and you are asked. A progress screen shows each photo's real state, with
  pause, and photos left half-read when the app closes are picked up again.
- **Review**: for each booklet the photo's exam-number crop, marks crop and total crop sit
  beside the fields. Nothing reaches the score grid until you press Confirm; confirming a
  second booklet for the same student, or the same booklet number again, needs an explicit OK.
  Marks above a question's maximum, a written total that disagrees with the marks, and an
  exam number that is not on the class list are all shown. Confirmed records are never
  overwritten by a later re-read, and corrections are logged for training.
- Light and dark themes, with a switch in Settings.
- Undo for deletes, and a bin for deleted courses.

## What it does not do (yet)

- It does **not** read handwriting. The reader (Google ML Kit text recognition, on the phone,
  no internet) finds the printed labels and the printed booklet number and works out where the
  handwritten exam number and marks are, but those are typed in by the examiner from the photo
  crops. A handwriting model is the next step; until then nothing handwritten is ever filled
  in for you, and anything the reader does suggest is marked with its confidence and needs
  your tap.
- PDF input is not supported.
- Accounts, sync and purchases do not exist; Settings says so.
- The ML Kit reader, camera and gallery pickers have only been exercised through the test
  doubles in CI. They need a run on a real phone.

## Running it

Flutter 3.32 (the version the CI uses).

```
flutter pub get
flutter run
flutter test
flutter analyze
```

## Layout

```
lib/
  domain/        Pure Dart: the grading scheme, totals, grades, registration numbers, checks.
                 No Flutter and no database, so it is easy to test.
  data/
    database/    drift (SQLite) schema, step-by-step migrations (see drift_schemas/)
    repositories/  the only code that reads and writes the database
  services/
    import/      CSV, Excel and paste readers; column guessing; import planning
    scan/        picking, storing and fingerprinting photos
    reader/      the OCR engine interface, the booklet extractor, the processing queue
    export/      one ResultTable model, rendered by four writers (docx, xlsx, pdf, csv)
  providers/     Riverpod providers; the grid combines scheme + students + marks
  features/      one folder per screen group
  core/          theme and shared widgets
test/            unit, database, migration, export, widget and layout tests
tool/            schema and icon generators
docs/RELEASE.md  how the store builds are made
```

## Database

Fifteen tables: the fourteen in the brief plus `upload_batch`. Every table has a UUID `id`, `updated_at` and a soft-delete
`deleted_at` from the first version, so Pro sync can be added without migrating anyone's data.
Repositories set `updated_at` on every write and never hard-delete.

Beyond the brief: `student.on_class_list` (false for numbers added by hand that were not on
the imported list), `student.position` (the order added, used for "scan order" in exports),
the `upload_batch` table, and on `scan`: `batch_id`, `original_name`, `content_hash`, `width`,
`height`, `error_message`.

Schema changes are step-by-step migrations checked against dumps in `drift_schemas/`
(`tool/generate_schema.sh` regenerates them). Version 2 added the upload tables and
columns; a test upgrades a version 1 database full of data and checks nothing is lost.

## Where the later steps plug in

| Step | Where it goes |
|---|---|
| Handwriting reading | a second `OcrEngine` in `services/reader/`; the extractor already hands it the regions and keeps results as suggestions with a confidence |
| Checks across sheets | extend `domain/flags.dart` |
| Accounts and sync | a sync service reading `updated_at` / `deleted_at`; `account` and `sync_state` tables exist |
| Purchases | a service behind a provider, like the repositories |
