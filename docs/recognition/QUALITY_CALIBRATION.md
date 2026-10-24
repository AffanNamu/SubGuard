# Picture-quality thresholds

`QualityAnalyzer` (`lib/services/vision/quality.dart`) measures a photograph and
says, in words, what is wrong and what to do. Thresholds are in
`QualityThresholds`. They were set from controlled damage applied to **one**
photograph (`test/vision/quality_calibration_test.dart` prints the measurements).
They are starting points, not settled values: they have never been checked against
a set of real good and bad photographs.

| measurement | warns | blocks ("retake") | how measured |
|---|---|---|---|
| long side | < 1000 px | < 600 px | stored file |
| sharpness (edge acutance of text-bearing tiles; ≈ 0.4 / σ of blur) | < 0.50 | < 0.30 | noise-robust: Laplacian variance was inflated by noise (9.9 at σ = 10) and was replaced |
| noise (Immerkaer estimate, grey levels) | > 12 | > 30 | separate from sharpness |
| dark clipping | > 18% | > 55% (or 98th percentile < 64) | |
| bright clipping | > 25% | — | |
| shadow ratio across the page | > 1.30 | — | |
| glare (bright blob fraction) | > 0.4% | > 3% | |
| ink contrast (per-tile, not page-dependent) | < 0.20 | < 0.12 | |
| text height | < 16 px | — | median printed-text height in original pixels |
| tilt | > 4° | — | projection-profile variance |
| perspective | > 18° | — | page corner departure from a right angle |
| page cropped | warns | — | a corner is within the frame edge |

What is measured against known damage: blur, noise, exposure, faint ink, shadow
and glare ladders, page-outline error 0.6–2.0% of the diagonal on placed copies,
skew within 0.6°. What is not: any of it on photographs other than the one.

A blocking fault does not stop reading; it caps every field at "needs review" and
tells the examiner to retake the photo, with the instruction.
