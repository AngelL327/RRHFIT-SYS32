

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';

Future<List<EmpleadoModel>> getAllEmpleados() async {
  List<EmpleadoModel> empleados = [];
  final snapshot = await FirebaseFirestore.instance.collection('empleados').get();
  for (var doc in snapshot.docs) {
    // include document id in the json map if needed by the model
    final data = doc.data();
    empleados.add(EmpleadoModel.fromJson(data));
  }
  return empleados;
}

Future<EmpleadoModel?> getEmpleadoById(String empleadoID) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('empleados')
      .where('empleado_id', isEqualTo: empleadoID)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final doc = snapshot.docs.first;
    final data = doc.data();
    return EmpleadoModel.fromJson(data);
  } else {
    return null; // No employee found with the given uid
  }
}