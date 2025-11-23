import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:flutter/services.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/pages/reporte_planilla_local.dart';

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
      home: const ReportePlanillaScreen(),
    );
  }
}

class ReportePlanillaScreen extends StatefulWidget {
  const ReportePlanillaScreen({super.key});

  @override
  State<ReportePlanillaScreen> createState() => _ReportePlanillaScreenState();
}

class _ReportePlanillaScreenState extends State<ReportePlanillaScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, List<Map<String, dynamic>>> departamentos = {};
  bool loading = true;

  final List<Color> cardColors = [
    const Color(0xFF2E7D32),
    const Color(0xFF39B5DA),
    const Color(0xFFF57C00),
    const Color(0xFF145A32),
    const Color(0xFF1976D2),
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
      final nomSnapshot = await _db.collection("nominas").get();

      final Map<String, Map<String, dynamic>> nominasMap = {};
      for (var doc in nomSnapshot.docs) {
        final data = doc.data();
        final empleadoId = data["empleado_id"];
        if (empleadoId != null) {
          nominasMap[empleadoId] = data;
        }
      }

      final Map<String, List<Map<String, dynamic>>> temp = {};

      for (var deptDoc in deptSnapshot.docs) {
        final deptId = deptDoc.id;
        final nombreDepto = deptDoc.data()["nombre"] ?? '';

        final empleadosDepto = empSnapshot.docs
            .where((emp) => emp.data()["departamento_id"] == deptId)
            .map((empDoc) {
              final empData = empDoc.data();
              final empleadoId = empData["empleado_id"];
              final nomina = nominasMap[empleadoId];

              return {
                "nombre": empData["nombre"] ?? '',
                "departamento_id": deptId,
                "salario": nomina != null
                    ? (nomina["sueldo_base"] ?? empData["salario"] ?? 0)
                          .toDouble()
                    : (empData["salario"] ?? 0).toDouble(),
                "rap": nomina != null ? (nomina["rap"] ?? 0).toDouble() : 0.0,
                "ihss": nomina != null
                    ? (nomina["seguro_social"] ?? 0).toDouble()
                    : 0.0,
                "isr": nomina != null ? (nomina["isr"] ?? 0).toDouble() : 0.0,
                "deducciones": nomina != null
                    ? (nomina["total_deducciones"] ?? 0).toDouble()
                    : 0.0,
                "sueldo_neto": nomina != null
                    ? (nomina["sueldo_neto"] ?? 0).toDouble()
                    : ((empData["salario"] ?? 0).toDouble()),
              };
            })
            .toList();

        temp[nombreDepto] = empleadosDepto;
      }

      setState(() {
        departamentos = temp;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
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

  // MÉTODO PARA LAS FILAS DE DEDUCCIONES
  Widget _buildRow(
    String label,
    String value, {
    double fontSizeLabel = 16,
    double fontSizeValue = 20,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSizeLabel, color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSizeValue,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final fechaReporte =
        '${toBeginningOfSentenceCase(meses[DateTime.now().month - 1])} ${DateTime.now().year}';
    final fechaGenerado = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // TOTALES POR DEPARTAMENTO
    final Map<String, double> totalSueldoBrutoPorDepto = {};
    final Map<String, double> totalDeduccionesPorDepto = {};
    final Map<String, double> totalSueldoNetoPorDepto = {};
    final Map<String, double> totalRapPorDepto = {};
    final Map<String, double> totalIhssPorDepto = {};
    final Map<String, double> totalIsrPorDepto = {};

    departamentos.forEach((depto, empleadosDepto) {
      final bruto = empleadosDepto.fold<double>(
        0,
        (sum, e) => sum + (e["salario"] as double),
      );
      final deducciones = empleadosDepto.fold<double>(
        0,
        (sum, e) => sum + (e["deducciones"] as double),
      );
      final neto = bruto - deducciones;
      final rap = empleadosDepto.fold<double>(
        0,
        (sum, e) => sum + (e["rap"] as double),
      );
      final ihss = empleadosDepto.fold<double>(
        0,
        (sum, e) => sum + (e["ihss"] as double),
      );
      final isr = empleadosDepto.fold<double>(
        0,
        (sum, e) => sum + (e["isr"] as double),
      );

      totalSueldoBrutoPorDepto[depto] = bruto;
      totalDeduccionesPorDepto[depto] = deducciones;
      totalSueldoNetoPorDepto[depto] = neto;
      totalRapPorDepto[depto] = rap;
      totalIhssPorDepto[depto] = ihss;
      totalIsrPorDepto[depto] = isr;
    });
    final totalDeducciones =
        totalRapPorDepto.values.fold<double>(0.0, (a, b) => a + b) +
        totalIhssPorDepto.values.fold<double>(0.0, (a, b) => a + b) +
        totalIsrPorDepto.values.fold<double>(0.0, (a, b) => a + b);

    const double maxBarHeight = 180;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Color(0xFFFBF8F6)),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Vista General Reporte Planilla',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportePlanillaLocal()),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver reportes anteriores',
                    style: TextStyle(color: Color(0xFFFBF8F6)),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/fittlay_imagotipo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Departamento de RRHH",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const Expanded(flex: 4, child: SizedBox()),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Fecha: $fechaGenerado',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 80),
              child: Column(
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
                      'Reporte de Deducciones por Departamento',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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

                  // === AQUÍ ESTÁ TU CARD PERFECTA ===
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Center(
                            child: Text(
                              'DEPARTAMENTOS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                                final color =
                                    cardColors[departamentos.keys
                                            .toList()
                                            .indexOf(depto) %
                                        cardColors.length];

                                final rap = totalRapPorDepto[depto] ?? 0.0;
                                final ihss = totalIhssPorDepto[depto] ?? 0.0;
                                final isr = totalIsrPorDepto[depto] ?? 0.0;
                                final deducciones =
                                    totalDeduccionesPorDepto[depto] ?? 0.0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Column(
                                    children: [
                                      Card(
                                        elevation: 12,
                                        shadowColor: Colors.black45,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Container(
                                          width:
                                              240, // reducido para que abarque menos espacio
                                          padding: const EdgeInsets.all(
                                            16,
                                          ), // padding reducido
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                color.withOpacity(0.98),
                                                color,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.people_alt_rounded,
                                                    size: 24,
                                                    color: Colors.white,
                                                  ), // icono más pequeño
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '$totalEmpleados',
                                                        style: const TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              _buildRow(
                                                'RAP',
                                                _formatCurrency(rap),
                                                fontSizeLabel: 12,
                                                fontSizeValue: 14,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildRow(
                                                'IHSS',
                                                _formatCurrency(ihss),
                                                fontSizeLabel: 12,
                                                fontSizeValue: 14,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildRow(
                                                'ISR',
                                                _formatCurrency(isr),
                                                fontSizeLabel: 12,
                                                fontSizeValue: 14,
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                height: 2,
                                                color: Colors.white30,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Total deducciones',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatCurrency(
                                                      deducciones,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        depto,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
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

                  const SizedBox(height: 80),

                  // GRÁFICAS (MANTENIDAS IGUAL)
                  SizedBox(
                    height: maxBarHeight + 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  width: max(
                                    constraints.maxWidth,
                                    totalDeduccionesPorDepto.length * 80 +
                                        (totalDeduccionesPorDepto.length - 1) *
                                            40,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: totalDeduccionesPorDepto.entries
                                        .map((e) {
                                          final depto = e.key;
                                          final deducciones =
                                              e.value; // ← USAR DEDUCCIONES

                                          final colorSueldo =
                                              cardColors[departamentos.keys
                                                      .toList()
                                                      .indexOf(depto) %
                                                  cardColors.length];

                                          final maxValue =
                                              totalDeduccionesPorDepto
                                                  .values
                                                  .isEmpty
                                              ? 1
                                              : totalDeduccionesPorDepto.values
                                                    .reduce(max);

                                          final barHeight =
                                              (deducciones / maxValue) *
                                              maxBarHeight; // ← ALTURA

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatCurrency(
                                                    deducciones,
                                                  ), // ← TEXTO
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  width: 40,
                                                  height:
                                                      barHeight, // ← ALTURA BARRA
                                                  color: colorSueldo,
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    depto,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                          color: Color(0xFF145A32),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'RAP',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF39B5DA),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'IHSS',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF57C00),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'ISR',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),

                              SizedBox(
                                width: 180,
                                height: maxBarHeight,
                                child: PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 50,
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 2,
                                    sections: [
                                      // RAP
                                      PieChartSectionData(
                                        color: const Color(0xFF2E7D32),
                                        value: totalRapPorDepto.values
                                            .fold<double>(0.0, (a, b) => a + b),
                                        title:
                                            '${(totalRapPorDepto.values.fold<double>(0.0, (a, b) => a + b) / totalDeducciones * 100).toStringAsFixed(1)}%',
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // IHSS
                                      PieChartSectionData(
                                        color: const Color(0xFF39B5DA),
                                        value: totalIhssPorDepto.values
                                            .fold<double>(0.0, (a, b) => a + b),
                                        title:
                                            '${(totalIhssPorDepto.values.fold<double>(0.0, (a, b) => a + b) / totalDeducciones * 100).toStringAsFixed(1)}%',
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // ISR
                                      PieChartSectionData(
                                        color: const Color(0xFFF57C00),
                                        value: totalIsrPorDepto.values
                                            .fold<double>(0.0, (a, b) => a + b),
                                        title:
                                            '${(totalIsrPorDepto.values.fold<double>(0.0, (a, b) => a + b) / totalDeducciones * 100).toStringAsFixed(1)}%',
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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
                            child: const Center(
                              child: Text(
                                'Distribución de deducciones por departamento',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: pieWidth,
                            child: const Center(
                              child: Text(
                                'Porcentaje de distribución de deducciones',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generado por: ${Global().userName ?? 'Usuario'}',
                      style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                    ),
                    Text(
                      'Página 1 / 1',
                      style: TextStyle(fontSize: 20, color: Colors.grey[700]),
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
}
