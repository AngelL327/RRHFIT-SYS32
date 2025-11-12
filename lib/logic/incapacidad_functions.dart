
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/utilities/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_solicitudes.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';

const String COLLECTION_INCAPACIDADES = 'incapacidades';

Future<List<IncapacidadModel>> getAllIncapacidades() async {
  List<IncapacidadModel> incapacidades = [];
      await FirebaseFirestore.instance.collection(COLLECTION_INCAPACIDADES)
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

Future<List<IncapacidadModel>> getIncapacidadesByEmpleadoId(String empleadoID) async {
  List<IncapacidadModel> incapacidades = [];
      await FirebaseFirestore.instance.collection(COLLECTION_INCAPACIDADES)
      .where("tipo", isEqualTo: TipoSolicitud.incapacidad)
      .where("uid", isEqualTo: empleadoID)
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

// Fetch incapacidades for a specific year and month (creadoEn within that month)
Future<List<IncapacidadModel>> getIncapacidadesByMonth(int year, int month) async {
  List<IncapacidadModel> incapacidades = [];
  try {
    final start = DateTime(year, month, 1);
    print("Comienza: ${start}");
    final end = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    print("Termina: ${end}");
  // Query only by 'creadoEn' as requested
    final q = await FirebaseFirestore.instance.collection(COLLECTION_INCAPACIDADES)
      .where('tipo', isEqualTo: TipoSolicitud.incapacidad)
      .where('creadoEn', isGreaterThanOrEqualTo: start)
      .where('creadoEn', isLessThan: end)
      .get();

    for (var doc in q.docs) {
      incapacidades.add(IncapacidadModel.fromJson(doc.id, doc.data()));
    }

    // Keep the same sorting logic as other fetchers
    incapacidades.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
    incapacidades.sort((a, b) {
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
  } catch (e) {
    // ignore and return empty list on error
  }
  return incapacidades;
}

// Fetch incapacidades for a specific year (all months)
Future<List<IncapacidadModel>> getIncapacidadesByYear(int year) async {
  List<IncapacidadModel> incapacidades = [];
  try {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    final q = await FirebaseFirestore.instance.collection(COLLECTION_INCAPACIDADES)
      .where('tipo', isEqualTo: TipoSolicitud.incapacidad)
      .where('creadoEn', isGreaterThanOrEqualTo: start)
      .where('creadoEn', isLessThan: end)
      .get();

    for (var doc in q.docs) {
      incapacidades.add(IncapacidadModel.fromJson(doc.id, doc.data()));
    }

    incapacidades.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
    incapacidades.sort((a, b) {
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
  } catch (e) {
    // ignore and return empty list on error
  }
  return incapacidades;
}


Future<bool> addIncapacidad(IncapacidadModel inc) async {
  try {
    await FirebaseFirestore.instance
        .collection(COLLECTION_INCAPACIDADES)
        .add(inc.toJson());
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> deleteIncapacidad(String id) async {
  try {
    await FirebaseFirestore.instance
        .collection(COLLECTION_INCAPACIDADES)
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
        .collection(COLLECTION_INCAPACIDADES)
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
