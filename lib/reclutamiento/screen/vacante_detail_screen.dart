import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VacanteDetailScreen extends StatefulWidget {
  final DocumentSnapshot vacante;
  final List<Map<String, String>> departamentos;
  final List<Map<String, String>> areas;
  final List<Map<String, String>> puestos;

  const VacanteDetailScreen({
    super.key,
    required this.vacante,
    required this.departamentos,
    required this.areas,
    required this.puestos,
  });

  @override
  State<VacanteDetailScreen> createState() => _VacanteDetailScreenState();
}

class _VacanteDetailScreenState extends State<VacanteDetailScreen> {
  Future<void> _showPostularCandidatoDialog() async {
    final _formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    final salarioController = TextEditingController();
    final numeroCuentaController = TextEditingController();
    final codigoEmplasivoController = TextEditingController();

    // Mover las variables de fecha aquí y usar ValueNotifier para manejar el estado
    ValueNotifier<DateTime?> fechaNacimiento = ValueNotifier<DateTime?>(null);
    ValueNotifier<DateTime?> fechaContratacion = ValueNotifier<DateTime?>(null);

    String? estado = 'Activo';

    await showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<double>(
          valueListenable: ValueNotifier(
            0.0,
          ), // Dummy value para forzar reconstrucción
          builder: (context, _, __) {
            return AlertDialog(
              title: const Text('Postular Candidato'),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildReadOnlySection(),
                        const SizedBox(height: 20),

                        _buildPersonalInfoSection(
                          nombreController,
                          correoController,
                          telefonoController,
                          direccionController,
                        ),
                        const SizedBox(height: 20),

                        _buildWorkInfoSection(
                          salarioController,
                          numeroCuentaController,
                          codigoEmplasivoController,
                          estado,
                          (value) => estado = value,
                        ),
                        const SizedBox(height: 20),

                        // Sección de fechas con ValueListenableBuilder para cada fecha
                        _buildDatesSectionWithListeners(
                          fechaNacimiento,
                          fechaContratacion,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (fechaNacimiento.value == null ||
                          fechaContratacion.value == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor, seleccione todas las fechas.',
                            ),
                          ),
                        );
                        return;
                      }

                      await _guardarEmpleado(
                        nombre: nombreController.text,
                        correo: correoController.text,
                        telefono: telefonoController.text,
                        direccion: direccionController.text,
                        fechaNacimiento: fechaNacimiento.value!,
                        fechaContratacion: fechaContratacion.value!,
                        salario: double.parse(salarioController.text),
                        numeroCuenta: numeroCuentaController.text,
                        codigoEmplasivo: codigoEmplasivoController.text,
                        estado: estado!,
                      );

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Candidato postulado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar Empleado'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReadOnlySection() {
    final data = widget.vacante.data() as Map<String, dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Vacante',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _buildReadOnlyItem('Departamento', data['departamentoNombre']),
            _buildReadOnlyItem('Área', data['areaNombre']),
            _buildReadOnlyItem('Puesto', data['puestoNombre']),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(
    TextEditingController nombreController,
    TextEditingController correoController,
    TextEditingController telefonoController,
    TextEditingController direccionController,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos Personales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfoSection(
    TextEditingController salarioController,
    TextEditingController numeroCuentaController,
    TextEditingController codigoEmplasivoController,
    String? estado,
    ValueChanged<String?> onEstadoChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Laboral',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: salarioController,
              decoration: const InputDecoration(
                labelText: 'Salario',
                border: OutlineInputBorder(),
                prefixText: ' L',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: numeroCuentaController,
              decoration: const InputDecoration(
                labelText: 'Número de cuenta',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: codigoEmplasivoController,
              decoration: const InputDecoration(
                labelText: 'DNI',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: estado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: [
                'Activo',
                'Inactivo',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onEstadoChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSectionWithListeners(
    ValueNotifier<DateTime?> fechaNacimiento,
    ValueNotifier<DateTime?> fechaContratacion,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fechas Importantes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),

            // Fecha de nacimiento con ValueListenableBuilder
            ValueListenableBuilder<DateTime?>(
              valueListenable: fechaNacimiento,
              builder: (context, value, child) {
                return _buildDatePickerWithListener(
                  label: 'Fecha de nacimiento',
                  selectedDate: value,
                  onDateSelected: (newDate) {
                    fechaNacimiento.value = newDate;
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Fecha de contratación con ValueListenableBuilder
            ValueListenableBuilder<DateTime?>(
              valueListenable: fechaContratacion,
              builder: (context, value, child) {
                return _buildDatePickerWithListener(
                  label: 'Fecha de contratación',
                  selectedDate: value,
                  onDateSelected: (newDate) {
                    fechaContratacion.value = newDate;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerWithListener({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedDate == null
                ? '$label: No seleccionada'
                : '$label: ${_formatDate(selectedDate)}',
            style: TextStyle(
              color: selectedDate == null ? Colors.grey : Colors.black87,
              fontWeight: selectedDate == null
                  ? FontWeight.normal
                  : FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }

  Widget _buildReadOnlyItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? 'No especificado'),
        ],
      ),
    );
  }

  Future<void> _guardarEmpleado({
    required String nombre,
    required String correo,
    required String telefono,
    required String direccion,
    required DateTime fechaNacimiento,
    required DateTime fechaContratacion,
    required double salario,
    required String numeroCuenta,
    required String codigoEmplasivo,
    required String estado,
  }) async {
    final data = widget.vacante.data() as Map<String, dynamic>;

    // Generar un ID único para el empleado
    final empleadoId = _generateEmployeeId();
    final asistenciaDocId = nombre.toLowerCase().replaceAll(' ', '_');

    try {
      // Guardar en la colección de empleados con ID específico
      await FirebaseFirestore.instance
          .collection('empleados')
          .doc(empleadoId)
          .set({
            'empleado_id': empleadoId,
            'asistenciaDocId': asistenciaDocId,
            'asistencia_doc_id': asistenciaDocId,
            'nombre': nombre,
            'correo': correo,
            'telefono': telefono,
            'direccion': direccion,
            'fecha_nacimiento': Timestamp.fromDate(fechaNacimiento),
            'fecha_contratacion': Timestamp.fromDate(fechaContratacion),
            'salario': salario,
            'numero_cuenta': numeroCuenta,
            'codigo_empleado': codigoEmplasivo,
            'estado': estado,
            'departamento_id': data['departamentoId'],
            'area_id': data['areaId'],
            'puesto_id': data['puestoId'],
            'departamento_nombre': data['departamentoNombre'],
            'area_nombre': data['areaNombre'],
            'puesto_nombre': data['puestoNombre'],
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('vacantes')
          .doc(widget.vacante.id)
          .update({
            'estado': 'ocupada',
            'empleado_asignado': empleadoId,
            'empleado_nombre': nombre,
            'empleado_correo': correo,
            'empleado_telefono': telefono,
            'empleado_fecha_contratacion': Timestamp.fromDate(
              fechaContratacion,
            ),
            'empleado_salario': salario,
            'fecha_ocupacion': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('vacantesOcupadas')
          .doc(widget.vacante.id)
          .set({
            ...data,
            'vacante_id': widget.vacante.id,
            'estado': 'ocupada',
            'empleado_asignado': empleadoId,
            'empleado_nombre': nombre,
            'empleado_correo': correo,
            'empleado_telefono': telefono,
            'empleado_fecha_contratacion': Timestamp.fromDate(
              fechaContratacion,
            ),
            'empleado_salario': salario,
            'fecha_ocupacion': FieldValue.serverTimestamp(),
            'vacante_original_id': widget.vacante.id,
          });
    } catch (e) {
      debugPrint('Error guardando empleado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateEmployeeId() {
    final chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // En la clase VacanteDetailScreen, actualiza el método build:

  @override
  Widget build(BuildContext context) {
    final data = widget.vacante.data() as Map<String, dynamic>;
    final endDate = data['endDate'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final fechaOcupacion = data['fecha_ocupacion'] as Timestamp?;
    final estado = data['estado'] ?? 'activa';
    final daysLeft = endDate != null
        ? endDate.toDate().difference(DateTime.now()).inDays
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Vacante'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header principal
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: estado == 'ocupada'
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['puestoNombre'] ?? 'Sin nombre',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: estado == 'ocupada'
                                ? Colors.green.shade900
                                : Colors.blue.shade900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: estado == 'ocupada'
                            ? Colors.green.shade100
                            : daysLeft > 7
                            ? Colors.blue.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        estado == 'ocupada'
                            ? 'OCUPADA'
                            : daysLeft > 7
                            ? 'VACANTE ACTIVA'
                            : 'POR VENCER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: estado == 'ocupada'
                              ? Colors.green.shade800
                              : daysLeft > 7
                              ? Colors.blue.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Información de la Vacante',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailCard(context, 'Detalles del Puesto', [
              _buildDetailItem('Departamento', data['departamentoNombre']),
              _buildDetailItem('Área', data['areaNombre']),
              _buildDetailItem('Puesto', data['puestoNombre']),
            ]),
            const SizedBox(height: 16),

            _buildDetailCard(context, 'Fechas', [
              _buildDetailItem(
                'Fecha de creación',
                createdAt != null
                    ? _formatDate(createdAt.toDate())
                    : 'No disponible',
              ),
              _buildDetailItem(
                'Fecha de vencimiento',
                endDate != null
                    ? _formatDate(endDate.toDate())
                    : 'No disponible',
              ),
              if (estado == 'ocupada' && fechaOcupacion != null)
                _buildDetailItem(
                  'Fecha de ocupación',
                  _formatDate(fechaOcupacion.toDate()),
                  isHighlighted: true,
                ),
              if (estado != 'ocupada')
                _buildDetailItem(
                  'Días restantes',
                  '$daysLeft días',
                  isHighlighted: daysLeft <= 7,
                ),
            ]),

            // NUEVA SECCIÓN: Información del Empleado (solo para vacantes ocupadas)
            if (estado == 'ocupada') ...[
              const SizedBox(height: 16),
              _buildEmpleadoSection(context, data),
            ],

            const SizedBox(height: 24),

            // Botón de Postular Candidato - Solo mostrar si la vacante está activa
            if (estado != 'ocupada') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showPostularCandidatoDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Postular Candidato'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Nueva función para mostrar la sección del empleado
  Widget _buildEmpleadoSection(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final fechaContratacion = data['empleado_fecha_contratacion'] as Timestamp?;
    final salario = data['empleado_salario'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.green.shade800, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Empleado Asignado',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información del empleado
              _buildEmpleadoInfoRow(
                'Nombre',
                data['empleado_nombre'] ?? 'No especificado',
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildEmpleadoInfoRow(
                'Correo',
                data['empleado_correo'] ?? 'No especificado',
                Icons.email,
              ),
              const SizedBox(height: 12),
              _buildEmpleadoInfoRow(
                'Teléfono',
                data['empleado_telefono'] ?? 'No especificado',
                Icons.phone,
              ),
              const SizedBox(height: 12),
              if (fechaContratacion != null)
                _buildEmpleadoInfoRow(
                  'Fecha de Contratación',
                  _formatDate(fechaContratacion.toDate()),
                  Icons.calendar_today,
                ),
              const SizedBox(height: 12),
              if (salario != null)
                _buildEmpleadoInfoRow(
                  'Salario',
                  '\$${salario.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpleadoInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(color: Colors.green.shade900, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isHighlighted
                    ? Colors.orange.shade800
                    : Colors.grey.shade900,
                fontSize: isHighlighted ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
