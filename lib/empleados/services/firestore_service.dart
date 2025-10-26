// lib/empleados/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/empleados/models/area_model.dart';
import 'package:rrhfit_sys32/empleados/models/departamento_model.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/models/puesto_model.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  CollectionReference get empleadosCol => db.collection('empleados');
  CollectionReference get deptoCol => db.collection('departamento');
  CollectionReference get areaCol => db.collection('area');
  CollectionReference get puestoCol => db.collection('puesto');

  Stream<List<Empleado>> streamEmpleados() {
    return empleadosCol.snapshots().map((snap) {
      return snap.docs.map((d) => Empleado.fromDocument(d)).toList();
    });
  }

  Stream<List<Departamento>> streamDepartamentos() {
    return deptoCol.snapshots().map((snap) {
      return snap.docs.map((d) => Departamento.fromDocument(d)).toList();
    });
  }

  Stream<List<Area>> streamAreas() {
    return areaCol.snapshots().map((snap) {
      return snap.docs.map((d) => Area.fromDocument(d)).toList();
    });
  }

  Stream<List<Puesto>> streamPuestos() {
    return puestoCol.snapshots().map((snap) {
      return snap.docs.map((d) => Puesto.fromDocument(d)).toList();
    });
  }

  // CRUD: Empleado

  String _formatId(String id) {
    if (id.isEmpty) return id;
    return id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  Future<Empleado> createEmployee(Empleado empleado) async {
    final ref = await empleadosCol.add(empleado.toMap());
    empleado.id = ref.id;
    empleado.empleadoId = _formatId(ref.id);
    await ref.update({'empleado_id': empleado.empleadoId});
    return empleado;
  }

  Future<void> updateEmployee(Empleado empleado) async {
    if (empleado.id == null) {
      throw Exception('Employee id is null');
    }
    if (empleado.id != null) {
      empleado.empleadoId = _formatId(empleado.id!);
    } else {
      empleado.empleadoId = empleado.empleadoId ?? '';
    }
    await empleadosCol.doc(empleado.id).update({
      ...empleado.toMap(),
      'empleado_id': empleado.empleadoId,
    });
  }

  Future<void> deleteEmployee(String id) async {
    await empleadosCol.doc(id).delete();
  }

  Future<Empleado?> getById(String id) async {
    final doc = await empleadosCol.doc(id).get();
    if (!doc.exists) return null;
    return Empleado.fromDocument(doc);
  }

  // CRUD: Departamento / Area / Puesto

  Future<Departamento> createDepartamento(Departamento d) async {
    final ref = await deptoCol.add(d.toMap());
    d.id = ref.id;
    d.departamentoId = ref.id;
    await ref.update({'departamento_id': d.id});
    return d;
  }

  Future<Area> createArea(Area a) async {
    final ref = await areaCol.add(a.toMap());
    a.id = ref.id;
    a.areaId = ref.id;
    await ref.update({'area_id': a.id});
    return a;
  }

  Future<Puesto> createPuesto(Puesto p) async {
    final ref = await puestoCol.add(p.toMap());
    p.id = ref.id;
    p.puestoId = ref.id;
    await ref.update({'puesto_id': p.id});
    return p;
  }

  // Get maps id->nombre (una sola vez)
  Future<Map<String, String>> getDepartamentosMap() async {
    final snap = await deptoCol.get();
    final map = <String, String>{};
    for (final d in snap.docs) {
      final doc = Departamento.fromDocument(d);
      if (doc.id != null && doc.nombre != null) map[doc.id!] = doc.nombre!;
    }
    return map;
  }

  Future<Map<String, String>> getAreasMap() async {
    final snap = await areaCol.get();
    final map = <String, String>{};
    for (final d in snap.docs) {
      final doc = Area.fromDocument(d);
      if (doc.id != null && doc.nombre != null) map[doc.id!] = doc.nombre!;
    }
    return map;
  }

  Future<Map<String, String>> getPuestosMap() async {
    final snap = await puestoCol.get();
    final map = <String, String>{};
    for (final d in snap.docs) {
      final doc = Puesto.fromDocument(d);
      if (doc.id != null && doc.nombre != null) map[doc.id!] = doc.nombre!;
    }
    return map;
  }

  Future<void> ensureAndSeedReferenceData() async {
    // departamentos
    final deptSnap = await deptoCol.get();
    final hasDept = deptSnap.docs.isNotEmpty;
    if (!hasDept) {
      final departamentos = [
        Departamento(nombre: 'Recursos Humanos', codigo: 'DH001'),
        Departamento(nombre: 'Administración', codigo: 'AD001'),
        Departamento(nombre: 'Sistemas', codigo: 'IT001'),
      ];
      for (final d in departamentos) {
        await createDepartamento(d);
      }
    }

    // puestos
    final puestoSnap = await puestoCol.get();
    final hasPuesto = puestoSnap.docs.isNotEmpty;
    if (!hasPuesto) {
      final puestos = [
        Puesto(nombre: 'Gerente', codigo: 'P001'),
        Puesto(nombre: 'Analista', codigo: 'P002'),
        Puesto(nombre: 'Desarrollador', codigo: 'P003'),
        Puesto(nombre: 'Soporte Técnico', codigo: 'P004'),
      ];
      for (final p in puestos) {
        await createPuesto(p);
      }
    }

    // areas
    final areaSnap = await areaCol.get();
    final hasArea = areaSnap.docs.isNotEmpty;
    if (!hasArea) {
      final deptsMap = await getDepartamentosMap();

      String? findDeptIdByName(String name) {
        final entry = deptsMap.entries.firstWhere(
          (e) => e.value == name,
          orElse: () => const MapEntry('', ''),
        );
        return entry.key.isEmpty ? null : entry.key;
      }

      final defaultAreas = <Area>[
        Area(
          departamentoId: findDeptIdByName('Recursos Humanos'),
          nombre: 'Reclutamiento',
          codigo: 'A001',
        ),
        Area(
          departamentoId: findDeptIdByName('Recursos Humanos'),
          nombre: 'Capacitación',
          codigo: 'A002',
        ),
        Area(
          departamentoId: findDeptIdByName('Administración'),
          nombre: 'Finanzas',
          codigo: 'A003',
        ),
        Area(
          departamentoId: findDeptIdByName('Sistemas'),
          nombre: 'Desarrollo',
          codigo: 'A004',
        ),
        Area(
          departamentoId: findDeptIdByName('Sistemas'),
          nombre: 'Soporte',
          codigo: 'A005',
        ),
      ];

      for (final a in defaultAreas) {
        await createArea(a);
      }
    }
  }
}
