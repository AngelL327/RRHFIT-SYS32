import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/views/empleado_form.dart';
import 'package:rrhfit_sys32/empleados/widgets/custom_button.dart';

class SecondSeccion extends StatefulWidget {
  const SecondSeccion({super.key});

  @override
  State<SecondSeccion> createState() => _SecondSeccionState();
}

class _SecondSeccionState extends State<SecondSeccion> {
  late final EmployeeController _controller;
  late final EmpleadosDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController();
    _dataSource = EmpleadosDataSource(
      context: context,
      empleados: [],
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            stream: _controller.empleadosStream,
            builder: (context, snapshot) {
              final empleados = snapshot.data ?? [];

              // Actualiza la data del dataSource y notifica listeners
              _dataSource.updateData(empleados);

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
                        final nuevo = await showDialog<Empleado?>(
                          context: context,
                          builder: (_) => const EmpleadoForm(),
                        );
                        if (nuevo != null) {
                          await _controller.createEmployee(nuevo);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Empleado creado')),
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
                  DataColumn(label: Text('Puesto')),
                  DataColumn(label: Text('Fecha Contratación')),
                  DataColumn(label: Text('Acciones')),
                ],
                source: _dataSource,
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
  final EmployeeController controller;
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
      selected: false,
      cells: [
        DataCell(Text(empleado.empleadoId ?? '-')),
        DataCell(Text(empleado.nombre ?? '-')),
        DataCell(Text(empleado.codigoEmpleado ?? '-')),
        DataCell(Text(empleado.correo ?? '-')),
        DataCell(Text(empleado.telefono ?? '-')),
        DataCell(
          (empleado.estado == "Activo")
              ? Icon(Icons.circle, color: Colors.green)
              : Icon(Icons.circle, color: Colors.red),
        ),
        DataCell(Text(empleado.departamentoId ?? '-')),
        DataCell(Text(empleado.puestoId ?? '-')),
        DataCell(Text(formato(empleado.fechaContratacion))),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: 'Editar',
                onPressed: () async {
                  final actualizado = await showDialog<Empleado?>(
                    context: context,
                    builder: (_) => EmpleadoForm(employee: empleado),
                  );
                  if (actualizado != null) {
                    actualizado.id = empleado.id;
                    await controller.updateEmployee(actualizado);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Empleado actualizado')),
                    );
                  }
                },
                icon: const Icon(Icons.edit),
                color: Colors.blue,
              ),
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
