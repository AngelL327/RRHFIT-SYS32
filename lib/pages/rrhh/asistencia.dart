import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _notaCtrl = TextEditingController();
  String? _empleadoSeleccionado;
  TimeOfDay? _entradaManual;
  TimeOfDay? _salidaManual;

  int presentes = 0;
  int tardanzas = 0;
  int horasRegulares = 80;
  int horasExtra = 2;
  int horasNocturnas = 16;

  String get horaActual =>
      DateFormat('hh:mm a').format(DateTime.now()).toLowerCase();

  // 🔹 Registrar entrada o salida
  Future<void> registrarAsistencia(String tipo) async {
    if (_empleadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione un empleado.")),
      );
      return;
    }

    final empleadoId = _empleadoSeleccionado!;
    final ahora = DateTime.now();
    final fechaClave = '${ahora.day}-${ahora.month}-${ahora.year}';
    final docRef = _db.collection('asistencias').doc('${empleadoId}_$fechaClave');

    final doc = await docRef.get();

    if (tipo == 'Entrada') {
      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La entrada ya fue registrada.")),
        );
        return;
      }
      await docRef.set({
        'empleado_id': empleadoId,
        'entrada': ahora,
        'salida': null,
        'fecha': DateTime(ahora.year, ahora.month, ahora.day),
        'notas': '',
        'estado': 'Presente',
      });
    } else {
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Primero registre la entrada.")),
        );
        return;
      }
      await docRef.update({'salida': ahora});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tipo registrada con éxito')),
    );
  }

  // 🔹 Registrar manualmente
  Future<void> registrarManual() async {
    if (_empleadoSeleccionado == null ||
        _entradaManual == null ||
        _salidaManual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete todos los campos.")),
      );
      return;
    }

    final ahora = DateTime.now();
    final entrada = DateTime(
        ahora.year, ahora.month, ahora.day, _entradaManual!.hour, _entradaManual!.minute);
    final salida = DateTime(
        ahora.year, ahora.month, ahora.day, _salidaManual!.hour, _salidaManual!.minute);

    await _db.collection('asistencias').add({
      'empleado_id': _empleadoSeleccionado,
      'entrada': entrada,
      'salida': salida,
      'fecha': DateTime(ahora.year, ahora.month, ahora.day),
      'notas': _notaCtrl.text,
      'estado': 'Presente',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registro manual guardado.")),
    );

    _notaCtrl.clear();
  }

  // 🔹 Tarjeta resumen
  Widget resumenBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '--:--';
    final date = ts.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  Future<String> _getEmpleadoNombre(String empleadoId) async {
    final doc = await _db.collection('empleados').doc(empleadoId).get();
    return doc.exists ? doc['nombre'] : 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
            title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Asistencia - Gestión de asistencia de empleados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 150, 32, 1),
        foregroundColor: const Color.fromARGB(255, 251, 255, 250),
        elevation: 0,
        centerTitle: true,
       
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(0, 150, 32, 1), 
                Color.fromRGBO(50, 200, 120, 1), 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
        
            SizedBox(
              width: screenWidth * 0.355,
              child: SingleChildScrollView(
                child: Column(
                  children: [
  
                    GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
            
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        resumenBox("Presentes", "$presentes", Colors.green, Icons.people),
                        resumenBox("Tardanzas", "$tardanzas", Colors.orange, Icons.warning),
                
                        resumenBox("Extras", "${horasExtra}h", Colors.blue, Icons.trending_up),
                        resumenBox("Nocturnas", "${horasNocturnas}h", Colors.purple, Icons.nightlight_round),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text("Registro Rápido",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Icon(Icons.access_time, color: Colors.green, size: 80),
                            Text(horaActual,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _db.collection('empleados').snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const CircularProgressIndicator();
                                final empleados = snapshot.data!.docs;
                                return DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text("Seleccione un empleado"),
                                  value: _empleadoSeleccionado,
                                  items: empleados.map((e) {
                                    final nombre = e['nombre'];
                                    final id = e.id;
                                    return DropdownMenuItem(
                                        value: id, child: Text(nombre));
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _empleadoSeleccionado = val),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => registrarAsistencia("Entrada"),
                                  icon: const Icon(Icons.login),
                                  label: const Text("Entrada"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                ),
                                const SizedBox(width: 20),
                                ElevatedButton.icon(
                                  onPressed: () => registrarAsistencia("Salida"),
                                  icon: const Icon(Icons.logout),
                                  label: const Text("Salida"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Registro Manual",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration:
                                        const InputDecoration(labelText: 'Hora de Entrada'),
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        setState(() => _entradaManual = picked);
                                      }
                                    },
                                    controller: TextEditingController(
                                        text: _entradaManual != null
                                            ? _entradaManual!.format(context)
                                            : ''),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration:
                                        const InputDecoration(labelText: 'Hora de Salida'),
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        setState(() => _salidaManual = picked);
                                      }
                                    },
                                    controller: TextEditingController(
                                        text: _salidaManual != null
                                            ? _salidaManual!.format(context)
                                            : ''),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _notaCtrl,
                              decoration: const InputDecoration(
                                labelText: "Notas (opcional)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: registrarManual,
                                icon: const Icon(Icons.save),
                                label: const Text("Guardar Manual"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("  Asistencia de Hoy",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('asistencias')
                          .where('fecha',
                              isEqualTo: DateTime(DateTime.now().year,
                                  DateTime.now().month, DateTime.now().day))
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;
                        presentes = docs.length;

                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: Future.wait(docs.map((d) async {
                            final nombre = await _getEmpleadoNombre(d['empleado_id']);
                            return {
                              'nombre': nombre,
                              'entrada': d['entrada'],
                              'salida': d['salida'],
                              'estado': d['estado']
                            };
                          })),
                          builder: (context, futureSnap) {
                            if (!futureSnap.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final data = futureSnap.data!;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingTextStyle:
                                    const TextStyle(fontWeight: FontWeight.bold),
                                columns: const [
                                  DataColumn(label: Text("Empleado")),
                                  DataColumn(label: Text("Entrada")),
                                  DataColumn(label: Text("Salida")),
                                  DataColumn(label: Text("Estado")),
                                ],
                                rows: data.map((d) {
                                  return DataRow(cells: [
                                    DataCell(Text(d['nombre'])),
                                    DataCell(Text(_formatTime(d['entrada']))),
                                    DataCell(Text(_formatTime(d['salida']))),
                                    DataCell(Text(d['estado'] ?? '')),
                                  ]);
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
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
}
