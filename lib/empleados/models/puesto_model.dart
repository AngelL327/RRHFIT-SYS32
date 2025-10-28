import 'package:cloud_firestore/cloud_firestore.dart';

class Puesto {
  String? id;
  String? puestoId;
  String? nombre;
  String? codigo;

  Puesto({this.id, this.puestoId, this.nombre, this.codigo});

  factory Puesto.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Puesto(
      id: doc.id,
      puestoId: map['puesto_id'] as String?,
      nombre: map['nombre'] as String?,
      codigo: map['codigo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'puesto_id': puestoId, 'nombre': nombre, 'codigo': codigo};
  }
}
