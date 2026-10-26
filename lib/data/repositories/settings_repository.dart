import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/layout_profile.dart';
import '../../services/export/result_table.dart';
import '../../services/scan/image_source.dart';

/// Per-phone preferences. Course data lives in the database; this holds only
/// the theme, the document header and the defaults for new courses.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.header = const ExportHeader(),
    this.defaultSession = '',
    this.defaultSemester = '',
    this.seenWelcome = false,
    this.photoQuality = PhotoQuality.high,
    this.readAutomatically = true,
    this.maxQuestionNumber = defaultMaxQuestionNumber,
  });

  /// The highest question number the app accepts when it reads or adds one. Not a list
  /// the app fills in: a question number above it is "not clear" rather than accepted.
  /// The examiner sets it for their papers.
  static const defaultMaxQuestionNumber = 60;
  static const maxQuestionNumberLimit = 999;

  final ThemeMode themeMode;
  final ExportHeader header;
  final String defaultSession;
  final String defaultSemester;
  final bool seenWelcome;

  /// How much photos are shrunk when picked.
  final PhotoQuality photoQuality;

  /// Start reading booklets as soon as they are added.
  final bool readAutomatically;

  /// See [defaultMaxQuestionNumber].
  final int maxQuestionNumber;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ExportHeader? header,
    String? defaultSession,
    String? defaultSemester,
    bool? seenWelcome,
    PhotoQuality? photoQuality,
    bool? readAutomatically,
    int? maxQuestionNumber,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        header: header ?? this.header,
        defaultSession: defaultSession ?? this.defaultSession,
        defaultSemester: defaultSemester ?? this.defaultSemester,
        seenWelcome: seenWelcome ?? this.seenWelcome,
        photoQuality: photoQuality ?? this.photoQuality,
        readAutomatically: readAutomatically ?? this.readAutomatically,
        maxQuestionNumber: maxQuestionNumber ?? this.maxQuestionNumber,
      );
}

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _theme = 'theme_mode';
  static const _university = 'header_university';
  static const _faculty = 'header_faculty';
  static const _department = 'header_department';
  static const _session = 'header_session';
  static const _examiner = 'header_examiner';
  static const _defaultSession = 'default_session';
  static const _defaultSemester = 'default_semester';
  static const _seenWelcome = 'seen_welcome';
  static const _photoQuality = 'photo_quality';
  static const _readAutomatically = 'read_automatically';
  static const _maxQuestionNumber = 'max_question_number';
  static const _layouts = 'layout_profiles';
  static const _layoutId = 'layout_profile_id';

  AppSettings load() => AppSettings(
        themeMode: switch (_prefs.getString(_theme)) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        header: ExportHeader(
          university: _prefs.getString(_university) ?? '',
          faculty: _prefs.getString(_faculty) ?? '',
          department: _prefs.getString(_department) ?? '',
          session: _prefs.getString(_session) ?? '',
          examiner: _prefs.getString(_examiner) ?? '',
        ),
        defaultSession: _prefs.getString(_defaultSession) ?? '',
        defaultSemester: _prefs.getString(_defaultSemester) ?? '',
        seenWelcome: _prefs.getBool(_seenWelcome) ?? false,
        photoQuality: PhotoQuality.fromName(_prefs.getString(_photoQuality)),
        readAutomatically: _prefs.getBool(_readAutomatically) ?? true,
        maxQuestionNumber: (_prefs.getInt(_maxQuestionNumber) ?? AppSettings.defaultMaxQuestionNumber).clamp(1, AppSettings.maxQuestionNumberLimit),
      );

  /// Layout files the administrator added, as they were checked when added. A stored
  /// file that no longer passes (an older or damaged copy) is left out.
  List<LayoutProfile> importedLayouts() {
    final out = <LayoutProfile>[];
    for (final text in _prefs.getStringList(_layouts) ?? const <String>[]) {
      try {
        out.add(LayoutProfile.parse(text));
      } on LayoutProfileException {
        continue;
      }
    }
    return out;
  }

  /// The id of the layout used for reading, or null for the built-in one.
  String? get selectedLayoutId => _prefs.getString(_layoutId);

  Future<void> saveLayouts(List<LayoutProfile> imported, String selectedId) async {
    await _prefs.setStringList(_layouts, [for (final p in imported) p.encode()]);
    await _prefs.setString(_layoutId, selectedId);
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_theme, switch (s.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    await _prefs.setString(_university, s.header.university);
    await _prefs.setString(_faculty, s.header.faculty);
    await _prefs.setString(_department, s.header.department);
    await _prefs.setString(_session, s.header.session);
    await _prefs.setString(_examiner, s.header.examiner);
    await _prefs.setString(_defaultSession, s.defaultSession);
    await _prefs.setString(_defaultSemester, s.defaultSemester);
    await _prefs.setBool(_seenWelcome, s.seenWelcome);
    await _prefs.setString(_photoQuality, s.photoQuality.name);
    await _prefs.setBool(_readAutomatically, s.readAutomatically);
    await _prefs.setInt(_maxQuestionNumber, s.maxQuestionNumber);
  }
}
