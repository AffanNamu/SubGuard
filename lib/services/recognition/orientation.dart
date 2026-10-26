import '../../domain/ocr.dart';
import '../reader/booklet_extractor.dart';

/// Turning a booklet photographed sideways or upside down.
///
/// A phone's own rotation flag is honoured when the photo is decoded. This is for
/// a photo whose pixels really are turned: the booklet lying across the frame, or
/// a picture taken with the phone held the wrong way up and no flag set.
///
/// The booklet layout is found from printed labels in their usual places, so a
/// page turned the wrong way round finds few of them, or finds them in the wrong
/// order. When that happens, or when most of the text runs up or down the picture,
/// the photo is read again turned each other way, and a turn is kept only when
/// it finds the labels, in the right order, clearly better than the photo as
/// taken. It is never a guess: a wrongly turned page does not produce the labels.
///
/// A photo that already reads as an upright booklet costs no extra reading.
class PageOrientation {
  const PageOrientation._();

  /// Fewer printed labels than this found, and the other turns are tried.
  static const minAnchors = 3;

  /// A turn must beat the photo as taken by at least this much
  /// ([BookletReading.layoutScore]) to be kept.
  static const minGain = 2;

  /// Whether the photo as taken looks as though it might be the wrong way round:
  /// too few labels found, labels found in the wrong order, or most of the text
  /// running up or down the picture.
  static bool suspect(BookletReading reading, OcrDocument doc, int width, int height) =>
      reading.foundAnchors.length < minAnchors || reading.layoutContradictions > 0 || verticalTextShare(doc, width, height) >= 0.5;

  /// Whether [turned] (the photo read turned) is clearly the better reading of
  /// the booklet than [asTaken].
  static bool better(BookletReading turned, BookletReading asTaken) =>
      turned.foundAnchors.length >= minAnchors && turned.layoutContradictions == 0 && turned.layoutScore >= asTaken.layoutScore + minGain;

  /// Lines shorter than this are not used to judge which way the text runs (a
  /// lone digit is as tall as it is wide whichever way round it is).
  static const _minLineChars = 4;

  /// The region [r] on a picture that was turned clockwise by [quarters]
  /// quarter-turns, as a region of the picture before it was turned.
  ///
  /// Both are fractions of their own picture's width and height, so a sideways
  /// turn (which swaps the picture's width and height) needs no sizes.
  static Region unturn(Region r, int quarters) {
    switch (quarters % 4) {
      case 1:
        return Region(r.top, 1 - r.right, r.bottom, 1 - r.left);
      case 2:
        return Region(1 - r.right, 1 - r.bottom, 1 - r.left, 1 - r.top);
      case 3:
        return Region(1 - r.bottom, r.left, 1 - r.top, r.right);
      default:
        return r;
    }
  }

  /// The region [r] on a picture, as a region of that picture turned clockwise
  /// by [quarters] quarter-turns.
  static Region turn(Region r, int quarters) => unturn(r, 4 - quarters % 4);

  /// Of the lines that have enough text to tell, the share running up or down
  /// the picture (taller than wide, as the picture really is).
  static double verticalTextShare(OcrDocument doc, int width, int height) {
    var tall = 0, counted = 0;
    for (final l in doc.lines) {
      if (l.text.replaceAll(RegExp(r'\s'), '').length < _minLineChars) continue;
      counted++;
      if (l.box.height * height > l.box.width * width) tall++;
    }
    return counted == 0 ? 0 : tall / counted;
  }

  /// The turns to try, most likely first. Text running up or down the picture
  /// means the booklet is on its side; otherwise it is most likely upside down.
  /// Every turn is still tried when the first fails: this only saves work.
  static List<int> candidates(OcrDocument doc, int width, int height) =>
      verticalTextShare(doc, width, height) >= 0.5 ? const [1, 3, 2] : const [2, 1, 3];

  /// What to tell the examiner about a turn.
  static String describe(int quarters) => switch (quarters % 4) {
        1 => 'The booklet was photographed on its side (the top of the page is on the left), so the photo was turned upright before reading.',
        3 => 'The booklet was photographed on its side (the top of the page is on the right), so the photo was turned upright before reading.',
        2 => 'The photo is upside down, so it was turned upright before reading.',
        _ => '',
      };
}
