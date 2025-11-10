import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart';
import 'package:rrhfit_sys32/core/theme.dart';

Future<Uint8List> generateAttendancePdf({
  Uint8List? logoBytes,
  // required String departamento,
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
    'Código',
    'Empleado',
    'Puesto',
    'Fecha de Contratación',
    'Periodo de Evaluación',
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
      r['periodo'] ?? '-',
      r['indice'] ?? '-',
      r['dias'] ?? '-',
    ];
  }).toList();

  final baseFont = customFont;
  final String fechaHoy =
      DateFormat('dd-MM-yy').format(DateTime.now()) as String;

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
                      // pw.SizedBox(height: 6),
                      // pw.Text(
                      //   'Fecha:',
                      //   style: pw.TextStyle(
                      //     fontWeight: pw.FontWeight.bold,
                      //     fontSize: 10.0,
                      //   ),
                      // ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Criterio de Excepción: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Período Evaluado:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12.0,
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
                          fontSize: 12.0,
                        ),
                      ),
                      // pw.SizedBox(height: 6),
                      // pw.Text(
                      //   fechaGenerado,
                      //   softWrap: true,
                      //   style: pw.TextStyle(
                      //     fontWeight: pw.FontWeight.normal,
                      //     fontSize: 10.0,
                      //   ),
                      // ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        criterioExcepcion,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 12.0,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        periodo,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 12.0,
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
          // Tabla principal de resumen
          // pw.Text(
          //   'Resumen de Asistencia por Empleado',
          //   style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          // ),
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
          pw.SizedBox(height: 20),

          // Detalles de registros por empleado
          ..._buildRegistrosDetails(data),

          pw.SizedBox(height: 8),
          pw.Text(
            '**Total empleados evaluados:** ${data.length}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
        ];

        if (watermarkBytes != null) {
          return [
            pw.Stack(
              children: [
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.40,
                    child: pw.SizedBox(
                      width: 400,
                      height: 500,
                      child: pw.Image(
                        pw.MemoryImage(watermarkBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                pw.Column(children: content),
              ],
            ),
          ];
        }

        return content;
      },
    ),
  );

  return pdf.save();
}

// Función auxiliar para construir los detalles de registros
List<pw.Widget> _buildRegistrosDetails(List<Map<String, dynamic>> data) {
  final widgets = <pw.Widget>[];

  for (final empleado in data) {
    final registros = (empleado['registros'] as List<dynamic>?) ?? [];

    if (registros.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue300, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'Detalles de Asistencia: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${empleado['empleado']} (${empleado['codigo']})',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Tabla de registros diarios
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  // Encabezado de la tabla de registros
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Fecha',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Entrada',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Salida',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Inicio Almuerzo',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Fin Almuerzo',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Horas Trabajadas',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Filas de registros
                  ...registros.map((registro) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _formatFecha(registro['fecha'] ?? ''),
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            registro['entrada']?.toString() ?? '-',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            registro['salida']?.toString() ?? '-',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            registro['almuerzo_inicio']?.toString() ?? '-',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            registro['almuerzo_fin']?.toString() ?? '-',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            registro['horas_trabajadas']?.toString() ?? '-',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Text(
                'Total de días asistidos: ${registros.length}',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ]);
    }
  }

  return widgets;
}

// Función auxiliar para formatear fechas
String _formatFecha(String fecha) {
  try {
    final parts = fecha.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return fecha;
  } catch (e) {
    return fecha;
  }
}
