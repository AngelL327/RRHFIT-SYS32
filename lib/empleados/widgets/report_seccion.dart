import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:rrhfit_sys32/empleados/views/report_preview_page.dart';
import 'package:rrhfit_sys32/empleados/widgets/custom_button.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'package:intl/intl.dart';
import 'package:rrhfit_sys32/empleados/widgets/report_asistencia_perfecta.dart';

class ReportSeccion extends StatelessWidget {
  const ReportSeccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          color: Colors.white30,
          width: 200.0,
          height: 50.0,
          alignment: Alignment.center,
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

        Container(
          color: Colors.white30,
          width: 300.0,
          height: 50.0,
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsetsGeometry.only(
              right: 10.0,
              top: 5.0,
              bottom: 5.0,
            ),
            child: CustomButton(
              icono: Icon(Icons.picture_as_pdf_rounded),
              btnTitle: "Generar Reporte Asistencia Perfecta",
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

                  final departamento = 'Departamento de RRHH';
                  final generadoPor = 'Jeffry Espinal Valle';
                  final fechaGenerado = DateFormat(
                    'dd/MM/yyyy',
                  ).format(DateTime.now());
                  final criterio = 'Índice de Asistencia > 95%';

                  // items: usa tus datos reales aquí. Ejemplo:
                  final items = [
                    {
                      'rankingLabel': '1°',
                      'nombre': 'Jeffry Valle',
                      'codigo': 'A001',
                      'puesto': 'Gerente IT',
                      'fechaContratacion': '26 / 07 / 2010',
                      'diasAsistidos': '22 / 22',
                      'porcentaje': 99.0,
                    },
                    {
                      'rankingLabel': '2°',
                      'nombre': 'Merari',
                      'codigo': 'A002',
                      'puesto': 'Gerente IT',
                      'fechaContratacion': '25 / 07 / 2010',
                      'diasAsistidos': '21 / 22',
                      'porcentaje': 97.0,
                    },
                    // 3..5...
                  ];

                  // Abrir preview en horizontal: inicializa PdfPreview con page format landscape
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Asistencia Perfecta'),
                        ),
                        body: PdfPreview(
                          // fuerza el page format inicial a landscape A4
                          initialPageFormat: PdfPageFormat.a4.landscape,
                          maxPageWidth: 1400,
                          allowPrinting: true,
                          allowSharing: true,
                          build: (format) async {
                            return await generateAsistenciaPerfectaPdf(
                              logoBytes: logo,
                              departamento: departamento,
                              generadoPor: generadoPor,
                              fechaGenerado: fechaGenerado,
                              criterioExcepcion: criterio,
                              items: items,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                } catch (e, st) {
                  debugPrint(
                    'Error generando preview asistencia perfecta: $e\n$st',
                  );
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
