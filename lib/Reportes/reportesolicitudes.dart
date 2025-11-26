// lib/Reportes/reportesolicitudes.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/utilities/obtener_mes_string.dart';
import 'package:rrhfit_sys32/Reportes/report_header.dart';

/// Página que recibe los docs (de Firestore) y genera el PDF.
/// Idea: renderizamos las gráficas con fl_chart dentro de RepaintBoundary
/// las convertimos a imagen y las insertamos en el PDF para que quede idéntico.
class GenerarReportePage extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  const GenerarReportePage({super.key, required this.docs});

  @override
  State<GenerarReportePage> createState() => _GenerarReportePageState();
}

class _GenerarReportePageState extends State<GenerarReportePage> {
  // Keys para capturar cada gráfico
  final GlobalKey _keyDonaTotal = GlobalKey();
  final GlobalKey _keyDonaDepto = GlobalKey();
  final GlobalKey _keyBar1 = GlobalKey();
  final GlobalKey _keyBar2 = GlobalKey();

  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    // toma los docs pasados desde el widget (debe estar antes de usarlos)
    final docs = widget.docs;

    // --- calcula agregados a partir de `docs` ---
    final Map<String, int> porDepto = {};
    final Map<String, Map<String, int>> deptoPorEstado =
        {}; // depto -> {estado->count}
    final Map<String, int> tipoCounts = {};

    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;

      final depto = data["departamento"]?.toString().trim();
      final estado = (data["estado"] ?? "Pendiente").toString();
      final tipo = (data["tipo"] ?? "Otro").toString();

      // Solo procesar si el departamento existe y no está vacío
      if (depto == null || depto.isEmpty) continue;

      // total por depto
      porDepto[depto] = (porDepto[depto] ?? 0) + 1;

      // conteo por estado dentro de cada depto
      deptoPorEstado[depto] ??= {"Aprobada": 0, "Rechazada": 0, "Pendiente": 0};
      deptoPorEstado[depto]![estado] =
          (deptoPorEstado[depto]![estado] ?? 0) + 1;

      // conteo por tipo
      tipoCounts[tipo] = (tipoCounts[tipo] ?? 0) + 1;
    }

    // determina departamento con más solicitudes
    String topDept = "Sin datos";
    if (porDepto.isNotEmpty) {
      topDept = porDepto.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    // prepara valores para la primera barra: estados del departamento topDept
    final estadoMap =
        deptoPorEstado[topDept] ??
        {"Aprobada": 0, "Rechazada": 0, "Pendiente": 0};
    final List<String> estadosLabels = [
      "Aprobadas",
      "Rechazadas",
      "Pendientes",
    ];
    final List<int> estadosValues = [
      estadoMap["Aprobada"] ?? 0,
      estadoMap["Rechazada"] ?? 0,
      estadoMap["Pendiente"] ?? 0,
    ];

    // colores (puedes ajustar)
    final List<Color> estadosColors = const [
      Color(0xFF2E8B57), // aprobadas
      Color(0xFF1FA9D6), // rechazadas
      Color(0xFFF57C00), // pendientes
    ];

    // prepara valores para la segunda barra: tipos de solicitud (top N)
    final tipoEntries = tipoCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTipoEntries = tipoEntries.take(6).toList();
    final List<String> tiposLabels = topTipoEntries.map((e) => e.key).toList();
    final List<int> tiposValues = topTipoEntries.map((e) => e.value).toList();
    final List<Color> tiposColors = [
      const Color(0xFF2E8B57),
      const Color(0xFF29B6F6),
      const Color(0xFFFFA726),
      const Color(0xFFAB47BC),
      const Color(0xFFFF7043),
      const Color(0xFF78909C),
    ].take(tiposLabels.length).toList();

    // Calcula totales que usabas antes (puedes mantenerlos)
    final totalPend = docs.where((d) => d["estado"] == "Pendiente").length;
    final totalApr = docs.where((d) => d["estado"] == "Aprobada").length;
    final totalRec = docs.where((d) => d["estado"] == "Rechazada").length;
    final totalGlobal = totalPend + totalApr + totalRec;
    final totalDeptos = porDepto.values.fold<int>(0, (a, b) => a + b);

    // --- UI ---
    return Scaffold(
      appBar: AppBar(title: const Text("Generar Reporte PDF")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generar y Descargar PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57), // color del botón
                  foregroundColor: Colors.white, // color del texto e ícono
                ),
                onPressed: _isGenerating
                    ? null
                    : () => _onGeneratePdfPressed(docs),
              ),
              const SizedBox(height: 20),

              Wrap(
                direction: Axis.vertical,
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  Row(
                    children: [
                      RepaintBoundary(
                        key: _keyDonaTotal,
                        child: SizedBox(
                          width: 450,
                          height: 190,
                          child: _buildDonaWidget(
                            "Solicitudes totales",
                            totalGlobal,
                            [
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
                            ],
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        key: _keyDonaDepto,
                        child: SizedBox(
                          width: 450,
                          height: 190,
                          child: _buildDonaWidget(
                            "Solicitudes por área",
                            totalDeptos,
                            porDepto.entries.map((e) {
                              final c = _colorForDepto(e.key);
                              return _DonaItem(e.key, e.value, c);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      RepaintBoundary(
                        key: _keyBar1,
                        child: SizedBox(
                          width: 450,
                          height: 260,
                          child: _buildBarWidget(
                            "Área: $topDept",
                            estadosLabels,
                            estadosValues,
                            estadosColors,
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        key: _keyBar2,
                        child: SizedBox(
                          width: 450,
                          height: 260,
                          child: _buildBarWidget(
                            "Tipo de solicitud",
                            tiposLabels,
                            tiposValues,
                            tiposColors,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              if (_isGenerating)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 12),
                      Text(
                        "Generando reporte, por favor espere...",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // cámbialo si lo quieres blanco
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Al presionar el botón: capturamos y generamos el PDF
  Future<void> _onGeneratePdfPressed(List<QueryDocumentSnapshot> docs) async {
    setState(() => _isGenerating = true);
    try {
      // Pequeña espera para asegurar renderizado
      await Future.delayed(const Duration(milliseconds: 200));

      final img1 = await _capturePng(_keyDonaTotal);
      final img2 = await _capturePng(_keyDonaDepto);
      final img3 = await _capturePng(_keyBar1);
      final img4 = await _capturePng(_keyBar2);

      // Generar PDF con esas imágenes
      final pdfBytes = await _buildPdfFromImages([
        img1,
        img2,
        img3,
        img4,
      ], docs);

      // Mostrar diálogo/descarga usando printing
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e, st) {
      debugPrint("Error generando PDF: $e\n$st");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generando PDF: $e")));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  // Captura Uint8List PNG de un RepaintBoundary
  Future<Uint8List> _capturePng(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception("RenderRepaintBoundary no disponible (key: $key)");
    }
    // mayor pixelRatio para mejor resolución en PDF (2.0 o 3.0)
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) throw Exception("Error al convertir imagen a bytes");
    return byteData.buffer.asUint8List();
  }

  // Construye el PDF con las imágenes y tablas
  Future<Uint8List> _buildPdfFromImages(
    List<Uint8List> images,
    List<QueryDocumentSnapshot> docs,
  ) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/images/fittlay.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
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

    // Página única estilo landscape (ajusta si quieres)
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          buildBackground: (context) {
            return pw.Center(
              child: pw.Opacity(
                opacity: 0.10,
                child: pw.Image(logo, width: 500, fit: pw.BoxFit.contain),
              ),
            );
          },
        ),
        build: (context) => [
          // Encabezado con título
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

            children: [
              pw.Text(
                'Departamento de RRHH                                                                                                                              Fecha: 10-11-2025',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: pdf_lib.PdfColors.grey700,
                ),
              ),

              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Container(
                  width: 40, // ajusta el tamaño del logo
                  height: 40,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Fittlay',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.Text(
                'Reporte general y por áreas de las solicitudes',
                style: pw.TextStyle(fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Primera fila: dos imágenes de dona
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                width: 400,
                child: pw.Image(pw.MemoryImage(images[0])),
              ),
              pw.Container(
                width: 400,
                child: pw.Image(pw.MemoryImage(images[1])),
              ),
            ],
          ),

          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'Area que hizo mas solicitudes y el tipo',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 2),
          // Segunda fila: dos imágenes de barras
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Image(pw.MemoryImage(images[2]))),
              pw.Expanded(child: pw.Image(pw.MemoryImage(images[3]))),
            ],
          ),

          pw.SizedBox(height: 12),

          // (Opcional) una tabla resumen con totales
        ],
      ),
    );

    return pdf.save();
  }

  // ------------------ Helpers UI (fl_chart widgets) ------------------

  // Dona con fl_chart (igual que tu UI)
  Widget _buildDonaWidget(String titulo, int total, List<_DonaItem> items) {
    final sections = items.map((e) {
      final porc = total == 0 ? 0.0 : (e.valor / total) * 100;
      return PieChartSectionData(
        color: e.color,
        value: e.valor.toDouble(),
        radius: 40,
        title: '${porc.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      sections: sections,
                    ),
                  ),
                ),

                Expanded(child: _buildTablaDona(items, total)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaDona(List<_DonaItem> items, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              ...items.map((e) {
                final porc = total == 0 ? 0.0 : (e.valor / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 1,
                  ),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, color: e.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.label, style: TextStyle(fontSize: 8)),
                      ),
                      Text(
                        '${porc.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 8,
                          color: const ui.Color.fromARGB(255, 15, 13, 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.valor}',
                        style: TextStyle(
                          fontSize: 8,
                          color: const ui.Color.fromARGB(255, 5, 4, 4),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    const Spacer(),
                    const Text(
                      'Total: ',
                      style: const TextStyle(
                        fontSize: 8,
                        color: ui.Color.fromARGB(255, 14, 11, 11),
                      ),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 8,
                        color: ui.Color.fromARGB(255, 5, 4, 4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Barra simple con fl_chart
  Widget _buildBarWidget(
    String titulo,
    List<String> categories,
    List<int> values,
    List<Color> colors,
  ) {
    final total = values.fold<int>(0, (a, b) => a + b);
    final maxY = values.isEmpty
        ? 1
        : (values.reduce((a, b) => a > b ? a : b).toDouble() + 1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),

            // --- Gráfico de barras ---
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY.toDouble(),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < categories.length) {
                            return Text(
                              categories[idx],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 8,
                                color: ui.Color.fromARGB(255, 17, 14, 14),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(values.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].toDouble(),
                          color: colors[i],
                          width: 18,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 3),

            // --- Tabla simple debajo del gráfico ---
            Column(
              children: List.generate(categories.length, (i) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categories[i],
                      style: const TextStyle(
                        fontSize: 8,
                        color: ui.Color.fromARGB(255, 8, 5, 5),
                      ),
                    ),
                    Text(
                      values[i].toString(),
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 1),

            // --- Total general ---
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total: $total solicitudes",
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: ui.Color.fromARGB(255, 10, 10, 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForDepto(String depto) {
    switch (depto.toLowerCase()) {
      case 'producción':
        return const Color(0xFF4CAF50);
      case 'recursos humanos':
        return const Color(0xFFFFA726);
      case 'ventas':
        return const Color(0xFF29B6F6);
      case 'administración':
        return const Color(0xFFAB47BC);
      case 'sistemas':
        return const Color(0xFFFF7043);
      default:
        return Colors.blueGrey;
    }
  }
}

class _DonaItem {
  final String label;
  final int valor;
  final Color color;
  _DonaItem(this.label, this.valor, this.color);
}
