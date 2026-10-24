import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/services/export/result_table.dart';

import '../support/fixtures.dart';

void main() {
  final f = Fixture();

  ResultTable build(ExportOptions o, {ExportHeader header = const ExportHeader()}) =>
      ResultTableBuilder.build(
        course: f.course,
        students: f.students,
        scores: f.scores,
        options: o,
        header: header,
      );

  List<String> titles(ResultTable t) => t.columns.map((c) => c.title).toList();
  List<String> row(ResultTable t, int i) => t.rows[i].map((c) => c.text).toList();

  final schemes = [f.course.scheme];

  group('presets', () {
    test('Exam sheet: Exam filled, the other columns blank', () {
      final t = build(ExportOptions.preset(ExportPreset.examSheet, schemes));
      expect(titles(t), ['S/N', 'Registration No.', 'Exam', 'Attendance', 'Assignment', 'Test', 'Total']);
      expect(row(t, 0), ['1', 'FWM/24U/0538', '9.5', '', '', '', '']);
      expect(row(t, 1), ['2', 'FST/25U/244/5772', '58', '', '', '', '']);
    });

    test('Continuous assessment sheet: Exam and Total blank', () {
      final t = build(ExportOptions.preset(ExportPreset.continuousAssessment, schemes));
      expect(row(t, 0), ['1', 'FWM/24U/0538', '', '4', '3.5', '5.0', '']);
      expect(row(t, 1), ['2', 'FST/25U/244/5772', '', '9', '8.0', '9.5', '']);
    });

    test('Full result: everything filled, Total and Grade calculated', () {
      final t = build(ExportOptions.preset(ExportPreset.fullResult, schemes));
      expect(titles(t).last, 'Grade');
      expect(row(t, 0), ['1', 'FWM/24U/0538', '9.5', '4', '3.5', '5.0', '22', 'F']);
      expect(row(t, 1), ['2', 'FST/25U/244/5772', '58', '9', '8.0', '9.5', '84.5', 'A']);
    });
  });

  group('cells', () {
    final full = ExportOptions.preset(ExportPreset.fullResult, schemes);

    test('a student with parts still to enter gets a partial total and no grade', () {
      final r = row(build(full), 2);
      expect(r, ['3', 'FWM/24U/0101', '10', '', '', '', '10', '']);
    });

    test('absent shows ABS and counts as zero', () {
      final r = row(build(full), 3);
      expect(r, ['4', 'ASR/25U/224/0937', 'ABS', '2', '1.0', '0.0', '3', 'F']);
    });

    test('attendance is a whole number, typed parts follow their step, exam as written', () {
      final r = row(build(full), 0);
      expect(r[3], '4'); // step 1
      expect(r[4], '3.5'); // step 0.5
      expect(r[5], '5.0'); // step 0.5
      expect(r[2], '9.5'); // exam: as the examiner wrote it
      expect(row(build(full), 2)[2], '10'); // not "10.0"
    });

    test('the brief sample adds up: 1.0 + 1.0 + 2.0 + 5.5 = 9.5 as the exam', () {
      final t = build(ExportOptions.preset(ExportPreset.examSheet, schemes));
      expect(t.rows[0][2].text, '9.5');
      expect(t.rows[0][2].number, 9.5);
    });
  });

  group('column chooser', () {
    test('a part can be blanked, and the total counts only what is filled', () {
      final o = ExportOptions.preset(ExportPreset.fullResult, schemes)
          .copyWith(partFilled: {'exam': true, 'attendance': false, 'assignment': true, 'test': true});
      final t = build(o);
      // 9.5 + 3.5 + 5 = 18, attendance (4) left out of the sum.
      expect(row(t, 0), ['1', 'FWM/24U/0538', '9.5', '', '3.5', '5.0', '18', '']);
    });

    test('grade can be left out altogether', () {
      final o = ExportOptions.preset(ExportPreset.fullResult, schemes).copyWith(includeGrade: false);
      final t = build(o);
      expect(titles(t), isNot(contains('Grade')));
      expect(t.rows[0].length, t.columns.length);
    });

    test('total can be blank while parts are filled', () {
      final o = ExportOptions.preset(ExportPreset.fullResult, schemes).copyWith(totalFilled: false);
      final r = row(build(o), 1);
      expect(r[6], '');
      expect(r[7], '', reason: 'no grade without a total');
    });

    test('a part that is not in the options is filled, not dropped', () {
      const o = ExportOptions(partFilled: {});
      expect(row(build(o), 0).sublist(2, 6), ['9.5', '4', '3.5', '5.0']);
    });

    test('S/N follows the order entered, or the exam number', () {
      final entered = build(const ExportOptions(serialOrder: SerialOrder.entryOrder));
      expect(entered.rows.map((r) => r[1].text),
          ['FWM/24U/0538', 'FST/25U/244/5772', 'FWM/24U/0101', 'ASR/25U/224/0937']);

      final sorted = build(const ExportOptions(serialOrder: SerialOrder.byRegNo));
      expect(sorted.rows.map((r) => r[1].text),
          ['ASR/25U/224/0937', 'FST/25U/244/5772', 'FWM/24U/0101', 'FWM/24U/0538']);
      expect(sorted.rows.map((r) => r[0].text), ['1', '2', '3', '4']);
    });
  });

  group('columns follow the course', () {
    test('a different list of parts gives different columns, in part order', () {
      final custom = f.course.copyWith(
        scheme: f.course.scheme.copyWith(parts: [
          const PartSpec(id: 'q', name: 'Quiz 2', max: 20, step: 1),
          f.course.scheme.parts[0],
        ], bands: const []),
      );
      final t = ResultTableBuilder.build(
        course: custom,
        students: f.students,
        scores: f.scores,
        options: const ExportOptions(includeGrade: false),
      );
      expect(titles(t), ['S/N', 'Registration No.', 'Quiz 2', 'Exam', 'Total']);
    });
  });

  group('heading and header', () {
    test('heading reads "(FWM) AGR 114"', () {
      expect(build(const ExportOptions()).title, '(FWM) AGR 114');
    });

    test('header lines come from settings and can be switched off', () {
      const header = ExportHeader(
        university: 'Modibbo Adama University, Yola',
        faculty: 'Faculty of Agriculture',
        session: '2024/2025',
        examiner: 'Dr A. Example',
      );
      expect(build(const ExportOptions(), header: header).headerLines, [
        'Modibbo Adama University, Yola',
        'Faculty of Agriculture',
        'Session: 2024/2025',
        'Examiner: Dr A. Example',
      ]);
      expect(build(const ExportOptions(includeHeader: false), header: header).headerLines, isEmpty);
      expect(build(const ExportOptions()).headerLines, isEmpty);
    });
  });
}
