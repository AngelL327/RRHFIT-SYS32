import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';
import 'package:rrhfit_sys32/empleados/reports/second_report/report_asistencia_perfecta.dart';
import 'package:rrhfit_sys32/empleados/widgets/custom_button.dart';
import 'package:rrhfit_sys32/globals.dart';

class SegundoReporte extends StatefulWidget {
  const SegundoReporte({super.key});

  @override
  State<SegundoReporte> createState() => _SegundoReporteState();
}

class _SegundoReporteState extends State<SegundoReporte> {
  final EmpleadoController _emplController = EmpleadoController();

  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));

  final DateTime _endDate = DateTime.now();

  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      // height: 50.0,
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsetsGeometry.only(right: 10.0, top: 15.0, bottom: 5.0),
        child: CustomButton(
          icono: Icon(Icons.picture_as_pdf_rounded),
          btnTitle: "Ver",
          bgColor: Colors.blueAccent,
          fgColor: Colors.white,
          onPressed: () async {
            try {
              Uint8List? logo;
              try {
                final bytes = await rootBundle.load(
                  'assets/images/fittlay_imagotipo.png',
                );
                logo = bytes.buffer.asUint8List();
              } catch (_) {
                logo = null;
              }

              final Future<List<Map<String, dynamic>>> futureRows =
                  _emplController.computeWeeklyAttendanceRows(
                    customStartDate: _startDate,
                    customEndDate: _endDate,
                    includeWeekends: false,
                    ind: 0,
                  );
              final List<Map<String, dynamic>> rows = await futureRows;

              final List<Map<String, dynamic>> five = rows.take(5).toList();

              //       for (var item in await rows) {
              //         print("""
              //   'ranking ${item["ranking"]}
              //   'codigo ${item["codigo"]}
              //   'empleado ${item["empleado"]}
              //   'puesto ${item["puesto"]}
              //   'departamento ${item["departamento"]}
              //   'fecha_contratacion ${item["fecha_contratacion"]}
              //   'periodo ${item["periodo"]}
              //   'indice ${item["indice"]}
              //   'dias ${item["dias"]}
              //   'area ${item["area"]}
              //   'detalle_asistencias ${item["detalle_asistencias"]}
              //   'empleado_id ${item["empleado_id"]}
              // }""");
              //       }

              final departamento = 'Departamento de RRHH';
              final generadoPor = Global().userName.toString();
              final fechaGenerado = DateFormat(
                'dd/MM/yyyy',
              ).format(DateTime.now());
              final criterio = 'Índice de Asistencia > $counter %';

              // items: usar datos reales aqui
              final items = [
                {
                  'rankingLabel': '1°',
                  'nombre': 'Jeffry Valle',
                  'codigo': 'A001',
                  'puesto': 'Gerente IT',
                  'fechaContratacion': '26 / 07 / 2010',
                  'diasAsistidos': '22 / 22',
                  'porcentaje': 100.0,
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
                {
                  'rankingLabel': '3°',
                  'nombre': 'Pedri Gonzales',
                  'codigo': 'A003',
                  'puesto': 'Gerente IT',
                  'fechaContratacion': '26 / 07 / 2010',
                  'diasAsistidos': '20 / 22',
                  'porcentaje': 96.0,
                },
                {
                  'rankingLabel': '4°',
                  'nombre': 'Chilindrina Peréz',
                  'codigo': 'A004',
                  'puesto': 'Gerente IT',
                  'fechaContratacion': '25 / 07 / 2010',
                  'diasAsistidos': '21 / 22',
                  'porcentaje': 95.0,
                },
                {
                  'rankingLabel': '5°',
                  'nombre': 'Profesor Girafales',
                  'codigo': 'A005',
                  'puesto': 'Gerente IT',
                  'fechaContratacion': '26 / 07 / 2010',
                  'diasAsistidos': '19 / 22',
                  'porcentaje': 95.0,
                },
              ];

              // Abrir preview en horizontal: inicializa PdfPreview con page format landscape
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Asistencia Perfecta')),
                    body: PdfPreview(
                      // fuerza el page format inicial a landscape A4
                      initialPageFormat: PdfPageFormat.a4.landscape,
                      maxPageWidth: 1400,
                      allowPrinting: true,
                      allowSharing: false,
                      loadingWidget: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                        color: Colors.green,
                      ),
                      actionBarTheme: PdfActionBarTheme(
                        backgroundColor: Color(0xFF39B5DA),
                        iconColor: Colors.white,
                      ),
                      canChangeOrientation: false,
                      canChangePageFormat: false,

                      build: (format) async {
                        return await generateAsistenciaPerfectaPdf(
                          logoBytes: logo,
                          departamento: departamento,
                          generadoPor: generadoPor,
                          fechaGenerado: fechaGenerado,
                          criterioExcepcion: criterio,
                          items: await five,
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
    );
  }
}
