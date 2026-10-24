import 'package:flutter/material.dart';

import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import '../../domain/reg_no.dart';

class StudentEdit {
  const StudentEdit(this.regNo, this.name);
  final String regNo;
  final String? name;
}

/// Add or edit one student. The registration number is checked as it is
/// typed: repaired to the standard form, compared with the pattern, and
/// compared with the rest of the class list. Nothing here blocks saving.
Future<StudentEdit?> showStudentSheet(
  BuildContext context, {
  Student? existing,
  required List<Student> others,
}) {
  return showModalBottomSheet<StudentEdit>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StudentSheet(existing: existing, others: others),
  );
}

class _StudentSheet extends StatefulWidget {
  const _StudentSheet({this.existing, required this.others});

  final Student? existing;
  final List<Student> others;

  @override
  State<_StudentSheet> createState() => _StudentSheetState();
}

class _StudentSheetState extends State<_StudentSheet> {
  late final _reg = TextEditingController(text: widget.existing?.regNo ?? '');
  late final _name = TextEditingController(text: widget.existing?.name ?? '');

  @override
  void dispose() {
    _reg.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = RegNo.normalise(_reg.text);
    final blank = result.canonical.isEmpty;
    final clash = !blank &&
        widget.others.any((s) => s.id != widget.existing?.id && RegNo.key(s.regNo) == result.canonical);

    Widget feedback() {
      if (blank) return const SizedBox.shrink();
      if (clash) {
        return const InfoBanner(
          message: 'This number is already on the class list. Saving it again will flag both rows.',
          kind: BannerKind.warning,
        );
      }
      if (!result.isValid) {
        return const InfoBanner(
          message: 'This does not look like DEPT/YYU/NNNN, for example FWM/24U/0538. You can still save it; it will be flagged.',
          kind: BannerKind.warning,
        );
      }
      return InfoBanner(
        message: result.wasCorrected
            ? 'Will be saved as ${result.canonical}. ${result.corrections.join('. ')}.'
            : 'Looks right: ${result.canonical}',
        kind: BannerKind.success,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existing == null ? 'Add a student' : 'Edit student', style: text.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _reg,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Registration number',
                  hintText: 'FWM/24U/0538',
                ),
              ),
              const SizedBox(height: 10),
              feedback(),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Name (optional)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: blank
                    ? null
                    : () => Navigator.pop(context, StudentEdit(_reg.text, _name.text)),
                child: Text(widget.existing == null ? 'Add student' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
