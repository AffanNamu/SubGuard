import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common.dart';
import '../../data/repositories/recognition_repository.dart';
import '../../providers/providers.dart';
import '../../services/export/labelled_export.dart';

/// The pieces of handwriting the examiner has confirmed, kept on this phone as
/// labelled examples, and a deliberate way to take them out.
final labelledExamplesProvider = FutureProvider<List<LabelledExample>>((ref) {
  ref.watch(batchesProvider); // confirming a booklet adds examples
  return ref.watch(recognitionRepositoryProvider).labelledExamples();
});

class TrainingExamplesScreen extends ConsumerStatefulWidget {
  const TrainingExamplesScreen({super.key});

  @override
  ConsumerState<TrainingExamplesScreen> createState() => _TrainingExamplesScreenState();
}

class _TrainingExamplesScreenState extends ConsumerState<TrainingExamplesScreen> {
  bool _agreed = false;
  bool _busy = false;
  String? _message;

  Future<void> _export(List<LabelledExample> examples) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final temp = await getTemporaryDirectory();
      final result = await LabelledExport.build(
        examples: examples,
        files: ref.read(scanFilesProvider),
        directory: Directory('${temp.path}/examples'),
      );
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _busy = false;
          _message = 'None of the photos could be read, so nothing was exported.';
        });
        return;
      }
      setState(() {
        _busy = false;
        _message = '${result.examples} examples were packed'
            '${result.skipped == 0 ? '' : ' (${result.skipped} left out because their photo is gone)'}. Choose where to send the file.';
      });
      await Share.shareXFiles([XFile(result.file.path, mimeType: 'application/zip')], subject: 'UniMarkLy labelled examples');
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = 'The examples could not be packed. Nothing was sent. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(labelledExamplesProvider);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Training examples')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const ErrorState(message: 'The examples could not be loaded.'),
        data: (examples) => ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                examples.isEmpty ? 'No examples yet' : '${examples.length} confirmed ${examples.length == 1 ? 'example' : 'examples'}',
                style: text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Every time you confirm a booklet, each value you confirmed is kept with the part of the photo it was written on. '
                'These are what the reader needs to learn from real handwriting. Nothing is sent anywhere, and the reader does not '
                'change by itself.',
                style: text.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                message: 'The pictures are of real handwriting and real registration numbers. Export them only when the people '
                    'concerned agree, and only to improve the reader.',
                kind: BannerKind.warning,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _agreed,
                onChanged: examples.isEmpty ? null : (v) => setState(() => _agreed = v ?? false),
                title: const Text('The examiners and candidates concerned agree to this.'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: (examples.isEmpty || !_agreed || _busy) ? null : () => _export(examples),
                icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.ios_share_rounded),
                label: Text(_busy ? 'Packing…' : 'Export examples'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: text.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
