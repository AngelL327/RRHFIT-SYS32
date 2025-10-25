import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/logic/functions/format_date.dart';
import 'package:rrhfit_sys32/logic/incapacidad_function.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:intl/intl.dart';

class IncapacidadesScreen extends StatelessWidget {
  const IncapacidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Solicitudes'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryBox('Solicitudes revisadas:', '10', Colors.green),
                _summaryBox('Solicitudes pendientes:', '23', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: FutureBuilder<List<IncapacidadModel>>( 
                future: getAllIncapacidades(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return const Center(child: Text('No hay incapacidades registradas'));
                  }

                  // Horizontal + vertical scrollable table
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        
                        columns: const [
                          DataColumn(label: Text('Empleado')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Fecha Solicitud')),
                          DataColumn(label: Text('Inicio')),
                          DataColumn(label: Text('Fin')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: list.map((inc) {
                          return DataRow(cells: [
                            DataCell(Text(inc.usuario)),
                            DataCell(Text(inc.tipoSolicitud)),
                            // DataCell(Text(DateFormat('dd-MM-yyyy').format(inc.fechaSolicitud))),
                            // DataCell(Text(DateFormat('dd-MM-yyyy').format(inc.fechaInicioIncapacidad))),
                            // DataCell(Text(DateFormat('dd-MM-yyyy').format(inc.fechaFinIncapacidad))),
                            DataCell(Text(formatDate(inc.fechaSolicitud))),
                            DataCell(Text(formatDate(inc.fechaInicioIncapacidad))),
                            DataCell(Text(formatDate(inc.fechaFinIncapacidad))),
                            DataCell(inc.estado == "Pendiente" ? const Text("Pendiente", style: TextStyle(color: Colors.orange),)
                            : inc.estado == "Aprobada" ? const Text("Aprobada", style: TextStyle(color: Colors.green),)
                            : const Text("Rechazada", style: TextStyle(color: Colors.red),)),
                            
                            DataCell(ElevatedButton(child: Text("Detalles"), onPressed: () {
                              // TODO:Acción al presionar el botón
                            },)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String title, String number, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
          ),
          const SizedBox(height: 4, width: 20,),
          Text(
            number,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}



