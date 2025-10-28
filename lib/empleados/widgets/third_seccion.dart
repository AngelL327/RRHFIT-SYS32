import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';
import 'package:rrhfit_sys32/empleados/models/empleado_model.dart';

class ThirdSeccion extends StatelessWidget {
  final EmpleadoController controller;

  const ThirdSeccion({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: StreamBuilder<List<Empleado>>(
        stream: controller.empleadosStream,
        builder: (context, snapshot) {
          final empleados = snapshot.data ?? [];

          final totalActivos = empleados
              .where((e) => (e.estado ?? '').toLowerCase() == 'activo')
              .length;
          final total = empleados.length;
          final empleadosPorDept = _groupByDepartamento(empleados, controller);
          final antiguedadPromedio = _calcularAntiguedadPromedio(empleados);
          final nuevos30dias = _empleadosNuevosEnDias(empleados, 30);
          final cumpleaniosProximos = _cumpleanosProximos(empleados, 30);
          final expiracionContratos = _contratosPorVencer(empleados, 30);
          // final salarioStats = _calcularDistribucionSalarial(empleados);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resumen de Recursos Humanos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Grid de tarjetas de métricas
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      _buildMetricCard(
                        width: isWide
                            ? (constraints.maxWidth - 48) / 3
                            : constraints.maxWidth,
                        title: 'Total Empleados Activos',
                        child: _metricNumber(
                          totalActivos.toString(),
                          subtitle: 'de $total',
                        ),
                      ),
                      _buildMetricCard(
                        width: isWide
                            ? (constraints.maxWidth - 48) / 3
                            : constraints.maxWidth,
                        title: 'Antigüedad Promedio',
                        child: _metricNumber(
                          antiguedadPromedio != null
                              ? '${antiguedadPromedio.toStringAsFixed(1)} yrs'
                              : '-',
                        ),
                      ),
                      _buildMetricCard(
                        width: isWide
                            ? (constraints.maxWidth - 48) / 3
                            : constraints.maxWidth,
                        title: 'Nuevos',
                        child: _metricNumber(nuevos30dias.length.toString()),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _departamentoPieCard(empleadosPorDept),
                            ),
                            const SizedBox(width: 12),
                            // Expanded(
                            //   child: _salarioDistributionCard(salarioStats),
                            // ),
                          ],
                        )
                      : Column(
                          children: [
                            _departamentoPieCard(empleadosPorDept),
                            const SizedBox(height: 12),
                            // _salarioDistributionCard(salarioStats),
                          ],
                        );
                },
              ),

              const SizedBox(height: 12),

              // Alertas
              _alertasCard(
                cumpleanios: cumpleaniosProximos,
                contratos: expiracionContratos,
                nuevos: nuevos30dias,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 100),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricNumber(String value, {String? subtitle}) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        if (subtitle != null)
          Text(subtitle, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Map<String, int> _groupByDepartamento(
    List<Empleado> empleados,
    EmpleadoController controller,
  ) {
    final Map<String, int> map = {};
    for (final e in empleados) {
      final deptName =
          controller.getDepartamentoNombre(e.departamentoId) ??
          'Sin departamento';
      map[deptName] = (map[deptName] ?? 0) + 1;
    }
    return map;
  }

  Widget _departamentoPieCard(Map<String, int> data) {
    final total = data.values.fold<int>(0, (p, n) => p + n);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Empleados por Departamento',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: total == 0
                  ? Center(child: Text('No hay datos'))
                  : Row(
                      children: [
                        Expanded(flex: 1, child: PieChartWidget(data: data)),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: data.entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        _legendDot(e.key, e.value / total),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${((e.value / total) * 100).toStringAsFixed(1)}%',
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, double fraction) {
    final color = PieChartWidget.colorForLabel(label);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Widget _salarioDistributionCard(SalaryDistribution stats) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(14),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [],
  //       ),
  //     ),
  //   );
  // }

  Widget _alertasCard({
    required List<Empleado> cumpleanios,
    required List<Empleado> contratos,
    required List<Empleado> nuevos,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallAlert(
                  'Cumpleaños próximos',
                  cumpleanios.length,
                  color: Colors.purple,
                ),
                _smallAlert(
                  'Contratos por vencer',
                  contratos.length,
                  color: Colors.orange,
                ),
                _smallAlert(
                  'Empleados nuevos',
                  nuevos.length,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cumpleanios.isEmpty && contratos.isEmpty && nuevos.isEmpty)
              const Text('Sin alertas por el momento.')
            else
              Column(
                children: [
                  if (cumpleanios.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Cumpleaños próximos:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...cumpleanios.map(
                      (e) => _empleadoTile(
                        e,
                        badge:
                            'Cumple el ${DateFormat('dd MMM').format(e.fechaNacimiento!)}',
                      ),
                    ),
                  ],
                  if (contratos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Contratos por vencer:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...contratos.map(
                      (e) => _empleadoTile(
                        e,
                        badge:
                            'Vence ${DateFormat('dd MMM').format(e.fechaFinContrato!)}',
                      ),
                    ),
                  ],
                  if (nuevos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Empleados nuevos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...nuevos.map(
                      (e) => _empleadoTile(
                        e,
                        badge:
                            'Desde ${DateFormat('dd MMM').format(e.fechaContratacion!)}',
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallAlert(String title, int count, {Color? color}) {
    return Chip(
      backgroundColor: (color ?? Colors.blue).withOpacity(0.12),
      label: Text(
        '$title — $count',
        style: TextStyle(color: (color ?? Colors.blue.shade700)),
      ),
    );
  }

  Widget _empleadoTile(Empleado e, {String? badge}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(e.nombre ?? '-'),
      subtitle: Text(e.correo ?? '-'),
      trailing: badge != null
          ? Chip(label: Text(badge, style: const TextStyle(fontSize: 12)))
          : null,
    );
  }

  double? _calcularAntiguedadPromedio(List<Empleado> empleados) {
    final fechas = empleados
        .where((e) => e.fechaContratacion != null)
        .map((e) => e.fechaContratacion!)
        .toList();
    if (fechas.isEmpty) return null;
    final now = DateTime.now();
    final totalYears = fechas.fold<double>(0.0, (prev, f) {
      final diff = now.difference(f).inDays / 365.25;
      return prev + diff;
    });
    return totalYears / fechas.length;
  }

  List<Empleado> _empleadosNuevosEnDias(List<Empleado> empleados, int dias) {
    final limite = DateTime.now().subtract(Duration(days: dias));
    return empleados
        .where(
          (e) =>
              e.fechaContratacion != null &&
              e.fechaContratacion!.isAfter(limite),
        )
        .toList();
  }

  List<Empleado> _cumpleanosProximos(List<Empleado> empleados, int dias) {
    final now = DateTime.now();
    final end = now.add(Duration(days: dias));
    List<Empleado> result = [];
    for (final e in empleados) {
      final bd = e.fechaNacimiento;
      if (bd == null) continue;
      final thisYearBd = DateTime(now.year, bd.month, bd.day);
      DateTime candidate = thisYearBd;
      if (candidate.isBefore(now))
        candidate = DateTime(now.year + 1, bd.month, bd.day);
      if (!candidate.isAfter(end)) result.add(e);
    }
    result.sort((a, b) {
      final aBd = a.fechaNacimiento!;
      final bBd = b.fechaNacimiento!;
      final aCandidate = DateTime(now.year, aBd.month, aBd.day).isBefore(now)
          ? DateTime(now.year + 1, aBd.month, aBd.day)
          : DateTime(now.year, aBd.month, aBd.day);
      final bCandidate = DateTime(now.year, bBd.month, bBd.day).isBefore(now)
          ? DateTime(now.year + 1, bBd.month, bBd.day)
          : DateTime(now.year, bBd.month, bBd.day);
      return aCandidate.compareTo(bCandidate);
    });
    return result;
  }

  List<Empleado> _contratosPorVencer(List<Empleado> empleados, int dias) {
    final now = DateTime.now();
    final end = now.add(Duration(days: dias));
    return empleados
        .where(
          (e) =>
              e.fechaFinContrato != null &&
              e.fechaFinContrato!.isAfter(now) &&
              e.fechaFinContrato!.isBefore(end),
        )
        .toList();
  }

  SalaryDistribution _calcularDistribucionSalarial(List<Empleado> empleados) {
    final salarios = empleados
        .where((e) => (e.salario != null))
        .map((e) => e.salario!.toDouble())
        .toList();
    if (salarios.isEmpty) return SalaryDistribution.empty();

    salarios.sort();
    final min = salarios.first;
    final max = salarios.last;
    if (min == max) {
      return SalaryDistribution.single(salarios.length, min);
    }

    final buckets = <String, int>{};
    final span = (max - min) / 5;
    for (int i = 0; i < 5; i++) {
      final start = min + span * i;
      final end = (i == 4) ? max : (min + span * (i + 1));
      final label = '${start.toStringAsFixed(0)} - ${end.toStringAsFixed(0)}';
      buckets[label] = 0;
    }

    for (final s in salarios) {
      final index = ((s - min) / (max - min) * 5).floor().clamp(0, 4);
      final start = min + span * index;
      final end = (index == 4) ? max : (min + span * (index + 1));
      final label = '${start.toStringAsFixed(0)} - ${end.toStringAsFixed(0)}';
      buckets[label] = (buckets[label] ?? 0) + 1;
    }

    return SalaryDistribution(buckets: buckets);
  }
}

class SalaryDistribution {
  final Map<String, int> buckets;
  SalaryDistribution({required this.buckets});
  SalaryDistribution.empty() : buckets = {};
  SalaryDistribution.single(int total, double value)
    : buckets = {'${value.toStringAsFixed(0)}': total};

  bool get hasData => buckets.isNotEmpty;
  int get total => buckets.values.fold(0, (p, n) => p + n);
}

class PieChartWidget extends StatelessWidget {
  final Map<String, int> data;
  const PieChartWidget({super.key, required this.data});

  static final List<Color> _palette = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.cyan,
    Colors.pink,
  ];

  static Color colorForLabel(String label) {
    final hash = label.codeUnits.fold<int>(0, (p, c) => p + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (p, n) => p + n);
    final entries = data.entries.toList();
    return CustomPaint(
      painter: _PiePainter(entries, total),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Empleados', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  _PiePainter(this.entries, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = min(size.width, size.height) * 0.45;
    final paint = Paint()..style = PaintingStyle.fill;
    double startRadian = -pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final sweep = (entry.value / (total == 0 ? 1 : total)) * 2 * pi;
      paint.color = PieChartWidget.colorForLabel(entry.key);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRadian,
        sweep,
        true,
        paint,
      );
      startRadian += sweep;
    }

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
