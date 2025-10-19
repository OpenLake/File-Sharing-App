import 'dart:async';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesharing/app_config.dart';
import 'package:filesharing/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class MyHomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;

  const MyHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String download = "";
  String? uploadedFilename;
  bool isUploading = false; // Track upload state
  bool isDownloading = false; // Track download state
  Map<String, dynamic>? encryptionMetadata; // Store encryption metadata
  String selectedPage = '';
  late DropzoneViewController controller;
  bool zoneHighlighted = false;

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
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
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

  /// Handles the core logic of encrypting and uploading the file.
  Future<void> _uploadFile(String filename, Uint8List fileBytes) async {
    _setUploading(true);
    try {
      if (!mounted) return;
      _showSnack("Encrypting file...");
      final encryptionResult = EncryptionService.encryptFile(fileBytes);
      final encryptedBytes = Uint8List.fromList(
        encryptionResult['encryptedBytes'],
      );
      final originalHash = EncryptionService.generateFileHash(fileBytes);

      encryptionMetadata = EncryptionService.createMetadata(
        iv: encryptionResult['iv'],
        key: encryptionResult['key'],
        originalFilename: filename,
        fileHash: originalHash,
        originalSize: fileBytes.length,
      );

      final encryptedFilename = '$filename.encrypted';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          encryptedBytes,
          filename: encryptedFilename,
        ),
      );

      request.fields['metadata'] = EncryptionService.serializeMetadata(
        encryptionMetadata!,
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          download = _sanitizeResponseBody(responseBody);
          uploadedFilename = encryptedFilename;
        });
        _showSnack("File encrypted and uploaded successfully");
      } else {
        _showSnack(
          "File upload failed: ${response.statusCode} - $responseBody",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error uploading file: $e", isError: true);
    } finally {
      _setUploading(false);
    }
  }

  /// Opens the file picker and triggers the upload process.
  Future<Null> Function()? selectFile() {
    return isUploading
        ? null
        : () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.any,
                allowMultiple: false,
              );

              if (!mounted || result == null || result.files.isEmpty) return;

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

              await _uploadFile(selectedFile.name, fileBytes);
            } catch (e) {
              if (!mounted) return;
              _showSnack("Error selecting file: $e", isError: true);
            }
          };
  }

  Future<Null> Function()? downloadFile() {
    return isDownloading
        ? null
        : () async {
            _setDownloading(true);
            try {
              if (uploadedFilename == null || uploadedFilename!.isEmpty) {
                _showSnack("No file uploaded yet", isError: true);
                _setDownloading(false);
                return;
              }

              if (encryptionMetadata == null) {
                _showSnack("No encryption metadata available", isError: true);
                _setDownloading(false);
                return;
              }

              final urlResponse = await http.get(
                Uri.parse(
                  '${AppConfig.baseUrl}/download?filename=$uploadedFilename',
                ),
              );
              if (!mounted) return;

              if (urlResponse.statusCode == 200) {
                final fileUrl = _sanitizeResponseBody(urlResponse.body);

                _showSnack("Downloading encrypted file...");
                final fileResponse = await http.get(Uri.parse(fileUrl));

                if (fileResponse.statusCode == 200) {
                  _showSnack("Decrypting file...");
                  final encryptedBytes = fileResponse.bodyBytes;

                  final decryptedBytes = EncryptionService.decryptFile(
                    encryptedBytes,
                    encryptionMetadata!['iv'],
                    encryptionMetadata!['key'],
                  );

                  final decryptedHash = EncryptionService.generateFileHash(
                    decryptedBytes,
                  );
                  if (decryptedHash != encryptionMetadata!['fileHash']) {
                    throw Exception(
                      'File integrity check failed - file may be corrupted',
                    );
                  }

                  setState(() {
                    download = fileUrl;
                    isDownloading = false;
                  });

                  _showSnack(
                    "File decrypted successfully! Original: ${encryptionMetadata!['originalFilename']}",
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
              _showSnack("Error during download/decryption: $e", isError: true);
            }
          };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      drawer: drawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 250,
                        // Conditionally build the entire UI based on platform
                        child: kIsWeb
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  dropzone(context),
                                  DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      strokeCap: StrokeCap.round,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.purple,
                                          Colors.indigo,
                                        ],
                                      ),
                                      strokeWidth: zoneHighlighted ? 3 : 2,
                                      radius: const Radius.circular(16.0),
                                      dashPattern: zoneHighlighted
                                          ? const [6, 9]
                                          : const [9, 6],
                                    ),
                                    child: uploadButton(context),
                                  ),
                                ],
                              )
                            : Center(child: uploadButton(context)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 250,
                        child: Stack(
                          children: [Center(child: downloadButton(context))],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                textArea(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget textArea(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final textStyle = TextStyle(
      fontSize: 14,
      color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
    );

    final labelStyle = textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurface.withAlpha(180),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text("Sharable Link", style: labelStyle),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline, width: 1.0),
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    download,
                    style: textStyle,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.copy, size: 24),
                    tooltip: "Copy Link",
                    color: colorScheme.primary,
                    onPressed: () async {
                      if (download.trim().isEmpty) {
                        _showSnack("No text to copy", isError: true);
                      } else {
                        await Clipboard.setData(ClipboardData(text: download));
                        if (!mounted) return;
                        _showSnack("Link copied to clipboard");
                      }
                    },
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.share, size: 24),
                    tooltip: "Share Link",
                    color: colorScheme.primary,
                    onPressed: share,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget uploadButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      shadowColor: colorScheme.primary.withAlpha(100),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        child: InkWell(
          onTap: selectFile(),
          child: Container(
            height: 250,
            width: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: zoneHighlighted
                    ? [colorScheme.secondaryContainer, colorScheme.secondary]
                    : [colorScheme.secondary, colorScheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: isUploading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_rounded,
                        size: 50,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Upload',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'or drag n drop',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget downloadButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      shadowColor: colorScheme.primary.withAlpha(100),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        child: InkWell(
          onTap: downloadFile(),
          child: Container(
            height: 250,
            width: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.secondary, colorScheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: isDownloading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 50,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Download',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Drawer drawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      child: Theme(
        data: theme.copyWith(
          listTileTheme: ListTileThemeData(
            iconColor: colorScheme.primary,
            textColor: colorScheme.onSurface,
            titleTextStyle: textTheme.titleMedium,
          ),
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: colorScheme.primary,
            collapsedIconColor: colorScheme.onSurface.withAlpha(
              (0.7 * 256).toInt(),
            ),
            textColor: colorScheme.primary,
            collapsedTextColor: colorScheme.onSurface,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primaryContainer),
              child: Text(
                'FILE SHARING APP',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const ExpansionTile(
              leading: Icon(Icons.library_books),
              title: Text('Recent File Shares'),
              childrenPadding: EdgeInsets.only(left: 40),
              children: [],
            ),
            ExpansionTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Account'),
              childrenPadding: const EdgeInsets.only(left: 40),
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('View/Edit Profile'),
                  onTap: () {
                    setState(() {
                      selectedPage = 'view-edit-profile';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 180,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      title: const Text('File Share'),
      titleTextStyle: theme.textTheme.displayMedium?.copyWith(
        color: colorScheme.onPrimary,
      ),
      centerTitle: false,
      actionsIconTheme: IconThemeData(color: colorScheme.onPrimary),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      actions: [
        IconButton(
          icon: Icon(
            widget.themeMode == ThemeMode.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
          ),
          onPressed: widget.onThemeChanged,
          tooltip: 'Toggle Theme',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget dropzone(BuildContext context) => Builder(
        builder: (context) => DropzoneView(
          operation: DragOperation.copy,
          cursor: CursorType.grab,
          onCreated: (ctrl) => controller = ctrl,
          onError: (error) => debugPrint('Zone 1 error: $error'),
          onHover: () {
            setState(() => zoneHighlighted = true);
          },
          onLeave: () {
            setState(() => zoneHighlighted = false);
          },
          onDropFile: (DropzoneFileInterface file) async {
            setState(() {
              zoneHighlighted = false;
            });
            if (isUploading) {
              _showSnack("An upload is already in progress.", isError: true);
              return;
            }
            final bytes = await controller.getFileData(file);
            await _uploadFile(file.name, bytes);
          },
        ),
      );
}
