import 'package:cloud_firestore/cloud_firestore.dart';
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

class ReportePlanillaScreen extends StatelessWidget {
  const ReportePlanillaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fecha actual en español (HN) - SIN StreamBuilder
    final String fechaActual = toBeginningOfSentenceCase(
      DateFormat('MMMM yyyy', 'es_HN').format(DateTime.now()),
    )!;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
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
          // MARCA DE AGUA
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

          // CONTENIDO PRINCIPAL
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/images/fittlay_imagotipo.png', width: 150, height: 150),
                  const SizedBox(height: 8),
                  const Text(
                    'Reporte Histórico de Vouchers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // FECHA DEL MES ACTUAL (CORREGIDA)
                  Text(
                    fechaActual,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // === CARD 1: ESTADO GENERAL (DATOS REALES) ===
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('vouchers').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildLoadingCard();
                      }

                      final docs = snapshot.data!.docs;
                      final totalGenerados = docs.length;
                      final enviados = docs.where((d) => d['estado'] == 'Enviado').length;
                      final pendientes = totalGenerados - enviados;

                      return Container(
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
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
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // TEXTO DESCRIPTIVO (CORREGIDO)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '**Visualización del estado actual del proceso de vouchers correspondientes al mes de $fechaActual.**',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // === CARD 2: GRÁFICOS + MONTO TOTAL (100% REAL EN 3 PARTES) ===
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('vouchers').snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return _buildLoadingCard(height: 400);
    }

    final docs = snapshot.data!.docs;
    final total = docs.length;
    if (total == 0) {
      return _buildEmptyCard();
    }

    // === CONTAR ESTADOS REALES ===
    final generados = docs.where((d) => d['estado'] == 'Generado').length;
    final enviados = docs.where((d) => d['estado'] == 'Enviado').length;
    final pendientes = total - enviados; // ← Pendiente = no enviado

    // === PORCENTAJES QUE SUMAN 100% ===
    final porcGenerado = total > 0 ? (generados / total * 100).round() : 0;
    final porcEnviado = total > 0 ? (enviados / total * 100).round() : 0;
    final porcPendiente = total > 0 ? (pendientes / total * 100).round() : 0;

    // === MONTO TOTAL ===
    final montoTotal = docs.fold<double>(0, (sum, d) {
      final neto = (d['sueldo_neto'] as num?)?.toDouble() ?? 0.0;
      return sum + neto;
    });

    return Container(
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
              // DONA: SOLO ENVÍO (Enviado + Pendiente = 100% del envío)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildColorIndicator(AppTheme.blue, 'Enviado'),
                        const SizedBox(width: 6),
                        _buildColorIndicator(AppTheme.accent, 'Pendiente'),
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
                              value: porcEnviado.toDouble(),
                              color: AppTheme.blue,
                              title: '$porcEnviado%',
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            PieChartSectionData(
                              value: porcPendiente.toDouble(),
                              color: AppTheme.accent,
                              title: '$porcPendiente%',
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
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
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.attach_money, color: Colors.black, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'TOTAL PAGOS',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
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
                              'L ${NumberFormat('#,##0.00', 'es_HN').format(montoTotal)}',
                              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // PASTEL: 3 ESTADOS → 100% DEL TOTAL
              // === PASTEL: 3 PARTES → 100% REAL (TUS REGLAS) ===
Expanded(
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildColorIndicator(AppTheme.primary, 'Generado'),
          const SizedBox(width: 6),
          _buildColorIndicator(AppTheme.blue, 'Enviado'),
          const SizedBox(width: 6),
          _buildColorIndicator(AppTheme.accent, 'Pendiente'),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 250,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('vouchers').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final totalDocs = docs.length;

            // === VALORES DE LAS MINI-CARDS ===
            final generados = totalDocs; // ← Generado = total creado
            final enviados = docs.where((d) => d['estado'] == 'Enviado').length;
            final pendientes = generados - enviados; // ← Pendiente = no enviado

            // === SUMA DE LOS 3 VALORES ===
            final sumaTotal = generados + enviados + pendientes; // ← siempre = generados

            // === PORCENTAJES (TUS REGLAS) ===
            final porcGenerado = sumaTotal > 0 ? (generados / sumaTotal * 100).round() : 0;
            final porcEnviado = sumaTotal > 0 ? (enviados / sumaTotal * 100).round() : 0;
            final porcPendiente = sumaTotal > 0 ? (pendientes / sumaTotal * 100).round() : 0;

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
    );
  },
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

  // === WIDGETS AUXILIARES ===
  Widget _buildMiniCard({required String label, required int value, required Color color, required IconData icon}) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                Text(value.toString(), style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLoadingCard({double height = 200}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cream, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      height: 400,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cream, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: const Center(child: Text("No hay vouchers aún", style: TextStyle(fontSize: 16, color: Colors.grey))),
    );
  }
}