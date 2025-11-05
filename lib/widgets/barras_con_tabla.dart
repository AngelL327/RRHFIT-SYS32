import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum BarrasModo { estadoPorDepto, tipo }

class BarrasConTabla extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final BarrasModo modo;

  const BarrasConTabla({required this.docs, required this.modo, super.key});

  @override
  Widget build(BuildContext context) {
    const colorPend = Color(0xFFF57C00);
    const colorApr = Color(0xFF2E8B57);
    const colorRec = Color(0xFF1FA9D6);

    Map<String, Map<String, int>> data = {};

    //  Generar los datos agrupados
    for (var d in docs) {
      final m = d.data() as Map<String, dynamic>;
      final cat = modo == BarrasModo.estadoPorDepto
          ? (m["departamento"] ?? "Sin depto").toString()
          : (m["tipo"] ?? "Sin tipo").toString();
      final est = (m["estado"] ?? "Pendiente").toString();

      data.putIfAbsent(
        cat,
        () => {"Aprobada": 0, "Rechazada": 0, "Pendiente": 0},
      );
      data[cat]![est] = (data[cat]![est] ?? 0) + 1;
    }

    //  Tomar máximo 4 categorías
    final keys = data.keys.take(5).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- GRÁFICO DE BARRAS ---
        SizedBox(
          width: 700, // ancho fijo o adaptable según tu layout
          height: 300,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              alignment: BarChartAlignment.center,
              barGroups: List.generate(keys.length, (i) {
                final item = data[keys[i]]!;
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: item["Pendiente"]!.toDouble(),
                      color: colorPend,
                      width: 36,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: item["Aprobada"]!.toDouble(),
                      color: colorApr,
                      width: 36,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: item["Rechazada"]!.toDouble(),
                      color: colorRec,
                      width: 36,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      if (v.toInt() >= keys.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          keys[v.toInt()],
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),

        const SizedBox(width: 100), // separación horizontal
        // --- TABLA ---
        SizedBox(
          width: 500, // ajusta este valor a tu gusto (entre 250 y 320 va bien)
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // evita que se alargue innecesariamente
              children: [
                Row(
                  children: [
                    const Flexible(
                      flex: 2,
                      child: Text(
                        "Categoría                                    ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 10, height: 10, color: colorApr),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              "Aprobadas",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 10, height: 10, color: colorRec),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              "Rechazadas",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 10, height: 10, color: colorPend),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              "Pendientes",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(),
                ...keys.map((k) {
                  final i = data[k]!;
                  return Row(
                    children: [
                      Expanded(flex: 2, child: Text(k)),
                      Expanded(child: Center(child: Text("${i["Aprobada"]}"))),
                      Expanded(child: Center(child: Text("${i["Rechazada"]}"))),
                      Expanded(child: Center(child: Text("${i["Pendiente"]}"))),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
