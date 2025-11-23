import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
import 'package:rrhfit_sys32/logic/utilities/estados_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/tipos_solicitudes.dart';
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/utilities/documentos_supabase.dart';

class SolicitudesEmpleadoPage extends StatefulWidget {
  final String empleadoId; // ID del empleado actual
  final String empleadoNombre;
  final String empleadoUid; // UID del empleado

  const SolicitudesEmpleadoPage({
    required this.empleadoId,
    required this.empleadoNombre,
    required this.empleadoUid,
    super.key,
  });

  @override
  State<SolicitudesEmpleadoPage> createState() =>
      _SolicitudesEmpleadoPageState();
}

class _SolicitudesEmpleadoPageState extends State<SolicitudesEmpleadoPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _motivoCtrl = TextEditingController();
  final _numCertificadoCtrl = TextEditingController();
  final _enteEmisorCtrl = TextEditingController();

  String _tipoIncapacidad = "Enfermedad común";
  DateTime _fechaExpediente = DateTime.now();
  DateTime _fechaInicioIncapacidad = DateTime.now();
  DateTime _fechaFinIncapacidad = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  // Para el archivo
  Uint8List? _archivoBytes;
  String? _nombreArchivo;

  final List<String> _tiposIncapacidad = [
    "Enfermedad común",
    "Maternidad",
    "Accidente laboral",
    "Riesgo profesional",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _motivoCtrl.dispose();
    _numCertificadoCtrl.dispose();
    _enteEmisorCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _archivoBytes = result.files.first.bytes;
          _nombreArchivo = result.files.first.name;
        });
        _mostrarExito('Archivo seleccionado: $_nombreArchivo');
      }
    } catch (e) {
      _mostrarError('Error al seleccionar archivo: $e');
    }
  }

  Future<void> _enviarIncapacidad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaFinIncapacidad.isBefore(_fechaInicioIncapacidad)) {
      _mostrarError('La fecha de fin debe ser posterior a la fecha de inicio');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String documentoUrl = '';

      // Subir archivo si existe
      if (_archivoBytes != null && _nombreArchivo != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'incapacidades/${widget.empleadoUid}_$timestamp\_$_nombreArchivo';
        
        documentoUrl = await uploadDocumentToSupabase(
          _archivoBytes!,
          path,
          bucket: 'Reportes',
          makePublic: true,
        );
      }

      // Crear modelo de incapacidad
      final incapacidad = IncapacidadModel(
        id: '', // Firestore asignará el ID
        userId: widget.empleadoUid,
        usuario: widget.empleadoNombre,
        tipoSolicitud: TipoSolicitud.incapacidad,
        tipoIncapacidad: _tipoIncapacidad,
        numCertificado: _numCertificadoCtrl.text.trim(),
        enteEmisor: _enteEmisorCtrl.text.trim(),
        fechaSolicitud: DateTime.now(),
        fechaExpediente: _fechaExpediente,
        fechaInicioIncapacidad: _fechaInicioIncapacidad,
        fechaFinIncapacidad: _fechaFinIncapacidad,
        estado: EstadoSolicitud.pendiente,
        motivo: _motivoCtrl.text.trim(),
        documentoUrl: documentoUrl.isEmpty 
            ? 'https://mmrnyhyltodxfirygqua.supabase.co/storage/v1/object/public/Reportes/Reportes/Formato%20incapacidad.pdf'
            : documentoUrl,
      );

      // Guardar en Firestore
      bool success = await addIncapacidad(incapacidad);

      if (mounted) {
        if (success) {
          _mostrarExito("Incapacidad enviada correctamente ${widget.empleadoId}");
          _limpiarFormulario();
          print('Incapacidad enviada por el empleado: ${widget.empleadoId}');
        } else {
          _mostrarError("Error al enviar la incapacidad ${widget.empleadoId}");
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarError("Error al enviar incapacidad: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    _motivoCtrl.clear();
    _numCertificadoCtrl.clear();
    _enteEmisorCtrl.clear();
    setState(() {
      _tipoIncapacidad = "Enfermedad común";
      _fechaExpediente = DateTime.now();
      _fechaInicioIncapacidad = DateTime.now();
      _fechaFinIncapacidad = DateTime.now().add(const Duration(days: 1));
      _archivoBytes = null;
      _nombreArchivo = null;
    });
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context, String tipo) async {
    DateTime initialDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (tipo) {
      case 'expediente':
        initialDate = _fechaExpediente;
        firstDate = DateTime(2000);
        lastDate = DateTime.now().add(const Duration(days: 365));
        break;
      case 'inicio':
        initialDate = _fechaInicioIncapacidad;
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now().add(const Duration(days: 365));
        break;
      case 'fin':
        initialDate = _fechaFinIncapacidad;
        firstDate = _fechaInicioIncapacidad;
        lastDate = DateTime.now().add(const Duration(days: 730));
        break;
      default:
        return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (tipo) {
          case 'expediente':
            _fechaExpediente = picked;
            break;
          case 'inicio':
            _fechaInicioIncapacidad = picked;
            // Ajustar fecha fin si es necesario
            if (_fechaFinIncapacidad.isBefore(picked)) {
              _fechaFinIncapacidad = picked.add(const Duration(days: 1));
            }
            break;
          case 'fin':
            _fechaFinIncapacidad = picked;
            break;
        }
      });
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case "Aprobada":
        return Colors.green;
      case "Rechazada":
        return Colors.red;
      case "Pendiente":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case "Aprobada":
        return Icons.check_circle;
      case "Rechazada":
        return Icons.cancel;
      case "Pendiente":
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mis Incapacidades',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Nueva Incapacidad'),
            Tab(text: 'Mis Incapacidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNuevaIncapacidadTab(), _buildMisIncapacidadesTab()],
      ),
    );
  }

  Widget _buildNuevaIncapacidadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de información del empleado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF2E7D32),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.empleadoNombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'user: ${widget.empleadoId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Formulario
            Text(
              'Nueva Incapacidad',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),

            // Tipo de incapacidad
            Text(
              'Tipo de Incapacidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _tipoIncapacidad,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
                ),
                items: _tiposIncapacidad.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoIncapacidad = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Número de certificado
            Text(
              'Número de Certificado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _numCertificadoCtrl,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Ej: CERT-2024-001',
                  prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF2E7D32)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el número de certificado';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Ente emisor
            Text(
              'Ente Emisor (Hospital/Clínica)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _enteEmisorCtrl,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Ej: Hospital San Felipe',
                  prefixIcon: Icon(Icons.local_hospital, color: Color(0xFF2E7D32)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el ente emisor';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Fecha expediente
            Text(
              'Fecha de Expedición del Certificado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _seleccionarFecha(context, 'expediente'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fechaExpediente),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fecha inicio incapacidad
            Text(
              'Fecha de Inicio de Incapacidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _seleccionarFecha(context, 'inicio'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fechaInicioIncapacidad),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fecha fin incapacidad
            Text(
              'Fecha de Fin de Incapacidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _seleccionarFecha(context, 'fin'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fechaFinIncapacidad),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Motivo
            Text(
              'Motivo / Diagnóstico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _motivoCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Describe el motivo o diagnóstico de la incapacidad...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el motivo';
                  }
                  if (value.trim().length < 10) {
                    return 'El motivo debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Subir documento
            Text(
              'Documento de Certificado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarArchivo,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _nombreArchivo != null 
                        ? const Color(0xFF2E7D32) 
                        : Colors.grey[300]!,
                    width: _nombreArchivo != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _nombreArchivo != null 
                          ? Icons.check_circle 
                          : Icons.upload_file,
                      color: _nombreArchivo != null 
                          ? const Color(0xFF2E7D32) 
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _nombreArchivo ?? 'Seleccionar archivo (PDF, JPG, PNG)',
                        style: TextStyle(
                          fontSize: 16,
                          color: _nombreArchivo != null 
                              ? const Color(0xFF2E7D32) 
                              : Colors.grey[600],
                          fontWeight: _nombreArchivo != null 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(Icons.attach_file, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Opcional: Sube el certificado médico en formato PDF o imagen',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 32),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _enviarIncapacidad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Enviar Incapacidad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMisIncapacidadesTab() {
    return FutureBuilder<List<IncapacidadModel>>(
      future: getIncapacidadesByEmpleadoId(widget.empleadoUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar incapacidades',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        final incapacidades = snapshot.data ?? [];

        if (incapacidades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No tienes incapacidades',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primera incapacidad en la pestaña anterior',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incapacidades.length,
          itemBuilder: (context, index) {
            final inc = incapacidades[index];
            final duracion = inc.fechaFinIncapacidad.difference(inc.fechaInicioIncapacidad).inDays + 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con tipo y estado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(inc.estado).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: _getEstadoColor(inc.estado),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inc.tipoIncapacidad,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(inc.estado),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEstadoIcon(inc.estado),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                inc.estado,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Certificado y ente emisor
                        Row(
                          children: [
                            Icon(
                              Icons.confirmation_number,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cert: ${inc.numCertificado}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.
                                w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                inc.enteEmisor,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Motivo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inc.motivo,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Fechas
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expedición: ${DateFormat('dd/MM/yyyy').format(inc.fechaExpediente)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Inicio: ${DateFormat('dd/MM/yyyy').format(inc.fechaInicioIncapacidad)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Fin: ${DateFormat('dd/MM/yyyy').format(inc.fechaFinIncapacidad)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Duración
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timelapse,
                                size: 14,
                                color: Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Duración: $duracion día${duracion != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Fecha de solicitud
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Enviada: ${DateFormat('dd/MM/yyyy HH:mm').format(inc.fechaSolicitud)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        // Botón ver documento
                        if (inc.documentoUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Aquí puedes implementar la apertura del documento
                                  // Por ejemplo, usando url_launcher
                                  _mostrarExito('Documento: ${inc.documentoUrl}');
                                },
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 18,
                                ),
                                label: const Text('Ver Documento'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2E7D32),
                                  side: const BorderSide(
                                    color: Color(0xFF2E7D32),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
Future<Map<String, String>> obtenerDatosEmpleado(String usuarioUid) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuarioUid)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      final uid = data['uid'] ?? ''; // Campo uidEmpleado
      final nombre = data['nombre'] ?? '';
      final apellido = data['apellido'] ?? '';
      final nombreCompleto = '$nombre $apellido'.trim();

      return {
        'uid': uid,
        'nombreCompleto': nombreCompleto,
      };
    } else {
      throw Exception('Usuario no encontrado');
    }
  } catch (e) {
    throw Exception('Error al obtener datos del empleado: $e');
  }
}