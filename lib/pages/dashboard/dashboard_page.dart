import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/Reportes/planillareport.dart';
import 'package:rrhfit_sys32/pages/Reporte_Planilla.dart';
import 'package:rrhfit_sys32/widgets/Reporte_Voucher.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, List<Map<String, dynamic>>> departamentos = {};
  bool loading = true;
  String selectedDept = 'Todos';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final deptSnapshot = await _db.collection("departamento").get();
      final empSnapshot = await _db.collection("empleados").get();
      final nomSnapshot = await _db.collection("nominas").get();

      // Map de nóminas por empleado_id
      final Map<String, Map<String, dynamic>> nominasMap = {
        for (var doc in nomSnapshot.docs) doc['empleado_id']: doc.data(),
      };

      // Lista de empleados con sus deducciones reales
      final List<Map<String, dynamic>> empleados = empSnapshot.docs.map((doc) {
        final data = doc.data();
        final nom =
            nominasMap[data['empleado_id']] ??
            {'rap': 0, 'seguro_social': 0, 'isr': 0, 'sueldo_base': 0};

        double rap = (nom['rap'] ?? 0).toDouble();
        double seguroSocial = (nom['seguro_social'] ?? 0).toDouble();
        double isr = (nom['isr'] ?? 0).toDouble();
        double salario = (nom['sueldo_base'] ?? 0).toDouble();

        return {
          "nombre": data["nombre"] ?? '',
          "departamento_id": data["departamento_id"] ?? '',
          "estado": data["estado"] ?? 'Activo',
          "salario": salario,
          "rap": rap,
          "seguro_social": seguroSocial,
          "isr": isr,
          "total_deducciones": rap + seguroSocial + isr,
        };
      }).toList();

      final Map<String, List<Map<String, dynamic>>> temp = {};

      for (var doc in deptSnapshot.docs) {
        final deptId = doc.id;
        final nombreDepto = doc.data()["nombre"] ?? '';
        temp[nombreDepto] = empleados
            .where((e) => e["departamento_id"] == deptId)
            .toList();
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

  int _calculateActivos(String depto) {
    if (depto == 'Todos') {
      return departamentos.values
          .expand((list) => list)
          .where((e) => e['estado'] == 'Activo')
          .length;
    } else {
      return departamentos[depto]!.where((e) => e['estado'] == 'Activo').length;
    }
  }

  int _calculateInactivos(String depto) {
    if (depto == 'Todos') {
      return departamentos.values
          .expand((list) => list)
          .where((e) => e['estado'] != 'Activo')
          .length;
    } else {
      return departamentos[depto]!.where((e) => e['estado'] != 'Activo').length;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Cargando datos administractivos ...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Dashboard Administrativo - Fittlay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
    
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
            tooltip: "¿Qué es esta sección?",
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFF2E7D32),

                  title: const Text(
                    "Acerca del Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    "Esta sección permite visualizar, administrar y generar reportes "
                    "relacionados con los empleados y departamentos de Fittlay.\n\n"
                    "En este panel puedes:\n"
                    "• Ver empleados activos e inactivos\n"
                    "• Filtrar empleados por departamento\n"
                    "• Consultar salarios, ISR, RAP y Seguro Social\n"
                    "• Generar reportes de planilla\n"
                    "• Sintetizar toda la informacion mostrada aqui \n\n"
                    "Toda la información se obtiene en tiempo real desde Firestore.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  actions: [
                    TextButton(
                      child: const Text(
                        "Cerrar",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de botones + filtro
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filtro departamentos
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Departamento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      filled: true,
                      fillColor: Color(0xFFFBF8F6),
                    ),
                    items: ['Todos', ...departamentos.keys].map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(
                          dept,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDept = value!;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Botones a la derecha
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportePlanillaFirestore1(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Reporte Planilla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.cream,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportePlanillaScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.monetization_on),
                      label: const Text('Reporte Deducciones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.cream,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cards resumen dinámicas con iconos
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusCard(
                    title: 'Activos',
                    value: _calculateActivos(selectedDept),
                    width: 150,
                    color: AppTheme.primary,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatusCard(
                    title: 'Inactivos',
                    value: _calculateInactivos(selectedDept),
                    width: 150,
                    color: AppTheme.accent,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'DEPARTAMENTOS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: departamentos.entries.map((entry) {
                  final depto = entry.key;
                  final listaEmpleados = entry.value;

                  if (selectedDept != 'Todos' && depto != selectedDept) {
                    return const SizedBox.shrink();
                  }

                  double totalSalario = listaEmpleados.fold(
                    0,
                    (sum, e) => sum + (e['salario'] as double),
                  );
                  double totalDeducciones = listaEmpleados.fold(
                    0,
                    (sum, e) => sum + (e['total_deducciones'] as double),
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            depto,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Column(
                            children: listaEmpleados.map((emp) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(
                                  emp['nombre'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12),
                                    children: [
                                      TextSpan(
                                        text: "Salario: ",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _formatCurrency(
                                          emp['salario'] as double,
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: "\nDeducciones:\n",
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      TextSpan(
                                        text:
                                            "ISR: ${_formatCurrency(emp['isr'] as double)}\n",
                                        style: TextStyle(
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "RAP: ${_formatCurrency(emp['rap'] as double)}\n",
                                        style: TextStyle(
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "Seguro Social: ${_formatCurrency(emp['seguro_social'] as double)}",
                                        style: TextStyle(
                                          color: AppTheme.accent,
                                        ),
                                      ),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Total Salarios: ",
                                  style: TextStyle(color: Colors.black87),
                                ),
                                TextSpan(
                                  text: _formatCurrency(totalSalario),
                                  style: TextStyle(color: AppTheme.primary),
                                ),
                                const TextSpan(
                                  text: "\nTotal Deducciones: ",
                                  style: TextStyle(color: Colors.black87),
                                ),
                                TextSpan(
                                  text: _formatCurrency(totalDeducciones),
                                  style: TextStyle(color: AppTheme.accent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card de estado dinámico con icono
class _StatusCard extends StatelessWidget {
  final String title;
  final int value;
  final double width;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    this.width = 150,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
