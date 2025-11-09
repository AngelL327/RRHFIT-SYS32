// lib/empleados/reports/report_asistencia_perfecta_pdf.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart'; // ajusta si tu footer está en otra ruta

/// items: lista de mapas con keys:
/// 'rankingLabel','nombre','codigo','puesto','fechaContratacion','diasAsistidos','porcentaje' (double)
Future<Uint8List> generateAsistenciaPerfectaPdf({
  Uint8List? logoBytes,
  required String departamento,
  required String generadoPor,
  required String fechaGenerado,
  required String criterioExcepcion,
  List<Map<String, dynamic>>? items,
  pw.Font? customFont,
}) async {
  final pdf = pw.Document();

  final pageFormat = PdfPageFormat.a4.landscape;
  final data =
      items ??
      List.generate(
        5,
        (i) => {
          'rankingLabel': '${i + 1}°',
          'nombre': 'Empleado ${i + 1}',
          'codigo': 'A00${i + 1}',
          'puesto': 'Gerente de IT',
          'fechaContratacion': '26 / 07 / 2010',
          'diasAsistidos': '${22 - i} / 22',
          'porcentaje': (99 - i).toDouble(),
        },
      );

  // try load watermark/logo if not provided
  Uint8List? watermarkBytes = logoBytes;
  if (watermarkBytes == null) {
    try {
      final bytes = await rootBundle.load('assets/images/fittlay.png');
      watermarkBytes = bytes.buffer.asUint8List();
    } catch (_) {
      watermarkBytes = null;
    }
  }

  final baseFont = customFont;

  // margins used below must match margins in MultiPage
  const horizontalMargin = 24.0;
  const verticalMargin = 16.0;
  // left column width (cards)
  const leftColWidth = 280.0;
  const gapBetweenColumns = 12.0;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      // header
      header: (pw.Context ctx) {
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
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey800,
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
                            width: 60,
                            height: 60,
                          )
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
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Reporte de Asistencia Destacada',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 15),
            // pw.Container(
            //   padding: const pw.EdgeInsets.all(6),
            //   child: pw.Row(
            //     children: [
            //       pw.Expanded(
            //         flex: 3,
            //         child: pw.Column(
            //           crossAxisAlignment: pw.CrossAxisAlignment.start,
            //           children: [
            //             pw.Text(
            //               'Generado por:',
            //               style: pw.TextStyle(
            //                 fontWeight: pw.FontWeight.bold,
            //                 fontSize: 9,
            //               ),
            //             ),
            //             pw.Text(generadoPor, style: pw.TextStyle(fontSize: 9)),
            //           ],
            //         ),
            //       ),
            //       pw.Expanded(
            //         flex: 2,
            //         child: pw.Column(
            //           crossAxisAlignment: pw.CrossAxisAlignment.start,
            //           children: [
            //             pw.Text(
            //               'Fecha:',
            //               style: pw.TextStyle(
            //                 fontWeight: pw.FontWeight.bold,
            //                 fontSize: 9,
            //               ),
            //             ),
            //             pw.Text(
            //               fechaGenerado,
            //               style: pw.TextStyle(fontSize: 9),
            //             ),
            //           ],
            //         ),
            //       ),
            //       pw.Expanded(
            //         flex: 4,
            //         child: pw.Column(
            //           crossAxisAlignment: pw.CrossAxisAlignment.start,
            //           children: [
            //             pw.Text(
            //               'Criterio de Excepción:',
            //               style: pw.TextStyle(
            //                 fontWeight: pw.FontWeight.bold,
            //                 fontSize: 9,
            //               ),
            //             ),
            //             pw.Text(
            //               criterioExcepcion,
            //               style: pw.TextStyle(fontSize: 9),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // pw.SizedBox(height: 3),
          ],
        );
      },
      footer: (pw.Context ctx) =>
          reportFooter(ctx, hPadding: 10, vPadding: 6, font: baseFont),
      build: (pw.Context ctx) {
        // compute available content width (A4 landscape width minus horizontal margins)
        final contentWidth = pageFormat.width - (horizontalMargin * 2);
        final maxBarWidth = contentWidth - leftColWidth - gapBetweenColumns;

        const double labelWidth = 18.0;
        const double labelSpacing = 8.0;

        final barAreaWidth = (maxBarWidth - labelWidth - labelSpacing).clamp(
          0.0,
          maxBarWidth,
        );

        // build left column: stacked cards with the requested structure
        final leftWidgets = data.map((row) {
          final pct = (row['porcentaje'] is num)
              ? (row['porcentaje'] as num).toDouble()
              : 0.0;
          final name = row['nombre'] ?? '-';
          final initials = (name is String && name.trim().isNotEmpty)
              ? name
                    .trim()
                    .split(RegExp(r'\s+'))
                    .map((p) => p.isNotEmpty ? p[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase()
              : '?';
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Ranking number column
                pw.Container(
                  // color: PdfColor(0.25, 0.25, 0.25),
                  width: 30,
                  height: 80,
                  child: pw.Center(
                    child: pw.Text(
                      row['rankingLabel'] ?? '',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                // Main card
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey600,
                        width: 0.6,
                      ),
                      borderRadius: pw.BorderRadius.circular(6),
                      color: PdfColors.white,
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Row 1: avatar + name
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // avatar circle
                            pw.Container(
                              width: 20,
                              height: 20,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: PdfColors.grey300,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  initials,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Text(
                                name,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        // Row 2: labels column | values column | porcentaje box
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // left column: labels
                            pw.Container(
                              width: 60,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Codigo',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    'Puesto',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    'Contratacion',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    'Dias Asistidos',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 2),
                            // middle column: values
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    row['codigo'] ?? '-',
                                    style: pw.TextStyle(fontSize: 8),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    row['puesto'] ?? '-',
                                    style: pw.TextStyle(fontSize: 8),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    row['fechaContratacion'] ?? '-',
                                    style: pw.TextStyle(fontSize: 8),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    row['diasAsistidos'] ?? '-',
                                    style: pw.TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                            // right column: porcentaje box
                            pw.Container(
                              width: 56,
                              padding: const pw.EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                borderRadius: pw.BorderRadius.circular(6),
                                color: PdfColors.green50,
                              ),
                              child: pw.Row(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    '%',
                                    style: pw.TextStyle(
                                      color: PdfColors.green800,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1),
                                    style: pw.TextStyle(
                                      color: PdfColors.green800,
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();

        // Right column: chart with coherent bars
        final rightWidgets = <pw.Widget>[];

        rightWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              '**Total empleados destacados:** ${data.length} de X (Y%)',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        );

        // bars
        for (final row in data) {
          final pct = (row['porcentaje'] is num)
              ? (row['porcentaje'] as num).toDouble()
              : 0.0;
          final barWidth = (pct.clamp(0.0, 100.0) / 100.0) * barAreaWidth;

          rightWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Row(
                children: [
                  // optional label at left (A, B, ...)
                  pw.Container(
                    width: 18,
                    child: pw.Text(''),
                    // color: PdfColor(0.1, 0.1, 0.1),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Stack(
                    children: [
                      // background track
                      pw.Container(
                        width: maxBarWidth,
                        height: 18,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                      ),
                      // foreground bar with computed width
                      pw.Positioned(
                        left: 0,
                        child: pw.Container(
                          width: barWidth - 40,
                          height: 18,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue400, //TODO
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // text overlay (nombre at left, pct at right)
                      pw.Positioned.fill(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 30,
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                row['nombre'] ?? '-',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 9,
                                ),
                              ),

                              pw.Text(
                                '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
                                style: pw.TextStyle(
                                  color: PdfColors.green,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // bottom axis (ticks 0..100)
        final tickRow = pw.Row(
          children: List.generate(6, (i) {
            final label = '${i * 20}';
            return pw.Expanded(
              child: pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  label,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            );
          }),
        );

        rightWidgets.add(pw.SizedBox(height: 10));
        rightWidgets.add(tickRow);

        // Combine left and right into main row
        final mainRow = pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // left column fixed width
            pw.Container(
              width: leftColWidth,
              child: pw.Column(children: leftWidgets),
            ),
            pw.SizedBox(width: gapBetweenColumns),
            // right column uses remaining width
            pw.Expanded(child: pw.Column(children: rightWidgets)),
          ],
        );

        final content = <pw.Widget>[];
        // If watermark exists, draw beneath content
        if (watermarkBytes != null) {
          content.add(
            pw.Stack(
              children: [
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.30,
                    child: pw.Image(
                      pw.MemoryImage(watermarkBytes),
                      width: 420,
                      height: 420,
                    ),
                  ),
                ),
                pw.Column(
                  children: [
                    mainRow,
                    pw.SizedBox(height: 12),
                    // pw.Text(
                    //   'Generado por: $generadoPor',
                    //   style: pw.TextStyle(
                    //     fontSize: 9,
                    //     color: PdfColors.grey600,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          );
        } else {
          content.add(mainRow);
          content.add(pw.SizedBox(height: 12));
          content.add(
            pw.Text(
              'Generado por: $generadoPor',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        }

        return content;
      },
    ),
  );

  return pdf.save();
}
