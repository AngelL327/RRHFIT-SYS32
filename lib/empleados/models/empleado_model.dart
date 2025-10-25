import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
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
  String? areaId;
  String? puestoId;
  DateTime? fechaContratacion;

  Employee({
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
    this.areaId,
    this.puestoId,
    this.fechaContratacion,
  });

  factory Employee.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? fromTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Employee(
      id: doc.id,
      empleadoId: map['empleado_id'] as String?,
      nombre: map['nombre'] as String?,
      codigoEmpleado: map['codigo_empleado'] as String?,
      fechaNacimiento: fromTimestamp(map['fecha_nacimiento']),
      correo: map['correo'] as String?,
      telefono: map['telefono'] as String?,
      estado: map['estado'] as String?,
      direccion: map['direccion'] as String?,
      numeroCuenta: map['numero_cuenta'] as String?,
      departamentoId: map['departamento_id'] as String?,
      areaId: map['area_id'] as String?,
      puestoId: map['puesto_id'] as String?,
      fechaContratacion: fromTimestamp(map['fecha_contratacion']),
    );
  }

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
      'area_id': areaId,
      'puesto_id': puestoId,
      'fecha_contratacion': toTimestamp(fechaContratacion),
    };
  }
}
