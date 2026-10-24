import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/widgets/common.dart';

/// Draws a PDF's pages for the viewer. Behind an interface because PDF
/// rendering is done by the phone's own PDF engine, which does not exist in
/// `flutter test`; tests use a stand-in and the real one is checked on a phone.
abstract class PdfBackend {
  const PdfBackend();

  /// A scrolling, zooming view of every page, with its own page controls.
  /// [onError] is called with words for the person if the file can not be drawn.
  Widget view(String path, {required void Function(String message) onError});

  /// Renders pages to JPEG photos in [outDir], one at a time (so a long PDF
  /// does not fill the phone's memory), for the booklet-scanning workflow.
  /// Throws if the file can not be opened.
  Future<List<File>> renderPages(
    String path,
    Directory outDir, {
    int maxPages = 40,
    void Function(int done, int total)? onProgress,
  });
}

class PdfxBackend extends PdfBackend {
  const PdfxBackend();

  @override
  Widget view(String path, {required void Function(String message) onError}) =>
      _PdfxPane(path: path, onError: onError);

  @override
  Future<List<File>> renderPages(
    String path,
    Directory outDir, {
    int maxPages = 40,
    void Function(int done, int total)? onProgress,
  }) async {
    final doc = await PdfDocument.openFile(path);
    try {
      final total = doc.pagesCount < maxPages ? doc.pagesCount : maxPages;
      final out = <File>[];
      await outDir.create(recursive: true);
      for (var i = 1; i <= total; i++) {
        final page = await doc.getPage(i);
        try {
          // About 200 dpi on an A4 page: enough for handwriting.
          final scale = 1600 / (page.width < page.height ? page.width : page.height);
          final image = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 92,
          );
          if (image == null) continue;
          final file = File('${outDir.path}/page_${i.toString().padLeft(3, '0')}.jpg');
          await file.writeAsBytes(image.bytes);
          out.add(file);
        } finally {
          await page.close();
        }
        onProgress?.call(i, total);
      }
      return out;
    } finally {
      await doc.close();
    }
  }
}

class _PdfxPane extends StatefulWidget {
  const _PdfxPane({required this.path, required this.onError});

  final String path;
  final void Function(String message) onError;

  @override
  State<_PdfxPane> createState() => _PdfxPaneState();
}

class _PdfxPaneState extends State<_PdfxPane> {
  late final PdfControllerPinch _controller = PdfControllerPinch(document: PdfDocument.openFile(widget.path));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _jump() async {
    final total = _controller.pagesCount ?? 1;
    final field = TextEditingController();
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1 to $total'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(field.text)), child: const Text('Go')),
        ],
      ),
    );
    field.dispose();
    if (page != null) {
      await _controller.animateToPage(pageNumber: page.clamp(1, total), duration: const Duration(milliseconds: 250));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: PdfViewPinch(
            controller: _controller,
            onDocumentError: (e) => widget.onError(
                'This PDF could not be drawn. It may be damaged, or use a feature this phone cannot display.'),
            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
              pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __) => const ErrorState(message: 'This PDF could not be drawn.'),
            ),
          ),
        ),
        Material(
          color: scheme.surfaceContainer,
          child: SizedBox(
            height: 56,
            child: ValueListenableBuilder<int>(
              valueListenable: _controller.pageListenable,
              builder: (context, page, _) {
                final total = _controller.pagesCount;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed: page > 1
                          ? () => _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    TextButton(
                      onPressed: total == null ? null : _jump,
                      child: Text(total == null ? 'Page $page' : 'Page $page of $total'),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      onPressed: total != null && page < total
                          ? () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
