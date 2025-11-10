import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

List<pw.Widget> buildRankingChart({
  required List<Map<String, dynamic>> data,
  required double maxBarWidth,
}) {
  final chartWidgets = <pw.Widget>[];

  chartWidgets.add(
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        '**Total empleados destacados:** ${data.length} de X (Y%)',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    ),
  );

  // Barras
  for (final row in data) {
    chartWidgets.add(_buildChartBar(row, maxBarWidth));
  }

  // Eje inferior (ticks 0..100)
  chartWidgets.add(pw.SizedBox(height: 10));
  chartWidgets.add(_buildAxisTicks(maxBarWidth));

  return chartWidgets;
}

pw.Widget _buildChartBar(Map<String, dynamic> row, double maxBarWidth) {
  final pct = (row['porcentaje'] is num)
      ? (row['porcentaje'] as num).toDouble()
      : 0.0;
  // Se usa maxBarWidth aquí porque es el ancho máximo disponible para el área de la barra (excluyendo márgenes y etiquetas)
  const double labelWidth = 18.0;
  const double labelSpacing = 8.0;

  final barAreaWidth = (maxBarWidth - labelWidth - labelSpacing).clamp(
    0.0,
    maxBarWidth,
  );
  final barWidth = (pct.clamp(0.0, 100.0) / 100.0) * barAreaWidth;

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      children: [
        // Label opcional a la izquierda
        pw.Container(width: labelWidth, child: pw.Text('')),
        pw.SizedBox(width: labelSpacing),
        pw.Stack(
          children: [
            // Track de fondo
            pw.Container(
              width: maxBarWidth,
              height: 18,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(6),
              ),
            ),
            // Barra de progreso
            pw.Positioned(
              left: 0,
              child: pw.Container(
                width: barWidth,
                height: 18,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue400,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
              ),
            ),
            // Overlay de texto
            pw.Positioned.fill(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 30),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      row['nombre'] ?? '-',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                    ),
                    pw.Text(
                      '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
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
  );
}

pw.Widget _buildAxisTicks(double maxBarWidth) {
  // Ajustar el ancho para que coincida con el área donde se dibujan las barras
  const double labelWidth = 18.0;
  const double labelSpacing = 8.0;
  final barAreaWidth = (maxBarWidth - labelWidth - labelSpacing).clamp(
    0.0,
    maxBarWidth,
  );

  return pw.Row(
    children: [
      // Espacio para la etiqueta opcional
      pw.SizedBox(width: labelWidth + labelSpacing),
      // Etiquetas horizontales
      pw.Container(
        // color: PdfColors.green100,
        height: 15.0,
        decoration: pw.BoxDecoration(
          color: PdfColors.green100,
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.SizedBox(
          width: barAreaWidth,
          child: pw.Row(
            children: List.generate(6, (i) {
              final label = '${i * 20}';
              return pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.black),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ],
  );
}
