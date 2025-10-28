// lib/pdf_storage_widget.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PdfStorageWidget extends StatefulWidget {
  const PdfStorageWidget({Key? key}) : super(key: key);

  @override
  _PdfStorageWidgetState createState() => _PdfStorageWidgetState();
}

class _PdfStorageWidgetState extends State<PdfStorageWidget> {
  final supabase = Supabase.instance.client;
  String? uploadedPath;
  String? publicUrl;
  bool loading = false;

  Future<void> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // importante: trae bytes en desktop
    );

    if (result == null) return; // el usuario canceló
    final file = result.files.first;
    final bytes = file.bytes;
    final filename = 'Reportes/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    if (bytes == null) return;

    setState(() => loading = true);

    try {
      // 1) Subir (uploadBinary)
      final fullPath = await supabase.storage
          .from('Reportes') // nombre del bucket
          .uploadBinary(filename, bytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      // 2) Obtener URL pública (si el bucket es public)
      final url = supabase.storage.from('Reportes').getPublicUrl(filename);

      setState(() {
        uploadedPath = filename;
        publicUrl = url;
      });
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo PDF: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> downloadAndOpen() async {
    if (uploadedPath == null) return;
    setState(() => loading = true);

    try {
      // Si el bucket es private => utiliza createSignedUrl en vez de download (o usa download para bytes).
      // Aquí mostramos la opción de descargar bytes directamente (funciona para private y public si hay permisos).
      final Uint8List fileBytes = await supabase.storage.from('Reportes').download(uploadedPath!);

      // Guardar temporal en disco
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${uploadedPath!.split('/').last}');
      await file.writeAsBytes(fileBytes);

      // Abrir el PDF con app por defecto
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error descargando PDF: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> getSignedUrl() async {
    if (uploadedPath == null) return;
    // Crear signed URL válida por 1 hora (3600 segundos)
    final res = await supabase.storage
        .from('Reportes')
        .createSignedUrl(uploadedPath!, 3600);
    final signedUrl = res; // según la API devuelve string
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed URL: $signedUrl')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: loading ? null : pickAndUpload,
          child: Text('Seleccionar y subir PDF'),
        ),
        ElevatedButton(
          onPressed: (uploadedPath == null || loading) ? null : downloadAndOpen,
          child: Text('Descargar y abrir PDF'),
        ),
        ElevatedButton(
          onPressed: (uploadedPath == null || loading) ? null : getSignedUrl,
          child: Text('Crear signed URL (1h)'),
        ),
        if (publicUrl != null) SelectableText('Public URL: $publicUrl'),
      ],
    );
  }
}
