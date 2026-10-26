import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../domain/layout_profile.dart';
import '../../providers/providers.dart';

/// Which booklet cover UniMarkLy reads photos with.
///
/// A layout says where to look on a cover: the printed labels, and from them the exam
/// number, the marks table and the total. The built-in one is the Modibbo Adama
/// University booklet. Another department's cover is read by adding its layout file
/// (the built-in layout can be shared as a starting point). Photos are read with the
/// layout chosen here; a photo already read keeps the record of the layout that read it.
class LayoutScreen extends ConsumerStatefulWidget {
  const LayoutScreen({super.key});

  @override
  ConsumerState<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends ConsumerState<LayoutScreen> {
  /// What was wrong with the last file added, in the file's own terms.
  String? _problem;
  String? _added;
  bool _busy = false;

  Future<void> _add() async {
    setState(() {
      _problem = null;
      _added = null;
      _busy = true;
    });
    try {
      final picked = await ref.read(layoutFilePickerProvider)();
      if (picked == null) return;
      final profile = await ref.read(layoutChoiceProvider.notifier).add(picked.text);
      if (mounted) setState(() => _added = '"${profile.name}" was added. Choose it below to read photos with it.');
    } on LayoutProfileException catch (e) {
      if (mounted) setState(() => _problem = e.message);
    } catch (_) {
      if (mounted) setState(() => _problem = 'The file could not be read. Nothing was added.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(LayoutProfile p) async {
    try {
      await ref.read(layoutFileSharerProvider)('${p.id}.json', '${p.encode()}\n');
    } catch (_) {
      if (mounted) showMessage(context, 'The file could not be shared. Please try again.');
    }
  }

  Future<void> _remove(LayoutProfile p) async {
    final ok = await confirm(
      context,
      title: 'Remove this layout?',
      message: '"${p.name}" will be removed from this phone. Booklets already read with it keep their results.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (ok) await ref.read(layoutChoiceProvider.notifier).remove(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final choice = ref.watch(layoutChoiceProvider);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Booklet layout')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'A layout tells UniMarkLy where to look on a booklet cover: the printed labels, and from them the exam number, '
              'the marks table and the total. Photos you add are read with the layout chosen here.',
              style: text.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: choice.selected.id,
              onChanged: (id) {
                if (id != null) ref.read(layoutChoiceProvider.notifier).select(id);
              },
              child: Column(
                children: [
                  for (final p in choice.all)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        key: ValueKey('layout-${p.id}'),
                        value: p.id,
                        title: Text(p.name, style: text.titleMedium),
                        subtitle: Text([
                          if (p.description != null) p.description!,
                          choice.isBuiltIn(p) ? 'Built in' : 'Added by you · revision ${p.revision}',
                        ].join('\n')),
                        isThreeLine: p.description != null,
                        secondary: PopupMenuButton<String>(
                          tooltip: 'More about ${p.name}',
                          onSelected: (v) => v == 'share' ? _share(p) : _remove(p),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'share', child: Text('Share a copy of this file')),
                            if (!choice.isBuiltIn(p)) const PopupMenuItem(value: 'remove', child: Text('Remove')),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_added != null) Padding(padding: const EdgeInsets.only(top: 4, bottom: 8), child: InfoBanner(message: _added!, kind: BannerKind.success)),
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: InfoBanner(message: 'That file was not added. $_problem', kind: BannerKind.danger),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a layout file'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To read another department\'s cover, share the built-in file with the menu above, change the labels and positions '
              'to match that cover, and add the edited file here. Every file is checked before it is used; if something is wrong '
              'it says what and where. The format is described in docs/recognition/LAYOUT_PROFILES.md.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
