class TiposIncapacidades {
  static const String enfermedad = 'Enfermedad General';
  static const String accidenteLaboral = 'Accidente de Trabajo';
  static const String enfermedadOcupacional = 'Enfermedad Ocupacional';
  static const String maternidad = 'Maternidad';

  static List<String> getTipos() {
    return [
      enfermedad,
      accidenteLaboral,
      enfermedadOcupacional,
      maternidad
    ];
  }
}