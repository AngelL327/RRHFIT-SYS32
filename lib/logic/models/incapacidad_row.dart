import 'package:rrhfit_sys32/logic/models/area_model.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';

class IncapacidadRow {
  final IncapacidadModel incapacidad;
  final EmpleadoModel? empleado;
  final AreaModel? area;

  IncapacidadRow({
    required this.incapacidad,
    required this.empleado,
    required this.area,
  });

  // Opcional: ayuda para convertir a lista si el PDF espera List<String>
  List<String> toStringList() {
    return [
      formatDate(incapacidad.fechaSolicitud),
      formatDate(incapacidad.fechaInicioIncapacidad),
      formatDate(incapacidad.fechaFinIncapacidad),
      incapacidad.tipoIncapacidad,
      incapacidad.estado,
      incapacidad.usuario,
      "${incapacidad.enteEmisor}\n#${incapacidad.numCertificado}",
      empleado?.correo ?? '',
      incapacidad.motivo.length > 30 ? '${incapacidad.motivo.substring(0, 30)}...' : incapacidad.motivo,
      area?.nombre ?? 'No asignada',
    ];
  }
}