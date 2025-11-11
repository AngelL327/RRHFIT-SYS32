import 'package:rrhfit_sys32/logic/models/area_model.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';

class EmpleadoRow {
  final EmpleadoModel empleado;
  final AreaModel? area;

  EmpleadoRow({
    required this.empleado,
    this.area,
  });
}