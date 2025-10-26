import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/services/firestore_service.dart';

class EmployeeController with ChangeNotifier {
  final FirestoreService service;

  EmployeeController({FirestoreService? service})
    : service = service ?? FirestoreService() {
    _init();
  }

  final StreamController<List<Empleado>> empleadosController =
      StreamController.broadcast();
  StreamSubscription? streamSubCollection;
  final Completer<void> readyCompleter = Completer<void>();

  Stream<List<Empleado>> get empleadosStream => empleadosController.stream;

  Future<void> _init() async {
    try {
      streamSubCollection = service.streamEmpleados().listen(
        (list) {
          empleadosController.add(list);
        },
        onError: (error, s) {
          debugPrint('Empleado error de stream: $error');
        },
      );
      // marcamos como listo
      if (!readyCompleter.isCompleted) readyCompleter.complete();
    } catch (e) {
      debugPrint('Error inicializando EmployeeController: $e');
      if (!readyCompleter.isCompleted) readyCompleter.completeError(e);
    }
  }

  Future<void> createEmployee(Empleado empleado) async {
    await readyCompleter.future;
    await service.createEmployee(empleado);
  }

  Future<void> updateEmployee(Empleado empleado) async {
    await readyCompleter.future;
    await service.updateEmployee(empleado);
  }

  Future<void> deleteEmployee(String id) async {
    await readyCompleter.future;
    await service.deleteEmployee(id);
  }

  @override
  void dispose() {
    streamSubCollection?.cancel();
    empleadosController.close();
    super.dispose();
  }
}
