
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/functions/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/functions/tipos_solicitudes.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';

Future<List<IncapacidadModel>> getAllIncapacidades() async {
  List<IncapacidadModel> incapacidades = [];
      await FirebaseFirestore.instance.collection('solicitudes')
      .where("tipo", isEqualTo: TipoSolicitud().incapacidad())
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

Future<String?> getCountIncapacidadesPendientes() async {
  int count = 0;
  List<IncapacidadModel> incapacidades = await getAllIncapacidades();
  for (var inc in incapacidades) {
    if (inc.estado == EstadoSolicitud.pendiente) {
      count++;
    }
  }
  return count.toString();
}

Future<String?> getCountIncapacidadesRevisadas() async {
  int count = 0;
  List<IncapacidadModel> incapacidades = await getAllIncapacidades();
  for (var inc in incapacidades) {
    if (inc.estado != EstadoSolicitud.pendiente) {
      count++;
    }
  }
  return count.toString();
}

Future<String?> getCountIncapacidadesAprobadas() async {
  int count = 0;
  List<IncapacidadModel> incapacidades = await getAllIncapacidades();
  for (var inc in incapacidades) {
    if (inc.estado == EstadoSolicitud.aprobada) {
      count++;
    }
  }
  return count.toString();
}

Future<String?> getCountIncapacidadesRechazadas() async {
  int count = 0;
  List<IncapacidadModel> incapacidades = await getAllIncapacidades();
  for (var inc in incapacidades) {
    if (inc.estado == EstadoSolicitud.rechazada) {
      count++;
    }
  }
  return count.toString();
}
