import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart';
import 'package:rrhfit_sys32/pages/reporte_voucher.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _notaCtrl = TextEditingController();
  
  String? _usuarioSeleccionadoUid;
  String? _usuarioSeleccionadoNombre;
  TimeOfDay? _entradaManual;
  TimeOfDay? _salidaManual;
  TimeOfDay? _almuerzoInicioManual;
  TimeOfDay? _almuerzoFinManual;
  DateTime _fechaSeleccionada = DateTime.now();

  String get horaActual =>
      DateFormat('hh:mm a').format(DateTime.now()).toLowerCase();

  // Obtener referencia a la subcolección de registros
  CollectionReference _getRegistrosCollection(String usuarioUid) {
    return _db
        .collection('asistenciasEmpleados')
        .doc(usuarioUid)
        .collection('registros');
  }

  // Formatear fecha como ID (YYYY-MM-DD)
  String _getFechaDocId(DateTime fecha) {
    return DateFormat('yyyy-MM-dd').format(fecha);
  }

  // Registrar entrada, salida o almuerzo rápido
  Future<void> registrarAsistencia(String tipo) async {
    if (_usuarioSeleccionadoUid == null) {
      _mostrarSnackbar("Seleccione un usuario.", Colors.red);
      return;
    }

    final ahora = DateTime.now();
    final fechaId = _getFechaDocId(ahora);
    final horaFormato = DateFormat('HH:mm:ss').format(ahora);
    
    final docRef = _getRegistrosCollection(_usuarioSeleccionadoUid!).doc(fechaId);
    final doc = await docRef.get();

    final Map<String, dynamic> datos = {
      'fecha': DateFormat('yyyy-MM-dd').format(DateTime(ahora.year, ahora.month, ahora.day)),
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    };

    final docData = doc.data() as Map<String, dynamic>?;

    switch (tipo) {
      case 'Entrada':
        if (doc.exists && docData?['entrada'] != null) {
          _mostrarSnackbar("La entrada ya fue registrada.", Colors.orange);
          return;
        }
        datos['entrada'] = horaFormato;
        datos['entradaTimestamp'] = Timestamp.fromDate(ahora);
        break;

      case 'AlmuerzoInicio':
        if (!doc.exists || docData?['entrada'] == null) {
          _mostrarSnackbar("Primero registre la entrada.", Colors.orange);
          return;
        }
        if (docData?['almuerzoInicio'] != null) {
          _mostrarSnackbar("Ya registró el inicio de almuerzo.", Colors.orange);
          return;
        }
        datos['almuerzoInicio'] = horaFormato;
        datos['almuerzoInicioTimestamp'] = Timestamp.fromDate(ahora);
        break;

      case 'AlmuerzoFin':
        if (!doc.exists || docData?['almuerzoInicio'] == null) {
          _mostrarSnackbar("Primero registre el inicio de almuerzo.", Colors.orange);
          return;
        }
        if (docData?['almuerzoFin'] != null) {
          _mostrarSnackbar("Ya registró el fin de almuerzo.", Colors.orange);
          return;
        }
        datos['almuerzoFin'] = horaFormato;
        datos['almuerzoFinTimestamp'] = Timestamp.fromDate(ahora);
        break;

      case 'Salida':
        if (!doc.exists || docData?['entrada'] == null) {
          _mostrarSnackbar("Primero registre la entrada.", Colors.orange);
          return;
        }
        datos['salida'] = horaFormato;
        datos['salidaTimestamp'] = Timestamp.fromDate(ahora);
        
        // Calcular horas trabajadas
        await _calcularYGuardarHoras(docRef, docData ?? {}, datos);
        break;
    }

    await docRef.set(datos, SetOptions(merge: true));
    _mostrarSnackbar('$tipo registrada con éxito', Colors.green);
    setState(() {}); // Refrescar la lista
  }

  // Registrar manualmente con todos los campos
  Future<void> registrarManual() async {
    if (_usuarioSeleccionadoUid == null) {
      _mostrarSnackbar("Seleccione un usuario.", Colors.red);
      return;
    }

    if (_entradaManual == null) {
      _mostrarSnackbar("Ingrese al menos la hora de entrada.", Colors.red);
      return;
    }

    final fecha = _fechaSeleccionada;
    final fechaId = _getFechaDocId(fecha);

    final Map<String, dynamic> datos = {
      'fecha': DateFormat('yyyy-MM-dd').format(fecha),
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    };

    // Entrada
    if (_entradaManual != null) {
      final entrada = DateTime(fecha.year, fecha.month, fecha.day,
          _entradaManual!.hour, _entradaManual!.minute);
      datos['entrada'] = DateFormat('HH:mm:ss').format(entrada);
      datos['entradaTimestamp'] = Timestamp.fromDate(entrada);
    }

    // Salida
    if (_salidaManual != null) {
      final salida = DateTime(fecha.year, fecha.month, fecha.day,
          _salidaManual!.hour, _salidaManual!.minute);
      datos['salida'] = DateFormat('HH:mm:ss').format(salida);
      datos['salidaTimestamp'] = Timestamp.fromDate(salida);
    }

    // Almuerzo Inicio
    if (_almuerzoInicioManual != null) {
      final almuerzoInicio = DateTime(fecha.year, fecha.month, fecha.day,
          _almuerzoInicioManual!.hour, _almuerzoInicioManual!.minute);
      datos['almuerzoInicio'] = DateFormat('HH:mm:ss').format(almuerzoInicio);
      datos['almuerzoInicioTimestamp'] = Timestamp.fromDate(almuerzoInicio);
    }

    // Almuerzo Fin
    if (_almuerzoFinManual != null) {
      final almuerzoFin = DateTime(fecha.year, fecha.month, fecha.day,
          _almuerzoFinManual!.hour, _almuerzoFinManual!.minute);
      datos['almuerzoFin'] = DateFormat('HH:mm:ss').format(almuerzoFin);
      datos['almuerzoFinTimestamp'] = Timestamp.fromDate(almuerzoFin);
    }

    // Notas
    if (_notaCtrl.text.isNotEmpty) {
      datos['notas'] = _notaCtrl.text;
    }

    final docRef = _getRegistrosCollection(_usuarioSeleccionadoUid!).doc(fechaId);

    // Calcular horas si hay entrada y salida
    if (_entradaManual != null && _salidaManual != null) {
      await _calcularYGuardarHoras(docRef, {}, datos);
    }

    await docRef.set(datos, SetOptions(merge: true));

    _mostrarSnackbar("Registro manual guardado exitosamente.", Colors.green);
    
    // Limpiar campos
    setState(() {
      _entradaManual = null;
      _salidaManual = null;
      _almuerzoInicioManual = null;
      _almuerzoFinManual = null;
      _notaCtrl.clear();
    });
  }

  // Calcular y guardar horas trabajadas
  Future<void> _calcularYGuardarHoras(
    DocumentReference docRef,
    Map<String, dynamic> datosExistentes,
    Map<String, dynamic> datosNuevos,
  ) async {
    try {
      final entradaTs = datosNuevos['entradaTimestamp'] ?? datosExistentes['entradaTimestamp'];
      final salidaTs = datosNuevos['salidaTimestamp'];

      if (entradaTs == null || salidaTs == null) return;

      DateTime entrada = (entradaTs as Timestamp).toDate();
      DateTime salida = (salidaTs as Timestamp).toDate();

      Duration total = salida.difference(entrada);

      // Restar tiempo de almuerzo si existe
      final almuerzoInicioTs = datosNuevos['almuerzoInicioTimestamp'] ?? datosExistentes['almuerzoInicioTimestamp'];
      final almuerzoFinTs = datosNuevos['almuerzoFinTimestamp'] ?? datosExistentes['almuerzoFinTimestamp'];

      if (almuerzoInicioTs != null && almuerzoFinTs != null) {
        DateTime almuerzoInicio = (almuerzoInicioTs as Timestamp).toDate();
        DateTime almuerzoFin = (almuerzoFinTs as Timestamp).toDate();
        Duration almuerzo = almuerzoFin.difference(almuerzoInicio);
        total -= almuerzo;
      }

      if (total.isNegative) total = Duration.zero;

      String formatearDuracion(Duration d) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
      }

      double horasDecimales = total.inMinutes / 60.0;

      datosNuevos['horasTrabajadas'] = formatearDuracion(total);
      datosNuevos['horasDecimales'] = double.parse(horasDecimales.toStringAsFixed(2));
      datosNuevos['totalMinutos'] = total.inMinutes;
    } catch (e) {
      print('Error al calcular horas: $e');
    }
  }

  // Mostrar mensaje
  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Obtener nombre del usuario
  Future<String> _getUsuarioNombre(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      return doc.exists ? doc['nombre'] ?? 'Sin nombre' : 'Desconocido';
    } catch (e) {
      return 'Error';
    }
  }

  // Selector de tiempo
  Future<void> _seleccionarTiempo(
    BuildContext context,
    String label,
    Function(TimeOfDay) onSelected,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(0, 150, 32, 1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  // Selector de fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(0, 150, 32, 1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Asistencia Manual - Registro para personal sin computadora',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                Color.fromRGBO(50, 200, 120, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo - Formularios
            SizedBox(
              width: screenWidth * 0.35,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Registro Rápido
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              "⚡ Registro Rápido",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Icon(
                              Icons.access_time,
                              color: Colors.green[700],
                              size: 70,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              horaActual,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Dropdown de usuarios
                            StreamBuilder<QuerySnapshot>(
                              stream: _db.collection('usuarios').snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }
                                final usuarios = snapshot.data!.docs;
                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: "Seleccione un usuario",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                  value: _usuarioSeleccionadoUid,
                                  items: usuarios.map<DropdownMenuItem<String>>((u) {
                                    final data = u.data() as Map<String, dynamic>;
                                    final nombre = data['nombre'] ?? 'Sin nombre';
                                    final uid = data['uid'] ?? u.id;
                                    return DropdownMenuItem<String>(
                                      value: uid,
                                      child: Text(nombre),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _usuarioSeleccionadoUid = val;
                                      final usuario = usuarios.firstWhere(
                                        (u) {
                                          final data = u.data() as Map<String, dynamic>;
                                          return (data['uid'] ?? u.id) == val;
                                        },
                                      );
                                      final userData = usuario.data() as Map<String, dynamic>;
                                      _usuarioSeleccionadoNombre = userData['nombre'] ?? 'Sin nombre';
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => registrarAsistencia("Entrada"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.login, size: 20),
                                          SizedBox(height: 4),
                                          Text("Entrada", style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => registrarAsistencia("AlmuerzoInicio"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.restaurant, size: 20),
                                          SizedBox(height: 4),
                                          Text("Inicio", style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => registrarAsistencia("AlmuerzoFin"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.restaurant_menu, size: 20),
                                          SizedBox(height: 4),
                                          Text("Fin", style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => registrarAsistencia("Salida"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.logout, size: 20),
                                          SizedBox(height: 4),
                                          Text("Salida", style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Registro Manual Completo
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "📝 Registro Manual Completo",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Selector de fecha
                            ListTile(
                              leading: const Icon(Icons.calendar_today, color: Colors.blue),
                              title: Text(
                                DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: const Text('Fecha del registro'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _seleccionarFecha(context),
                              ),
                              tileColor: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Campos de tiempo
                            _buildCampoTiempo(
                              'Hora de Entrada *',
                              _entradaManual,
                              Icons.login,
                              Colors.green,
                              (picked) => setState(() => _entradaManual = picked),
                            ),
                            const SizedBox(height: 12),
                            _buildCampoTiempo(
                              'Hora de Salida',
                              _salidaManual,
                              Icons.logout,
                              Colors.red,
                              (picked) => setState(() => _salidaManual = picked),
                            ),
                            const SizedBox(height: 12),
                            _buildCampoTiempo(
                              'Inicio Almuerzo',
                              _almuerzoInicioManual,
                              Icons.restaurant,
                              Colors.orange,
                              (picked) => setState(() => _almuerzoInicioManual = picked),
                            ),
                            const SizedBox(height: 12),
                            _buildCampoTiempo(
                              'Fin Almuerzo',
                              _almuerzoFinManual,
                              Icons.restaurant_menu,
                              Colors.orange,
                              (picked) => setState(() => _almuerzoFinManual = picked),
                            ),
                            const SizedBox(height: 16),

                            // Campo de notas
                            TextField(
                              controller: _notaCtrl,
                              decoration: InputDecoration(
                                labelText: "Notas (opcional)",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.note),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),

                            // Botón guardar
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: registrarManual,
                                icon: const Icon(Icons.save),
                                label: const Text("Guardar Registro Manual"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(0, 150, 32, 1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

            const SizedBox(width: 16),

            // Panel derecho - Tabla de registros
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.view_list, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text(
                            "Registros de Hoy",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Expanded(
                        child: _buildRegistrosTabla(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Widget que construye la tabla de registros
  Widget _buildRegistrosTabla() {
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getRegistrosStream(hoy),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(0, 150, 32, 1),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final registros = snapshot.data ?? [];

        if (registros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "No hay registros para hoy",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Colors.green.shade50,
            ),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            columns: const [
              DataColumn(label: Text("Usuario")),
              DataColumn(label: Text("Entrada")),
              DataColumn(label: Text("Almuerzo Inicio")),
              DataColumn(label: Text("Almuerzo Fin")),
              DataColumn(label: Text("Salida")),
              DataColumn(label: Text("Horas")),
            ],
            rows: registros.map((r) {
              return DataRow(cells: [
                DataCell(Text(r['nombre'] ?? '-')),
                DataCell(Text(r['entrada'] ?? '--:--')),
                DataCell(Text(r['almuerzoInicio'] ?? '--:--')),
                DataCell(Text(r['almuerzoFin'] ?? '--:--')),
                DataCell(Text(r['salida'] ?? '--:--')),
                DataCell(Text(r['horasTrabajadas'] ?? '--:--:--')),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  // Stream que obtiene los registros de hoy
  Stream<List<Map<String, dynamic>>> _getRegistrosStream(String fechaHoy) {
    return _db
        .collection('usuarios')
        .snapshots()
        .asyncMap((usuariosSnapshot) async {
          final registros = <Map<String, dynamic>>[];
          
          for (var usuarioDoc in usuariosSnapshot.docs) {
            final usuarioData = usuarioDoc.data() as Map<String, dynamic>;
            final empleadoUid = usuarioData['uid'] ?? usuarioDoc.id;
            final nombre = usuarioData['nombre'] ?? 'Sin nombre';
            
            // Obtener registro del día para este usuario
            final registroDoc = await _db
                .collection('asistenciasEmpleados')
                .doc(empleadoUid)
                .collection('registros')
                .doc(fechaHoy)
                .get();
            
            if (registroDoc.exists) {
              final data = registroDoc.data() as Map<String, dynamic>;
              registros.add({
                'nombre': nombre,
                'entrada': data['entrada'],
                'salida': data['salida'],
                'almuerzoInicio': data['almuerzoInicio'],
                'almuerzoFin': data['almuerzoFin'],
                'horasTrabajadas': data['horasTrabajadas'],
              });
            }
          }
          
          return registros;
        });
  }

  // Widget auxiliar para campos de tiempo
  Widget _buildCampoTiempo(
    String label,
    TimeOfDay? valor,
    IconData icono,
    Color color,
    Function(TimeOfDay) onSelected,
  ) {
    return InkWell(
      onTap: () => _seleccionarTiempo(context, label, onSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: Icon(icono, color: color),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          valor != null ? valor.format(context) : '--:--',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}