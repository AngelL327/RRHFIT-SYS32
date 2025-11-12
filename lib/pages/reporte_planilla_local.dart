// reporte_planilla_local.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/globals.dart';

// === DATOS DE PRUEBA (INTACTOS) ===
final List<Map<String, dynamic>> datosPruebaPlanilla = [
  // --- AGOSTO 2025 ---
  {
    "mes": "agosto",
    "anio": 2025,
    "departamento_nombre": "Producción",
    "total_empleados": 37,
    "total_salarios": 1400000.0,
    "total_deducciones": 290000.0
  },
  {
    "mes": "agosto",
    "anio": 2025,
    "departamento_nombre": "Recursos Humanos",
    "total_empleados": 12,
    "total_salarios": 420000.0,
    "total_deducciones": 80000.0
  },
  {
    "mes": "agosto",
    "anio": 2025,
    "departamento_nombre": "Ventas",
    "total_empleados": 22,
    "total_salarios": 810000.0,
    "total_deducciones": 170000.0
  },
  {
    "mes": "agosto",
    "anio": 2025,
    "departamento_nombre": "Administración",
    "total_empleados": 11,
    "total_salarios": 420000.0,
    "total_deducciones": 65000.0
  },
  {
    "mes": "agosto",
    "anio": 2025,
    "departamento_nombre": "Sistemas",
    "total_empleados": 9,
    "total_salarios": 350000.0,
    "total_deducciones": 60000.0
  },

  // --- SEPTIEMBRE 2025 ---
  {
    "mes": "septiembre",
    "anio": 2025,
    "departamento_nombre": "Producción",
    "total_empleados": 35,
    "total_salarios": 1300000.0,
    "total_deducciones": 270000.0
  },
  {
    "mes": "septiembre",
    "anio": 2025,
    "departamento_nombre": "Recursos Humanos",
    "total_empleados": 12,
    "total_salarios": 420000.0,
    "total_deducciones": 80000.0
  },
  {
    "mes": "septiembre",
    "anio": 2025,
    "departamento_nombre": "Ventas",
    "total_empleados": 20,
    "total_salarios": 750000.0,
    "total_deducciones": 150000.0
  },
  {
    "mes": "septiembre",
    "anio": 2025,
    "departamento_nombre": "Administración",
    "total_empleados": 10,
    "total_salarios": 380000.0,
    "total_deducciones": 60000.0
  },
  {
    "mes": "septiembre",
    "anio": 2025,
    "departamento_nombre": "Sistemas",
    "total_empleados": 8,
    "total_salarios": 300000.0,
    "total_deducciones": 50000.0
  },

  // --- OCTUBRE 2025 ---
  {
    "mes": "octubre",
    "anio": 2025,
    "departamento_nombre": "Producción",
    "total_empleados": 36,
    "total_salarios": 1350000.0,
    "total_deducciones": 280000.0
  },
  {
    "mes": "octubre",
    "anio": 2025,
    "departamento_nombre": "Recursos Humanos",
    "total_empleados": 13,
    "total_salarios": 455000.0,
    "total_deducciones": 85000.0
  },
  {
    "mes": "octubre",
    "anio": 2025,
    "departamento_nombre": "Ventas",
    "total_empleados": 21,
    "total_salarios": 780000.0,
    "total_deducciones": 160000.0
  },
  {
    "mes": "octubre",
    "anio": 2025,
    "departamento_nombre": "Administración",
    "total_empleados": 10,
    "total_salarios": 380000.0,
    "total_deducciones": 60000.0
  },
  {
    "mes": "octubre",
    "anio": 2025,
    "departamento_nombre": "Sistemas",
    "total_empleados": 9,
    "total_salarios": 340000.0,
    "total_deducciones": 55000.0
  },
];

class ReportePlanillaLocal extends StatefulWidget {
  const ReportePlanillaLocal({super.key});

  @override
  State<ReportePlanillaLocal> createState() => _ReportePlanillaLocalState();
}

class _ReportePlanillaLocalState extends State<ReportePlanillaLocal> {
  String _selectedMes = 'octubre'; // Cambiado a octubre para prueba
  int _selectedAnio = 2025;

  final List<Color> cardColors = [
    const Color(0xFF2E7D32),
    const Color(0xFF39B5DA),
    const Color(0xFFF57C00),
    const Color(0xFF145A32),
    const Color(0xFF39B5DA),
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_HN', null);
  }

  List<Map<String, dynamic>> _getDatosFiltrados() {
    return datosPruebaPlanilla
        .where((d) => d['mes'] == _selectedMes && d['anio'] == _selectedAnio)
        .toList();
  }

  List<DropdownMenuItem<String>> _getMesesDisponibles() {
    final Set<String> claves = {};
    final List<DropdownMenuItem<String>> items = [];

    for (var d in datosPruebaPlanilla) {
      final clave = '${d['mes']}-${d['anio']}';
      if (!claves.contains(clave)) {
        claves.add(clave);
        final mes = toBeginningOfSentenceCase(d['mes'] as String)!;
        items.add(DropdownMenuItem(value: d['mes'] as String, child: Text('$mes ${d['anio']}')));
      }
    }
    return items;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_US', symbol: 'L ', decimalDigits: 2).format(amount);
  }

  // === FUNCIÓN PARA OBTENER EL NÚMERO DEL MES ===
  int _getMesNumero(String mes) {
    const meses = {
      'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
      'julio': 7, 'agosto': 8, 'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12
    };
    return meses[mes.toLowerCase()] ?? 11;
  }

  @override
  Widget build(BuildContext context) {
    final datos = _getDatosFiltrados();

    // === TÍTULO: MES + AÑO (QUEDA IGUAL) ===
    final fechaReporte = '${toBeginningOfSentenceCase(_selectedMes)} $_selectedAnio';

    // === FECHA DE GENERACIÓN: ÚLTIMO DÍA DEL MES SELECCIONADO ===
    final DateTime ultimoDiaMes = DateTime(_selectedAnio, _getMesNumero(_selectedMes) + 1, 0);
    final fechaGenerado = DateFormat('dd/MM/yyyy').format(ultimoDiaMes);

    final generadoPor = Global().userName ?? 'Usuario';

    final totalSueldo = datos.fold<double>(0, (s, d) => s + (d['total_salarios'] as double));
    final totalDeducciones = datos.fold<double>(0, (s, d) => s + (d['total_deducciones'] as double));
    final totalGeneral = totalSueldo + totalDeducciones;

    const double maxBarHeight = 180.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Color(0xFFFBF8F6)),
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text('Reportes Mensuales de Planilla', style: TextStyle(color: Colors.white)),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // === FILTRO DE MES ===
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  const Text('Mes:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedMes,
                      isExpanded: true,
                      items: _getMesesDisponibles(),
                      onChanged: (v) => v != null ? setState(() => _selectedMes = v) : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // === MARCA DE AGUA + CONTENIDO ===
            Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/images/fittlay_imagotipo.png',
                      fit: BoxFit.contain,
                      repeat: ImageRepeat.repeatY,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 100),
                  child: Column(
                    children: [
                      // === HEADER CON FECHA DE GENERACIÓN CORRECTA ===
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text("Departamento de RRHH", style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                            const Expanded(flex: 4, child: SizedBox()),
                            Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('Fecha: $fechaGenerado', style: TextStyle(fontSize: 12, color: Colors.grey[700])))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Image.asset('assets/images/fittlay_imagotipo.png', width: 200, height: 200),
                      const SizedBox(height: 10),
                      const Text('Reporte de Planilla por Departamento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(fechaReporte, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 30),

                      // === TARJETAS (CÍRCULO ARRIBA-IZQUIERDA + NOMBRE EN 1 LÍNEA) ===
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('DEPARTAMENTOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: datos.map((d) {
                                    final depto = d['departamento_nombre'] as String;
                                    final empleados = d['total_empleados'] as int;
                                    final sueldo = d['total_salarios'] as double;
                                    final deducciones = d['total_deducciones'] as double;
                                    final color = cardColors[datosPruebaPlanilla.indexWhere((e) => e['departamento_nombre'] == depto) % cardColors.length];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Column(
                                        children: [
                                          Card(
                                            color: color,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            child: Container(
                                              width: 240,
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text('$empleados', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                                        const Text('TOTAL EMPLEADOS', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                                        const SizedBox(height: 8),
                                                        Text(_formatCurrency(sueldo), style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                                        const Text('TOTAL SUELDO', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                                        const SizedBox(height: 8),
                                                        Text(_formatCurrency(deducciones), style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                                        const Text('TOTAL DEDUCCIONES', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: 240,
                                            child: Text(
                                              depto,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
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
                      const SizedBox(height: 50),

                      // === GRÁFICAS (BARRAS: NOMBRE EN 1 LÍNEA) ===
                      SizedBox(
                        height: maxBarHeight + 80,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 3,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxValue = datos.isEmpty ? 1.0 : datos.map((e) => e['total_salarios'] as double).reduce(max);
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      width: max(constraints.maxWidth, datos.length * 120.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: datos.map((d) {
                                          final depto = d['departamento_nombre'] as String;
                                          final sueldo = d['total_salarios'] as double;
                                          final color = cardColors[datosPruebaPlanilla.indexWhere((e) => e['departamento_nombre'] == depto) % cardColors.length];
                                          final double barHeight = maxValue > 0 ? (sueldo / maxValue * maxBarHeight).toDouble() : 0.0;

                                          return Container(
                                            width: 100,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(_formatCurrency(sueldo), style: const TextStyle(fontSize: 10)),
                                                const SizedBox(height: 4),
                                                Container(width: 40, height: barHeight, color: color),
                                                const SizedBox(height: 4),
                                                // === NOMBRE EN 1 LÍNEA + ... ===
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    depto,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1, // AQUÍ ESTÁ LA CLAVE
                                                  ),
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
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    _buildIndicator(const Color(0xFF145A32), 'Salarios'),
                                    const SizedBox(width: 16),
                                    _buildIndicator(const Color(0xFFF57C00), 'Deducciones'),
                                  ]),
                                  const SizedBox(height: 8),
                                  const Spacer(),
                                  SizedBox(
                                    width: 180,
                                    height: maxBarHeight,
                                    child: totalGeneral > 0
                                        ? PieChart(PieChartData(
                                            centerSpaceRadius: 50,
                                            sections: [
                                              PieChartSectionData(color: const Color(0xFF145A32), value: totalSueldo, title: '${(totalSueldo / totalGeneral * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                              PieChartSectionData(color: const Color(0xFFF57C00), value: totalDeducciones, title: '${(totalDeducciones / totalGeneral * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                            ],
                                          ))
                                        : const Center(child: Text('Sin datos')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      LayoutBuilder(
                        builder: (context, constraints) => Row(
                          children: [
                            SizedBox(width: constraints.maxWidth * 3 / 5, child: const Center(child: Text('Distribución salarial por departamento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))),
                            SizedBox(width: constraints.maxWidth * 2 / 5, child: const Center(child: Text('Comparativa entre salarios y deducciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      // FOOTER
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Generado por: $generadoPor', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            Text('Página 1 / 1', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}