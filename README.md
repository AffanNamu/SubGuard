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
  beside the fields, and "Show on photo" outlines a field's place on the whole photo, zoomed.
  What the machine read is offered as **suggestions to tap** (each says whether it was read from
  the photo or came from the class list, with a note on how), each field carries a state chip
  (Read / Check this / Not readable / Reading failed) and "How this was read" lists every attempt.
  **Nothing handwritten is entered for you.** A photo the quality check says is unusable says
  so first, with what to do. Nothing reaches the score grid until you press Confirm; confirming a
  second booklet for the same student, or the same booklet number again, needs an explicit OK.
  Marks above a question's maximum, a written total that disagrees with the marks (both numbers
  kept, never "corrected"), and an exam number that is not on the class list are all shown. The
  waiting list says why each booklet is waiting. Confirmed records show what the machine read
  beside what you confirmed, are never overwritten by a later re-read, and every decision is
  stored with its time as a labelled example. **Settings → Training examples** counts them
  and, only when you say the people concerned agree, packs them into a file to share.
- **Unconfirmed entries are kept**: what you typed on a booklet and have not confirmed comes back,
  with a notice and a "Discard them" button, if you leave the booklet or the app closes. A draft
  is never a result; only Confirm reaches the score grid.
- **Sideways and upside-down photos are turned upright for reading.** The booklet's printed labels
  must appear in the right places and the right order, so a turn is only made on evidence; the
  photo viewer then shows the photograph upright (the file is never changed). On the one real
  photograph, in all four orientations, the mark rows were found 4 of 4 times once turned and
  0 of 4 as taken.
- **Another booklet cover is another file.** Settings → Booklet layout chooses which layout photos
  are read with, adds a layout file (checked before it is used), and shares the built-in one as a
  starting point. See `docs/recognition/LAYOUT_PROFILES.md`. Only the Modibbo Adama cover has been
  tested on real photographs; a new layout must be checked against photographs of its own cover.
- Light and dark themes, with a switch in Settings.
- Undo for deletes, and a bin for deleted courses.

## Opening documents from other apps

UniMarkLy is offered in the phone's "Open with" and share lists for PDF, Word (`.docx`, `.doc`),
Excel (`.xlsx`, `.xls`), CSV, and JPEG, PNG, WebP and HEIC photos. It never claims to be the default
for any of them; the phone's own chooser decides.

- **Android** (`AndroidManifest.xml`, `MainActivity.kt`, `IncomingFiles.kt`): `VIEW`, `SEND` and
  `SEND_MULTIPLE` filters for those MIME types only. A document arrives as a `content://` address;
  it is streamed into a private copy in the app cache (never a shared folder, never a file path),
  the name is made safe, over 200 MB is refused, and `file://` addresses are refused. The
  activity is `singleTask` so a running app receives the document instead of starting a second one.
- **iOS** (`Info.plist`, `AppDelegate.swift`): document types with rank *Alternate* and
  "open in place". The file's security-scoped URL is read with file coordination (so a file in iCloud
  Drive downloads first) and copied to a private temporary folder. Photos shared from the Photos app
  do not appear (that needs a Share Extension, which is not built); photos from Files do.
- **In the app** (`lib/features/incoming`, `lib/services/incoming`): the file is checked from its bytes,
  not just its name. Then it is shown: PDF with zoom and page controls (the phone's own PDF engine);
  Word as text (headings, bold and italic, bullets, tables; pictures and layout are not drawn); Excel and
  CSV as a scrollable grid with sheet tabs (first 5,000 rows shown). Old `.doc` and `.xls`, locked, damaged,
  empty, unsupported and oversized files each say what is wrong and offer "Open in another app" and
  "Save a copy". A held-up document shows "Opening…"; a document that started the app is opened once
  the app is up; the same document delivered twice opens once.
- **Next steps depend on the file, and viewing never changes data.** A table can be used as a class list
  or as scores, which opens the existing import screen, where columns are matched and nothing is written
  until you press its button. A photo, or the pages of a PDF, can start the scan workflow. "Save a copy"
  keeps a file in Settings, Saved documents (the same bytes are never stored twice and a different file is
  never replaced). The original is only ever read.

Checked in tests: the file checks, all three readers on files UniMarkLy itself writes, every screen above
at six phone sizes, and the Android copying code on a plain JVM (Robolectric, run by the Android workflow).
**Not yet checked on a real phone:** that Android and iOS actually offer UniMarkLy, that the system PDF
engine draws pages, and the iOS copying code (it is only compiled). The list of device checks is in
`docs/DEVICE_TESTS.md`.

## What it does not do (yet)

- **Handwriting is not reliably read, and the app does not pretend it is.** Printed text is read
  by PaddleOCR (PP-OCR) on the phone, with no internet, and ML Kit as a fallback. Marks are read
  by a small digit network (`assets/models/digits_v1.bin`, 128 KB, trained on MNIST); on the one
  real photograph available it read 1 of 4 marks exactly, and the handwritten exam number was
  not read at all. So handwritten values are **suggestions the examiner checks**, never
  accepted automatically. Real accuracy needs labelled examples from real booklets; the app now
  records them on every confirmation. See `docs/recognition/` (AUDIT, BENCHMARK, MODEL_SELECTION).
- No accuracy figure can be given: the evaluation set is one photograph. No phone speed or memory
  figure can be given either: the pipeline has not been measured on a phone.
- PDF input is not supported.
- Accounts, sync and purchases do not exist; Settings says so.
- The PaddleOCR and ML Kit readers, camera and gallery pickers have only been exercised through the test
  doubles in CI. They need a run on a real phone.

## Running it

Flutter 3.44 or newer (CI uses 3.44.9); the PaddleOCR package needs it. Phones: Android 8+ on a
64-bit ARM CPU, iOS 16+ on a real device (the PaddleOCR libraries have no simulator build).

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
    recognition/ the recognition pipeline: stages as interfaces, marks table, validation, models
    vision/      pure-Dart image work: quality, page outline, ink separation, lines, digit network
    export/      one ResultTable model, rendered by four writers (docx, xlsx, pdf, csv)
  providers/     Riverpod providers; the grid combines scheme + students + marks
  features/      one folder per screen group
  core/          theme and shared widgets
test/            unit, database, migration, export, widget, layout and recognition tests
tool/            schema and icon generators; train/ (the digit model); bench/ (the benchmark)
eval/            the evaluation dataset (read eval/README.md)
docs/RELEASE.md  how the store builds are made
docs/recognition/ how recognition works, what it was measured at, and what is not known
```

## Database

Seventeen tables: the fourteen in the brief plus `upload_batch`, `recognition_run` and `field_review`. Every table has a UUID `id`, `updated_at` and a soft-delete
`deleted_at` from the first version, so Pro sync can be added without migrating anyone's data.
Repositories set `updated_at` on every write and never hard-delete.

Beyond the brief: `student.on_class_list` (false for numbers added by hand that were not on
the imported list), `student.position` (the order added, used for "scan order" in exports),
the `upload_batch` table, and on `scan`: `batch_id`, `original_name`, `content_hash`, `width`,
`height`, `error_message`.

Schema changes are step-by-step migrations checked against dumps in `drift_schemas/`
(`tool/generate_schema.sh` regenerates them). Version 2 added the upload tables and
columns; version 3 added `recognition_run` (what the pipeline found, kept as produced) and
`field_review` (what the examiner decided about each field, with when); version 4 added
`review_draft` (entries typed on a booklet and not yet confirmed, so an interrupted review
is not lost; never read by the grid or an export). Tests upgrade old databases full of data
and check nothing is lost.

## Where the later steps plug in

| Step | Where it goes |
|---|---|
| Handwriting reading | a second `OcrEngine` in `services/reader/`; the extractor already hands it the regions and keeps results as suggestions with a confidence |
| Checks across sheets | extend `domain/flags.dart` |
| Accounts and sync | a sync service reading `updated_at` / `deleted_at`; `account` and `sync_state` tables exist |
| Purchases | a service behind a provider, like the repositories |
