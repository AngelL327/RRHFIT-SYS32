// lib/empleados/reports/_report_content.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '_employee_card.dart';
import '_ranking_chart.dart';

const leftColWidth = 280.0;
const gapBetweenColumns = 12.0;

pw.Widget buildReportContent(
  pw.Context ctx, {
  required List<Map<String, dynamic>> data,
  required PdfPageFormat pageFormat,
  required double horizontalMargin,
}) {
  final contentWidth = pageFormat.width - (horizontalMargin * 2);
  final maxBarWidth = contentWidth - leftColWidth - gapBetweenColumns;

  // Columna Izquierda: Tarjetas de Empleados
  final leftWidgets = data
      .map((row) => buildEmployeeCard(row: row, leftColWidth: leftColWidth))
      .toList();

  // Columna Derecha: Gráfico de Barras
  final rightWidgets = buildRankingChart(data: data, maxBarWidth: maxBarWidth);

  // Combinar ambas columnas
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      // Columna izquierda de ancho fijo
      pw.Container(
        width: leftColWidth,
        child: pw.Column(children: leftWidgets),
      ),
      pw.SizedBox(width: gapBetweenColumns),
      // Columna derecha usando el ancho restante
      pw.Expanded(child: pw.Column(children: rightWidgets)),
    ],
  );
}
