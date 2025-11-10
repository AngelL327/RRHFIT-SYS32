// lib/empleados/reports/_employee_card.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

pw.Widget buildEmployeeCard({
  required Map<String, dynamic> row,
  required double leftColWidth,
}) {
  final name = row['nombre'] ?? '-';
  final pct = (row['porcentaje'] is num)
      ? (row['porcentaje'] as num).toDouble()
      : 0.0;

  // Lógica para iniciales - extraída para simplificar la función principal
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
          width: 30,
          height: 80,
          child: pw.Center(
            child: pw.Text(
              row['rankingLabel'] ?? '',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        // Main card
        pw.Expanded(child: _buildCardContent(row, initials, pct)),
      ],
    ),
  );
}

pw.Widget _buildCardContent(
  Map<String, dynamic> row,
  String initials,
  double pct,
) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
      borderRadius: pw.BorderRadius.circular(6),
      color: PdfColors.white,
    ),
    padding: const pw.EdgeInsets.all(8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Row 1: avatar + name
        _buildNameRow(initials, row['nombre']),
        pw.SizedBox(height: 4),
        // Row 2: info columns + percentage box
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildInfoLabels(),
            pw.SizedBox(width: 2),
            _buildInfoValues(row),
            _buildPercentageBox(pct),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildNameRow(String initials, String? name) {
  return pw.Row(
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
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Expanded(
        child: pw.Text(
          name ?? '-',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        ),
      ),
    ],
  );
}

pw.Widget _buildInfoLabels() {
  const labelStyle = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
  return pw.Container(
    width: 60,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Codigo', style: labelStyle),
        pw.SizedBox(height: 1),
        pw.Text('Puesto', style: labelStyle),
        pw.SizedBox(height: 1),
        pw.Text('Contratacion', style: labelStyle),
        pw.SizedBox(height: 1),
        pw.Text('Dias Asistidos', style: labelStyle),
      ],
    ),
  );
}

pw.Widget _buildInfoValues(Map<String, dynamic> row) {
  const valueStyle = pw.TextStyle(fontSize: 8);
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(row['codigo'] ?? '-', style: valueStyle),
        pw.SizedBox(height: 1),
        pw.Text(row['puesto'] ?? '-', style: valueStyle),
        pw.SizedBox(height: 1),
        pw.Text(row['fechaContratacion'] ?? '-', style: valueStyle),
        pw.SizedBox(height: 1),
        pw.Text(row['diasAsistidos'] ?? '-', style: valueStyle),
      ],
    ),
  );
}

pw.Widget _buildPercentageBox(double pct) {
  return pw.Container(
    width: 56,
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(6),
      color: PdfColors.green50,
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          '%',
          style: pw.TextStyle(color: PdfColors.green800, fontSize: 8),
        ),
        pw.SizedBox(width: 2),
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
  );
}
