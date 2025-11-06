// lib/empleados/reports/report_preview_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:rrhfit_sys32/empleados/widgets/report_generator.dart';

class AttendanceReportPreview extends StatelessWidget {
  final Uint8List? logoBytes;
  final String departamento;
  final String generadoPor;
  final String fechaGenerado;
  final String criterioExcepcion;
  final List<Map<String, dynamic>>? rows;

  const AttendanceReportPreview({
    super.key,
    this.logoBytes,
    required this.departamento,
    required this.generadoPor,
    required this.fechaGenerado,
    required this.criterioExcepcion,
    this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte Asistencia Perfecta')),
      body: PdfPreview(
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 1000,
        build: (format) async {
          return await generateAttendancePdf(
            logoBytes: logoBytes,
            departamento: departamento,
            generadoPor: generadoPor,
            fechaGenerado: fechaGenerado,
            criterioExcepcion: criterioExcepcion,
            rows: rows,
          );
        },
      ),
    );
  }
}
