import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

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
  bool isUploading = false; // Track upload state
  bool isDownloading = false; // Track download state

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
                  fontSize: 40, // Reduced for better responsiveness
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
                        setState(() {
                          isUploading = true;
                        });
                        final currentContext = context;
                        try {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: false,
                          );

                          if (result != null &&
                              result.files.single.path != null) {
                            var request = http.MultipartRequest(
                              'POST',
                              Uri.parse('http://127.0.0.1:8000/upload'),
                            );
                            request.files.add(
                              await http.MultipartFile.fromPath(
                                'file',
                                result.files.single.path!,
                              ),
                            );

                            var response = await request.send();
                            if (mounted && currentContext.mounted) {
                              if (response.statusCode == 200) {
                                final responseBody =
                                    await response.stream.bytesToString();
                                setState(() {
                                  download = responseBody.split('\n').first;
                                  uploadedFilename = result.files.single.name;
                                  isUploading = false;
                                });
                                ScaffoldMessenger.of(currentContext)
                                    .showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("File uploaded successfully")),
                                );
                              } else {
                                setState(() {
                                  isUploading = false;
                                });
                                ScaffoldMessenger.of(currentContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "File upload failed: ${response.statusCode}"),
                                  ),
                                );
                              }
                            }
                          } else {
                            setState(() {
                              isUploading = false;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            isUploading = false;
                          });
                          if (mounted && currentContext.mounted) {
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(
                                  content: Text("Error uploading file: $e")),
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
                onPressed: isDownloading
                    ? null
                    : () async {
                        setState(() {
                          isDownloading = true;
                        });
                        final currentContext = context;
                        try {
                          if (uploadedFilename == null ||
                              uploadedFilename!.isEmpty) {
                            if (mounted && currentContext.mounted) {
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                const SnackBar(
                                    content: Text("No file uploaded yet")),
                              );
                            }
                            setState(() {
                              isDownloading = false;
                            });
                            return;
                          }
                          final response = await http.get(
                            Uri.parse(
                                'http://127.0.0.1:8000/download?filename=$uploadedFilename'),
                          );
                          if (mounted && currentContext.mounted) {
                            if (response.statusCode == 200) {
                              setState(() {
                                download = response.body;
                                isDownloading = false;
                              });
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "File URL retrieved successfully")),
                              );
                            } else {
                              setState(() {
                                isDownloading = false;
                              });
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Download failed: ${response.statusCode}")),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() {
                            isDownloading = false;
                          });
                          if (mounted && currentContext.mounted) {
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Error retrieving file URL: $e")),
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
