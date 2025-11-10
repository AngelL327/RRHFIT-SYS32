// lib/empleados/reports/_report_header.dart
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

pw.Widget buildReportHeader({
  Uint8List? logoBytes,
  required String departamento,
  required String fechaGenerado,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                departamento,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Center(
              child: logoBytes != null
                  ? pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60)
                  : pw.Text(
                      'Fittlay',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Fecha: $fechaGenerado',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Center(
        child: pw.Text(
          'Reporte de Asistencia Perfecta',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 15),
    ],
  );
}
