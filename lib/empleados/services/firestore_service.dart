import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<List<Map<String, dynamic>>> getAllEmpleados() async {
    try {
      final snapshot = await _firestore.collection('empleados').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAsistenciasByEmpleadoId(
    String empleadoId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final docRef = _firestore
          .collection('asistenciasEmpleados')
          .doc(empleadoId);

      final registrosRef = docRef.collection('registros');

      try {
        final startTs = Timestamp.fromDate(
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0),
        );
        final endTs = Timestamp.fromDate(
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        );
        final byFecha = await registrosRef
            .where('fecha', isGreaterThanOrEqualTo: startTs)
            .where('fecha', isLessThanOrEqualTo: endTs)
            .orderBy('fecha')
            .get(const GetOptions(source: Source.server));

        if (byFecha.docs.isNotEmpty) {
          return byFecha.docs.map((d) {
            final m = Map<String, dynamic>.from(d.data());
            m['_docId'] = d.id;
            return m;
          }).toList();
        } else {}
      } catch (e) {
        print("Error en getAsistenciasByEmpleadoId por fecha: $e");
      }

      try {
        final startId = _formatDate(startDate);
        final endId = _formatDate(endDate);
        final byDocId = await registrosRef
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
            .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
            .orderBy(FieldPath.documentId)
            .get(const GetOptions(source: Source.server));

        if (byDocId.docs.isNotEmpty) {
          return byDocId.docs.map((d) {
            final m = Map<String, dynamic>.from(d.data());
            m['_docId'] = d.id;
            return m;
          }).toList();
        } else {}
      } catch (e) {
        print("Error en getAsistenciasByEmpleadoId por docId: $e");
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRegistrosByEmpleadoIdAnywhere(
    String empleadoId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startTs = Timestamp.fromDate(
        DateTime(start.year, start.month, start.day, 0, 0, 0),
      );
      final endTs = Timestamp.fromDate(
        DateTime(end.year, end.month, end.day, 23, 59, 59),
      );
      final startId = _dateId(start);
      final endId = _dateId(end);

      try {
        final docRef = _firestore
            .collection('asistenciasEmpleados')
            .doc(empleadoId);

        try {
          final qFecha = docRef
              .collection('registros')
              .where('fecha', isGreaterThanOrEqualTo: startTs)
              .where('fecha', isLessThanOrEqualTo: endTs)
              .orderBy('fecha');
          final snapFecha = await qFecha.get(
            const GetOptions(source: Source.server),
          );
          if (snapFecha.docs.isNotEmpty) {
            return snapFecha.docs.map((d) {
              final m = Map<String, dynamic>.from(d.data());
              m['_docId'] = d.id;
              m['_parentPath'] = d.reference.parent.parent?.path ?? '';
              return m;
            }).toList();
          } else {}
        } catch (e) {
          print("Error en fetchRegistrosByEmpleadoIdAnywhere por fecha: $e");
        }

        try {
          final qDocId = docRef
              .collection('registros')
              .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
              .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
              .orderBy(FieldPath.documentId);
          final snapDocId = await qDocId.get(
            const GetOptions(source: Source.server),
          );
          if (snapDocId.docs.isNotEmpty) {
            return snapDocId.docs.map((d) {
              final m = Map<String, dynamic>.from(d.data());
              m['_docId'] = d.id;
              m['_parentPath'] = d.reference.parent.parent?.path ?? '';
              return m;
            }).toList();
          } else {}
        } catch (e) {
          print("Error en fetchRegistrosByEmpleadoIdAnywhere por docId: $e");
        }
      } catch (e) {
        print("Error en fetchRegistrosByEmpleadoIdAnywhere: $e");
      }

      return [];
    } catch (e) {
      print("Error en fetchRegistrosByEmpleadoIdAnywhere: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getReporteAsistenciaData({
    required DateTime startDate,
    required DateTime endDate,
    int? ind,
  }) async {
    try {
      final empleados = await getAllEmpleados();
      final reportData = <Map<String, dynamic>>[];

      final totalDias = _calculateWorkingDays(startDate, endDate);

      for (final empleado in empleados) {
        final empleadoId = empleado['id']?.toString() ?? '';

        final asistenciaDocId =
            (empleado['asistencia_doc_id'] ??
                    empleado['asistenciaDocId'] ??
                    empleado['asistencia_docid'] ??
                    '')
                .toString();

        List<Map<String, dynamic>> asistencias = [];

        if (asistenciaDocId.isNotEmpty) {
          try {
            final fetched = await fetchRegistrosByAsistenciaDocId(
              asistenciaDocId,
              startDate,
              endDate,
            );
            if (fetched.isNotEmpty) {
              asistencias = fetched;
            }
          } catch (e) {
            print("Error fetching by asistenciaDocId: $e");
          }
        }

        if (asistencias.isEmpty && empleadoId.isNotEmpty) {
          try {
            final fetched2 = await getAsistenciasByEmpleadoId(
              empleadoId,
              startDate: startDate,
              endDate: endDate,
            );
            if (fetched2.isNotEmpty) {
              asistencias = fetched2;
            }
          } catch (e) {
            print("Error fetching by empleadoId: $e");
          }
        }

        if (asistencias.isEmpty && empleadoId.isNotEmpty) {
          try {
            final fetched3 = await fetchRegistrosByEmpleadoIdAnywhere(
              empleadoId,
              startDate,
              endDate,
            );
            if (fetched3.isNotEmpty) {
              asistencias = fetched3;
            }
          } catch (e) {
            print("Error fetching anywhere by empleadoId: $e");
          }
        }

        final Set<String> diasUnicos = <String>{};
        final List<Map<String, dynamic>> detalle = [];

        DateTime? parseFechaFromRegistro(Map<String, dynamic> r) {
          try {
            if (r.containsKey('fecha') && r['fecha'] is Timestamp) {
              return (r['fecha'] as Timestamp).toDate();
            }
            if (r.containsKey('fecha')) {
              final s = r['fecha'].toString();
              final parsed = DateTime.tryParse(s);
              if (parsed != null) return parsed;
            }
            if (r.containsKey('_docId')) {
              final id = r['_docId'].toString();
              final m = RegExp(
                r'(\d{4})[-_]?(\d{2})[-_]?(\d{2})',
              ).firstMatch(id);
              if (m != null) {
                return DateTime(
                  int.parse(m.group(1)!),
                  int.parse(m.group(2)!),
                  int.parse(m.group(3)!),
                );
              }
              final parts = id.split(RegExp(r'[-/ ]'));
              if (parts.length == 3) {
                final d = int.tryParse(parts[0]);
                final mo = int.tryParse(parts[1]);
                final y = int.tryParse(parts[2]);
                if (d != null && mo != null && y != null)
                  return DateTime(y, mo, d);
              }
            }
          } catch (_) {
            return null;
          }
          return null;
        }

        for (final r in asistencias) {
          final dt = parseFechaFromRegistro(Map<String, dynamic>.from(r));
          String key;
          if (dt != null) {
            key =
                '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } else {
            key =
                (r['_docId']?.toString() ??
                r['id']?.toString() ??
                r.toString());
          }

          detalle.add(Map<String, dynamic>.from(r));
          diasUnicos.add(key);
        }

        final diasAsistidos = diasUnicos.length;
        final indiceAsistencia = totalDias > 0
            ? (diasAsistidos / totalDias) * 100
            : 0.0;

        final puestoNombre = await _getPuestoNombre(
          empleado['puesto_id'] ??
              empleado['puestoId'] ??
              empleado['puesto'] ??
              '',
        );
        final departamentoNombre = await _getDepartamentoNombre(
          empleado['departamento_id'] ??
              empleado['departamentoId'] ??
              empleado['departamento'] ??
              '',
        );
        final areaNombre = await _getAreaNombre(
          empleado['area_id'] ?? empleado['areaId'] ?? empleado['area'] ?? '',
        );

        reportData.add({
          'empleado_id': empleadoId,
          'codigo_empleado':
              empleado['codigo_empleado'] ?? empleado['codigo'] ?? '-',
          'nombre': empleado['nombre'] ?? '-',
          'puesto': puestoNombre,
          'departamento': departamentoNombre,
          'area': areaNombre,
          'fecha_contratacion': empleado['fecha_contratacion'] != null
              ? _formatFirestoreTimestamp(empleado['fecha_contratacion'])
              : '-',
          'total_dias': totalDias,
          'dias_asistidos': diasAsistidos,
          'indice_asistencia': indiceAsistencia,
          'indice_formateado': '${indiceAsistencia.toStringAsFixed(1)}%',
          'asistencias': detalle,
          'asistencia_perfecta': indiceAsistencia >= (ind ?? 0),
        });
      }

      reportData.sort(
        (a, b) => (b['indice_asistencia'] as double).compareTo(
          a['indice_asistencia'] as double,
        ),
      );

      return reportData;
    } catch (e) {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateWorkingDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
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

  Future<List<Map<String, dynamic>>> fetchRegistrosByAsistenciaDocId(
    String asistenciaDocId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startId = _dateId(start);
      final endId = _dateId(end);

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
        m['_docId'] = d.id;
        m['_asistenciaDocId'] = asistenciaDocId;
        return m;
      }).toList();
    } catch (e) {
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

    final cleaned = removeDiacritics(
      nombre,
    ).toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9\s]'), '');

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];

    return '${parts[0]}_${parts[1]}';
  }
}
