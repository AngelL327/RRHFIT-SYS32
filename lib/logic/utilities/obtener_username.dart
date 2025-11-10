

import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> obtenerUsername(String uid) async {
  final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
  if (doc.exists) {
    final data = doc.data();
    if (data != null && data.containsKey('nombre')) {
      String nombreCompleto = "${data['nombre']} ${data['apellido']}";
      return nombreCompleto;
    }
  }
  return 'Usuario Desconocido';
}

Future<String> obtenerEmpleadoID(String userID) async {
  final doc = await FirebaseFirestore.instance
  .collection('usuarios')
  .doc(userID)
  .get();
  if (doc.exists) {
    final data = doc.data();
    if (data != null && data.containsKey('uid')) {
      String empleadoId = data['uid'];
      return empleadoId;
    }
  }
  return '';
}