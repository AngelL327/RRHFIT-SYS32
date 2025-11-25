import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';

// Widget para mostrar el documento en un diálogo completo
class DocumentViewerDialog extends StatefulWidget {
  final String documentUrl;
  final String titulo;

  const DocumentViewerDialog({
    required this.documentUrl,
    required this.titulo,
    super.key,
  });

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  bool _esPdf() => widget.documentUrl.toLowerCase().endsWith('.pdf');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Para PDFs, abrir directamente en el navegador
    if (_esPdf()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirPdfEnNavegador();
      });
    }
  }

  void _abrirPdfEnNavegador() {
    debugPrint("Abriendo PDF en navegador: ${widget.documentUrl}");
    html.window.open(widget.documentUrl, '_blank');
    // Cerrar el diálogo después de abrir
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _descargarArchivo() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint("Descargando archivo: ${widget.documentUrl}");
      final uri = Uri.parse(widget.documentUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = 'certificado_incapacidad.pdf';
        anchor.click();
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo descargado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(" Error descargando: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2E7D32),
                child: Row(
                  children: [
                    Icon(_esPdf() ? Icons.picture_as_pdf : Icons.image, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.titulo,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Contenido
              Flexible(
                child: Container(
                  color: Colors.grey[100],
                  child: _esPdf() ? _buildPdfContent() : _buildImageContent(),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: _esPdf() ? _buildPdfFooter() : _buildImageFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Documento abierto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El PDF se ha abierto en una nueva pestaña del navegador',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  'Si no se abrió, revisa el bloqueador de ventanas emergentes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Image.network(
      widget.documentUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Cargando imagen...'),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar la imagen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfFooter() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _abrirPdfEnNavegador,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir nuevamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              minimumSize: const Size(0, 50),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _descargarArchivo,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download),
            label: Text(_isLoading ? 'Descargando...' : 'Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageFooter() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close),
      label: const Text('Cerrar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

// Función auxiliar para mostrar el diálogo desde cualquier parte
void mostrarDocumento(BuildContext context, String url, String titulo) {
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay documento disponible'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  debugPrint("Abriendo documento: $url");
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => DocumentViewerDialog(
      documentUrl: url,
      titulo: titulo,
    ),
  );
}

// Preview inline optimizado
Widget documentPreview(BuildContext context, IncapacidadModel inc) {
  final url = inc.documentoUrl.trim();
  final theme = AppTheme.lightTheme.textTheme;
  
  if (url.isEmpty) {
    return Center(child: Text('No hay documento adjunto', style: theme.bodyMedium));
  }

  final lower = url.split('?').first.toLowerCase();
  
  // Para imágenes
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
    return FutureBuilder<Uint8List?>(
      future: () async {
        try {
          debugPrint("Descargando imagen preview: $url");
          final uri = Uri.parse(url);
          final resp = await http.get(uri).timeout(const Duration(seconds: 15));
          if (resp.statusCode == 200) {
            debugPrint("Imagen preview descargada");
            return resp.bodyBytes;
          } else {
            debugPrint('Error HTTP ${resp.statusCode}');
            return null;
          }
        } catch (e) {
          debugPrint('Error descargando imagen: $e');
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
            errorBuilder: (c, e, s) => Center(
              child: Text('Error al mostrar la imagen', style: theme.bodyMedium),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text('No se pudo cargar la imagen', style: theme.titleMedium),
            ],
          ),
        );
      },
    );
  }

  // Para PDFs - mostrar indicador elegante
  if (lower.endsWith('.pdf')) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.picture_as_pdf, size: 64, color: Colors.red.shade700),
            ),
            const SizedBox(height: 20),
            Text('Documento PDF adjunto', style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Haz clic en "Ver Documento" para abrirlo',
              style: theme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => mostrarDocumento(context, url, 'Certificado de Incapacidad'),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text('Ver Documento', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Center(
    child: Text('Archivo adjunto: ${url.split('/').last}', style: theme.bodyMedium),
  );
}