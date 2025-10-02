import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'services/encryption_service.dart';

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
  Map<String, dynamic>? encryptionMetadata; // Store encryption metadata

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
                            final selectedFile = result.files.single;
                            Uint8List? fileBytes;

                            if (kIsWeb) {
                              if (selectedFile.bytes != null) {
                                fileBytes = selectedFile.bytes!;
                              } else {
                                throw Exception('File bytes are unavailable');
                              }
                            } else {
                              if (selectedFile.path != null) {
                                fileBytes = await selectedFile.xFile.readAsBytes();
                              } else {
                                throw Exception('File path is unavailable');
                              }
                            }

                            // Encrypt the file
                            _showSnack("Encrypting file...");
                            final encryptionResult = EncryptionService.encryptFile(fileBytes);
                            final encryptedBytes = Uint8List.fromList(encryptionResult['encryptedBytes']);
                            final originalHash = EncryptionService.generateFileHash(fileBytes);

                            // Store encryption metadata locally
                            encryptionMetadata = EncryptionService.createMetadata(
                              iv: encryptionResult['iv'],
                              key: encryptionResult['key'],
                              originalFilename: selectedFile.name,
                              fileHash: originalHash,
                              originalSize: fileBytes.length,
                            );

                            // Create encrypted filename
                            final encryptedFilename = '${selectedFile.name}.encrypted';
                            
                            var request = http.MultipartRequest(
                              'POST',
                              Uri.parse('${AppConfig.baseUrl}/upload'),
                            );

                            // Upload encrypted file
                            request.files.add(http.MultipartFile.fromBytes(
                              'file',
                              encryptedBytes,
                              filename: encryptedFilename,
                            ));

                            // Add encryption metadata as a separate field
                            request.fields['metadata'] = EncryptionService.serializeMetadata(encryptionMetadata!);

                            var response = await request.send();
                            final responseBody = await response.stream
                                .bytesToString(); // Always read body
                            if (!mounted) return;

                            if (response.statusCode == 200) {
                              setState(() {
                                download = _sanitizeResponseBody(responseBody);
                                uploadedFilename = encryptedFilename;
                                isUploading = false;
                              });
                              _showSnack("File encrypted and uploaded successfully");
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
                          
                          if (encryptionMetadata == null) {
                            _showSnack("No encryption metadata available", isError: true);
                            _setDownloading(false);
                            return;
                          }

                          // Get the presigned URL
                          final urlResponse = await http.get(
                            Uri.parse(
                                '${AppConfig.baseUrl}/download?filename=$uploadedFilename'),
                          );
                          if (!mounted) return;

                          if (urlResponse.statusCode == 200) {
                            final fileUrl = _sanitizeResponseBody(urlResponse.body);
                            
                            // Download the encrypted file
                            _showSnack("Downloading encrypted file...");
                            final fileResponse = await http.get(Uri.parse(fileUrl));
                            
                            if (fileResponse.statusCode == 200) {
                              // Decrypt the file
                              _showSnack("Decrypting file...");
                              final encryptedBytes = fileResponse.bodyBytes;
                              
                              final decryptedBytes = EncryptionService.decryptFile(
                                encryptedBytes,
                                encryptionMetadata!['iv'],
                                encryptionMetadata!['key'],
                              );

                              // Verify file integrity
                              final decryptedHash = EncryptionService.generateFileHash(decryptedBytes);
                              if (decryptedHash != encryptionMetadata!['fileHash']) {
                                throw Exception('File integrity check failed - file may be corrupted');
                              }

                              setState(() {
                                download = fileUrl;
                                isDownloading = false;
                              });
                              
                              _showSnack(
                                "File decrypted successfully! Original: ${encryptionMetadata!['originalFilename']}"
                              );
                            } else {
                              _setDownloading(false);
                              _showSnack(
                                "File download failed: ${fileResponse.statusCode}",
                                isError: true,
                              );
                            }
                          } else {
                            _setDownloading(false);
                            _showSnack(
                              "URL retrieval failed: ${urlResponse.statusCode}",
                              isError: true,
                            );
                          }
                        } catch (e) {
                          _setDownloading(false);
                          if (!mounted) return;
                          _showSnack(
                            "Error during download/decryption: $e",
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
