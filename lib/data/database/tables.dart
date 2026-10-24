import 'package:drift/drift.dart';

import '../../domain/ids.dart';

/// Columns every table carries from the first version, even on Free, so Pro
/// sync can be added later without migrating anyone's data.
///
///  * `id` is a UUID.
///  * `updated_at` is set on every write (by the repositories).
///  * `deleted_at` is a soft delete; null means the row is live.
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newId)();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CourseRow')
@TableIndex(name: 'course_code', columns: {#code})
class Courses extends Table with SyncColumns {
  @override
  String get tableName => 'course';

  TextColumn get code => text()();
  TextColumn get department => text().withDefault(const Constant(''))();
  TextColumn get session => text().withDefault(const Constant(''))();
  TextColumn get semester => text().withDefault(const Constant(''))();

  /// What the parts should add up to (100 by default).
  RealColumn get totalExpected => real().withDefault(const Constant(100))();

  /// `all`, `best_n` or `compulsory_plus_best_n`.
  TextColumn get countRule => text().withDefault(const Constant('all'))();
  IntColumn get countN => integer().nullable()();
}

@DataClassName('CoursePartRow')
@TableIndex(name: 'course_part_course', columns: {#courseId})
class CourseParts extends Table with SyncColumns {
  @override
  String get tableName => 'course_part';

  TextColumn get courseId => text().references(Courses, #id)();
  TextColumn get name => text()();
  RealColumn get max => real()();
  RealColumn get min => real().withDefault(const Constant(0))();
  RealColumn get passMark => real().nullable()();
  RealColumn get step => real().withDefault(const Constant(0.5))();

  /// Null means "same as max".
  RealColumn get markedOutOf => real().nullable()();

  /// Null means "same as max".
  RealColumn get countsFor => real().nullable()();

  /// `scanned`, `typed` or `imported`.
  TextColumn get source => text().withDefault(const Constant('typed'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('ExamQuestionRow')
@TableIndex(name: 'exam_question_course', columns: {#courseId})
class ExamQuestions extends Table with SyncColumns {
  @override
  String get tableName => 'exam_question';

  TextColumn get courseId => text().references(Courses, #id)();
  IntColumn get qNo => integer()();
  RealColumn get max => real()();
  BoolColumn get compulsory => boolean().withDefault(const Constant(false))();
}

@DataClassName('GradeScaleRow')
@TableIndex(name: 'grade_scale_course', columns: {#courseId})
class GradeScales extends Table with SyncColumns {
  @override
  String get tableName => 'grade_scale';

  TextColumn get courseId => text().references(Courses, #id)();
  RealColumn get minScore => real()();
  RealColumn get maxScore => real()();
  TextColumn get letter => text()();
  RealColumn get points => real().withDefault(const Constant(0))();
}

@DataClassName('SchemeTemplateRow')
class SchemeTemplates extends Table with SyncColumns {
  @override
  String get tableName => 'scheme_template';

  TextColumn get name => text()();
  TextColumn get json => text()();
}

@DataClassName('StudentRow')
@TableIndex(name: 'student_course', columns: {#courseId})
@TableIndex(name: 'student_reg_no', columns: {#courseId, #regNo})
class Students extends Table with SyncColumns {
  @override
  String get tableName => 'student';

  TextColumn get courseId => text().references(Courses, #id)();

  /// Stored in one form: upper case DEPT/YYU/NNNN, optional middle part.
  TextColumn get regNo => text()();
  TextColumn get name => text().nullable()();

  /// False for numbers added by hand that were not on the imported list.
  BoolColumn get onClassList => boolean().withDefault(const Constant(true))();

  /// Order added; the "scan order" for exports.
  IntColumn get position => integer().withDefault(const Constant(0))();
}

/// One upload session: a set of booklet photos for one course.
@DataClassName('BatchRow')
@TableIndex(name: 'upload_batch_course', columns: {#courseId})
class Batches extends Table with SyncColumns {
  @override
  String get tableName => 'upload_batch';

  TextColumn get courseId => text().references(Courses, #id)();

  /// Optional name the examiner gave it. Shown as "Batch of 12 Oct" when empty.
  TextColumn get title => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

@DataClassName('ScanRow')
@TableIndex(name: 'scan_course', columns: {#courseId})
@TableIndex(name: 'scan_batch', columns: {#batchId})
@TableIndex(name: 'scan_hash', columns: {#courseId, #contentHash})
class Scans extends Table with SyncColumns {
  @override
  String get tableName => 'scan';

  TextColumn get courseId => text().references(Courses, #id)();

  /// `booklet_cover` or `list_sheet`.
  TextColumn get kind => text()();
  TextColumn get photoPath => text().nullable()();
  IntColumn get pageNo => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('scanned'))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  // Added in schema version 2 (intake).
  TextColumn get batchId => text().nullable().references(Batches, #id)();

  /// The file name the examiner's phone gave the image.
  TextColumn get originalName => text().nullable()();

  /// SHA-256 of the image bytes, to catch the same photo added twice.
  TextColumn get contentHash => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();

  /// Why reading failed, in words the examiner can act on.
  TextColumn get errorMessage => text().nullable()();
}

@DataClassName('BookletRow')
@TableIndex(name: 'booklet_course', columns: {#courseId})
class Booklets extends Table with SyncColumns {
  @override
  String get tableName => 'booklet';

  TextColumn get courseId => text().references(Courses, #id)();
  TextColumn get studentId => text().nullable().references(Students, #id)();
  TextColumn get scanId => text().nullable().references(Scans, #id)();
  TextColumn get serialNo => text().nullable()();
  TextColumn get readJson => text().nullable()();

  /// `needs_review` until the examiner confirms it; then `confirmed`.
  TextColumn get status => text().withDefault(const Constant('scanned'))();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
}

@DataClassName('QuestionMarkRow')
@TableIndex(name: 'question_mark_booklet', columns: {#bookletId})
class QuestionMarks extends Table with SyncColumns {
  @override
  String get tableName => 'question_mark';

  TextColumn get bookletId => text().references(Booklets, #id)();
  IntColumn get qNo => integer()();
  RealColumn get mark => real()();
  RealColumn get confidence => real().nullable()();
  BoolColumn get edited => boolean().withDefault(const Constant(false))();
}

@DataClassName('RowReadRow')
@TableIndex(name: 'row_read_scan', columns: {#scanId})
class RowReads extends Table with SyncColumns {
  @override
  String get tableName => 'row_read';

  TextColumn get scanId => text().references(Scans, #id)();
  IntColumn get rowNo => integer()();
  TextColumn get rawId => text().nullable()();
  TextColumn get rawValue => text().nullable()();
  TextColumn get studentId => text().nullable().references(Students, #id)();
  TextColumn get partId => text().nullable().references(CourseParts, #id)();
  RealColumn get value => real().nullable()();
  RealColumn get confidence => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('read'))();
}

@DataClassName('PartScoreRow')
@TableIndex(name: 'part_score_course', columns: {#courseId})
@TableIndex(name: 'part_score_cell', columns: {#studentId, #partId})
class PartScores extends Table with SyncColumns {
  @override
  String get tableName => 'part_score';

  TextColumn get courseId => text().references(Courses, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get partId => text().references(CourseParts, #id)();

  /// Null when the status is `absent` or `missing`.
  RealColumn get value => real().nullable()();

  /// `entered`, `absent` or `missing`. The total and grade are calculated,
  /// never stored.
  TextColumn get status => text().withDefault(const Constant('entered'))();

  /// `typed`, `scanned` or `imported`.
  TextColumn get source => text().withDefault(const Constant('typed'))();
}

@DataClassName('CorrectionRow')
class Corrections extends Table with SyncColumns {
  @override
  String get tableName => 'correction';

  TextColumn get cropPath => text()();
  TextColumn get field => text()();
  TextColumn get readValue => text().nullable()();
  TextColumn get confirmedValue => text().nullable()();

  /// Where on the photo the value was, as "left,top,right,bottom" fractions
  /// (added in schema version 2). With [cropPath] this is enough to cut the
  /// crop again later when training the digit model.
  TextColumn get region => text().nullable()();
}

@DataClassName('AccountRow')
class Accounts extends Table with SyncColumns {
  @override
  String get tableName => 'account';

  TextColumn get userId => text()();
  TextColumn get email => text().nullable()();
  TextColumn get plan => text().withDefault(const Constant('free'))();
  DateTimeColumn get planValidUntil => dateTime().nullable()();
}

@DataClassName('SyncStateRow')
class SyncStates extends Table with SyncColumns {
  @override
  String get tableName => 'sync_state';

  TextColumn get syncTable => text().named('table_name')();
  DateTimeColumn get lastPullAt => dateTime().nullable()();
  DateTimeColumn get lastPushAt => dateTime().nullable()();
}
