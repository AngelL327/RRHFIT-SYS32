import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';

Future<List<IncapacidadModel>> getAllIncapacidades() async {
  List<IncapacidadModel> incapacidades = [];
      await FirebaseFirestore.instance.collection('solicitudes')
      .where("tipo", isEqualTo: "Incapacidad")
      .get()
      .then((value) {
        print('Incapacidades obtenidas: ${value.docs.length}');
        for (var doc in value.docs) {
          incapacidades.add(IncapacidadModel.fromJson(doc.id, doc.data()));
        }
      })
      .catchError((error) {
        print('Error obteniendo incapacidades: $error');
      });
  return incapacidades;
}

