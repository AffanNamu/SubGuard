import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../services/incoming/file_inspector.dart';
import '../../services/incoming/incoming_file.dart';
import '../../services/scan/image_source.dart';
import '../scan/scan_screen.dart';
import '../scan/upload_flow.dart';
import 'incoming_controller.dart';
import 'incoming_file_screen.dart';

/// Several documents arrived together. Each can be opened on its own, and if
/// some are photos they can be scanned as booklets in one go.
class IncomingListScreen extends ConsumerStatefulWidget {
  const IncomingListScreen({super.key, required this.files});

  final List<IncomingFile> files;

  @override
  ConsumerState<IncomingListScreen> createState() => _IncomingListScreenState();
}

class _IncomingListScreenState extends ConsumerState<IncomingListScreen> {
  final Map<String, Inspection> _inspected = {};

  @override
  void initState() {
    super.initState();
    _inspectAll();
  }

  @override
  void dispose() {
    for (final f in widget.files) {
      IncomingController.deleteCopy(f);
    }
    super.dispose();
  }

  Future<void> _inspectAll() async {
    for (final f in widget.files) {
      final r = await FileInspector.inspect(File(f.path), name: f.name, mime: f.mime);
      if (!mounted) return;
      setState(() => _inspected[f.id] = r);
    }
  }

  List<IncomingFile> get _photos => [
        for (final f in widget.files)
          if (_inspected[f.id]?.ok == true && _inspected[f.id]!.kind == IncomingKind.image) f,
      ];

  Future<void> _scanPhotos() async {
    final photos = _photos;
    final courseId = await chooseCourse(context, ref);
    if (courseId == null || !mounted) return;
    final batch = await addPhotos(
      context,
      ref,
      [for (final f in photos) PickedImage(name: f.name, path: f.path)],
      courseId: courseId,
    );
    if (batch != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => ScanScreen(batchId: batch)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final photos = _photos;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.files.length} documents')),
      body: ContentWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (photos.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GradientButton(
                  label: 'Scan ${photos.length} photos as booklets',
                  icon: Icons.document_scanner_rounded,
                  expand: true,
                  onPressed: _scanPhotos,
                ),
              ),
            for (final f in widget.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlowCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _inspected[f.id] == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => IncomingFileScreen(file: f, deleteOnClose: false),
                            ),
                          ),
                  child: Row(
                    children: [
                      Icon(_icon(_inspected[f.id]), color: scheme.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                            Text(
                              _line(_inspected[f.id]),
                              style: text.bodyMedium?.copyWith(
                                color: _inspected[f.id]?.ok == false ? context.colors.danger : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(Inspection? r) {
    if (r == null) return Icons.hourglass_empty_rounded;
    if (!r.ok) return Icons.error_outline_rounded;
    return switch (r.kind) {
      IncomingKind.pdf => Icons.picture_as_pdf_outlined,
      IncomingKind.docx || IncomingKind.doc => Icons.description_outlined,
      IncomingKind.xlsx || IncomingKind.xls || IncomingKind.csv => Icons.grid_on_rounded,
      IncomingKind.image => Icons.photo_outlined,
      IncomingKind.unknown => Icons.help_outline_rounded,
    };
  }

  static String _line(Inspection? r) {
    if (r == null) return 'Checking…';
    if (!r.ok) return r.problem!.message;
    return r.kind.label;
  }
}
