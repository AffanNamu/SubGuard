# Device checks for opening documents from other apps

These need a real Android phone and a real iPhone. The code is built and unit-tested in CI; nothing
here has been run on a device yet, so none of these formats may be called supported until its row passes.

Install the Android build from the "Android release" run (Artifacts), or the iOS build from TestFlight.
Make these files first (the app's own exports work): a results PDF, DOCX, XLSX and CSV; a class list CSV
and XLSX; a photo of a booklet cover; a `.doc` and `.xls`; a password-protected PDF and DOCX; a text file
renamed `.pdf`; a 150 MB file.

| # | Do | Expect | Android | iOS |
|---|----|--------|:---:|:---:|
| A | Files app → tap the PDF → choose UniMarkLy (iOS: Share → UniMarkLy) | UniMarkLy is offered; the PDF shows; pinch zooms; page buttons work | | |
| B | Same with the DOCX, from Downloads, e-mail and a chat app | Opens as text with its table | | |
| C | Same with XLSX and CSV | Grid shows; "Use as class list" opens the import screen; nothing is added until "Add to class list" | | |
| D | Open the booklet photo | "Scan this booklet" starts the scan screen with that photo | | |
| E | Repeat A with UniMarkLy (1) open on Home, (2) in the background, (3) swiped away | Opens each time, once | | |
| F | Open: `.doc`, `.xls`, locked PDF/DOCX, fake `.pdf`, 150 MB file; open the same file twice quickly | Each says what is wrong, no blank screen; one screen for the double open; the app stays responsive | | |
| G | Upload, scan, review, export as before | All still work | | |
| H | Open the PDF of booklet pages → "Scan its pages as booklets" | Pages become photos in a new upload | | |

Also check on Android that, after choosing "Always" for another app, UniMarkLy is still in the list
under "Open with". Report any row that fails with the file used and the phone model.

## Recognition on a device

Nothing about the recognition pipeline has been measured on a phone. Until these are filled in, no
phone speed, memory or accuracy figure should be quoted. Use a low-end Android phone (the weakest you
support: record its model, RAM and Android version) and a recent iPhone. Use full-resolution photographs
(not scaled copies), at least ten booklets from different examiners.

| # | Do | Record | Android | iOS |
|---|----|--------|:---:|:---:|
| R1 | Add 1 photo; time from "added" to "needs review" | seconds per page (PaddleOCR close-ups included) | | |
| R2 | Add 30 photos in one batch | total time; whether the app stayed responsive; photos read / failed | | |
| R3 | During R2, watch memory (Android Studio profiler / Xcode) | peak resident memory | | |
| R4 | Kill the app during R2, reopen | interrupted photos re-queued and read; none lost | | |
| R5 | Airplane mode on, repeat R1 | still reads; no network request | | |
| R6 | Review 10 booklets against the photos | per booklet: how many fields needed typing; exam number read at all? marks right? | | |
| R7 | Photograph one booklet badly (blur, dark, glare, far away) | the quality notice names the fault and says what to do | | |
| R8 | Try `PaddleOcrConfig.handwrittenRows()` for the close-ups | whether the exam number is read better than with the current config | | |
| R9 | Rotate the phone and use font scale 1.3 on the review screen | nothing cut off; "Show on photo" works with pinch zoom | | |
| R10 | Photograph one booklet lying on its side, and one upside down (a phone that does not set the rotation flag, or a booklet turned on the desk) | the app turns it upright (a note says so); the photo viewer shows it upright; extra seconds per page | | |
| R11 | Type an exam number and two marks on a booklet, kill the app, reopen the booklet | the entries come back with a notice; "Discard them" clears them; nothing reached the score grid before Confirm | | |

Report each row with the photos (if authorised) and the phone model. Rows R6 and R8 are what decide the
next step in `docs/recognition/MODEL_SELECTION.md`.
