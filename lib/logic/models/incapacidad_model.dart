

import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_solicitudes.dart';

class IncapacidadModel {
  String id;
  String userId;
  String usuario;
  String tipoSolicitud;
  String numCertificado;
  String enteEmisor;
  DateTime fechaSolicitud;
  DateTime fechaExpediente;
  DateTime fechaInicioIncapacidad;
  DateTime fechaFinIncapacidad;
  String estado;
  String motivo;
  String documentoUrl;

  IncapacidadModel({
    required this.id,
    required this.userId,
    required this.usuario,
    required this.tipoSolicitud,
    required this.numCertificado,
    required this.enteEmisor,
    required this.fechaSolicitud,
    required this.fechaExpediente,
    required this.fechaInicioIncapacidad,
    required this.fechaFinIncapacidad,
    required this.estado,
    required this.motivo,
    required this.documentoUrl,
  });

  factory IncapacidadModel.fromJson(String id, Map<String, dynamic> json) {
    return IncapacidadModel(
      id: id,
      userId: json['uid']?? 'N/A',
      usuario: json['empleado'] ?? 'N/A',
      tipoSolicitud: json['tipo'] ?? 'N/A',
      numCertificado: json['numCertificado'] ?? 'N/A',
      enteEmisor: json['enteEmisor'] ?? 'N/A',
      fechaSolicitud: parseToDateTime(json['creadoEn']),
      fechaExpediente: parseToDateTime(json['fechaExpediente']),
      fechaInicioIncapacidad: parseToDateTime(json['fechaInicioIncapacidad']),
      fechaFinIncapacidad: parseToDateTime(json['fechaFinIncapacidad']),
      estado: json['estado'] ?? 'N/A',
      motivo: json['motivo'] ?? 'N/A',
      documentoUrl: json['documento'] ?? json['documento'] ?? json['documento'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': userId,
      'empleado': usuario,
      'tipo': TipoSolicitud.incapacidad,
      'numCertificado': numCertificado,
      'enteEmisor': enteEmisor,
      'creadoEn': parseToTimestamp(fechaSolicitud),
      'fechaExpediente': parseToTimestamp(fechaExpediente),
      'fechaInicioIncapacidad': parseToTimestamp(fechaInicioIncapacidad),
      'fechaFinIncapacidad': parseToTimestamp(fechaFinIncapacidad),
      'estado': estado,
      'motivo': motivo,
      'documento': documentoUrl,
    };
  }

}

