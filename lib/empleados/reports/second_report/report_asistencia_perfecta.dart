// lib/empleados/reports/report_asistencia_perfecta_pdf.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart'; // Asumimos que ReportFooter está aquí
import '_report_content.dart'; // NUEVO - Para el contenido principal
import '_report_header.dart'; // NUEVO - Para el encabezado
import '_report_data_model.dart'; // NUEVO - Para la inicialización de datos

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

  // 1. Lógica de Datos
  final data = items ?? generateDummyData();
  final pageFormat = PdfPageFormat.a4.landscape;

  // 2. Lógica de Assets (Watermark)
  final watermarkBytes = await _loadWatermark(logoBytes);

  final baseFont = customFont;
  const horizontalMargin = 24.0;
  const verticalMargin = 16.0;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      // Delegar el encabezado a una función externa
      header: (pw.Context ctx) => buildReportHeader(
        logoBytes: logoBytes,
        departamento: departamento,
        fechaGenerado: fechaGenerado,
      ),
      // Pie de página existente
      footer: (pw.Context ctx) =>
          reportFooter(ctx, hPadding: 10, vPadding: 6, font: baseFont),
      // Delegar la construcción del contenido a una función externa
      build: (pw.Context ctx) {
        final mainContent = buildReportContent(
          ctx,
          data: data as List<Map<String, dynamic>>,
          pageFormat: pageFormat,
          horizontalMargin: horizontalMargin,
        );

        // 3. Lógica de Watermark (Dibujo)
        if (watermarkBytes != null) {
          return [
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
                mainContent,
              ],
            ),
          ];
        }

        return [mainContent];
      },
    ),
  );

  return pdf.save();
}

// Función de ayuda para cargar la marca de agua
Future<Uint8List?> _loadWatermark(Uint8List? logoBytes) async {
  if (logoBytes != null) return logoBytes;
  try {
    final bytes = await rootBundle.load('assets/images/fittlay.png');
    return bytes.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
