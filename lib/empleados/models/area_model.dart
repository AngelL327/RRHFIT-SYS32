import 'package:cloud_firestore/cloud_firestore.dart';

class Area {
  String? id;
  String? areaId;
  String? departamentoId;
  String? nombre;
  String? codigo;

  Area({this.id, this.areaId, this.departamentoId, this.nombre, this.codigo});

  factory Area.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Area(
      id: doc.id,
      areaId: map['area_id'] as String?,
      departamentoId: map['departamento_id'] as String?,
      nombre: map['nombre'] as String?,
      codigo: map['codigo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area_id': areaId,
      'departamento_id': departamentoId,
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}
