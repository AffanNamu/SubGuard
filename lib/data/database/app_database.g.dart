// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CoursesTable extends Courses with TableInfo<$CoursesTable, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sessionMeta = const VerificationMeta(
    'session',
  );
  @override
  late final GeneratedColumn<String> session = GeneratedColumn<String>(
    'session',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalExpectedMeta = const VerificationMeta(
    'totalExpected',
  );
  @override
  late final GeneratedColumn<double> totalExpected = GeneratedColumn<double>(
    'total_expected',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _countRuleMeta = const VerificationMeta(
    'countRule',
  );
  @override
  late final GeneratedColumn<String> countRule = GeneratedColumn<String>(
    'count_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _countNMeta = const VerificationMeta('countN');
  @override
  late final GeneratedColumn<int> countN = GeneratedColumn<int>(
    'count_n',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    code,
    department,
    session,
    semester,
    totalExpected,
    countRule,
    countN,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    }
    if (data.containsKey('session')) {
      context.handle(
        _sessionMeta,
        session.isAcceptableOrUnknown(data['session']!, _sessionMeta),
      );
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    }
    if (data.containsKey('total_expected')) {
      context.handle(
        _totalExpectedMeta,
        totalExpected.isAcceptableOrUnknown(
          data['total_expected']!,
          _totalExpectedMeta,
        ),
      );
    }
    if (data.containsKey('count_rule')) {
      context.handle(
        _countRuleMeta,
        countRule.isAcceptableOrUnknown(data['count_rule']!, _countRuleMeta),
      );
    }
    if (data.containsKey('count_n')) {
      context.handle(
        _countNMeta,
        countN.isAcceptableOrUnknown(data['count_n']!, _countNMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      )!,
      session: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester'],
      )!,
      totalExpected: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_expected'],
      )!,
      countRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}count_rule'],
      )!,
      countN: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count_n'],
      ),
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String code;
  final String department;
  final String session;
  final String semester;

  /// What the parts should add up to (100 by default).
  final double totalExpected;

  /// `all`, `best_n` or `compulsory_plus_best_n`.
  final String countRule;
  final int? countN;
  const CourseRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.code,
    required this.department,
    required this.session,
    required this.semester,
    required this.totalExpected,
    required this.countRule,
    this.countN,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['code'] = Variable<String>(code);
    map['department'] = Variable<String>(department);
    map['session'] = Variable<String>(session);
    map['semester'] = Variable<String>(semester);
    map['total_expected'] = Variable<double>(totalExpected);
    map['count_rule'] = Variable<String>(countRule);
    if (!nullToAbsent || countN != null) {
      map['count_n'] = Variable<int>(countN);
    }
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      code: Value(code),
      department: Value(department),
      session: Value(session),
      semester: Value(semester),
      totalExpected: Value(totalExpected),
      countRule: Value(countRule),
      countN: countN == null && nullToAbsent
          ? const Value.absent()
          : Value(countN),
    );
  }

  factory CourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      code: serializer.fromJson<String>(json['code']),
      department: serializer.fromJson<String>(json['department']),
      session: serializer.fromJson<String>(json['session']),
      semester: serializer.fromJson<String>(json['semester']),
      totalExpected: serializer.fromJson<double>(json['totalExpected']),
      countRule: serializer.fromJson<String>(json['countRule']),
      countN: serializer.fromJson<int?>(json['countN']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'code': serializer.toJson<String>(code),
      'department': serializer.toJson<String>(department),
      'session': serializer.toJson<String>(session),
      'semester': serializer.toJson<String>(semester),
      'totalExpected': serializer.toJson<double>(totalExpected),
      'countRule': serializer.toJson<String>(countRule),
      'countN': serializer.toJson<int?>(countN),
    };
  }

  CourseRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? code,
    String? department,
    String? session,
    String? semester,
    double? totalExpected,
    String? countRule,
    Value<int?> countN = const Value.absent(),
  }) => CourseRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    code: code ?? this.code,
    department: department ?? this.department,
    session: session ?? this.session,
    semester: semester ?? this.semester,
    totalExpected: totalExpected ?? this.totalExpected,
    countRule: countRule ?? this.countRule,
    countN: countN.present ? countN.value : this.countN,
  );
  CourseRow copyWithCompanion(CoursesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      code: data.code.present ? data.code.value : this.code,
      department: data.department.present
          ? data.department.value
          : this.department,
      session: data.session.present ? data.session.value : this.session,
      semester: data.semester.present ? data.semester.value : this.semester,
      totalExpected: data.totalExpected.present
          ? data.totalExpected.value
          : this.totalExpected,
      countRule: data.countRule.present ? data.countRule.value : this.countRule,
      countN: data.countN.present ? data.countN.value : this.countN,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('code: $code, ')
          ..write('department: $department, ')
          ..write('session: $session, ')
          ..write('semester: $semester, ')
          ..write('totalExpected: $totalExpected, ')
          ..write('countRule: $countRule, ')
          ..write('countN: $countN')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    code,
    department,
    session,
    semester,
    totalExpected,
    countRule,
    countN,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.code == this.code &&
          other.department == this.department &&
          other.session == this.session &&
          other.semester == this.semester &&
          other.totalExpected == this.totalExpected &&
          other.countRule == this.countRule &&
          other.countN == this.countN);
}

class CoursesCompanion extends UpdateCompanion<CourseRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> code;
  final Value<String> department;
  final Value<String> session;
  final Value<String> semester;
  final Value<double> totalExpected;
  final Value<String> countRule;
  final Value<int?> countN;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.department = const Value.absent(),
    this.session = const Value.absent(),
    this.semester = const Value.absent(),
    this.totalExpected = const Value.absent(),
    this.countRule = const Value.absent(),
    this.countN = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String code,
    this.department = const Value.absent(),
    this.session = const Value.absent(),
    this.semester = const Value.absent(),
    this.totalExpected = const Value.absent(),
    this.countRule = const Value.absent(),
    this.countN = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code);
  static Insertable<CourseRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? code,
    Expression<String>? department,
    Expression<String>? session,
    Expression<String>? semester,
    Expression<double>? totalExpected,
    Expression<String>? countRule,
    Expression<int>? countN,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (code != null) 'code': code,
      if (department != null) 'department': department,
      if (session != null) 'session': session,
      if (semester != null) 'semester': semester,
      if (totalExpected != null) 'total_expected': totalExpected,
      if (countRule != null) 'count_rule': countRule,
      if (countN != null) 'count_n': countN,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? code,
    Value<String>? department,
    Value<String>? session,
    Value<String>? semester,
    Value<double>? totalExpected,
    Value<String>? countRule,
    Value<int?>? countN,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      code: code ?? this.code,
      department: department ?? this.department,
      session: session ?? this.session,
      semester: semester ?? this.semester,
      totalExpected: totalExpected ?? this.totalExpected,
      countRule: countRule ?? this.countRule,
      countN: countN ?? this.countN,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (session.present) {
      map['session'] = Variable<String>(session.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (totalExpected.present) {
      map['total_expected'] = Variable<double>(totalExpected.value);
    }
    if (countRule.present) {
      map['count_rule'] = Variable<String>(countRule.value);
    }
    if (countN.present) {
      map['count_n'] = Variable<int>(countN.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('code: $code, ')
          ..write('department: $department, ')
          ..write('session: $session, ')
          ..write('semester: $semester, ')
          ..write('totalExpected: $totalExpected, ')
          ..write('countRule: $countRule, ')
          ..write('countN: $countN, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoursePartsTable extends CourseParts
    with TableInfo<$CoursePartsTable, CoursePartRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursePartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxMeta = const VerificationMeta('max');
  @override
  late final GeneratedColumn<double> max = GeneratedColumn<double>(
    'max',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minMeta = const VerificationMeta('min');
  @override
  late final GeneratedColumn<double> min = GeneratedColumn<double>(
    'min',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _passMarkMeta = const VerificationMeta(
    'passMark',
  );
  @override
  late final GeneratedColumn<double> passMark = GeneratedColumn<double>(
    'pass_mark',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<double> step = GeneratedColumn<double>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _markedOutOfMeta = const VerificationMeta(
    'markedOutOf',
  );
  @override
  late final GeneratedColumn<double> markedOutOf = GeneratedColumn<double>(
    'marked_out_of',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countsForMeta = const VerificationMeta(
    'countsFor',
  );
  @override
  late final GeneratedColumn<double> countsFor = GeneratedColumn<double>(
    'counts_for',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('typed'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    name,
    max,
    min,
    passMark,
    step,
    markedOutOf,
    countsFor,
    source,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_part';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoursePartRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('max')) {
      context.handle(
        _maxMeta,
        max.isAcceptableOrUnknown(data['max']!, _maxMeta),
      );
    } else if (isInserting) {
      context.missing(_maxMeta);
    }
    if (data.containsKey('min')) {
      context.handle(
        _minMeta,
        min.isAcceptableOrUnknown(data['min']!, _minMeta),
      );
    }
    if (data.containsKey('pass_mark')) {
      context.handle(
        _passMarkMeta,
        passMark.isAcceptableOrUnknown(data['pass_mark']!, _passMarkMeta),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('marked_out_of')) {
      context.handle(
        _markedOutOfMeta,
        markedOutOf.isAcceptableOrUnknown(
          data['marked_out_of']!,
          _markedOutOfMeta,
        ),
      );
    }
    if (data.containsKey('counts_for')) {
      context.handle(
        _countsForMeta,
        countsFor.isAcceptableOrUnknown(data['counts_for']!, _countsForMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoursePartRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoursePartRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      max: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max'],
      )!,
      min: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min'],
      )!,
      passMark: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pass_mark'],
      ),
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}step'],
      )!,
      markedOutOf: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}marked_out_of'],
      ),
      countsFor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}counts_for'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CoursePartsTable createAlias(String alias) {
    return $CoursePartsTable(attachedDatabase, alias);
  }
}

class CoursePartRow extends DataClass implements Insertable<CoursePartRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;
  final String name;
  final double max;
  final double min;
  final double? passMark;
  final double step;

  /// Null means "same as max".
  final double? markedOutOf;

  /// Null means "same as max".
  final double? countsFor;

  /// `scanned`, `typed` or `imported`.
  final String source;
  final int sortOrder;
  const CoursePartRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    required this.name,
    required this.max,
    required this.min,
    this.passMark,
    required this.step,
    this.markedOutOf,
    this.countsFor,
    required this.source,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    map['name'] = Variable<String>(name);
    map['max'] = Variable<double>(max);
    map['min'] = Variable<double>(min);
    if (!nullToAbsent || passMark != null) {
      map['pass_mark'] = Variable<double>(passMark);
    }
    map['step'] = Variable<double>(step);
    if (!nullToAbsent || markedOutOf != null) {
      map['marked_out_of'] = Variable<double>(markedOutOf);
    }
    if (!nullToAbsent || countsFor != null) {
      map['counts_for'] = Variable<double>(countsFor);
    }
    map['source'] = Variable<String>(source);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CoursePartsCompanion toCompanion(bool nullToAbsent) {
    return CoursePartsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      name: Value(name),
      max: Value(max),
      min: Value(min),
      passMark: passMark == null && nullToAbsent
          ? const Value.absent()
          : Value(passMark),
      step: Value(step),
      markedOutOf: markedOutOf == null && nullToAbsent
          ? const Value.absent()
          : Value(markedOutOf),
      countsFor: countsFor == null && nullToAbsent
          ? const Value.absent()
          : Value(countsFor),
      source: Value(source),
      sortOrder: Value(sortOrder),
    );
  }

  factory CoursePartRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoursePartRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      name: serializer.fromJson<String>(json['name']),
      max: serializer.fromJson<double>(json['max']),
      min: serializer.fromJson<double>(json['min']),
      passMark: serializer.fromJson<double?>(json['passMark']),
      step: serializer.fromJson<double>(json['step']),
      markedOutOf: serializer.fromJson<double?>(json['markedOutOf']),
      countsFor: serializer.fromJson<double?>(json['countsFor']),
      source: serializer.fromJson<String>(json['source']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'name': serializer.toJson<String>(name),
      'max': serializer.toJson<double>(max),
      'min': serializer.toJson<double>(min),
      'passMark': serializer.toJson<double?>(passMark),
      'step': serializer.toJson<double>(step),
      'markedOutOf': serializer.toJson<double?>(markedOutOf),
      'countsFor': serializer.toJson<double?>(countsFor),
      'source': serializer.toJson<String>(source),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CoursePartRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    String? name,
    double? max,
    double? min,
    Value<double?> passMark = const Value.absent(),
    double? step,
    Value<double?> markedOutOf = const Value.absent(),
    Value<double?> countsFor = const Value.absent(),
    String? source,
    int? sortOrder,
  }) => CoursePartRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    name: name ?? this.name,
    max: max ?? this.max,
    min: min ?? this.min,
    passMark: passMark.present ? passMark.value : this.passMark,
    step: step ?? this.step,
    markedOutOf: markedOutOf.present ? markedOutOf.value : this.markedOutOf,
    countsFor: countsFor.present ? countsFor.value : this.countsFor,
    source: source ?? this.source,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CoursePartRow copyWithCompanion(CoursePartsCompanion data) {
    return CoursePartRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      name: data.name.present ? data.name.value : this.name,
      max: data.max.present ? data.max.value : this.max,
      min: data.min.present ? data.min.value : this.min,
      passMark: data.passMark.present ? data.passMark.value : this.passMark,
      step: data.step.present ? data.step.value : this.step,
      markedOutOf: data.markedOutOf.present
          ? data.markedOutOf.value
          : this.markedOutOf,
      countsFor: data.countsFor.present ? data.countsFor.value : this.countsFor,
      source: data.source.present ? data.source.value : this.source,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoursePartRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('max: $max, ')
          ..write('min: $min, ')
          ..write('passMark: $passMark, ')
          ..write('step: $step, ')
          ..write('markedOutOf: $markedOutOf, ')
          ..write('countsFor: $countsFor, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    courseId,
    name,
    max,
    min,
    passMark,
    step,
    markedOutOf,
    countsFor,
    source,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoursePartRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.name == this.name &&
          other.max == this.max &&
          other.min == this.min &&
          other.passMark == this.passMark &&
          other.step == this.step &&
          other.markedOutOf == this.markedOutOf &&
          other.countsFor == this.countsFor &&
          other.source == this.source &&
          other.sortOrder == this.sortOrder);
}

class CoursePartsCompanion extends UpdateCompanion<CoursePartRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<String> name;
  final Value<double> max;
  final Value<double> min;
  final Value<double?> passMark;
  final Value<double> step;
  final Value<double?> markedOutOf;
  final Value<double?> countsFor;
  final Value<String> source;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CoursePartsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.name = const Value.absent(),
    this.max = const Value.absent(),
    this.min = const Value.absent(),
    this.passMark = const Value.absent(),
    this.step = const Value.absent(),
    this.markedOutOf = const Value.absent(),
    this.countsFor = const Value.absent(),
    this.source = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursePartsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    required String name,
    required double max,
    this.min = const Value.absent(),
    this.passMark = const Value.absent(),
    this.step = const Value.absent(),
    this.markedOutOf = const Value.absent(),
    this.countsFor = const Value.absent(),
    this.source = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       name = Value(name),
       max = Value(max);
  static Insertable<CoursePartRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<String>? name,
    Expression<double>? max,
    Expression<double>? min,
    Expression<double>? passMark,
    Expression<double>? step,
    Expression<double>? markedOutOf,
    Expression<double>? countsFor,
    Expression<String>? source,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (name != null) 'name': name,
      if (max != null) 'max': max,
      if (min != null) 'min': min,
      if (passMark != null) 'pass_mark': passMark,
      if (step != null) 'step': step,
      if (markedOutOf != null) 'marked_out_of': markedOutOf,
      if (countsFor != null) 'counts_for': countsFor,
      if (source != null) 'source': source,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursePartsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<String>? name,
    Value<double>? max,
    Value<double>? min,
    Value<double?>? passMark,
    Value<double>? step,
    Value<double?>? markedOutOf,
    Value<double?>? countsFor,
    Value<String>? source,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CoursePartsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      max: max ?? this.max,
      min: min ?? this.min,
      passMark: passMark ?? this.passMark,
      step: step ?? this.step,
      markedOutOf: markedOutOf ?? this.markedOutOf,
      countsFor: countsFor ?? this.countsFor,
      source: source ?? this.source,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (max.present) {
      map['max'] = Variable<double>(max.value);
    }
    if (min.present) {
      map['min'] = Variable<double>(min.value);
    }
    if (passMark.present) {
      map['pass_mark'] = Variable<double>(passMark.value);
    }
    if (step.present) {
      map['step'] = Variable<double>(step.value);
    }
    if (markedOutOf.present) {
      map['marked_out_of'] = Variable<double>(markedOutOf.value);
    }
    if (countsFor.present) {
      map['counts_for'] = Variable<double>(countsFor.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursePartsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('max: $max, ')
          ..write('min: $min, ')
          ..write('passMark: $passMark, ')
          ..write('step: $step, ')
          ..write('markedOutOf: $markedOutOf, ')
          ..write('countsFor: $countsFor, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamQuestionsTable extends ExamQuestions
    with TableInfo<$ExamQuestionsTable, ExamQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _qNoMeta = const VerificationMeta('qNo');
  @override
  late final GeneratedColumn<int> qNo = GeneratedColumn<int>(
    'q_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxMeta = const VerificationMeta('max');
  @override
  late final GeneratedColumn<double> max = GeneratedColumn<double>(
    'max',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compulsoryMeta = const VerificationMeta(
    'compulsory',
  );
  @override
  late final GeneratedColumn<bool> compulsory = GeneratedColumn<bool>(
    'compulsory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("compulsory" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    qNo,
    max,
    compulsory,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_question';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('q_no')) {
      context.handle(
        _qNoMeta,
        qNo.isAcceptableOrUnknown(data['q_no']!, _qNoMeta),
      );
    } else if (isInserting) {
      context.missing(_qNoMeta);
    }
    if (data.containsKey('max')) {
      context.handle(
        _maxMeta,
        max.isAcceptableOrUnknown(data['max']!, _maxMeta),
      );
    } else if (isInserting) {
      context.missing(_maxMeta);
    }
    if (data.containsKey('compulsory')) {
      context.handle(
        _compulsoryMeta,
        compulsory.isAcceptableOrUnknown(data['compulsory']!, _compulsoryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExamQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      qNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}q_no'],
      )!,
      max: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max'],
      )!,
      compulsory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}compulsory'],
      )!,
    );
  }

  @override
  $ExamQuestionsTable createAlias(String alias) {
    return $ExamQuestionsTable(attachedDatabase, alias);
  }
}

class ExamQuestionRow extends DataClass implements Insertable<ExamQuestionRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;
  final int qNo;
  final double max;
  final bool compulsory;
  const ExamQuestionRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    required this.qNo,
    required this.max,
    required this.compulsory,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    map['q_no'] = Variable<int>(qNo);
    map['max'] = Variable<double>(max);
    map['compulsory'] = Variable<bool>(compulsory);
    return map;
  }

  ExamQuestionsCompanion toCompanion(bool nullToAbsent) {
    return ExamQuestionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      qNo: Value(qNo),
      max: Value(max),
      compulsory: Value(compulsory),
    );
  }

  factory ExamQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamQuestionRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      qNo: serializer.fromJson<int>(json['qNo']),
      max: serializer.fromJson<double>(json['max']),
      compulsory: serializer.fromJson<bool>(json['compulsory']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'qNo': serializer.toJson<int>(qNo),
      'max': serializer.toJson<double>(max),
      'compulsory': serializer.toJson<bool>(compulsory),
    };
  }

  ExamQuestionRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    int? qNo,
    double? max,
    bool? compulsory,
  }) => ExamQuestionRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    qNo: qNo ?? this.qNo,
    max: max ?? this.max,
    compulsory: compulsory ?? this.compulsory,
  );
  ExamQuestionRow copyWithCompanion(ExamQuestionsCompanion data) {
    return ExamQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      qNo: data.qNo.present ? data.qNo.value : this.qNo,
      max: data.max.present ? data.max.value : this.max,
      compulsory: data.compulsory.present
          ? data.compulsory.value
          : this.compulsory,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamQuestionRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('qNo: $qNo, ')
          ..write('max: $max, ')
          ..write('compulsory: $compulsory')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, courseId, qNo, max, compulsory);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamQuestionRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.qNo == this.qNo &&
          other.max == this.max &&
          other.compulsory == this.compulsory);
}

class ExamQuestionsCompanion extends UpdateCompanion<ExamQuestionRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<int> qNo;
  final Value<double> max;
  final Value<bool> compulsory;
  final Value<int> rowid;
  const ExamQuestionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.qNo = const Value.absent(),
    this.max = const Value.absent(),
    this.compulsory = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamQuestionsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    required int qNo,
    required double max,
    this.compulsory = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       qNo = Value(qNo),
       max = Value(max);
  static Insertable<ExamQuestionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<int>? qNo,
    Expression<double>? max,
    Expression<bool>? compulsory,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (qNo != null) 'q_no': qNo,
      if (max != null) 'max': max,
      if (compulsory != null) 'compulsory': compulsory,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamQuestionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<int>? qNo,
    Value<double>? max,
    Value<bool>? compulsory,
    Value<int>? rowid,
  }) {
    return ExamQuestionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      qNo: qNo ?? this.qNo,
      max: max ?? this.max,
      compulsory: compulsory ?? this.compulsory,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (qNo.present) {
      map['q_no'] = Variable<int>(qNo.value);
    }
    if (max.present) {
      map['max'] = Variable<double>(max.value);
    }
    if (compulsory.present) {
      map['compulsory'] = Variable<bool>(compulsory.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('qNo: $qNo, ')
          ..write('max: $max, ')
          ..write('compulsory: $compulsory, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GradeScalesTable extends GradeScales
    with TableInfo<$GradeScalesTable, GradeScaleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradeScalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _minScoreMeta = const VerificationMeta(
    'minScore',
  );
  @override
  late final GeneratedColumn<double> minScore = GeneratedColumn<double>(
    'min_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<double> maxScore = GeneratedColumn<double>(
    'max_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _letterMeta = const VerificationMeta('letter');
  @override
  late final GeneratedColumn<String> letter = GeneratedColumn<String>(
    'letter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<double> points = GeneratedColumn<double>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    minScore,
    maxScore,
    letter,
    points,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grade_scale';
  @override
  VerificationContext validateIntegrity(
    Insertable<GradeScaleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('min_score')) {
      context.handle(
        _minScoreMeta,
        minScore.isAcceptableOrUnknown(data['min_score']!, _minScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_minScoreMeta);
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_maxScoreMeta);
    }
    if (data.containsKey('letter')) {
      context.handle(
        _letterMeta,
        letter.isAcceptableOrUnknown(data['letter']!, _letterMeta),
      );
    } else if (isInserting) {
      context.missing(_letterMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradeScaleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradeScaleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      minScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_score'],
      )!,
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_score'],
      )!,
      letter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}points'],
      )!,
    );
  }

  @override
  $GradeScalesTable createAlias(String alias) {
    return $GradeScalesTable(attachedDatabase, alias);
  }
}

class GradeScaleRow extends DataClass implements Insertable<GradeScaleRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;
  final double minScore;
  final double maxScore;
  final String letter;
  final double points;
  const GradeScaleRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    required this.minScore,
    required this.maxScore,
    required this.letter,
    required this.points,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    map['min_score'] = Variable<double>(minScore);
    map['max_score'] = Variable<double>(maxScore);
    map['letter'] = Variable<String>(letter);
    map['points'] = Variable<double>(points);
    return map;
  }

  GradeScalesCompanion toCompanion(bool nullToAbsent) {
    return GradeScalesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      minScore: Value(minScore),
      maxScore: Value(maxScore),
      letter: Value(letter),
      points: Value(points),
    );
  }

  factory GradeScaleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradeScaleRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      minScore: serializer.fromJson<double>(json['minScore']),
      maxScore: serializer.fromJson<double>(json['maxScore']),
      letter: serializer.fromJson<String>(json['letter']),
      points: serializer.fromJson<double>(json['points']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'minScore': serializer.toJson<double>(minScore),
      'maxScore': serializer.toJson<double>(maxScore),
      'letter': serializer.toJson<String>(letter),
      'points': serializer.toJson<double>(points),
    };
  }

  GradeScaleRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    double? minScore,
    double? maxScore,
    String? letter,
    double? points,
  }) => GradeScaleRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    minScore: minScore ?? this.minScore,
    maxScore: maxScore ?? this.maxScore,
    letter: letter ?? this.letter,
    points: points ?? this.points,
  );
  GradeScaleRow copyWithCompanion(GradeScalesCompanion data) {
    return GradeScaleRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      minScore: data.minScore.present ? data.minScore.value : this.minScore,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      letter: data.letter.present ? data.letter.value : this.letter,
      points: data.points.present ? data.points.value : this.points,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradeScaleRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('minScore: $minScore, ')
          ..write('maxScore: $maxScore, ')
          ..write('letter: $letter, ')
          ..write('points: $points')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    courseId,
    minScore,
    maxScore,
    letter,
    points,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradeScaleRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.minScore == this.minScore &&
          other.maxScore == this.maxScore &&
          other.letter == this.letter &&
          other.points == this.points);
}

class GradeScalesCompanion extends UpdateCompanion<GradeScaleRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<double> minScore;
  final Value<double> maxScore;
  final Value<String> letter;
  final Value<double> points;
  final Value<int> rowid;
  const GradeScalesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.minScore = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.letter = const Value.absent(),
    this.points = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GradeScalesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    required double minScore,
    required double maxScore,
    required String letter,
    this.points = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       minScore = Value(minScore),
       maxScore = Value(maxScore),
       letter = Value(letter);
  static Insertable<GradeScaleRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<double>? minScore,
    Expression<double>? maxScore,
    Expression<String>? letter,
    Expression<double>? points,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (minScore != null) 'min_score': minScore,
      if (maxScore != null) 'max_score': maxScore,
      if (letter != null) 'letter': letter,
      if (points != null) 'points': points,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GradeScalesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<double>? minScore,
    Value<double>? maxScore,
    Value<String>? letter,
    Value<double>? points,
    Value<int>? rowid,
  }) {
    return GradeScalesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      letter: letter ?? this.letter,
      points: points ?? this.points,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (minScore.present) {
      map['min_score'] = Variable<double>(minScore.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<double>(maxScore.value);
    }
    if (letter.present) {
      map['letter'] = Variable<String>(letter.value);
    }
    if (points.present) {
      map['points'] = Variable<double>(points.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradeScalesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('minScore: $minScore, ')
          ..write('maxScore: $maxScore, ')
          ..write('letter: $letter, ')
          ..write('points: $points, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemeTemplatesTable extends SchemeTemplates
    with TableInfo<$SchemeTemplatesTable, SchemeTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemeTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, deletedAt, name, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheme_template';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemeTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchemeTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemeTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $SchemeTemplatesTable createAlias(String alias) {
    return $SchemeTemplatesTable(attachedDatabase, alias);
  }
}

class SchemeTemplateRow extends DataClass
    implements Insertable<SchemeTemplateRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final String json;
  const SchemeTemplateRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['json'] = Variable<String>(json);
    return map;
  }

  SchemeTemplatesCompanion toCompanion(bool nullToAbsent) {
    return SchemeTemplatesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      json: Value(json),
    );
  }

  factory SchemeTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemeTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'json': serializer.toJson<String>(json),
    };
  }

  SchemeTemplateRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? json,
  }) => SchemeTemplateRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    json: json ?? this.json,
  );
  SchemeTemplateRow copyWithCompanion(SchemeTemplatesCompanion data) {
    return SchemeTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemeTemplateRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deletedAt, name, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemeTemplateRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.json == this.json);
}

class SchemeTemplatesCompanion extends UpdateCompanion<SchemeTemplateRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> json;
  final Value<int> rowid;
  const SchemeTemplatesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchemeTemplatesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String name,
    required String json,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       json = Value(json);
  static Insertable<SchemeTemplateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchemeTemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return SchemeTemplatesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemeTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students
    with TableInfo<$StudentsTable, StudentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _regNoMeta = const VerificationMeta('regNo');
  @override
  late final GeneratedColumn<String> regNo = GeneratedColumn<String>(
    'reg_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onClassListMeta = const VerificationMeta(
    'onClassList',
  );
  @override
  late final GeneratedColumn<bool> onClassList = GeneratedColumn<bool>(
    'on_class_list',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_class_list" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    regNo,
    name,
    onClassList,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('reg_no')) {
      context.handle(
        _regNoMeta,
        regNo.isAcceptableOrUnknown(data['reg_no']!, _regNoMeta),
      );
    } else if (isInserting) {
      context.missing(_regNoMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('on_class_list')) {
      context.handle(
        _onClassListMeta,
        onClassList.isAcceptableOrUnknown(
          data['on_class_list']!,
          _onClassListMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      regNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reg_no'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      onClassList: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_class_list'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class StudentRow extends DataClass implements Insertable<StudentRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;

  /// Stored in one form: upper case DEPT/YYU/NNNN, optional middle part.
  final String regNo;
  final String? name;

  /// False for numbers added by hand that were not on the imported list.
  final bool onClassList;

  /// Order added; the "scan order" for exports.
  final int position;
  const StudentRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    required this.regNo,
    this.name,
    required this.onClassList,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    map['reg_no'] = Variable<String>(regNo);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['on_class_list'] = Variable<bool>(onClassList);
    map['position'] = Variable<int>(position);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      regNo: Value(regNo),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      onClassList: Value(onClassList),
      position: Value(position),
    );
  }

  factory StudentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      regNo: serializer.fromJson<String>(json['regNo']),
      name: serializer.fromJson<String?>(json['name']),
      onClassList: serializer.fromJson<bool>(json['onClassList']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'regNo': serializer.toJson<String>(regNo),
      'name': serializer.toJson<String?>(name),
      'onClassList': serializer.toJson<bool>(onClassList),
      'position': serializer.toJson<int>(position),
    };
  }

  StudentRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    String? regNo,
    Value<String?> name = const Value.absent(),
    bool? onClassList,
    int? position,
  }) => StudentRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    regNo: regNo ?? this.regNo,
    name: name.present ? name.value : this.name,
    onClassList: onClassList ?? this.onClassList,
    position: position ?? this.position,
  );
  StudentRow copyWithCompanion(StudentsCompanion data) {
    return StudentRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      regNo: data.regNo.present ? data.regNo.value : this.regNo,
      name: data.name.present ? data.name.value : this.name,
      onClassList: data.onClassList.present
          ? data.onClassList.value
          : this.onClassList,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('regNo: $regNo, ')
          ..write('name: $name, ')
          ..write('onClassList: $onClassList, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    courseId,
    regNo,
    name,
    onClassList,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.regNo == this.regNo &&
          other.name == this.name &&
          other.onClassList == this.onClassList &&
          other.position == this.position);
}

class StudentsCompanion extends UpdateCompanion<StudentRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<String> regNo;
  final Value<String?> name;
  final Value<bool> onClassList;
  final Value<int> position;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.regNo = const Value.absent(),
    this.name = const Value.absent(),
    this.onClassList = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    required String regNo,
    this.name = const Value.absent(),
    this.onClassList = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       regNo = Value(regNo);
  static Insertable<StudentRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<String>? regNo,
    Expression<String>? name,
    Expression<bool>? onClassList,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (regNo != null) 'reg_no': regNo,
      if (name != null) 'name': name,
      if (onClassList != null) 'on_class_list': onClassList,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<String>? regNo,
    Value<String?>? name,
    Value<bool>? onClassList,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      regNo: regNo ?? this.regNo,
      name: name ?? this.name,
      onClassList: onClassList ?? this.onClassList,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (regNo.present) {
      map['reg_no'] = Variable<String>(regNo.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (onClassList.present) {
      map['on_class_list'] = Variable<bool>(onClassList.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('regNo: $regNo, ')
          ..write('name: $name, ')
          ..write('onClassList: $onClassList, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchesTable extends Batches with TableInfo<$BatchesTable, BatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    title,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_batch';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BatchesTable createAlias(String alias) {
    return $BatchesTable(attachedDatabase, alias);
  }
}

class BatchRow extends DataClass implements Insertable<BatchRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;

  /// Optional name the examiner gave it. Shown as "Batch of 12 Oct" when empty.
  final String? title;
  final DateTime createdAt;
  const BatchRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    this.title,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BatchesCompanion toCompanion(bool nullToAbsent) {
    return BatchesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      createdAt: Value(createdAt),
    );
  }

  factory BatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'title': serializer.toJson<String?>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BatchRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    Value<String?> title = const Value.absent(),
    DateTime? createdAt,
  }) => BatchRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    title: title.present ? title.value : this.title,
    createdAt: createdAt ?? this.createdAt,
  );
  BatchRow copyWithCompanion(BatchesCompanion data) {
    return BatchRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, courseId, title, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.title == this.title &&
          other.createdAt == this.createdAt);
}

class BatchesCompanion extends UpdateCompanion<BatchRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<String?> title;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BatchesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId);
  static Insertable<BatchRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<String?>? title,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BatchesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScansTable extends Scans with TableInfo<$ScansTable, ScanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageNoMeta = const VerificationMeta('pageNo');
  @override
  late final GeneratedColumn<int> pageNo = GeneratedColumn<int>(
    'page_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scanned'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES upload_batch (id)',
    ),
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    kind,
    photoPath,
    pageNo,
    status,
    createdAt,
    batchId,
    originalName,
    contentHash,
    width,
    height,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('page_no')) {
      context.handle(
        _pageNoMeta,
        pageNo.isAcceptableOrUnknown(data['page_no']!, _pageNoMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      pageNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_no'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ScansTable createAlias(String alias) {
    return $ScansTable(attachedDatabase, alias);
  }
}

class ScanRow extends DataClass implements Insertable<ScanRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;

  /// `booklet_cover` or `list_sheet`.
  final String kind;
  final String? photoPath;
  final int pageNo;
  final String status;
  final DateTime createdAt;
  final String? batchId;

  /// The file name the examiner's phone gave the image.
  final String? originalName;

  /// SHA-256 of the image bytes, to catch the same photo added twice.
  final String? contentHash;
  final int? width;
  final int? height;

  /// Why reading failed, in words the examiner can act on.
  final String? errorMessage;
  const ScanRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    required this.kind,
    this.photoPath,
    required this.pageNo,
    required this.status,
    required this.createdAt,
    this.batchId,
    this.originalName,
    this.contentHash,
    this.width,
    this.height,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['page_no'] = Variable<int>(pageNo);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    if (!nullToAbsent || originalName != null) {
      map['original_name'] = Variable<String>(originalName);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ScansCompanion toCompanion(bool nullToAbsent) {
    return ScansCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      kind: Value(kind),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      pageNo: Value(pageNo),
      status: Value(status),
      createdAt: Value(createdAt),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      originalName: originalName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalName),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ScanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      kind: serializer.fromJson<String>(json['kind']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      pageNo: serializer.fromJson<int>(json['pageNo']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      originalName: serializer.fromJson<String?>(json['originalName']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'kind': serializer.toJson<String>(kind),
      'photoPath': serializer.toJson<String?>(photoPath),
      'pageNo': serializer.toJson<int>(pageNo),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'batchId': serializer.toJson<String?>(batchId),
      'originalName': serializer.toJson<String?>(originalName),
      'contentHash': serializer.toJson<String?>(contentHash),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ScanRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    String? kind,
    Value<String?> photoPath = const Value.absent(),
    int? pageNo,
    String? status,
    DateTime? createdAt,
    Value<String?> batchId = const Value.absent(),
    Value<String?> originalName = const Value.absent(),
    Value<String?> contentHash = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => ScanRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    kind: kind ?? this.kind,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    pageNo: pageNo ?? this.pageNo,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    batchId: batchId.present ? batchId.value : this.batchId,
    originalName: originalName.present ? originalName.value : this.originalName,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ScanRow copyWithCompanion(ScansCompanion data) {
    return ScanRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      kind: data.kind.present ? data.kind.value : this.kind,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      pageNo: data.pageNo.present ? data.pageNo.value : this.pageNo,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('kind: $kind, ')
          ..write('photoPath: $photoPath, ')
          ..write('pageNo: $pageNo, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('batchId: $batchId, ')
          ..write('originalName: $originalName, ')
          ..write('contentHash: $contentHash, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    courseId,
    kind,
    photoPath,
    pageNo,
    status,
    createdAt,
    batchId,
    originalName,
    contentHash,
    width,
    height,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.kind == this.kind &&
          other.photoPath == this.photoPath &&
          other.pageNo == this.pageNo &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.batchId == this.batchId &&
          other.originalName == this.originalName &&
          other.contentHash == this.contentHash &&
          other.width == this.width &&
          other.height == this.height &&
          other.errorMessage == this.errorMessage);
}

class ScansCompanion extends UpdateCompanion<ScanRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<String> kind;
  final Value<String?> photoPath;
  final Value<int> pageNo;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String?> batchId;
  final Value<String?> originalName;
  final Value<String?> contentHash;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const ScansCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.kind = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.pageNo = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.batchId = const Value.absent(),
    this.originalName = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScansCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    required String kind,
    this.photoPath = const Value.absent(),
    this.pageNo = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.batchId = const Value.absent(),
    this.originalName = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       kind = Value(kind);
  static Insertable<ScanRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<String>? kind,
    Expression<String>? photoPath,
    Expression<int>? pageNo,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? batchId,
    Expression<String>? originalName,
    Expression<String>? contentHash,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (kind != null) 'kind': kind,
      if (photoPath != null) 'photo_path': photoPath,
      if (pageNo != null) 'page_no': pageNo,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (batchId != null) 'batch_id': batchId,
      if (originalName != null) 'original_name': originalName,
      if (contentHash != null) 'content_hash': contentHash,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScansCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<String>? kind,
    Value<String?>? photoPath,
    Value<int>? pageNo,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<String?>? batchId,
    Value<String?>? originalName,
    Value<String?>? contentHash,
    Value<int?>? width,
    Value<int?>? height,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return ScansCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      kind: kind ?? this.kind,
      photoPath: photoPath ?? this.photoPath,
      pageNo: pageNo ?? this.pageNo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      batchId: batchId ?? this.batchId,
      originalName: originalName ?? this.originalName,
      contentHash: contentHash ?? this.contentHash,
      width: width ?? this.width,
      height: height ?? this.height,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (pageNo.present) {
      map['page_no'] = Variable<int>(pageNo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScansCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('kind: $kind, ')
          ..write('photoPath: $photoPath, ')
          ..write('pageNo: $pageNo, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('batchId: $batchId, ')
          ..write('originalName: $originalName, ')
          ..write('contentHash: $contentHash, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookletsTable extends Booklets
    with TableInfo<$BookletsTable, BookletRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES student (id)',
    ),
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _serialNoMeta = const VerificationMeta(
    'serialNo',
  );
  @override
  late final GeneratedColumn<String> serialNo = GeneratedColumn<String>(
    'serial_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readJsonMeta = const VerificationMeta(
    'readJson',
  );
  @override
  late final GeneratedColumn<String> readJson = GeneratedColumn<String>(
    'read_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scanned'),
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    studentId,
    scanId,
    serialNo,
    readJson,
    status,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'booklet';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookletRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    }
    if (data.containsKey('serial_no')) {
      context.handle(
        _serialNoMeta,
        serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta),
      );
    }
    if (data.containsKey('read_json')) {
      context.handle(
        _readJsonMeta,
        readJson.isAcceptableOrUnknown(data['read_json']!, _readJsonMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookletRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookletRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      ),
      serialNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_no'],
      ),
      readJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}read_json'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $BookletsTable createAlias(String alias) {
    return $BookletsTable(attachedDatabase, alias);
  }
}

class BookletRow extends DataClass implements Insertable<BookletRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;
  final String? studentId;
  final String? scanId;
  final String? serialNo;
  final String? readJson;

  /// `needs_review` until the examiner confirms it; then `confirmed`.
  final String status;
  final DateTime? confirmedAt;
  const BookletRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    this.studentId,
    this.scanId,
    this.serialNo,
    this.readJson,
    required this.status,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    if (!nullToAbsent || scanId != null) {
      map['scan_id'] = Variable<String>(scanId);
    }
    if (!nullToAbsent || serialNo != null) {
      map['serial_no'] = Variable<String>(serialNo);
    }
    if (!nullToAbsent || readJson != null) {
      map['read_json'] = Variable<String>(readJson);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  BookletsCompanion toCompanion(bool nullToAbsent) {
    return BookletsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      scanId: scanId == null && nullToAbsent
          ? const Value.absent()
          : Value(scanId),
      serialNo: serialNo == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNo),
      readJson: readJson == null && nullToAbsent
          ? const Value.absent()
          : Value(readJson),
      status: Value(status),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory BookletRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookletRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      scanId: serializer.fromJson<String?>(json['scanId']),
      serialNo: serializer.fromJson<String?>(json['serialNo']),
      readJson: serializer.fromJson<String?>(json['readJson']),
      status: serializer.fromJson<String>(json['status']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'studentId': serializer.toJson<String?>(studentId),
      'scanId': serializer.toJson<String?>(scanId),
      'serialNo': serializer.toJson<String?>(serialNo),
      'readJson': serializer.toJson<String?>(readJson),
      'status': serializer.toJson<String>(status),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  BookletRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    Value<String?> studentId = const Value.absent(),
    Value<String?> scanId = const Value.absent(),
    Value<String?> serialNo = const Value.absent(),
    Value<String?> readJson = const Value.absent(),
    String? status,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => BookletRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    studentId: studentId.present ? studentId.value : this.studentId,
    scanId: scanId.present ? scanId.value : this.scanId,
    serialNo: serialNo.present ? serialNo.value : this.serialNo,
    readJson: readJson.present ? readJson.value : this.readJson,
    status: status ?? this.status,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  BookletRow copyWithCompanion(BookletsCompanion data) {
    return BookletRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
      readJson: data.readJson.present ? data.readJson.value : this.readJson,
      status: data.status.present ? data.status.value : this.status,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookletRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('studentId: $studentId, ')
          ..write('scanId: $scanId, ')
          ..write('serialNo: $serialNo, ')
          ..write('readJson: $readJson, ')
          ..write('status: $status, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    courseId,
    studentId,
    scanId,
    serialNo,
    readJson,
    status,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookletRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.studentId == this.studentId &&
          other.scanId == this.scanId &&
          other.serialNo == this.serialNo &&
          other.readJson == this.readJson &&
          other.status == this.status &&
          other.confirmedAt == this.confirmedAt);
}

class BookletsCompanion extends UpdateCompanion<BookletRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<String?> studentId;
  final Value<String?> scanId;
  final Value<String?> serialNo;
  final Value<String?> readJson;
  final Value<String> status;
  final Value<DateTime?> confirmedAt;
  final Value<int> rowid;
  const BookletsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.readJson = const Value.absent(),
    this.status = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookletsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    this.studentId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.readJson = const Value.absent(),
    this.status = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId);
  static Insertable<BookletRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<String>? studentId,
    Expression<String>? scanId,
    Expression<String>? serialNo,
    Expression<String>? readJson,
    Expression<String>? status,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (studentId != null) 'student_id': studentId,
      if (scanId != null) 'scan_id': scanId,
      if (serialNo != null) 'serial_no': serialNo,
      if (readJson != null) 'read_json': readJson,
      if (status != null) 'status': status,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookletsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<String?>? studentId,
    Value<String?>? scanId,
    Value<String?>? serialNo,
    Value<String?>? readJson,
    Value<String>? status,
    Value<DateTime?>? confirmedAt,
    Value<int>? rowid,
  }) {
    return BookletsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      scanId: scanId ?? this.scanId,
      serialNo: serialNo ?? this.serialNo,
      readJson: readJson ?? this.readJson,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<String>(serialNo.value);
    }
    if (readJson.present) {
      map['read_json'] = Variable<String>(readJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookletsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('studentId: $studentId, ')
          ..write('scanId: $scanId, ')
          ..write('serialNo: $serialNo, ')
          ..write('readJson: $readJson, ')
          ..write('status: $status, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionMarksTable extends QuestionMarks
    with TableInfo<$QuestionMarksTable, QuestionMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookletIdMeta = const VerificationMeta(
    'bookletId',
  );
  @override
  late final GeneratedColumn<String> bookletId = GeneratedColumn<String>(
    'booklet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES booklet (id)',
    ),
  );
  static const VerificationMeta _qNoMeta = const VerificationMeta('qNo');
  @override
  late final GeneratedColumn<int> qNo = GeneratedColumn<int>(
    'q_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markMeta = const VerificationMeta('mark');
  @override
  late final GeneratedColumn<double> mark = GeneratedColumn<double>(
    'mark',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedMeta = const VerificationMeta('edited');
  @override
  late final GeneratedColumn<bool> edited = GeneratedColumn<bool>(
    'edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    bookletId,
    qNo,
    mark,
    confidence,
    edited,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_mark';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('booklet_id')) {
      context.handle(
        _bookletIdMeta,
        bookletId.isAcceptableOrUnknown(data['booklet_id']!, _bookletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookletIdMeta);
    }
    if (data.containsKey('q_no')) {
      context.handle(
        _qNoMeta,
        qNo.isAcceptableOrUnknown(data['q_no']!, _qNoMeta),
      );
    } else if (isInserting) {
      context.missing(_qNoMeta);
    }
    if (data.containsKey('mark')) {
      context.handle(
        _markMeta,
        mark.isAcceptableOrUnknown(data['mark']!, _markMeta),
      );
    } else if (isInserting) {
      context.missing(_markMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('edited')) {
      context.handle(
        _editedMeta,
        edited.isAcceptableOrUnknown(data['edited']!, _editedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionMarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      bookletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booklet_id'],
      )!,
      qNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}q_no'],
      )!,
      mark: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mark'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      edited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited'],
      )!,
    );
  }

  @override
  $QuestionMarksTable createAlias(String alias) {
    return $QuestionMarksTable(attachedDatabase, alias);
  }
}

class QuestionMarkRow extends DataClass implements Insertable<QuestionMarkRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String bookletId;
  final int qNo;
  final double mark;
  final double? confidence;
  final bool edited;
  const QuestionMarkRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.bookletId,
    required this.qNo,
    required this.mark,
    this.confidence,
    required this.edited,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['booklet_id'] = Variable<String>(bookletId);
    map['q_no'] = Variable<int>(qNo);
    map['mark'] = Variable<double>(mark);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['edited'] = Variable<bool>(edited);
    return map;
  }

  QuestionMarksCompanion toCompanion(bool nullToAbsent) {
    return QuestionMarksCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      bookletId: Value(bookletId),
      qNo: Value(qNo),
      mark: Value(mark),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      edited: Value(edited),
    );
  }

  factory QuestionMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionMarkRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      bookletId: serializer.fromJson<String>(json['bookletId']),
      qNo: serializer.fromJson<int>(json['qNo']),
      mark: serializer.fromJson<double>(json['mark']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      edited: serializer.fromJson<bool>(json['edited']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'bookletId': serializer.toJson<String>(bookletId),
      'qNo': serializer.toJson<int>(qNo),
      'mark': serializer.toJson<double>(mark),
      'confidence': serializer.toJson<double?>(confidence),
      'edited': serializer.toJson<bool>(edited),
    };
  }

  QuestionMarkRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? bookletId,
    int? qNo,
    double? mark,
    Value<double?> confidence = const Value.absent(),
    bool? edited,
  }) => QuestionMarkRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    bookletId: bookletId ?? this.bookletId,
    qNo: qNo ?? this.qNo,
    mark: mark ?? this.mark,
    confidence: confidence.present ? confidence.value : this.confidence,
    edited: edited ?? this.edited,
  );
  QuestionMarkRow copyWithCompanion(QuestionMarksCompanion data) {
    return QuestionMarkRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      bookletId: data.bookletId.present ? data.bookletId.value : this.bookletId,
      qNo: data.qNo.present ? data.qNo.value : this.qNo,
      mark: data.mark.present ? data.mark.value : this.mark,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      edited: data.edited.present ? data.edited.value : this.edited,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionMarkRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('bookletId: $bookletId, ')
          ..write('qNo: $qNo, ')
          ..write('mark: $mark, ')
          ..write('confidence: $confidence, ')
          ..write('edited: $edited')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    bookletId,
    qNo,
    mark,
    confidence,
    edited,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionMarkRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.bookletId == this.bookletId &&
          other.qNo == this.qNo &&
          other.mark == this.mark &&
          other.confidence == this.confidence &&
          other.edited == this.edited);
}

class QuestionMarksCompanion extends UpdateCompanion<QuestionMarkRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> bookletId;
  final Value<int> qNo;
  final Value<double> mark;
  final Value<double?> confidence;
  final Value<bool> edited;
  final Value<int> rowid;
  const QuestionMarksCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.bookletId = const Value.absent(),
    this.qNo = const Value.absent(),
    this.mark = const Value.absent(),
    this.confidence = const Value.absent(),
    this.edited = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionMarksCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String bookletId,
    required int qNo,
    required double mark,
    this.confidence = const Value.absent(),
    this.edited = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookletId = Value(bookletId),
       qNo = Value(qNo),
       mark = Value(mark);
  static Insertable<QuestionMarkRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? bookletId,
    Expression<int>? qNo,
    Expression<double>? mark,
    Expression<double>? confidence,
    Expression<bool>? edited,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (bookletId != null) 'booklet_id': bookletId,
      if (qNo != null) 'q_no': qNo,
      if (mark != null) 'mark': mark,
      if (confidence != null) 'confidence': confidence,
      if (edited != null) 'edited': edited,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionMarksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? bookletId,
    Value<int>? qNo,
    Value<double>? mark,
    Value<double?>? confidence,
    Value<bool>? edited,
    Value<int>? rowid,
  }) {
    return QuestionMarksCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      bookletId: bookletId ?? this.bookletId,
      qNo: qNo ?? this.qNo,
      mark: mark ?? this.mark,
      confidence: confidence ?? this.confidence,
      edited: edited ?? this.edited,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (bookletId.present) {
      map['booklet_id'] = Variable<String>(bookletId.value);
    }
    if (qNo.present) {
      map['q_no'] = Variable<int>(qNo.value);
    }
    if (mark.present) {
      map['mark'] = Variable<double>(mark.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (edited.present) {
      map['edited'] = Variable<bool>(edited.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionMarksCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('bookletId: $bookletId, ')
          ..write('qNo: $qNo, ')
          ..write('mark: $mark, ')
          ..write('confidence: $confidence, ')
          ..write('edited: $edited, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RowReadsTable extends RowReads
    with TableInfo<$RowReadsTable, RowReadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RowReadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _rowNoMeta = const VerificationMeta('rowNo');
  @override
  late final GeneratedColumn<int> rowNo = GeneratedColumn<int>(
    'row_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawIdMeta = const VerificationMeta('rawId');
  @override
  late final GeneratedColumn<String> rawId = GeneratedColumn<String>(
    'raw_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawValueMeta = const VerificationMeta(
    'rawValue',
  );
  @override
  late final GeneratedColumn<String> rawValue = GeneratedColumn<String>(
    'raw_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES student (id)',
    ),
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<String> partId = GeneratedColumn<String>(
    'part_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_part (id)',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('read'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    scanId,
    rowNo,
    rawId,
    rawValue,
    studentId,
    partId,
    value,
    confidence,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'row_read';
  @override
  VerificationContext validateIntegrity(
    Insertable<RowReadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('row_no')) {
      context.handle(
        _rowNoMeta,
        rowNo.isAcceptableOrUnknown(data['row_no']!, _rowNoMeta),
      );
    } else if (isInserting) {
      context.missing(_rowNoMeta);
    }
    if (data.containsKey('raw_id')) {
      context.handle(
        _rawIdMeta,
        rawId.isAcceptableOrUnknown(data['raw_id']!, _rawIdMeta),
      );
    }
    if (data.containsKey('raw_value')) {
      context.handle(
        _rawValueMeta,
        rawValue.isAcceptableOrUnknown(data['raw_value']!, _rawValueMeta),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RowReadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RowReadRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      rowNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_no'],
      )!,
      rawId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_id'],
      ),
      rawValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_value'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_id'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $RowReadsTable createAlias(String alias) {
    return $RowReadsTable(attachedDatabase, alias);
  }
}

class RowReadRow extends DataClass implements Insertable<RowReadRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String scanId;
  final int rowNo;
  final String? rawId;
  final String? rawValue;
  final String? studentId;
  final String? partId;
  final double? value;
  final double? confidence;
  final String status;
  const RowReadRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.scanId,
    required this.rowNo,
    this.rawId,
    this.rawValue,
    this.studentId,
    this.partId,
    this.value,
    this.confidence,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['scan_id'] = Variable<String>(scanId);
    map['row_no'] = Variable<int>(rowNo);
    if (!nullToAbsent || rawId != null) {
      map['raw_id'] = Variable<String>(rawId);
    }
    if (!nullToAbsent || rawValue != null) {
      map['raw_value'] = Variable<String>(rawValue);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    if (!nullToAbsent || partId != null) {
      map['part_id'] = Variable<String>(partId);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  RowReadsCompanion toCompanion(bool nullToAbsent) {
    return RowReadsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      scanId: Value(scanId),
      rowNo: Value(rowNo),
      rawId: rawId == null && nullToAbsent
          ? const Value.absent()
          : Value(rawId),
      rawValue: rawValue == null && nullToAbsent
          ? const Value.absent()
          : Value(rawValue),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      partId: partId == null && nullToAbsent
          ? const Value.absent()
          : Value(partId),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      status: Value(status),
    );
  }

  factory RowReadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RowReadRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      scanId: serializer.fromJson<String>(json['scanId']),
      rowNo: serializer.fromJson<int>(json['rowNo']),
      rawId: serializer.fromJson<String?>(json['rawId']),
      rawValue: serializer.fromJson<String?>(json['rawValue']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      partId: serializer.fromJson<String?>(json['partId']),
      value: serializer.fromJson<double?>(json['value']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'scanId': serializer.toJson<String>(scanId),
      'rowNo': serializer.toJson<int>(rowNo),
      'rawId': serializer.toJson<String?>(rawId),
      'rawValue': serializer.toJson<String?>(rawValue),
      'studentId': serializer.toJson<String?>(studentId),
      'partId': serializer.toJson<String?>(partId),
      'value': serializer.toJson<double?>(value),
      'confidence': serializer.toJson<double?>(confidence),
      'status': serializer.toJson<String>(status),
    };
  }

  RowReadRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? scanId,
    int? rowNo,
    Value<String?> rawId = const Value.absent(),
    Value<String?> rawValue = const Value.absent(),
    Value<String?> studentId = const Value.absent(),
    Value<String?> partId = const Value.absent(),
    Value<double?> value = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    String? status,
  }) => RowReadRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    scanId: scanId ?? this.scanId,
    rowNo: rowNo ?? this.rowNo,
    rawId: rawId.present ? rawId.value : this.rawId,
    rawValue: rawValue.present ? rawValue.value : this.rawValue,
    studentId: studentId.present ? studentId.value : this.studentId,
    partId: partId.present ? partId.value : this.partId,
    value: value.present ? value.value : this.value,
    confidence: confidence.present ? confidence.value : this.confidence,
    status: status ?? this.status,
  );
  RowReadRow copyWithCompanion(RowReadsCompanion data) {
    return RowReadRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      rowNo: data.rowNo.present ? data.rowNo.value : this.rowNo,
      rawId: data.rawId.present ? data.rawId.value : this.rawId,
      rawValue: data.rawValue.present ? data.rawValue.value : this.rawValue,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      partId: data.partId.present ? data.partId.value : this.partId,
      value: data.value.present ? data.value.value : this.value,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RowReadRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('scanId: $scanId, ')
          ..write('rowNo: $rowNo, ')
          ..write('rawId: $rawId, ')
          ..write('rawValue: $rawValue, ')
          ..write('studentId: $studentId, ')
          ..write('partId: $partId, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    scanId,
    rowNo,
    rawId,
    rawValue,
    studentId,
    partId,
    value,
    confidence,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RowReadRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.scanId == this.scanId &&
          other.rowNo == this.rowNo &&
          other.rawId == this.rawId &&
          other.rawValue == this.rawValue &&
          other.studentId == this.studentId &&
          other.partId == this.partId &&
          other.value == this.value &&
          other.confidence == this.confidence &&
          other.status == this.status);
}

class RowReadsCompanion extends UpdateCompanion<RowReadRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> scanId;
  final Value<int> rowNo;
  final Value<String?> rawId;
  final Value<String?> rawValue;
  final Value<String?> studentId;
  final Value<String?> partId;
  final Value<double?> value;
  final Value<double?> confidence;
  final Value<String> status;
  final Value<int> rowid;
  const RowReadsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.scanId = const Value.absent(),
    this.rowNo = const Value.absent(),
    this.rawId = const Value.absent(),
    this.rawValue = const Value.absent(),
    this.studentId = const Value.absent(),
    this.partId = const Value.absent(),
    this.value = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RowReadsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String scanId,
    required int rowNo,
    this.rawId = const Value.absent(),
    this.rawValue = const Value.absent(),
    this.studentId = const Value.absent(),
    this.partId = const Value.absent(),
    this.value = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scanId = Value(scanId),
       rowNo = Value(rowNo);
  static Insertable<RowReadRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? scanId,
    Expression<int>? rowNo,
    Expression<String>? rawId,
    Expression<String>? rawValue,
    Expression<String>? studentId,
    Expression<String>? partId,
    Expression<double>? value,
    Expression<double>? confidence,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (scanId != null) 'scan_id': scanId,
      if (rowNo != null) 'row_no': rowNo,
      if (rawId != null) 'raw_id': rawId,
      if (rawValue != null) 'raw_value': rawValue,
      if (studentId != null) 'student_id': studentId,
      if (partId != null) 'part_id': partId,
      if (value != null) 'value': value,
      if (confidence != null) 'confidence': confidence,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RowReadsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? scanId,
    Value<int>? rowNo,
    Value<String?>? rawId,
    Value<String?>? rawValue,
    Value<String?>? studentId,
    Value<String?>? partId,
    Value<double?>? value,
    Value<double?>? confidence,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return RowReadsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      scanId: scanId ?? this.scanId,
      rowNo: rowNo ?? this.rowNo,
      rawId: rawId ?? this.rawId,
      rawValue: rawValue ?? this.rawValue,
      studentId: studentId ?? this.studentId,
      partId: partId ?? this.partId,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (rowNo.present) {
      map['row_no'] = Variable<int>(rowNo.value);
    }
    if (rawId.present) {
      map['raw_id'] = Variable<String>(rawId.value);
    }
    if (rawValue.present) {
      map['raw_value'] = Variable<String>(rawValue.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<String>(partId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RowReadsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('scanId: $scanId, ')
          ..write('rowNo: $rowNo, ')
          ..write('rawId: $rawId, ')
          ..write('rawValue: $rawValue, ')
          ..write('studentId: $studentId, ')
          ..write('partId: $partId, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PartScoresTable extends PartScores
    with TableInfo<$PartScoresTable, PartScoreRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course (id)',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES student (id)',
    ),
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<String> partId = GeneratedColumn<String>(
    'part_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_part (id)',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('entered'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('typed'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    courseId,
    studentId,
    partId,
    value,
    status,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'part_score';
  @override
  VerificationContext validateIntegrity(
    Insertable<PartScoreRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartScoreRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartScoreRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $PartScoresTable createAlias(String alias) {
    return $PartScoresTable(attachedDatabase, alias);
  }
}

class PartScoreRow extends DataClass implements Insertable<PartScoreRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String courseId;
  final String studentId;
  final String partId;

  /// Null when the status is `absent` or `missing`.
  final double? value;

  /// `entered`, `absent` or `missing`. The total and grade are calculated,
  /// never stored.
  final String status;

  /// `typed`, `scanned` or `imported`.
  final String source;
  const PartScoreRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.courseId,
    required this.studentId,
    required this.partId,
    this.value,
    required this.status,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['course_id'] = Variable<String>(courseId);
    map['student_id'] = Variable<String>(studentId);
    map['part_id'] = Variable<String>(partId);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    return map;
  }

  PartScoresCompanion toCompanion(bool nullToAbsent) {
    return PartScoresCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      courseId: Value(courseId),
      studentId: Value(studentId),
      partId: Value(partId),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      status: Value(status),
      source: Value(source),
    );
  }

  factory PartScoreRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartScoreRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      courseId: serializer.fromJson<String>(json['courseId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      partId: serializer.fromJson<String>(json['partId']),
      value: serializer.fromJson<double?>(json['value']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'courseId': serializer.toJson<String>(courseId),
      'studentId': serializer.toJson<String>(studentId),
      'partId': serializer.toJson<String>(partId),
      'value': serializer.toJson<double?>(value),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
    };
  }

  PartScoreRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? courseId,
    String? studentId,
    String? partId,
    Value<double?> value = const Value.absent(),
    String? status,
    String? source,
  }) => PartScoreRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    courseId: courseId ?? this.courseId,
    studentId: studentId ?? this.studentId,
    partId: partId ?? this.partId,
    value: value.present ? value.value : this.value,
    status: status ?? this.status,
    source: source ?? this.source,
  );
  PartScoreRow copyWithCompanion(PartScoresCompanion data) {
    return PartScoreRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      partId: data.partId.present ? data.partId.value : this.partId,
      value: data.value.present ? data.value.value : this.value,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartScoreRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('studentId: $studentId, ')
          ..write('partId: $partId, ')
          ..write('value: $value, ')
          ..write('status: $status, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    courseId,
    studentId,
    partId,
    value,
    status,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartScoreRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.courseId == this.courseId &&
          other.studentId == this.studentId &&
          other.partId == this.partId &&
          other.value == this.value &&
          other.status == this.status &&
          other.source == this.source);
}

class PartScoresCompanion extends UpdateCompanion<PartScoreRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> courseId;
  final Value<String> studentId;
  final Value<String> partId;
  final Value<double?> value;
  final Value<String> status;
  final Value<String> source;
  final Value<int> rowid;
  const PartScoresCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.courseId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.partId = const Value.absent(),
    this.value = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartScoresCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String courseId,
    required String studentId,
    required String partId,
    this.value = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       studentId = Value(studentId),
       partId = Value(partId);
  static Insertable<PartScoreRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? courseId,
    Expression<String>? studentId,
    Expression<String>? partId,
    Expression<double>? value,
    Expression<String>? status,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (courseId != null) 'course_id': courseId,
      if (studentId != null) 'student_id': studentId,
      if (partId != null) 'part_id': partId,
      if (value != null) 'value': value,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartScoresCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? courseId,
    Value<String>? studentId,
    Value<String>? partId,
    Value<double?>? value,
    Value<String>? status,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return PartScoresCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      partId: partId ?? this.partId,
      value: value ?? this.value,
      status: status ?? this.status,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<String>(partId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartScoresCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('courseId: $courseId, ')
          ..write('studentId: $studentId, ')
          ..write('partId: $partId, ')
          ..write('value: $value, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CorrectionsTable extends Corrections
    with TableInfo<$CorrectionsTable, CorrectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropPathMeta = const VerificationMeta(
    'cropPath',
  );
  @override
  late final GeneratedColumn<String> cropPath = GeneratedColumn<String>(
    'crop_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readValueMeta = const VerificationMeta(
    'readValue',
  );
  @override
  late final GeneratedColumn<String> readValue = GeneratedColumn<String>(
    'read_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedValueMeta = const VerificationMeta(
    'confirmedValue',
  );
  @override
  late final GeneratedColumn<String> confirmedValue = GeneratedColumn<String>(
    'confirmed_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    cropPath,
    field,
    readValue,
    confirmedValue,
    region,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'correction';
  @override
  VerificationContext validateIntegrity(
    Insertable<CorrectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('crop_path')) {
      context.handle(
        _cropPathMeta,
        cropPath.isAcceptableOrUnknown(data['crop_path']!, _cropPathMeta),
      );
    } else if (isInserting) {
      context.missing(_cropPathMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('read_value')) {
      context.handle(
        _readValueMeta,
        readValue.isAcceptableOrUnknown(data['read_value']!, _readValueMeta),
      );
    }
    if (data.containsKey('confirmed_value')) {
      context.handle(
        _confirmedValueMeta,
        confirmedValue.isAcceptableOrUnknown(
          data['confirmed_value']!,
          _confirmedValueMeta,
        ),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CorrectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CorrectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      cropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_path'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      readValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}read_value'],
      ),
      confirmedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_value'],
      ),
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
    );
  }

  @override
  $CorrectionsTable createAlias(String alias) {
    return $CorrectionsTable(attachedDatabase, alias);
  }
}

class CorrectionRow extends DataClass implements Insertable<CorrectionRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String cropPath;
  final String field;
  final String? readValue;
  final String? confirmedValue;

  /// Where on the photo the value was, as "left,top,right,bottom" fractions
  /// (added in schema version 2). With [cropPath] this is enough to cut the
  /// crop again later when training the digit model.
  final String? region;
  const CorrectionRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.cropPath,
    required this.field,
    this.readValue,
    this.confirmedValue,
    this.region,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['crop_path'] = Variable<String>(cropPath);
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || readValue != null) {
      map['read_value'] = Variable<String>(readValue);
    }
    if (!nullToAbsent || confirmedValue != null) {
      map['confirmed_value'] = Variable<String>(confirmedValue);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    return map;
  }

  CorrectionsCompanion toCompanion(bool nullToAbsent) {
    return CorrectionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cropPath: Value(cropPath),
      field: Value(field),
      readValue: readValue == null && nullToAbsent
          ? const Value.absent()
          : Value(readValue),
      confirmedValue: confirmedValue == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedValue),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
    );
  }

  factory CorrectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CorrectionRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      cropPath: serializer.fromJson<String>(json['cropPath']),
      field: serializer.fromJson<String>(json['field']),
      readValue: serializer.fromJson<String?>(json['readValue']),
      confirmedValue: serializer.fromJson<String?>(json['confirmedValue']),
      region: serializer.fromJson<String?>(json['region']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'cropPath': serializer.toJson<String>(cropPath),
      'field': serializer.toJson<String>(field),
      'readValue': serializer.toJson<String?>(readValue),
      'confirmedValue': serializer.toJson<String?>(confirmedValue),
      'region': serializer.toJson<String?>(region),
    };
  }

  CorrectionRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? cropPath,
    String? field,
    Value<String?> readValue = const Value.absent(),
    Value<String?> confirmedValue = const Value.absent(),
    Value<String?> region = const Value.absent(),
  }) => CorrectionRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cropPath: cropPath ?? this.cropPath,
    field: field ?? this.field,
    readValue: readValue.present ? readValue.value : this.readValue,
    confirmedValue: confirmedValue.present
        ? confirmedValue.value
        : this.confirmedValue,
    region: region.present ? region.value : this.region,
  );
  CorrectionRow copyWithCompanion(CorrectionsCompanion data) {
    return CorrectionRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cropPath: data.cropPath.present ? data.cropPath.value : this.cropPath,
      field: data.field.present ? data.field.value : this.field,
      readValue: data.readValue.present ? data.readValue.value : this.readValue,
      confirmedValue: data.confirmedValue.present
          ? data.confirmedValue.value
          : this.confirmedValue,
      region: data.region.present ? data.region.value : this.region,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cropPath: $cropPath, ')
          ..write('field: $field, ')
          ..write('readValue: $readValue, ')
          ..write('confirmedValue: $confirmedValue, ')
          ..write('region: $region')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    cropPath,
    field,
    readValue,
    confirmedValue,
    region,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CorrectionRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cropPath == this.cropPath &&
          other.field == this.field &&
          other.readValue == this.readValue &&
          other.confirmedValue == this.confirmedValue &&
          other.region == this.region);
}

class CorrectionsCompanion extends UpdateCompanion<CorrectionRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> cropPath;
  final Value<String> field;
  final Value<String?> readValue;
  final Value<String?> confirmedValue;
  final Value<String?> region;
  final Value<int> rowid;
  const CorrectionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cropPath = const Value.absent(),
    this.field = const Value.absent(),
    this.readValue = const Value.absent(),
    this.confirmedValue = const Value.absent(),
    this.region = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CorrectionsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String cropPath,
    required String field,
    this.readValue = const Value.absent(),
    this.confirmedValue = const Value.absent(),
    this.region = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cropPath = Value(cropPath),
       field = Value(field);
  static Insertable<CorrectionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? cropPath,
    Expression<String>? field,
    Expression<String>? readValue,
    Expression<String>? confirmedValue,
    Expression<String>? region,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cropPath != null) 'crop_path': cropPath,
      if (field != null) 'field': field,
      if (readValue != null) 'read_value': readValue,
      if (confirmedValue != null) 'confirmed_value': confirmedValue,
      if (region != null) 'region': region,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CorrectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? cropPath,
    Value<String>? field,
    Value<String?>? readValue,
    Value<String?>? confirmedValue,
    Value<String?>? region,
    Value<int>? rowid,
  }) {
    return CorrectionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cropPath: cropPath ?? this.cropPath,
      field: field ?? this.field,
      readValue: readValue ?? this.readValue,
      confirmedValue: confirmedValue ?? this.confirmedValue,
      region: region ?? this.region,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (cropPath.present) {
      map['crop_path'] = Variable<String>(cropPath.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (readValue.present) {
      map['read_value'] = Variable<String>(readValue.value);
    }
    if (confirmedValue.present) {
      map['confirmed_value'] = Variable<String>(confirmedValue.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cropPath: $cropPath, ')
          ..write('field: $field, ')
          ..write('readValue: $readValue, ')
          ..write('confirmedValue: $confirmedValue, ')
          ..write('region: $region, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecognitionRunsTable extends RecognitionRuns
    with TableInfo<$RecognitionRunsTable, RecognitionRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecognitionRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _pipelineVersionMeta = const VerificationMeta(
    'pipelineVersion',
  );
  @override
  late final GeneratedColumn<String> pipelineVersion = GeneratedColumn<String>(
    'pipeline_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('complete'),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    scanId,
    pipelineVersion,
    status,
    durationMs,
    resultJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recognition_run';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecognitionRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('pipeline_version')) {
      context.handle(
        _pipelineVersionMeta,
        pipelineVersion.isAcceptableOrUnknown(
          data['pipeline_version']!,
          _pipelineVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pipelineVersionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecognitionRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecognitionRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      pipelineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pipeline_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      )!,
    );
  }

  @override
  $RecognitionRunsTable createAlias(String alias) {
    return $RecognitionRunsTable(attachedDatabase, alias);
  }
}

class RecognitionRunRow extends DataClass
    implements Insertable<RecognitionRunRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String scanId;
  final String pipelineVersion;

  /// `complete`, or `partial` when a stage failed and its fields say so.
  final String status;
  final int durationMs;

  /// Fields (value, candidates, confidences, regions, attempts, warnings),
  /// quality report, findings, models, timings and notes, as JSON.
  final String resultJson;
  const RecognitionRunRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.scanId,
    required this.pipelineVersion,
    required this.status,
    required this.durationMs,
    required this.resultJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['scan_id'] = Variable<String>(scanId);
    map['pipeline_version'] = Variable<String>(pipelineVersion);
    map['status'] = Variable<String>(status);
    map['duration_ms'] = Variable<int>(durationMs);
    map['result_json'] = Variable<String>(resultJson);
    return map;
  }

  RecognitionRunsCompanion toCompanion(bool nullToAbsent) {
    return RecognitionRunsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      scanId: Value(scanId),
      pipelineVersion: Value(pipelineVersion),
      status: Value(status),
      durationMs: Value(durationMs),
      resultJson: Value(resultJson),
    );
  }

  factory RecognitionRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecognitionRunRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      scanId: serializer.fromJson<String>(json['scanId']),
      pipelineVersion: serializer.fromJson<String>(json['pipelineVersion']),
      status: serializer.fromJson<String>(json['status']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'scanId': serializer.toJson<String>(scanId),
      'pipelineVersion': serializer.toJson<String>(pipelineVersion),
      'status': serializer.toJson<String>(status),
      'durationMs': serializer.toJson<int>(durationMs),
      'resultJson': serializer.toJson<String>(resultJson),
    };
  }

  RecognitionRunRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? scanId,
    String? pipelineVersion,
    String? status,
    int? durationMs,
    String? resultJson,
  }) => RecognitionRunRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    scanId: scanId ?? this.scanId,
    pipelineVersion: pipelineVersion ?? this.pipelineVersion,
    status: status ?? this.status,
    durationMs: durationMs ?? this.durationMs,
    resultJson: resultJson ?? this.resultJson,
  );
  RecognitionRunRow copyWithCompanion(RecognitionRunsCompanion data) {
    return RecognitionRunRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      pipelineVersion: data.pipelineVersion.present
          ? data.pipelineVersion.value
          : this.pipelineVersion,
      status: data.status.present ? data.status.value : this.status,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecognitionRunRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('scanId: $scanId, ')
          ..write('pipelineVersion: $pipelineVersion, ')
          ..write('status: $status, ')
          ..write('durationMs: $durationMs, ')
          ..write('resultJson: $resultJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    scanId,
    pipelineVersion,
    status,
    durationMs,
    resultJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecognitionRunRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.scanId == this.scanId &&
          other.pipelineVersion == this.pipelineVersion &&
          other.status == this.status &&
          other.durationMs == this.durationMs &&
          other.resultJson == this.resultJson);
}

class RecognitionRunsCompanion extends UpdateCompanion<RecognitionRunRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> scanId;
  final Value<String> pipelineVersion;
  final Value<String> status;
  final Value<int> durationMs;
  final Value<String> resultJson;
  final Value<int> rowid;
  const RecognitionRunsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.scanId = const Value.absent(),
    this.pipelineVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecognitionRunsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String scanId,
    required String pipelineVersion,
    this.status = const Value.absent(),
    this.durationMs = const Value.absent(),
    required String resultJson,
    this.rowid = const Value.absent(),
  }) : scanId = Value(scanId),
       pipelineVersion = Value(pipelineVersion),
       resultJson = Value(resultJson);
  static Insertable<RecognitionRunRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? scanId,
    Expression<String>? pipelineVersion,
    Expression<String>? status,
    Expression<int>? durationMs,
    Expression<String>? resultJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (scanId != null) 'scan_id': scanId,
      if (pipelineVersion != null) 'pipeline_version': pipelineVersion,
      if (status != null) 'status': status,
      if (durationMs != null) 'duration_ms': durationMs,
      if (resultJson != null) 'result_json': resultJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecognitionRunsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? scanId,
    Value<String>? pipelineVersion,
    Value<String>? status,
    Value<int>? durationMs,
    Value<String>? resultJson,
    Value<int>? rowid,
  }) {
    return RecognitionRunsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      scanId: scanId ?? this.scanId,
      pipelineVersion: pipelineVersion ?? this.pipelineVersion,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      resultJson: resultJson ?? this.resultJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (pipelineVersion.present) {
      map['pipeline_version'] = Variable<String>(pipelineVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecognitionRunsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('scanId: $scanId, ')
          ..write('pipelineVersion: $pipelineVersion, ')
          ..write('status: $status, ')
          ..write('durationMs: $durationMs, ')
          ..write('resultJson: $resultJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldReviewsTable extends FieldReviews
    with TableInfo<$FieldReviewsTable, FieldReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineValueMeta = const VerificationMeta(
    'machineValue',
  );
  @override
  late final GeneratedColumn<String> machineValue = GeneratedColumn<String>(
    'machine_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _machineStateMeta = const VerificationMeta(
    'machineState',
  );
  @override
  late final GeneratedColumn<String> machineState = GeneratedColumn<String>(
    'machine_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalValueMeta = const VerificationMeta(
    'finalValue',
  );
  @override
  late final GeneratedColumn<String> finalValue = GeneratedColumn<String>(
    'final_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decisionMeta = const VerificationMeta(
    'decision',
  );
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
    'decision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    scanId,
    runId,
    fieldKey,
    kind,
    machineValue,
    machineState,
    finalValue,
    decision,
    region,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_review';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldReviewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('machine_value')) {
      context.handle(
        _machineValueMeta,
        machineValue.isAcceptableOrUnknown(
          data['machine_value']!,
          _machineValueMeta,
        ),
      );
    }
    if (data.containsKey('machine_state')) {
      context.handle(
        _machineStateMeta,
        machineState.isAcceptableOrUnknown(
          data['machine_state']!,
          _machineStateMeta,
        ),
      );
    }
    if (data.containsKey('final_value')) {
      context.handle(
        _finalValueMeta,
        finalValue.isAcceptableOrUnknown(data['final_value']!, _finalValueMeta),
      );
    }
    if (data.containsKey('decision')) {
      context.handle(
        _decisionMeta,
        decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta),
      );
    } else if (isInserting) {
      context.missing(_decisionMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldReviewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      ),
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      machineValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_value'],
      ),
      machineState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_state'],
      ),
      finalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_value'],
      ),
      decision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
    );
  }

  @override
  $FieldReviewsTable createAlias(String alias) {
    return $FieldReviewsTable(attachedDatabase, alias);
  }
}

class FieldReviewRow extends DataClass implements Insertable<FieldReviewRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String scanId;

  /// The run the machine value came from, when there was one.
  final String? runId;
  final String fieldKey;
  final String kind;
  final String? machineValue;
  final String? machineState;

  /// What the examiner confirmed; null for a field they left blank or rejected.
  final String? finalValue;

  /// `accepted` (the machine's value, confirmed), `suggestion` (another of the
  /// machine's candidates, tapped by the examiner), `edited` (changed from the
  /// machine's value), `entered` (typed with no machine value), `rejected` (the
  /// machine's value was dismissed) or `blank`.
  final String decision;

  /// Where on the photo, "left,top,right,bottom" as fractions.
  final String? region;
  final DateTime reviewedAt;
  const FieldReviewRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.scanId,
    this.runId,
    required this.fieldKey,
    required this.kind,
    this.machineValue,
    this.machineState,
    this.finalValue,
    required this.decision,
    this.region,
    required this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['scan_id'] = Variable<String>(scanId);
    if (!nullToAbsent || runId != null) {
      map['run_id'] = Variable<String>(runId);
    }
    map['field_key'] = Variable<String>(fieldKey);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || machineValue != null) {
      map['machine_value'] = Variable<String>(machineValue);
    }
    if (!nullToAbsent || machineState != null) {
      map['machine_state'] = Variable<String>(machineState);
    }
    if (!nullToAbsent || finalValue != null) {
      map['final_value'] = Variable<String>(finalValue);
    }
    map['decision'] = Variable<String>(decision);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    return map;
  }

  FieldReviewsCompanion toCompanion(bool nullToAbsent) {
    return FieldReviewsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      scanId: Value(scanId),
      runId: runId == null && nullToAbsent
          ? const Value.absent()
          : Value(runId),
      fieldKey: Value(fieldKey),
      kind: Value(kind),
      machineValue: machineValue == null && nullToAbsent
          ? const Value.absent()
          : Value(machineValue),
      machineState: machineState == null && nullToAbsent
          ? const Value.absent()
          : Value(machineState),
      finalValue: finalValue == null && nullToAbsent
          ? const Value.absent()
          : Value(finalValue),
      decision: Value(decision),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      reviewedAt: Value(reviewedAt),
    );
  }

  factory FieldReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldReviewRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      scanId: serializer.fromJson<String>(json['scanId']),
      runId: serializer.fromJson<String?>(json['runId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      kind: serializer.fromJson<String>(json['kind']),
      machineValue: serializer.fromJson<String?>(json['machineValue']),
      machineState: serializer.fromJson<String?>(json['machineState']),
      finalValue: serializer.fromJson<String?>(json['finalValue']),
      decision: serializer.fromJson<String>(json['decision']),
      region: serializer.fromJson<String?>(json['region']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'scanId': serializer.toJson<String>(scanId),
      'runId': serializer.toJson<String?>(runId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'kind': serializer.toJson<String>(kind),
      'machineValue': serializer.toJson<String?>(machineValue),
      'machineState': serializer.toJson<String?>(machineState),
      'finalValue': serializer.toJson<String?>(finalValue),
      'decision': serializer.toJson<String>(decision),
      'region': serializer.toJson<String?>(region),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
    };
  }

  FieldReviewRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? scanId,
    Value<String?> runId = const Value.absent(),
    String? fieldKey,
    String? kind,
    Value<String?> machineValue = const Value.absent(),
    Value<String?> machineState = const Value.absent(),
    Value<String?> finalValue = const Value.absent(),
    String? decision,
    Value<String?> region = const Value.absent(),
    DateTime? reviewedAt,
  }) => FieldReviewRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    scanId: scanId ?? this.scanId,
    runId: runId.present ? runId.value : this.runId,
    fieldKey: fieldKey ?? this.fieldKey,
    kind: kind ?? this.kind,
    machineValue: machineValue.present ? machineValue.value : this.machineValue,
    machineState: machineState.present ? machineState.value : this.machineState,
    finalValue: finalValue.present ? finalValue.value : this.finalValue,
    decision: decision ?? this.decision,
    region: region.present ? region.value : this.region,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );
  FieldReviewRow copyWithCompanion(FieldReviewsCompanion data) {
    return FieldReviewRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      runId: data.runId.present ? data.runId.value : this.runId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      machineValue: data.machineValue.present
          ? data.machineValue.value
          : this.machineValue,
      machineState: data.machineState.present
          ? data.machineState.value
          : this.machineState,
      finalValue: data.finalValue.present
          ? data.finalValue.value
          : this.finalValue,
      decision: data.decision.present ? data.decision.value : this.decision,
      region: data.region.present ? data.region.value : this.region,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldReviewRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('scanId: $scanId, ')
          ..write('runId: $runId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('kind: $kind, ')
          ..write('machineValue: $machineValue, ')
          ..write('machineState: $machineState, ')
          ..write('finalValue: $finalValue, ')
          ..write('decision: $decision, ')
          ..write('region: $region, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    scanId,
    runId,
    fieldKey,
    kind,
    machineValue,
    machineState,
    finalValue,
    decision,
    region,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldReviewRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.scanId == this.scanId &&
          other.runId == this.runId &&
          other.fieldKey == this.fieldKey &&
          other.kind == this.kind &&
          other.machineValue == this.machineValue &&
          other.machineState == this.machineState &&
          other.finalValue == this.finalValue &&
          other.decision == this.decision &&
          other.region == this.region &&
          other.reviewedAt == this.reviewedAt);
}

class FieldReviewsCompanion extends UpdateCompanion<FieldReviewRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> scanId;
  final Value<String?> runId;
  final Value<String> fieldKey;
  final Value<String> kind;
  final Value<String?> machineValue;
  final Value<String?> machineState;
  final Value<String?> finalValue;
  final Value<String> decision;
  final Value<String?> region;
  final Value<DateTime> reviewedAt;
  final Value<int> rowid;
  const FieldReviewsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.scanId = const Value.absent(),
    this.runId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.machineValue = const Value.absent(),
    this.machineState = const Value.absent(),
    this.finalValue = const Value.absent(),
    this.decision = const Value.absent(),
    this.region = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldReviewsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String scanId,
    this.runId = const Value.absent(),
    required String fieldKey,
    required String kind,
    this.machineValue = const Value.absent(),
    this.machineState = const Value.absent(),
    this.finalValue = const Value.absent(),
    required String decision,
    this.region = const Value.absent(),
    required DateTime reviewedAt,
    this.rowid = const Value.absent(),
  }) : scanId = Value(scanId),
       fieldKey = Value(fieldKey),
       kind = Value(kind),
       decision = Value(decision),
       reviewedAt = Value(reviewedAt);
  static Insertable<FieldReviewRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? scanId,
    Expression<String>? runId,
    Expression<String>? fieldKey,
    Expression<String>? kind,
    Expression<String>? machineValue,
    Expression<String>? machineState,
    Expression<String>? finalValue,
    Expression<String>? decision,
    Expression<String>? region,
    Expression<DateTime>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (scanId != null) 'scan_id': scanId,
      if (runId != null) 'run_id': runId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (kind != null) 'kind': kind,
      if (machineValue != null) 'machine_value': machineValue,
      if (machineState != null) 'machine_state': machineState,
      if (finalValue != null) 'final_value': finalValue,
      if (decision != null) 'decision': decision,
      if (region != null) 'region': region,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldReviewsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? scanId,
    Value<String?>? runId,
    Value<String>? fieldKey,
    Value<String>? kind,
    Value<String?>? machineValue,
    Value<String?>? machineState,
    Value<String?>? finalValue,
    Value<String>? decision,
    Value<String?>? region,
    Value<DateTime>? reviewedAt,
    Value<int>? rowid,
  }) {
    return FieldReviewsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      scanId: scanId ?? this.scanId,
      runId: runId ?? this.runId,
      fieldKey: fieldKey ?? this.fieldKey,
      kind: kind ?? this.kind,
      machineValue: machineValue ?? this.machineValue,
      machineState: machineState ?? this.machineState,
      finalValue: finalValue ?? this.finalValue,
      decision: decision ?? this.decision,
      region: region ?? this.region,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (machineValue.present) {
      map['machine_value'] = Variable<String>(machineValue.value);
    }
    if (machineState.present) {
      map['machine_state'] = Variable<String>(machineState.value);
    }
    if (finalValue.present) {
      map['final_value'] = Variable<String>(finalValue.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldReviewsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('scanId: $scanId, ')
          ..write('runId: $runId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('kind: $kind, ')
          ..write('machineValue: $machineValue, ')
          ..write('machineState: $machineState, ')
          ..write('finalValue: $finalValue, ')
          ..write('decision: $decision, ')
          ..write('region: $region, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('free'),
  );
  static const VerificationMeta _planValidUntilMeta = const VerificationMeta(
    'planValidUntil',
  );
  @override
  late final GeneratedColumn<DateTime> planValidUntil =
      GeneratedColumn<DateTime>(
        'plan_valid_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    userId,
    email,
    plan,
    planValidUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    }
    if (data.containsKey('plan_valid_until')) {
      context.handle(
        _planValidUntilMeta,
        planValidUntil.isAcceptableOrUnknown(
          data['plan_valid_until']!,
          _planValidUntilMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      planValidUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}plan_valid_until'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String userId;
  final String? email;
  final String plan;
  final DateTime? planValidUntil;
  const AccountRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.userId,
    this.email,
    required this.plan,
    this.planValidUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['plan'] = Variable<String>(plan);
    if (!nullToAbsent || planValidUntil != null) {
      map['plan_valid_until'] = Variable<DateTime>(planValidUntil);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId: Value(userId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      plan: Value(plan),
      planValidUntil: planValidUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(planValidUntil),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String?>(json['email']),
      plan: serializer.fromJson<String>(json['plan']),
      planValidUntil: serializer.fromJson<DateTime?>(json['planValidUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String?>(email),
      'plan': serializer.toJson<String>(plan),
      'planValidUntil': serializer.toJson<DateTime?>(planValidUntil),
    };
  }

  AccountRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? userId,
    Value<String?> email = const Value.absent(),
    String? plan,
    Value<DateTime?> planValidUntil = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    userId: userId ?? this.userId,
    email: email.present ? email.value : this.email,
    plan: plan ?? this.plan,
    planValidUntil: planValidUntil.present
        ? planValidUntil.value
        : this.planValidUntil,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      plan: data.plan.present ? data.plan.value : this.plan,
      planValidUntil: data.planValidUntil.present
          ? data.planValidUntil.value
          : this.planValidUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('plan: $plan, ')
          ..write('planValidUntil: $planValidUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    userId,
    email,
    plan,
    planValidUntil,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.plan == this.plan &&
          other.planValidUntil == this.planValidUntil);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> userId;
  final Value<String?> email;
  final Value<String> plan;
  final Value<DateTime?> planValidUntil;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.plan = const Value.absent(),
    this.planValidUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String userId,
    this.email = const Value.absent(),
    this.plan = const Value.absent(),
    this.planValidUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? plan,
    Expression<DateTime>? planValidUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (plan != null) 'plan': plan,
      if (planValidUntil != null) 'plan_valid_until': planValidUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? userId,
    Value<String?>? email,
    Value<String>? plan,
    Value<DateTime?>? planValidUntil,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      plan: plan ?? this.plan,
      planValidUntil: planValidUntil ?? this.planValidUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (planValidUntil.present) {
      map['plan_valid_until'] = Variable<DateTime>(planValidUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('plan: $plan, ')
          ..write('planValidUntil: $planValidUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncTableMeta = const VerificationMeta(
    'syncTable',
  );
  @override
  late final GeneratedColumn<String> syncTable = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPushAtMeta = const VerificationMeta(
    'lastPushAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPushAt = GeneratedColumn<DateTime>(
    'last_push_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    syncTable,
    lastPullAt,
    lastPushAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _syncTableMeta,
        syncTable.isAcceptableOrUnknown(data['table_name']!, _syncTableMeta),
      );
    } else if (isInserting) {
      context.missing(_syncTableMeta);
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    if (data.containsKey('last_push_at')) {
      context.handle(
        _lastPushAtMeta,
        lastPushAt.isAcceptableOrUnknown(
          data['last_push_at']!,
          _lastPushAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
      lastPushAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_push_at'],
      ),
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncTable;
  final DateTime? lastPullAt;
  final DateTime? lastPushAt;
  const SyncStateRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.syncTable,
    this.lastPullAt,
    this.lastPushAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['table_name'] = Variable<String>(syncTable);
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    if (!nullToAbsent || lastPushAt != null) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt);
    }
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncTable: Value(syncTable),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
      lastPushAt: lastPushAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncTable: serializer.fromJson<String>(json['syncTable']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
      lastPushAt: serializer.fromJson<DateTime?>(json['lastPushAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncTable': serializer.toJson<String>(syncTable),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
      'lastPushAt': serializer.toJson<DateTime?>(lastPushAt),
    };
  }

  SyncStateRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncTable,
    Value<DateTime?> lastPullAt = const Value.absent(),
    Value<DateTime?> lastPushAt = const Value.absent(),
  }) => SyncStateRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncTable: syncTable ?? this.syncTable,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
    lastPushAt: lastPushAt.present ? lastPushAt.value : this.lastPushAt,
  );
  SyncStateRow copyWithCompanion(SyncStatesCompanion data) {
    return SyncStateRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncTable: data.syncTable.present ? data.syncTable.value : this.syncTable,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
      lastPushAt: data.lastPushAt.present
          ? data.lastPushAt.value
          : this.lastPushAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncTable: $syncTable, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastPushAt: $lastPushAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, syncTable, lastPullAt, lastPushAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncTable == this.syncTable &&
          other.lastPullAt == this.lastPullAt &&
          other.lastPushAt == this.lastPushAt);
}

class SyncStatesCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncTable;
  final Value<DateTime?> lastPullAt;
  final Value<DateTime?> lastPushAt;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncTable = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String syncTable,
    this.lastPullAt = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : syncTable = Value(syncTable);
  static Insertable<SyncStateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncTable,
    Expression<DateTime>? lastPullAt,
    Expression<DateTime>? lastPushAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncTable != null) 'table_name': syncTable,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (lastPushAt != null) 'last_push_at': lastPushAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncTable,
    Value<DateTime?>? lastPullAt,
    Value<DateTime?>? lastPushAt,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncTable: syncTable ?? this.syncTable,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncTable.present) {
      map['table_name'] = Variable<String>(syncTable.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (lastPushAt.present) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncTable: $syncTable, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $CoursePartsTable courseParts = $CoursePartsTable(this);
  late final $ExamQuestionsTable examQuestions = $ExamQuestionsTable(this);
  late final $GradeScalesTable gradeScales = $GradeScalesTable(this);
  late final $SchemeTemplatesTable schemeTemplates = $SchemeTemplatesTable(
    this,
  );
  late final $StudentsTable students = $StudentsTable(this);
  late final $BatchesTable batches = $BatchesTable(this);
  late final $ScansTable scans = $ScansTable(this);
  late final $BookletsTable booklets = $BookletsTable(this);
  late final $QuestionMarksTable questionMarks = $QuestionMarksTable(this);
  late final $RowReadsTable rowReads = $RowReadsTable(this);
  late final $PartScoresTable partScores = $PartScoresTable(this);
  late final $CorrectionsTable corrections = $CorrectionsTable(this);
  late final $RecognitionRunsTable recognitionRuns = $RecognitionRunsTable(
    this,
  );
  late final $FieldReviewsTable fieldReviews = $FieldReviewsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final Index courseCode = Index(
    'course_code',
    'CREATE INDEX course_code ON course (code)',
  );
  late final Index coursePartCourse = Index(
    'course_part_course',
    'CREATE INDEX course_part_course ON course_part (course_id)',
  );
  late final Index examQuestionCourse = Index(
    'exam_question_course',
    'CREATE INDEX exam_question_course ON exam_question (course_id)',
  );
  late final Index gradeScaleCourse = Index(
    'grade_scale_course',
    'CREATE INDEX grade_scale_course ON grade_scale (course_id)',
  );
  late final Index studentCourse = Index(
    'student_course',
    'CREATE INDEX student_course ON student (course_id)',
  );
  late final Index studentRegNo = Index(
    'student_reg_no',
    'CREATE INDEX student_reg_no ON student (course_id, reg_no)',
  );
  late final Index uploadBatchCourse = Index(
    'upload_batch_course',
    'CREATE INDEX upload_batch_course ON upload_batch (course_id)',
  );
  late final Index scanCourse = Index(
    'scan_course',
    'CREATE INDEX scan_course ON scan (course_id)',
  );
  late final Index scanBatch = Index(
    'scan_batch',
    'CREATE INDEX scan_batch ON scan (batch_id)',
  );
  late final Index scanHash = Index(
    'scan_hash',
    'CREATE INDEX scan_hash ON scan (course_id, content_hash)',
  );
  late final Index bookletCourse = Index(
    'booklet_course',
    'CREATE INDEX booklet_course ON booklet (course_id)',
  );
  late final Index questionMarkBooklet = Index(
    'question_mark_booklet',
    'CREATE INDEX question_mark_booklet ON question_mark (booklet_id)',
  );
  late final Index rowReadScan = Index(
    'row_read_scan',
    'CREATE INDEX row_read_scan ON row_read (scan_id)',
  );
  late final Index partScoreCourse = Index(
    'part_score_course',
    'CREATE INDEX part_score_course ON part_score (course_id)',
  );
  late final Index partScoreCell = Index(
    'part_score_cell',
    'CREATE INDEX part_score_cell ON part_score (student_id, part_id)',
  );
  late final Index recognitionRunScan = Index(
    'recognition_run_scan',
    'CREATE INDEX recognition_run_scan ON recognition_run (scan_id)',
  );
  late final Index fieldReviewScan = Index(
    'field_review_scan',
    'CREATE INDEX field_review_scan ON field_review (scan_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    courses,
    courseParts,
    examQuestions,
    gradeScales,
    schemeTemplates,
    students,
    batches,
    scans,
    booklets,
    questionMarks,
    rowReads,
    partScores,
    corrections,
    recognitionRuns,
    fieldReviews,
    accounts,
    syncStates,
    courseCode,
    coursePartCourse,
    examQuestionCourse,
    gradeScaleCourse,
    studentCourse,
    studentRegNo,
    uploadBatchCourse,
    scanCourse,
    scanBatch,
    scanHash,
    bookletCourse,
    questionMarkBooklet,
    rowReadScan,
    partScoreCourse,
    partScoreCell,
    recognitionRunScan,
    fieldReviewScan,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String code,
      Value<String> department,
      Value<String> session,
      Value<String> semester,
      Value<double> totalExpected,
      Value<String> countRule,
      Value<int?> countN,
      Value<int> rowid,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> code,
      Value<String> department,
      Value<String> session,
      Value<String> semester,
      Value<double> totalExpected,
      Value<String> countRule,
      Value<int?> countN,
      Value<int> rowid,
    });

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, CourseRow> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CoursePartsTable, List<CoursePartRow>>
  _coursePartsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseParts,
    aliasName: $_aliasNameGenerator(db.courses.id, db.courseParts.courseId),
  );

  $$CoursePartsTableProcessedTableManager get coursePartsRefs {
    final manager = $$CoursePartsTableTableManager(
      $_db,
      $_db.courseParts,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_coursePartsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExamQuestionsTable, List<ExamQuestionRow>>
  _examQuestionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.examQuestions,
    aliasName: $_aliasNameGenerator(db.courses.id, db.examQuestions.courseId),
  );

  $$ExamQuestionsTableProcessedTableManager get examQuestionsRefs {
    final manager = $$ExamQuestionsTableTableManager(
      $_db,
      $_db.examQuestions,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_examQuestionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GradeScalesTable, List<GradeScaleRow>>
  _gradeScalesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gradeScales,
    aliasName: $_aliasNameGenerator(db.courses.id, db.gradeScales.courseId),
  );

  $$GradeScalesTableProcessedTableManager get gradeScalesRefs {
    final manager = $$GradeScalesTableTableManager(
      $_db,
      $_db.gradeScales,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_gradeScalesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StudentsTable, List<StudentRow>>
  _studentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.students,
    aliasName: $_aliasNameGenerator(db.courses.id, db.students.courseId),
  );

  $$StudentsTableProcessedTableManager get studentsRefs {
    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_studentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BatchesTable, List<BatchRow>> _batchesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.batches,
    aliasName: $_aliasNameGenerator(db.courses.id, db.batches.courseId),
  );

  $$BatchesTableProcessedTableManager get batchesRefs {
    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_batchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScansTable, List<ScanRow>> _scansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scans,
    aliasName: $_aliasNameGenerator(db.courses.id, db.scans.courseId),
  );

  $$ScansTableProcessedTableManager get scansRefs {
    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookletsTable, List<BookletRow>>
  _bookletsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.booklets,
    aliasName: $_aliasNameGenerator(db.courses.id, db.booklets.courseId),
  );

  $$BookletsTableProcessedTableManager get bookletsRefs {
    final manager = $$BookletsTableTableManager(
      $_db,
      $_db.booklets,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookletsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PartScoresTable, List<PartScoreRow>>
  _partScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.partScores,
    aliasName: $_aliasNameGenerator(db.courses.id, db.partScores.courseId),
  );

  $$PartScoresTableProcessedTableManager get partScoresRefs {
    final manager = $$PartScoresTableTableManager(
      $_db,
      $_db.partScores,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_partScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get session => $composableBuilder(
    column: $table.session,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalExpected => $composableBuilder(
    column: $table.totalExpected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countRule => $composableBuilder(
    column: $table.countRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countN => $composableBuilder(
    column: $table.countN,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> coursePartsRefs(
    Expression<bool> Function($$CoursePartsTableFilterComposer f) f,
  ) {
    final $$CoursePartsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableFilterComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> examQuestionsRefs(
    Expression<bool> Function($$ExamQuestionsTableFilterComposer f) f,
  ) {
    final $$ExamQuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.examQuestions,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamQuestionsTableFilterComposer(
            $db: $db,
            $table: $db.examQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gradeScalesRefs(
    Expression<bool> Function($$GradeScalesTableFilterComposer f) f,
  ) {
    final $$GradeScalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gradeScales,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GradeScalesTableFilterComposer(
            $db: $db,
            $table: $db.gradeScales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> studentsRefs(
    Expression<bool> Function($$StudentsTableFilterComposer f) f,
  ) {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> batchesRefs(
    Expression<bool> Function($$BatchesTableFilterComposer f) f,
  ) {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scansRefs(
    Expression<bool> Function($$ScansTableFilterComposer f) f,
  ) {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookletsRefs(
    Expression<bool> Function($$BookletsTableFilterComposer f) f,
  ) {
    final $$BookletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableFilterComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> partScoresRefs(
    Expression<bool> Function($$PartScoresTableFilterComposer f) f,
  ) {
    final $$PartScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partScores,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartScoresTableFilterComposer(
            $db: $db,
            $table: $db.partScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get session => $composableBuilder(
    column: $table.session,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalExpected => $composableBuilder(
    column: $table.totalExpected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countRule => $composableBuilder(
    column: $table.countRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countN => $composableBuilder(
    column: $table.countN,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => column,
  );

  GeneratedColumn<String> get session =>
      $composableBuilder(column: $table.session, builder: (column) => column);

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<double> get totalExpected => $composableBuilder(
    column: $table.totalExpected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countRule =>
      $composableBuilder(column: $table.countRule, builder: (column) => column);

  GeneratedColumn<int> get countN =>
      $composableBuilder(column: $table.countN, builder: (column) => column);

  Expression<T> coursePartsRefs<T extends Object>(
    Expression<T> Function($$CoursePartsTableAnnotationComposer a) f,
  ) {
    final $$CoursePartsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> examQuestionsRefs<T extends Object>(
    Expression<T> Function($$ExamQuestionsTableAnnotationComposer a) f,
  ) {
    final $$ExamQuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.examQuestions,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamQuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.examQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gradeScalesRefs<T extends Object>(
    Expression<T> Function($$GradeScalesTableAnnotationComposer a) f,
  ) {
    final $$GradeScalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gradeScales,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GradeScalesTableAnnotationComposer(
            $db: $db,
            $table: $db.gradeScales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> studentsRefs<T extends Object>(
    Expression<T> Function($$StudentsTableAnnotationComposer a) f,
  ) {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> batchesRefs<T extends Object>(
    Expression<T> Function($$BatchesTableAnnotationComposer a) f,
  ) {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scansRefs<T extends Object>(
    Expression<T> Function($$ScansTableAnnotationComposer a) f,
  ) {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookletsRefs<T extends Object>(
    Expression<T> Function($$BookletsTableAnnotationComposer a) f,
  ) {
    final $$BookletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableAnnotationComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> partScoresRefs<T extends Object>(
    Expression<T> Function($$PartScoresTableAnnotationComposer a) f,
  ) {
    final $$PartScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partScores,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.partScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          CourseRow,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (CourseRow, $$CoursesTableReferences),
          CourseRow,
          PrefetchHooks Function({
            bool coursePartsRefs,
            bool examQuestionsRefs,
            bool gradeScalesRefs,
            bool studentsRefs,
            bool batchesRefs,
            bool scansRefs,
            bool bookletsRefs,
            bool partScoresRefs,
          })
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> department = const Value.absent(),
                Value<String> session = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<double> totalExpected = const Value.absent(),
                Value<String> countRule = const Value.absent(),
                Value<int?> countN = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                code: code,
                department: department,
                session: session,
                semester: semester,
                totalExpected: totalExpected,
                countRule: countRule,
                countN: countN,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String code,
                Value<String> department = const Value.absent(),
                Value<String> session = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<double> totalExpected = const Value.absent(),
                Value<String> countRule = const Value.absent(),
                Value<int?> countN = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                code: code,
                department: department,
                session: session,
                semester: semester,
                totalExpected: totalExpected,
                countRule: countRule,
                countN: countN,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coursePartsRefs = false,
                examQuestionsRefs = false,
                gradeScalesRefs = false,
                studentsRefs = false,
                batchesRefs = false,
                scansRefs = false,
                bookletsRefs = false,
                partScoresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (coursePartsRefs) db.courseParts,
                    if (examQuestionsRefs) db.examQuestions,
                    if (gradeScalesRefs) db.gradeScales,
                    if (studentsRefs) db.students,
                    if (batchesRefs) db.batches,
                    if (scansRefs) db.scans,
                    if (bookletsRefs) db.booklets,
                    if (partScoresRefs) db.partScores,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (coursePartsRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          CoursePartRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._coursePartsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).coursePartsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (examQuestionsRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          ExamQuestionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._examQuestionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).examQuestionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gradeScalesRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          GradeScaleRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._gradeScalesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).gradeScalesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (studentsRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          StudentRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._studentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).studentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (batchesRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          BatchRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._batchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).batchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scansRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          ScanRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._scansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(db, table, p0).scansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookletsRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          BookletRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._bookletsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).bookletsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (partScoresRefs)
                        await $_getPrefetchedData<
                          CourseRow,
                          $CoursesTable,
                          PartScoreRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._partScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).partScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      CourseRow,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (CourseRow, $$CoursesTableReferences),
      CourseRow,
      PrefetchHooks Function({
        bool coursePartsRefs,
        bool examQuestionsRefs,
        bool gradeScalesRefs,
        bool studentsRefs,
        bool batchesRefs,
        bool scansRefs,
        bool bookletsRefs,
        bool partScoresRefs,
      })
    >;
typedef $$CoursePartsTableCreateCompanionBuilder =
    CoursePartsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      required String name,
      required double max,
      Value<double> min,
      Value<double?> passMark,
      Value<double> step,
      Value<double?> markedOutOf,
      Value<double?> countsFor,
      Value<String> source,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CoursePartsTableUpdateCompanionBuilder =
    CoursePartsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<String> name,
      Value<double> max,
      Value<double> min,
      Value<double?> passMark,
      Value<double> step,
      Value<double?> markedOutOf,
      Value<double?> countsFor,
      Value<String> source,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$CoursePartsTableReferences
    extends BaseReferences<_$AppDatabase, $CoursePartsTable, CoursePartRow> {
  $$CoursePartsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias(
        $_aliasNameGenerator(db.courseParts.courseId, db.courses.id),
      );

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RowReadsTable, List<RowReadRow>>
  _rowReadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rowReads,
    aliasName: $_aliasNameGenerator(db.courseParts.id, db.rowReads.partId),
  );

  $$RowReadsTableProcessedTableManager get rowReadsRefs {
    final manager = $$RowReadsTableTableManager(
      $_db,
      $_db.rowReads,
    ).filter((f) => f.partId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rowReadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PartScoresTable, List<PartScoreRow>>
  _partScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.partScores,
    aliasName: $_aliasNameGenerator(db.courseParts.id, db.partScores.partId),
  );

  $$PartScoresTableProcessedTableManager get partScoresRefs {
    final manager = $$PartScoresTableTableManager(
      $_db,
      $_db.partScores,
    ).filter((f) => f.partId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_partScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursePartsTableFilterComposer
    extends Composer<_$AppDatabase, $CoursePartsTable> {
  $$CoursePartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get max => $composableBuilder(
    column: $table.max,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get min => $composableBuilder(
    column: $table.min,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get passMark => $composableBuilder(
    column: $table.passMark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get markedOutOf => $composableBuilder(
    column: $table.markedOutOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get countsFor => $composableBuilder(
    column: $table.countsFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rowReadsRefs(
    Expression<bool> Function($$RowReadsTableFilterComposer f) f,
  ) {
    final $$RowReadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowReads,
      getReferencedColumn: (t) => t.partId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowReadsTableFilterComposer(
            $db: $db,
            $table: $db.rowReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> partScoresRefs(
    Expression<bool> Function($$PartScoresTableFilterComposer f) f,
  ) {
    final $$PartScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partScores,
      getReferencedColumn: (t) => t.partId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartScoresTableFilterComposer(
            $db: $db,
            $table: $db.partScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursePartsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursePartsTable> {
  $$CoursePartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get max => $composableBuilder(
    column: $table.max,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get min => $composableBuilder(
    column: $table.min,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get passMark => $composableBuilder(
    column: $table.passMark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get markedOutOf => $composableBuilder(
    column: $table.markedOutOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get countsFor => $composableBuilder(
    column: $table.countsFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoursePartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursePartsTable> {
  $$CoursePartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get max =>
      $composableBuilder(column: $table.max, builder: (column) => column);

  GeneratedColumn<double> get min =>
      $composableBuilder(column: $table.min, builder: (column) => column);

  GeneratedColumn<double> get passMark =>
      $composableBuilder(column: $table.passMark, builder: (column) => column);

  GeneratedColumn<double> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get markedOutOf => $composableBuilder(
    column: $table.markedOutOf,
    builder: (column) => column,
  );

  GeneratedColumn<double> get countsFor =>
      $composableBuilder(column: $table.countsFor, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rowReadsRefs<T extends Object>(
    Expression<T> Function($$RowReadsTableAnnotationComposer a) f,
  ) {
    final $$RowReadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowReads,
      getReferencedColumn: (t) => t.partId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowReadsTableAnnotationComposer(
            $db: $db,
            $table: $db.rowReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> partScoresRefs<T extends Object>(
    Expression<T> Function($$PartScoresTableAnnotationComposer a) f,
  ) {
    final $$PartScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partScores,
      getReferencedColumn: (t) => t.partId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.partScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursePartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursePartsTable,
          CoursePartRow,
          $$CoursePartsTableFilterComposer,
          $$CoursePartsTableOrderingComposer,
          $$CoursePartsTableAnnotationComposer,
          $$CoursePartsTableCreateCompanionBuilder,
          $$CoursePartsTableUpdateCompanionBuilder,
          (CoursePartRow, $$CoursePartsTableReferences),
          CoursePartRow,
          PrefetchHooks Function({
            bool courseId,
            bool rowReadsRefs,
            bool partScoresRefs,
          })
        > {
  $$CoursePartsTableTableManager(_$AppDatabase db, $CoursePartsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursePartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursePartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursePartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> max = const Value.absent(),
                Value<double> min = const Value.absent(),
                Value<double?> passMark = const Value.absent(),
                Value<double> step = const Value.absent(),
                Value<double?> markedOutOf = const Value.absent(),
                Value<double?> countsFor = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursePartsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                name: name,
                max: max,
                min: min,
                passMark: passMark,
                step: step,
                markedOutOf: markedOutOf,
                countsFor: countsFor,
                source: source,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                required String name,
                required double max,
                Value<double> min = const Value.absent(),
                Value<double?> passMark = const Value.absent(),
                Value<double> step = const Value.absent(),
                Value<double?> markedOutOf = const Value.absent(),
                Value<double?> countsFor = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursePartsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                name: name,
                max: max,
                min: min,
                passMark: passMark,
                step: step,
                markedOutOf: markedOutOf,
                countsFor: countsFor,
                source: source,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoursePartsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseId = false,
                rowReadsRefs = false,
                partScoresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rowReadsRefs) db.rowReads,
                    if (partScoresRefs) db.partScores,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable:
                                        $$CoursePartsTableReferences
                                            ._courseIdTable(db),
                                    referencedColumn:
                                        $$CoursePartsTableReferences
                                            ._courseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rowReadsRefs)
                        await $_getPrefetchedData<
                          CoursePartRow,
                          $CoursePartsTable,
                          RowReadRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursePartsTableReferences
                              ._rowReadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursePartsTableReferences(
                                db,
                                table,
                                p0,
                              ).rowReadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.partId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (partScoresRefs)
                        await $_getPrefetchedData<
                          CoursePartRow,
                          $CoursePartsTable,
                          PartScoreRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoursePartsTableReferences
                              ._partScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursePartsTableReferences(
                                db,
                                table,
                                p0,
                              ).partScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.partId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoursePartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursePartsTable,
      CoursePartRow,
      $$CoursePartsTableFilterComposer,
      $$CoursePartsTableOrderingComposer,
      $$CoursePartsTableAnnotationComposer,
      $$CoursePartsTableCreateCompanionBuilder,
      $$CoursePartsTableUpdateCompanionBuilder,
      (CoursePartRow, $$CoursePartsTableReferences),
      CoursePartRow,
      PrefetchHooks Function({
        bool courseId,
        bool rowReadsRefs,
        bool partScoresRefs,
      })
    >;
typedef $$ExamQuestionsTableCreateCompanionBuilder =
    ExamQuestionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      required int qNo,
      required double max,
      Value<bool> compulsory,
      Value<int> rowid,
    });
typedef $$ExamQuestionsTableUpdateCompanionBuilder =
    ExamQuestionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<int> qNo,
      Value<double> max,
      Value<bool> compulsory,
      Value<int> rowid,
    });

final class $$ExamQuestionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExamQuestionsTable, ExamQuestionRow> {
  $$ExamQuestionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias(
        $_aliasNameGenerator(db.examQuestions.courseId, db.courses.id),
      );

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExamQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $ExamQuestionsTable> {
  $$ExamQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qNo => $composableBuilder(
    column: $table.qNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get max => $composableBuilder(
    column: $table.max,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get compulsory => $composableBuilder(
    column: $table.compulsory,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamQuestionsTable> {
  $$ExamQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qNo => $composableBuilder(
    column: $table.qNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get max => $composableBuilder(
    column: $table.max,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get compulsory => $composableBuilder(
    column: $table.compulsory,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamQuestionsTable> {
  $$ExamQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get qNo =>
      $composableBuilder(column: $table.qNo, builder: (column) => column);

  GeneratedColumn<double> get max =>
      $composableBuilder(column: $table.max, builder: (column) => column);

  GeneratedColumn<bool> get compulsory => $composableBuilder(
    column: $table.compulsory,
    builder: (column) => column,
  );

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamQuestionsTable,
          ExamQuestionRow,
          $$ExamQuestionsTableFilterComposer,
          $$ExamQuestionsTableOrderingComposer,
          $$ExamQuestionsTableAnnotationComposer,
          $$ExamQuestionsTableCreateCompanionBuilder,
          $$ExamQuestionsTableUpdateCompanionBuilder,
          (ExamQuestionRow, $$ExamQuestionsTableReferences),
          ExamQuestionRow,
          PrefetchHooks Function({bool courseId})
        > {
  $$ExamQuestionsTableTableManager(_$AppDatabase db, $ExamQuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<int> qNo = const Value.absent(),
                Value<double> max = const Value.absent(),
                Value<bool> compulsory = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamQuestionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                qNo: qNo,
                max: max,
                compulsory: compulsory,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                required int qNo,
                required double max,
                Value<bool> compulsory = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamQuestionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                qNo: qNo,
                max: max,
                compulsory: compulsory,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExamQuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $$ExamQuestionsTableReferences
                                    ._courseIdTable(db),
                                referencedColumn: $$ExamQuestionsTableReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExamQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamQuestionsTable,
      ExamQuestionRow,
      $$ExamQuestionsTableFilterComposer,
      $$ExamQuestionsTableOrderingComposer,
      $$ExamQuestionsTableAnnotationComposer,
      $$ExamQuestionsTableCreateCompanionBuilder,
      $$ExamQuestionsTableUpdateCompanionBuilder,
      (ExamQuestionRow, $$ExamQuestionsTableReferences),
      ExamQuestionRow,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$GradeScalesTableCreateCompanionBuilder =
    GradeScalesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      required double minScore,
      required double maxScore,
      required String letter,
      Value<double> points,
      Value<int> rowid,
    });
typedef $$GradeScalesTableUpdateCompanionBuilder =
    GradeScalesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<double> minScore,
      Value<double> maxScore,
      Value<String> letter,
      Value<double> points,
      Value<int> rowid,
    });

final class $$GradeScalesTableReferences
    extends BaseReferences<_$AppDatabase, $GradeScalesTable, GradeScaleRow> {
  $$GradeScalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias(
        $_aliasNameGenerator(db.gradeScales.courseId, db.courses.id),
      );

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GradeScalesTableFilterComposer
    extends Composer<_$AppDatabase, $GradeScalesTable> {
  $$GradeScalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minScore => $composableBuilder(
    column: $table.minScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get letter => $composableBuilder(
    column: $table.letter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradeScalesTableOrderingComposer
    extends Composer<_$AppDatabase, $GradeScalesTable> {
  $$GradeScalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minScore => $composableBuilder(
    column: $table.minScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get letter => $composableBuilder(
    column: $table.letter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradeScalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradeScalesTable> {
  $$GradeScalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<double> get minScore =>
      $composableBuilder(column: $table.minScore, builder: (column) => column);

  GeneratedColumn<double> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<String> get letter =>
      $composableBuilder(column: $table.letter, builder: (column) => column);

  GeneratedColumn<double> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradeScalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradeScalesTable,
          GradeScaleRow,
          $$GradeScalesTableFilterComposer,
          $$GradeScalesTableOrderingComposer,
          $$GradeScalesTableAnnotationComposer,
          $$GradeScalesTableCreateCompanionBuilder,
          $$GradeScalesTableUpdateCompanionBuilder,
          (GradeScaleRow, $$GradeScalesTableReferences),
          GradeScaleRow,
          PrefetchHooks Function({bool courseId})
        > {
  $$GradeScalesTableTableManager(_$AppDatabase db, $GradeScalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradeScalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradeScalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradeScalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<double> minScore = const Value.absent(),
                Value<double> maxScore = const Value.absent(),
                Value<String> letter = const Value.absent(),
                Value<double> points = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GradeScalesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                minScore: minScore,
                maxScore: maxScore,
                letter: letter,
                points: points,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                required double minScore,
                required double maxScore,
                required String letter,
                Value<double> points = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GradeScalesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                minScore: minScore,
                maxScore: maxScore,
                letter: letter,
                points: points,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GradeScalesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $$GradeScalesTableReferences
                                    ._courseIdTable(db),
                                referencedColumn: $$GradeScalesTableReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GradeScalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradeScalesTable,
      GradeScaleRow,
      $$GradeScalesTableFilterComposer,
      $$GradeScalesTableOrderingComposer,
      $$GradeScalesTableAnnotationComposer,
      $$GradeScalesTableCreateCompanionBuilder,
      $$GradeScalesTableUpdateCompanionBuilder,
      (GradeScaleRow, $$GradeScalesTableReferences),
      GradeScaleRow,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$SchemeTemplatesTableCreateCompanionBuilder =
    SchemeTemplatesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      required String json,
      Value<int> rowid,
    });
typedef $$SchemeTemplatesTableUpdateCompanionBuilder =
    SchemeTemplatesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<String> json,
      Value<int> rowid,
    });

class $$SchemeTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $SchemeTemplatesTable> {
  $$SchemeTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemeTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemeTemplatesTable> {
  $$SchemeTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemeTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemeTemplatesTable> {
  $$SchemeTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$SchemeTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemeTemplatesTable,
          SchemeTemplateRow,
          $$SchemeTemplatesTableFilterComposer,
          $$SchemeTemplatesTableOrderingComposer,
          $$SchemeTemplatesTableAnnotationComposer,
          $$SchemeTemplatesTableCreateCompanionBuilder,
          $$SchemeTemplatesTableUpdateCompanionBuilder,
          (
            SchemeTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $SchemeTemplatesTable,
              SchemeTemplateRow
            >,
          ),
          SchemeTemplateRow,
          PrefetchHooks Function()
        > {
  $$SchemeTemplatesTableTableManager(
    _$AppDatabase db,
    $SchemeTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemeTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemeTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemeTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchemeTemplatesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => SchemeTemplatesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemeTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemeTemplatesTable,
      SchemeTemplateRow,
      $$SchemeTemplatesTableFilterComposer,
      $$SchemeTemplatesTableOrderingComposer,
      $$SchemeTemplatesTableAnnotationComposer,
      $$SchemeTemplatesTableCreateCompanionBuilder,
      $$SchemeTemplatesTableUpdateCompanionBuilder,
      (
        SchemeTemplateRow,
        BaseReferences<_$AppDatabase, $SchemeTemplatesTable, SchemeTemplateRow>,
      ),
      SchemeTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$StudentsTableCreateCompanionBuilder =
    StudentsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      required String regNo,
      Value<String?> name,
      Value<bool> onClassList,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$StudentsTableUpdateCompanionBuilder =
    StudentsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<String> regNo,
      Value<String?> name,
      Value<bool> onClassList,
      Value<int> position,
      Value<int> rowid,
    });

final class $$StudentsTableReferences
    extends BaseReferences<_$AppDatabase, $StudentsTable, StudentRow> {
  $$StudentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) => db.courses
      .createAlias($_aliasNameGenerator(db.students.courseId, db.courses.id));

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BookletsTable, List<BookletRow>>
  _bookletsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.booklets,
    aliasName: $_aliasNameGenerator(db.students.id, db.booklets.studentId),
  );

  $$BookletsTableProcessedTableManager get bookletsRefs {
    final manager = $$BookletsTableTableManager(
      $_db,
      $_db.booklets,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookletsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RowReadsTable, List<RowReadRow>>
  _rowReadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rowReads,
    aliasName: $_aliasNameGenerator(db.students.id, db.rowReads.studentId),
  );

  $$RowReadsTableProcessedTableManager get rowReadsRefs {
    final manager = $$RowReadsTableTableManager(
      $_db,
      $_db.rowReads,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rowReadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PartScoresTable, List<PartScoreRow>>
  _partScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.partScores,
    aliasName: $_aliasNameGenerator(db.students.id, db.partScores.studentId),
  );

  $$PartScoresTableProcessedTableManager get partScoresRefs {
    final manager = $$PartScoresTableTableManager(
      $_db,
      $_db.partScores,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_partScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regNo => $composableBuilder(
    column: $table.regNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onClassList => $composableBuilder(
    column: $table.onClassList,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bookletsRefs(
    Expression<bool> Function($$BookletsTableFilterComposer f) f,
  ) {
    final $$BookletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableFilterComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rowReadsRefs(
    Expression<bool> Function($$RowReadsTableFilterComposer f) f,
  ) {
    final $$RowReadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowReads,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowReadsTableFilterComposer(
            $db: $db,
            $table: $db.rowReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> partScoresRefs(
    Expression<bool> Function($$PartScoresTableFilterComposer f) f,
  ) {
    final $$PartScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partScores,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartScoresTableFilterComposer(
            $db: $db,
            $table: $db.partScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regNo => $composableBuilder(
    column: $table.regNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onClassList => $composableBuilder(
    column: $table.onClassList,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get regNo =>
      $composableBuilder(column: $table.regNo, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get onClassList => $composableBuilder(
    column: $table.onClassList,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bookletsRefs<T extends Object>(
    Expression<T> Function($$BookletsTableAnnotationComposer a) f,
  ) {
    final $$BookletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableAnnotationComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rowReadsRefs<T extends Object>(
    Expression<T> Function($$RowReadsTableAnnotationComposer a) f,
  ) {
    final $$RowReadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowReads,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowReadsTableAnnotationComposer(
            $db: $db,
            $table: $db.rowReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> partScoresRefs<T extends Object>(
    Expression<T> Function($$PartScoresTableAnnotationComposer a) f,
  ) {
    final $$PartScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partScores,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.partScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTable,
          StudentRow,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (StudentRow, $$StudentsTableReferences),
          StudentRow,
          PrefetchHooks Function({
            bool courseId,
            bool bookletsRefs,
            bool rowReadsRefs,
            bool partScoresRefs,
          })
        > {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> regNo = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<bool> onClassList = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                regNo: regNo,
                name: name,
                onClassList: onClassList,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                required String regNo,
                Value<String?> name = const Value.absent(),
                Value<bool> onClassList = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                regNo: regNo,
                name: name,
                onClassList: onClassList,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseId = false,
                bookletsRefs = false,
                rowReadsRefs = false,
                partScoresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookletsRefs) db.booklets,
                    if (rowReadsRefs) db.rowReads,
                    if (partScoresRefs) db.partScores,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable: $$StudentsTableReferences
                                        ._courseIdTable(db),
                                    referencedColumn: $$StudentsTableReferences
                                        ._courseIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookletsRefs)
                        await $_getPrefetchedData<
                          StudentRow,
                          $StudentsTable,
                          BookletRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._bookletsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookletsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rowReadsRefs)
                        await $_getPrefetchedData<
                          StudentRow,
                          $StudentsTable,
                          RowReadRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._rowReadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).rowReadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (partScoresRefs)
                        await $_getPrefetchedData<
                          StudentRow,
                          $StudentsTable,
                          PartScoreRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._partScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).partScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTable,
      StudentRow,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (StudentRow, $$StudentsTableReferences),
      StudentRow,
      PrefetchHooks Function({
        bool courseId,
        bool bookletsRefs,
        bool rowReadsRefs,
        bool partScoresRefs,
      })
    >;
typedef $$BatchesTableCreateCompanionBuilder =
    BatchesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      Value<String?> title,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$BatchesTableUpdateCompanionBuilder =
    BatchesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<String?> title,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$BatchesTableReferences
    extends BaseReferences<_$AppDatabase, $BatchesTable, BatchRow> {
  $$BatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) => db.courses
      .createAlias($_aliasNameGenerator(db.batches.courseId, db.courses.id));

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScansTable, List<ScanRow>> _scansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scans,
    aliasName: $_aliasNameGenerator(db.batches.id, db.scans.batchId),
  );

  $$ScansTableProcessedTableManager get scansRefs {
    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scansRefs(
    Expression<bool> Function($$ScansTableFilterComposer f) f,
  ) {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scansRefs<T extends Object>(
    Expression<T> Function($$ScansTableAnnotationComposer a) f,
  ) {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchesTable,
          BatchRow,
          $$BatchesTableFilterComposer,
          $$BatchesTableOrderingComposer,
          $$BatchesTableAnnotationComposer,
          $$BatchesTableCreateCompanionBuilder,
          $$BatchesTableUpdateCompanionBuilder,
          (BatchRow, $$BatchesTableReferences),
          BatchRow,
          PrefetchHooks Function({bool courseId, bool scansRefs})
        > {
  $$BatchesTableTableManager(_$AppDatabase db, $BatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                title: title,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                Value<String?> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                title: title,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false, scansRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (scansRefs) db.scans],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $$BatchesTableReferences
                                    ._courseIdTable(db),
                                referencedColumn: $$BatchesTableReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scansRefs)
                    await $_getPrefetchedData<BatchRow, $BatchesTable, ScanRow>(
                      currentTable: table,
                      referencedTable: $$BatchesTableReferences._scansRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$BatchesTableReferences(db, table, p0).scansRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.batchId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchesTable,
      BatchRow,
      $$BatchesTableFilterComposer,
      $$BatchesTableOrderingComposer,
      $$BatchesTableAnnotationComposer,
      $$BatchesTableCreateCompanionBuilder,
      $$BatchesTableUpdateCompanionBuilder,
      (BatchRow, $$BatchesTableReferences),
      BatchRow,
      PrefetchHooks Function({bool courseId, bool scansRefs})
    >;
typedef $$ScansTableCreateCompanionBuilder =
    ScansCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      required String kind,
      Value<String?> photoPath,
      Value<int> pageNo,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String?> batchId,
      Value<String?> originalName,
      Value<String?> contentHash,
      Value<int?> width,
      Value<int?> height,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$ScansTableUpdateCompanionBuilder =
    ScansCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<String> kind,
      Value<String?> photoPath,
      Value<int> pageNo,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String?> batchId,
      Value<String?> originalName,
      Value<String?> contentHash,
      Value<int?> width,
      Value<int?> height,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

final class $$ScansTableReferences
    extends BaseReferences<_$AppDatabase, $ScansTable, ScanRow> {
  $$ScansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) => db.courses
      .createAlias($_aliasNameGenerator(db.scans.courseId, db.courses.id));

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BatchesTable _batchIdTable(_$AppDatabase db) => db.batches
      .createAlias($_aliasNameGenerator(db.scans.batchId, db.batches.id));

  $$BatchesTableProcessedTableManager? get batchId {
    final $_column = $_itemColumn<String>('batch_id');
    if ($_column == null) return null;
    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BookletsTable, List<BookletRow>>
  _bookletsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.booklets,
    aliasName: $_aliasNameGenerator(db.scans.id, db.booklets.scanId),
  );

  $$BookletsTableProcessedTableManager get bookletsRefs {
    final manager = $$BookletsTableTableManager(
      $_db,
      $_db.booklets,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookletsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RowReadsTable, List<RowReadRow>>
  _rowReadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rowReads,
    aliasName: $_aliasNameGenerator(db.scans.id, db.rowReads.scanId),
  );

  $$RowReadsTableProcessedTableManager get rowReadsRefs {
    final manager = $$RowReadsTableTableManager(
      $_db,
      $_db.rowReads,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rowReadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecognitionRunsTable, List<RecognitionRunRow>>
  _recognitionRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recognitionRuns,
    aliasName: $_aliasNameGenerator(db.scans.id, db.recognitionRuns.scanId),
  );

  $$RecognitionRunsTableProcessedTableManager get recognitionRunsRefs {
    final manager = $$RecognitionRunsTableTableManager(
      $_db,
      $_db.recognitionRuns,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recognitionRunsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FieldReviewsTable, List<FieldReviewRow>>
  _fieldReviewsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fieldReviews,
    aliasName: $_aliasNameGenerator(db.scans.id, db.fieldReviews.scanId),
  );

  $$FieldReviewsTableProcessedTableManager get fieldReviewsRefs {
    final manager = $$FieldReviewsTableTableManager(
      $_db,
      $_db.fieldReviews,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fieldReviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScansTableFilterComposer extends Composer<_$AppDatabase, $ScansTable> {
  $$ScansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bookletsRefs(
    Expression<bool> Function($$BookletsTableFilterComposer f) f,
  ) {
    final $$BookletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableFilterComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rowReadsRefs(
    Expression<bool> Function($$RowReadsTableFilterComposer f) f,
  ) {
    final $$RowReadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowReads,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowReadsTableFilterComposer(
            $db: $db,
            $table: $db.rowReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recognitionRunsRefs(
    Expression<bool> Function($$RecognitionRunsTableFilterComposer f) f,
  ) {
    final $$RecognitionRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recognitionRuns,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecognitionRunsTableFilterComposer(
            $db: $db,
            $table: $db.recognitionRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fieldReviewsRefs(
    Expression<bool> Function($$FieldReviewsTableFilterComposer f) f,
  ) {
    final $$FieldReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldReviews,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldReviewsTableFilterComposer(
            $db: $db,
            $table: $db.fieldReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScansTableOrderingComposer
    extends Composer<_$AppDatabase, $ScansTable> {
  $$ScansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScansTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScansTable> {
  $$ScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<int> get pageNo =>
      $composableBuilder(column: $table.pageNo, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bookletsRefs<T extends Object>(
    Expression<T> Function($$BookletsTableAnnotationComposer a) f,
  ) {
    final $$BookletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableAnnotationComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rowReadsRefs<T extends Object>(
    Expression<T> Function($$RowReadsTableAnnotationComposer a) f,
  ) {
    final $$RowReadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowReads,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowReadsTableAnnotationComposer(
            $db: $db,
            $table: $db.rowReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recognitionRunsRefs<T extends Object>(
    Expression<T> Function($$RecognitionRunsTableAnnotationComposer a) f,
  ) {
    final $$RecognitionRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recognitionRuns,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecognitionRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.recognitionRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fieldReviewsRefs<T extends Object>(
    Expression<T> Function($$FieldReviewsTableAnnotationComposer a) f,
  ) {
    final $$FieldReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldReviews,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.fieldReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScansTable,
          ScanRow,
          $$ScansTableFilterComposer,
          $$ScansTableOrderingComposer,
          $$ScansTableAnnotationComposer,
          $$ScansTableCreateCompanionBuilder,
          $$ScansTableUpdateCompanionBuilder,
          (ScanRow, $$ScansTableReferences),
          ScanRow,
          PrefetchHooks Function({
            bool courseId,
            bool batchId,
            bool bookletsRefs,
            bool rowReadsRefs,
            bool recognitionRunsRefs,
            bool fieldReviewsRefs,
          })
        > {
  $$ScansTableTableManager(_$AppDatabase db, $ScansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int> pageNo = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScansCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                kind: kind,
                photoPath: photoPath,
                pageNo: pageNo,
                status: status,
                createdAt: createdAt,
                batchId: batchId,
                originalName: originalName,
                contentHash: contentHash,
                width: width,
                height: height,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                required String kind,
                Value<String?> photoPath = const Value.absent(),
                Value<int> pageNo = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScansCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                kind: kind,
                photoPath: photoPath,
                pageNo: pageNo,
                status: status,
                createdAt: createdAt,
                batchId: batchId,
                originalName: originalName,
                contentHash: contentHash,
                width: width,
                height: height,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ScansTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseId = false,
                batchId = false,
                bookletsRefs = false,
                rowReadsRefs = false,
                recognitionRunsRefs = false,
                fieldReviewsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookletsRefs) db.booklets,
                    if (rowReadsRefs) db.rowReads,
                    if (recognitionRunsRefs) db.recognitionRuns,
                    if (fieldReviewsRefs) db.fieldReviews,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable: $$ScansTableReferences
                                        ._courseIdTable(db),
                                    referencedColumn: $$ScansTableReferences
                                        ._courseIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (batchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.batchId,
                                    referencedTable: $$ScansTableReferences
                                        ._batchIdTable(db),
                                    referencedColumn: $$ScansTableReferences
                                        ._batchIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookletsRefs)
                        await $_getPrefetchedData<
                          ScanRow,
                          $ScansTable,
                          BookletRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._bookletsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(
                                db,
                                table,
                                p0,
                              ).bookletsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rowReadsRefs)
                        await $_getPrefetchedData<
                          ScanRow,
                          $ScansTable,
                          RowReadRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._rowReadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(
                                db,
                                table,
                                p0,
                              ).rowReadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recognitionRunsRefs)
                        await $_getPrefetchedData<
                          ScanRow,
                          $ScansTable,
                          RecognitionRunRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._recognitionRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(
                                db,
                                table,
                                p0,
                              ).recognitionRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fieldReviewsRefs)
                        await $_getPrefetchedData<
                          ScanRow,
                          $ScansTable,
                          FieldReviewRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._fieldReviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(
                                db,
                                table,
                                p0,
                              ).fieldReviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScansTable,
      ScanRow,
      $$ScansTableFilterComposer,
      $$ScansTableOrderingComposer,
      $$ScansTableAnnotationComposer,
      $$ScansTableCreateCompanionBuilder,
      $$ScansTableUpdateCompanionBuilder,
      (ScanRow, $$ScansTableReferences),
      ScanRow,
      PrefetchHooks Function({
        bool courseId,
        bool batchId,
        bool bookletsRefs,
        bool rowReadsRefs,
        bool recognitionRunsRefs,
        bool fieldReviewsRefs,
      })
    >;
typedef $$BookletsTableCreateCompanionBuilder =
    BookletsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      Value<String?> studentId,
      Value<String?> scanId,
      Value<String?> serialNo,
      Value<String?> readJson,
      Value<String> status,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });
typedef $$BookletsTableUpdateCompanionBuilder =
    BookletsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<String?> studentId,
      Value<String?> scanId,
      Value<String?> serialNo,
      Value<String?> readJson,
      Value<String> status,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });

final class $$BookletsTableReferences
    extends BaseReferences<_$AppDatabase, $BookletsTable, BookletRow> {
  $$BookletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) => db.courses
      .createAlias($_aliasNameGenerator(db.booklets.courseId, db.courses.id));

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentIdTable(_$AppDatabase db) => db.students
      .createAlias($_aliasNameGenerator(db.booklets.studentId, db.students.id));

  $$StudentsTableProcessedTableManager? get studentId {
    final $_column = $_itemColumn<String>('student_id');
    if ($_column == null) return null;
    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScansTable _scanIdTable(_$AppDatabase db) => db.scans.createAlias(
    $_aliasNameGenerator(db.booklets.scanId, db.scans.id),
  );

  $$ScansTableProcessedTableManager? get scanId {
    final $_column = $_itemColumn<String>('scan_id');
    if ($_column == null) return null;
    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestionMarksTable, List<QuestionMarkRow>>
  _questionMarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.questionMarks,
    aliasName: $_aliasNameGenerator(db.booklets.id, db.questionMarks.bookletId),
  );

  $$QuestionMarksTableProcessedTableManager get questionMarksRefs {
    final manager = $$QuestionMarksTableTableManager(
      $_db,
      $_db.questionMarks,
    ).filter((f) => f.bookletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionMarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BookletsTableFilterComposer
    extends Composer<_$AppDatabase, $BookletsTable> {
  $$BookletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNo => $composableBuilder(
    column: $table.serialNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readJson => $composableBuilder(
    column: $table.readJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questionMarksRefs(
    Expression<bool> Function($$QuestionMarksTableFilterComposer f) f,
  ) {
    final $$QuestionMarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionMarks,
      getReferencedColumn: (t) => t.bookletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionMarksTableFilterComposer(
            $db: $db,
            $table: $db.questionMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BookletsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookletsTable> {
  $$BookletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNo => $composableBuilder(
    column: $table.serialNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readJson => $composableBuilder(
    column: $table.readJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookletsTable> {
  $$BookletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);

  GeneratedColumn<String> get readJson =>
      $composableBuilder(column: $table.readJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questionMarksRefs<T extends Object>(
    Expression<T> Function($$QuestionMarksTableAnnotationComposer a) f,
  ) {
    final $$QuestionMarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionMarks,
      getReferencedColumn: (t) => t.bookletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionMarksTableAnnotationComposer(
            $db: $db,
            $table: $db.questionMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BookletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookletsTable,
          BookletRow,
          $$BookletsTableFilterComposer,
          $$BookletsTableOrderingComposer,
          $$BookletsTableAnnotationComposer,
          $$BookletsTableCreateCompanionBuilder,
          $$BookletsTableUpdateCompanionBuilder,
          (BookletRow, $$BookletsTableReferences),
          BookletRow,
          PrefetchHooks Function({
            bool courseId,
            bool studentId,
            bool scanId,
            bool questionMarksRefs,
          })
        > {
  $$BookletsTableTableManager(_$AppDatabase db, $BookletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> scanId = const Value.absent(),
                Value<String?> serialNo = const Value.absent(),
                Value<String?> readJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookletsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                studentId: studentId,
                scanId: scanId,
                serialNo: serialNo,
                readJson: readJson,
                status: status,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                Value<String?> studentId = const Value.absent(),
                Value<String?> scanId = const Value.absent(),
                Value<String?> serialNo = const Value.absent(),
                Value<String?> readJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookletsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                studentId: studentId,
                scanId: scanId,
                serialNo: serialNo,
                readJson: readJson,
                status: status,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookletsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseId = false,
                studentId = false,
                scanId = false,
                questionMarksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionMarksRefs) db.questionMarks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable: $$BookletsTableReferences
                                        ._courseIdTable(db),
                                    referencedColumn: $$BookletsTableReferences
                                        ._courseIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (studentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.studentId,
                                    referencedTable: $$BookletsTableReferences
                                        ._studentIdTable(db),
                                    referencedColumn: $$BookletsTableReferences
                                        ._studentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (scanId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scanId,
                                    referencedTable: $$BookletsTableReferences
                                        ._scanIdTable(db),
                                    referencedColumn: $$BookletsTableReferences
                                        ._scanIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionMarksRefs)
                        await $_getPrefetchedData<
                          BookletRow,
                          $BookletsTable,
                          QuestionMarkRow
                        >(
                          currentTable: table,
                          referencedTable: $$BookletsTableReferences
                              ._questionMarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BookletsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionMarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookletId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BookletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookletsTable,
      BookletRow,
      $$BookletsTableFilterComposer,
      $$BookletsTableOrderingComposer,
      $$BookletsTableAnnotationComposer,
      $$BookletsTableCreateCompanionBuilder,
      $$BookletsTableUpdateCompanionBuilder,
      (BookletRow, $$BookletsTableReferences),
      BookletRow,
      PrefetchHooks Function({
        bool courseId,
        bool studentId,
        bool scanId,
        bool questionMarksRefs,
      })
    >;
typedef $$QuestionMarksTableCreateCompanionBuilder =
    QuestionMarksCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String bookletId,
      required int qNo,
      required double mark,
      Value<double?> confidence,
      Value<bool> edited,
      Value<int> rowid,
    });
typedef $$QuestionMarksTableUpdateCompanionBuilder =
    QuestionMarksCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> bookletId,
      Value<int> qNo,
      Value<double> mark,
      Value<double?> confidence,
      Value<bool> edited,
      Value<int> rowid,
    });

final class $$QuestionMarksTableReferences
    extends
        BaseReferences<_$AppDatabase, $QuestionMarksTable, QuestionMarkRow> {
  $$QuestionMarksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BookletsTable _bookletIdTable(_$AppDatabase db) =>
      db.booklets.createAlias(
        $_aliasNameGenerator(db.questionMarks.bookletId, db.booklets.id),
      );

  $$BookletsTableProcessedTableManager get bookletId {
    final $_column = $_itemColumn<String>('booklet_id')!;

    final manager = $$BookletsTableTableManager(
      $_db,
      $_db.booklets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionMarksTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionMarksTable> {
  $$QuestionMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qNo => $composableBuilder(
    column: $table.qNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mark => $composableBuilder(
    column: $table.mark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get edited => $composableBuilder(
    column: $table.edited,
    builder: (column) => ColumnFilters(column),
  );

  $$BookletsTableFilterComposer get bookletId {
    final $$BookletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookletId,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableFilterComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionMarksTable> {
  $$QuestionMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qNo => $composableBuilder(
    column: $table.qNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mark => $composableBuilder(
    column: $table.mark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get edited => $composableBuilder(
    column: $table.edited,
    builder: (column) => ColumnOrderings(column),
  );

  $$BookletsTableOrderingComposer get bookletId {
    final $$BookletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookletId,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableOrderingComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionMarksTable> {
  $$QuestionMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get qNo =>
      $composableBuilder(column: $table.qNo, builder: (column) => column);

  GeneratedColumn<double> get mark =>
      $composableBuilder(column: $table.mark, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get edited =>
      $composableBuilder(column: $table.edited, builder: (column) => column);

  $$BookletsTableAnnotationComposer get bookletId {
    final $$BookletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookletId,
      referencedTable: $db.booklets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookletsTableAnnotationComposer(
            $db: $db,
            $table: $db.booklets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionMarksTable,
          QuestionMarkRow,
          $$QuestionMarksTableFilterComposer,
          $$QuestionMarksTableOrderingComposer,
          $$QuestionMarksTableAnnotationComposer,
          $$QuestionMarksTableCreateCompanionBuilder,
          $$QuestionMarksTableUpdateCompanionBuilder,
          (QuestionMarkRow, $$QuestionMarksTableReferences),
          QuestionMarkRow,
          PrefetchHooks Function({bool bookletId})
        > {
  $$QuestionMarksTableTableManager(_$AppDatabase db, $QuestionMarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> bookletId = const Value.absent(),
                Value<int> qNo = const Value.absent(),
                Value<double> mark = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<bool> edited = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionMarksCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                bookletId: bookletId,
                qNo: qNo,
                mark: mark,
                confidence: confidence,
                edited: edited,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String bookletId,
                required int qNo,
                required double mark,
                Value<double?> confidence = const Value.absent(),
                Value<bool> edited = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionMarksCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                bookletId: bookletId,
                qNo: qNo,
                mark: mark,
                confidence: confidence,
                edited: edited,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionMarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookletId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookletId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookletId,
                                referencedTable: $$QuestionMarksTableReferences
                                    ._bookletIdTable(db),
                                referencedColumn: $$QuestionMarksTableReferences
                                    ._bookletIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuestionMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionMarksTable,
      QuestionMarkRow,
      $$QuestionMarksTableFilterComposer,
      $$QuestionMarksTableOrderingComposer,
      $$QuestionMarksTableAnnotationComposer,
      $$QuestionMarksTableCreateCompanionBuilder,
      $$QuestionMarksTableUpdateCompanionBuilder,
      (QuestionMarkRow, $$QuestionMarksTableReferences),
      QuestionMarkRow,
      PrefetchHooks Function({bool bookletId})
    >;
typedef $$RowReadsTableCreateCompanionBuilder =
    RowReadsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String scanId,
      required int rowNo,
      Value<String?> rawId,
      Value<String?> rawValue,
      Value<String?> studentId,
      Value<String?> partId,
      Value<double?> value,
      Value<double?> confidence,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$RowReadsTableUpdateCompanionBuilder =
    RowReadsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> scanId,
      Value<int> rowNo,
      Value<String?> rawId,
      Value<String?> rawValue,
      Value<String?> studentId,
      Value<String?> partId,
      Value<double?> value,
      Value<double?> confidence,
      Value<String> status,
      Value<int> rowid,
    });

final class $$RowReadsTableReferences
    extends BaseReferences<_$AppDatabase, $RowReadsTable, RowReadRow> {
  $$RowReadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScansTable _scanIdTable(_$AppDatabase db) => db.scans.createAlias(
    $_aliasNameGenerator(db.rowReads.scanId, db.scans.id),
  );

  $$ScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentIdTable(_$AppDatabase db) => db.students
      .createAlias($_aliasNameGenerator(db.rowReads.studentId, db.students.id));

  $$StudentsTableProcessedTableManager? get studentId {
    final $_column = $_itemColumn<String>('student_id');
    if ($_column == null) return null;
    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CoursePartsTable _partIdTable(_$AppDatabase db) => db.courseParts
      .createAlias($_aliasNameGenerator(db.rowReads.partId, db.courseParts.id));

  $$CoursePartsTableProcessedTableManager? get partId {
    final $_column = $_itemColumn<String>('part_id');
    if ($_column == null) return null;
    final manager = $$CoursePartsTableTableManager(
      $_db,
      $_db.courseParts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_partIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RowReadsTableFilterComposer
    extends Composer<_$AppDatabase, $RowReadsTable> {
  $$RowReadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowNo => $composableBuilder(
    column: $table.rowNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawId => $composableBuilder(
    column: $table.rawId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursePartsTableFilterComposer get partId {
    final $$CoursePartsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partId,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableFilterComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RowReadsTableOrderingComposer
    extends Composer<_$AppDatabase, $RowReadsTable> {
  $$RowReadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowNo => $composableBuilder(
    column: $table.rowNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawId => $composableBuilder(
    column: $table.rawId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursePartsTableOrderingComposer get partId {
    final $$CoursePartsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partId,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableOrderingComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RowReadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RowReadsTable> {
  $$RowReadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowNo =>
      $composableBuilder(column: $table.rowNo, builder: (column) => column);

  GeneratedColumn<String> get rawId =>
      $composableBuilder(column: $table.rawId, builder: (column) => column);

  GeneratedColumn<String> get rawValue =>
      $composableBuilder(column: $table.rawValue, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursePartsTableAnnotationComposer get partId {
    final $$CoursePartsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partId,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RowReadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RowReadsTable,
          RowReadRow,
          $$RowReadsTableFilterComposer,
          $$RowReadsTableOrderingComposer,
          $$RowReadsTableAnnotationComposer,
          $$RowReadsTableCreateCompanionBuilder,
          $$RowReadsTableUpdateCompanionBuilder,
          (RowReadRow, $$RowReadsTableReferences),
          RowReadRow,
          PrefetchHooks Function({bool scanId, bool studentId, bool partId})
        > {
  $$RowReadsTableTableManager(_$AppDatabase db, $RowReadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RowReadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RowReadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RowReadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<int> rowNo = const Value.absent(),
                Value<String?> rawId = const Value.absent(),
                Value<String?> rawValue = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> partId = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RowReadsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                scanId: scanId,
                rowNo: rowNo,
                rawId: rawId,
                rawValue: rawValue,
                studentId: studentId,
                partId: partId,
                value: value,
                confidence: confidence,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String scanId,
                required int rowNo,
                Value<String?> rawId = const Value.absent(),
                Value<String?> rawValue = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> partId = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RowReadsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                scanId: scanId,
                rowNo: rowNo,
                rawId: rawId,
                rawValue: rawValue,
                studentId: studentId,
                partId: partId,
                value: value,
                confidence: confidence,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RowReadsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({scanId = false, studentId = false, partId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (scanId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scanId,
                                    referencedTable: $$RowReadsTableReferences
                                        ._scanIdTable(db),
                                    referencedColumn: $$RowReadsTableReferences
                                        ._scanIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (studentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.studentId,
                                    referencedTable: $$RowReadsTableReferences
                                        ._studentIdTable(db),
                                    referencedColumn: $$RowReadsTableReferences
                                        ._studentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (partId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.partId,
                                    referencedTable: $$RowReadsTableReferences
                                        ._partIdTable(db),
                                    referencedColumn: $$RowReadsTableReferences
                                        ._partIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RowReadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RowReadsTable,
      RowReadRow,
      $$RowReadsTableFilterComposer,
      $$RowReadsTableOrderingComposer,
      $$RowReadsTableAnnotationComposer,
      $$RowReadsTableCreateCompanionBuilder,
      $$RowReadsTableUpdateCompanionBuilder,
      (RowReadRow, $$RowReadsTableReferences),
      RowReadRow,
      PrefetchHooks Function({bool scanId, bool studentId, bool partId})
    >;
typedef $$PartScoresTableCreateCompanionBuilder =
    PartScoresCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String courseId,
      required String studentId,
      required String partId,
      Value<double?> value,
      Value<String> status,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$PartScoresTableUpdateCompanionBuilder =
    PartScoresCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> courseId,
      Value<String> studentId,
      Value<String> partId,
      Value<double?> value,
      Value<String> status,
      Value<String> source,
      Value<int> rowid,
    });

final class $$PartScoresTableReferences
    extends BaseReferences<_$AppDatabase, $PartScoresTable, PartScoreRow> {
  $$PartScoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) => db.courses
      .createAlias($_aliasNameGenerator(db.partScores.courseId, db.courses.id));

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentIdTable(_$AppDatabase db) =>
      db.students.createAlias(
        $_aliasNameGenerator(db.partScores.studentId, db.students.id),
      );

  $$StudentsTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<String>('student_id')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CoursePartsTable _partIdTable(_$AppDatabase db) =>
      db.courseParts.createAlias(
        $_aliasNameGenerator(db.partScores.partId, db.courseParts.id),
      );

  $$CoursePartsTableProcessedTableManager get partId {
    final $_column = $_itemColumn<String>('part_id')!;

    final manager = $$CoursePartsTableTableManager(
      $_db,
      $_db.courseParts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_partIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PartScoresTableFilterComposer
    extends Composer<_$AppDatabase, $PartScoresTable> {
  $$PartScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursePartsTableFilterComposer get partId {
    final $$CoursePartsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partId,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableFilterComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PartScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $PartScoresTable> {
  $$PartScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursePartsTableOrderingComposer get partId {
    final $$CoursePartsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partId,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableOrderingComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PartScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartScoresTable> {
  $$PartScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursePartsTableAnnotationComposer get partId {
    final $$CoursePartsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partId,
      referencedTable: $db.courseParts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursePartsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PartScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PartScoresTable,
          PartScoreRow,
          $$PartScoresTableFilterComposer,
          $$PartScoresTableOrderingComposer,
          $$PartScoresTableAnnotationComposer,
          $$PartScoresTableCreateCompanionBuilder,
          $$PartScoresTableUpdateCompanionBuilder,
          (PartScoreRow, $$PartScoresTableReferences),
          PartScoreRow,
          PrefetchHooks Function({bool courseId, bool studentId, bool partId})
        > {
  $$PartScoresTableTableManager(_$AppDatabase db, $PartScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> partId = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartScoresCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                studentId: studentId,
                partId: partId,
                value: value,
                status: status,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String courseId,
                required String studentId,
                required String partId,
                Value<double?> value = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartScoresCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                courseId: courseId,
                studentId: studentId,
                partId: partId,
                value: value,
                status: status,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PartScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseId = false, studentId = false, partId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable: $$PartScoresTableReferences
                                        ._courseIdTable(db),
                                    referencedColumn:
                                        $$PartScoresTableReferences
                                            ._courseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (studentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.studentId,
                                    referencedTable: $$PartScoresTableReferences
                                        ._studentIdTable(db),
                                    referencedColumn:
                                        $$PartScoresTableReferences
                                            ._studentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (partId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.partId,
                                    referencedTable: $$PartScoresTableReferences
                                        ._partIdTable(db),
                                    referencedColumn:
                                        $$PartScoresTableReferences
                                            ._partIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PartScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PartScoresTable,
      PartScoreRow,
      $$PartScoresTableFilterComposer,
      $$PartScoresTableOrderingComposer,
      $$PartScoresTableAnnotationComposer,
      $$PartScoresTableCreateCompanionBuilder,
      $$PartScoresTableUpdateCompanionBuilder,
      (PartScoreRow, $$PartScoresTableReferences),
      PartScoreRow,
      PrefetchHooks Function({bool courseId, bool studentId, bool partId})
    >;
typedef $$CorrectionsTableCreateCompanionBuilder =
    CorrectionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String cropPath,
      required String field,
      Value<String?> readValue,
      Value<String?> confirmedValue,
      Value<String?> region,
      Value<int> rowid,
    });
typedef $$CorrectionsTableUpdateCompanionBuilder =
    CorrectionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> cropPath,
      Value<String> field,
      Value<String?> readValue,
      Value<String?> confirmedValue,
      Value<String?> region,
      Value<int> rowid,
    });

class $$CorrectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropPath => $composableBuilder(
    column: $table.cropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readValue => $composableBuilder(
    column: $table.readValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedValue => $composableBuilder(
    column: $table.confirmedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CorrectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropPath => $composableBuilder(
    column: $table.cropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readValue => $composableBuilder(
    column: $table.readValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedValue => $composableBuilder(
    column: $table.confirmedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CorrectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get cropPath =>
      $composableBuilder(column: $table.cropPath, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get readValue =>
      $composableBuilder(column: $table.readValue, builder: (column) => column);

  GeneratedColumn<String> get confirmedValue => $composableBuilder(
    column: $table.confirmedValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);
}

class $$CorrectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CorrectionsTable,
          CorrectionRow,
          $$CorrectionsTableFilterComposer,
          $$CorrectionsTableOrderingComposer,
          $$CorrectionsTableAnnotationComposer,
          $$CorrectionsTableCreateCompanionBuilder,
          $$CorrectionsTableUpdateCompanionBuilder,
          (
            CorrectionRow,
            BaseReferences<_$AppDatabase, $CorrectionsTable, CorrectionRow>,
          ),
          CorrectionRow,
          PrefetchHooks Function()
        > {
  $$CorrectionsTableTableManager(_$AppDatabase db, $CorrectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CorrectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> cropPath = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String?> readValue = const Value.absent(),
                Value<String?> confirmedValue = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                cropPath: cropPath,
                field: field,
                readValue: readValue,
                confirmedValue: confirmedValue,
                region: region,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String cropPath,
                required String field,
                Value<String?> readValue = const Value.absent(),
                Value<String?> confirmedValue = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                cropPath: cropPath,
                field: field,
                readValue: readValue,
                confirmedValue: confirmedValue,
                region: region,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CorrectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CorrectionsTable,
      CorrectionRow,
      $$CorrectionsTableFilterComposer,
      $$CorrectionsTableOrderingComposer,
      $$CorrectionsTableAnnotationComposer,
      $$CorrectionsTableCreateCompanionBuilder,
      $$CorrectionsTableUpdateCompanionBuilder,
      (
        CorrectionRow,
        BaseReferences<_$AppDatabase, $CorrectionsTable, CorrectionRow>,
      ),
      CorrectionRow,
      PrefetchHooks Function()
    >;
typedef $$RecognitionRunsTableCreateCompanionBuilder =
    RecognitionRunsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String scanId,
      required String pipelineVersion,
      Value<String> status,
      Value<int> durationMs,
      required String resultJson,
      Value<int> rowid,
    });
typedef $$RecognitionRunsTableUpdateCompanionBuilder =
    RecognitionRunsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> scanId,
      Value<String> pipelineVersion,
      Value<String> status,
      Value<int> durationMs,
      Value<String> resultJson,
      Value<int> rowid,
    });

final class $$RecognitionRunsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecognitionRunsTable,
          RecognitionRunRow
        > {
  $$RecognitionRunsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScansTable _scanIdTable(_$AppDatabase db) => db.scans.createAlias(
    $_aliasNameGenerator(db.recognitionRuns.scanId, db.scans.id),
  );

  $$ScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecognitionRunsTableFilterComposer
    extends Composer<_$AppDatabase, $RecognitionRunsTable> {
  $$RecognitionRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pipelineVersion => $composableBuilder(
    column: $table.pipelineVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecognitionRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecognitionRunsTable> {
  $$RecognitionRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pipelineVersion => $composableBuilder(
    column: $table.pipelineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecognitionRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecognitionRunsTable> {
  $$RecognitionRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get pipelineVersion => $composableBuilder(
    column: $table.pipelineVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecognitionRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecognitionRunsTable,
          RecognitionRunRow,
          $$RecognitionRunsTableFilterComposer,
          $$RecognitionRunsTableOrderingComposer,
          $$RecognitionRunsTableAnnotationComposer,
          $$RecognitionRunsTableCreateCompanionBuilder,
          $$RecognitionRunsTableUpdateCompanionBuilder,
          (RecognitionRunRow, $$RecognitionRunsTableReferences),
          RecognitionRunRow,
          PrefetchHooks Function({bool scanId})
        > {
  $$RecognitionRunsTableTableManager(
    _$AppDatabase db,
    $RecognitionRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecognitionRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecognitionRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecognitionRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> pipelineVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecognitionRunsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                scanId: scanId,
                pipelineVersion: pipelineVersion,
                status: status,
                durationMs: durationMs,
                resultJson: resultJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String scanId,
                required String pipelineVersion,
                Value<String> status = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                required String resultJson,
                Value<int> rowid = const Value.absent(),
              }) => RecognitionRunsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                scanId: scanId,
                pipelineVersion: pipelineVersion,
                status: status,
                durationMs: durationMs,
                resultJson: resultJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecognitionRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable:
                                    $$RecognitionRunsTableReferences
                                        ._scanIdTable(db),
                                referencedColumn:
                                    $$RecognitionRunsTableReferences
                                        ._scanIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecognitionRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecognitionRunsTable,
      RecognitionRunRow,
      $$RecognitionRunsTableFilterComposer,
      $$RecognitionRunsTableOrderingComposer,
      $$RecognitionRunsTableAnnotationComposer,
      $$RecognitionRunsTableCreateCompanionBuilder,
      $$RecognitionRunsTableUpdateCompanionBuilder,
      (RecognitionRunRow, $$RecognitionRunsTableReferences),
      RecognitionRunRow,
      PrefetchHooks Function({bool scanId})
    >;
typedef $$FieldReviewsTableCreateCompanionBuilder =
    FieldReviewsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String scanId,
      Value<String?> runId,
      required String fieldKey,
      required String kind,
      Value<String?> machineValue,
      Value<String?> machineState,
      Value<String?> finalValue,
      required String decision,
      Value<String?> region,
      required DateTime reviewedAt,
      Value<int> rowid,
    });
typedef $$FieldReviewsTableUpdateCompanionBuilder =
    FieldReviewsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> scanId,
      Value<String?> runId,
      Value<String> fieldKey,
      Value<String> kind,
      Value<String?> machineValue,
      Value<String?> machineState,
      Value<String?> finalValue,
      Value<String> decision,
      Value<String?> region,
      Value<DateTime> reviewedAt,
      Value<int> rowid,
    });

final class $$FieldReviewsTableReferences
    extends BaseReferences<_$AppDatabase, $FieldReviewsTable, FieldReviewRow> {
  $$FieldReviewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScansTable _scanIdTable(_$AppDatabase db) => db.scans.createAlias(
    $_aliasNameGenerator(db.fieldReviews.scanId, db.scans.id),
  );

  $$ScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FieldReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $FieldReviewsTable> {
  $$FieldReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineValue => $composableBuilder(
    column: $table.machineValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineState => $composableBuilder(
    column: $table.machineState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalValue => $composableBuilder(
    column: $table.finalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldReviewsTable> {
  $$FieldReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineValue => $composableBuilder(
    column: $table.machineValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineState => $composableBuilder(
    column: $table.machineState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalValue => $composableBuilder(
    column: $table.finalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldReviewsTable> {
  $$FieldReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get machineValue => $composableBuilder(
    column: $table.machineValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineState => $composableBuilder(
    column: $table.machineState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalValue => $composableBuilder(
    column: $table.finalValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FieldReviewsTable,
          FieldReviewRow,
          $$FieldReviewsTableFilterComposer,
          $$FieldReviewsTableOrderingComposer,
          $$FieldReviewsTableAnnotationComposer,
          $$FieldReviewsTableCreateCompanionBuilder,
          $$FieldReviewsTableUpdateCompanionBuilder,
          (FieldReviewRow, $$FieldReviewsTableReferences),
          FieldReviewRow,
          PrefetchHooks Function({bool scanId})
        > {
  $$FieldReviewsTableTableManager(_$AppDatabase db, $FieldReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String?> runId = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> machineValue = const Value.absent(),
                Value<String?> machineState = const Value.absent(),
                Value<String?> finalValue = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FieldReviewsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                scanId: scanId,
                runId: runId,
                fieldKey: fieldKey,
                kind: kind,
                machineValue: machineValue,
                machineState: machineState,
                finalValue: finalValue,
                decision: decision,
                region: region,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String scanId,
                Value<String?> runId = const Value.absent(),
                required String fieldKey,
                required String kind,
                Value<String?> machineValue = const Value.absent(),
                Value<String?> machineState = const Value.absent(),
                Value<String?> finalValue = const Value.absent(),
                required String decision,
                Value<String?> region = const Value.absent(),
                required DateTime reviewedAt,
                Value<int> rowid = const Value.absent(),
              }) => FieldReviewsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                scanId: scanId,
                runId: runId,
                fieldKey: fieldKey,
                kind: kind,
                machineValue: machineValue,
                machineState: machineState,
                finalValue: finalValue,
                decision: decision,
                region: region,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FieldReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable: $$FieldReviewsTableReferences
                                    ._scanIdTable(db),
                                referencedColumn: $$FieldReviewsTableReferences
                                    ._scanIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FieldReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FieldReviewsTable,
      FieldReviewRow,
      $$FieldReviewsTableFilterComposer,
      $$FieldReviewsTableOrderingComposer,
      $$FieldReviewsTableAnnotationComposer,
      $$FieldReviewsTableCreateCompanionBuilder,
      $$FieldReviewsTableUpdateCompanionBuilder,
      (FieldReviewRow, $$FieldReviewsTableReferences),
      FieldReviewRow,
      PrefetchHooks Function({bool scanId})
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String userId,
      Value<String?> email,
      Value<String> plan,
      Value<DateTime?> planValidUntil,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> userId,
      Value<String?> email,
      Value<String> plan,
      Value<DateTime?> planValidUntil,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get planValidUntil => $composableBuilder(
    column: $table.planValidUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get planValidUntil => $composableBuilder(
    column: $table.planValidUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<DateTime> get planValidUntil => $composableBuilder(
    column: $table.planValidUntil,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<DateTime?> planValidUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                userId: userId,
                email: email,
                plan: plan,
                planValidUntil: planValidUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String userId,
                Value<String?> email = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<DateTime?> planValidUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                userId: userId,
                email: email,
                plan: plan,
                planValidUntil: planValidUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String syncTable,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastPushAt,
      Value<int> rowid,
    });
typedef $$SyncStatesTableUpdateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncTable,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastPushAt,
      Value<int> rowid,
    });

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncTable => $composableBuilder(
    column: $table.syncTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncTable => $composableBuilder(
    column: $table.syncTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncTable =>
      $composableBuilder(column: $table.syncTable, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => column,
  );
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncStateRow,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncTable = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncTable: syncTable,
                lastPullAt: lastPullAt,
                lastPushAt: lastPushAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String syncTable,
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncTable: syncTable,
                lastPullAt: lastPullAt,
                lastPushAt: lastPushAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncStateRow,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$CoursePartsTableTableManager get courseParts =>
      $$CoursePartsTableTableManager(_db, _db.courseParts);
  $$ExamQuestionsTableTableManager get examQuestions =>
      $$ExamQuestionsTableTableManager(_db, _db.examQuestions);
  $$GradeScalesTableTableManager get gradeScales =>
      $$GradeScalesTableTableManager(_db, _db.gradeScales);
  $$SchemeTemplatesTableTableManager get schemeTemplates =>
      $$SchemeTemplatesTableTableManager(_db, _db.schemeTemplates);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db, _db.batches);
  $$ScansTableTableManager get scans =>
      $$ScansTableTableManager(_db, _db.scans);
  $$BookletsTableTableManager get booklets =>
      $$BookletsTableTableManager(_db, _db.booklets);
  $$QuestionMarksTableTableManager get questionMarks =>
      $$QuestionMarksTableTableManager(_db, _db.questionMarks);
  $$RowReadsTableTableManager get rowReads =>
      $$RowReadsTableTableManager(_db, _db.rowReads);
  $$PartScoresTableTableManager get partScores =>
      $$PartScoresTableTableManager(_db, _db.partScores);
  $$CorrectionsTableTableManager get corrections =>
      $$CorrectionsTableTableManager(_db, _db.corrections);
  $$RecognitionRunsTableTableManager get recognitionRuns =>
      $$RecognitionRunsTableTableManager(_db, _db.recognitionRuns);
  $$FieldReviewsTableTableManager get fieldReviews =>
      $$FieldReviewsTableTableManager(_db, _db.fieldReviews);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
}
