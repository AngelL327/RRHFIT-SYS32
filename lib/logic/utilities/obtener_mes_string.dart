String getMonthString(int month) {
  const monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  if (month < 1 || month > 12) {
    throw ArgumentError('Month must be between 1 and 12');
  }

  return monthNames[month - 1];
}