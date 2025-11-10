class AsistenciaPerfectaItem {
  final String rankingLabel;
  final String nombre;
  final String codigo;
  final String puesto;
  final String fechaContratacion;
  final String diasAsistidos;
  final double porcentaje;

  const AsistenciaPerfectaItem({
    required this.rankingLabel,
    required this.nombre,
    required this.codigo,
    required this.puesto,
    required this.fechaContratacion,
    required this.diasAsistidos,
    required this.porcentaje,
  });

  /// Constructor factory que crea un item a partir de un Map
  factory AsistenciaPerfectaItem.fromMap(Map<String, dynamic> map) {
    return AsistenciaPerfectaItem(
      rankingLabel: map['rankingLabel'] as String? ?? 'N/A',
      nombre: map['nombre'] as String? ?? 'Desconocido',
      codigo: map['codigo'] as String? ?? 'N/A',
      puesto: map['puesto'] as String? ?? 'N/A',
      fechaContratacion: map['fechaContratacion'] as String? ?? 'N/A',
      diasAsistidos: map['diasAsistidos'] as String? ?? 'N/A',
      porcentaje: (map['porcentaje'] is num)
          ? (map['porcentaje'] as num).toDouble()
          : 0.0,
    );
  }
}

List<AsistenciaPerfectaItem> generateDummyData() {
  return List.generate(
    5,
    (i) => AsistenciaPerfectaItem(
      rankingLabel: '${i + 1}°',
      nombre: 'Empleado ${i + 1}',
      codigo: 'A00${i + 1}',
      puesto: 'Gerente de IT',
      fechaContratacion: '26 / 07 / 2010',
      diasAsistidos: '${22 - i} / 22',
      porcentaje: (99 - i).toDouble(),
    ),
  );
}
