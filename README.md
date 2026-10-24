# UniMarkLy

Exam scores, added up for you. UniMarkLy turns a class list and a set of marks into one
result table per course, and exports it as Word, Excel, PDF or CSV. It works offline and
keeps everything on the phone.

This is build steps 1 and 2 of the Exam Score Scanner brief: **courses, grading scheme, class
list, typed score grid, and export**. Scanning booklet covers and list sheets, accounts, sync
and payments come later; the code is laid out so they can be added (see below).

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
- Light and dark themes, with a switch in Settings.
- Undo for deletes, and a bin for deleted courses.

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
    database/    drift (SQLite) schema, numbered migrations
    repositories/  the only code that reads and writes the database
  services/
    import/      CSV, Excel and paste readers; column guessing; import planning
    export/      one ResultTable model, rendered by four writers (docx, xlsx, pdf, csv)
  providers/     Riverpod providers; the grid combines scheme + students + marks
  features/      one folder per screen group
  core/          theme and shared widgets
test/            unit, database, migration, export, widget and layout tests
tool/            schema and icon generators
docs/RELEASE.md  how the store builds are made
```

## Database

Fourteen tables, as in the brief. Every table has a UUID `id`, `updated_at` and a soft-delete
`deleted_at` from the first version, so Pro sync can be added without migrating anyone's data.
Repositories set `updated_at` on every write and never hard-delete.

Two columns were added to `student` beyond the brief: `on_class_list` (false for numbers
added by hand that were not on the imported list) and `position` (the order added, used for
"scan order" in exports).

Changes go through numbered migrations. See `lib/data/database/migrations.dart`.

## Where the later steps plug in

| Step | Where it goes |
|---|---|
| Capture and review | a `features/capture/` folder; the `scan`, `booklet`, `question_mark` and `row_read` tables already exist |
| Reader | `services/reader/`, writing `question_mark` rows and `part_score` rows with `source = 'scanned'` |
| Checks across sheets | extend `domain/flags.dart` |
| Accounts and sync | a sync service reading `updated_at` / `deleted_at`; `account` and `sync_state` tables exist |
| Purchases | a service behind a provider, like the repositories |

The score grid already reads `part_score` regardless of where a value came from, so scanned
marks will appear in it with no change to the screens.
