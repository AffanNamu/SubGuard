import 'package:excel/excel.dart';

import 'result_table.dart';

class XlsxWriter {
  const XlsxWriter._();

  static List<int> build(ResultTable table) {
    final book = Excel.createExcel();
    const sheetName = 'Results';
    final defaultName = book.getDefaultSheet();
    if (defaultName != null && defaultName != sheetName) {
      book.rename(defaultName, sheetName);
    }
    final sheet = book[sheetName];

    final black = ExcelColor.black;
    Border thin() => Border(borderStyle: BorderStyle.Thin, borderColorHex: black);
    CellStyle style({
      bool bold = false,
      HorizontalAlign align = HorizontalAlign.Center,
      bool grey = false,
      bool borders = true,
      NumFormat? format,
    }) =>
        CellStyle(
          fontFamily: 'Times New Roman',
          fontSize: 12,
          bold: bold,
          horizontalAlign: align,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: grey ? ExcelColor.fromHexString('#D9D9D9') : ExcelColor.none,
          leftBorder: borders ? thin() : null,
          rightBorder: borders ? thin() : null,
          topBorder: borders ? thin() : null,
          bottomBorder: borders ? thin() : null,
          numberFormat: format ?? NumFormat.standard_0,
        );

    var r = 0;
    for (var i = 0; i < table.headerLines.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r++));
      cell.value = TextCellValue(table.headerLines[i]);
      cell.cellStyle = style(bold: i == 0, align: HorizontalAlign.Left, borders: false);
    }
    final title = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r++));
    title.value = TextCellValue(table.title);
    title.cellStyle = style(bold: true, align: HorizontalAlign.Left, borders: false);
    r++; // blank row between the heading and the table

    for (var c = 0; c < table.columns.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      cell.value = TextCellValue(table.columns[c].title);
      cell.cellStyle = style(bold: true, grey: true);
    }
    r++;

    for (final row in table.rows) {
      for (var c = 0; c < table.columns.length; c++) {
        final src = row[c];
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        final isReg = table.columns[c].kind == ExportColumnKind.regNo;
        final align = isReg ? HorizontalAlign.Left : HorizontalAlign.Center;

        if (src.number != null) {
          final n = src.number!;
          final whole = n == n.roundToDouble();
          cell.value = (src.decimals == 0 || (src.decimals == null && whole))
              ? IntCellValue(n.round())
              : DoubleCellValue(n);
          cell.cellStyle = style(align: align, format: _format(src.decimals, n));
        } else {
          cell.value = src.text.isEmpty ? null : TextCellValue(src.text);
          cell.cellStyle = style(align: align);
        }
      }
      r++;
    }

    for (var c = 0; c < table.columns.length; c++) {
      final width = switch (table.columns[c].kind) {
        ExportColumnKind.serial => 7.0,
        ExportColumnKind.regNo => 24.0,
        _ => (table.columns[c].title.length + 4).clamp(10, 24).toDouble(),
      };
      sheet.setColumnWidth(c, width);
    }

    return book.encode()!;
  }

  /// Shows as many decimals as the part's step needs (0, 1 or 2); marks that
  /// are shown "as written" use the general format.
  static NumFormat? _format(int? decimals, double value) {
    switch (decimals) {
      case 0:
        return NumFormat.standard_1;
      case 1:
        return NumFormat.custom(formatCode: '0.0');
      case 2:
        return NumFormat.standard_2;
      default:
        return value == value.roundToDouble()
            ? NumFormat.standard_1
            : NumFormat.custom(formatCode: '0.0#');
    }
  }
}
