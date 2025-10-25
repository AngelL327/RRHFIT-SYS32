import 'package:flutter/material.dart';

class IncapacidadesScreen extends StatelessWidget {
  const IncapacidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final solicitudes = [
      {
        'nombre': 'Andres Leiva',
        'certificado': '#2025-2329',
        'expedicion': '14/10/2025',
        'inicio': '14/10/2025',
        'final': '20/10/2025',
        'estado': 'Pendiente'
      },
      {
        'nombre': 'Merary Argueta',
        'certificado': '#2025-2329',
        'expedicion': '14/10/2025',
        'inicio': '14/10/2025',
        'final': '20/10/2025',
        'estado': 'Validado'
      },
    ];

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
            // Expanded(
            //   child: PaginatedDataTable(
            //       columns: const <DataColumn>[
            //         DataColumn(label: Text("Nombre"))
            //       ], source: DataTableSource<List<DataColumn>>)
            // ),
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



