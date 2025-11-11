// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/Reportes/historial_incapacidades_empleado_body.dart';
import 'package:rrhfit_sys32/core/document_preview.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/area_functions.dart';
import 'package:rrhfit_sys32/logic/empleados_functions.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
import 'package:rrhfit_sys32/logic/models/area_model.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';
import 'package:rrhfit_sys32/logic/models/empleado_row.dart';
import 'package:rrhfit_sys32/logic/utilities/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/widgets/alert_message.dart';


Widget buildDetallesDialog(BuildContext context, IncapacidadModel inc, {Function? setState}) {
  Size size = MediaQuery.of(context).size;
  return AlertDialog(
    title:  Text('Detalles de Incapacidad'),
    titleTextStyle: TextStyle(fontSize: 30),
    backgroundColor: AppTheme.cream,
    content: SingleChildScrollView(
      child: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.8,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Empleado: ${inc.usuario}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Tipo de solicitud: ${inc.tipoSolicitud}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Tipo de incapacidad: ${inc.tipoIncapacidad}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Fecha de Solicitud: ${formatDate(inc.fechaSolicitud)}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Fecha de Expediente: ${formatDate(inc.fechaExpediente)}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Fecha Inicio de Incapacidad: ${formatDate(inc.fechaInicioIncapacidad)}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Fecha Final de Incapacidad: ${formatDate(inc.fechaFinIncapacidad)}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Número de Certificado: ${inc.numCertificado}', style: AppTheme.lightTheme.textTheme.titleLarge,),
                    Text('Ente Emisor: ${inc.enteEmisor}', style: AppTheme.lightTheme.textTheme.titleLarge,),

                    if(inc.estado == EstadoSolicitud.aprobada)...[
                    Text('Estado de Solicitud: ${inc.estado}', 
                      style: AppTheme.lightTheme.textTheme.titleLarge!.copyWith(color: Colors.green.shade700),
                    )],

                    if(inc.estado == EstadoSolicitud.rechazada)...[
                    Text('Estado de Solicitud: ${inc.estado}', 
                      style: AppTheme.lightTheme.textTheme.titleLarge!.copyWith(color: Colors.red.shade700),
                    )],

                    if(inc.estado == EstadoSolicitud.pendiente)...[
                    Text('Estado de Solicitud: ${inc.estado}', 
                      style: AppTheme.lightTheme.textTheme.titleLarge!.copyWith(color: Colors.orange.shade700),
                    )],
                    SizedBox(
                      width: size.width * 0.3,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          TextField(
                            readOnly: true,
                            maxLines: 10,
                            decoration: InputDecoration(
                              labelText: 'Motivo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            controller: TextEditingController(text: inc.motivo),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(
              color: Colors.grey,
              thickness: 1,
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, size: 40, color: Colors.green.shade700,),
                          const SizedBox(width: 10,),
                          Text('Documento adjunto', style: AppTheme.lightTheme.textTheme.titleLarge,),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Preview box
                      Container(
                        height: size.height * 0.6,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: documentPreview(context, inc),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    
    actions: [
      Row(
      children: [
        Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
          width: size.width * 0.25,
          child: GenerateHistoriaIncapacidades(
            buttonLabel: "Descargar Historial de Incapacidad del Empleado",
            reportTitle: "Historial de Incapacidades",
            fetchData: () => _getHistIncRegistros(inc.userId),
              userData: () => _getUserDataRow(inc.userId),
            tableHeaders: [
            'Fecha Solicitud',
            'Tipo Incapacidad',
            'Emisor y Documento',
            'Fecha Inicio',
            'Fecha Fin',
            'Motivo',
            'Estado',
            ],
            rowMapper: (inc) {
            IncapacidadModel? incModel;
            if (inc is IncapacidadModel) {
              incModel = inc;
            } else if (inc is List && inc.isNotEmpty && inc[0] is IncapacidadModel) {
              incModel = inc[0] as IncapacidadModel;
            }

            if (incModel == null) return List<String>.filled(7, '');

            return [
              formatDate(incModel.fechaSolicitud),
              incModel.tipoIncapacidad,
              '${incModel.enteEmisor}\n#${incModel.numCertificado}',
              formatDate(incModel.fechaInicioIncapacidad),
              formatDate(incModel.fechaFinIncapacidad),
              incModel.motivo.length > 30 ? '${incModel.motivo.substring(0, 30)}...' : incModel.motivo,
              incModel.estado,
            ];
            },
          ),
          ),
        ],
        ),
        Expanded(child: Container()),
        if (inc.estado == EstadoSolicitud.pendiente || inc.estado == EstadoSolicitud.aprobada) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
              style: AppTheme.lightTheme.elevatedButtonTheme.style,
              onPressed: () async {
                // Rechazar
                try {
                await updateEstadoIncapacidad(inc.id, EstadoSolicitud.rechazada)
                  .then((val) {
                  if (val) {
                  Navigator.pop(context);
                  successScaffoldMsg(context, 'Solicitud rechazada exitosamente');
                  if (setState != null) {
                    setState();
                  }
                  } else {
                  Navigator.pop(context);
                  successScaffoldMsg(context, 'Error al rechazar la solicitud');
                  }
                });
                } catch (e) {
                Navigator.pop(context);
                successScaffoldMsg(context, 'Error al rechazar: $e');
                }
              },
              child: const Text('Rechazar'),
              ),
            ],
          ),
        ],
        SizedBox(width: 8),
        if (inc.estado == EstadoSolicitud.pendiente || inc.estado == EstadoSolicitud.aprobada) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
              style: AppTheme.lightTheme.elevatedButtonTheme.style,
              onPressed: () async {
                // Aprobar
                try {
                await updateEstadoIncapacidad(inc.id, EstadoSolicitud.aprobada)
                  .then((value) {
                  if (value) {
                  successScaffoldMsg(context, 'Solicitud aprobada exitosamente');
                  Navigator.pop(context);
                  if (setState != null) {
                    setState();
                  }
                  } else {
                  Navigator.pop(context);
                  successScaffoldMsg(context, 'Error al aprobar la solicitud');
                  }
                });
                } catch (e) {
                Navigator.pop(context);
                successScaffoldMsg(context, 'Error al aprobar: $e');
                }
              },
              child: const Text('Aprobar'),
              ),
            ],
          ),
          SizedBox(width: 8),

        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              style: AppTheme.lightTheme.elevatedButtonTheme.style,
              onPressed: () async {
              await deleteIncapacidad(inc.id)
                .then((value) {
                if (value) {
                Navigator.pop(context);
                successScaffoldMsg(context, 'Solicitud eliminada exitosamente');
                if (setState != null) {
                  setState();
                }
                } else {
                Navigator.pop(context);
                successScaffoldMsg(context, 'Error al eliminar la solicitud');
                }
              })
                .catchError((e) {
                Navigator.pop(context);
                successScaffoldMsg(context, 'Error al eliminar: $e');
              });
              },
              label: const Text('Eliminar'),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
          const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              style: AppTheme.lightTheme.elevatedButtonTheme.style,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ],
      ),
    ],
    
  );
}

  Future<List<dynamic>> _getHistIncRegistros(String empleadoID) async {
    List<dynamic> resultados = [];

    List<IncapacidadModel> incapacidades = await getIncapacidadesByEmpleadoId(empleadoID);
    for (var inc in incapacidades) {
      EmpleadoModel? empleado = await getEmpleadoById(inc.userId);
      if (empleado != null) {
        resultados.add([inc, empleado]);
      }
    }

    return resultados;
  }

  Future<List<dynamic>> _getUserData(String empleadoID) async {
    List<dynamic> resultados = [];
    EmpleadoModel? empleado = await getEmpleadoById(empleadoID);
    if (empleado != null) {
      AreaModel? area = await getAreaById(empleado.areaID);
      resultados.add(empleado);
      resultados.add(area);
    }
    return resultados;
  }

  // Adapter that returns a typed EmpleadoRow? for consumers that expect it
  Future<EmpleadoRow?> _getUserDataRow(String empleadoID) async {
    final empleado = await getEmpleadoById(empleadoID);
    if (empleado == null) return null;
    final area = await getAreaById(empleado.areaID);
    return EmpleadoRow(empleado: empleado, area: area);
  }
