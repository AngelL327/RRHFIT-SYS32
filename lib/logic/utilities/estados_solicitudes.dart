String estadoSolicitud(String estado){
switch(estado.toLowerCase()){
  case 'pendiente':
    return 'Pendiente';
  case 'aprobada':
    return 'Aprobada';
  case 'rechazada':
    return 'Rechazada';
  default:
    return 'Desconocido';
}
}

class EstadoSolicitud {

  static String get pendiente => 'Pendiente';
  static String get aprobada => 'Aprobada';
  static String get rechazada => 'Rechazada';
}