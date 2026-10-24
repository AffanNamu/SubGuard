import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  final ThemeMode themeMode;
  final ExportHeader header;
  final String defaultSession;
  final String defaultSemester;
  final bool seenWelcome;

  /// How much photos are shrunk when picked.
  final PhotoQuality photoQuality;

  /// Start reading booklets as soon as they are added.
  final bool readAutomatically;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ExportHeader? header,
    String? defaultSession,
    String? defaultSemester,
    bool? seenWelcome,
    PhotoQuality? photoQuality,
    bool? readAutomatically,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        header: header ?? this.header,
        defaultSession: defaultSession ?? this.defaultSession,
        defaultSemester: defaultSemester ?? this.defaultSemester,
        seenWelcome: seenWelcome ?? this.seenWelcome,
        photoQuality: photoQuality ?? this.photoQuality,
        readAutomatically: readAutomatically ?? this.readAutomatically,
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
      );

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
  }
}
