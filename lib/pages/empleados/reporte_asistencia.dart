import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/core/theme.dart';

// Modelo para los eventos de asistencia del día
class EventoAsistencia {
  final String evento;
  final String hora;

  EventoAsistencia({
    required this.evento,
    required this.hora,
  });
}

// Modelo para datos del usuario
class DatosUsuario {
  final String nombre;
  final String apellido;
  final String departamento;

  DatosUsuario({
    required this.nombre,
    required this.apellido,
    required this.departamento,
  });

  String get nombreCompleto => '$nombre $apellido';
}

class GenerateAsistenciaPDFScreen extends StatelessWidget {
  const GenerateAsistenciaPDFScreen({
    super.key,
    required this.title,
    required this.empleadoId,
    required this.fecha,
    this.uid,
  });

  final String title;
  final String empleadoId;
  final DateTime fecha;
  final String? uid;

  Future<DatosUsuario> getDatosUsuario(String? uid) async {
    try {
      print('Buscando datos de usuario para UID: $uid');
      
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (usuarioDoc.exists) {
        final data = usuarioDoc.data();
        if (data != null) {
          final nombre = data['nombre'] ?? 'Sin nombre';
          final apellido = data['apellido'] ?? '';
          final departamento = data['Departamento'] ?? 'Sin departamento';
          
          print(' Usuario encontrado: $nombre $apellido - Depto: $departamento');
          
          return DatosUsuario(
            nombre: nombre,
            apellido: apellido,
            departamento: departamento,
          );
        }
      }
      
      print(' No se encontró usuario, usando valores por defecto');
      return DatosUsuario(
        nombre: 'Usuario',
        apellido: 'Desconocido',
        departamento: 'Sin departamento',
      );
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return DatosUsuario(
        nombre: 'Error',
        apellido: '',
        departamento: 'N/A',
      );
    }
  }

  Future<List<EventoAsistencia>> getEventosDelDia(String empleadoId, DateTime fecha) async {
    List<EventoAsistencia> eventos = [];
    
    try {
      final fechaId = DateFormat('yyyy-MM-dd').format(fecha);
      print('Buscando registro para fecha: $fechaId');
      
      final registroDoc = await FirebaseFirestore.instance
          .collection('asistencias')
          .doc(empleadoId)
          .collection('registros')
          .doc(fechaId)
          .get();

      if (!registroDoc.exists) {
        print(' No existe registro para esta fecha');
        return eventos;
      }

      final data = registroDoc.data()!;
      print('Datos del registro: $data');

      // Agregar eventos en orden
      if (data['entrada'] != null && data['entrada'].toString().isNotEmpty) {
        eventos.add(EventoAsistencia(
          evento: 'Entrada',
          hora: _formatearHora(data['entrada']),
        ));
      }

      if (data['almuerzoInicio'] != null && data['almuerzoInicio'].toString().isNotEmpty) {
        eventos.add(EventoAsistencia(
          evento: 'Inicio almuerzo',
          hora: _formatearHora(data['almuerzoInicio']),
        ));
      }

      if (data['almuerzoFin'] != null && data['almuerzoFin'].toString().isNotEmpty) {
        eventos.add(EventoAsistencia(
          evento: 'Fin Almuerzo',
          hora: _formatearHora(data['almuerzoFin']),
        ));
      }

      if (data['salida'] != null && data['salida'].toString().isNotEmpty) {
        eventos.add(EventoAsistencia(
          evento: 'Salida',
          hora: _formatearHora(data['salida']),
        ));
      }
      
      print(' Total de eventos: ${eventos.length}');
    } catch (e) {
      print('Error al obtener eventos: $e');
    }

    return eventos;
  }

  String _formatearHora(String hora) {
    try {
      // Si la hora ya está en formato HH:mm:ss, convertir a formato de 12 horas
      final parts = hora.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        String period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      print('Error al formatear hora: $e');
    }
    return hora;
  }

  Future<Uint8List> _buildPdf(pdf_lib.PdfPageFormat format) async {
    final doc = pw.Document();
    
    print(' Construyendo PDF para fecha: ${DateFormat('dd-MM-yyyy').format(fecha)}');
    
    // Obtener eventos del día Y datos del usuario
    final resultados = await Future.wait([
      getEventosDelDia(empleadoId, fecha),
      getDatosUsuario(uid),
    ]);
    
    List<EventoAsistencia> eventos = resultados[0] as List<EventoAsistencia>;
    DatosUsuario datosUsuario = resultados[1] as DatosUsuario;
    
    print('Eventos para incluir en PDF: ${eventos.length}');
    print('Usuario: ${datosUsuario.nombreCompleto}');
    print(' Departamento: ${datosUsuario.departamento}');

    final dateFmt = DateFormat('dd-MM-yyyy');
    final fechaGenerado = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Cargar logo y marca de agua desde assets
    Uint8List? logoBytes;
    pw.ImageProvider? logoImage;
    Uint8List? watermarkBytes;
    
    try {
      logoBytes = (await rootBundle.load('assets/images/fittlay.png'))
          .buffer
          .asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
      watermarkBytes = logoBytes; // Usar el mismo para marca de agua
    } catch (e) {
      try {
        logoBytes = (await rootBundle.load('images/fittlay.png'))
            .buffer
            .asUint8List();
        logoImage = pw.MemoryImage(logoBytes);
        watermarkBytes = logoBytes;
      } catch (e2) {
        print(' No se pudo cargar el logo: $e2');
        logoImage = null;
        watermarkBytes = null;
      }
    }

    pw.Font? ttf;
    pw.Font? ttfBold;
    try {
      final fontData = await rootBundle.load('/fonts/Roboto-Regular.ttf');
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
      
      try {
        final fontBoldData = await rootBundle.load('/fonts/Roboto-Bold.ttf');
        ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
      } catch (e) {
        ttfBold = ttf;
      }
    } catch (e) {
      print(' No se pudo cargar la fuente: $e');
      ttf = null;
      ttfBold = null;
    }

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        build: (context) {
          final contenido = <pw.Widget>[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      "Departamento de RRHH",
                      //datosUsuario.departamento,
                      style: ttf != null
                          ? pw.TextStyle(font: ttf, fontSize: 10, color: pdf_lib.PdfColors.grey900)
                          : pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey900),
                    ),
                  ),
                ),
                // Logo (centro)
                pw.Expanded(
                  flex: 4,
                  child: pw.Center(
                    child: logoImage != null
                        ? pw.Image(logoImage, width: 70, height: 70)
                        : pw.Text(
                            'Fittlay',
                            style: ttfBold != null
                                ? pw.TextStyle(font: ttfBold, fontSize: 18, fontWeight: pw.FontWeight.bold)
                                : pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                          ),
                  ),
                ),
                // Fecha (derecha)
                pw.Expanded(
                  flex: 3,
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Fecha: $fechaGenerado',
                      style: ttf != null
                          ? pw.TextStyle(font: ttf, fontSize: 10, color: pdf_lib.PdfColors.grey900)
                          : pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey900),
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 8),
            
            // Título
            pw.Center(
              child: pw.Text(
                'Fittlay',
                style: ttfBold != null
                    ? pw.TextStyle(font: ttfBold, fontSize: 16, fontWeight: pw.FontWeight.bold)
                    : pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Reporte Historial de Asistencia Diario',
                style: ttfBold != null
                    ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                    : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(dateFmt.format(fecha),
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 12)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 12),),
            ),
            
            pw.SizedBox(height: 12),
            
            pw.Center(
              child: pw.Text(
                'Datos del Empleado',
                style: ttfBold != null
                    ? pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold)
                    : pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ),
            // Información adicional
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empleado:',
                        style: ttfBold != null
                            ? pw.TextStyle(font: ttfBold, fontWeight: pw.FontWeight.bold, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Departamento:',
                        style: ttfBold != null
                            ? pw.TextStyle(font: ttfBold, fontWeight: pw.FontWeight.bold, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      
                    ],
                  ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        datosUsuario.nombreCompleto,
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        datosUsuario.departamento,
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      
                    ],
                  ),
                  pw.SizedBox(width: 150),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Correo:",
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        "Teléfono:",
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      
                    ],
                  ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "jdn2021@gmail.com",//Por mientras
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        "97643734",//pondre los de firebase despues
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.normal, fontSize: 11)
                            : pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            if (eventos.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: pw.EdgeInsets.all(40),
                  child: pw.Column(
                    children: [
                      pw.Icon(
                        pw.IconData(0xe88f),
                        size: 48,
                        color: pdf_lib.PdfColors.grey400,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'No hay registros de asistencia para este día',
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontSize: 12, color: pdf_lib.PdfColors.grey600)
                            : pw.TextStyle(fontSize: 12, color: pdf_lib.PdfColors.grey600),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: AppTheme.pdfTableHeaderBG, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    // Header de la tabla
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: pw.BoxDecoration(
                        color: AppTheme.pdfTableHeaderBG,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(6),
                          topRight: pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              textAlign: pw.TextAlign.center,
                              'Evento',
                              style: ttfBold != null
                                  ? pw.TextStyle(
                                      font: ttfBold,
                                      fontSize: 11,
                                      color: pdf_lib.PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    )
                                  : pw.TextStyle(
                                      fontSize: 11,
                                      color: pdf_lib.PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              textAlign: pw.TextAlign.center,
                              'Hora',
                              style: ttfBold != null
                                  ? pw.TextStyle(
                                      font: ttfBold,
                                      fontSize: 11,
                                      color: pdf_lib.PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    )
                                  : pw.TextStyle(
                                      fontSize: 11,
                                      color: pdf_lib.PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Filas de la tabla
                    ...eventos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final evento = entry.value;
                      final isEven = index % 2 == 0;
                      
                      return pw.Container(
                        padding: pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: pw.BoxDecoration(
                          color: isEven ? pdf_lib.PdfColors.white : pdf_lib.PdfColors.grey100,
                          border: pw.Border(
                            bottom: index < eventos.length - 1
                                ? pw.BorderSide(color: pdf_lib.PdfColors.grey300, width: 0.5)
                                : pw.BorderSide.none,
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                              textAlign: pw.TextAlign.center, 
                                evento.evento,
                                style: ttf != null
                                    ? pw.TextStyle(font: ttf, fontSize: 10)
                                    : pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                              textAlign: pw.TextAlign.center,
                                evento.hora,
                                style: ttf != null
                                    ? pw.TextStyle(font: ttf, fontSize: 10)
                                    : pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            
            pw.Spacer(),
            
            // Footer
            pw.SizedBox(height: 6),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Generado por ${datosUsuario.nombreCompleto}',
                style: ttf != null
                    ? pw.TextStyle(font: ttf, fontSize: 9)
                    : pw.TextStyle(fontSize: 9),
              ),
            ),
          ];

          // Si hay marca de agua, aplicarla
          if (watermarkBytes != null) {
            return pw.Stack(
              children: [
                // Marca de agua centrada
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.4,
                    child: pw.SizedBox(
                      width: 400,
                      height: 500,
                      child: pw.Image(
                        pw.MemoryImage(watermarkBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Contenido principal encima
                pw.Column(children: contenido),
              ],
            );
          }

          // Sin marca de agua
          return pw.Column(children: contenido);
        },
      ),
    );

    print(' PDF construido exitosamente');
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        getEventosDelDia(empleadoId, fecha),
        getDatosUsuario(empleadoId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final eventos = snapshot.data![0] as List<EventoAsistencia>;
        
        print('Renderizando vista previa con ${eventos.length} eventos');
        if (eventos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros de asistencia para este día',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMMM yyyy', 'es').format(fecha),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
 return Theme(
        data: ThemeData(
          primaryColor: AppTheme.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primary,
            primary: AppTheme.primary,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        child: PdfPreview(
          canChangeOrientation: false,
          canDebug: false,
          maxPageWidth: 700,
          previewPageMargin: const EdgeInsets.all(20),
          build: (format) => _buildPdf(format),
        ),
        );
      },
    );
  }
}