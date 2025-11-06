import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart';

Future<Uint8List> generateAttendancePdf({
  Uint8List? logoBytes,
  required String departamento,
  required String generadoPor,
  required String fechaGenerado,
  required String criterioExcepcion,
  List<Map<String, dynamic>>? rows,
  pw.Font? customFont, // opcional
}) async {
  final pdf = pw.Document();

  final data =
      rows ??
      List.generate(
        5,
        (i) => {
          'ranking': (i + 1).toString(),
          'codigo': 'A001',
          'empleado': 'Empleado ${i + 1}',
          'puesto': 'Gerente IT',
          'fecha_contratacion': '26 / 07 / 2010',
          'periodo': '20 - 25 Oct/2025',
          'indice': '${99.5 - i * 0.5}%',
          'dias': '${22 - i} / 22',
        },
      );

  final tableHeaders = [
    'Ranking',
    'Código',
    'Empleado',
    'Puesto',
    'Fecha de Contratación',
    'Periodo de Evaluación',
    'Indice de Asistencia',
    'Días Asistidos / Total',
  ];

  final tableData = data.map((r) {
    return [
      r['ranking'] ?? '-',
      r['codigo'] ?? '-',
      r['empleado'] ?? '-',
      r['puesto'] ?? '-',
      r['fecha_contratacion'] ?? '-',
      r['periodo'] ?? '-',
      r['indice'] ?? '-',
      r['dias'] ?? '-',
    ];
  }).toList();

  final baseFont = customFont;

  Uint8List? watermarkBytes = logoBytes;
  if (watermarkBytes == null) {
    try {
      final bytes = await rootBundle.load('assets/images/fittlay.png');
      watermarkBytes = bytes.buffer.asUint8List();
    } catch (_) {
      watermarkBytes = null;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      // Header
      header: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // departamento left
                pw.Expanded(
                  flex: 3,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      departamento,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ),
                ),
                // logo center
                pw.Expanded(
                  flex: 4,
                  child: pw.Center(
                    child: logoBytes != null
                        ? pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 70,
                            height: 70,
                          )
                        : pw.Text(
                            'Fittlay',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // fecha right
                pw.Expanded(
                  flex: 3,
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Fecha: $fechaGenerado',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            // Title
            pw.Center(
              child: pw.Text(
                'Reporte de Asistencia Perfecta',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Generado por:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.0,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Fecha:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.0,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Criterio de Excepción: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.0,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        generadoPor,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 8.0,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        fechaGenerado,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 8.0,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        criterioExcepcion,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 8.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        );
      },
      // Footer using your helper
      footer: (pw.Context ctx) =>
          reportFooter(ctx, hPadding: 10, vPadding: 6, font: baseFont),
      // Build: contenido con watermark opcional
      build: (pw.Context ctx) {
        // Contenido principal (tabla + texto)
        final content = <pw.Widget>[
          pw.Table.fromTextArray(
            headers: tableHeaders,
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.normal,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue300),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellDecoration: (rowIndex, cellData, colIndex) {
              return const pw.BoxDecoration(color: PdfColors.white);
            },
            cellAlignment: pw.Alignment.centerLeft,

            columnWidths: {
              0: const pw.FlexColumnWidth(1.1),
              1: const pw.FlexColumnWidth(1.1),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(2.0),
              6: const pw.FlexColumnWidth(1.5),
              7: const pw.FlexColumnWidth(1.5),
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            border: pw.TableBorder.all(color: PdfColors.black, width: .2),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '**Total empleados destacados:** ${data.length} de X (Y%)',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
        ];

        // Si hay watermark, lo centramos y escalamos para cubrir el área central
        if (watermarkBytes != null) {
          return [
            pw.Stack(
              children: [
                // Watermark centrado y escalado
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.40, // Ajusta según necesites
                    child: pw.SizedBox(
                      width: 400, // Ancho grande para cubrir el centro
                      height:
                          500, // Alto grande (ajusta según tu imagen y página)
                      child: pw.Image(
                        pw.MemoryImage(watermarkBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Contenido principal encima
                pw.Column(children: content),
              ],
            ),
          ];
        }

        // Sin watermark
        return content;
      },
    ),
  );

  return pdf.save();
}
