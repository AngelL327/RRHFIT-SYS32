// lib/empleados/views/primer_reporte.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

  void increment() {
    if (counter >= 100) return;
    counter = counter + 10;
  }

  void decrement() {
    if (counter <= 0) return;
    counter = counter - 10;
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

      final departamento = 'Departamento de RRHH';
      final generadoPor = Global().userName.toString();
      // final fechaGenerado = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final criterio = 'Índice de Asistencia > $counter';

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceReportPreview(
            logoBytes: logo,
            departamento: departamento,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow,
      width: 400.0,
      height: 200.0,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text("Indice a Evaluar"),
                SizedBox(width: 15.0),
                Container(
                  width: 30.0,
                  height: 30,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        increment();
                      });
                    },
                    icon: Icon(Icons.add),
                    color: Colors.white,
                    style: ButtonStyle(
                      iconSize: WidgetStateProperty.all(15),
                      backgroundColor: MaterialStateProperty.all(
                        Color.fromARGB(255, 24, 210, 27),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.0),
                Text("$counter"),
                SizedBox(width: 12.0),
                Container(
                  width: 30.0,
                  height: 30,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        decrement();
                      });
                    },
                    icon: Icon(Icons.remove),
                    color: Colors.white,
                    style: ButtonStyle(
                      iconSize: WidgetStateProperty.all(15),
                      backgroundColor: MaterialStateProperty.all(
                        Color.fromARGB(255, 24, 210, 27),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.0),
            DateRangePicker(
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              onDateRangeSelected: _onDateRangeSelected,
            ),
            const SizedBox(height: 8),
            CustomButton(
              icono: const Icon(Icons.picture_as_pdf_rounded),
              btnTitle: "Generar Reporte de Asistencia Perfecta",
              bgColor: Colors.blueAccent,
              fgColor: Colors.white,
              onPressed: _isLoading ? null : _generarReporte,
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
