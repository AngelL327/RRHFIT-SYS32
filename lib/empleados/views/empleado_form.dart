import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';
import 'package:rrhfit_sys32/empleados/models/departamento_model.dart';
import 'package:rrhfit_sys32/empleados/models/area_model.dart';
import 'package:rrhfit_sys32/empleados/models/puesto_model.dart';

class EmpleadoForm extends StatefulWidget {
  final Empleado? employee;
  final EmpleadoController controller;

  const EmpleadoForm({super.key, this.employee, required this.controller});

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

  DateTime? fechaNacimiento;
  DateTime? fechaContratacion;

  String? _selectedDepartamentoId;
  String? _selectedAreaId;
  String? _selectedPuestoId;

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

    fechaNacimiento = empleado?.fechaNacimiento;
    fechaContratacion = empleado?.fechaContratacion;

    _selectedDepartamentoId = empleado?.departamentoId;
    _selectedAreaId = empleado?.areaId;
    _selectedPuestoId = empleado?.puestoId;
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

  Widget _buildDepartamentoDropdown() {
    return StreamBuilder<List<Departamento>>(
      stream: widget.controller.departamentosStream,
      builder: (context, snap) {
        final list = snap.data ?? [];

        if (snap.connectionState == ConnectionState.waiting &&
            list.isEmpty &&
            widget.controller.departamentoMapa.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Departamento'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Cargando...'),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        final items =
            (list.isNotEmpty
                    ? list
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.nombre ?? '-'),
                            ),
                          )
                          .toList()
                    : widget.controller.departamentoMapa.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList())
                .where((it) => it.value != null)
                .toList();

        final hasSelected = items.any(
          (it) => it.value == _selectedDepartamentoId,
        );
        final valueToUse = hasSelected ? _selectedDepartamentoId : null;

        debugPrint(
          'FormDepartamento: selected=$_selectedDepartamentoId hasSelected=$hasSelected items=${items.length}',
        );

        if (items.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Departamento'),
            child: const Text('No hay departamentos disponibles'),
          );
        }

        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: valueToUse,
          items: items,
          onChanged: (v) {
            setState(() {
              _selectedDepartamentoId = v;
              _selectedAreaId = null;
            });
          },
          decoration: const InputDecoration(labelText: 'Departamento'),
        );
      },
    );
  }

  Widget _buildAreaDropdown() {
    return StreamBuilder<List<Area>>(
      stream: widget.controller.areasStream,
      builder: (context, snap) {
        final allAreas = snap.data ?? [];

        if (snap.connectionState == ConnectionState.waiting &&
            allAreas.isEmpty &&
            widget.controller.areaMapa.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Área'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Cargando...'),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        List<Area> usableAreas = [];
        if (allAreas.isNotEmpty) {
          usableAreas = _selectedDepartamentoId == null
              ? allAreas
              : allAreas
                    .where((a) => a.departamentoId == _selectedDepartamentoId)
                    .toList();
        } else {
          try {
            final fallback = widget.controller.lastAreas;
            usableAreas = _selectedDepartamentoId == null
                ? fallback
                : fallback
                      .where((a) => a.departamentoId == _selectedDepartamentoId)
                      .toList();
          } catch (_) {
            usableAreas = [];
          }
        }

        final items = usableAreas
            .map(
              (a) =>
                  DropdownMenuItem(value: a.id, child: Text(a.nombre ?? '-')),
            )
            .toList();
        final hasSelected = items.any((it) => it.value == _selectedAreaId);
        final valueToUse = hasSelected ? _selectedAreaId : null;

        debugPrint(
          'FormArea: selected=$_selectedAreaId hasSelected=$hasSelected items=${items.length} depto=$_selectedDepartamentoId',
        );

        if (items.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Área'),
            child: const Text('No hay áreas para este departamento'),
          );
        }

        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: valueToUse,
          items: items,
          onChanged: (v) => setState(() => _selectedAreaId = v),
          decoration: const InputDecoration(labelText: 'Área'),
        );
      },
    );
  }

  Widget _buildPuestoDropdown() {
    return StreamBuilder<List<Puesto>>(
      stream: widget.controller.puestosStream,
      builder: (context, snap) {
        final list = snap.data ?? [];

        if (snap.connectionState == ConnectionState.waiting &&
            list.isEmpty &&
            widget.controller.puestoMapa.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Puesto'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Cargando...'),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        final items =
            (list.isNotEmpty
                    ? list
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.nombre ?? '-'),
                            ),
                          )
                          .toList()
                    : widget.controller.puestoMapa.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList())
                .where((it) => it.value != null)
                .toList();

        final hasSelected = items.any((it) => it.value == _selectedPuestoId);
        final valueToUse = hasSelected ? _selectedPuestoId : null;

        debugPrint(
          'FormPuesto: selected=$_selectedPuestoId hasSelected=$hasSelected items=${items.length}',
        );

        if (items.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Puesto'),
            child: const Text('No hay puestos disponibles'),
          );
        }

        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: valueToUse,
          items: items,
          onChanged: (v) => setState(() => _selectedPuestoId = v),
          decoration: const InputDecoration(labelText: 'Puesto'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.employee == null ? 'Crear empleado' : 'Editar empleado',
      ),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 520,
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
                DropdownButtonFormField<String>(
                  value: estado.text.isEmpty ? null : estado.text,
                  items: const [
                    DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                    DropdownMenuItem(
                      value: 'Inactivo',
                      child: Text('Inactivo'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      estado.text = v ?? '';
                    });
                  },
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
                const SizedBox(height: 8),
                // dropdowns: Departamento, Area, Puesto
                Row(
                  children: [
                    Expanded(child: _buildDepartamentoDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAreaDropdown()),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPuestoDropdown(),
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
              departamentoId: _selectedDepartamentoId,
              areaId: _selectedAreaId,
              puestoId: _selectedPuestoId,
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
