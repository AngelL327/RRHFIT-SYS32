import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/Reportes/planillareport.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, List<Map<String, dynamic>>> departamentos = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final deptSnapshot = await _db.collection("departamento").get();
      final empSnapshot = await _db.collection("empleados").get();

      final List<Map<String, dynamic>> empleados = empSnapshot.docs.map((doc) {
        final data = doc.data();
        double salarioFijo = 95000.0;
        double deduccionFija = 10000.0;

        return {
          "nombre": data["nombre"] ?? '',
          "departamento_id": data["departamento_id"] ?? '',
          "salario": salarioFijo,
          "deducciones": deduccionFija,
        };
      }).toList();

      final Map<String, List<Map<String, dynamic>>> temp = {};

      for (var doc in deptSnapshot.docs) {
        final deptId = doc.id;
        final nombreDepto = doc.data()["nombre"] ?? '';
        temp[nombreDepto] =
            empleados.where((e) => e["departamento_id"] == deptId).toList();
      }

      setState(() {
        departamentos = temp;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() {
        loading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg, // verde de fondo arriba
      body: Stack(
        children: [
          // Contenido principal
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Cards de resumen
                const Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _DashboardCard(title: 'Empleados Activos', value: '9'),
                    _DashboardCard(title: 'Horas Totales Hoy', value: '56'),
                    _DashboardCard(title: 'Horas Extra Acumuladas', value: '27'),
                    _DashboardCard(title: 'Solicitudes Pendientes', value: '1'),
                  ],
                ),

                const SizedBox(height: 30),

                // Título del reporte de planilla
                const Text(
                  "DEPARTAMENTO",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Cards del reporte de planilla
                Column(
                  children: departamentos.entries.map((entry) {
                    final depto = entry.key;
                    final listaEmpleados = entry.value;

                    double totalSalario = listaEmpleados.fold(
                        0, (sum, e) => sum + (e['salario'] as double));
                    double totalDeducciones = listaEmpleados.fold(
                        0, (sum, e) => sum + (e['deducciones'] as double));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              depto,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Column(
                              children: listaEmpleados.map((emp) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(emp['nombre'],
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black87)),
                                  subtitle: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 12),
                                      children: [
                                        const TextSpan(
                                            text: "Salario: ",
                                            style:
                                                TextStyle(color: Colors.black87)),
                                        TextSpan(
                                            text: _formatCurrency(
                                                emp['salario'] as double),
                                            style: TextStyle(
                                                color: AppTheme.primary)),
                                        const TextSpan(
                                            text: "  |  Deducciones: ",
                                            style:
                                                TextStyle(color: Colors.black87)),
                                        TextSpan(
                                            text: _formatCurrency(
                                                emp['deducciones'] as double),
                                            style:
                                                TextStyle(color: AppTheme.accent)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                children: [
                                  const TextSpan(
                                      text: "Total Salarios: ",
                                      style: TextStyle(color: Colors.black87)),
                                  TextSpan(
                                      text: _formatCurrency(totalSalario),
                                      style: TextStyle(color: AppTheme.primary)),
                                  const TextSpan(
                                      text: "  |  Total Deducciones: ",
                                      style: TextStyle(color: Colors.black87)),
                                  TextSpan(
                                      text: _formatCurrency(totalDeducciones),
                                      style: TextStyle(color: AppTheme.accent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 60), // espacio al final
              ],
            ),
          ),

          // Botón flotante en esquina superior derecha
          Positioned(
            top: 16,
            right: 24,
            child: ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportePlanillaFirestore(),
      ),
    );
  },
  icon: const Icon(Icons.insert_drive_file),
  label: const Text('Generar Reporte de Planilla'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.accent,
    foregroundColor: AppTheme.cream,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
)

          ),
        ],
      ),
    );
  }
}

// Cards del Dashboard
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  const _DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 200,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
