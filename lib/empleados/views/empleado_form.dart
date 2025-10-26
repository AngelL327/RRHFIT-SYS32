import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';

class EmpleadoForm extends StatefulWidget {
  final Empleado? employee;
  const EmpleadoForm({super.key, this.employee});

  @override
  State<EmpleadoForm> createState() => _EmpleadoFormState();
}

class _EmpleadoFormState extends State<EmpleadoForm> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nombre;
  late final TextEditingController codigo;
  late final TextEditingController correo;
  late final TextEditingController telefono;
  late final TextEditingController estado;
  late final TextEditingController direccion;
  late final TextEditingController numeroCuenta;
  late final TextEditingController departamentoId;
  late final TextEditingController areaId;
  late final TextEditingController puestoId;

  DateTime? fechaNacimiento;
  DateTime? fechaContratacion;

  @override
  void initState() {
    super.initState();
    final empleado = widget.employee;
    nombre = TextEditingController(text: empleado?.nombre ?? '');
    codigo = TextEditingController(text: empleado?.codigoEmpleado ?? '');
    correo = TextEditingController(text: empleado?.correo ?? '');
    telefono = TextEditingController(text: empleado?.telefono ?? '');
    estado = TextEditingController(text: empleado?.estado ?? '');
    direccion = TextEditingController(text: empleado?.direccion ?? '');
    numeroCuenta = TextEditingController(text: empleado?.numeroCuenta ?? '');
    departamentoId = TextEditingController(
      text: empleado?.departamentoId ?? '',
    );
    areaId = TextEditingController(text: empleado?.areaId ?? '');
    puestoId = TextEditingController(text: empleado?.puestoId ?? '');
    fechaNacimiento = empleado?.fechaNacimiento;
    fechaContratacion = empleado?.fechaContratacion;
  }

  @override
  void dispose() {
    nombre.dispose();
    codigo.dispose();
    correo.dispose();
    telefono.dispose();
    estado.dispose();
    direccion.dispose();
    numeroCuenta.dispose();
    departamentoId.dispose();
    areaId.dispose();
    puestoId.dispose();
    super.dispose();
  }

  Future<void> pickDate(
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

  String formatoDate(DateTime? d) =>
      d == null ? '-' : d.toLocal().toIso8601String().split('T')[0];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.employee == null ? 'Crear empleado' : 'Editar empleado',
      ),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingrese nombre' : null,
                ),
                TextFormField(
                  controller: codigo,
                  decoration: const InputDecoration(
                    labelText: 'Código empleado',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: correo,
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
                        controller: telefono,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextFormField(
                  controller: direccion,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                TextFormField(
                  controller: numeroCuenta,
                  decoration: const InputDecoration(
                    labelText: 'Número de cuenta',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: departamentoId,
                        decoration: const InputDecoration(
                          labelText: 'Departamento ID',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: areaId,
                        decoration: const InputDecoration(labelText: 'Area ID'),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: puestoId,
                  decoration: const InputDecoration(labelText: 'Puesto ID'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => pickDate(
                          context,
                          fechaNacimiento,
                          (d) => setState(() => fechaNacimiento = d),
                        ),
                        child: Text(
                          'Fecha Nac: ${formatoDate(fechaNacimiento)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => pickDate(
                          context,
                          fechaContratacion,
                          (d) => setState(() => fechaContratacion = d),
                        ),
                        child: Text(
                          'Fecha Contratación: ${formatoDate(fechaContratacion)}',
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
            if (!formKey.currentState!.validate()) return;
            final newEmpleado = Empleado(
              id: widget.employee?.id,
              nombre: nombre.text.trim(),
              codigoEmpleado: codigo.text.trim(),
              fechaNacimiento: fechaNacimiento,
              correo: correo.text.trim(),
              telefono: telefono.text.trim(),
              estado: estado.text.trim(),
              direccion: direccion.text.trim(),
              numeroCuenta: numeroCuenta.text.trim(),
              departamentoId: departamentoId.text.trim(),
              areaId: areaId.text.trim(),
              puestoId: puestoId.text.trim(),
              fechaContratacion: fechaContratacion,
            );
            Navigator.pop(context, newEmpleado);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
