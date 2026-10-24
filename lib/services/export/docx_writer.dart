import 'dart:convert';

import 'package:archive/archive.dart';

import 'result_table.dart';

/// A small .docx writer for the one layout the examiners already use:
/// the heading "(FWM) AGR 114", then one table. A4, Times New Roman 12 pt,
/// grey header row, borders on every cell.
class DocxWriter {
  const DocxWriter._();

  static const int _a4Width = 11906;
  static const int _a4Height = 16838;
  static const int _margin = 1440;

  static List<int> build(ResultTable table) {
    // Portrait unless the column headings cannot fit across the page.
    final landscape = ColumnLayout.needsLandscape(table.columns);
    final pageWidth = landscape ? _a4Height : _a4Width;
    final pageHeight = landscape ? _a4Width : _a4Height;
    final usable = pageWidth - 2 * _margin;

    final files = <String, String>{
      '[Content_Types].xml': _contentTypes,
      '_rels/.rels': _rootRels,
      'word/_rels/document.xml.rels': _documentRels,
      'word/styles.xml': _styles,
      'word/document.xml': _document(table, usable, pageWidth, pageHeight, landscape),
    };

    final archive = Archive();
    files.forEach((name, xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return ZipEncoder().encode(archive)!;
  }

  static String esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _document(ResultTable t, int usable, int pw, int ph, bool landscape) {
    final b = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>');

    for (var i = 0; i < t.headerLines.length; i++) {
      b.write(_paragraph(t.headerLines[i], bold: i == 0, center: true, after: 0));
    }
    if (t.headerLines.isNotEmpty) b.write(_paragraph('', after: 120));
    b.write(_paragraph(t.title, bold: true, center: true, after: 160));

    final widths = _columnWidths(t, usable);
    b.write('<w:tbl><w:tblPr>'
        '<w:tblW w:w="${widths.fold<int>(0, (a, c) => a + c)}" w:type="dxa"/>'
        '<w:jc w:val="center"/>'
        '<w:tblBorders>${_border('top')}${_border('left')}${_border('bottom')}${_border('right')}'
        '${_border('insideH')}${_border('insideV')}</w:tblBorders>'
        '<w:tblLayout w:type="fixed"/>'
        '<w:tblCellMar><w:left w:w="80" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tblCellMar>'
        '<w:tblLook w:val="04A0"/>'
        '</w:tblPr><w:tblGrid>');
    for (final w in widths) {
      b.write('<w:gridCol w:w="$w"/>');
    }
    b.write('</w:tblGrid>');

    // Header row: grey, bold, repeated on every page.
    b.write('<w:tr><w:trPr><w:cantSplit/><w:tblHeader/></w:trPr>');
    for (var c = 0; c < t.columns.length; c++) {
      b.write(_cell(t.columns[c].title, widths[c],
          bold: true, center: true, fill: 'D9D9D9'));
    }
    b.write('</w:tr>');

    for (final row in t.rows) {
      b.write('<w:tr><w:trPr><w:cantSplit/></w:trPr>');
      for (var c = 0; c < t.columns.length; c++) {
        final left = t.columns[c].kind == ExportColumnKind.regNo;
        b.write(_cell(row[c].text, widths[c], center: !left));
      }
      b.write('</w:tr>');
    }
    b.write('</w:tbl>');

    // A paragraph must follow a table at the end of the body.
    b.write(_paragraph('', after: 0));
    b.write('<w:sectPr><w:pgSz w:w="$pw" w:h="$ph"${landscape ? ' w:orient="landscape"' : ''}/>'
        '<w:pgMar w:top="$_margin" w:right="$_margin" w:bottom="$_margin" w:left="$_margin" '
        'w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>'
        '</w:body></w:document>');
    return b.toString();
  }

  /// Each column gets the width its heading needs; any space left over is
  /// shared between the mark columns.
  static List<int> _columnWidths(ResultTable t, int usable) {
    final mins = [for (final c in t.columns) ColumnLayout.minTwips(c)];
    final flexible = [
      for (var i = 0; i < t.columns.length; i++)
        if (t.columns[i].kind != ExportColumnKind.serial &&
            t.columns[i].kind != ExportColumnKind.regNo)
          i,
    ];
    final spare = usable - mins.fold<int>(0, (a, b) => a + b);
    if (spare > 0 && flexible.isNotEmpty) {
      final extra = (spare / flexible.length).floor();
      for (final i in flexible) {
        mins[i] += extra;
      }
    }
    return mins;
  }

  static String _border(String side) =>
      '<w:$side w:val="single" w:sz="4" w:space="0" w:color="000000"/>';

  static String _paragraph(String text,
      {bool bold = false, bool center = false, int after = 0}) {
    final run = text.isEmpty
        ? ''
        : '<w:r>${bold ? '<w:rPr><w:b/></w:rPr>' : ''}<w:t xml:space="preserve">${esc(text)}</w:t></w:r>';
    return '<w:p><w:pPr><w:spacing w:before="0" w:after="$after"/>'
        '${center ? '<w:jc w:val="center"/>' : ''}</w:pPr>$run</w:p>';
  }

  static String _cell(String text, int width,
      {bool bold = false, bool center = false, String? fill}) {
    final shading = fill == null ? '' : '<w:shd w:val="clear" w:color="auto" w:fill="$fill"/>';
    return '<w:tc><w:tcPr><w:tcW w:w="$width" w:type="dxa"/>$shading<w:vAlign w:val="center"/></w:tcPr>'
        '${_paragraph(text, bold: bold, center: center)}</w:tc>';
  }

  static const String _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '</Types>';

  static const String _rootRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  static const String _documentRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  /// Times New Roman, 12 pt (24 half-points), no extra paragraph spacing.
  static const String _styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:docDefaults>'
      '<w:rPrDefault><w:rPr>'
      '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="Times New Roman" w:cs="Times New Roman"/>'
      '<w:sz w:val="24"/><w:szCs w:val="24"/><w:lang w:val="en-GB"/>'
      '</w:rPr></w:rPrDefault>'
      '<w:pPrDefault><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr></w:pPrDefault>'
      '</w:docDefaults>'
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>'
      '</w:styles>';
}
