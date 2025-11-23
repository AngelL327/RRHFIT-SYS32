import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rrhfit_sys32/core/theme.dart'; 
import 'package:rrhfit_sys32/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_HN', null);
  runApp(const MaterialApp(home: ReporteDeduccionesPrueba()));
}

class ReporteDeduccionesPrueba extends StatefulWidget {
  const ReporteDeduccionesPrueba({super.key});
  @override
  State<ReporteDeduccionesPrueba> createState() => _ReporteDeduccionesPruebaState();
}

class _ReporteDeduccionesPruebaState extends State<ReporteDeduccionesPrueba> {
  String _selectedMes = 'octubre';
  int _selectedAnio = 2025;

  final List<Color> cardColors = [
    const Color(0xFF2E7D32),
    const Color(0xFF39B5DA),
    const Color(0xFFF57C00),
    const Color(0xFF145A32),
    const Color(0xFF1976D2),
  ];

  final List<Map<String, dynamic>> datosPrueba = [
    // OCTUBRE
    {"mes": "octubre", "anio": 2025, "departamento": "Producción",      "empleados": 36, "rap": 83000.0, "ihss": 122000.0, "isr": 75000.0},
    {"mes": "octubre", "anio": 2025, "departamento": "Recursos Humanos",    "empleados": 13, "rap": 27000.0, "ihss": 38000.0,  "isr": 20000.0},
    {"mes": "octubre", "anio": 2025, "departamento": "Ventas",          "empleados": 21, "rap": 50000.0, "ihss": 70000.0,  "isr": 40000.0},
    {"mes": "octubre", "anio": 2025, "departamento": "Administración",  "empleados": 10, "rap": 18000.0, "ihss": 25000.0,  "isr": 17000.0},
    {"mes": "octubre", "anio": 2025, "departamento": "Sistemas",        "empleados": 9,  "rap": 17000.0, "ihss": 24000.0,  "isr": 14000.0},

    // SEPTIEMBRE
    {"mes": "septiembre", "anio": 2025, "departamento": "Producción",      "empleados": 35, "rap": 81000.0, "ihss": 118000.0, "isr": 71000.0},
    {"mes": "septiembre", "anio": 2025, "departamento": "Recursos Humanos",    "empleados": 13, "rap": 26000.0, "ihss": 37500.0,  "isr": 19500.0},
    {"mes": "septiembre", "anio": 2025, "departamento": "Ventas",          "empleados": 22, "rap": 52000.0, "ihss": 72000.0,  "isr": 41000.0},
    {"mes": "septiembre", "anio": 2025, "departamento": "Administración",  "empleados": 10, "rap": 17500.0, "ihss": 24800.0,  "isr": 16800.0},
    {"mes": "septiembre", "anio": 2025, "departamento": "Sistemas",        "empleados": 9,  "rap": 16500.0, "ihss": 23800.0,  "isr": 13800.0},

    // AGOSTO
    {"mes": "agosto", "anio": 2025, "departamento": "Producción",      "empleados": 37, "rap": 85000.0, "ihss": 125000.0, "isr": 78000.0},
    {"mes": "agosto", "anio": 2025, "departamento": "Recursos Humanos",    "empleados": 12, "rap": 25000.0, "ihss": 35000.0,  "isr": 19000.0},
    {"mes": "agosto", "anio": 2025, "departamento": "Ventas",          "empleados": 20, "rap": 48000.0, "ihss": 68000.0,  "isr": 39000.0},
    {"mes": "agosto", "anio": 2025, "departamento": "Administración",  "empleados": 11, "rap": 19000.0, "ihss": 26000.0,  "isr": 17500.0},
    {"mes": "agosto", "anio": 2025, "departamento": "Sistemas",        "empleados": 9,  "rap": 17500.0, "ihss": 24500.0,  "isr": 14200.0},
  ];


  List<DropdownMenuItem<String>> _getMesesDisponibles() {
    final meses = ['agosto', 'septiembre', 'octubre'];
    return meses.map((m) {
      return DropdownMenuItem(
        value: m,
        child: Text(
          '${toBeginningOfSentenceCase(m)} 2025',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }).toList();
  }

  List<Map<String, dynamic>> get datosFiltrados => datosPrueba
      .where((d) => d['mes'] == _selectedMes && d['anio'] == _selectedAnio)
      .toList();

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
  
String get fechaGenerado {
  final ultimoDiaMes = DateTime(_selectedAnio, _getMesNumero(_selectedMes) + 1, 0);
  return DateFormat('dd/MM/yyyy').format(ultimoDiaMes);
}

  
  @override
  Widget build(BuildContext context) {
    final datos = datosFiltrados;
    final fechaTitulo = '${toBeginningOfSentenceCase(_selectedMes)} $_selectedAnio';

    final totalRapGlobal = datos.fold<double>(0, (a, b) => a + (b['rap'] as double));
    final totalIhssGlobal = datos.fold<double>(0, (a, b) => a + (b['ihss'] as double));
    final totalIsrGlobal = datos.fold<double>(0, (a, b) => a + (b['isr'] as double));
    final totalDeducciones = totalRapGlobal + totalIhssGlobal + totalIsrGlobal;
    
    final generadoPor = Global().userName ?? 'Usuario';

    const double maxBarHeight = 180;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Color(0xFFFBF8F6)),
        title: const Text('Reportes mensuales de deducciones', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(opacity: 0.08, child: Image.asset('assets/images/fittlay_imagotipo.png', fit: BoxFit.contain)),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                // FILTRO 
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
                          underline: const SizedBox(),
                          items: _getMesesDisponibles(),
                          onChanged: (v) => v != null ? setState(() => _selectedMes = v) : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text("Departamento de RRHH", style: TextStyle(fontSize: 20, color: Colors.grey[700]))),
                            const Expanded(flex: 4, child: SizedBox()),
                            Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('Fecha: $fechaGenerado', style: TextStyle(fontSize: 20, color: Colors.grey[700])))),
                          ],
                        ),
                      ),
                const SizedBox(height: 20),
                Image.asset('assets/images/fittlay_imagotipo.png', width: 200, height: 200),
                const SizedBox(height: 10),
                const Text('Reporte de Deducciones por Departamento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(fechaTitulo, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 50),

                

                // Tarjetas y gráficas (igual que antes, pero con datos filtrados)
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Text('DEPARTAMENTOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: datos.asMap().entries.map((e) {
                            final i = e.key;
                            final d = e.value;
                            final color = cardColors[i % cardColors.length];
                            final total = (d['rap'] as double) + (d['ihss'] as double) + (d['isr'] as double);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(children: [
                                Card(
                                  elevation: 12,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  child: Container(
                                    width: 240,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [color.withOpacity(0.98), color]),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        const Icon(Icons.people_alt_rounded, size: 24, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('${d['empleados']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ]),
                                      const SizedBox(height: 8),
                                      _buildRow('RAP', _formatCurrency(d['rap'] as double)),
                                      const SizedBox(height: 8),
                                      _buildRow('IHSS', _formatCurrency(d['ihss'] as double)),
                                      const SizedBox(height: 8),
                                      _buildRow('ISR', _formatCurrency(d['isr'] as double)),
                                      const Divider(color: Colors.white30),
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        const Text('Total deducciones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                        Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      ]),
                                    ]),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(d['departamento'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 80),

                // GRÁFICAS
                SizedBox(
                  height: maxBarHeight + 80,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(flex: 3, child: _buildBarras(datos, maxBarHeight)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildDona(totalRapGlobal, totalIhssGlobal, totalIsrGlobal, totalDeducciones, maxBarHeight)),
                  ]),
                ),

                const SizedBox(height: 15),
                Row(children: const [
                  Expanded(flex: 3, child: Center(child: Text('Distribución de deducciones por departamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
                  Expanded(flex: 2, child: Center(child: Text('Porcentaje de distribución de deducciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
                ]),

                Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Generado por: $generadoPor', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                            Text('Página 1 / 1', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarras(List<Map<String, dynamic>> datos, double maxBarHeight) {
    final maxValue = datos.map((e) => (e['rap'] as double) + (e['ihss'] as double) + (e['isr'] as double)).reduce(max);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: max(constraints.maxWidth, datos.length * 100),
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: datos.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final total = (d['rap'] as double) + (d['ihss'] as double) + (d['isr'] as double);
                final color = cardColors[i % cardColors.length];
                final height = (total / maxValue) * maxBarHeight;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(_formatCurrency(total), style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(width: 40, height: height, color: color),
                    const SizedBox(height: 4),
                    SizedBox(width: 80, child: Text(d['departamento'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  ]),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDona(double rap, double ihss, double isr, double total, double maxBarHeight) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendItem(const Color(0xFF145A32), 'RAP'),
        const SizedBox(width: 16),
        _legendItem(const Color(0xFF39B5DA), 'IHSS'),
        const SizedBox(width: 16),
        _legendItem(const Color(0xFFF57C00), 'ISR'),
      ]),
      const Spacer(),
      SizedBox(
        width: 180,
        height: maxBarHeight,
        child: PieChart(PieChartData(
          centerSpaceRadius: 50,
          sectionsSpace: 2,
          sections: [
            PieChartSectionData(color: const Color(0xFF2E7D32), value: rap, title: '${(rap / total * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            PieChartSectionData(color: const Color(0xFF39B5DA), value: ihss, title: '${(ihss / total * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            PieChartSectionData(color: const Color(0xFFF57C00), value: isr, title: '${(isr / total * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        )),
      ),
    ]);
  }

  Widget _buildRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
    ]);
  }

  Widget _legendItem(Color color, String text) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12)),
    ]);
  }
}