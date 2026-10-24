import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/incoming/document_loaders.dart';

/// A worksheet or CSV as a scrollable grid: rows go up and down, columns go
/// sideways. Rows are built as they scroll into view, so thousands of rows
/// stay smooth.
class TableViewer extends StatelessWidget {
  const TableViewer({super.key, required this.sheet});

  final SheetData sheet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      return Center(child: Text('This sheet is empty.', style: text.bodyLarge));
    }
    final columns = rows.first.length;

    // A width for each column from its longest text near the top.
    final widths = List<double>.filled(columns, 72);
    for (final row in rows.take(200)) {
      for (var c = 0; c < columns && c < row.length; c++) {
        widths[c] = math.max(widths[c], math.min(260, row[c].length * 8.5 + 28));
      }
    }
    const numberWidth = 52.0;
    final total = numberWidth + widths.fold<double>(0, (a, b) => a + b);

    return Column(
      children: [
        if (sheet.truncated)
          Container(
            width: double.infinity,
            color: context.colors.warningContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Showing the first ${rows.length} of ${sheet.totalRows} rows'
              '${sheet.totalColumns > columns ? ' and $columns of ${sheet.totalColumns} columns' : ''}. '
              'Importing reads the whole sheet.',
              style: text.bodySmall?.copyWith(color: context.colors.warning),
            ),
          ),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(total, MediaQuery.sizeOf(context).width),
                child: ListView.builder(
                  itemCount: rows.length,
                  itemExtent: 44,
                  itemBuilder: (context, r) {
                    final header = r == 0;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: header ? scheme.surfaceContainerHighest : (r.isEven ? scheme.surfaceContainerLow : null),
                        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: numberWidth,
                            child: Center(
                              child: Text('${r + 1}', style: text.labelSmall?.copyWith(color: scheme.outline)),
                            ),
                          ),
                          for (var c = 0; c < columns; c++)
                            SizedBox(
                              width: widths[c],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    c < rows[r].length ? rows[r][c] : '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodyMedium?.copyWith(fontWeight: header ? FontWeight.w700 : null),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A Word document as text: headings, bold and italic, bullets and tables.
/// Pictures, columns and page layout are not drawn.
class TextViewer extends StatelessWidget {
  const TextViewer({super.key, required this.doc});

  final TextDoc doc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final blocks = doc.blocks;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Text view. Pictures and the page layout are not shown'
            '${doc.truncated ? ', and only the first ${blocks.length} parts are' : ''}.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: blocks.length,
            itemBuilder: (context, i) {
              final b = blocks[i];
              if (b is DocTable) return _DocTableView(table: b);
              final para = b as DocParagraph;
              final size = switch (para.heading) {
                1 => text.headlineSmall,
                2 => text.titleLarge,
                3 => text.titleMedium,
                0 => text.bodyLarge,
                _ => text.titleSmall,
              };
              return Padding(
                padding: EdgeInsets.only(bottom: 10, top: para.heading > 0 ? 8 : 0),
                child: Text.rich(
                  TextSpan(
                    style: size?.copyWith(fontWeight: para.heading > 0 ? FontWeight.w800 : null),
                    children: [
                      if (para.bullet) const TextSpan(text: '•  '),
                      for (final r in para.runs)
                        TextSpan(
                          text: r.text,
                          style: TextStyle(
                            fontWeight: r.bold ? FontWeight.w800 : null,
                            fontStyle: r.italic ? FontStyle.italic : null,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocTableView extends StatelessWidget {
  const _DocTableView({required this.table});

  final DocTable table;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columns = table.rows.fold<int>(0, (m, r) => math.max(m, r.length));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(120),
          border: TableBorder.all(color: scheme.outlineVariant),
          children: [
            for (var r = 0; r < table.rows.length; r++)
              TableRow(
                decoration: r == 0 ? BoxDecoration(color: scheme.surfaceContainerHighest) : null,
                children: [
                  for (var c = 0; c < columns; c++)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        c < table.rows[r].length ? table.rows[r][c] : '',
                        style: TextStyle(fontWeight: r == 0 ? FontWeight.w800 : null),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Said in place of a viewer: what is wrong or what can not be shown, and what
/// to do instead. Never a blank screen.
class NoticeView extends StatelessWidget {
  const NoticeView({super.key, required this.icon, required this.title, required this.message, this.color});

  final IconData icon;
  final String title;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
