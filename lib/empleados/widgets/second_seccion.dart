import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/views/empleado_detalle.dart';
import 'package:rrhfit_sys32/empleados/views/empleado_form.dart';
import 'package:rrhfit_sys32/empleados/widgets/custom_button.dart';

class SecondSeccion extends StatefulWidget {
  final EmpleadoController controller;
  const SecondSeccion({super.key, required this.controller});

  @override
  State<SecondSeccion> createState() => _SecondSeccionState();
}

class _SecondSeccionState extends State<SecondSeccion> {
  late final EmpleadosDataSource dataSource;

  @override
  void initState() {
    super.initState();
    dataSource = EmpleadosDataSource(
      context: context,
      empleados: [],
      controller: widget.controller,
    );
  }

  bool estado(String str) {
    if (str == "Activo") return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 15, left: 15, right: 15),
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StreamBuilder<List<Empleado>>(
            stream: widget.controller.empleadosStream,
            builder: (context, snapshot) {
              final empleados = snapshot.data ?? [];

              if (!listEquals(empleados, dataSource.empleados)) {
                dataSource.updateData(empleados);
              }

              return PaginatedDataTable(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Empleados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CustomButton(
                      bgColor: Colors.green,
                      fgColor: Colors.white,
                      icono: const Icon(Icons.person_add),
                      btnTitle: "Crear",
                      onPressed: () async {
                        try {
                          await widget.controller.ready;

                          final nuevo = await showDialog<Empleado?>(
                            context: context,
                            builder: (_) =>
                                EmpleadoForm(controller: widget.controller),
                          );
                          if (nuevo != null) {
                            await widget.controller.createEmployee(nuevo);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Empleado creado')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error al abrir formulario crear: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error inicializando datos'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                columnSpacing: 12,
                horizontalMargin: 12,
                headingRowHeight: 48,
                dataRowHeight: 52,
                rowsPerPage: 6,
                columns: const [
                  DataColumn(label: Text('EmpleadoID')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Correo')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Departamento')),
                  DataColumn(label: Text('Area')),
                  DataColumn(label: Text('Puesto')),
                  DataColumn(label: Text('Fecha Contratación')),
                  DataColumn(label: Text('Acciones')),
                ],
                source: dataSource,
              );
            },
          ),
        ],
      ),
    );
  }
}

class EmpleadosDataSource extends DataTableSource {
  EmpleadosDataSource({
    required this.context,
    List<Empleado>? empleados,
    required this.controller,
  }) : empleados = empleados ?? [];

  final BuildContext context;
  final EmpleadoController controller;
  List<Empleado> empleados;

  void updateData(List<Empleado> nuevaLista) {
    empleados = nuevaLista;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= empleados.length) return null;
    final empleado = empleados[index];
    String formato(DateTime? date) =>
        date == null ? '-' : date.toLocal().toIso8601String().split('T')[0];

    return DataRow.byIndex(
      index: index,
      // no manejamos selected persistente; permitimos seleccionar para abrir detalle
      selected: false,
      onSelectChanged: (selected) {
        if (selected == true) {
          // abrir pantalla detalle
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmpleadoDetalleScreen(
                empleado: empleado,
                controller: controller,
              ),
            ),
          );
        }
      },
      cells: [
        DataCell(Text(empleado.empleadoId ?? '-')),
        DataCell(Text(empleado.nombre ?? '-')),
        DataCell(Text(empleado.codigoEmpleado ?? '-')),
        DataCell(Text(empleado.correo ?? '-')),
        DataCell(Text(empleado.telefono ?? '-')),
        DataCell(
          (empleado.estado == "Activo")
              ? const Icon(Icons.circle, color: Colors.green)
              : const Icon(Icons.circle, color: Colors.red),
        ),
        DataCell(
          Text(
            controller.getDepartamentoNombre(empleado.departamentoId) ?? '-',
          ),
        ),
        DataCell(Text(controller.getAreaNombre(empleado.areaId) ?? '-')),
        DataCell(Text(controller.getPuestoNombre(empleado.puestoId) ?? '-')),
        DataCell(Text(formato(empleado.fechaContratacion))),
        DataCell(
          Row(
            children: [
              // Ver (abre detalle)
              IconButton(
                tooltip: 'Ver',
                icon: const Icon(Icons.visibility),
                color: Colors.grey[700],
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmpleadoDetalleScreen(
                        empleado: empleado,
                        controller: controller,
                      ),
                    ),
                  );
                },
              ),

              // Editar
              IconButton(
                tooltip: 'Editar',
                onPressed: () async {
                  try {
                    await controller.ready;
                    final actualizado = await showDialog<Empleado?>(
                      context: context,
                      builder: (_) => EmpleadoForm(
                        employee: empleado,
                        controller: controller,
                      ),
                    );
                    if (actualizado != null) {
                      actualizado.id = empleado.id;
                      await controller.updateEmployee(actualizado);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Empleado actualizado')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error al abrir formulario editar: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error inicializando datos'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit),
                color: Colors.blue,
              ),

              // Eliminar
              IconButton(
                tooltip: 'Eliminar',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirmar eliminación'),
                      content: Text(
                        'Eliminar a ${empleado.nombre ?? 'este empleado'}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && empleado.id != null) {
                    await controller.deleteEmployee(empleado.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Empleado eliminado')),
                    );
                  }
                },
                icon: const Icon(Icons.delete),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => empleados.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
