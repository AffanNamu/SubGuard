import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../providers/providers.dart';
import '../../services/export/result_table.dart';

/// The optional header above every export. Set once; used for every course.
class HeaderSettingsScreen extends ConsumerStatefulWidget {
  const HeaderSettingsScreen({super.key});

  @override
  ConsumerState<HeaderSettingsScreen> createState() => _HeaderSettingsScreenState();
}

class _HeaderSettingsScreenState extends ConsumerState<HeaderSettingsScreen> {
  late final ExportHeader _initial = ref.read(settingsProvider).header;
  late final _university = TextEditingController(text: _initial.university);
  late final _faculty = TextEditingController(text: _initial.faculty);
  late final _department = TextEditingController(text: _initial.department);
  late final _session = TextEditingController(text: _initial.session);
  late final _examiner = TextEditingController(text: _initial.examiner);

  @override
  void dispose() {
    for (final c in [_university, _faculty, _department, _session, _examiner]) {
      c.dispose();
    }
    super.dispose();
  }

  ExportHeader get _header => ExportHeader(
        university: _university.text,
        faculty: _faculty.text,
        department: _department.text,
        session: _session.text,
        examiner: _examiner.text,
      );

  void _save() {
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(header: _header));
  }

  Widget _field(TextEditingController c, String label, {String? hint, bool last = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          textCapitalization: TextCapitalization.words,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          onChanged: (_) {
            setState(() {});
            _save();
          },
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final lines = _header.lines();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Document header')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(
              'Printed above the table in Word, Excel and PDF files. Leave a line empty to leave it out. It saves as you type.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _field(_university, 'University', hint: 'Modibbo Adama University, Yola'),
            _field(_faculty, 'Faculty', hint: 'Faculty of Agriculture'),
            _field(_department, 'Department'),
            _field(_session, 'Session', hint: '2024/2025'),
            _field(_examiner, 'Examiner', hint: 'Dr A. Example', last: true),
            const SectionHeading('How it prints'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  if (lines.isEmpty)
                    const Text('No header', style: TextStyle(color: Colors.black54, fontFamily: 'serif')),
                  for (var i = 0; i < lines.length; i++)
                    Text(
                      lines[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'serif',
                        fontSize: 15,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text('(FWM) AGR 114',
                      style: TextStyle(color: Colors.black, fontFamily: 'serif', fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
