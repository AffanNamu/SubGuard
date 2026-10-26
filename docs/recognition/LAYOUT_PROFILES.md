# Booklet layouts

A **layout** says where to look on one kind of booklet cover. UniMarkLy ships with one
(the Modibbo Adama University exam booklet) and can read another cover from a layout
*file*, with no change to the app. Settings → **Booklet layout** chooses the layout in use,
adds a file, shares a copy of one, and removes one the administrator added.

A layout is only about **finding** things: the printed labels, and from them the regions
where the exam number, the marks table, the total and the "questions answered" line are.
It does not change how handwriting is read, or the rule that handwriting is never accepted
without the examiner (`POLICY.md`). Photos are read with the layout in use when they are
read; each stored reading records which layout (id, name, revision) read it.

## Starting a new layout

1. Settings → Booklet layout → ⋮ on the built-in layout → **Share a copy of this file**.
   (The same file is `docs/recognition/layouts/modibbo_adama.json`.)
2. Edit it for the other cover: its printed labels, and where its regions are.
3. Give it its own `id` (the built-in id cannot be replaced) and raise `revision` each time
   you change it.
4. **Add a layout file**, then choose it. Every file is checked first; a refusal names the
   setting and says what is wrong (`regions.marks.variants[0].bottom.ref: uses "grand",
   which is not in this variant's "needs"`).
5. Photograph a few covers and look at where "Show on photo" outlines the exam number and
   the marks. A layout is only as good as how the regions land on real photos: measure them.

`docs/recognition/layouts/example_left_table.json` is a second, invented layout (marks table
on the left, matric number top right) used by the tests.

## The file

JSON, at most 64 KB. Positions are fractions of the photo's width and height, from the top
left (0 to 1). Unknown settings are refused, not ignored.

```json
{
  "schema": 1,
  "id": "faculty-x-cover",
  "name": "Faculty X script cover",
  "description": "Optional, shown under the name",
  "revision": 1,
  "anchors": [ … ],
  "relations": [ … ],
  "regions": { … },
  "serial": { … },
  "institution": { … }
}
```

### `anchors`: the printed labels

```json
{"key": "total", "name": "Total", "words": ["total"], "where": {"left": {"gt": 0.5}, "top": {"gt": 0.6}}}
```

* `key`: what regions and relations call it (`a`–`z`, digits, `_`; up to 24 characters).
* `name`: what the examiner is told when it is found or missing.
* `words`: lower-case letters of a word on the label (3–20 letters, no spaces). A line matches
  when it contains **any** of them, allowing for the odd wrong or missing letter.
* `where`: optional tests on the line's box. Positions: `left`, `top`, `right`, `bottom`,
  `centerX`, `centerY`. Tests: `gt`, `gte`, `lt`, `lte`. All must hold.
* `pick`: `"first"` (default) or `"lowest"` (the matching line lowest on the page).
* `reported`: `false` for a label that only places a region and whose absence is not a
  fault in the photo. At least one label must be reported.

### `relations`: how labels sit relative to each other

```json
{"a": "question", "rule": "left_of_same_row", "b": "marks", "tolerance": 0.03}
```

Rules: `left_of_same_row` (`a` left of `b`, centres within `tolerance`), `below`, `above`
(entirely), `higher` (centre higher up). These are what tell an upright page from one
photographed on its side or upside down: a label can be found "somewhere in the left half"
on a turned page, but not in the right order. A relation counts only when both labels were
found. **Give a layout at least two relations**, or orientation correction has little to go on
(`ARCHITECTURE.md`, stage 3c).

### `regions`

Keys: `exam_number`, `question_column`, `marks` (**required**), `total`, `answered`. Each has
`variants`, tried in order; the first whose `needs` labels were all found is used. Each
variant gives `left`, `top`, `right`, `bottom` as an expression:

| expression | meaning |
|---|---|
| `0.96` | that position |
| `{"ref": "total.top", "offset": -0.004}` | an edge (`left`, `top`, `right`, `bottom`, `centerX`, `centerY`) of a label in `needs`, moved by `offset` (−0.5 to 0.5) |
| `{"max": [0.3, {"ref": "exam_label.right"}]}` | the larger (or `min`, the smaller) of 2–6 expressions |

Regions are clamped to the page. `answered` may also have `"readsAs"`, a pattern the
handwritten line of question numbers inside it must match.

**Patterns** (`readsAs`, `serial.pattern`) are at most 80 characters and are checked against
every line of text the reader finds, so they are kept to a plain subset: characters,
classes such as `\d` and `[A-Z]`, and repeats such as `{5,8}`. A repeat applied to a group
(`(a+)+`), a back-reference and look-ahead/look-behind are refused, because a pattern like
that can make the app hang on a short line of text.

### `serial` and `institution` (optional)

```json
"serial": {"pattern": "^\\d{5,8}$", "where": {"top": {"lte": 0.2}, "centerX": {"gte": 0.5}}},
"institution": {"word": "university", "where": {"top": {"lt": 0.1}}}
```

`serial` is the printed booklet number (digits that match the pattern, in the area `where`
gives); it also catches the same booklet photographed twice. `institution` is the heading
that names the university. Finding either counts as evidence the page is the right way up.

## What is checked, and what is not

* Checked on adding: JSON syntax and size, schema number, id and name, every key and
  setting name, every number's range, that relations and regions only name labels that
  exist, that a region only measures from labels it `needs`, that patterns compile, and that
  the `marks` region exists.
* **Not** checked: that the regions are *right* for the cover. Nothing can know that without
  photographs of it. A wrong layout reads the wrong part of the page (the examiner sees it
  because "Show on photo" outlines it) or finds no labels (the review screen says so).
* Not supported by a layout: a different number of marks per row, a table with several
  columns of marks, a cover with the marks table across two pages. Those need code.

## Tests

`test/services/layout_profile_test.dart`: the built-in profile reads 400 randomly damaged
OCR readings, and the real ones, exactly as the hard-coded reader it replaced did (the old
reader is kept in `test/support/legacy_extractor.dart` for this comparison); every kind of
bad file is refused with the right message; the example layout is read from a drawn page
with the real digit network, upright and on its side. `test/ui/layout_settings_test.dart`:
the screen, the choice being remembered, and the choice reaching the pipeline.
