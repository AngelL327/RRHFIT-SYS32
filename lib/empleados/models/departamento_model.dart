import 'package:cloud_firestore/cloud_firestore.dart';

class Departamento {
  String? id;
  String? departamentoId;
  String? nombre;
  String? codigo;

  Departamento({this.id, this.departamentoId, this.nombre, this.codigo});

  factory Departamento.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Departamento(
      id: doc.id,
      departamentoId: map['departamento_id'] as String?,
      nombre: map['nombre'] as String?,
      codigo: map['codigo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departamento_id': departamentoId,
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}
