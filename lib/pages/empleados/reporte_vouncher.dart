import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

Uint8List? logoBytes;
pw.ImageProvider? logoImage;
Uint8List? watermarkBytes;

// Modelo para datos del usuario
class DatosUsuario {
  final String nombre;
  final String apellido;
  final String departamento;
  final String puesto;
  final double salarioBase;

  DatosUsuario({
    required this.nombre,
    required this.apellido,
    required this.departamento,
    required this.puesto,
    required this.salarioBase,
  });

  String get nombreCompleto => '$nombre $apellido';
}

// Modelo para registro de asistencia con cálculos de nómina
class RegistroNomina {
  final String fecha;
  final double horasTrabajadas;
  final double horasNormales;
  final double horasExtra;
  final double pagoNormal;
  final double pagoExtra;

  RegistroNomina({
    required this.fecha,
    required this.horasTrabajadas,
    required this.horasNormales,
    required this.horasExtra,
    required this.pagoNormal,
    required this.pagoExtra,
  });

  double get pagoTotal => pagoNormal + pagoExtra;
}

class GenerateNominaPDFScreen extends StatelessWidget {
  const GenerateNominaPDFScreen({
    super.key,
    required this.title,
    required this.empleadoId,
    required this.fechaInicio,
    required this.fechaFin,
    this.uid,
  });

  final String title;
  final String empleadoId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
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
          final puesto = data['puesto'] ?? 'Sin puesto';
          final salarioBase = (data['salarioBase'] ?? 0.0).toDouble();
          
          print('Usuario encontrado: $nombre $apellido - Depto: $departamento - Puesto: $puesto - Salario: $salarioBase');
          
          return DatosUsuario(
            nombre: nombre,
            apellido: apellido,
            departamento: departamento,
            puesto: puesto,
            salarioBase: salarioBase,
          );
        }
      }
      
      print(' No se encontró usuario, usando valores por defecto');
      return DatosUsuario(
        nombre: 'Usuario',
        apellido: 'Desconocido',
        departamento: 'Sin departamento',
        puesto: 'Sin puesto',
        salarioBase: 0.0,
      );
    } catch (e) {
      print(' Error al obtener datos del usuario: $e');
      return DatosUsuario(
        nombre: 'Error',
        apellido: '',
        departamento: 'N/A',
        puesto: 'N/A',
        salarioBase: 0.0,
      );
    }
  }

  Future<List<RegistroNomina>> getRegistrosPeriodo(String empleadoId, DateTime fechaInicio, DateTime fechaFin, double salarioHora) async {
    List<RegistroNomina> registros = [];
    
    try {
      // Generar lista de fechas en el período
      final dias = <DateTime>[];
      DateTime currentDate = fechaInicio;
      while (currentDate.isBefore(fechaFin) || currentDate.isAtSameMomentAs(fechaFin)) {
        dias.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      print(' Buscando registros para ${dias.length} días');

      // Obtener registros para cada día
      for (final dia in dias) {
        final fechaId = DateFormat('yyyy-MM-dd').format(dia);
        
        final registroDoc = await FirebaseFirestore.instance
            .collection('asistencias')
            .doc(empleadoId)
            .collection('registros')
            .doc(fechaId)
            .get();

        if (registroDoc.exists) {
          final data = registroDoc.data()!;
          final horasDecimales = (data['horasDecimales'] ?? 0.0).toDouble();
          
          // Calcular horas normales y extra
          double horasNormales = horasDecimales;
          double horasExtra = 0.0;
          
          if (horasDecimales > 8.0) {
            horasNormales = 8.0;
            horasExtra = horasDecimales - 8.0;
          }
          
          // Calcular pagos (asumiendo tiempo extra a 1.5x)
          final pagoNormal = horasNormales * salarioHora;
          final pagoExtra = horasExtra * salarioHora * 1.5;
          
          registros.add(RegistroNomina(
            fecha: fechaId,
            horasTrabajadas: horasDecimales,
            horasNormales: horasNormales,
            horasExtra: horasExtra,
            pagoNormal: pagoNormal,
            pagoExtra: pagoExtra,
          ));
          
          print('Registro $fechaId: $horasDecimales horas (Normales: $horasNormales, Extra: $horasExtra)');
        }
      }
      
      print(' Total de registros encontrados: ${registros.length}');
    } catch (e) {
      print('Error al obtener registros: $e');
    }

    return registros;
  }

  Future<Uint8List> _buildPdf(pdf_lib.PdfPageFormat format) async {
    final doc = pw.Document();
    
    print(' Construyendo PDF de nómina para período: ${DateFormat('dd/MM/yyyy').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(fechaFin)}');
    
    // Obtener datos del usuario
    final datosUsuario = await getDatosUsuario(uid);
    
    // Calcular salario por hora (asumiendo 8 horas diarias, 22 días al mes)
    final salarioHora = datosUsuario.salarioBase > 0 
        ? datosUsuario.salarioBase / (8 * 22) 
        : 0.0;
    
    // Obtener registros del período
    final registros = await getRegistrosPeriodo(empleadoId, fechaInicio, fechaFin, salarioHora);
    
    // Calcular totales
    final totalHorasNormales = registros.fold(0.0, (sum, registro) => sum + registro.horasNormales);
    final totalHorasExtra = registros.fold(0.0, (sum, registro) => sum + registro.horasExtra);
    final totalPagoNormal = registros.fold(0.0, (sum, registro) => sum + registro.pagoNormal);
    final totalPagoExtra = registros.fold(0.0, (sum, registro) => sum + registro.pagoExtra);
    final totalPago = totalPagoNormal + totalPagoExtra;

    print('Totales - Horas Normales: $totalHorasNormales, Horas Extra: $totalHorasExtra');
    print('Pagos - Normal: L${totalPagoNormal.toStringAsFixed(2)}, Extra: L${totalPagoExtra.toStringAsFixed(2)}, Total: L${totalPago.toStringAsFixed(2)}');

    final fechaGenerado = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Cargar logo y fuentes
    Uint8List? logoBytes;
    pw.ImageProvider? logoImage;
    
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
        watermarkBytes = logoBytes; // Usar el mismo para marca de agua
      } catch (e2) {
        print('No se pudo cargar el logo: $e2');
        logoImage = null;
        watermarkBytes = null;
      }
    }

    // Cargar fuente TTF
    pw.Font? ttf;
    pw.Font? ttfBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
      
      try {
        final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
        ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
      } catch (e) {
        ttfBold = ttf;
      }
    } catch (e) {
      print('No se pudo cargar la fuente: $e');
      ttf = null;
      ttfBold = null;
    }

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        build: (context) {
          return pw.Stack(
            children: [
              // === MARCA DE AGUA (FONDO) ===
              if (watermarkBytes != null)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.4, // Ajusta la transparencia (0.0 - 1.0)
                      child: pw.Transform.rotate(
                        angle: 0, // Rotación diagonal (en radianes)
                        child: pw.Image(
                          pw.MemoryImage(watermarkBytes!),
                          width: 400, // Ajusta el tamaño según necesites
                          height: 500,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // === CONTENIDO PRINCIPAL ===
              pw.Column(
                children: [
                  // === HEADER ===
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            "Departamento de RRHH",
                            style: ttf != null
                                ? pw.TextStyle(font: ttf, fontSize: 10, color: pdf_lib.PdfColors.grey900)
                                : pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey900),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 4,
                        child: pw.Center(
                          child: logoImage != null
                              ? pw.Image(logoImage!, width: 70, height: 70)
                              : pw.Text(
                                  'Fittlay',
                                  style: ttfBold != null
                                      ? pw.TextStyle(font: ttfBold, fontSize: 18, fontWeight: pw.FontWeight.bold)
                                      : pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                                ),
                        ),
                      ),
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
                  
                  // === TÍTULO ===
                  pw.Center(
                    child: pw.Text(
                      'Fittlay',
                      style: ttfBold != null
                          ? pw.TextStyle(font: ttfBold, fontSize: 18, fontWeight: pw.FontWeight.bold)
                          : pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      'BOLETA DE PAGO DE LA PRIMERA QUINCENA DE NOVIEMBRE${DateFormat(' yyyy').format(fechaInicio)}',
                      style: ttfBold != null
                          ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                          : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  
                  pw.SizedBox(height: 20),
                  
                  // === INFORMACIÓN DEL EMPLEADO ===
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Text(
                                        'Nombre:',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(width: 50),
                                      pw.Text(
                                        datosUsuario.nombreCompleto,
                                        style: ttf != null
                                            ? pw.TextStyle(font: ttf, fontSize: 12)
                                            : pw.TextStyle(fontSize: 12),
                                      ),
                                      pw.SizedBox(width: 140),
                                      pw.Text(
                                        'Departamento:',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(width: 30),
                                      pw.Text(
                                        datosUsuario.departamento,
                                        style: ttf != null
                                            ? pw.TextStyle(font: ttf, fontSize: 12)
                                            : pw.TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 10),
                                  pw.Row(children: [
                                  pw.Text(
                                        'Fecha Pago:',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(width: 30),
                                      pw.Text(
                                        DateFormat('dd-MMM-yyyy').format(DateTime.now()),
                                        style: ttf != null
                                            ? pw.TextStyle(font: ttf, fontSize: 12)
                                            : pw.TextStyle(fontSize: 12),
                                      ),
                                pw.SizedBox(width: 150),
                                      pw.Text(
                                        'Puesto:',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(width: 30),
                                      pw.Text(
                                        datosUsuario.puesto,
                                        style: ttf != null
                                            ? pw.TextStyle(font: ttf, fontSize: 12)
                                            : pw.TextStyle(fontSize: 12),
                                      ),
                                ]),pw.SizedBox(height: 10),
                                  pw.Row(children: [
                                  pw.Text(
                                        'DNI:',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(width: 70),
                                      pw.Text(
                                        '0501200400501',
                                        style: ttf != null
                                            ? pw.TextStyle(font: ttf, fontSize: 12)
                                            : pw.TextStyle(fontSize: 12),
                                      ),
                                pw.SizedBox(width: 135),
                                      pw.Text(
                                        'Periodo:',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(width: 30),
                                      pw.Text(
                                        '${DateFormat('dd/MM/yyyy').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                                        style: ttf != null
                                            ? pw.TextStyle(font: ttf, fontSize: 12)
                                            : pw.TextStyle(fontSize: 12),
                                      ),
                                ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // === TABLA DE INGRESOS Y EGRESOS ===
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // COLUMNA INGRESOS
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: pdf_lib.PdfColors.grey400),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            children: [
                              // Header Ingresos
                              pw.Container(
                                width: double.infinity,
                                padding: pw.EdgeInsets.all(12),
                                decoration: pw.BoxDecoration(
                                  color: pdf_lib.PdfColors.grey400,
                                  borderRadius: pw.BorderRadius.only(
                                    topLeft: pw.Radius.circular(4),
                                    topRight: pw.Radius.circular(4),
                                  ),
                                ),
                                child: pw.Text(
                                  'INGRESOS',
                                  style: ttfBold != null
                                      ? pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                          color: pdf_lib.PdfColors.black,
                                          fontWeight: pw.FontWeight.bold,
                                        )
                                      : pw.TextStyle(
                                          fontSize: 12,
                                          color: pdf_lib.PdfColors.white,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              
                              // Contenido Ingresos
                              pw.Padding(
                                padding: pw.EdgeInsets.all(12),
                                child: pw.Column(
                                  children: [
                                    _buildConceptoRow('Sueldo Base', totalPagoNormal, ttf, ttfBold),
                                    _buildConceptoRow('Horas Extra', totalPagoExtra, ttf, ttfBold),
                                    pw.Divider(color: pdf_lib.PdfColors.grey400),
                                    _buildConceptoRow('TOTAL INGRESOS', totalPago, ttf, ttfBold, isTotal: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      pw.SizedBox(width: 16),
                      
                      // COLUMNA EGRESOS
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: pdf_lib.PdfColors.grey400),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            children: [
                              // Header Egresos
                              pw.Container(
                                width: double.infinity,
                                padding: pw.EdgeInsets.all(12),
                                decoration: pw.BoxDecoration(
                                  color: pdf_lib.PdfColors.grey400,
                                  borderRadius: pw.BorderRadius.only(
                                    topLeft: pw.Radius.circular(4),
                                    topRight: pw.Radius.circular(4),
                                  ),
                                ),
                                child: pw.Text(
                                  'EGRESOS',
                                  style: ttfBold != null
                                      ? pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                          color: pdf_lib.PdfColors.black,
                                          fontWeight: pw.FontWeight.bold,
                                        )
                                      : pw.TextStyle(
                                          fontSize: 12,
                                          color: pdf_lib.PdfColors.white,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              
                              // Contenido Egresos
                              pw.Padding(
                                padding: pw.EdgeInsets.all(12),
                                child: pw.Column(
                                  children: [
                                    _buildConceptoRow('IHSS', 250.0, ttf, ttfBold),
                                    _buildConceptoRow('RAP', 50.0, ttf, ttfBold),
                                    _buildConceptoRow('ISR', 0.0, ttf, ttfBold),
                                    pw.Divider(color: pdf_lib.PdfColors.grey400),
                                    _buildConceptoRow('TOTAL EGRESOS', 300.0, ttf, ttfBold, isTotal: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // === LIQUIDO A RECIBIR ===
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'LIQUIDO RECIBIDO:',
                          style: ttfBold != null
                              ? pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                )
                              : pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                        ),
                        pw.Text(
                          'L ${(totalPago - 300.0).toStringAsFixed(2)}',
                          style: ttfBold != null
                              ? pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                )
                              : pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                        ),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // === DETALLE DE HORAS TRABAJADAS === (NO BORRAR QUE LO VOY A USAR DESPUES)
                /*   if (registros.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Detalle de Horas Trabajadas',
                          style: ttfBold != null
                              ? pw.TextStyle(font: ttfBold, fontSize: 12, fontWeight: pw.FontWeight.bold)
                              : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: pdf_lib.PdfColors.grey400),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            children: [
                              // Header de la tabla
                              pw.Container(
                                padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: pw.BoxDecoration(
                                  color: pdf_lib.PdfColors.grey200,
                                  border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey400)),
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Expanded(
                                      flex: 2,
                                      child: pw.Text(
                                        'Fecha',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 10, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        'Horas',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 10, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        'Normal',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 10, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        'Extra',
                                        style: ttfBold != null
                                            ? pw.TextStyle(font: ttfBold, fontSize: 10, fontWeight: pw.FontWeight.bold)
                                            : pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Filas de detalle
                              ...registros.take(10).map((registro) => 
                                pw.Container(
                                  padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey300)),
                                  ),
                                  child: pw.Row(
                                    children: [
                                      pw.Expanded(
                                        flex: 2,
                                        child: pw.Text(
                                          DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(registro.fecha)),
                                          style: ttf != null
                                              ? pw.TextStyle(font: ttf, fontSize: 9)
                                              : pw.TextStyle(fontSize: 9),
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          registro.horasTrabajadas.toStringAsFixed(2),
                                          style: ttf != null
                                              ? pw.TextStyle(font: ttf, fontSize: 9)
                                              : pw.TextStyle(fontSize: 9),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          registro.horasNormales.toStringAsFixed(2),
                                          style: ttf != null
                                              ? pw.TextStyle(font: ttf, fontSize: 9)
                                              : pw.TextStyle(fontSize: 9),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          registro.horasExtra > 0 ? registro.horasExtra.toStringAsFixed(2) : '-',
                                          style: ttf != null
                                              ? pw.TextStyle(
                                                  font: ttf, 
                                                  fontSize: 9,
                                                  color: registro.horasExtra > 0 ? pdf_lib.PdfColors.orange : pdf_lib.PdfColors.grey
                                                )
                                              : pw.TextStyle(
                                                  fontSize: 9,
                                                  color: registro.horasExtra > 0 ? pdf_lib.PdfColors.orange : pdf_lib.PdfColors.grey
                                                ),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).toList(),
                              
                              // Total
                              if (registros.length > 10)
                                pw.Container(
                                  padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  child: pw.Text(
                                    '... y ${registros.length - 10} días más',
                                    style: ttf != null
                                        ? pw.TextStyle(font: ttf, fontSize: 9, fontStyle: pw.FontStyle.italic)
                                        : pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                   */
                  pw.Spacer(),
                  
                  // === FOOTER ===
                  pw.Divider(thickness: 1, color: pdf_lib.PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generado por: Sistema Fittlay',
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontSize: 9)
                            : pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Página 1 de 1',
                        style: ttf != null
                            ? pw.TextStyle(font: ttf, fontSize: 9)
                            : pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    print(' PDF de nómina construido exitosamente');
    return doc.save(); 
  }

  // Métodos auxiliares para construir filas
  pw.Widget _buildInfoRow(String label, String value, pw.Font? ttf, pw.Font? ttfBold) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: ttfBold != null
              ? pw.TextStyle(font: ttfBold, fontSize: 10, fontWeight: pw.FontWeight.bold)
              : pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: ttf != null
              ? pw.TextStyle(font: ttf, fontSize: 10)
              : pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildConceptoRow(String concepto, double monto, pw.Font? ttf, pw.Font? ttfBold, {bool isTotal = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            concepto,
            style: isTotal
                ? (ttfBold != null
                    ? pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold)
                    : pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))
                : (ttf != null
                    ? pw.TextStyle(font: ttf, fontSize: 11)
                    : pw.TextStyle(fontSize: 11)),
          ),
          pw.Text(
            'L ${monto.toStringAsFixed(2)}',
            style: isTotal
                ? (ttfBold != null
                    ? pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold)
                    : pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))
                : (ttf != null
                    ? pw.TextStyle(font: ttf, fontSize: 11)
                    : pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Regresar',
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
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
                      'Error al cargar datos de nómina',
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

          final data = snapshot.data!;
          final registros = data['registros'] as List<RegistroNomina>;
          
          if (registros.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay registros de asistencia para este período',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
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

          return PdfPreview(
            canChangeOrientation: false,
            canDebug: false,
            maxPageWidth: 700,
            previewPageMargin: const EdgeInsets.all(20),
            build: (format) => _buildPdf(format),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadData() async {
    final datosUsuario = await getDatosUsuario(uid);
    final salarioHora = datosUsuario.salarioBase > 0 
        ? datosUsuario.salarioBase / (8 * 22) 
        : 0.0;
    final registros = await getRegistrosPeriodo(empleadoId, fechaInicio, fechaFin, salarioHora);
    
    return {
      'datosUsuario': datosUsuario,
      'registros': registros,
    };
  }
}