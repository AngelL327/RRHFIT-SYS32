// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/empleados_functions.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
import 'package:rrhfit_sys32/logic/utilities/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_incapacidades.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_solicitudes.dart';
import 'package:rrhfit_sys32/widgets/alert_message.dart';

// New: extract the form into a reusable widget that can be embedded inside an AlertDialog
class AddIncapacidadForm extends StatefulWidget {
  const AddIncapacidadForm({super.key});

  @override
  State<AddIncapacidadForm> createState() => _AddIncapacidadFormState();
}

class _AddIncapacidadFormState extends State<AddIncapacidadForm> {
  final _formKey = GlobalKey<FormState>();

  // Removed controller for empleado dropdown — we use a selected model instead
  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _userIdCtrl = TextEditingController();
  String _tipoSolicitud = TipoSolicitud.incapacidad;
  String _tipoIncapacidad = TiposIncapacidades.enfermedad;
  final TextEditingController _numCertCtrl = TextEditingController();
  final TextEditingController _enteEmisorCtrl = TextEditingController();
  DateTime _fechaSolicitud = DateTime.now();
  DateTime? _fechaExpediente;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _estado = EstadoSolicitud.pendiente;
  final TextEditingController _motivoCtrl = TextEditingController();
  final TextEditingController _documentoCtrl = TextEditingController();
  EmpleadoModel? _selectedEmpleado;
  List<EmpleadoModel> _empleados = [];
  bool _loadingEmpleados = true;
  TextEditingController? _empleadoTextCtrl;

  @override
  void initState() {
    super.initState();
    final user = Global().currentUser;
    if (user != null) {
      _userIdCtrl.text = user.uid;
      _usuarioCtrl.text = user.displayName ?? user.email ?? '';
    }
    // Preload empleados for the dropdown so the widget does not need a FutureBuilder
    _loadEmpleados();
  }

  Future<void> _loadEmpleados() async {
    setState(() => _loadingEmpleados = true);
    try {
      final empleados = await getAllEmpleados();
      _empleados = empleados;
      // try to preselect an empleado matching the current user's email if available
      final currentEmail = Global().currentUser?.email;
      if (currentEmail != null && _selectedEmpleado == null) {
        final idx = _empleados.indexWhere((e) => e.correo.toLowerCase() == currentEmail.toLowerCase());
        if (idx != -1) _selectedEmpleado = _empleados[idx];
        // if the autocomplete controller exists, set its text
        if (_empleadoTextCtrl != null && _selectedEmpleado != null) {
          _empleadoTextCtrl!.text = _selectedEmpleado!.nombre;
        }
      }
    } catch (e) {
      // ignore errors here; the UI will show no empleados
      // ignore: avoid_print
      print('Error cargando empleados: $e');
    } finally {
      if (mounted) setState(() => _loadingEmpleados = false);
    }
  }

  @override
  void dispose() {
    _empleadoTextCtrl?.dispose();
    _usuarioCtrl.dispose();
    _userIdCtrl.dispose();
    _numCertCtrl.dispose();
    _enteEmisorCtrl.dispose();
    _motivoCtrl.dispose();
    _documentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, DateTime? initial, Function(DateTime) onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onPicked(picked);
  }

  // _getEmpleados removed; we preload empleados in initState using _loadEmpleados

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      errorScaffoldMsg(context, 'Por favor seleccione las fechas de inicio y fin de incapacidad');
      return;
    }
    if (_fechaInicio!.isAfter(_fechaFin!)) {
      errorScaffoldMsg(context, 'La fecha de inicio no puede ser posterior a la fecha final');
      return;
    }
    if(_numCertCtrl.text.trim().isEmpty){
      errorScaffoldMsg(context, 'Por favor ingrese el número de certificado');
      return;
    }

    if (_enteEmisorCtrl.text.trim().isEmpty) {
      errorScaffoldMsg(context, 'Por favor ingrese el ente emisor');
      return;
    }

    final inc = IncapacidadModel(
      id: '',
      userId: _selectedEmpleado?.empleadoID ?? (_userIdCtrl.text.trim().isEmpty ? 'N/A' : _userIdCtrl.text.trim()),
      usuario: _selectedEmpleado?.nombre ?? (_usuarioCtrl.text.trim().isEmpty ? 'N/A' : _usuarioCtrl.text.trim()),
      tipoSolicitud: _tipoSolicitud,
      tipoIncapacidad: _tipoIncapacidad.trim().isEmpty ? 'N/A' : _tipoIncapacidad.trim(),
      numCertificado: _numCertCtrl.text.trim().isEmpty ? 'N/A' : _numCertCtrl.text.trim(),
      enteEmisor: _enteEmisorCtrl.text.trim().isEmpty ? 'N/A' : _enteEmisorCtrl.text.trim(),
      fechaSolicitud: _fechaSolicitud,
      fechaExpediente: _fechaExpediente ?? _fechaSolicitud,
      fechaInicioIncapacidad: _fechaInicio!,
      fechaFinIncapacidad: _fechaFin!,
      estado: _estado,
      motivo: _motivoCtrl.text.trim().isEmpty ? 'N/A' : _motivoCtrl.text.trim(),
      documentoUrl: _documentoCtrl.text.trim(),
    );

    final success = await addIncapacidad(inc);
    if (success) {
      successScaffoldMsg(context, 'Incapacidad creada correctamente');
      Navigator.of(context).pop(true);
    } else {
      errorScaffoldMsg(context, 'Error al crear la incapacidad');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a constrained SingleChildScrollView so this can be placed inside AlertDialog content
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.5,
      height: size.height * 0.7,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadingEmpleados)
                  const Center(child: CircularProgressIndicator())
                else if (_empleados.isEmpty)
                  const Text('No se encontraron empleados')
                else
                  Autocomplete<EmpleadoModel>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        // show all when empty
                        return _empleados;
                      }
                      return _empleados.where((EmpleadoModel e) =>
                          e.nombre.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (EmpleadoModel e) => e.nombre,
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // store the controller so we can prefill it after loading
                      _empleadoTextCtrl = textEditingController;
                      // if we preselected an empleado earlier, ensure the controller shows it
                      if (_selectedEmpleado != null && textEditingController.text.isEmpty) {
                        textEditingController.text = _selectedEmpleado!.nombre;
                      }
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Empleado'),
                        validator: (v) => _selectedEmpleado == null ? 'Seleccione un empleado' : null,
                      );
                    },
                    onSelected: (EmpleadoModel selection) {
                      setState(() {
                        _selectedEmpleado = selection;
                        _empleadoTextCtrl?.text = selection.nombre;
                      });
                    },
                  ),
                const SizedBox(height: 8),
                // DropdownButtonFormField<String>(
                //   initialValue: _tipoSolicitud,
                //   items: [TipoSolicitud.incapacidad, TipoSolicitud.permiso, TipoSolicitud.vacaciones, TipoSolicitud.otro]
                //       .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                //       .toList(),
                //   onChanged: (v) => setState(() => _tipoSolicitud = v ?? TipoSolicitud.incapacidad),
                //   decoration: const InputDecoration(labelText: 'Tipo de solicitud'),
                // ),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  initialValue: _tipoIncapacidad,
                  items: TiposIncapacidades.getTipos().map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _tipoIncapacidad = v ?? TiposIncapacidades.enfermedad),
                  decoration: const InputDecoration(labelText: 'Tipo de incapacidad'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numCertCtrl,
                  decoration: const InputDecoration(labelText: 'Número de certificado'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _enteEmisorCtrl,
                  decoration: const InputDecoration(labelText: 'Ente emisor'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha de solicitud'),
                  subtitle: Text('${_fechaSolicitud.toLocal()}'.split(' ')[0]),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, _fechaSolicitud, (d) => setState(() => _fechaSolicitud = d)),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha de expediente'),
                  subtitle: Text(_fechaExpediente != null ? '${_fechaExpediente!.toLocal()}'.split(' ')[0] : 'No asignada'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, _fechaExpediente, (d) => setState(() => _fechaExpediente = d)),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha inicio de incapacidad'),
                  subtitle: Text(_fechaInicio != null ? '${_fechaInicio!.toLocal()}'.split(' ')[0] : 'No asignada'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, _fechaInicio, (d) => setState(() => _fechaInicio = d)),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha fin de incapacidad'),
                  subtitle: Text(_fechaFin != null ? '${_fechaFin!.toLocal()}'.split(' ')[0] : 'No asignada'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, _fechaFin, (d) => setState(() => _fechaFin = d)),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  items: [EstadoSolicitud.pendiente, EstadoSolicitud.aprobada, EstadoSolicitud.rechazada]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _estado = v ?? EstadoSolicitud.pendiente),
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motivoCtrl,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese motivo' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _documentoCtrl,
                  decoration: const InputDecoration(labelText: 'URL de documento (opcional)'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: AppTheme.lightTheme.elevatedButtonTheme.style,
                      onPressed: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        child: Text('Guardar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper to show the Add Incapacidad form inside an AlertDialog.
Future<bool?> showAddIncapacidadDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        
        title: const Text('Nueva Incapacidad'),
        content: const AddIncapacidadForm(),
      );
    },
  );
}
