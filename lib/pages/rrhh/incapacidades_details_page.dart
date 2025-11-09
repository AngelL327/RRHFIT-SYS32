// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/document_preview.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
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
      if (inc.estado == EstadoSolicitud.pendiente || inc.estado == EstadoSolicitud.aprobada) ...[
        TextButton(
          style: AppTheme.lightTheme.elevatedButtonTheme.style,
          onPressed: () async {
            // Rechazar
            try {
              await updateEstadoIncapacidad(inc.id, EstadoSolicitud.rechazada)
              .then((val){
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
      if (inc.estado == EstadoSolicitud.pendiente || inc.estado == EstadoSolicitud.aprobada) ...[
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
                  }else {
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
      TextButton(
          style: AppTheme.lightTheme.elevatedButtonTheme.style,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  );
}
