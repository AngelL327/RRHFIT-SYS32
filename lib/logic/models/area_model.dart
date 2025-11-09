class AreaModel {
  String areaID;
  String codigo;
  String departamentoID;
  String nombre;

  AreaModel({
    required this.areaID,
    required this.codigo,
    required this.departamentoID,
    required this.nombre,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      areaID: json['area_id'] ?? 'N/A',
      codigo: json['codigo'] ?? 'N/A',
      departamentoID: json['departamento_id'] ?? 'N/A',
      nombre: json['nombre'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area_id': areaID,
      'codigo': codigo,
      'departamento_id': departamentoID,
      'nombre': nombre,
    };
  }
}