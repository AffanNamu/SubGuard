import 'package:flutter/foundation.dart';

import '../../domain/defaults.dart';
import '../../domain/ids.dart';
import '../../domain/models.dart';
import '../../domain/scheme.dart';
import '../../domain/scheme_codec.dart';

/// The course being created or edited in the setup wizard. Every change goes
/// through here, so the running total and the warnings always match what is
/// on screen. Nothing is saved until the wizard's final step.
class CourseDraftController extends ChangeNotifier {
  CourseDraftController.create({
    required GradingScheme scheme,
    this.session = '',
    this.semester = '',
  })  : id = newId(),
        isNew = true,
        _scheme = scheme,
        code = '',
        department = '';

  CourseDraftController.edit(Course course)
      : id = course.id,
        isNew = false,
        _scheme = course.scheme,
        code = course.code,
        department = course.department,
        session = course.session,
        semester = course.semester;

  final String id;
  final bool isNew;

  String code;
  String department;
  String session;
  String semester;

  GradingScheme _scheme;
  GradingScheme get scheme => _scheme;

  String? templateName;

  void _set(GradingScheme s) {
    _scheme = s;
    notifyListeners();
  }

  void setBasics({String? code, String? department, String? session, String? semester}) {
    if (code != null) this.code = code;
    if (department != null) this.department = department;
    if (session != null) this.session = session;
    if (semester != null) this.semester = semester;
    notifyListeners();
  }

  /// True when the scheme differs from [other], ignoring ids.
  bool differsFrom(GradingScheme other) =>
      SchemeCodec.encode(_scheme) != SchemeCodec.encode(other);

  void applyTemplate(SchemeTemplate t) {
    templateName = t.name;
    _set(SchemeCodec.freshCopy(t.scheme));
  }

  // ---- parts ----

  void setTotalExpected(double v) => _set(_scheme.copyWith(totalExpected: v));

  void updatePart(PartSpec part) => _set(_scheme.copyWith(parts: [
        for (final p in _scheme.parts) p.id == part.id ? part : p,
      ]));

  PartSpec addPart(String name) {
    final part = PartSpec(
      id: newId(),
      name: name,
      max: 10,
      step: 0.5,
      sortOrder: _scheme.parts.length,
    );
    _set(_scheme.copyWith(parts: [..._scheme.parts, part]));
    return part;
  }

  void removePart(String id) =>
      _set(_scheme.copyWith(parts: _scheme.parts.where((p) => p.id != id).toList()));

  void movePart(int oldIndex, int newIndex) {
    final parts = [..._scheme.parts];
    if (newIndex > oldIndex) newIndex -= 1;
    parts.insert(newIndex, parts.removeAt(oldIndex));
    _set(_scheme.copyWith(parts: parts));
  }

  // ---- exam paper ----

  void setQuestionCount(int n) {
    final questions = [..._scheme.questions]..sort((a, b) => a.qNo.compareTo(b.qNo));
    if (n < questions.length) {
      _set(_scheme.copyWith(questions: questions.take(n).toList()));
      return;
    }
    final fill = questions.isNotEmpty ? questions.last.max : 10.0;
    for (var i = questions.length; i < n; i++) {
      questions.add(QuestionSpec(id: newId(), qNo: i + 1, max: fill));
    }
    _set(_scheme.copyWith(questions: questions));
  }

  void updateQuestion(QuestionSpec q) => _set(_scheme.copyWith(questions: [
        for (final x in _scheme.questions) x.id == q.id ? q : x,
      ]));

  void setAllQuestionMax(double max) => _set(_scheme.copyWith(questions: [
        for (final q in _scheme.questions) q.copyWith(max: max),
      ]));

  void setCountRule(CountRule rule) {
    var n = _scheme.countN;
    if (rule != CountRule.all && n == null) {
      final count = _scheme.questions.length;
      n = count > 1 ? count - 1 : count;
    }
    _set(_scheme.copyWith(
      countRule: rule,
      countN: n,
      clearCountN: rule == CountRule.all,
    ));
  }

  void setCountN(int n) => _set(_scheme.copyWith(countN: n));

  // ---- grade scale ----

  void updateBand(GradeBand band) => _set(_scheme.copyWith(bands: [
        for (final b in _scheme.bands) b.id == band.id ? band : b,
      ]));

  void addBand() {
    final sorted = [..._scheme.bands]..sort((a, b) => a.minScore.compareTo(b.minScore));
    final top = sorted.isEmpty ? 0.0 : sorted.last.maxScore;
    _set(_scheme.copyWith(bands: [
      ..._scheme.bands,
      GradeBand(
        id: newId(),
        minScore: top,
        maxScore: _scheme.totalExpected,
        letter: '',
        points: 0,
      ),
    ]));
  }

  void removeBand(String id) =>
      _set(_scheme.copyWith(bands: _scheme.bands.where((b) => b.id != id).toList()));

  void resetBands() => _set(_scheme.copyWith(bands: Defaults.nigerianGradeScale()));

  // ---- result ----

  /// Problems that stop the course being saved at all. Everything else is a
  /// warning, so this stays short.
  List<String> get blockingProblems => [
        if (code.trim().isEmpty) 'Give the course a code, such as AGR 114.',
        for (final p in _scheme.parts)
          if (p.name.trim().isEmpty) 'Every part needs a name.',
      ];

  Course build() => Course(
        id: id,
        code: code.trim(),
        department: department.trim(),
        session: session.trim(),
        semester: semester.trim(),
        scheme: _scheme,
      );
}
