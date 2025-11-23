// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:flutter/services.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/empleados_functions.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
import 'package:rrhfit_sys32/logic/utilities/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_incapacidades.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_solicitudes.dart';
import 'package:rrhfit_sys32/widgets/alert_message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rrhfit_sys32/logic/utilities/documentos_supabase.dart';
import 'dart:typed_data';

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
  // Document upload state (replaces the previous URL text input)
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _uploadedFilePath;
  String? _documentPublicUrl; // will be assigned after upload and saved to the model
  bool _uploadingDocument = false;
  EmpleadoModel? _selectedEmpleado;
  List<EmpleadoModel> _empleados = [];
  Future<List<EmpleadoModel>>? _empleadosFuture;
  String _empleadoTyped = '';
  bool _submitting = false;
  String? _asyncError; // errors from async checks (overlap, duplicate)
  bool _autoSelectedInitialized = false;

  @override
  void initState() {
    super.initState();
    final user = Global().currentUser;
    if (user != null) {
      _userIdCtrl.text = user.uid;
      _usuarioCtrl.text = user.displayName ?? user.email ?? '';
    }
    // prepare future to load empleados; UI will use a FutureBuilder
    _empleadosFuture = getAllEmpleados();
  }

  // we use [_empleadosFuture] + FutureBuilder in build instead of a manual loader

  @override
  void dispose() {
    // we don't own the Autocomplete controller; nothing to dispose here
    _usuarioCtrl.dispose();
    _userIdCtrl.dispose();
    _numCertCtrl.dispose();
    _enteEmisorCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadDocument() async {
    setState(() {
      _asyncError = null;
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png'],
      withData: true,
    );
    if (result == null) return; // user cancelled
    final file = result.files.first;
    final bytes = file.bytes;
    final name = file.name;
    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileName = name;
      _uploadingDocument = true;
    });

    try {
      if (bytes == null) throw Exception('No se obtuvieron datos del archivo (withData==true pendiente)');
      final path = 'Incapacidades/${DateTime.now().millisecondsSinceEpoch}_$name';
      final url = await uploadDocumentToSupabase(bytes, path, bucket: 'Reportes', makePublic: true);
      setState(() {
        _uploadedFilePath = path;
        _documentPublicUrl = url;
      });
    } catch (e) {
      setState(() => _asyncError = 'Error subiendo archivo: $e');
    } finally {
      setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _removeSelectedDocument() async {
    // If the file was already uploaded to Supabase, try to delete it from storage
    if (_uploadedFilePath != null) {
      setState(() {
        _uploadingDocument = true;
        _asyncError = null;
      });
      try {
        final deleted = await deleteDocumentFromSupabase(_uploadedFilePath!);
        if (!deleted) {
          setState(() => _asyncError = 'No se pudo eliminar el archivo en el servidor');
        }
      } catch (e) {
        setState(() => _asyncError = 'Error eliminando archivo en servidor: $e');
      } finally {
        // Clear local selection regardless; keep error visible if any
        setState(() {
          _selectedFileBytes = null;
          _selectedFileName = null;
          _uploadedFilePath = null;
          _documentPublicUrl = null;
          _uploadingDocument = false;
        });
      }
    } else {
      // Not uploaded yet: just clear local selection
      setState(() {
        _selectedFileBytes = null;
        _selectedFileName = null;
        _uploadedFilePath = null;
        _documentPublicUrl = null;
        _asyncError = null;
      });
    }
  }

  Future<void> _pickDate(BuildContext ctx, DateTime? initial, Function(DateTime) onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial ?? now,
      // Restrict selectable dates to a reasonable window: not more than 1 year in the past
      // and not more than 1 year in the future from today.
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) onPicked(picked);
  }

  // _getEmpleados removed; we preload empleados in initState using _loadEmpleados

  Future<void> _submit() async {
    // If user typed a name but didn't pick from the autocomplete list,
    // try to match it to an empleado by name. Require selecting an existing
    // empleado when the empleados list is available.
    if (_selectedEmpleado == null) {
      final typed = _empleadoTyped.trim();
      if (_empleados.isNotEmpty) {
        // If there are empleados to choose from, the user must select one
        if (typed.isEmpty) {
          setState(() => _asyncError = 'Seleccione un empleado existente antes de guardar');
          return;
        }
        final idx = _empleados.indexWhere((e) => e.nombre.toLowerCase() == typed.toLowerCase());
        if (idx == -1) {
          setState(() => _asyncError = 'Empleado no encontrado. Seleccione un empleado existente de la lista');
          return;
        }
        _selectedEmpleado = _empleados[idx];
      } else {
        // If no empleados are loaded, fall back to using the current user id/text fields.
        // Leave _selectedEmpleado null; later checks will allow using _userIdCtrl as fallback.
      }
    }

    // Run synchronous validators first (field validators)
    if (!_formKey.currentState!.validate()) return;

    // Validate date presence and ordering. Fecha de expediente is required.
    if (_fechaExpediente == null) {
      setState(() => _asyncError = 'Por favor seleccione la fecha de expediente');
      return;
    }
    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _asyncError = 'Por favor seleccione las fechas de inicio y fin de incapacidad');
      return;
    }
    if (_fechaInicio!.isAfter(_fechaFin!)) {
      setState(() => _asyncError = 'La fecha de inicio no puede ser posterior a la fecha final');
      return;
    }

    // Validate date range: not more than 1 year in the past or future from today
    final now = DateTime.now();
    final earliest = DateTime(now.year - 1, now.month, now.day);
    final latest = DateTime(now.year + 1, now.month, now.day);
    if (_fechaExpediente!.isBefore(earliest) || _fechaExpediente!.isAfter(latest) || _fechaInicio!.isBefore(earliest) || _fechaFin!.isBefore(earliest) || _fechaInicio!.isAfter(latest) || _fechaFin!.isAfter(latest)) {
      setState(() => _asyncError = 'Las fechas deben estar dentro de un año hacia atrás y un año hacia adelante desde hoy');
      return;
    }
  // Trim inputs and enforce length limits before further checks
  String numCert = _numCertCtrl.text.trim();
  String enteEmisor = _enteEmisorCtrl.text.trim();
  String motivo = _motivoCtrl.text.trim();
  // Use uploaded document URL if present (file picker replaces URL input)
  String documento = _documentPublicUrl?.trim() ?? '';

    // Length truncation
    if (motivo.length > 256) motivo = motivo.substring(0, 256);
    if (enteEmisor.length > 64) enteEmisor = enteEmisor.substring(0, 64);
    if (numCert.length > 8) numCert = numCert.substring(0, 8);

    // Reassign trimmed/truncated values back to controllers so UI reflects them
    _numCertCtrl.text = numCert;
    _enteEmisorCtrl.text = enteEmisor;
  _motivoCtrl.text = motivo;

    // Basic presence checks (validators already cover some, double-check)
    if (numCert.isEmpty) {
      setState(() => _asyncError = 'Por favor ingrese el número de certificado');
      return;
    }
    if (enteEmisor.isEmpty) {
      setState(() => _asyncError = 'Por favor ingrese el ente emisor');
      return;
    }
    if (_empleados.isNotEmpty && _selectedEmpleado == null) {
      setState(() => _asyncError = 'El empleado seleccionado no es válido');
      return;
    }

    // numCert pattern: digits only, length between 4 and 8
    final digitsOnly = RegExp(r'^\d{4,8}$');
    if (!digitsOnly.hasMatch(numCert)) {
      setState(() => _asyncError = 'El número de certificado debe contener sólo dígitos (4-8 caracteres)');
      return;
    }

    // Before creating, perform async business checks: overlap and duplicates
    setState(() {
      _asyncError = null;
      _submitting = true;
    });

    try {
      // fetch existing incapacidades for employee (if we have an id)
      final empleadoId = _selectedEmpleado?.empleadoID ?? _userIdCtrl.text.trim();
      if (empleadoId.isNotEmpty) {
        final existing = await getIncapacidadesByEmpleadoId(empleadoId);
        // check overlap
        final overlaps = existing.where((e) {
          final aStart = e.fechaInicioIncapacidad;
          final aEnd = e.fechaFinIncapacidad;
          final bStart = _fechaInicio!;
          final bEnd = _fechaFin!;
          // intervals [aStart,aEnd] and [bStart,bEnd] intersect iff
          return !(aEnd.isBefore(bStart) || aStart.isAfter(bEnd));
        }).toList();
        if (overlaps.isNotEmpty) {
          setState(() {
            _asyncError = 'La incapacidad solapa con otra registrada para este empleado';
            _submitting = false;
          });
          return;
        }
        // check duplicate certificate recently used (same certificate number)
        final dup = existing.where((e) => e.numCertificado.trim() == numCert).toList();
        if (dup.isNotEmpty) {
          setState(() {
            _asyncError = 'El número de certificado ya está registrado para este empleado';
            _submitting = false;
          });
          return;
        }
      }

      final inc = IncapacidadModel(
      id: '',
      userId: _selectedEmpleado?.empleadoID ?? (_userIdCtrl.text.trim().isEmpty ? 'N/A' : _userIdCtrl.text.trim()),
      usuario: _selectedEmpleado?.nombre ?? (_usuarioCtrl.text.trim().isEmpty ? 'N/A' : _usuarioCtrl.text.trim()),
      tipoSolicitud: _tipoSolicitud,
      tipoIncapacidad: _tipoIncapacidad.trim().isEmpty ? 'N/A' : _tipoIncapacidad.trim(),
      numCertificado: numCert.isEmpty ? 'N/A' : numCert,
      enteEmisor: enteEmisor.isEmpty ? 'N/A' : enteEmisor,
      fechaSolicitud: _fechaSolicitud,
      fechaExpediente: _fechaExpediente!,
      fechaInicioIncapacidad: _fechaInicio!,
      fechaFinIncapacidad: _fechaFin!,
      estado: _estado,
      motivo: motivo.isEmpty ? 'N/A' : motivo,
      documentoUrl: documento,
    );
      final success = await addIncapacidad(inc);
      if (success) {
        successScaffoldMsg(context, 'Incapacidad creada correctamente');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _asyncError = 'Error al crear la incapacidad');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a constrained SingleChildScrollView so this can be placed inside AlertDialog content
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.5,
      height: size.height * 0.85,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<EmpleadoModel>>(
                  future: _empleadosFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Text('Error cargando empleados: ${snap.error}');
                    }
                    final empleados = snap.data ?? [];
                    // keep a local copy for submit-time decisions
                    _empleados = empleados;
                    if (empleados.isEmpty) return const Text('No se encontraron empleados');
                    // If not yet initialized, auto-select the first empleado without calling setState
                    // to avoid marking widgets dirty during build. We'll update the Autocomplete controller
                    // later inside its fieldViewBuilder.
                    if (!_autoSelectedInitialized && _selectedEmpleado == null && empleados.isNotEmpty) {
                      _selectedEmpleado = empleados.first;
                      _empleadoTyped = empleados.first.nombre;
                      _autoSelectedInitialized = true;
                    }
                    return Autocomplete<EmpleadoModel>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          // show all when empty
                          return empleados;
                        }
                        return empleados.where((EmpleadoModel e) =>
                            e.nombre.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      displayStringForOption: (EmpleadoModel e) => e.nombre,
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        // ensure the controller reflects the typed/selected value
                        // (do this after the frame to avoid mutating the controller during build)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (_empleadoTyped.isNotEmpty && textEditingController.text != _empleadoTyped) {
                            textEditingController.text = _empleadoTyped;
                            textEditingController.selection = TextSelection.collapsed(offset: _empleadoTyped.length);
                          }
                        });
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Empleado'),
                                SizedBox(width: 4),
                                Text('*', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          // keep track of what's typed so we can try to match on submit
                          onChanged: (v) => _empleadoTyped = v,
                          // validator ensures an empleado is chosen when empleados exist
                          validator: (v) {
                            if (_empleados.isNotEmpty && _selectedEmpleado == null) {
                              final typed = v?.trim() ?? '';
                              if (typed.isEmpty) return 'Seleccione un empleado';
                              final idx = _empleados.indexWhere((e) => e.nombre.toLowerCase() == typed.toLowerCase());
                              if (idx == -1) return 'Seleccione un empleado válido';
                            }
                            return null;
                          },
                        );
                      },
                      onSelected: (EmpleadoModel selection) {
                        setState(() {
                          _selectedEmpleado = selection;
                          _empleadoTyped = selection.nombre;
                        });
                      },
                    );
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
                  decoration: InputDecoration(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Número de certificado'),
                        SizedBox(width: 4),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Ingrese el número de certificado';
                    if (s.length < 4 || s.length > 8) return 'Deben ser 4-8 dígitos';
                    if (int.tryParse(s) == null) return 'El número debe contener sólo dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _enteEmisorCtrl,
                  decoration: InputDecoration(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Ente emisor'),
                        SizedBox(width: 4),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Ingrese el ente emisor';
                    if (s.length > 64) return 'Máximo 64 caracteres';
                    return null;
                  },
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
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Fecha de expediente'),
                      SizedBox(width: 4),
                      Text('*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  subtitle: Text(_fechaExpediente != null ? '${_fechaExpediente!.toLocal()}'.split(' ')[0] : 'No asignada'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, _fechaExpediente, (d) => setState(() => _fechaExpediente = d)),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Fecha inicio de incapacidad'),
                      SizedBox(width: 4),
                      Text('*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  subtitle: Text(_fechaInicio != null ? '${_fechaInicio!.toLocal()}'.split(' ')[0] : 'No asignada'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, _fechaInicio, (d) => setState(() => _fechaInicio = d)),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Fecha fin de incapacidad'),
                      SizedBox(width: 4),
                      Text('*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
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
                  decoration: InputDecoration(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Motivo'),
                        SizedBox(width: 4),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  maxLines: 4,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Ingrese motivo';
                    if (s.length < 5) return 'El motivo debe tener al menos 5 caracteres';
                    if (s.length > 256) return 'Máximo 256 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // File picker & upload (only PDF or PNG). Uploaded file public URL is stored in
                // _documentPublicUrl and will be saved to the model as documentoUrl.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _uploadingDocument ? null : _pickAndUploadDocument,
                          icon: const Icon(Icons.attach_file),
                          label: Text(_selectedFileName == null ? 'Seleccionar archivo (pdf/png)' : 'Cambiar archivo'),
                        ),
                        const SizedBox(width: 8),
                        if (_uploadingDocument) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        if (_selectedFileName != null) ...[
                          const SizedBox(width: 8),
                          Text(_selectedFileName!, style: const TextStyle(fontStyle: FontStyle.italic)),
                          IconButton(onPressed: _removeSelectedDocument, icon: const Icon(Icons.delete, color: Colors.red)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedFileBytes != null && _selectedFileName != null && _selectedFileName!.toLowerCase().endsWith('.png'))
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.memory(_selectedFileBytes!, fit: BoxFit.cover),
                      ),
                    if (_documentPublicUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SelectableText('Archivo subido: $_documentPublicUrl', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_asyncError != null) ...[
                  Text(_asyncError!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
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
                      // Disable submit while saving or while a document upload/delete is in progress
                      onPressed: (_submitting || _uploadingDocument) ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        child: (_submitting || _uploadingDocument)
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Guardar', style: TextStyle(fontSize: 16)),
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
