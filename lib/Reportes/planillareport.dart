import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_HN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vista General Reporte Planilla',
      home: const ReportePlanillaFirestore(),
    );
  }
}

class ReportePlanillaFirestore extends StatefulWidget {
  const ReportePlanillaFirestore({super.key});

  @override
  State<ReportePlanillaFirestore> createState() =>
      _ReportePlanillaFirestoreState();
}

class _ReportePlanillaFirestoreState extends State<ReportePlanillaFirestore> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GlobalKey _repaintKey = GlobalKey();

  Map<String, List<Map<String, dynamic>>> departamentos = {};
  bool loading = true;

  final List<Color> cardColors = [
    Colors.blue.shade300,
    Colors.green.shade300,
    const Color(0xFFFFB74D),
    const Color.fromARGB(255, 69, 168, 217),
    const Color.fromARGB(255, 72, 206, 193),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final deptSnapshot = await _db.collection("departamento").get();
      final empSnapshot = await _db.collection("empleados").get();

      final empleados = empSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "nombre": data["nombre"] ?? '',
          "departamento_id": data["departamento_id"] ?? '',
        };
      }).toList();

      final Map<String, List<Map<String, dynamic>>> temp = {};

      for (var doc in deptSnapshot.docs) {
        final deptId = doc.id;
        final nombreDepto = doc.data()["nombre"] ?? '';
        temp[nombreDepto] = empleados
            .where((e) => e["departamento_id"] == deptId)
            .toList();
      }

      setState(() {
        departamentos = temp;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error fetching data: $e");
    }
  }

  double _randomSalary() => 1000000 + Random().nextInt(1000000).toDouble();
  double _randomDeduccion() => 50000 + Random().nextInt(150000).toDouble();

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_US',
      symbol: 'L ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Future<void> _exportToPdf() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0); // Más resolución
      final logoBytes = await rootBundle.load('assets/images/fittlay.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());


      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a3,
          build: (context) => pw.Stack(
            children: [
              // Fondo con opacidad (marca de agua centrada)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1, // transparencia del fondo
                    child: pw.Image(
                      logo,
                      fit: pw.BoxFit.contain,
                      width: 400, // tamaño del fondo
                    ),
                  ),
                ),
              ),

              // 🔹 Imagen principal (tu gráfico o captura)
              pw.Expanded(
                child: pw.Image(
                  pw.MemoryImage(pngBytes),
                  fit: pw.BoxFit.contain,
                  width: PdfPageFormat.a5.width,
                  height: PdfPageFormat.a3.height,
                ),
              ),

              // 🔹 Logo pequeño en esquina superior derecha
             
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      debugPrint('Error exportando PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final fechaReporte =
        '${toBeginningOfSentenceCase(meses[DateTime.now().month - 1])} ${DateTime.now().year}';

    // Totales por departamento
    final Map<String, double> totalSueldoPorDepto = {};
    final Map<String, double> totalDeduccionesPorDepto = {};

    departamentos.forEach((depto, empleadosDepto) {
      totalSueldoPorDepto[depto] = empleadosDepto
          .map((e) => _randomSalary())
          .fold<double>(0, (a, b) => a + b);
      totalDeduccionesPorDepto[depto] = empleadosDepto
          .map((e) => _randomDeduccion())
          .fold<double>(0, (a, b) => a + b);
    });

    const double maxBarHeight = 180;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Vista General Reporte Planilla'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // REPAINTBOUNDARY para PDF (solo contenido)
            RepaintBoundary(
              key: _repaintKey,
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/fittlay.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reporte de Planilla por Departamento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    fechaReporte,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // TARJETAS DE DEPARTAMENTOS
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'DEPARTAMENTOS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: departamentos.entries.map((entry) {
                                final depto = entry.key;
                                final empleadosDepto = entry.value;
                                final totalEmpleados = empleadosDepto.length;
                                final totalSueldo = empleadosDepto
                                    .map((e) => _randomSalary())
                                    .fold<double>(0, (a, b) => a + b);
                                final totalDeducciones = empleadosDepto
                                    .map((e) => _randomDeduccion())
                                    .fold<double>(0, (a, b) => a + b);

                                final color =
                                    cardColors[departamentos.keys
                                            .toList()
                                            .indexOf(depto) %
                                        cardColors.length];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Column(
                                    children: [
                                      Card(
                                        color: color,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Container(
                                          width: 300,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '$totalEmpleados',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Text(
                                                'TOTAL EMPLEADOS',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _formatCurrency(totalSueldo),
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Text(
                                                'TOTAL SUELDO',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _formatCurrency(
                                                  totalDeducciones,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Text(
                                                'TOTAL DEDUCCIONES',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        depto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // GRAFICAS BARRA Y DONA
                  SizedBox(
                    height: maxBarHeight + 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: totalSueldoPorDepto.entries.map((
                                    e,
                                  ) {
                                    final depto = e.key;
                                    final sueldo = e.value;
                                    final colorSueldo =
                                        cardColors[departamentos.keys
                                                .toList()
                                                .indexOf(depto) %
                                            cardColors.length];
                                    final maxValue = totalSueldoPorDepto.values
                                        .reduce((a, b) => a > b ? a : b);
                                    final barHeight =
                                        (sueldo / maxValue) * maxBarHeight;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatCurrency(sueldo),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: 50,
                                            height: barHeight,
                                            color: colorSueldo,
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              depto,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            width: 180,
                            height: maxBarHeight,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 50,
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: totalSueldoPorDepto.values
                                        .fold<double>(0, (a, b) => a + b),
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFFFFB74D),
                                    value: totalDeduccionesPorDepto.values
                                        .fold<double>(0, (a, b) => a + b),
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // BOTON FUERA DEL REPAINTBOUNDARY
            ElevatedButton.icon(
              onPressed: _exportToPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar a PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
