import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimarkly/app.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/providers/providers.dart';

/// Runs the real app on an in-memory database.
///
/// Data a test needs up front goes in through `seed`, which runs before the
/// app starts. (Writing from the test body while the app's streams are live
/// would wait on the test's fake clock.) Changes made through the UI work
/// normally.
class AppHarness {
  late AppDatabase db;
  late SharedPreferences prefs;

  CourseRepository get courses => CourseRepository(db);
  StudentRepository get students => StudentRepository(db);
  ScoreRepository get scores => ScoreRepository(db);

  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    Map<String, Object> prefsValues = const {},
    Future<void> Function()? seed,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues(prefsValues);
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearAllTestValues();
    });

    if (seed != null) await tester.runAsync(seed);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const UniMarkLyApp(),
    ));
    await settle(tester);
  }

  /// Lets database streams deliver and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Bounded: a screen with a spinner or other endless animation must not
    // hang the test.
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
    } catch (_) {
      // Still animating; whatever is on screen now is what we check.
    }
  }

  /// Unmounts the app first and lets the fake clock run, so the providers and
  /// drift's stream clean-up timers fire; only then closes the database.
  Future<void> stop(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Scrolls the top screen's vertical list, down and then back up, until
  /// [finder] is built.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);
    for (final dy in [-240.0, 240.0]) {
      for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
        if (vertical.evaluate().isEmpty) break;
        await tester.drag(vertical.last, Offset(0, dy), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      if (finder.evaluate().isNotEmpty) break;
    }
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pump();
    }
  }

  Future<void> tapText(WidgetTester tester, String text, {bool settleAfter = true}) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) await reveal(tester, finder);
    expect(finder, findsAtLeastNWidgets(1), reason: 'looking for "$text"');
    await tester.ensureVisible(finder.first);
    await tester.pump(); // let the scroll take effect before tapping
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(finder.first);
    if (settleAfter) await settle(tester);
  }

  // ---- data for `seed` ----

  static Course makeCourse({String code = 'AGR 114', String department = 'FWM'}) => Course(
        id: newId(),
        code: code,
        department: department,
        session: '2024/2025',
        semester: 'Second',
        scheme: Defaults.nigerianScheme(),
      );

  /// A course with the default scheme and the given students.
  Future<Course> createCourse({
    String code = 'AGR 114',
    String department = 'FWM',
    List<String> regNos = const ['FWM/24U/0538', 'FWM/24U/0539', 'FST/25U/244/5772'],
  }) async {
    final course = makeCourse(code: code, department: department);
    await courses.save(course);
    if (regNos.isNotEmpty) {
      await students.addMany(course.id, [for (final r in regNos) NewStudent(r)]);
    }
    return course;
  }

  /// Writes marks by part index for one student.
  Future<void> setMarks(Course course, Student student, Map<int, double> byPartIndex) async {
    for (final e in byPartIndex.entries) {
      await scores.set(
        course.id,
        ScoreWrite(studentId: student.id, partId: course.scheme.parts[e.key].id, value: e.value),
      );
    }
  }
}
