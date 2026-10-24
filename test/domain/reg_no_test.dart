import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/reg_no.dart';

void main() {
  group('RegNo.normalise', () {
    test('accepts DEPT/YYU/NNNN as written', () {
      final r = RegNo.normalise('FWM/24U/0538');
      expect(r.canonical, 'FWM/24U/0538');
      expect(r.isValid, isTrue);
      expect(r.wasCorrected, isFalse);
    });

    test('accepts the optional extra middle part', () {
      expect(RegNo.normalise('FST/25U/244/5772').isValid, isTrue);
      expect(RegNo.normalise('ASR/25U/224/0937').canonical, 'ASR/25U/224/0937');
    });

    test('upper-cases and trims', () {
      expect(RegNo.normalise('  fwm/24u/0538 ').canonical, 'FWM/24U/0538');
    });

    test('accepts spaces, hyphens and backslashes as separators', () {
      for (final raw in ['FWM 24U 0538', 'FWM-24U-0538', r'FWM\24U\0538', 'FWM / 24U / 0538']) {
        expect(RegNo.normalise(raw).canonical, 'FWM/24U/0538', reason: raw);
      }
    });

    test('repairs a U that was written like a 4', () {
      final r = RegNo.normalise('FWM/244/0538');
      expect(r.canonical, 'FWM/24U/0538');
      expect(r.isValid, isTrue);
      expect(r.wasCorrected, isTrue);
    });

    test('repairs the U in a number that has a middle part', () {
      final r = RegNo.normalise('FST/254/244/5772');
      expect(r.canonical, 'FST/25U/244/5772');
    });

    test('never touches a genuine middle part that looks like a year', () {
      expect(RegNo.normalise('FST/25U/244/5772').canonical, 'FST/25U/244/5772');
    });

    test('repairs a U written as V or W', () {
      expect(RegNo.normalise('FWM/24V/0538').canonical, 'FWM/24U/0538');
      expect(RegNo.normalise('FWM/24W/0538').canonical, 'FWM/24U/0538');
    });

    test('adds a missing U', () {
      expect(RegNo.normalise('FWM/24/0538').canonical, 'FWM/24U/0538');
    });

    test('adds missing slashes in the compact form', () {
      expect(RegNo.normalise('FWM24U0538').canonical, 'FWM/24U/0538');
      expect(RegNo.normalise('FWM2444538').canonical, 'FWM/24U/4538');
    });

    test('reads letters written for digits in the number', () {
      expect(RegNo.normalise('FWM/24U/O538').canonical, 'FWM/24U/0538');
      expect(RegNo.normalise('FWM/24U/05S8').canonical, 'FWM/24U/0558');
    });

    test('reads digits written for letters in the department', () {
      expect(RegNo.normalise('F0M/24U/0538').canonical, 'FOM/24U/0538');
    });

    test('pads a short number to four digits', () {
      final r = RegNo.normalise('FWM/24U/538');
      expect(r.canonical, 'FWM/24U/0538');
      expect(r.isValid, isTrue);
    });

    test('flags what it cannot repair, and keeps a clean best effort', () {
      final r = RegNo.normalise('hello world');
      expect(r.isValid, isFalse);
      expect(r.canonical, 'HELLO/WORLD');
      expect(RegNo.normalise('').isValid, isFalse);
      expect(RegNo.normalise('FWM/24U/05381').isValid, isFalse);
      expect(RegNo.normalise('F/24U/0538').isValid, isFalse);
    });

    test('key() is stable for the same student written two ways', () {
      expect(RegNo.key('fwm 244 0538'), RegNo.key('FWM/24U/0538'));
    });
  });

  group('RegNo.nearest', () {
    const list = ['FWM/24U/0538', 'FWM/24U/0539', 'FWM/24U/0640', 'ASR/25U/224/0937'];

    test('returns the closest numbers first, at most three', () {
      final s = RegNo.nearest('FWM/24U/0537', list);
      expect(s.map((e) => e.regNo), ['FWM/24U/0538', 'FWM/24U/0539']);
      expect(s.first.distance, 1);
    });

    test('exact match has distance zero', () {
      expect(RegNo.nearest('FWM/24U/0538', list).first.distance, 0);
    });

    test('returns nothing when nothing is close', () {
      expect(RegNo.nearest('XYZ/20U/9999', list), isEmpty);
    });

    test('limits the number of suggestions', () {
      final many = List.generate(10, (i) => 'FWM/24U/050$i');
      expect(RegNo.nearest('FWM/24U/0500', many, maxDistance: 3).length, 3);
    });
  });
}
