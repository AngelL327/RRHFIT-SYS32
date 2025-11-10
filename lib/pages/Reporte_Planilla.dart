import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_HN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vista General Reporte Planilla',
      home: const ReportePlanillaFirestore1(),
    );
  }
}

class ReportePlanillaFirestore1 extends StatefulWidget {
  const ReportePlanillaFirestore1({super.key});

  @override
  State<ReportePlanillaFirestore1> createState() =>
      _ReportePlanillaFirestoreState();
}

class _ReportePlanillaFirestoreState extends State<ReportePlanillaFirestore1> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, List<Map<String, dynamic>>> departamentos = {};
  bool loading = true;

  // VALORES FIJOS IGUAL QUE EN EL DASHBOARD
  final double salarioFijo = 95000.0;
  final double deduccionFija = 10000.0;

  final List<Color> cardColors = [
    Colors.blue.shade300,
    Colors.green.shade300,
    Color(0xFFFFB74D),
    const Color.fromARGB(255, 69, 168, 217),
    const Color.fromARGB(255, 72, 206, 193),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final deptSnapshot = await _db.collection("departamento").get();
      final empSnapshot = await _db.collection("empleados").get();

      final empleados = empSnapshot.docs.map((doc) {
        final data = doc.data();
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
        temp[nombreDepto] = empleados
            .where((e) => e["departamento_id"] == deptId)
            .toList();
      }

      setState(() {
        departamentos = temp;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error fetching data: $e");
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_US',
      symbol: 'L ',
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

    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final fechaReporte =
        '${toBeginningOfSentenceCase(meses[DateTime.now().month - 1])} ${DateTime.now().year}';

    // TOTALES REALES POR DEPARTAMENTO (usando salarioFijo y deduccionFija)
    final Map<String, double> totalSueldoPorDepto = {};
    final Map<String, double> totalDeduccionesPorDepto = {};

    departamentos.forEach((depto, empleadosDepto) {
      totalSueldoPorDepto[depto] = empleadosDepto.length * salarioFijo;
      totalDeduccionesPorDepto[depto] = empleadosDepto.length * deduccionFija;
    });

    const double maxBarHeight = 180;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
  backgroundColor: AppTheme.primary, // Color del AppBar
  title: Align(
    alignment: Alignment.centerLeft, // Alinear a la izquierda
    child: Padding(
      padding: const EdgeInsets.only(left: 16), // margen opcional
      child: const Text(
        'Vista General Reporte Planilla',
        style: TextStyle(
          color: Colors.white, // Cambia el color aquí
        ),
      ),
    ),
  ),
),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: Stack(
          children: [
            // --- IMAGEN DE FONDO GRANDE (marca de agua) ---
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/fittlay_imagotipo.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),

            // --- CONTENIDO NORMAL ENCIMA ---
            Column(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/fittlay_imagotipo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Reporte de Planilla por Departamento',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fechaReporte,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 50),

                // CARD GRANDE - DEPARTAMENTOS
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Center(
                          child: Text(
                            'DEPARTAMENTOS',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: departamentos.entries.map((entry) {
                              final depto = entry.key;
                              final empleadosDepto = entry.value;
                              final totalEmpleados = empleadosDepto.length;

                              // USANDO VALORES FIJOS
                              final totalSueldo = totalEmpleados * salarioFijo;
                              final totalDeducciones = totalEmpleados * deduccionFija;

                              final color = cardColors[
                                  departamentos.keys.toList().indexOf(depto) %
                                      cardColors.length];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Column(
                                  children: [
                                    Card(
                                      color: color,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Container(
                                        width: 240,
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '$totalEmpleados',
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const Text('TOTAL EMPLEADOS',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white70)),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _formatCurrency(totalSueldo),
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const Text('TOTAL SUELDO',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white70)),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _formatCurrency(
                                                        totalDeducciones),
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const Text('TOTAL DEDUCCIONES',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white70)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      depto,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    '**Visualización del personal, salarios, y deducciones por departamento.**',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 80),

              
                // ---------------- GRAFICAS MEJORADAS ----------------
                SizedBox(
                  height: maxBarHeight + 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // BARRAS
                      Expanded(
                        flex: 3,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: max(constraints.maxWidth,
                                    totalSueldoPorDepto.length * 80 +
                                        (totalSueldoPorDepto.length - 1) * 40),
                                alignment: Alignment.center,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: totalSueldoPorDepto.entries.map((e) {
                                    final depto = e.key;
                                    final sueldo = e.value;
                                    final colorSueldo = cardColors[
                                        departamentos.keys
                                                .toList()
                                                .indexOf(depto) %
                                            cardColors.length];
                                    final maxValue = totalSueldoPorDepto.values
                                        .reduce((a, b) => a > b ? a : b);
                                    final barHeight = (sueldo / maxValue) *
                                        maxBarHeight;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(_formatCurrency(sueldo),
                                              style:
                                                  const TextStyle(fontSize: 10)),
                                          const SizedBox(height: 4),
                                          Container(
                                              width: 40,
                                              height: barHeight,
                                              color: colorSueldo),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 80,
                                            child: Text(depto,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),
                      // DONA
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    const Text('Salarios',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFFFB74D),
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    const Text('Deducciones',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Spacer(),
                            SizedBox(
                              width: 180,
                              height: maxBarHeight,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 50,
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.green,
                                      value: totalSueldoPorDepto.values
                                          .fold<double>(0.0, (a, b) => a + b),
                                      title:
                                          '${(totalSueldoPorDepto.values.fold<double>(0.0, (a, b) => a + b) / (totalSueldoPorDepto.values.fold<double>(0.0, (a, b) => a + b) + totalDeduccionesPorDepto.values.fold<double>(0.0, (a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      color: const Color(0xFFFFB74D),
                                      value: totalDeduccionesPorDepto.values
                                          .fold<double>(0.0, (a, b) => a + b),
                                      title:
                                          '${(totalDeduccionesPorDepto.values.fold<double>(0.0, (a, b) => a + b) / (totalSueldoPorDepto.values.fold<double>(0.0, (a, b) => a + b) + totalDeduccionesPorDepto.values.fold<double>(0.0, (a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final barWidth = totalWidth * 3 / 5;
                    final pieWidth = totalWidth * 2 / 5;

                    return Row(
                      children: [
                        SizedBox(
                          width: barWidth,
                          child: Center(
                            child: Text(
                              'Distribución salarial por departamento',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: pieWidth,
                          child: Center(
                            child: Text(
                              'Comparativa entre salarios y deducciones',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}