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
  late final EmployeeDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController();
    _dataSource = EmployeeDataSource(
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 15, left: 15, right: 15),
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StreamBuilder<List<Employee>>(
            stream: _controller.empleadosStream,
            builder: (context, snapshot) {
              final empleados = snapshot.data ?? [];

              // Actualiza la data del dataSource y notifica listeners
              _dataSource.updateData(empleados);

              return PaginatedDataTable(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Empleados'),
                    CustomButton(
                      bgColor: Colors.green,
                      fgColor: Colors.white,
                      icono: const Icon(Icons.person_add),
                      btnTitle: "Crear",
                      onPressed: () async {
                        final nuevo = await showDialog<Employee?>(
                          context: context,
                          builder: (_) => const EmployeeForm(),
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
                rowsPerPage: 6,
                columns: const [
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

class EmployeeDataSource extends DataTableSource {
  EmployeeDataSource({
    required this.context,
    List<Employee>? empleados,
    required this.controller,
  }) : empleados = empleados ?? [];

  final BuildContext context;
  final EmployeeController controller;
  List<Employee> empleados;

  void updateData(List<Employee> nuevaLista) {
    empleados = nuevaLista;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= empleados.length) return null;
    final e = empleados[index];
    String formato(DateTime? d) =>
        d == null ? '-' : d.toLocal().toIso8601String().split('T')[0];
    return DataRow.byIndex(
      index: index,
      selected: false,
      cells: [
        DataCell(Text(e.nombre ?? '-')),
        DataCell(Text(e.codigoEmpleado ?? '-')),
        DataCell(Text(e.correo ?? '-')),
        DataCell(Text(e.telefono ?? '-')),
        DataCell(Text(e.estado ?? '-')),
        DataCell(Text(e.departamentoId ?? '-')),
        DataCell(Text(e.puestoId ?? '-')),
        DataCell(Text(formato(e.fechaContratacion))),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: 'Editar',
                onPressed: () async {
                  final actualizado = await showDialog<Employee?>(
                    context: context,
                    builder: (_) => EmployeeForm(employee: e),
                  );
                  if (actualizado != null) {
                    actualizado.id = e.id;
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
                        'Eliminar a ${e.nombre ?? 'este empleado'}?',
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
                  if (confirm == true && e.id != null) {
                    await controller.deleteEmployee(e.id!);
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
