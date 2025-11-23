import 'package:cloud_firestore/cloud_firestore.dart';

class Empleado {
  String? id;
  String? empleadoId;
  String? nombre;
  String? codigoEmpleado;
  DateTime? fechaNacimiento;
  String? correo;
  String? telefono;
  String? estado;
  String? direccion;
  String? numeroCuenta;
  String? departamentoId;
  double? salario;
  String? areaId;
  String? asistenciaDocId;
  String? puestoId;
  DateTime? fechaContratacion;

  Empleado({
    this.id,
    this.empleadoId,
    this.nombre,
    this.codigoEmpleado,
    this.fechaNacimiento,
    this.correo,
    this.telefono,
    this.estado,
    this.direccion,
    this.numeroCuenta,
    this.departamentoId,
    this.salario,
    this.areaId,
    this.asistenciaDocId,
    this.puestoId,
    this.fechaContratacion,
  });

  factory Empleado.fromDocument(DocumentSnapshot doc) {
    final mapa = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? fromTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Empleado(
      id: doc.id,
      empleadoId: mapa['empleado_id'] as String?,
      nombre: mapa['nombre'] as String?,
      codigoEmpleado: mapa['codigo_empleado'] as String?,
      fechaNacimiento: fromTimestamp(mapa['fecha_nacimiento']),
      correo: mapa['correo'] as String?,
      telefono: mapa['telefono'] as String?,
      estado: mapa['estado'] as String?,
      direccion: mapa['direccion'] as String?,
      numeroCuenta: mapa['numero_cuenta'] as String?,
      departamentoId: mapa['departamento_id'] as String?,
      salario: (mapa['salario'] as num?)?.toDouble(),
      areaId: mapa['area_id'] as String?,
      asistenciaDocId: mapa['asistenciaDocId'] as String?,
      puestoId: mapa['puesto_id'] as String?,
      fechaContratacion: fromTimestamp(mapa['fecha_contratacion']),
    );
  }

  get fechaFinContrato => null;

  Map<String, dynamic> toMap() {
    dynamic toTimestamp(DateTime? d) =>
        d == null ? null : Timestamp.fromDate(d);

    return {
      'empleado_id': empleadoId,
      'nombre': nombre,
      'codigo_empleado': codigoEmpleado,
      'fecha_nacimiento': toTimestamp(fechaNacimiento),
      'correo': correo,
      'telefono': telefono,
      'estado': estado,
      'direccion': direccion,
      'numero_cuenta': numeroCuenta,
      'departamento_id': departamentoId,
      'salario': salario,
      'area_id': areaId,
      'asistenciaDocId': asistenciaDocId,
      'puesto_id': puestoId,
      'fecha_contratacion': toTimestamp(fechaContratacion),
    };
  }
}
