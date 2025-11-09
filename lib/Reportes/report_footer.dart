import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:rrhfit_sys32/globals.dart';

/// Reusable PDF footer builder for reports.
///
/// Usage: pass `footer: (context) => reportFooter(context, hPadding: 40, vPadding: 20)`
pw.Widget reportFooter(
  pw.Context context, {
  double hPadding = 40,
  double vPadding = 20,
  pw.Font? font,
}) {
  String pageInfo;
  try {
    pageInfo = 'Página ${context.pageNumber} / ${context.pagesCount}';
  } catch (_) {
    pageInfo = '';
  }

  return pw.Container(
    padding: pw.EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generado por: ${Global().userName}',
          style: font != null
              ? pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: pdf_lib.PdfColors.grey700,
                )
              : pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey700),
        ),
        pw.Text(
          pageInfo,
          style: font != null
              ? pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: pdf_lib.PdfColors.grey700,
                )
              : pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey700),
        ),
      ],
    ),
  );
}
