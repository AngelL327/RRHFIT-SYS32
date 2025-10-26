import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:rrhfit_sys32/logic/incapacidad_function.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rrhfit_sys32/Reportes/report_header.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart';
// import 'package:path/path.dart' as p; // not needed for asset key
//
//TODO: Generalizar pantalla de generacion de PDF para otros reportes


class GeneratePDFScreen extends StatelessWidget {
  const GeneratePDFScreen({super.key, required this.title});

  final String title;

  Future<Uint8List> _buildPdf(pdf_lib.PdfPageFormat format) async {
  final doc = pw.Document();
    // fetch data
    List<IncapacidadModel> incapacidades = await getAllIncapacidades();

    final dateFmt = DateFormat('dd-MM-yyyy');
    final double hPadding = 40;
    final double vPadding = 20;

    // load logo from assets into a MemoryImage for the pdf
    // On some platforms (web) the asset key is resolved to 'assets/<key>' so
    // trying both common keys makes the code more robust.
    Uint8List logoBytes;
    try {
      logoBytes = (await rootBundle.load('assets/images/fittlay.png')).buffer.asUint8List();
    } catch (_) {
      // fallback key (some build systems resolve assets without the 'assets/' prefix)
      logoBytes = (await rootBundle.load('images/fittlay.png')).buffer.asUint8List();
    }
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    // Try to load a TTF font from assets/fonts/ so the PDF uses a Unicode-capable font
    // Place a TTF (e.g., Roboto-Regular.ttf) under assets/fonts/ and it will be used here.
    pw.Font? ttf;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
    } catch (e) {
      // If font isn't present, continue without it (pdf package will fallback to Helvetica)
      ttf = null;
    }

    doc.addPage(
      pw.MultiPage(
  pageFormat: format,
  // remove margins if you want full-bleed PDF; printers may still apply hardware margins
  margin: pw.EdgeInsets.zero,
        // Header shown on every page
        header: (context) => reportHeader(
          title: 'Reporte de Incapacidades',
          logo: logoImage,
          dateString: dateFmt.format(DateTime.now()),
          hPadding: 0,
          vPadding: 0,
          font: ttf,
        ),
        // Footer shown on every page (reusable)
        footer: (context) => reportFooter(context, hPadding: hPadding, vPadding: vPadding, font: ttf),

        build: (context) {
          return [
            // pw.SizedBox(height: 10),
            // pw.Text('Total: ${incapacidades.length}', style: ttf != null ? pw.TextStyle(font: ttf, fontSize: 12) : pw.TextStyle(fontSize: 12)),
            // pw.SizedBox(height: 12),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
              child:pw.TableHelper.fromTextArray(
              headers: ['Empleado', 'Inicio', 'Fin', 'Estado'],
              data: incapacidades.map((inc) {
                final inicio = dateFmt.format(inc.fechaInicioIncapacidad);
                final fin = dateFmt.format(inc.fechaFinIncapacidad);
                return [inc.usuario, inicio, fin, inc.estado];
              }).toList(),
              headerStyle: ttf != null ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10) : pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: ttf != null ? pw.TextStyle(font: ttf, fontSize: 9) : pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: pdf_lib.PdfColors.grey300),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
              },
              border: pw.TableBorder.all(width: 0.5, color: pdf_lib.PdfColors.grey600),
            ),
            ),
            pw.SizedBox(height: 20),
          ];
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
              child: const Text('Abrir vista previa en diálogo'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final size = MediaQuery.of(context).size;
                    return AlertDialog(
                      titlePadding: EdgeInsets.fromLTRB(16, 12, 8, 0),
                      title: Row(
                        children: [
                          Expanded(child: Text('Imprimir')),
                          IconButton(
                            icon: Icon(Icons.close, size: 20),
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
                        child: PdfPreview(
                          canChangeOrientation: true,
                          canDebug: false,
                          maxPageWidth: 700,
                          previewPageMargin: const EdgeInsets.all(20),
                          build: (format) => _buildPdf(format),
                        ),
                      ),
                    );
                  },
                );
              },
            );
  }
}
