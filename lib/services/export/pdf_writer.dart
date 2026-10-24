import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'result_table.dart';

class PdfWriter {
  const PdfWriter._();

  static Future<List<int>> build(ResultTable table) async {
    final doc = pw.Document(title: table.title);
    final landscape = ColumnLayout.needsLandscape(table.columns);
    final format = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    // Times New Roman 12 pt, as in the Word file. The built-in Times face
    // covers Western European letters.
    final base = pw.TextStyle(font: pw.Font.times(), fontSize: 12);
    final bold = pw.TextStyle(font: pw.Font.timesBold(), fontSize: 12);

    pw.Widget cell(String text, pw.TextStyle style, {bool left = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: pw.Text(
            text,
            style: style,
            textAlign: left ? pw.TextAlign.left : pw.TextAlign.center,
          ),
        );

    final widths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < table.columns.length; i++)
        i: switch (table.columns[i].kind) {
          ExportColumnKind.serial => const pw.FixedColumnWidth(36),
          ExportColumnKind.regNo => const pw.FixedColumnWidth(118),
          // Wider headings get a wider column, so a word is never split.
          _ => pw.FlexColumnWidth(
              table.columns[i].title.length < 6 ? 6 : table.columns[i].title.length.toDouble()),
        },
    };

    doc.addPage(pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(56.7), // 2 cm
      theme: pw.ThemeData.withFont(
        base: pw.Font.times(),
        bold: pw.Font.timesBold(),
      ),
      build: (context) => [
        for (var i = 0; i < table.headerLines.length; i++)
          pw.Center(child: pw.Text(table.headerLines[i], style: i == 0 ? bold : base)),
        if (table.headerLines.isNotEmpty) pw.SizedBox(height: 8),
        pw.Center(child: pw.Text(table.title, style: bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: widths,
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            // The header row repeats on every page.
            pw.TableRow(
              repeat: true,
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD9D9D9)),
              children: [for (final c in table.columns) cell(c.title, bold)],
            ),
            for (final row in table.rows)
              pw.TableRow(children: [
                for (var c = 0; c < table.columns.length; c++)
                  cell(row[c].text, base,
                      left: table.columns[c].kind == ExportColumnKind.regNo),
              ]),
          ],
        ),
      ],
    ));

    return doc.save();
  }
}
