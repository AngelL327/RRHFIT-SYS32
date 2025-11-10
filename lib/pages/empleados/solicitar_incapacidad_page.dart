import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rrhfit_sys32/widgets/type.dart';
import 'package:rrhfit_sys32/pages/solicitudes.dart';
import 'package:rrhfit_sys32/pages/mainpage.dart';
import 'package:rrhfit_sys32/pages/solicitudes.dart';

class SolicitudesEmpleadoPage extends StatefulWidget {
  final String empleadoId; // ID del empleado actual
  final String empleadoNombre; // Nombre del empleado

  const SolicitudesEmpleadoPage({
    super.key,
    required this.empleadoId,
    required this.empleadoNombre,
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
  final _descripcionCtrl = TextEditingController();
  final _departamentoCtrl = TextEditingController();
  final TextEditingController _puestoCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();

  String _tipoSolicitud = "Permiso médico";
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isSubmitting = false;

  final List<String> _tiposSolicitud = [
    "Vacaciones",
    "Permiso médico",
    "Cambio de turno",
  ];

  final List<String> _departamentos = [
    "Producción",
    "Recursos Humanos",
    "Ventas",
    "Administración",
    "Sistemas",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _departamentoCtrl.text = "Recursos Humanos";
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descripcionCtrl.dispose();
    _departamentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _db.collection("solicitudes").add({
        "uid": widget.empleadoId,
        "empleado": widget.empleadoNombre,
        "departamento": _departamentoCtrl.text,
        "descripcion": _descripcionCtrl.text,
        "tipo": _tipoSolicitud,
        "fecha": _fechaSeleccionada,
        "estado": "Pendiente",
        "creadoEn": FieldValue.serverTimestamp(),

      
        "codigo": _codigoCtrl.text.isEmpty ? "Sin código" : _codigoCtrl.text,
        "puesto": _puestoCtrl.text.isEmpty ? "Empleado" : _puestoCtrl.text,
      });

      if (mounted) {
        _mostrarExito("Solicitud enviada correctamente");
        _limpiarFormulario();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError("Error al enviar solicitud: $e");
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
    _descripcionCtrl.clear();
    _departamentoCtrl.text = "Recursos Humanos";
    setState(() {
      _tipoSolicitud = "Permiso médico";
      _fechaSeleccionada = DateTime.now();
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

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
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
          'Mis Solicitudes',
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
            Tab(text: 'Nueva Solicitud'),
            Tab(text: 'Mis Solicitudes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNuevaSolicitudTab(), _buildMisSolicitudesTab()],
      ),
    );
  }

  Widget _buildNuevaSolicitudTab() {
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
              'Nueva Solicitud',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),

            // Tipo de solicitud
            Text(
              'Tipo de Solicitud',
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
                value: _tipoSolicitud,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.category, color: Color(0xFF2E7D32)),
                ),
                items: _tiposSolicitud.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSolicitud = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Departamento
            Text(
              'Departamento',
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
                value: _departamentoCtrl.text,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.business, color: Color(0xFF2E7D32)),
                ),
                items: _departamentos.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _departamentoCtrl.text = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Fecha
            Text(
              'Fecha de la Solicitud',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarFecha,
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
                      DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Descripción
            Text(
              'Descripción / Motivo',
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
                controller: _descripcionCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Describe el motivo de tu solicitud...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  if (value.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 32),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _enviarSolicitud,
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
                            'Enviar Solicitud',
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

  Widget _buildMisSolicitudesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('solicitudes')
          .where('uid', isEqualTo: widget.empleadoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar solicitudes',
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

        final solicitudes = snapshot.data?.docs ?? [];

        // Ordenar manualmente por fecha de creación
        solicitudes.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['creadoEn'] as Timestamp?;
          final bTimestamp = bData['creadoEn'] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp);
        });

        if (solicitudes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No tienes solicitudes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primera solicitud en la pestaña anterior',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: solicitudes.length,
          itemBuilder: (context, index) {
            final doc = solicitudes[index];
            final data = doc.data() as Map<String, dynamic>;

            final String tipo = data['tipo'] ?? 'Sin tipo';
            final String descripcion = data['descripcion'] ?? 'Sin descripción';
            final String estado = data['estado'] ?? 'Pendiente';
            final String departamento =
                data['departamento'] ?? 'Sin departamento';
            final Timestamp? fechaTs = data['fecha'];
            final Timestamp? creadoEnTs = data['creadoEn'];

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
                      color: _getEstadoColor(estado).withOpacity(0.1),
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
                                Icons.description,
                                color: _getEstadoColor(estado),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tipo,
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
                            color: _getEstadoColor(estado),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEstadoIcon(estado),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                estado,
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
                        // Descripción
                        Text(
                          descripcion,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Información adicional
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              departamento,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (fechaTs != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(fechaTs.toDate())}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),

                        if (creadoEnTs != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Enviada: ${DateFormat('dd/MM/yyyy HH:mm').format(creadoEnTs.toDate())}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
