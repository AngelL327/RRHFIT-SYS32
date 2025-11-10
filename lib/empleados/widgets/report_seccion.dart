import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/reports/primer_reporte.dart';
import 'package:rrhfit_sys32/empleados/reports/segundo_reporte.dart';

class ReportSeccion extends StatelessWidget {
  const ReportSeccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [PrimerReporte(), SegundoReporte()],
    );
  }
}
