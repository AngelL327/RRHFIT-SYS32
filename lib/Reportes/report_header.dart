import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/utilities/obtener_mes_string.dart';

/// Reusable PDF header builder for reports.
///
/// Usage:
/// final header = reportHeaderBuilder(
///   logo: logoImage,
///   dateString: dateString,
///   hPadding: 40,
///   vPadding: 20,
/// );
///
/// Then pass to `MultiPage.header: (_) => header` or `header: (ctx) => header`.

pw.Widget reportHeader({
  required String title,
	required pw.ImageProvider logo,
	required String dateString,
	double hPadding = 40,
	double vPadding = 20,
  pw.Font? font,
}) {
	return pw.Container(
		padding: pw.EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding / 2),
		child: pw.Row(
			crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
			children: [
        pw.Expanded(
					child: pw.Column(
						crossAxisAlignment: pw.CrossAxisAlignment.start,
						mainAxisSize: pw.MainAxisSize.min,
						children: [
                pw.Padding(padding: pw.EdgeInsets.only(top: 20, left: 20),
                child: pw.Text('Departamento de RRHH', 
                  style: font != null ? pw.TextStyle(font: font, fontSize: 8, color: pdf_lib.PdfColors.grey700) : pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                ),
              ],
					),
				),
        pw.Expanded(
					child: pw.Column(
						crossAxisAlignment: pw.CrossAxisAlignment.center,
						mainAxisSize: pw.MainAxisSize.min,
						children: [
              pw.Container(
                width: 20,
                height: 20,
                child: pw.Image(logo, fit: pw.BoxFit.contain, width: 100, height: 100),
              ),
							pw.Text(title, style: font != null ? pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold) : pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
							pw.Text("Al mes de ${getMonthString(DateTime.now().month)} - ${DateTime.now().year}", style: font != null ? pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold) : pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
					),
				),
        pw.Expanded(
					child: pw.Column(
						crossAxisAlignment: pw.CrossAxisAlignment.end,
						mainAxisSize: pw.MainAxisSize.min,
						children: [
                pw.Padding(padding: pw.EdgeInsets.only(top: 20, right: 20),
                child: pw.Text('Fecha: $dateString', style: font != null ? pw.TextStyle(font: font, fontSize: 8, color: pdf_lib.PdfColors.grey700) : pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
              ),
            ],
					),
				),
					],
		),
	);
}

