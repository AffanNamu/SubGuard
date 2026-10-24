import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../services/incoming/document_loaders.dart';
import '../../services/incoming/file_inspector.dart';
import '../../services/incoming/incoming_file.dart';
import '../../services/scan/image_source.dart';
import '../roster/import_screen.dart';
import '../scan/scan_screen.dart';
import '../scan/upload_flow.dart';
import 'document_views.dart';
import 'incoming_controller.dart';
import 'saved_documents_screen.dart';

/// A document from another app (or one kept in UniMarkLy): checked first, then
/// shown, with the next steps that make sense for what it is.
///
/// Viewing and importing are separate. Nothing here changes a course, a class
/// list or a score; the import screens ask, and show what will happen, first.
class IncomingFileScreen extends ConsumerStatefulWidget {
  const IncomingFileScreen({super.key, required this.file, this.deleteOnClose = true});

  final IncomingFile file;

  /// The private copy is removed when the screen closes. A copy kept in
  /// "Saved documents", or one owned by a list of several files, is not.
  final bool deleteOnClose;

  @override
  ConsumerState<IncomingFileScreen> createState() => _IncomingFileScreenState();
}

class _IncomingFileScreenState extends ConsumerState<IncomingFileScreen> {
  Inspection? _inspection;
  FileProblem? _problem;
  Object? _doc; // TableDoc or TextDoc
  String? _pdfError;
  int _sheet = 0;
  bool _busy = false;
  String? _busyText;

  IncomingFile get file => widget.file;
  IncomingKind get _kind => _inspection?.kind ?? IncomingKind.unknown;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    if (widget.deleteOnClose) IncomingController.deleteCopy(file);
    super.dispose();
  }

  Future<void> _open() async {
    final inspection = await FileInspector.inspect(File(file.path), name: file.name, mime: file.mime);
    if (!mounted) return;
    if (!inspection.ok) {
      setState(() {
        _inspection = inspection;
        _problem = inspection.problem;
      });
      return;
    }
    setState(() => _inspection = inspection);
    try {
      switch (inspection.kind) {
        case IncomingKind.csv:
          _doc = await DocumentLoader.loadCsv(file.path);
        case IncomingKind.xlsx:
          _doc = await DocumentLoader.loadXlsx(file.path);
        case IncomingKind.docx:
          _doc = await DocumentLoader.loadDocx(file.path);
        case IncomingKind.pdf:
        case IncomingKind.doc:
        case IncomingKind.xls:
        case IncomingKind.image:
        case IncomingKind.unknown:
          break;
      }
    } on DocumentReadException catch (e) {
      _problem = e.problem;
    } catch (_) {
      _problem = FileProblem.corrupt;
    }
    if (mounted) setState(() {});
  }

  // ---- actions ----

  Future<void> _share() async {
    try {
      await Share.shareXFiles([XFile(file.path, name: file.name)]);
    } catch (_) {
      if (mounted) showMessage(context, 'The file could not be shared.');
    }
  }

  Future<void> _save() async {
    try {
      final outcome = await ref.read(savedDocumentsProvider).save(File(file.path), name: file.name);
      if (!mounted) return;
      showMessage(
        context,
        outcome.alreadySaved
            ? 'Already saved in UniMarkLy as ${outcome.document.name}.'
            : 'Saved in UniMarkLy: ${outcome.document.name}. Find it in Settings, Saved documents.',
      );
    } catch (_) {
      if (mounted) showMessage(context, 'The file could not be saved. Check that the phone has free space.');
    }
  }

  Future<void> _importTable(ImportMode mode) async {
    final doc = _doc as TableDoc?;
    if (doc == null) return;
    final classList = mode == ImportMode.classList;
    final courseId = await chooseCourse(
      context,
      ref,
      question: classList ? 'Which course is this class list for?' : 'Which course are these scores for?',
      createMessage: 'A list is added to a course. Create the course first, then open this file again from Saved documents.',
    );
    if (courseId == null || !mounted) return;

    setState(() {
      _busy = true;
      _busyText = 'Reading the whole sheet…';
    });
    try {
      final table = await DocumentLoader.loadTable(
        file.path,
        excel: _kind == IncomingKind.xlsx,
        sheet: _kind == IncomingKind.xlsx ? doc.sheets[_sheet].name : null,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      // The import screen shows how the columns were matched and what will
      // happen. Nothing is written until its button is pressed.
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ImportScreen(courseId: courseId, mode: mode, initialTable: table, initialName: file.name),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, 'The sheet could not be read. Nothing was changed.');
      }
    }
  }

  Future<void> _scanPhoto() async {
    final courseId = await chooseCourse(context, ref);
    if (courseId == null || !mounted) return;
    final batch = await addPhotos(context, ref, [PickedImage(name: file.name, path: file.path)], courseId: courseId);
    if (batch != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => ScanScreen(batchId: batch)));
    }
  }

  Future<void> _scanPdf() async {
    final courseId = await chooseCourse(context, ref);
    if (courseId == null || !mounted) return;
    setState(() {
      _busy = true;
      _busyText = 'Turning the pages into photos…';
    });
    final temp = await Directory.systemTemp.createTemp('unimarkly_pdf_pages_');
    try {
      final pages = await ref.read(pdfBackendProvider).renderPages(
        file.path,
        temp,
        onProgress: (done, total) {
          if (mounted) setState(() => _busyText = 'Turning page $done of $total into a photo…');
        },
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (pages.isEmpty) {
        showMessage(context, 'No pages could be read from this PDF.');
        return;
      }
      final stem = p.basenameWithoutExtension(file.name);
      final batch = await addPhotos(
        context,
        ref,
        [
          for (var i = 0; i < pages.length; i++)
            PickedImage(name: '$stem page ${i + 1}.jpg', path: pages[i].path),
        ],
        courseId: courseId,
      );
      if (batch != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => ScanScreen(batchId: batch)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, 'The pages could not be turned into photos. Nothing was changed.');
      }
    } finally {
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    }
  }

  // ---- screen ----

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
            if (_inspection != null)
              Text('${_kind == IncomingKind.unknown ? 'File' : _kind.label} · ${_size(file.size)}',
                  style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              switch (v) {
                case 'share':
                  _share();
                case 'save':
                  _save();
                case 'saved':
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SavedDocumentsScreen()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'share', child: Text('Open in another app')),
              PopupMenuItem(value: 'save', child: Text('Save a copy in UniMarkLy')),
              PopupMenuItem(value: 'saved', child: Text('Saved documents')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _body(context)),
              if (_inspection != null) _actions(context),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 20),
                          Flexible(child: Text(_busyText ?? 'Working…')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_inspection == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final problem = _problem;
    if (problem != null) {
      return NoticeView(
        icon: switch (problem) {
          FileProblem.passwordProtected => Icons.lock_outline_rounded,
          FileProblem.tooLarge => Icons.sd_storage_outlined,
          FileProblem.unsupported => Icons.help_outline_rounded,
          _ => Icons.error_outline_rounded,
        },
        color: context.colors.danger,
        title: switch (problem) {
          FileProblem.passwordProtected => 'This file is locked',
          FileProblem.tooLarge => 'This file is too large to open here',
          FileProblem.unsupported => 'This kind of file cannot be opened',
          FileProblem.empty => 'This file is empty',
          FileProblem.missing => 'The file is not there any more',
          FileProblem.corrupt => 'This file is damaged',
        },
        message: problem.message,
      );
    }

    switch (_kind) {
      case IncomingKind.csv:
      case IncomingKind.xlsx:
        final doc = _doc as TableDoc?;
        if (doc == null) return const Center(child: CircularProgressIndicator());
        return Column(
          children: [
            if (doc.sheets.length > 1)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (var i = 0; i < doc.sheets.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(doc.sheets[i].name),
                          selected: i == _sheet,
                          onSelected: (_) => setState(() => _sheet = i),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: TableViewer(key: ValueKey('sheet$_sheet'), sheet: doc.sheets[_sheet])),
          ],
        );
      case IncomingKind.docx:
        final doc = _doc as TextDoc?;
        if (doc == null) return const Center(child: CircularProgressIndicator());
        return TextViewer(doc: doc);
      case IncomingKind.pdf:
        if (_pdfError != null) {
          return NoticeView(
              icon: Icons.error_outline_rounded,
              color: context.colors.danger,
              title: 'This PDF could not be drawn',
              message: '$_pdfError You can still open it in another app, or save a copy.');
        }
        return ref.watch(pdfBackendProvider).view(
              file.path,
              onError: (m) {
                if (mounted && _pdfError == null) setState(() => _pdfError = m);
              },
            );
      case IncomingKind.doc:
        return const NoticeView(
          icon: Icons.description_outlined,
          title: 'Old Word files cannot be shown here',
          message:
              'This is the old .doc format, which UniMarkLy cannot draw reliably. Open it in another app, '
              'save a copy to keep it, or save it as .docx or PDF where you made it.',
        );
      case IncomingKind.xls:
        return const NoticeView(
          icon: Icons.grid_on_rounded,
          title: 'Old Excel files cannot be shown here',
          message:
              'This is the old .xls format, which UniMarkLy cannot read. Open it in another app, '
              'save a copy to keep it, or save it as .xlsx or CSV where you made it, then open that.',
        );
      case IncomingKind.image:
        return InteractiveViewer(
          maxScale: 8,
          child: Center(child: Image.file(File(file.path), fit: BoxFit.contain, errorBuilder: (_, __, ___) {
            return const NoticeView(
                icon: Icons.broken_image_outlined,
                title: 'This photo could not be drawn',
                message: 'It may be damaged or in a format this phone cannot show.');
          })),
        );
      case IncomingKind.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _actions(BuildContext context) {
    final ok = _problem == null;
    final buttons = <Widget>[];

    if (!ok) {
      buttons.addAll([
        PillButton(label: 'Open in another app', icon: Icons.open_in_new_rounded, onPressed: _share),
      ]);
    } else {
      switch (_kind) {
        case IncomingKind.csv:
        case IncomingKind.xlsx:
          if (_doc != null) {
            buttons.addAll([
              GradientButton(
                label: 'Use as class list',
                icon: Icons.groups_rounded,
                expand: true,
                onPressed: () => _importTable(ImportMode.classList),
              ),
              PillButton(
                label: 'Add scores from it',
                icon: Icons.playlist_add_rounded,
                onPressed: () => _importTable(ImportMode.scores),
              ),
            ]);
          }
        case IncomingKind.image:
          buttons.add(GradientButton(
            label: 'Scan this booklet',
            icon: Icons.document_scanner_rounded,
            expand: true,
            onPressed: _scanPhoto,
          ));
        case IncomingKind.pdf:
          if (_pdfError == null) {
            buttons.add(GradientButton(
              label: 'Scan its pages as booklets',
              icon: Icons.document_scanner_rounded,
              expand: true,
              onPressed: _scanPdf,
            ));
          }
        case IncomingKind.docx:
        case IncomingKind.doc:
        case IncomingKind.xls:
        case IncomingKind.unknown:
          break;
      }
      buttons.add(PillButton(label: 'Save a copy', icon: Icons.save_alt_rounded, onPressed: _save));
      if (_kind == IncomingKind.doc || _kind == IncomingKind.xls || _kind == IncomingKind.docx || _pdfError != null) {
        buttons.add(PillButton(label: 'Open in another app', icon: Icons.open_in_new_rounded, onPressed: _share));
      }
    }

    return BottomActionBar(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final b in buttons)
            b is GradientButton ? SizedBox(width: double.infinity, child: b) : b,
        ],
      ),
    );
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
