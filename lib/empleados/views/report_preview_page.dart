// lib/empleados/reports/report_preview_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:rrhfit_sys32/empleados/reports/report_generator.dart';

class AttendanceReportPreview extends StatelessWidget {
  final Uint8List? logoBytes;
  // final String departamento;
  final String generadoPor;
  final String criterioExcepcion;
  final List<Map<String, dynamic>>? rows;
  final String periodo; // Nuevo parámetro

  AttendanceReportPreview({
    super.key,
    this.logoBytes,
    // required this.departamento,
    required this.generadoPor,
    required this.criterioExcepcion,
    this.rows,
    required this.periodo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Asistencia Perfecta')),
      body: PdfPreview(
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 1000,
        build: (format) async {
          return await generateAttendancePdf(
            logoBytes: logoBytes,
            // departamento: departamento,
            generadoPor: generadoPor,
            criterioExcepcion: criterioExcepcion,
            periodo: periodo,
            rows: rows,
          );
        },
      ),
    );
  }
}
