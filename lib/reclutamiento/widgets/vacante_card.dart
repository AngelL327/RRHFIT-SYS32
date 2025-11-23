import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ImprovedVacanteCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onVerPressed;

  const ImprovedVacanteCard({
    super.key,
    required this.doc,
    required this.onVerPressed,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final endDate = data['endDate'] as Timestamp?;
    final daysLeft = endDate != null
        ? endDate.toDate().difference(DateTime.now()).inDays
        : 0;
    final estado = data['estado'] ?? 'activa';
    final fechaOcupacion = data['fecha_ocupacion'] as Timestamp?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: estado == 'ocupada'
                ? [Colors.green.shade50, Colors.white]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con puesto y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['puestoNombre'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: estado == 'ocupada' ? Colors.green : Colors.blue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estado == 'ocupada'
                          ? Colors.green.shade100
                          : daysLeft > 7
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado == 'ocupada'
                          ? 'Ocupada'
                          : daysLeft > 7
                          ? 'Activa'
                          : 'Por vencer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
              const SizedBox(height: 12),

              // Información básica de la vacante
              _buildInfoRow(
                Icons.business,
                data['departamentoNombre'] ?? 'No especificado',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.category,
                data['areaNombre'] ?? 'No especificado',
              ),
              const SizedBox(height: 8),

              // Información específica según el estado
              if (estado != 'ocupada')
                _buildInfoRow(
                  Icons.calendar_today,
                  'Vence en $daysLeft días',
                  color: daysLeft <= 7 ? Colors.orange : Colors.grey,
                ),

              if (estado == 'ocupada') ...[
                _buildInfoRow(
                  Icons.person,
                  'Empleado: ${data['empleado_nombre'] ?? 'No especificado'}',
                  color: Colors.green.shade700,
                ),
                // const SizedBox(height: 8),
                // _buildInfoRow(
                //   Icons.phone,
                //   'Tel: ${data['empleado_telefono'] ?? 'No especificado'}',
                //   color: Colors.green.shade600,
                // ),
                // const SizedBox(height: 8),
                // _buildInfoRow(
                //   Icons.email,
                //   'Email: ${data['empleado_correo'] ?? 'No especificado'}',
                //   color: Colors.green.shade600,
                // ),
                const SizedBox(height: 8),
                if (fechaOcupacion != null)
                  _buildInfoRow(
                    Icons.date_range,
                    'Ocupada: ${_formatDate(fechaOcupacion.toDate())}',
                    color: Colors.green.shade600,
                  ),
              ],

              const Spacer(),

              // Botón Ver
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onVerPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: estado == 'ocupada'
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ver detalles'),
                      SizedBox(width: 4),
                      Icon(Icons.visibility, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
