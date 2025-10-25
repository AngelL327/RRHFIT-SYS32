// lib/empleados/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';

class FirestoreService {
  final CollectionReference coll = FirebaseFirestore.instance.collection(
    'empleados',
  );

  Stream<List<Employee>> streamEmpleados() {
    return coll.snapshots().map((snap) {
      final docs = snap.docs;
      return docs.map((d) => Employee.fromDocument(d)).toList();
    });
  }

  Future<Employee> createEmployee(Employee empleado) async {
    final docRef = await coll.add(empleado.toMap());
    empleado.id = docRef.id;
    await docRef.update({'empleado_id': empleado.id});
    return empleado;
  }

  Future<void> updateEmployee(Employee empleado) async {
    if (empleado.id == null) {
      throw Exception('Employee id is null');
    }
    await coll.doc(empleado.id).update(empleado.toMap());
  }

  Future<void> deleteEmployee(String id) async {
    await coll.doc(id).delete();
  }

  Future<Employee?> getById(String id) async {
    final doc = await coll.doc(id).get();
    if (!doc.exists) return null;
    return Employee.fromDocument(doc);
  }
}
