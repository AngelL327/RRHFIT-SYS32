// lib/empleados/controllers/empleado_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/models/departamento_model.dart';
import 'package:rrhfit_sys32/empleados/models/area_model.dart';
import 'package:rrhfit_sys32/empleados/models/puesto_model.dart';
import 'package:rrhfit_sys32/empleados/services/firestore_service.dart';

class EmpleadoController with ChangeNotifier {
  final FirestoreService service;

  EmpleadoController({FirestoreService? service})
    : service = service ?? FirestoreService() {
    empleadosController = StreamController<List<Empleado>>.broadcast(
      onListen: () => empleadosController.add(List.from(_lastEmpleados)),
    );
    departamentosController = StreamController<List<Departamento>>.broadcast(
      onListen: () =>
          departamentosController.add(List.from(_lastDepartamentos)),
    );
    areasController = StreamController<List<Area>>.broadcast(
      onListen: () => areasController.add(List.from(lastAreas)),
    );
    puestosController = StreamController<List<Puesto>>.broadcast(
      onListen: () => puestosController.add(List.from(_lastPuestos)),
    );
    _init();
  }

  final Completer<void> _readyCompleter = Completer<void>();
  List<Map<String, dynamic>> _reportData = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<void> get ready => _readyCompleter.future;

  late final StreamController<List<Empleado>> empleadosController;
  late final StreamController<List<Departamento>> departamentosController;
  late final StreamController<List<Area>> areasController;
  late final StreamController<List<Puesto>> puestosController;

  StreamSubscription? empleadosSub;
  StreamSubscription? deptoSub;
  StreamSubscription? areaSub;
  StreamSubscription? puestoSub;

  List<Empleado> _lastEmpleados = [];
  List<Departamento> _lastDepartamentos = [];
  List<Area> lastAreas = [];
  List<Puesto> _lastPuestos = [];

  final Map<String, String> departamentoMapa = {};
  final Map<String, String> areaMapa = {};
  final Map<String, String> puestoMapa = {};

  List<Empleado> allEmployees = [];
  String searchTerm = '';
  String filterField = 'Nombre';

  Stream<List<Empleado>> get empleadosStream => empleadosController.stream;
  Stream<List<Departamento>> get departamentosStream =>
      departamentosController.stream;
  Stream<List<Area>> get areasStream => areasController.stream;
  Stream<List<Puesto>> get puestosStream => puestosController.stream;

  //---------------------------------------------------------------------------------------------

  // Método principal para generar datos del reporte
  Future<List<Map<String, dynamic>>> computeWeeklyAttendanceRows({
    bool includeWeekends = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool soloAsistenciaPerfecta = true,
    int ind = 0,
  }) async {
    await ready;

    final start = customStartDate ?? _startDate;
    final end = customEndDate ?? _endDate;

    try {
      _reportData = await service.getReporteAsistenciaData(
        startDate: start,
        endDate: end,
        ind: ind,
      );

      // Filtrar solo asistencia perfecta si se solicita
      final filteredData = soloAsistenciaPerfecta
          ? _reportData
                .where((emp) => emp['asistencia_perfecta'] == true)
                .toList()
          : _reportData;

      // Formatear datos para la tabla
      final rows = filteredData.asMap().entries.map((entry) {
        final index = entry.key;
        final empleado = entry.value;
        final asistencias =
            empleado['asistencias'] as List<Map<String, dynamic>>;

        return {
          'ranking': (index + 1).toString(),
          'codigo': empleado['codigo_empleado'],
          'empleado': empleado['nombre'],
          'puesto': empleado['puesto'],
          'departamento': empleado['departamento'],
          'fecha_contratacion': empleado['fecha_contratacion'],
          'periodo': '${_formatDate(start)} - ${_formatDate(end)}',
          'indice': empleado['indice_formateado'],
          'dias': '${empleado['dias_asistidos']} / ${empleado['total_dias']}',
          'area': empleado['area'],
          'detalle_asistencias': asistencias,
          'empleado_id': empleado['empleado_id'],
        };
      }).toList();

      debugPrint(
        'Reporte generado: ${rows.length} empleados con asistencia perfecta',
      );
      return rows;
    } catch (e, st) {
      debugPrint('Error generando reporte: $e\n$st');
      return [];
    }
  }

  // Método para obtener datos detallados de un empleado
  Future<Map<String, dynamic>?> getDetalleEmpleado(String empleadoId) async {
    await ready;
    return _reportData.firstWhere(
      (emp) => emp['empleado_id'] == empleadoId,
      orElse: () => {},
    );
  }

  // Métodos para configurar fechas
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  //---------------------------------------------------------------------------------------------

  Future<void> _init() async {
    try {
      await service.ensureAndSeedReferenceData();

      deptoSub = service.streamDepartamentos().listen((list) {
        _lastDepartamentos = List.from(list);
        departamentoMapa.clear();
        for (final d in list) {
          if (d.id != null && d.nombre != null) {
            departamentoMapa[d.id!] = d.nombre!;
          }
        }
        departamentosController.add(List.from(list));
        notifyListeners();
      });

      areaSub = service.streamAreas().listen((list) {
        lastAreas = List.from(list);
        areaMapa.clear();
        for (final a in list) {
          if (a.id != null && a.nombre != null) areaMapa[a.id!] = a.nombre!;
        }
        areasController.add(List.from(list));
        notifyListeners();
      });

      puestoSub = service.streamPuestos().listen((list) {
        _lastPuestos = List.from(list);
        puestoMapa.clear();
        for (final p in list) {
          if (p.id != null && p.nombre != null) puestoMapa[p.id!] = p.nombre!;
        }
        puestosController.add(List.from(list));
        notifyListeners();
      });

      empleadosSub = service.streamEmpleados().listen((list) {
        _lastEmpleados = List.from(list);
        allEmployees = list;
        _applyFilter();
      });

      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    } catch (e, s) {
      debugPrint('EmpleadoController _init error: $e\n$s');
      if (!_readyCompleter.isCompleted) _readyCompleter.completeError(e);
    }
  }

  void setSearchTerm(String term) {
    searchTerm = term.trim();
    _applyFilter();
  }

  void setFilterField(String field) {
    filterField = field;
    _applyFilter();
  }

  void _applyFilter() {
    if (searchTerm.isEmpty) {
      empleadosController.add(List.from(allEmployees));
      return;
    }
    final q = searchTerm.toLowerCase();
    final filtered = allEmployees.where((e) {
      switch (filterField) {
        case 'EmpleadoID':
          return (e.empleadoId ?? '').toLowerCase().contains(q);
        case 'Nombre':
          return (e.nombre ?? '').toLowerCase().contains(q);
        case 'Codigo':
          return (e.codigoEmpleado ?? '').toLowerCase().contains(q);
        case 'Correo':
          return (e.correo ?? '').toLowerCase().contains(q);
        case 'Telefono':
          return (e.telefono ?? '').toLowerCase().contains(q);
        case 'Estado':
          return (e.estado ?? '').toLowerCase().contains(q);
        case 'Departamento':
          return (getDepartamentoNombre(e.departamentoId) ?? '')
              .toLowerCase()
              .contains(q);
        case 'Puesto':
          return (getPuestoNombre(e.puestoId) ?? '').toLowerCase().contains(q);
        default:
          return (e.nombre ?? '').toLowerCase().contains(q);
      }
    }).toList();
    empleadosController.add(filtered);
  }

  String? getDepartamentoNombre(String? id) =>
      id == null ? '-' : departamentoMapa[id] ?? '-';
  String? getAreaNombre(String? id) => id == null ? '-' : areaMapa[id] ?? '-';
  String? getPuestoNombre(String? id) =>
      id == null ? '-' : puestoMapa[id] ?? '-';

  Future<void> createEmployee(Empleado e) async {
    await ready;
    await service.createEmployee(e);
  }

  Future<void> updateEmployee(Empleado e) async {
    await ready;
    await service.updateEmployee(e);
  }

  Future<void> deleteEmployee(String id) async {
    await ready;
    await service.deleteEmployee(id);
  }

  // REPORTE SEMANAL POR UID

  // Future<List<Map<String, dynamic>>> computeWeeklyAttendanceRows({
  //   bool includeWeekends = false,
  // }) async {
  //   await ready;

  //   final DateTime start = DateTime(2025, 10, 31);
  //   final DateTime end = DateTime(2025, 11, 9);

  //   // Calcular totalDays laborables
  //   int totalDays = 0;
  //   DateTime current = start;
  //   while (!current.isAfter(end)) {
  //     if (includeWeekends ||
  //         (current.weekday >= DateTime.monday &&
  //             current.weekday <= DateTime.friday)) {
  //       totalDays++;
  //     }
  //     current = current.add(const Duration(days: 1));
  //   }
  //   if (totalDays == 0) totalDays = 1;

  //   final List<Map<String, dynamic>> rows = [];
  //   debugPrint('DEBUG: Empleados cargados: ${allEmployees.length}');

  //   for (final e in allEmployees) {
  //     if (e.asistenciaDocId == null || e.asistenciaDocId!.isEmpty) {
  //       debugPrint(
  //         'DEBUG: Empleado sin asistenciaDocId, saltando: ${e.nombre}',
  //       );
  //       continue;
  //     }

  //     // Obtener registros usando el asistenciaDocId (nombre normalizado)
  //     final registros = await service.fetchRegistrosByAsistenciaDocId(
  //       e.asistenciaDocId!,
  //       start,
  //       end,
  //     );

  //     final int asistencias = registros.length;
  //     final double indice = totalDays > 0 ? (asistencias / totalDays) * 100 : 0;

  //     final String indiceStr = '${indice.toStringAsFixed(1)}%';
  //     final String periodoLabel = '${_formatDate(start)} - ${_formatDate(end)}';

  //     // Preparar datos detallados de registros para el PDF
  //     final registrosDetallados = registros.map((registro) {
  //       return {
  //         'fecha': registro['_docId'],
  //         'entrada': registro['entrada'] ?? '-',
  //         'salida': registro['salida'] ?? '-',
  //         'almuerzo_inicio': registro['almuerzoInicio'] ?? '-',
  //         'almuerzo_fin': registro['almuerzoFin'] ?? '-',
  //         'horas_trabajadas': registro['horasTrabajadas'] ?? '-',
  //       };
  //     }).toList();

  //     rows.add({
  //       'ranking': '',
  //       'codigo': e.codigoEmpleado ?? '-',
  //       'empleado': e.nombre ?? '-',
  //       'puesto': getPuestoNombre(e.puestoId) ?? '-',
  //       'fecha_contratacion': e.fechaContratacion == null
  //           ? '-'
  //           : '${e.fechaContratacion!.day.toString().padLeft(2, '0')} / ${e.fechaContratacion!.month.toString().padLeft(2, '0')} / ${e.fechaContratacion!.year}',
  //       'periodo': periodoLabel,
  //       'indice': indiceStr,
  //       'dias': '$asistencias / $totalDays',
  //       'rawIndice': indice,
  //       'registros': registrosDetallados, // Incluir registros detallados
  //       'asistenciaDocId': e.asistenciaDocId, // Para debugging
  //     });
  //   }

  //   // Ordenar por índice descendente
  //   rows.sort(
  //     (a, b) => (b['rawIndice'] as double).compareTo(a['rawIndice'] as double),
  //   );

  //   // Asignar ranking
  //   for (int i = 0; i < rows.length; i++) {
  //     rows[i]['ranking'] = (i + 1).toString();
  //     rows[i].remove('rawIndice');
  //   }

  //   debugPrint('DEBUG: Rows generadas: ${rows.length}');
  //   return rows;
  // }

  // String _formatDate(DateTime d) =>
  //     '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  @override
  void dispose() {
    empleadosSub?.cancel();
    deptoSub?.cancel();
    areaSub?.cancel();
    puestoSub?.cancel();
    empleadosController.close();
    departamentosController.close();
    areasController.close();
    puestosController.close();
    super.dispose();
  }
}
