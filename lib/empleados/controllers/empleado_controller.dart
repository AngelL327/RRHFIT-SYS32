// lib/empleados/controllers/empleado_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/models/departamento_model.dart';
import 'package:rrhfit_sys32/empleados/models/area_model.dart';
import 'package:rrhfit_sys32/empleados/models/puesto_model.dart';
import 'package:rrhfit_sys32/empleados/services/firestore_service.dart';

class EmpleadoController with ChangeNotifier {
  final FirestoreService service;

  final FirebaseFirestore firestoree = FirebaseFirestore.instance;

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

  //---------------------------------------------------------------------------------------------

  // Reemplaza la implementación actual de computeWeeklyAttendanceRows por esta:
  Future<List<Map<String, dynamic>>> computeWeeklyAttendanceRows({
    bool includeWeekends = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool soloAsistenciaPerfecta = true,
    int? ind,
  }) async {
    await ready;

    final start = customStartDate ?? _startDate;
    final end = customEndDate ?? _endDate;

    try {
      _reportData = await service.getReporteAsistenciaData(
        startDate: start,
        endDate: end,
        ind: ind ?? 0,
      );

      // Contar solo días laborables (lunes..viernes) en el rango
      int totalWorkingDays = 0;
      DateTime cur = DateTime(start.year, start.month, start.day);
      final DateTime endDay = DateTime(end.year, end.month, end.day);
      while (!cur.isAfter(endDay)) {
        if (cur.weekday >= DateTime.monday && cur.weekday <= DateTime.friday) {
          totalWorkingDays++;
        }
        cur = cur.add(const Duration(days: 1));
      }
      if (totalWorkingDays == 0)
        totalWorkingDays = 1; // evitar división por cero

      // Helper para determinar si un registro corresponde a un día laborable
      bool registroEsLaborable(Map<String, dynamic> registro) {
        // Intenta extraer fecha de campos comunes
        final candidates = <String?>[
          registro['_docId']?.toString(),
          registro['fecha']?.toString(),
          registro['date']?.toString(),
          registro['dia']?.toString(),
        ];

        for (final cand in candidates) {
          if (cand == null) continue;
          // Intentar parse ISO first
          DateTime? parsed;
          try {
            parsed = DateTime.tryParse(cand);
          } catch (_) {
            parsed = null;
          }
          if (parsed == null) {
            // Intentar dd/MM/yyyy
            try {
              final parts = cand.split(RegExp(r'[-/ ]'));
              if (parts.length == 3) {
                // detectar formato heurísticamente: si la primera parte tiene 4 dígitos, es yyyy-MM-dd
                if (parts[0].length == 4) {
                  parsed = DateTime.tryParse(
                    cand,
                  ); // ya intentado, pero reintento
                } else {
                  // asumir dd MM yyyy
                  final d = int.tryParse(parts[0]);
                  final m = int.tryParse(parts[1]);
                  final y = int.tryParse(parts[2]);
                  if (d != null && m != null && y != null) {
                    parsed = DateTime(y, m, d);
                  }
                }
              }
            } catch (_) {
              parsed = null;
            }
          }

          if (parsed != null) {
            // si la fecha parsea, devolver true si es Lunes-Viernes
            return parsed.weekday >= DateTime.monday &&
                parsed.weekday <= DateTime.friday;
          }
        }

        // Si no pudimos parsear, podemos intentar usar otros indicadores:
        // si el registro tiene 'entrada' o 'salida' asumimos que es asistencia válida
        if (registro.containsKey('entrada') || registro.containsKey('salida')) {
          return true; // asumimos laboral
        }

        // Por defecto: considerar como laboral (conservador)
        return true;
      }

      // Filtrar solo asistencia perfecta si se solicita
      final filteredData = soloAsistenciaPerfecta
          ? _reportData
                .where((emp) => emp['asistencia_perfecta'] == true)
                .toList()
          : _reportData;

      final rows = filteredData.asMap().entries.map((entry) {
        final index = entry.key;
        final empleado = entry.value;
        final asistencias =
            (empleado['asistencias'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

        // Contar solo las asistencias que caen en días laborables
        int asistenciasLaborables = 0;
        for (final reg in asistencias) {
          try {
            if (registroEsLaborable(reg)) asistenciasLaborables++;
          } catch (e) {
            // Si algo falla con un registro, asumimos que cuenta (evita subreportar)
            asistenciasLaborables++;
          }
        }

        // Calcular índice con respecto a los días laborables
        final double indiceDouble = totalWorkingDays > 0
            ? (asistenciasLaborables / totalWorkingDays) * 100.0
            : 0.0;
        final String indiceStr = '${indiceDouble.toStringAsFixed(1)}%';

        return {
          'ranking': (index + 1).toString(),
          'codigo': empleado['codigo_empleado'],
          'empleado': empleado['nombre'],
          'puesto': empleado['puesto'],
          'departamento': empleado['departamento'],
          'fecha_contratacion': empleado['fecha_contratacion'],
          'periodo': '${_formatDate(start)} - ${_formatDate(end)}',
          'indice': indiceStr,
          'indice_valor_numerico': indiceDouble,
          'dias': '$asistenciasLaborables / $totalWorkingDays',
          'area': empleado['area'],
          'detalle_asistencias': asistencias,
          'empleado_id': empleado['empleado_id'],
        };
      }).toList();

      rows.sort((a, b) {
        // Ordenamos de mayor a menor porcentaje
        return (b['indice_valor_numerico'] as double).compareTo(
          (a['indice_valor_numerico'] as double),
        );
      });

      double parseIndicePorcentaje(String indiceStr) {
        // Elimina el símbolo de '%'
        final cleanString = indiceStr.replaceAll('%', '');

        // Intenta parsear a double, si falla devuelve 0.0 para evitar errores
        return double.tryParse(cleanString) ?? 0.0;
      }

      for (int i = 0; i < rows.length; i++) {
        // i es el índice basado en 0, así que el ranking es i + 1
        rows[i]['ranking'] = (i + 1).toString();
      }

      rows.sort((a, b) {
        // Obtenemos los strings de índice de los mapas a y b
        final indiceAStr = a['indice'] as String;
        final indiceBStr = b['indice'] as String;

        // Parseamos los strings a doubles usando nuestra función auxiliar
        final indiceADouble = parseIndicePorcentaje(indiceAStr);
        final indiceBDouble = parseIndicePorcentaje(indiceBStr);

        // Comparamos los valores numéricos
        // Esto ordena de forma ascendente (de menor a mayor índice)
        return indiceBDouble.compareTo(indiceADouble);
      });

      for (int i = 0; i < rows.length; i++) {
        // i es el índice basado en 0, así que el ranking es i + 1
        rows[i]['ranking'] = (i + 1).toString();
      }

      return rows;
    } catch (e, st) {
      return [];
    }
  }

  //---------------------------------------------------------------------------------------------

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
