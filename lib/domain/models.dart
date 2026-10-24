import 'scheme.dart';

class Course {
  const Course({
    required this.id,
    required this.code,
    this.department = '',
    this.session = '',
    this.semester = '',
    required this.scheme,
  });

  final String id;
  final String code;
  final String department;
  final String session;
  final String semester;
  final GradingScheme scheme;

  /// Heading used on exports: "(FWM) AGR 114".
  String get title {
    final dept = department.trim();
    return dept.isEmpty ? code : '($dept) $code';
  }

  Course copyWith({
    String? code,
    String? department,
    String? session,
    String? semester,
    GradingScheme? scheme,
  }) =>
      Course(
        id: id,
        code: code ?? this.code,
        department: department ?? this.department,
        session: session ?? this.session,
        semester: semester ?? this.semester,
        scheme: scheme ?? this.scheme,
      );
}

class Student {
  const Student({
    required this.id,
    required this.courseId,
    required this.regNo,
    this.name,
    this.onClassList = true,
    this.position = 0,
  });

  final String id;
  final String courseId;

  /// Stored in one form: upper case DEPT/YYU/NNNN, optional middle part.
  final String regNo;
  final String? name;

  /// False for numbers added by hand that were not on the imported list.
  final bool onClassList;

  /// Order the student was added in; "scan order" for exports.
  final int position;

  Student copyWith({String? regNo, String? name, bool? onClassList}) => Student(
        id: id,
        courseId: courseId,
        regNo: regNo ?? this.regNo,
        name: name ?? this.name,
        onClassList: onClassList ?? this.onClassList,
        position: position,
      );
}

class SchemeTemplate {
  const SchemeTemplate({
    required this.id,
    required this.name,
    required this.scheme,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final GradingScheme scheme;
  final bool isBuiltIn;
}
