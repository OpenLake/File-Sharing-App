import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

// Web-only imports with proper conditional compilation
import 'dart:html' as html;
import 'dart:ui_web' as ui_web show platformViewRegistry;

class DragDropZone extends StatefulWidget {
  final Function(PlatformFile) onFileDropped;
  final bool isUploading;

  const DragDropZone({
    super.key,
    required this.onFileDropped,
    required this.isUploading,
  });

  @override
  State<DragDropZone> createState() => _DragDropZoneState();
}

class _DragDropZoneState extends State<DragDropZone> {
  bool isDragOver = false;
  String? viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      viewId = 'drag-drop-${DateTime.now().millisecondsSinceEpoch}';
      _registerView();
    }
  }

  void _registerView() {
    if (!kIsWeb || viewId == null) return;

    ui_web.platformViewRegistry.registerViewFactory(viewId!, (int id) {
      final div = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.background = 'transparent';

      div.addEventListener('dragenter', (event) {
        event.preventDefault();
        if (!widget.isUploading && mounted) {
          setState(() => isDragOver = true);
        }
      });

      div.addEventListener('dragover', (event) {
        event.preventDefault();
      });

      div.addEventListener('dragleave', (event) {
        event.preventDefault();
        if (mounted) {
          setState(() => isDragOver = false);
        }
      });

      div.addEventListener('drop', (event) {
        event.preventDefault();
        if (mounted) {
          setState(() => isDragOver = false);
        }

        if (widget.isUploading) return;

        final dragEvent = event;
        final dataTransfer = (dragEvent as dynamic).dataTransfer;
        final files = dataTransfer?.files;
        if (files != null && files.isNotEmpty) {
          final file = files.first;
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((_) {
            final bytes = reader.result as Uint8List;
            final platformFile = PlatformFile(
              name: file.name,
              size: file.size,
              bytes: bytes,
            );
            widget.onFileDropped(platformFile);
          });
        }
      });

      return div;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDragOver ? Colors.blue : Colors.grey,
          width: isDragOver ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isDragOver
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
      ),
      child: kIsWeb && viewId != null
          ? Stack(
              children: [
                Positioned.fill(
                  child: HtmlElementView(viewType: viewId!),
                ),
                IgnorePointer(
                  child: _buildContent(),
                ),
              ],
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDragOver ? Icons.cloud_upload : Icons.cloud_upload_outlined,
            size: 48,
            color: isDragOver ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isDragOver ? 'Drop file here' : 'Drag & drop files here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDragOver ? Colors.blue : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
