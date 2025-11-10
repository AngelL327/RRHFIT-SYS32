import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rrhfit_sys32/widgets/Reporte_Voucher.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_HN', null);
  }

  @override
Widget build(BuildContext context) {
  final fechaReporte =
      '${toBeginningOfSentenceCase(['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'][DateTime.now().month - 1])} ${DateTime.now().year}';

  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('Reporte de Vouchers'),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      elevation: 0,
    ),

    body: Stack(
      children: [
        // MARCA DE AGUA
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: Image.asset('assets/images/fittlay.png', fit: BoxFit.contain),
          ),
        ),

        // CONTENIDO
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Reporte: $fechaReporte',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // CARD DE INDICADORES
                StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('vouchers').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    final generados = docs.where((d) => d['estado'] == 'Generado').length;
                    final enviados = docs.where((d) => d['estado'] == 'Enviado').length;
                    final pendientes = docs.where((d) => d['estado'] == 'Pendiente').length;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSmallCard(color: Colors.orange, value: generados, label: 'Generados'),
                          _buildSmallCard(color: Colors.green, value: enviados, label: 'Enviados'),
                          _buildSmallCard(color: Colors.blue, value: pendientes, label: 'Pendientes'),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // TABLA DE VOUCHERS
                Container(
                  width: double.infinity,
                  height: 350,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                    ],
                  ),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("vouchers")
                        .orderBy("fecha_creado", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text("No hay vouchers aún"));
                      }

                      return ListView(
                        children: docs.map((d) {
                          final fecha = (d["fecha_creado"] as Timestamp?)?.toDate();
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text("${d["nombre"]} - DNI: ${d["dni"]}"),
                            subtitle: Text(
                              "${d["estado"]} - ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : ''}",
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Aquí puedes abrir el PDF o lo que necesites
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                              child: const Text("Ver", style: TextStyle(color: Colors.white)),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // BOTÓN VERDE ARRIBA A LA DERECHA
        Positioned(
          top: 16,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: () {
              // AQUÍ VA TU REPORTE GENERAL (el que ya tienes)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportePlanillaScreen(), // Cambia por tu pantalla real
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text(
              "GENERAR REPORTE",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.green.withOpacity(0.6),
            ),
          ),
        ),
      ],
    ),
  );
}

  // Mini cards dentro del card grande
  Widget _buildSmallCard({
    required Color color,
    required int value,
    required String label,
  }) {
    return Container(
      width: 100,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
