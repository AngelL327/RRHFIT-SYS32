import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Widget documentPreview(BuildContext context, IncapacidadModel inc) {
  final url = inc.documentoUrl.trim();
  final theme = AppTheme.lightTheme.textTheme;
  if (url.isEmpty) {
    return Center(child: Text('No hay documento adjunto', style: theme.bodyMedium));
  }

  final lower = url.toLowerCase();
  // Simple inline preview: images shown via network image; PDFs show a placeholder
  if (!lower.endsWith('.pdf')) {
    // Use http to fetch bytes and show Image.memory so we can handle failures gracefully
    return FutureBuilder<Uint8List?>(
      future: () async {
        try {
          final uri = Uri.parse(url);
          final resp = await http.get(uri).timeout(const Duration(seconds: 15));
          if (resp.statusCode == 200) {
            return resp.bodyBytes;
          } else {
            // non-200, return null so the UI shows the error text below
            debugPrint('Image HTTP error ${resp.statusCode} for $url');
            return null;
          }
        } catch (e) {
          debugPrint('Error fetching image: $e');
          return null;
        }
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => Center(child: Text('Error al mostrar la imagen', style: theme.bodyMedium)),
          );
        }
        // Show helpful error + raw URL so you can diagnose (CORS, cert, cleartext, etc.)
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text('No se pudo cargar la imagen', style: theme.titleMedium),
              const SizedBox(height: 6),
              Text(url, overflow: TextOverflow.ellipsis, style: theme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  if (lower.endsWith('.pdf')) {
    // Try to display a quick inline preview of the first page of the PDF using
    // Syncfusion's PDF viewer. We constrain its height so the UI behaves like a
    // thumbnail/preview showing the first page; tapping the preview could open
    // the full PDF viewer if desired (not implemented here).
    try {
      return SizedBox(
        height: 420,
        child: SfPdfViewer.network(
          url,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          initialZoomLevel: 1.0,
          // The viewer will render the document; wrap in Material to match theme
        ),
      );
    } catch (e) {
      debugPrint('Error mostrando PDF: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 8),
            Text('PDF adjunto', style: theme.titleMedium),
            const SizedBox(height: 6),
            Text(url, overflow: TextOverflow.ellipsis, style: theme.bodySmall),
          ],
        ),
      );
    }
  }

  // Fallback for other types
  return Center(child: Text('Archivo adjunto: ${url.split('/').last}', style: theme.bodyMedium));
}
