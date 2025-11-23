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
  late final TextEditingController salario;
  late final TextEditingController numeroCuenta;

  DateTime? fechaNacimiento;
  DateTime? fechaContratacion;

  String? _selectedDepartamentoId;
  String? _selectedAreaId;
  String? _selectedPuestoId;

  bool _isSaving = false;

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
    salario = TextEditingController(text: empleado?.salario?.toString() ?? '');
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
    salario.dispose();
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

  bool esSoloNumeros(String str) {
    final RegExp regex = RegExp(r'^\d{8}$');
    return regex.hasMatch(str);
  }

  bool esSoloNumerosDNI(String str) {
    final RegExp regex = RegExp(r'^\d{13}$');
    return regex.hasMatch(str);
  }

  bool esMayorDeEdad(DateTime dob) {
    final today = DateTime.now();
    final fechaAdulto = DateTime(today.year - 18, today.month, today.day);
    return dob.isBefore(fechaAdulto) || dob.isAtSameMomentAs(fechaAdulto);
  }

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
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: "Lionel Andrés Messi Cuccittini",
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingrese nombre' : null,
                ),
                TextFormField(
                  controller: codigo,
                  decoration: const InputDecoration(
                    labelText: 'DNI',
                    hintText: "Ej: 0501199909283, Sin guiones ni espacios",
                  ),
                  validator: (v) {
                    final bool esNumeroDNI = esSoloNumerosDNI(v.toString());
                    if (v == null || v.isEmpty || !esNumeroDNI) {
                      return 'Ingrese DNI válido de 13 dígitos';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: correo,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          hintText: "Ej: correo@correo.com",
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty || !v.contains("@"))
                            return 'Ingrese correo';
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
                          hintText: "Ej: 95563530, sin guiones ni espacios",
                        ),
                        validator: (v) {
                          final bool esNumero = esSoloNumeros(v.toString());
                          if (v == null || v.isEmpty || !esNumero) {
                            return 'Ingrese teléfono';
                          }
                          return null;
                        },
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
                    hintText: "Ej: 744718183",
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
                TextFormField(
                  controller: salario,
                  decoration: const InputDecoration(
                    labelText: 'Salario',
                    hintText: "Ej: 5000.00",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
          onPressed: _isSaving
              ? null
              : () async {
                  final bool isEditing = widget.employee != null;

                  if (!formKey.currentState!.validate()) return;

                  if (!isEditing) {
                    if (fechaNacimiento == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleccione fecha de nacimiento'),
                          backgroundColor: Colors.yellow,
                        ),
                      );
                      return;
                    }
                    if (fechaContratacion == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleccione fecha de contratación'),
                          backgroundColor: Colors.yellow,
                        ),
                      );
                      return;
                    }
                    // nacimiento < contratación
                    if (!fechaNacimiento!.isBefore(fechaContratacion!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La fecha de nacimiento debe ser anterior a la fecha de contratación',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (fechaNacimiento != null && fechaContratacion != null) {
                      if (!fechaNacimiento!.isBefore(fechaContratacion!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La fecha de nacimiento debe ser anterior a la fecha de contratación',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    // edad >= 18 años
                    if (!esMayorDeEdad(fechaNacimiento!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El empleado debe tener al menos 18 años',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  } else {
                    if (fechaNacimiento != null && fechaContratacion != null) {
                      if (!fechaNacimiento!.isBefore(fechaContratacion!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La fecha de nacimiento debe ser anterior a la fecha de contratación',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (!esMayorDeEdad(fechaNacimiento!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El empleado debe tener al menos 18 años',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
                  }

                  // Common validations
                  if (_selectedDepartamentoId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seleccione un departamento'),
                      ),
                    );
                    return;
                  }
                  if (_selectedAreaId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione un área')),
                    );
                    return;
                  }
                  if (_selectedPuestoId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione un puesto')),
                    );
                    return;
                  }
                  if (estado.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione el estado')),
                    );
                    return;
                  }

                  if (salario.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingrese el salario'),
                        backgroundColor: Colors.yellow,
                      ),
                    );
                    return;
                  }

                  // salario deber ser un numero positivo
                  if (salario.text.trim().isNotEmpty) {
                    final salarioValue =
                        double.tryParse(salario.text.trim()) ?? -1.0;
                    if (salarioValue < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El salario debe ser un número válido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  setState(() => _isSaving = true);
                  try {
                    // Only check uniqueness when necessary:
                    final originalDni = widget.employee?.codigoEmpleado?.trim();
                    final originalEmail = widget.employee?.correo?.trim();
                    final currentDni = codigo.text.trim();
                    final currentEmail = correo.text.trim();

                    final needCheckDni =
                        !isEditing || (currentDni != originalDni);
                    final needCheckEmail =
                        !isEditing || (currentEmail != originalEmail);

                    if (needCheckEmail && currentEmail.isNotEmpty) {
                      final existeEmail = await widget.controller.checkEmail(
                        currentEmail,
                      );
                      if (existeEmail) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Este correo ya se encuentra en uso.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    }

                    if (needCheckDni && currentDni.isNotEmpty) {
                      final existe = await widget.controller.checkDNI(
                        currentDni,
                      );
                      if (existe) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El DNI del empleado ya existe.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    }

                    final newEmpleado = Empleado(
                      id: widget.employee?.id,
                      nombre: nombre.text.trim(),
                      codigoEmpleado: codigo.text.trim(),
                      fechaNacimiento: fechaNacimiento,
                      correo: correo.text.trim(),
                      telefono: telefono.text.trim(),
                      estado: estado.text.trim(),
                      direccion: direccion.text.trim(),
                      salario: double.tryParse(salario.text.trim()) ?? 0.0,
                      numeroCuenta: numeroCuenta.text.trim(),
                      departamentoId: _selectedDepartamentoId,
                      areaId: _selectedAreaId,
                      puestoId: _selectedPuestoId,
                      fechaContratacion: fechaContratacion,
                    );

                    if (mounted) Navigator.pop(context, newEmpleado);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al verificar el DNI o correo: $e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
