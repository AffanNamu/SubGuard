import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../providers/providers.dart';

/// Session and semester that new courses start with.
class DefaultsScreen extends ConsumerStatefulWidget {
  const DefaultsScreen({super.key});

  @override
  ConsumerState<DefaultsScreen> createState() => _DefaultsScreenState();
}

class _DefaultsScreenState extends ConsumerState<DefaultsScreen> {
  late final _session = TextEditingController(text: ref.read(settingsProvider).defaultSession);
  late final _semester = TextEditingController(text: ref.read(settingsProvider).defaultSemester);

  @override
  void dispose() {
    _session.dispose();
    _semester.dispose();
    super.dispose();
  }

  void _save() => ref.read(settingsProvider.notifier).update(
        (s) => s.copyWith(defaultSession: _session.text.trim(), defaultSemester: _semester.text.trim()),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New course defaults')),
        body: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Text(
                'New courses start with these. You can change them on each course.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _session,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Session', hintText: '2024/2025'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _semester,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Semester', hintText: 'First'),
              ),
            ],
          ),
        ),
      );
}
