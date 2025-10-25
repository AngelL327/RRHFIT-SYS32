import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';

class EmployeeForm extends StatefulWidget {
  final Employee? employee;
  const EmployeeForm({super.key, this.employee});

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreC;
  late final TextEditingController _codigoC;
  late final TextEditingController _correoC;
  late final TextEditingController _telefonoC;
  late final TextEditingController _estadoC;
  late final TextEditingController _direccionC;
  late final TextEditingController _numeroCuentaC;
  late final TextEditingController _departamentoIdC;
  late final TextEditingController _areaIdC;
  late final TextEditingController _puestoIdC;

  DateTime? _fechaNacimiento;
  DateTime? _fechaContratacion;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nombreC = TextEditingController(text: e?.nombre ?? '');
    _codigoC = TextEditingController(text: e?.codigoEmpleado ?? '');
    _correoC = TextEditingController(text: e?.correo ?? '');
    _telefonoC = TextEditingController(text: e?.telefono ?? '');
    _estadoC = TextEditingController(text: e?.estado ?? '');
    _direccionC = TextEditingController(text: e?.direccion ?? '');
    _numeroCuentaC = TextEditingController(text: e?.numeroCuenta ?? '');
    _departamentoIdC = TextEditingController(text: e?.departamentoId ?? '');
    _areaIdC = TextEditingController(text: e?.areaId ?? '');
    _puestoIdC = TextEditingController(text: e?.puestoId ?? '');
    _fechaNacimiento = e?.fechaNacimiento;
    _fechaContratacion = e?.fechaContratacion;
  }

  @override
  void dispose() {
    _nombreC.dispose();
    _codigoC.dispose();
    _correoC.dispose();
    _telefonoC.dispose();
    _estadoC.dispose();
    _direccionC.dispose();
    _numeroCuentaC.dispose();
    _departamentoIdC.dispose();
    _areaIdC.dispose();
    _puestoIdC.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime?> onPicked,
  ) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
    );
    onPicked(result);
  }

  String _formatDate(DateTime? d) =>
      d == null ? '-' : d.toLocal().toIso8601String().split('T')[0];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.employee == null ? 'Crear empleado' : 'Editar empleado',
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreC,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingrese nombre' : null,
                ),
                TextFormField(
                  controller: _codigoC,
                  decoration: const InputDecoration(
                    labelText: 'Código empleado',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _correoC,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingrese correo';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoC,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _estadoC,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextFormField(
                  controller: _direccionC,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                TextFormField(
                  controller: _numeroCuentaC,
                  decoration: const InputDecoration(
                    labelText: 'Número de cuenta',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _departamentoIdC,
                        decoration: const InputDecoration(
                          labelText: 'Departamento ID',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _areaIdC,
                        decoration: const InputDecoration(labelText: 'Area ID'),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _puestoIdC,
                  decoration: const InputDecoration(labelText: 'Puesto ID'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(
                          context,
                          _fechaNacimiento,
                          (d) => setState(() => _fechaNacimiento = d),
                        ),
                        child: Text(
                          'Fecha Nac: ${_formatDate(_fechaNacimiento)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(
                          context,
                          _fechaContratacion,
                          (d) => setState(() => _fechaContratacion = d),
                        ),
                        child: Text(
                          'Fecha Contratación: ${_formatDate(_fechaContratacion)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final newEmp = Employee(
              id: widget.employee?.id,
              nombre: _nombreC.text.trim(),
              codigoEmpleado: _codigoC.text.trim(),
              fechaNacimiento: _fechaNacimiento,
              correo: _correoC.text.trim(),
              telefono: _telefonoC.text.trim(),
              estado: _estadoC.text.trim(),
              direccion: _direccionC.text.trim(),
              numeroCuenta: _numeroCuentaC.text.trim(),
              departamentoId: _departamentoIdC.text.trim(),
              areaId: _areaIdC.text.trim(),
              puestoId: _puestoIdC.text.trim(),
              fechaContratacion: _fechaContratacion,
            );
            Navigator.pop(context, newEmp);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
