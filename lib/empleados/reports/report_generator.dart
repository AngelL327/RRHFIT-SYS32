import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart';

Future<Uint8List> generateAttendancePdf({
  Uint8List? logoBytes,
  required String generadoPor,
  required String criterioExcepcion,
  required String periodo,
  List<Map<String, dynamic>>? rows,
  pw.Font? customFont,
}) async {
  final pdf = pw.Document();
  final data = rows ?? [];

  final tableHeaders = [
    'Ranking',
    'DNI',
    'Empleado',
    'Puesto',
    'Fecha de Contratación',
    // 'Periodo de Evaluación',
    'Índice de Asistencia',
    'Días Asistidos / Total',
  ];

  final tableData = data.map((r) {
    return [
      r['ranking'] ?? '-',
      r['codigo'] ?? '-',
      r['empleado'] ?? '-',
      r['puesto'] ?? '-',
      r['fecha_contratacion'] ?? '-',
      // r['periodo'] ?? '-',
      r['indice'] ?? '-',
      r['dias'] ?? '-',
    ];
  }).toList();

  final baseFont = customFont;
  final String fechaHoy = DateFormat('dd-MM-yy').format(DateTime.now());

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
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        buildBackground: (pw.Context ctx) {
          if (watermarkBytes == null) return pw.Container();
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.12,
                child: pw.Image(
                  pw.MemoryImage(watermarkBytes),
                  width: 400,
                  height: 400,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),

      header: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      "Departamento RRHH",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ),
                ),
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
                pw.Expanded(
                  flex: 3,
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Fecha: $fechaHoy',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Reporte de Asistencia Perfecta',
                style: pw.TextStyle(
                  fontSize: 12.0,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 15),
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
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Criterio de Excepción: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Período Evaluado:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
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
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        criterioExcepcion,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        periodo,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],
        );
      },

      footer: (pw.Context ctx) =>
          reportFooter(ctx, hPadding: 10, vPadding: 6, font: baseFont),

      build: (pw.Context ctx) {
        final content = <pw.Widget>[
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: tableHeaders,
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.normal,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF39B5DA),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(0.8),
              1: const pw.FlexColumnWidth(1.7),
              2: const pw.FlexColumnWidth(2.0),
              3: const pw.FlexColumnWidth(1.7),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.1),
              6: const pw.FlexColumnWidth(1.5),
              // 7: const pw.FlexColumnWidth(1.5),
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            border: pw.TableBorder.all(color: PdfColors.black, width: .2),
          ),

          pw.SizedBox(height: 12),
          pw.Text(
            '**Total empleados evaluados:** ${data.length}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
        ];

        return content;
      },
    ),
  );

  return pdf.save();
}
