import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';

// Tema personalizado
class AppTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF145A32);
  static const Color accent = Color(0xFFF57C00);
  static const Color bg = Color(0xFFF7F4F1);
  static const Color cream = Color(0xFFFBF8F6);
  static const Color blue = Color(0xFF39B5DA);
  static const Color black = Colors.black45;
}

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
      home: const ReportePlanillaScreen(),
    );
  }
}

class ReportePlanillaScreen extends StatelessWidget {
  const ReportePlanillaScreen({super.key});

  @override
  Widget build(BuildContext context) {
final fechaReporte = toBeginningOfSentenceCase(
  DateFormat('MMMM yyyy', 'es_HN').format(DateTime.now())
)!;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
  backgroundColor: AppTheme.cream,
  elevation: 0,
  centerTitle: false, //  Esto alinea el título a la izquierda
  titleSpacing: 16,   //  Espaciado del borde izquierdo
  title: const Text(
    'Estado general de vouchers',
    style: TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
  ),
  iconTheme: const IconThemeData(color: Colors.black87),
),


      body: Stack(
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

          // --- CONTENIDO PRINCIPAL ---
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  Image.asset('assets/images/fittlay_imagotipo.png',
                      width: 150, height: 150),
                  const SizedBox(height: 8),

                  // --- NUEVO TÍTULO DEBAJO DEL LOGO ---
                  const Text(
                    'Reporte Histórico de Vouchers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Fecha
                  Text(
                    fechaReporte,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // --- Primera card grande con mini-cards ---
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
                        const Text(
                          'Estado General de Vouchers',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniCard(
                                label: 'Generado',
                                value: 120,
                                color: AppTheme.primary,
                                icon: Icons.fact_check,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMiniCard(
                                label: 'Enviado',
                                value: 95,
                                color: AppTheme.blue,
                                icon: Icons.send,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMiniCard(
                                label: 'Pendiente',
                                value: 30,
                                color: AppTheme.accent,
                                icon: Icons.hourglass_empty,
                              ),
                            ),
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
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Segunda card grande con dona, card intermedia y pastel ---
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Dona ---
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildColorIndicator(
                                          AppTheme.blue, 'Enviado'),
                                      const SizedBox(width: 6),
                                      _buildColorIndicator(
                                          AppTheme.accent, 'Pendiente'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 250,
                                    child: PieChart(
                                      PieChartData(
                                        centerSpaceRadius: 40,
                                        sections: [
                                          PieChartSectionData(
                                              value: 60,
                                              color: AppTheme.blue,
                                              title: '60%',
                                              titleStyle:
                                                  const TextStyle(
                                                      color: Colors.white)),
                                          PieChartSectionData(
                                              value: 40,
                                              color: AppTheme.accent,
                                              title: '40%',
                                              titleStyle:
                                                  const TextStyle(
                                                      color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // --- Card intermedia ---
                            Expanded(
                              child: Container(
                                height: 250,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.attach_money,
                                              color: Colors.black,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'TOTAL PAGOS',
                                            style: TextStyle(
                                              color: Colors.greenAccent
                                                  .shade100,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        'L 182,000.00',
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // --- Pastel ---
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _buildColorIndicator(
                                          AppTheme.primary, 'Generado'),
                                      const SizedBox(width: 6),
                                      _buildColorIndicator(
                                          AppTheme.blue, 'Enviado'),
                                      const SizedBox(width: 6),
                                      _buildColorIndicator(
                                          AppTheme.accent, 'Pendiente'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 250,
                                    child: PieChart(
                                      PieChartData(
                                        centerSpaceRadius: 0,
                                        sections: [
                                          PieChartSectionData(
                                              value: 50,
                                              color: AppTheme.primary,
                                              title: '50%',
                                              radius: 95,
                                              titleStyle: const TextStyle(
                                                  color: Colors.white)),
                                          PieChartSectionData(
                                              value: 20,
                                              color: AppTheme.blue,
                                              title: '20%',
                                              radius: 95,
                                              titleStyle: const TextStyle(
                                                  color: Colors.white)),
                                          PieChartSectionData(
                                              value: 30,
                                              color: AppTheme.accent,
                                              title: '30%',
                                              radius: 95,
                                              titleStyle: const TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // --- Títulos debajo de cada gráfico/card ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Porcentaje de envío exitoso',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Monto total pagado en vouchers',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Distribución del estado de vouchers',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets auxiliares ---
  Widget _buildMiniCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
