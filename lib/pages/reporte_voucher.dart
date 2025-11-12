// voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rrhfit_sys32/globals.dart';

// === TEMA ===
class AppTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF145A32);
  static const Color accent = Color(0xFFF57C00);
  static const Color bg = Color(0xFFF7F4F1);
  static const Color cream = Color(0xFFFBF8F6);
  static const Color blue = Color(0xFF39B5DA);
  static const Color black = Colors.black45;
}

// === DATOS DE PRUEBA (VALORES GRANDES + 2 MESES SIN PENDIENTES) ===
final List<Map<String, dynamic>> datosPruebaVouchers = [
  // AGOSTO 2025 → 120 generados, 120 enviados, 0 pendientes
  ...List.generate(120, (i) => {
    "mes": "agosto",
    "anio": 2025,
    "nombre": "Empleado ${i + 1}",
    "dni": "0801-199${i + 100}-00${i % 100}",
    "estado": "Enviado",
    "fecha_creado": DateTime(2025, 8, 1 + (i % 30)),
    "sueldo_neto": 8000.00 + (i * 45),
  }),

  // SEPTIEMBRE 2025 → 135 generados, 95 enviados, 40 pendientes
  ...List.generate(95, (i) => {
    "mes": "septiembre",
    "anio": 2025,
    "nombre": "Empleado ${i + 121}",
    "dni": "0801-199${i + 121}-00${(i + 121) % 100}",
    "estado": "Enviado",
    "fecha_creado": DateTime(2025, 9, 1 + (i % 29)),
    "sueldo_neto": 8500.00 + (i * 55),
  }),
  ...List.generate(40, (i) => {
    "mes": "septiembre",
    "anio": 2025,
    "nombre": "Empleado ${i + 216}",
    "dni": "0801-199${i + 216}-00${(i + 216) % 100}",
    "estado": "Generado",
    "fecha_creado": DateTime(2025, 9, 1 + ((i + 95) % 29)),
    "sueldo_neto": 8200.00 + (i * 60),
  }),

  // OCTUBRE 2025 → 110 generados, 110 enviados, 0 pendientes
  ...List.generate(110, (i) => {
    "mes": "octubre",
    "anio": 2025,
    "nombre": "Empleado ${i + 256}",
    "dni": "0801-199${i + 256}-00${(i + 256) % 100}",
    "estado": "Enviado",
    "fecha_creado": DateTime(2025, 10, 1 + (i % 30)),
    "sueldo_neto": 8700.00 + (i * 50),
  }),
];

class VoucherScreen1 extends StatefulWidget {
  const VoucherScreen1({super.key});

  @override
  State<VoucherScreen1> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen1> {
  String _selectedMes = 'octubre';
  int _selectedAnio = 2025;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_HN', null);
  }

  // === FILTRO DE MESES ===
  List<DropdownMenuItem<String>> _getMesesDisponibles() {
    final meses = ['agosto', 'septiembre', 'octubre'];
    return meses.map((m) {
      final mes = toBeginningOfSentenceCase(m)!;
      return DropdownMenuItem(value: m, child: Text('$mes 2025'));
    }).toList();
  }

  // === ÚLTIMO DÍA DEL MES ===
  String _getFechaGenerado() {
    const meses = {
      'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
      'julio': 7, 'agosto': 8, 'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12
    };
    final mesNum = meses[_selectedMes] ?? 11;
    final ultimoDia = DateTime(_selectedAnio, mesNum + 1, 0);
    return DateFormat('dd/MM/yyyy').format(ultimoDia);
  }

  // === DATOS FILTRADOS ===
  List<Map<String, dynamic>> _getDatosFiltrados() {
    return datosPruebaVouchers
        .where((d) => d['mes'] == _selectedMes && d['anio'] == _selectedAnio)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final fechaReporte = '${toBeginningOfSentenceCase(_selectedMes)} $_selectedAnio';
    final fechaGenerado = _getFechaGenerado();
    final generadoPor = Global().userName ?? 'Usuario';
    final datos = _getDatosFiltrados();

    final totalGenerados = datos.length;
    final enviados = datos.where((d) => d['estado'] == 'Enviado').length;
    final pendientes = totalGenerados - enviados;
    final montoTotal = datos.fold<double>(0, (sum, d) => sum + (d['sueldo_neto'] as double));

    // Evitar división por cero
    final total = totalGenerados > 0 ? totalGenerados : 1;
    final porcEnviado = (enviados / total * 100).round();
    final porcPendiente = (pendientes / total * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Estado general de vouchers',
          style: TextStyle(color: Color(0xFFFBF8F6), fontWeight: FontWeight.w600, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFBF8F6)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, bottom: 100, left: 20, right: 20),
        child: Stack(
          children: [
            // === MARCA DE AGUA DENTRO DEL SCROLL (se mueve con el contenido) ===
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/fittlay_imagotipo.png',
                  fit: BoxFit.contain,
                  repeat: ImageRepeat.repeatY,
                  alignment: Alignment.center,
                ),
              ),
            ),

            // === CONTENIDO PRINCIPAL ===
            Column(
              children: [
                // === 1. FILTRO DE MES/AÑO (LO PRIMERO) ===
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

                // === 2. HEADER (debajo del filtro) ===
                Container(
                  color: AppTheme.bg,
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
                Image.asset('assets/images/fittlay_imagotipo.png', width: 150, height: 150),
                const SizedBox(height: 8),
                const Text('Reporte Histórico de Vouchers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(fechaReporte, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 30),

                // === CARD 1: ESTADO GENERAL ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text('Estado General de Vouchers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildMiniCard(label: 'Generado', value: totalGenerados, color: AppTheme.primary, icon: Icons.fact_check)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiniCard(label: 'Enviado', value: enviados, color: AppTheme.blue, icon: Icons.send)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiniCard(label: 'Pendiente', value: pendientes, color: AppTheme.accent, icon: Icons.hourglass_empty)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '**Visualización del estado actual del proceso de vouchers correspondientes al mes de $fechaReporte.**',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 30),

                // === CARD 2: GRÁFICOS + MONTO TOTAL ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // DONA: ENVÍO
                          Expanded(
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  _buildColorIndicator(AppTheme.blue, 'Enviado'),
                                  const SizedBox(width: 6),
                                  _buildColorIndicator(AppTheme.accent, 'Pendiente'),
                                ]),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 250,
                                  child: PieChart(
                                    PieChartData(
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(value: porcEnviado.toDouble(), color: AppTheme.blue, title: '$porcEnviado%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        PieChartSectionData(value: porcPendiente.toDouble(), color: AppTheme.accent, title: '$porcPendiente%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // MONTO TOTAL
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 150,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.attach_money, color: Colors.black, size: 24)),
                                          const SizedBox(width: 12),
                                          const Expanded(child: Text('TOTAL PAGOS', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5))),
                                        ],
                                      ),
                                      const Spacer(),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text('L ${NumberFormat('#,##0.00', 'es_HN').format(montoTotal)}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // PASTEL: 3 ESTADOS
                          Expanded(
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  _buildColorIndicator(AppTheme.primary, 'Generado'),
                                  const SizedBox(width: 6),
                                  _buildColorIndicator(AppTheme.blue, 'Enviado'),
                                  const SizedBox(width: 6),
                                  _buildColorIndicator(AppTheme.accent, 'Pendiente'),
                                ]),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 250,
                                  child: Builder(
                                    builder: (context) {
                                      final generados = totalGenerados;
                                      final enviadosCount = enviados;
                                      final pendientesCount = pendientes;

                                      final sumaTotal = generados + enviadosCount + pendientesCount;
                                      final porcGenerado = sumaTotal > 0 ? (generados / sumaTotal * 100).round() : 0;
                                      final porcEnviado = sumaTotal > 0 ? (enviadosCount / sumaTotal * 100).round() : 0;
                                      final porcPendiente = sumaTotal > 0 ? (pendientesCount / sumaTotal * 100).round() : 0;

                                      return PieChart(
                                        PieChartData(
                                          centerSpaceRadius: 0,
                                          sections: [
                                            PieChartSectionData(
                                              value: porcGenerado.toDouble(),
                                              color: AppTheme.primary,
                                              title: '$porcGenerado%',
                                              radius: 95,
                                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            PieChartSectionData(
                                              value: porcEnviado.toDouble(),
                                              color: AppTheme.blue,
                                              title: '$porcEnviado%',
                                              radius: 95,
                                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            PieChartSectionData(
                                              value: porcPendiente.toDouble(),
                                              color: AppTheme.accent,
                                              title: '$porcPendiente%',
                                              radius: 95,
                                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Expanded(child: Center(child: Text('Porcentaje de envío exitoso', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
                          Expanded(child: Center(child: Text('Monto total pagado en vouchers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
                          Expanded(child: Center(child: Text('Distribución del estado de vouchers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
                        ],
                      ),
                    ],
                  ),
                ),

                // === FOOTER ===
                const SizedBox(height: 40),
                Container(
                  color: AppTheme.bg,
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
          ],
        ),
      ),
    );
  }

  // === WIDGETS AUXILIARES ===
  Widget _buildMiniCard({required String label, required int value, required Color color, required IconData icon}) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Align(alignment: Alignment.topLeft, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: Colors.black, size: 24))),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(value.toString(), style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildColorIndicator(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}