import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/views/report_preview_page.dart';
import 'package:rrhfit_sys32/empleados/widgets/custom_button.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'package:intl/intl.dart';

class ReportSeccion extends StatelessWidget {
  const ReportSeccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          color: Colors.white30,
          width: 200.0,
          height: 50.0,
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsetsGeometry.only(
              right: 10.0,
              top: 5.0,
              bottom: 5.0,
            ),
            child: CustomButton(
              icono: Icon(Icons.picture_as_pdf_rounded),
              btnTitle: "Generar Reporte",
              bgColor: Colors.blueAccent,
              fgColor: Colors.white,
              onPressed: () async {
                try {
                  Uint8List? logo;
                  try {
                    final bytes = await rootBundle.load(
                      'assets/images/fittlay.png',
                    );
                    logo = bytes.buffer.asUint8List();
                  } catch (_) {
                    logo = null;
                  }

                  // datos de ejemplo o reales
                  final departamento = 'Departamento de RRHH';
                  final generadoPor = 'Jeffry Espinal Valle';
                  final fechaGenerado = DateFormat(
                    'dd/MM/yyyy',
                  ).format(DateTime.now());
                  final criterio = 'Índice de Asistencia > 95%';

                  final rows = <Map<String, dynamic>>[
                    {
                      'ranking': '1',
                      'codigo': 'A001',
                      'empleado': 'Jeffry',
                      'puesto': 'Gerente IT',
                      'fecha_contratacion': '26 / 07 / 2010',
                      'periodo': '20 - 25 Oct/2025',
                      'indice': '99.5%',
                      'dias': '22 / 22',
                    },
                    // ... más filas
                  ];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceReportPreview(
                        logoBytes: logo,
                        departamento: departamento,
                        generadoPor: generadoPor,
                        fechaGenerado: fechaGenerado,
                        criterioExcepcion: criterio,
                        rows: rows,
                      ),
                    ),
                  );
                } catch (e, st) {
                  debugPrint('Error generando preview: $e\n$st');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error creando reporte')),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
