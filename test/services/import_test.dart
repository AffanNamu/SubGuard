import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scoring.dart';
import 'package:unimarkly/services/import/import_planner.dart';
import 'package:unimarkly/services/import/table_reader.dart';

import '../support/fixtures.dart';

void main() {
  group('TableReader', () {
    test('reads a CSV with a byte-order mark and Windows line endings', () {
      final t = TableReader.fromCsv('﻿S/N,Registration No.,Name\r\n1,FWM/24U/0538,Ada Obi\r\n2,FWM/24U/0539,"Bola, A."\r\n');
      expect(t.rows, [
        ['S/N', 'Registration No.', 'Name'],
        ['1', 'FWM/24U/0538', 'Ada Obi'],
        ['2', 'FWM/24U/0539', 'Bola, A.'],
      ]);
    });

    test('detects semicolons and tabs', () {
      expect(TableReader.fromCsv('a;b;c\n1;2;3').rows[1], ['1', '2', '3']);
      expect(TableReader.fromPaste('FWM/24U/0538\tAda\nFWM/24U/0539\tBola').rows,
          [['FWM/24U/0538', 'Ada'], ['FWM/24U/0539', 'Bola']]);
    });

    test('a pasted list with one number per line is one column', () {
      final t = TableReader.fromPaste('FWM/24U/0538\nFWM/24U/0539\n\nFWM/24U/0540\n');
      expect(t.columnCount, 1);
      expect(t.rowCount, 3);
    });

    test('keeps numbers as typed, such as 0538 and 5.0', () {
      expect(TableReader.fromCsv('0538,5.0').rows.single, ['0538', '5.0']);
    });

    test('empty input gives an empty table', () {
      expect(TableReader.fromPaste('  \n ').isEmpty, isTrue);
    });

    test('reads an Excel sheet, writing whole numbers without ".0"', () {
      final book = Excel.createExcel();
      final sheet = book[book.getDefaultSheet()!];
      sheet.appendRow([TextCellValue('Reg'), TextCellValue('Attendance')]);
      sheet.appendRow([TextCellValue('FWM/24U/0538'), const IntCellValue(4)]);
      sheet.appendRow([TextCellValue('FWM/24U/0539'), const DoubleCellValue(3.5)]);
      sheet.appendRow([TextCellValue('FWM/24U/0540'), const DoubleCellValue(5.0)]);
      final t = TableReader.fromExcel(Uint8List.fromList(book.encode()!));
      expect(t.rows, [
        ['Reg', 'Attendance'],
        ['FWM/24U/0538', '4'],
        ['FWM/24U/0539', '3.5'],
        ['FWM/24U/0540', '5'],
      ]);
    });

    test('fromFile picks the reader from the name and rejects old .xls', () {
      expect(TableReader.fromFile('list.csv', Uint8List.fromList(utf8.encode('a,b'))).rows.single, ['a', 'b']);
      expect(() => TableReader.fromFile('list.xls', Uint8List(0)), throwsFormatException);
    });

    test('falls back to Latin-1 for old exports', () {
      final t = TableReader.fromFile('l.csv', Uint8List.fromList(latin1.encode('FWM/24U/0538,José')));
      expect(t.rows.single.last, 'José');
    });
  });

  group('ImportPlanner.guess', () {
    test('finds the header, registration column and name column', () {
      final t = TableReader.fromCsv('S/N,Name,Registration No.\n1,Ada,FWM/24U/0538\n2,Bola,FWM/24U/0539');
      final g = ImportPlanner.guess(t);
      expect(g.hasHeader, isTrue);
      expect(g.regNoColumn, 2);
      expect(g.nameColumn, 1);
    });

    test('finds the column when there is no header', () {
      final t = TableReader.fromPaste('FWM/24U/0538\nFWM/24U/0539');
      final g = ImportPlanner.guess(t);
      expect(g.hasHeader, isFalse);
      expect(g.regNoColumn, 0);
      expect(g.nameColumn, isNull);
    });

    test('numbers where the U was read as 4 still count as registration numbers', () {
      final t = TableReader.fromPaste('FWM/244/0538\nFWM/244/0539');
      expect(ImportPlanner.guess(t).regNoColumn, 0);
    });

    test('matches part columns to parts by name', () {
      final f = Fixture();
      final t = TableReader.fromCsv('S/N,Registration No.,Attendance,Assignment,Test\n1,FWM/24U/0538,4,3.5,5');
      final g = ImportPlanner.guess(t, parts: f.course.scheme.parts);
      expect(g.partColumns[f.attendance.id], 2);
      expect(g.partColumns[f.assignment.id], 3);
      expect(g.partColumns[f.test.id], 4);
      expect(g.partColumns.containsKey(f.exam.id), isFalse);
    });
  });

  group('class list', () {
    test('turns rows into students, skipping the header', () {
      final t = TableReader.fromCsv('Reg,Name\nFWM/24U/0538,Ada\nFWM/24U/0539,');
      final rows = ImportPlanner.classList(t, regNoColumn: 0, nameColumn: 1, hasHeader: true);
      expect(rows.map((r) => r.regNo), ['FWM/24U/0538', 'FWM/24U/0539']);
      expect(rows.first.name, 'Ada');
    });
  });

  group('score import', () {
    final f = Fixture();
    final students = [
      for (final s in f.students) s,
    ];

    ScoreImportPlan plan(String csv, {Map<String, int>? cols}) => ImportPlanner.scores(
          TableReader.fromCsv(csv),
          regNoColumn: 1,
          partColumns: cols ?? {f.attendance.id: 2, f.assignment.id: 3, f.test.id: 4},
          hasHeader: true,
          scheme: f.course.scheme,
          students: students,
        );

    test('matches students and reads every mark', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,FWM/24U/0538,4,3.5,5\n2,fst 25u 244 5772,9,8,9.5');
      expect(p.matchedStudents, 2);
      expect(p.cellsRead, 6);
      expect(p.unmatched, isEmpty);
      final w = p.writes.firstWhere((w) => w.studentId == 's1' && w.partId == f.assignment.id);
      expect(w.value, 3.5);
      expect(w.source, 'imported');
    });

    test('reads a raised-dot half mark and "abs"', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,FWM/24U/0538,abs,3·5,5');
      expect(p.absentCells, 1);
      expect(p.writes.firstWhere((w) => w.partId == f.attendance.id).status, ScoreStatus.absent);
      expect(p.writes.firstWhere((w) => w.partId == f.assignment.id).value, 3.5);
    });

    test('a blank cell is skipped, not written as zero', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,FWM/24U/0538,,3,');
      expect(p.writes, hasLength(1));
    });

    test('numbers that are not on the class list come back with suggestions', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,FWM/24U/0539,4,3,5\n2,FWM/24U/0999,1,1,1');
      expect(p.matchedStudents, 0);
      expect(p.unmatched.map((u) => u.regNo), ['FWM/24U/0539', 'FWM/24U/0999']);
      expect(p.unmatched.first.suggestions.map((s) => s.regNo), contains('FWM/24U/0538'));
      expect(p.unmatched.first.values.length, 3);
    });

    test('text that is not a mark is reported with its row', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,FWM/24U/0538,four,3,5');
      expect(p.unreadable.single.partName, 'Attendance');
      expect(p.unreadable.single.row, 2);
      expect(p.unreadable.single.text, 'four');
      expect(p.cellsRead, 2);
    });

    test('a number repeated further down the file is skipped and counted', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,FWM/24U/0538,4,3,5\n2,FWM/24U/0538,9,9,9');
      expect(p.repeatedRows, 1);
      expect(p.writes.firstWhere((w) => w.partId == f.attendance.id).value, 4);
    });

    test('blank rows are counted', () {
      final p = plan('S/N,Reg,Attendance,Assignment,Test\n1,,4,3,5');
      expect(p.blankRows, 1);
    });

    test('students from another course are never matched', () {
      final other = [const Student(id: 'zz', courseId: 'other', regNo: 'FWM/24U/0538')];
      final p = ImportPlanner.scores(
        TableReader.fromCsv('S/N,Reg,Attendance\n1,FWM/24U/0538,4'),
        regNoColumn: 1,
        partColumns: {f.attendance.id: 2},
        hasHeader: true,
        scheme: f.course.scheme,
        students: other,
      );
      expect(p.writes.single.studentId, 'zz', reason: 'the caller passes only this course\'s students');
    });
  });
}
