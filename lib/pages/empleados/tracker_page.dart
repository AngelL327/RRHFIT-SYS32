import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'reporte_asistencia.dart';

class TrackerPage extends StatefulWidget {
  final String empleadoId; // ID del empleado actual

  const TrackerPage({super.key, required this.empleadoId});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  
  Duration _tiempoTrabajado = Duration.zero;
  bool _cronometroActivo = false;
  
  Map<String, dynamic>? _registroHoy;
  bool _isLoading = true;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startClock();
    _cargarRegistroDelDia();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        
        // Actualizar cronómetro si está activo
        if (_cronometroActivo) {
          _calcularTiempoTrabajado();
        }
      });
    });
  }

  String _getFechaDocId() {
    // Formato: YYYY-MM-DD
    return DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
  }

  // Referencia a la subcolección de registros del empleado
  CollectionReference _getRegistrosCollection() {
    return _firestore
        .collection('asistencias')
        .doc(widget.empleadoId)
        .collection('registros');
  }

  Future<void> _cargarRegistroDelDia() async {
    try {
      final fechaId = _getFechaDocId();
      final doc = await _getRegistrosCollection().doc(fechaId).get();
      
      setState(() {
        _registroHoy = doc.exists ? doc.data() as Map<String, dynamic>? : null;
        _isLoading = false;
      });
      
      // Calcular tiempo trabajado y estado del cronómetro
      _calcularTiempoTrabajado();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar registro: $e');
    }
  }

  Future<void> _registrarMarca(String tipo) async {
    // Solo permitir registrar marcas en el día actual
    if (!_esDiaActual()) {
      _mostrarError('Solo puedes registrar marcas en el día actual');
      return;
    }

    try {
      final fechaId = _getFechaDocId();
      final ahora = DateTime.now();
      final horaFormato = DateFormat('HH:mm:ss').format(ahora);
      
      final Map<String, dynamic> datos = {
        'empleadoId': widget.empleadoId,
        'fecha': DateFormat('yyyy-MM-dd').format(ahora),
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      };

      // Agregar el campo específico según el tipo
      switch (tipo) {
        case 'entrada':
          datos['entrada'] = horaFormato;
          datos['entradaTimestamp'] = Timestamp.fromDate(ahora);
          break;
        case 'almuerzo':
          // Si ya existe almuerzoInicio, entonces es almuerzoFin
          if (_registroHoy != null && _registroHoy!['almuerzoInicio'] != null) {
            datos['almuerzoFin'] = horaFormato;
            datos['almuerzoFinTimestamp'] = Timestamp.fromDate(ahora);
          } else {
            datos['almuerzoInicio'] = horaFormato;
            datos['almuerzoInicioTimestamp'] = Timestamp.fromDate(ahora);
          }
          break;
        case 'salida':
          datos['salida'] = horaFormato;
          datos['salidaTimestamp'] = Timestamp.fromDate(ahora);
          break;
      }

      // Usar merge para no sobrescribir datos existentes
      await _getRegistrosCollection().doc(fechaId).set(
        datos,
        SetOptions(merge: true),
      );

      // Si es salida, calcular y guardar horas totales
      if (tipo == 'salida') {
        await _guardarHorasTotales(fechaId);
      }

      // Recargar datos
      await _cargarRegistroDelDia();
      
      _mostrarExito('Marca registrada correctamente');
    } catch (e) {
      _mostrarError('Error al registrar marca: $e');
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _puedeRegistrar(String tipo) {
    // No permitir registrar si no es el día actual
    if (!_esDiaActual()) return false;
    
    if (_registroHoy == null) return tipo == 'entrada';
    
    switch (tipo) {
      case 'entrada':
        // Solo permitir entrada si no existe ya
        return _registroHoy!['entrada'] == null;
      case 'almuerzo':
        return _registroHoy!['entrada'] != null && _registroHoy!['salida'] == null;
      case 'salida':
        return _registroHoy!['entrada'] != null;
      default:
        return false;
    }
  }

  bool _esDiaActual() {
    final hoy = DateTime.now();
    return _fechaSeleccionada.year == hoy.year &&
           _fechaSeleccionada.month == hoy.month &&
           _fechaSeleccionada.day == hoy.day;
  }

  void _cambiarDia(int dias) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: dias));
    });
    _cargarRegistroDelDia();
  }

  bool _puedeAvanzarDia() {
    final hoy = DateTime.now();
    final manana = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, _fechaSeleccionada.day + 1);
    return manana.isBefore(hoy) || manana.day == hoy.day;
  }

  void _calcularTiempoTrabajado() {
    if (_registroHoy == null || _registroHoy!['entradaTimestamp'] == null) {
      setState(() {
        _tiempoTrabajado = Duration.zero;
        _cronometroActivo = false;
      });
      return;
    }

    Duration total = Duration.zero;
    bool activo = false;

    Timestamp entradaTs = _registroHoy!['entradaTimestamp'];
    DateTime entrada = entradaTs.toDate();
    
    // Si hay salida, calcular tiempo total
    if (_registroHoy!['salidaTimestamp'] != null) {
      Timestamp salidaTs = _registroHoy!['salidaTimestamp'];
      DateTime salida = salidaTs.toDate();
      total = salida.difference(entrada);
      
      // Restar tiempo de almuerzo si existe
      if (_registroHoy!['almuerzoInicioTimestamp'] != null && 
          _registroHoy!['almuerzoFinTimestamp'] != null) {
        Timestamp almuerzoInicioTs = _registroHoy!['almuerzoInicioTimestamp'];
        Timestamp almuerzoFinTs = _registroHoy!['almuerzoFinTimestamp'];
        Duration almuerzo = almuerzoFinTs.toDate().difference(almuerzoInicioTs.toDate());
        total -= almuerzo;
      }
      
      // Cronómetro se detiene al marcar salida
      activo = false;
    } else {
      // No hay salida, cronómetro activo
      DateTime ahora = DateTime.now();
      
      // Si está en almuerzo, no contar tiempo
      if (_registroHoy!['almuerzoInicioTimestamp'] != null && 
          _registroHoy!['almuerzoFinTimestamp'] == null) {
        // En almuerzo: calcular solo hasta inicio de almuerzo
        Timestamp almuerzoInicioTs = _registroHoy!['almuerzoInicioTimestamp'];
        total = almuerzoInicioTs.toDate().difference(entrada);
        activo = false; // Pausado durante almuerzo
      } else {
        // Trabajando activamente
        total = ahora.difference(entrada);
        
        // Restar tiempo de almuerzo completado
        if (_registroHoy!['almuerzoInicioTimestamp'] != null && 
            _registroHoy!['almuerzoFinTimestamp'] != null) {
          Timestamp almuerzoInicioTs = _registroHoy!['almuerzoInicioTimestamp'];
          Timestamp almuerzoFinTs = _registroHoy!['almuerzoFinTimestamp'];
          Duration almuerzo = almuerzoFinTs.toDate().difference(almuerzoInicioTs.toDate());
          total -= almuerzo;
        }
        
        activo = true;
      }
    }
    
    // Si el total es negativo, establecer en cero
    if (total.isNegative) {
      total = Duration.zero;
    }

    setState(() {
      _tiempoTrabajado = total;
      _cronometroActivo = activo && _esDiaActual();
    });
  }

  String _formatearDuracion(Duration duracion) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final horas = twoDigits(duracion.inHours);
    final minutos = twoDigits(duracion.inMinutes.remainder(60));
    final segundos = twoDigits(duracion.inSeconds.remainder(60));
    return "$horas:$minutos:$segundos";
  }

  Future<void> _guardarHorasTotales(String fechaId) async {
    try {
      // Esperar un momento para que Firebase actualice los datos
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Recargar datos para asegurar que tenemos la información completa
      final doc = await _getRegistrosCollection().doc(fechaId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      if (data['entradaTimestamp'] == null || data['salidaTimestamp'] == null) {
        return;
      }

      Timestamp entradaTs = data['entradaTimestamp'];
      Timestamp salidaTs = data['salidaTimestamp'];
      
      DateTime entrada = entradaTs.toDate();
      DateTime salida = salidaTs.toDate();
      
      Duration total = salida.difference(entrada);
      
      // Restar tiempo de almuerzo si existe
      if (data['almuerzoInicioTimestamp'] != null && 
          data['almuerzoFinTimestamp'] != null) {
        Timestamp almuerzoInicioTs = data['almuerzoInicioTimestamp'];
        Timestamp almuerzoFinTs = data['almuerzoFinTimestamp'];
        Duration almuerzo = almuerzoFinTs.toDate().difference(almuerzoInicioTs.toDate());
        total -= almuerzo;
      }
      
      // Asegurar que no sea negativo
      if (total.isNegative) {
        total = Duration.zero;
      }
      
      // Convertir a horas decimales (ej: 8.5 horas, 7.75 horas)
      double horasDecimales = total.inMinutes / 60.0;
      
      // Guardar en Firebase
      await _getRegistrosCollection().doc(fechaId).update({
        'horasTrabajadas': _formatearDuracion(total), // Formato HH:MM:SS
        'horasDecimales': double.parse(horasDecimales.toStringAsFixed(2)), // Para cálculos
        'totalMinutos': total.inMinutes, // Minutos totales
      });
      
      print('Horas guardadas: ${_formatearDuracion(total)} (${horasDecimales.toStringAsFixed(2)}h)');
      
    } catch (e) {
      print('Error al calcular horas totales: $e');
    }
  }

  String _getBotonAlmuerzoTexto() {
    if (_registroHoy != null && _registroHoy!['almuerzoInicio'] != null && _registroHoy!['almuerzoFin'] == null) {
      return 'Fin Almuerzo';
    }
    return 'Almuerzo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_esDiaActual())
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(
                                'Historial',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Control de Asistencia',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(_fechaSeleccionada),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Reloj
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('HH:mm:ss').format(_currentTime),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Cronómetro principal (grande)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatearDuracion(_tiempoTrabajado),
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: _cronometroActivo 
                                        ? const Color(0xFF2E7D32) 
                                        : Colors.grey[700],
                                    letterSpacing: 4,
                                    height: 1.0,
                                  ),
                                ),
                                if (_cronometroActivo)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.6),
                                            blurRadius: 10,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _cronometroActivo 
                                  ? 'Trabajando...' 
                                  : _registroHoy != null && _registroHoy!['entrada'] != null
                                      ? (_registroHoy!['almuerzoInicioTimestamp'] != null && _registroHoy!['almuerzoFinTimestamp'] == null
                                          ? 'En almuerzo'
                                          : 'Detenido')
                                      : 'Sin iniciar',
                              style: TextStyle(
                                fontSize: 14,
                                color: _cronometroActivo ? Colors.green[700] : Colors.grey[500],
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Botones de marcado
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildBotonMarca(
                              'Entrada',
                              Icons.login,
                              Colors.blue,
                              () => _registrarMarca('entrada'),
                              _puedeRegistrar('entrada'),
                            ),
                            _buildBotonMarca(
                              _getBotonAlmuerzoTexto(),
                              Icons.restaurant,
                              Colors.orange,
                              () => _registrarMarca('almuerzo'),
                              _puedeRegistrar('almuerzo'),
                            ),
                            _buildBotonMarca(
                              'Salida',
                              Icons.logout,
                              Colors.red,
                              () => _registrarMarca('salida'),
                              _puedeRegistrar('salida'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Historial del día
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              _esDiaActual() ? 'Historial de Hoy' : 'Historial',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        if (_registroHoy == null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _esDiaActual() ? 'No hay registros para hoy' : 'No hay registros para este día',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          )
                          
                        else
                          Column(
                            children: [
                              // Lista de registros
                              if (_registroHoy!['entrada'] != null)
                                _buildRegistroItem(
                                  'Entrada',
                                  _registroHoy!['entrada'],
                                  Icons.login,
                                  Colors.blue,
                                ),
                              if (_registroHoy!['almuerzoInicio'] != null)
                                _buildRegistroItem(
                                  'Inicio Almuerzo',
                                  _registroHoy!['almuerzoInicio'],
                                  Icons.restaurant,
                                  Colors.orange,
                                ),
                              if (_registroHoy!['almuerzoFin'] != null)
                                _buildRegistroItem(
                                  'Fin Almuerzo',
                                  _registroHoy!['almuerzoFin'],
                                  Icons.restaurant_menu,
                                  Colors.orange,
                                ),
                              if (_registroHoy!['salida'] != null)
                                _buildRegistroItem(
                                  'Salida',
                                  _registroHoy!['salida'],
                                  Icons.logout,
                                  Colors.red,
                                ),
                            ],
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Navegación entre días
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Flecha izquierda - día anterior
                            IconButton(
                              onPressed: () => _cambiarDia(-1),
                              icon: const Icon(Icons.chevron_left),
                              iconSize: 32,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                              ),
                              tooltip: 'Día anterior',
                            ),
                            
                            // Botón "Hoy"
                            if (!_esDiaActual())
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fechaSeleccionada = DateTime.now();
                                  });
                                  _cargarRegistroDelDia();
                                },
                                icon: const Icon(Icons.today, size: 18),
                                label: const Text('Ir a Hoy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            
                            // Flecha derecha - día siguiente
                            IconButton(
                              onPressed: _puedeAvanzarDia() ? () => _cambiarDia(1) : null,
                              icon: const Icon(Icons.chevron_right),
                              iconSize: 32,
                              style: IconButton.styleFrom(
                                backgroundColor: _puedeAvanzarDia() 
                                    ? const Color(0xFF2E7D32) 
                                    : Colors.grey[300],
                                foregroundColor: _puedeAvanzarDia() 
                                    ? Colors.white 
                                    : Colors.grey[500],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                              ),
                              tooltip: 'Día siguiente',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Botón de generar reporte - CORREGIDO
                        Center(
                          child: BotonGenerarReporte(
                            empleadoUid: widget.empleadoId, // Pasar el empleadoId aquí
                            fecha: _fechaSeleccionada, // Pasar la fecha seleccionada
                            usuarioUid: FirebaseAuth.instance.currentUser?.uid,
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

  Widget _buildBotonMarca(String texto, IconData icono, Color color, VoidCallback onPressed, bool enabled) {
    return SizedBox(
      width: 140,
      height: 140,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 4 : 0,
          padding: const EdgeInsets.all(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistroItem(String tipo, String hora, IconData icono, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  hora,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green[400]),
        ],
      ),
    );
  }
}

// Widget del botón que ahora incluye empleadoUid
class BotonGenerarReporte extends StatelessWidget {
  final String empleadoUid;
  final DateTime fecha;
  final String? usuarioUid;

  const BotonGenerarReporte({
    super.key,
    required this.empleadoUid,
    required this.fecha,
    this.usuarioUid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                final size = MediaQuery.of(context).size;
                return AlertDialog(
                  titlePadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  title: Row(
                    children: [
                      const Expanded(child: Text('Imprimir Reporte de Asistencias')),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.redAccent,
                        splashRadius: 18,
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  contentPadding: EdgeInsets.zero,
                  content: SizedBox(
                    width: size.width * 0.9,
                    height: size.height * 0.8,
                    child: GenerateAsistenciaPDFScreen(
                      title: 'Reporte de Asistencias',
                      empleadoId: empleadoUid,
                      fecha: fecha, // Pasar la fecha aquí también
                      uid: usuarioUid
                    ),
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.picture_as_pdf, size: 24),
          label: const Text(
            'Generar Reporte PDF',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}