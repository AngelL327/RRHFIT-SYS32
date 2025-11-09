import 'package:rrhfit_sys32/logic/utilities/format_date.dart';

class EmpleadoModel {
  String empleadoID;
  String areaID;
  String codEmpleado;
  String correo;
  String depID;
  String direccion;
  String estado;
  DateTime fechaContratacion;
  DateTime fechaNacimiento;
  String nombre;
  String numCuenta;
  String puestoID;
  String telefono;

  EmpleadoModel({
    required this.empleadoID,
    required this.areaID,
    required this.codEmpleado,
    required this.correo,
    required this.depID,
    required this.direccion,
    required this.estado,
    required this.fechaContratacion,
    required this.fechaNacimiento,
    required this.nombre,
    required this.numCuenta,
    required this.puestoID,
    required this.telefono,
  });

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) {
    return EmpleadoModel(
      empleadoID: json['empleado_id'] ?? 'N/A',
      areaID: json['area_id'] ?? 'N/A',
      codEmpleado: json['cod_empleado'] ?? 'N/A',
      correo: json['correo'] ?? 'N/A',
      depID: json['dep_id'] ?? 'N/A',
      direccion: json['direccion'] ?? 'N/A',
      estado: json['estado'] ?? 'N/A',
      fechaContratacion:  parseToDateTime(json['fecha_contratacion']),
      fechaNacimiento: parseToDateTime(json['fecha_nacimiento']),
      nombre: json['nombre'] ?? 'N/A',
      numCuenta: json['num_cuenta'] ?? 'N/A',
      puestoID: json['puesto_id'] ?? 'N/A',
      telefono: json['telefono'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empleado_id': empleadoID,
      'area_id': areaID,
      'codigo_empleado': codEmpleado,
      'correo': correo,
      'departamento_id': depID,
      'direccion': direccion,
      'estado': estado,
      'fecha_contratacion': parseToTimestamp(fechaContratacion),
      'fecha_nacimiento': parseToTimestamp(fechaNacimiento),
      'nombre': nombre,
      'numero_cuenta': numCuenta,
      'puesto_id': puestoID,
      'telefono': telefono,
    };
  }
}