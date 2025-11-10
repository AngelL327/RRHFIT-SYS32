// lib/empleados/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/models/area_model.dart';
import 'package:rrhfit_sys32/empleados/models/departamento_model.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/models/puesto_model.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  String _formatId(String id) {
    if (id.isEmpty) return id;
    return id;
  }

  // -----------------------------------------------------------------------------------------------

  // Obtener todos los empleados
  Future<List<Map<String, dynamic>>> getAllEmpleados() async {
    try {
      final snapshot = await _firestore.collection('empleados').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo empleados: $e');
      return [];
    }
  }

  // Obtener asistencias por empleado ID
  Future<List<Map<String, dynamic>>> getAsistenciasByEmpleadoId(
    String empleadoId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final asistenciaSnapshot = await _firestore
          .collection('asistenciasEmpleados')
          .doc(empleadoId)
          .get();

      if (!asistenciaSnapshot.exists) {
        return [];
      }

      // Obtener registros del rango de fechas
      final registrosSnapshot = await _firestore
          .collection('asistenciasEmpleados')
          .doc(empleadoId)
          .collection('registros')
          .where(
            FieldPath.documentId,
            isGreaterThanOrEqualTo: _formatDate(startDate),
          )
          .where(
            FieldPath.documentId,
            isLessThanOrEqualTo: _formatDate(endDate),
          )
          .get();

      return registrosSnapshot.docs.map((doc) {
        final data = doc.data();
        return {'fecha': doc.id, ...data};
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo asistencias para $empleadoId: $e');
      return [];
    }
  }

  // Obtener datos combinados para el reporte
  Future<List<Map<String, dynamic>>> getReporteAsistenciaData({
    required DateTime startDate,
    required DateTime endDate,
    int ind = 0,
  }) async {
    try {
      final empleados = await getAllEmpleados();
      final reportData = <Map<String, dynamic>>[];

      for (final empleado in empleados) {
        final asistencias = await getAsistenciasByEmpleadoId(
          empleado['id'],
          startDate: startDate,
          endDate: endDate,
        );
        // Calcular métricas
        final totalDias = _calculateWorkingDays(startDate, endDate);
        final diasAsistidos = asistencias.length;
        final indiceAsistencia = totalDias > 0
            ? (diasAsistidos / totalDias) * 100
            : 0;

        // print('PERÍODO: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
        // print('DÍAS LABORABLES ESPERADOS: 3 (31/oct, 3/nov, 4/nov)');
        // print('DÍAS LABORABLES CALCULADOS: $totalDias');
        // print('DÍAS Asistencia: $diasAsistidos');
        // print('DÍAS indice: $indiceAsistencia');

        // Obtener información del puesto y departamento
        final puestoNombre = await _getPuestoNombre(empleado['puesto_id']);
        final departamentoNombre = await _getDepartamentoNombre(
          empleado['departamento_id'],
        );
        final areaNombre = await _getAreaNombre(empleado['area_id']);

        reportData.add({
          // Datos del empleado
          'empleado_id': empleado['id'],
          'codigo_empleado': empleado['codigo_empleado'] ?? '-',
          'nombre': empleado['nombre'] ?? '-',
          'puesto': puestoNombre,
          'departamento': departamentoNombre,
          'area': areaNombre,
          'fecha_contratacion': empleado['fecha_contratacion'] != null
              ? _formatFirestoreTimestamp(empleado['fecha_contratacion'])
              : '-',

          // Métricas de asistencia
          'total_dias': totalDias,
          'dias_asistidos': diasAsistidos,
          'indice_asistencia': indiceAsistencia,
          'indice_formateado': '${indiceAsistencia.toStringAsFixed(1)}%',

          // Detalles de asistencias
          'asistencias': asistencias,

          // Para el reporte perfecto (100% de asistencia)
          'asistencia_perfecta': indiceAsistencia >= ind,
        });
      }

      // Ordenar por índice de asistencia descendente
      reportData.sort(
        (a, b) => b['indice_asistencia'].compareTo(a['indice_asistencia']),
      );

      return reportData;
    } catch (e) {
      debugPrint('Error generando datos del reporte: $e');
      return [];
    }
  }

  // Métodos auxiliares
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateWorkingDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Excluir fines de semana (sábado = 6, domingo = 7)
      if (current.weekday != 6 && current.weekday != 7) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  Future<String> _getPuestoNombre(String? puestoId) async {
    if (puestoId == null) return '-';
    try {
      final doc = await _firestore.collection('puesto').doc(puestoId).get();
      return doc.data()?['nombre'] ?? '-';
    } catch (e) {
      return '-';
    }
  }

  Future<String> _getDepartamentoNombre(String? deptoId) async {
    if (deptoId == null) return '-';
    try {
      final doc = await _firestore
          .collection('departamento')
          .doc(deptoId)
          .get();
      return doc.data()?['nombre'] ?? '-';
    } catch (e) {
      return '-';
    }
  }

  Future<String> _getAreaNombre(String? areaId) async {
    if (areaId == null) return '-';
    try {
      final doc = await _firestore.collection('area').doc(areaId).get();
      return doc.data()?['nombre'] ?? '-';
    } catch (e) {
      return '-';
    }
  }

  String _formatFirestoreTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      return '-';
    } catch (e) {
      return '-';
    }
  }

  // -----------------------------------------------------------------------------------------------

  Future<Empleado> createEmployee(Empleado empleado) async {
    final ref = await empleadosCol.add(empleado.toMap());
    empleado.id = ref.id;
    empleado.empleadoId = _formatId(ref.id);
    empleado.asistenciaDocId = normalizeNombreToId(empleado.nombre ?? '');
    await ref.update({
      'empleado_id': empleado.empleadoId,
      'asistencia_doc_id': empleado.asistenciaDocId,
    });
    return empleado;
  }

  Future<void> updateEmployee(Empleado empleado) async {
    if (empleado.id == null) throw Exception('Employee id is null');
    empleado.empleadoId = _formatId(empleado.id!);
    empleado.asistenciaDocId = normalizeNombreToId(empleado.nombre ?? '');
    await empleadosCol.doc(empleado.id).update({
      ...empleado.toMap(),
      'empleado_id': empleado.empleadoId,
      'asistencia_doc_id': empleado.asistenciaDocId,
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

  // CRUD: Referencias
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
    final deptSnap = await deptoCol.get();
    if (deptSnap.docs.isEmpty) {
      final departamentos = [
        Departamento(nombre: 'Recursos Humanos', codigo: 'DH001'),
        Departamento(nombre: 'Administración', codigo: 'AD001'),
        Departamento(nombre: 'Sistemas', codigo: 'IT001'),
      ];
      for (final d in departamentos) {
        await createDepartamento(d);
      }
    }

    final puestoSnap = await puestoCol.get();
    if (puestoSnap.docs.isEmpty) {
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

    final areaSnap = await areaCol.get();
    if (areaSnap.docs.isEmpty) {
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

  // DEBUG
  Future<void> debugListAllAsistencias() async {
    try {
      final col = _firestore.collection('asistencias');
      final snap = await col.get();
      debugPrint('DEBUG: total asistencias docs = ${snap.docs.length}');
      for (final doc in snap.docs) {
        debugPrint('  - asistenciaDocId = ${doc.id}');
        final regsSnap = await col.doc(doc.id).collection('registros').get();
        debugPrint('      registros.count = ${regsSnap.docs.length}');
        for (int i = 0; i < regsSnap.docs.length && i < 3; i++) {
          final r = regsSnap.docs[i];
          final data = r.data();
          debugPrint(
            '         registro $i: id=${r.id}, uid=${data['uid']}, entrada=${data['entrada']}',
          );
        }
      }
    } catch (e, st) {
      debugPrint('debugListAllAsistencias error: $e\n$st');
    }
  }

  String _dateId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> countRegistrosByUserUid(
    String empleadoUid,
    DateTime start,
    DateTime end,
  ) async {
    final startId = _dateId(start);
    final endId = _dateId(end);
    final q = _firestore
        .collectionGroup('registros')
        .where('empleadoUid', isEqualTo: empleadoUid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endId);
    final snap = await q.get();
    return snap.docs.length;
  }

  /// Obtiene los registros de asistencia usando el asistenciaDocId del empleado
  Future<List<Map<String, dynamic>>> fetchRegistrosByAsistenciaDocId(
    String asistenciaDocId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startId = _dateId(start);
      final endId = _dateId(end);

      // Consulta en la estructura: asistencias/{asistenciaDocId}/registros/{fecha}
      final registrosRef = _firestore
          .collection('asistencias')
          .doc(asistenciaDocId)
          .collection('registros');

      final q = registrosRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
          .orderBy(FieldPath.documentId);

      final snap = await q.get();

      return snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['_docId'] = d.id; // Esto será la fecha (ej: "2025-11-09")
        m['_asistenciaDocId'] = asistenciaDocId;
        return m;
      }).toList();
    } catch (e, st) {
      debugPrint('Error en fetchRegistrosByAsistenciaDocId: $e\n$st');
      return [];
    }
  }

  Future<int> countRegistrosByAsistenciaDocId(
    String asistenciaDocId,
    DateTime start,
    DateTime end,
  ) async {
    final registros = await fetchRegistrosByAsistenciaDocId(
      asistenciaDocId,
      start,
      end,
    );
    return registros.length;
  }

  String normalizeNombreToId(String nombre) {
    if (nombre.trim().isEmpty) return '';

    String removeDiacritics(String s) {
      return s
          .replaceAll(RegExp(r'[ÁÀÄÂáàäâ]'), 'a')
          .replaceAll(RegExp(r'[ÉÈËÊéèëê]'), 'e')
          .replaceAll(RegExp(r'[ÍÌÏÎíìïî]'), 'i')
          .replaceAll(RegExp(r'[ÓÒÖÔóòöô]'), 'o')
          .replaceAll(RegExp(r'[ÚÙÜÛúùüû]'), 'u')
          .replaceAll(RegExp(r'[Ññ]'), 'n');
    }

    final cleaned = removeDiacritics(nombre).toLowerCase().trim().replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      '',
    ); // Remover caracteres especiales

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];

    // Retornar "primernombre_primerapellido"
    return '${parts[0]}_${parts[1]}';
  }
}
