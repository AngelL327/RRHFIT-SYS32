import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';
import 'package:rrhfit_sys32/empleados/views/report_preview_page.dart';
import 'package:rrhfit_sys32/empleados/widgets/custom_button.dart';
import 'package:rrhfit_sys32/empleados/widgets/pick_a_date.dart';
import 'package:rrhfit_sys32/globals.dart';

class PrimerReporte extends StatefulWidget {
  const PrimerReporte({super.key});

  @override
  State<PrimerReporte> createState() => _PrimerReporteState();
}

class _PrimerReporteState extends State<PrimerReporte> {
  final EmpleadoController _empleadoController = EmpleadoController();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  int counter = 0;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _empleadoController.ready;
      _empleadoController.setDateRange(_startDate, _endDate);
    } catch (e) {
      debugPrint('Error inicializando controlador: $e');
    }
  }

  void _onDateRangeSelected(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _empleadoController.setDateRange(start, end);
  }

  Future<void> _generarReporte() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uint8List? logo = await _loadLogo();

      final rows = await _empleadoController.computeWeeklyAttendanceRows(
        customStartDate: _startDate,
        customEndDate: _endDate,
        soloAsistenciaPerfecta: true,
        ind: counter,
      );

      final generadoPor = Global().userName.toString();
      final criterio = 'Índice de Asistencia > $counter';

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceReportPreview(
            logoBytes: logo,
            generadoPor: generadoPor,
            criterioExcepcion: criterio,
            rows: rows,
            periodo: '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error generando preview: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error creando reporte')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load(
        'assets/images/fittlay_imagotipo.png',
      );
      return bytes.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Muestra el dialog para elegir rango de fechas e índice
  Future<void> _showReporteDialog() async {
    // valores temporales para el diálogo (no aplican hasta que el usuario presiona "Generar")
    DateTime tempStart = _startDate;
    DateTime tempEnd = _endDate;
    int tempCounter = counter;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar reporte'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 500,
                // Ajusta altura si es necesario
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reutilizamos tu DateRangePicker, pero con los valores temporales.
                      DateRangePicker(
                        initialStartDate: tempStart,
                        initialEndDate: tempEnd,
                        onDateRangeSelected: (s, e) {
                          setStateDialog(() {
                            tempStart = s;
                            tempEnd = e;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Índice a evaluar: $tempCounter'),
                      ),
                      // Slider para seleccionar índice 0..100
                      Slider(
                        value: tempCounter.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '$tempCounter',
                        onChanged: (v) {
                          setStateDialog(() {
                            tempCounter = v.round();
                          });
                        },
                      ),
                      // También mostramos botones +/- rápidos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Disminuir 1',
                            onPressed: () {
                              setStateDialog(() {
                                if (tempCounter > 0) tempCounter -= 1;
                              });
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$tempCounter',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Aumentar 1',
                            onPressed: () {
                              setStateDialog(() {
                                if (tempCounter < 100) tempCounter += 1;
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      // Aplicar los valores seleccionados al estado real y cerrar diálogo
                      setState(() {
                        _startDate = tempStart;
                        _endDate = tempEnd;
                        counter = tempCounter;
                      });
                      _empleadoController.setDateRange(_startDate, _endDate);
                      Navigator.of(context).pop();
                      // Ejecutar la generación del reporte con los parámetros seleccionados
                      await _generarReporte();
                    },
              child: const Text('Generar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.0,
      // height: 100.0,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // // Título
            // const Text(
            //   'Reporte — Asistencia Perfecta',
            //   style: TextStyle(fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            // // Resumen: muestra las opciones actualmente seleccionadas
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'Periodo: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
            //         ),
            //         const SizedBox(height: 6),
            //         Text('Índice seleccionado: $counter'),
            //       ],
            //     ),
            //   ],
            // ),
            const SizedBox(height: 12),
            // Botón principal: abre el diálogo para elegir parámetros
            CustomButton(
              icono: const Icon(Icons.picture_as_pdf_rounded),
              btnTitle: "Reporte Asistencia Perfecta",
              bgColor: Colors.blueAccent,
              fgColor: Colors.white,
              onPressed: _isLoading ? null : _showReporteDialog,
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _empleadoController.dispose();
    super.dispose();
  }
}
