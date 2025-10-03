class Incapacidad {
  String? id;
  String motivo;
  String empleado;
  DateTime inicio;
  DateTime fin;
  String hospital;
  String documento;
  int diasAutorizados;
  bool completada;
  bool coberturaTotal;

  Incapacidad({
    this.id,
    required this.motivo,
    required this.empleado,
    required this.inicio,
    required this.fin,
    required this.hospital,
    required this.documento,
    required this.diasAutorizados,
    required this.completada,
    required this.coberturaTotal,
  });

  /// Convierte de Firebase → Dart
  factory Incapacidad.fromJson(Map<String, dynamic> json, {String? id}) {
    return Incapacidad(
      id: id,
      motivo: json['motivo'] ?? '',
      empleado: json['empleado'] ?? '',
      inicio: DateTime.parse(json['inicio']),
      fin: DateTime.parse(json['fin']),
      hospital: json['hospital'] ?? '',
      documento: json['documento'] ?? '',
      diasAutorizados: json['diasAutorizados'] ?? 0,
      completada: json['completada'] ?? false,
      coberturaTotal: json['coberturaTotal'] ?? false,
    );
  }

  /// Convierte de Dart → Firebase
  Map<String, dynamic> toFirebaseDatabase() {
    return {
      "motivo": motivo,
      "empleado": empleado,
      "inicio": inicio.toIso8601String(),
      "fin": fin.toIso8601String(),
      "hospital": hospital,
      "documento": documento,
      "diasAutorizados": diasAutorizados,
      "completada": completada,
      "coberturaTotal": coberturaTotal,
    };
  }
}
