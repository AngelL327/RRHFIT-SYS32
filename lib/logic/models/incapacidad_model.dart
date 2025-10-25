

import 'package:rrhfit_sys32/logic/functions/format_date.dart';
import 'package:rrhfit_sys32/logic/functions/tipos_solicitudes.dart';

class IncapacidadModel {
  String id;
  String usuario;
  String tipoSolicitud;
  DateTime fechaSolicitud;
  DateTime fechaExpediente;
  DateTime fechaInicioIncapacidad;
  DateTime fechaFinIncapacidad;
  String estado;
  //String descripcion;

  IncapacidadModel({
    required this.id,
    required this.usuario,
    required this.tipoSolicitud,
    required this.fechaSolicitud,
    required this.fechaExpediente,
    required this.fechaInicioIncapacidad,
    required this.fechaFinIncapacidad,
    required this.estado,
    //required this.descripcion,
  });

  factory IncapacidadModel.fromJson(String id, Map<String, dynamic> json) {

    return IncapacidadModel(
      // prefer document id passed in; fall back to json uid if present
      id: (json['uid'] as String?) ?? id,
      usuario: json['empleado'] as String? ?? '',
      tipoSolicitud: TipoSolicitud().incapacidad(),
      fechaSolicitud: parseToDateTime((json['creadoEn'])),
      fechaExpediente: parseToDateTime((json['fechaExpediente'])),
      fechaInicioIncapacidad: parseToDateTime((json['fechaInicioIncapacidad'])),
      fechaFinIncapacidad: parseToDateTime((json['fechaFinIncapacidad'])),
      estado: json['estado'] as String? ?? '',
      //descripcion: json['descripcion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'empleado': usuario,
      'tipo': TipoSolicitud().incapacidad(),
      'creadoEn': fechaSolicitud,
      'fechaExpediente': fechaExpediente,
      'fechaInicioIncapacidad': fechaInicioIncapacidad,
      'fechaFinIncapacidad': fechaFinIncapacidad,
      'estado': estado,
      //'descripcion': descripcion,
    };
  }

}

