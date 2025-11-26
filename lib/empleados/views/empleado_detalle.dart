import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';

class EmpleadoDetalleScreen extends StatelessWidget {
  final Empleado empleado;
  final EmpleadoController controller;

  const EmpleadoDetalleScreen({
    super.key,
    required this.empleado,
    required this.controller,
  });

  String _formatDate(DateTime? d) =>
      d == null ? '-' : d.toLocal().toIso8601String().split('T')[0];

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departamento =
        controller.getDepartamentoNombre(empleado.departamentoId) ?? '-';
    final area = controller.getAreaNombre(empleado.areaId) ?? '-';
    final puesto = controller.getPuestoNombre(empleado.puestoId) ?? '-';
    final estado = (empleado.estado ?? '').toLowerCase();
    final isActivo = estado == 'activo' || estado == 'active' || estado == 'a';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Text('Empleado', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.indigo.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: Text(
                            _initials(empleado.nombre),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empleado.nombre ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Chip(
                                  backgroundColor: isActivo
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  label: Text(
                                    empleado.estado ?? '-',
                                    style: TextStyle(
                                      color: isActivo
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (empleado.codigoEmpleado != null &&
                                    empleado.codigoEmpleado!.isNotEmpty)
                                  Chip(
                                    backgroundColor: Colors.white24,
                                    label: Text(
                                      'DNI: ${empleado.codigoEmpleado!}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              departamento != '-'
                                  ? '$puesto · $departamento'
                                  : puesto,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [const SizedBox(height: 8)],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 760;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Card(
                            color: Color(0xFF2E7D32),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Información básica',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Divider(),
                                  _infoRow(
                                    Icons.person_outline,
                                    'Nombre completo',
                                    empleado.nombre ?? '-',
                                  ),
                                  _infoRow(
                                    Icons.badge_outlined,
                                    'Empleado ID',
                                    empleado.empleadoId ?? '-',
                                  ),
                                  _infoRow(
                                    Icons.account_box_outlined,
                                    'Salario',
                                    'L. ${empleado.salario?.toString() ?? '-'}',
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Contacto',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Divider(),
                                  _infoRow(
                                    Icons.email_outlined,
                                    'Correo',
                                    empleado.correo ?? '-',
                                  ),
                                  _infoRow(
                                    Icons.phone_outlined,
                                    'Teléfono',
                                    empleado.telefono ?? '-',
                                  ),
                                  _infoRow(
                                    Icons.location_on_outlined,
                                    'Dirección',
                                    empleado.direccion ?? '-',
                                  ),
                                  _infoRow(
                                    Icons.account_balance_wallet_outlined,
                                    'Cuenta',
                                    empleado.numeroCuenta ?? '-',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (isWide)
                          const SizedBox(width: 16)
                        else
                          const SizedBox(height: 12),

                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Card(
                                color: Color(0xFF2E7D32),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Organización',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Divider(),
                                      _infoRow(
                                        Icons.apartment_outlined,
                                        'Departamento',
                                        departamento,
                                      ),
                                      _infoRow(
                                        Icons.layers_outlined,
                                        'Área',
                                        area,
                                      ),
                                      _infoRow(
                                        Icons.work_outline,
                                        'Puesto',
                                        puesto,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Chip(
                                            label: Text(departamento),
                                            backgroundColor: Colors.grey[100],
                                          ),
                                          Chip(
                                            label: Text(area),
                                            backgroundColor: Colors.grey[100],
                                          ),
                                          Chip(
                                            label: Text(puesto),
                                            backgroundColor: Colors.grey[100],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Card(
                                color: Color(0xFF2E7D32),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Fechas',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Divider(),
                                      _infoRow(
                                        Icons.cake_outlined,
                                        'Nacimiento',
                                        _formatDate(empleado.fechaNacimiento),
                                      ),
                                      _infoRow(
                                        Icons.calendar_today_outlined,
                                        'Contratación',
                                        _formatDate(empleado.fechaContratacion),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Card(
                                color: Color(0xFF2E7D32),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Última actualización: ${_formatDate(empleado.fechaContratacion)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.grey.shade200,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          label: const Text(
                            'Volver',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
