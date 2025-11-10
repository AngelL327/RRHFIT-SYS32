import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:rrhfit_sys32/widgets/barras_con_tabla.dart';
import 'package:rrhfit_sys32/Reportes/reportesolicitudes.dart';

class ReporteSolicitudesWidget extends StatelessWidget {
  const ReporteSolicitudesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection("solicitudes").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No hay solicitudes registradas."));
        }

        final totalPend = docs.where((d) => d["estado"] == "Pendiente").length;
        final totalApr = docs.where((d) => d["estado"] == "Aprobada").length;
        final totalRec = docs.where((d) => d["estado"] == "Rechazada").length;
        final totalGlobal = totalPend + totalApr + totalRec;

        final Map<String, int> porDepto = {};
        docs.forEach((d) {
          final data = d.data() as Map<String, dynamic>;
          final depto = data["departamento"]?.toString();
          if (depto != null && depto.isNotEmpty) {
            porDepto[depto] = (porDepto[depto] ?? 0) + 1;
          }
        });

        final totalDeptos = porDepto.values.fold<int>(0, (a, b) => a + b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenerarReportePage(docs: docs),
                    ),
                  );
                },

                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generar Reporte PDF"),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Primera dona con su título arriba
                  Column(
                    children: [
                      _titulo("Solicitudes totales"),
                      const SizedBox(height: 30),
                      _donaSimple(totalGlobal, [
                        _DonaItem(
                          "Pendientes",
                          totalPend,
                          const Color(0xFFF57C00),
                        ),
                        _DonaItem(
                          "Rechazadas",
                          totalRec,
                          const Color(0xFF1FA9D6),
                        ),
                        _DonaItem(
                          "Aprobadas",
                          totalApr,
                          const Color(0xFF2E8B57),
                        ),
                      ]),
                    ],
                  ),

                  const SizedBox(width: 180), // Espacio entre las dos donas
                  //  Segunda dona con su título arriba
                  Column(
                    children: [
                      _titulo("Solicitudes por área"),
                      const SizedBox(height: 30),
                      _donaSimple(
                        totalDeptos,
                        porDepto.entries.map((e) {
                          Color color;
                          switch (e.key) {
                            case "Producción":
                              color = const Color(0xFF4CAF50); // verde
                              break;
                            case "Recursos Humanos":
                              color = const Color(0xFFFFA726); // naranja
                              break;
                            case "Ventas":
                              color = const Color(0xFF29B6F6); // celeste
                              break;
                            case "Administración":
                              color = const Color(0xFFAB47BC); // morado
                              break;
                            case "Sistemas":
                              color = const Color(0xFFFF7043); // coral
                              break;
                            default:
                              color = Colors.blueGrey; // color por defecto
                          }

                          return _DonaItem(e.key, e.value, color);
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _titulo("Solicitudes por estado y departamento (máximo 4)"),
              BarrasConTabla(docs: docs, modo: BarrasModo.estadoPorDepto),

              const SizedBox(height: 30),

              _titulo("Tipos de solicitudes (máximo 4)"),
              BarrasConTabla(docs: docs, modo: BarrasModo.tipo),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _titulo(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  // ---------- VERSIÓN LADO A LADO: DONA A LA IZQUIERDA, TABLA A LA DERECHA ----------
  Widget _donaSimple(int total, List<_DonaItem> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caja fija para la dona
        SizedBox(
          width: 230,
          height: 230,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 55,
              borderData: FlBorderData(show: false),
              sectionsSpace: 1,
              sections: items.map((e) {
                final porc = total == 0 ? 0 : (e.valor / total) * 100;
                return PieChartSectionData(
                  color: e.color,
                  radius: 55,
                  value: e.valor.toDouble(),
                  title: "${porc.toStringAsFixed(1)}%",
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(width: 16), // separación entre dona y tabla
        // Tabla a la derecha que ocupa el espacio restante
        SizedBox(
          width: 300,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado de la tabla
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      flex: 4,
                      child: Text(
                        "Categoría",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          "% del total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Cantidad",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Filas con los datos
                ...items.map((e) {
                  final porc = total == 0 ? 0 : (e.valor / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              // indicador de color pequeño
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: e.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  e.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text("${porc.toStringAsFixed(1)}%"),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text("${e.valor}"),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------------
}
// ---------------- PDF ----------------

class _DonaItem {
  final String label;
  final int valor;
  final Color color;
  _DonaItem(this.label, this.valor, this.color);
}
