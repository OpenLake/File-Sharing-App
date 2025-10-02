import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

// Configuration constants
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

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
  bool isUploading = false; // Track upload state
  bool isDownloading = false; // Track download state

  void _setUploading(bool value) {
    if (!mounted) return;
    setState(() {
      isUploading = value;
    });
  }

  void _setDownloading(bool value) {
    if (!mounted) return;
    setState(() {
      isDownloading = value;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _sanitizeResponseBody(String body) {
    final firstLine = body.split('\n').first;
    return firstLine.trim();
  }

  Future<void> share() async {
    await Share.share(
      download.isEmpty ? 'No file URL available' : 'Shared file URL: $download',
      subject: 'Shared File URL',
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
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        _setUploading(true);
                        try {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: false,
                          );

                          if (!mounted) return;

                          if (result != null && result.files.isNotEmpty) {
                            var request = http.MultipartRequest(
                              'POST',
                              Uri.parse('${AppConfig.baseUrl}/upload'),
                            );

                            final selectedFile = result.files.single;

                            if (kIsWeb) {
                              // On web, use bytes instead of path
                              if (selectedFile.bytes != null) {
                                request.files.add(http.MultipartFile.fromBytes(
                                  'file',
                                  selectedFile.bytes!,
                                  filename: selectedFile.name,
                                ));
                                uploadedFilename = selectedFile.name;
                              } else {
                                throw Exception('File bytes are unavailable');
                              }
                            } else {
                              // On other platforms, use path
                              if (selectedFile.path != null) {
                                request.files.add(
                                  await http.MultipartFile.fromPath(
                                    'file',
                                    selectedFile.path!,
                                  ),
                                );
                                uploadedFilename = selectedFile.name;
                              } else {
                                throw Exception('File path is unavailable');
                              }
                            }

                            var response = await request.send();
                            final responseBody = await response.stream
                                .bytesToString(); // Always read body
                            if (!mounted) return;

                            if (response.statusCode == 200) {
                              setState(() {
                                download = _sanitizeResponseBody(responseBody);
                                isUploading = false;
                              });
                              _showSnack("File uploaded successfully");
                            } else {
                              _setUploading(false);
                              _showSnack(
                                "File upload failed: ${response.statusCode} - $responseBody",
                                isError: true,
                              );
                            }
                          } else {
                            uploadedFilename = null;
                            _setUploading(false);
                          }
                        } catch (e) {
                          _setUploading(false);
                          if (!mounted) return;
                          _showSnack("Error uploading file: $e", isError: true);
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
                    : const Text('UPLOAD FILE'),
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
                      if (download.trim().isEmpty) {
                        _showSnack("No text to copy", isError: true);
                      } else {
                        await Clipboard.setData(ClipboardData(text: download));
                        if (!mounted) return;
                        _showSnack("Text copied");
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
                onPressed: isDownloading
                    ? null
                    : () async {
                        _setDownloading(true);
                        try {
                          if (uploadedFilename == null ||
                              uploadedFilename!.isEmpty) {
                            _showSnack("No file uploaded yet", isError: true);
                            _setDownloading(false);
                            return;
                          }
                          final response = await http.get(
                            Uri.parse(
                                '${AppConfig.baseUrl}/download?filename=$uploadedFilename'),
                          );
                          if (!mounted) return;

                          if (response.statusCode == 200) {
                            setState(() {
                              download = _sanitizeResponseBody(response.body);
                              isDownloading = false;
                            });
                            _showSnack("File URL retrieved successfully");
                          } else {
                            _setDownloading(false);
                            _showSnack(
                              "Download failed: ${response.statusCode}",
                              isError: true,
                            );
                          }
                        } catch (e) {
                          _setDownloading(false);
                          if (!mounted) return;
                          _showSnack(
                            "Error retrieving file URL: $e",
                            isError: true,
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
                    : const Text('DOWNLOAD FILE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
