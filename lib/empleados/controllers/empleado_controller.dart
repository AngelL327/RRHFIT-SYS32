import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/models/departamento_model.dart';
import 'package:rrhfit_sys32/empleados/models/area_model.dart';
import 'package:rrhfit_sys32/empleados/models/puesto_model.dart';
import 'package:rrhfit_sys32/empleados/services/firestore_service.dart';

class EmployeeController with ChangeNotifier {
  final FirestoreService _service;

  EmployeeController({FirestoreService? service})
    : _service = service ?? FirestoreService() {
    empleadosController = StreamController<List<Empleado>>.broadcast(
      onListen: () {
        empleadosController.add(List<Empleado>.from(_lastEmpleados));
      },
    );

    departamentosController = StreamController<List<Departamento>>.broadcast(
      onListen: () {
        departamentosController.add(
          List<Departamento>.from(_lastDepartamentos),
        );
      },
    );

    areasController = StreamController<List<Area>>.broadcast(
      onListen: () {
        areasController.add(List<Area>.from(lastAreas));
      },
    );

    puestosController = StreamController<List<Puesto>>.broadcast(
      onListen: () {
        puestosController.add(List<Puesto>.from(_lastPuestos));
      },
    );

    _init();
  }

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

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  Stream<List<Empleado>> get empleadosStream => empleadosController.stream;
  Stream<List<Departamento>> get departamentosStream =>
      departamentosController.stream;
  Stream<List<Area>> get areasStream => areasController.stream;
  Stream<List<Puesto>> get puestosStream => puestosController.stream;

  Future<void> _init() async {
    try {
      await _service.ensureAndSeedReferenceData();

      deptoSub = _service.streamDepartamentos().listen(
        (list) {
          _lastDepartamentos = List<Departamento>.from(list);
          departamentoMapa.clear();
          for (final d in list) {
            if (d.id != null && d.nombre != null)
              departamentoMapa[d.id!] = d.nombre!;
          }
          departamentosController.add(List<Departamento>.from(list));
          notifyListeners();
        },
        onError: (e) {
          debugPrint('EmployeeController: error departamentos stream: $e');
        },
      );

      areaSub = _service.streamAreas().listen(
        (list) {
          lastAreas = List<Area>.from(list);
          areaMapa.clear();
          for (final a in list) {
            if (a.id != null && a.nombre != null) areaMapa[a.id!] = a.nombre!;
          }
          areasController.add(List<Area>.from(list));
          notifyListeners();
        },
        onError: (e) {
          debugPrint('EmployeeController: error areas stream: $e');
        },
      );

      puestoSub = _service.streamPuestos().listen(
        (list) {
          _lastPuestos = List<Puesto>.from(list);
          puestoMapa.clear();
          for (final p in list) {
            if (p.id != null && p.nombre != null) puestoMapa[p.id!] = p.nombre!;
          }
          puestosController.add(List<Puesto>.from(list));
          notifyListeners();
        },
        onError: (e) {
          debugPrint('EmployeeController: error puestos stream: $e');
        },
      );

      empleadosSub = _service.streamEmpleados().listen(
        (list) {
          _lastEmpleados = List<Empleado>.from(list);
          allEmployees = list;
          _applyFilter();
        },
        onError: (e) {
          debugPrint('EmployeeController: error empleados stream: $e');
        },
      );

      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    } catch (e, s) {
      debugPrint('EmployeeController _init error: $e\n$s');
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
      empleadosController.add(List<Empleado>.from(allEmployees));
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
          final dn = getDepartamentoNombre(e.departamentoId);
          return (dn ?? '').toLowerCase().contains(q);
        case 'Puesto':
          final pn = getPuestoNombre(e.puestoId);
          return (pn ?? '').toLowerCase().contains(q);
        case 'Fecha de Contratacion':
          final f = e.fechaContratacion;
          final s = f == null
              ? ''
              : f.toLocal().toIso8601String().split('T')[0];
          return s.toLowerCase().contains(q);
        default:
          return (e.nombre ?? '').toLowerCase().contains(q);
      }
    }).toList();
    empleadosController.add(filtered);
  }

  String? getDepartamentoNombre(String? id) {
    if (id == null) return '-';
    return departamentoMapa[id] ?? '-';
  }

  String? getAreaNombre(String? id) {
    if (id == null) return '-';
    return areaMapa[id] ?? '-';
  }

  String? getPuestoNombre(String? id) {
    if (id == null) return '-';
    return puestoMapa[id] ?? '-';
  }

  Future<void> createEmployee(Empleado e) async {
    await _readyCompleter.future;
    await _service.createEmployee(e);
  }

  Future<void> updateEmployee(Empleado e) async {
    await _readyCompleter.future;
    await _service.updateEmployee(e);
  }

  Future<void> deleteEmployee(String id) async {
    await _readyCompleter.future;
    await _service.deleteEmployee(id);
  }

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
