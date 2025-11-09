
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/utilities/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_solicitudes.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';

Future<List<IncapacidadModel>> getAllIncapacidades() async {
  List<IncapacidadModel> incapacidades = [];
      await FirebaseFirestore.instance.collection('solicitudes')
      .where("tipo", isEqualTo: TipoSolicitud.incapacidad)
      .get()
      .then((value) {
        for (var doc in value.docs) {
          incapacidades.add(IncapacidadModel.fromJson(doc.id, doc.data()));
        }
        incapacidades.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
        incapacidades.sort((a, b) {
          // Priorizar estados: Pendiente > Aprobada > Rechazada
          int getEstadoPriority(String estado) {
            switch (estado) {
              case "Pendiente":
                return 3;
              case "Aprobada":
                return 2;
              case "Rechazada":
                return 1;
              default:
                return 0;
            }
          }
          return getEstadoPriority(b.estado).compareTo(getEstadoPriority(a.estado));
        });
      })
      .catchError((error) {
      });
  return incapacidades;
}

Future<bool> addIncapacidad(IncapacidadModel inc) async {
  try {
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .add(inc.toJson());
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> deleteIncapacidad(String id) async {
  try {
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(id)
        .delete();
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> updateEstadoIncapacidad(String id, String nuevoEstado) async {
  try {
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(id)
        .update({'estado': nuevoEstado});
    return true;
  } catch (e) {
    return false;
  }
}

Future<String?> getCountIncapacidades() async {
  List<IncapacidadModel> incapacidades = await getAllIncapacidades();
  return incapacidades.length.toString();
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
