import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'drag_drop_zone.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Sharing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String download = "";
  String? uploadedFilename;
  bool isUploading = false;
  bool isDownloading = false;

  Future<void> share() async {
    await Share.share(
      download.isEmpty ? 'No file URL available' : 'Shared file URL: $download',
      subject: 'Shared File URL',
    );
  }

  Future<void> _uploadFile(PlatformFile file) async {
    setState(() {
      isUploading = true;
    });
    final currentContext = context;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/upload'),
      );

      if (kIsWeb) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ));
          uploadedFilename = file.name;
        } else {
          throw Exception('File bytes are unavailable');
        }
      } else {
        if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            file.path!,
          ));
          uploadedFilename = file.name;
        } else {
          throw Exception('File path is unavailable');
        }
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (mounted && currentContext.mounted) {
        if (response.statusCode == 200) {
          setState(() {
            download = responseBody.trim();
            isUploading = false;
          });
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text("File uploaded successfully")),
          );
        } else {
          setState(() {
            isUploading = false;
          });
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text("Upload failed: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      if (mounted && currentContext.mounted) {
        String errorMessage =
            "Server not running. Please start Node.js server first.";
        if (e.toString().contains('Failed to fetch')) {
          errorMessage =
              "Cannot connect to server. Run 'start_node_server.bat' to start backend.";
        }
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Help',
              onPressed: () => _showServerHelp(currentContext),
            ),
          ),
        );
      }
    }
  }

  void _showServerHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Setup'),
        content: const Text(
          'To use file upload:\n\n'
          '1. Run "start_node_server.bat" in project folder\n'
          '2. Wait for "Server running at: http://127.0.0.1:8000"\n'
          '3. Try uploading again\n\n'
          'Make sure Node.js is installed on your system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Sharing App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "FILE SHARING APP",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 40,
                  shadows: <Shadow>[
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 8.0,
                      color: Color.fromARGB(125, 0, 0, 255),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              // Drag and Drop Zone for Web
              if (kIsWeb)
                DragDropZone(
                  onFileDropped: _uploadFile,
                  isUploading: isUploading,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        try {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: false,
                          );

                          if (result != null && result.files.isNotEmpty) {
                            await _uploadFile(result.files.single);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Error selecting file: $e")),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.bold),
                  foregroundColor: Colors.red,
                  shadowColor: Colors.lightBlue,
                  elevation: 15,
                  minimumSize: const Size(200, 80),
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(kIsWeb ? 'BROWSE FILES' : 'UPLOAD FILE'),
              ),
              if (isUploading)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        'Uploading ${uploadedFilename ?? "file"}...',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    constraints: const BoxConstraints(
                      minHeight: 50,
                      minWidth: 50,
                      maxWidth: 300,
                      maxHeight: 70,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(download),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final currentContext = context;
                      if (download.trim().isEmpty) {
                        if (mounted && currentContext.mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(content: Text("No text to copy")),
                          );
                        }
                      } else {
                        await Clipboard.setData(ClipboardData(text: download));
                        if (mounted && currentContext.mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text("Text copied"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: const Icon(Icons.copy, color: Colors.blue, size: 32),
                  ),
                  IconButton(
                    onPressed: share,
                    icon: const Icon(Icons.share, color: Colors.blue, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (download.isEmpty)
                    ? null
                    : () async {
                        if (kIsWeb) {
                          // Open download link in new tab for web
                          html.window.open(download, '_blank');
                        } else {
                          // For mobile/desktop, you could use url_launcher
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Download: $download")),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.bold),
                  foregroundColor: Colors.red,
                  shadowColor: Colors.lightBlue,
                  elevation: 15,
                  minimumSize: const Size(200, 80),
                ),
                child: isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(download.isEmpty
                        ? 'NO FILE TO DOWNLOAD'
                        : 'DOWNLOAD FILE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
