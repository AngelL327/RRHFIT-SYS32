import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rrhfit_sys32/Reportes/report_header.dart';
import 'package:rrhfit_sys32/Reportes/report_footer.dart';
class GeneratePDFButton<T> extends StatelessWidget {
  const GeneratePDFButton({
    super.key,
    required this.buttonLabel,
    required this.reportTitle,
    required this.fetchData,
    required this.tableHeaders,
    required this.rowMapper,
    this.reportMonth,
    this.reportYear,
    this.logoAsset = 'assets/images/fittlay_imagotipo.png',
    this.fallbackLogoAsset = 'images/fittlay.png',
    this.fontAsset = 'assets/fonts/Roboto-Regular.ttf',
    this.columnFlexes,
    this.bodyContent,
    this.buttonWidth = 8.0,
  });

  final String buttonLabel;
  final String reportTitle;
  final Future<List<T>> Function() fetchData;
  final List<String> tableHeaders;
  final List<String> Function(T item) rowMapper;
  final String logoAsset;
  final String fallbackLogoAsset;
  final String fontAsset;
  final List<double>? columnFlexes;
  final pw.Widget? bodyContent;
  final double buttonWidth;
  // Optional period to be displayed in the report header
  final int? reportMonth;
  final int? reportYear;

  Future<Uint8List> _buildPdf(pdf_lib.PdfPageFormat format) async {
    final doc = pw.Document();
    final data = await fetchData();

    final dateFmt = DateFormat('dd-MM-yyyy');
    final double hPadding = 30;
    final double vPadding = 10;

    // load logo from assets into a MemoryImage for the pdf
    Uint8List logoBytes;
    try {
      logoBytes = (await rootBundle.load(logoAsset)).buffer.asUint8List();
    } catch (_) {
      logoBytes = (await rootBundle.load(fallbackLogoAsset)).buffer.asUint8List();
    }
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    // Try to load a TTF font from assets/fonts/ so the PDF uses a Unicode-capable font
    pw.Font? ttf;
    try {
      final fontData = await rootBundle.load(fontAsset);
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
    } catch (e) {
      ttf = null;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        header: (context) => reportHeader(
          title: reportTitle,
          logo: logoImage,
          dateString: dateFmt.format(DateTime.now()),
          hPadding: 0,
          vPadding: 0,
          font: ttf,
          selectedMonth: reportMonth,
          selectedYear: reportYear,
        ),
        footer: (context) => reportFooter(context, hPadding: hPadding, vPadding: vPadding, font: ttf),
        build: (context) {
          // build table data
          final tableData = data.map((d) => rowMapper(d)).toList();

          // prepare column widths
          final Map<int, pw.FlexColumnWidth> widths = {};
          for (var i = 0; i < tableHeaders.length; i++) {
            final flex = (columnFlexes != null && i < columnFlexes!.length) ? columnFlexes![i] : 1.0;
            widths[i] = pw.FlexColumnWidth(flex);
          }

          return [
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
              child: pw.TableHelper.fromTextArray(
                headers: tableHeaders,
                data: tableData,
                headerStyle: ttf != null ? pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10) : pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: ttf != null ? pw.TextStyle(font: ttf, fontSize: 9) : pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(color: AppTheme.pdfTableHeaderBG),
                columnWidths: widths,                
                border: pw.TableBorder.all(width: 0.5, color: pdf_lib.PdfColors.black),
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: AppTheme.lightTheme.elevatedButtonTheme.style,
      icon: Row(
        children: [
          Icon(Icons.picture_as_pdf),
          SizedBox(width: buttonWidth),
          Text(buttonLabel, style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
        ],
      ),
      tooltip: buttonLabel,
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
                  onZoomChanged: (value) => {},

                  pageFormats: const {
                    'A4': pdf_lib.PdfPageFormat.a4,
                    'Letter': pdf_lib.PdfPageFormat.letter,
                  },
                  
                  actionBarTheme: PdfActionBarTheme(backgroundColor: AppTheme.primary),
                  canChangeOrientation: true,
                  canDebug: false,
                  maxPageWidth: 900,
                  pdfFileName: "${reportTitle.replaceAll(' ', '_').toLowerCase()}.pdf",
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

