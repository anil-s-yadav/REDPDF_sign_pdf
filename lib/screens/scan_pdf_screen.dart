import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/pdf_provider.dart';
import 'package:sign_pdf_redpdf/models/pdf_document_model.dart';
import 'package:image/image.dart' as img; // if needed

class ScanPdfScreen extends StatefulWidget {
  const ScanPdfScreen({super.key});

  @override
  State<ScanPdfScreen> createState() => _ScanPdfScreenState();
}

class _ScanPdfScreenState extends State<ScanPdfScreen> {
  String? _scannedPdfPath;
  List<String> _scannedImagePaths = [];

  Future<void> _startScan() async {
    try {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          mode: ScannerMode.full,
          pageLimit: 20,
          isGalleryImport: true,
        ),
      );

      final result = await scanner.scanDocument();
      if (result.pdf != null) {
        final pdfPath = result.pdf!.uri;
        
        final prefs = await SharedPreferences.getInstance();
        String? customPath = prefs.getString('save_location');
        String dirPath = customPath ?? '/storage/emulated/0/Download/signpdf_refpdf';
        
        // Request Permissions
        if (Platform.isAndroid) {
          await Permission.storage.request();
          await Permission.manageExternalStorage.request();
        }

        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          try {
            await dir.create(recursive: true);
          } catch (e) {
            final fallback = await getApplicationDocumentsDirectory();
            dirPath = fallback.path;
          }
        }
        
        final newPath = '$dirPath/scanned_${DateTime.now().millisecondsSinceEpoch}.pdf';
        
        // ML Kit gives content:// or file:// URI, but we can treat it as a path mostly depending on OS
        final File original = File(pdfPath.replaceFirst('file://', ''));
        if (await original.exists()) {
          await original.copy(newPath);
          
          try {
            await MediaScanner.loadMedia(path: newPath);
          } catch(e) {
            // ignore
          }

          final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
          
          final doc = PdfDocumentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: "Scanned_Doc_${DateTime.now().millisecondsSinceEpoch}.pdf",
            path: newPath,
            sizeInBytes: await File(newPath).length(),
          );

          await pdfProvider.addSignedDocument(doc);

          setState(() {
            _scannedPdfPath = newPath;
            _scannedImagePaths = result.images != null ? result.images!.map((img) => img.replaceFirst('file://', '')).toList() : [];
          });
        }
      }
      scanner.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text("Scan to PDF"),
        actions: [
          if (_scannedPdfPath != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _scannedPdfPath = null;
                  _scannedImagePaths = [];
                });
              },
              child: Text("Clear", style: TextStyle(color: colors.primary)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_scannedImagePaths.isEmpty) ...[
                 Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const SizedBox(height: 100),
                       Icon(Icons.document_scanner, size: 80, color: colors.light),
                       const SizedBox(height: 16),
                       Text("Ready to scan your documents?", style: TextStyle(fontSize: 18, color: colors.text)),
                       const SizedBox(height: 32),
                       SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Start Scanner"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                     ],
                   )
                 )
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SCANNED PAGES (${_scannedImagePaths.length})",
                      style: TextStyle(color: colors.light),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("HQ Scan", style: TextStyle(color: colors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: _scannedImagePaths.length + 1,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      if (index == _scannedImagePaths.length) {
                        return GestureDetector(
                          onTap: _startScan,
                          child: _addCard(colors),
                        );
                      }
                      return _imageCard(colors, _scannedImagePaths[index], "Page ${index + 1}");
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Secondary Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/viewer', arguments: _scannedPdfPath);
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("View"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colors.card,
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Share.shareXFiles([XFile(_scannedPdfPath!)]);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text("Share"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colors.card,
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signpdf', arguments: _scannedPdfPath);
                        },
                        icon: const Icon(Icons.edit_document),
                        label: const Text("Sign"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageCard(AppColors colors, String path, String name) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(File(path), fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(name, style: TextStyle(fontSize: 12, color: colors.text)),
          ),
        ],
      ),
    );
  }

  Widget _addCard(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.primary, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
        color: colors.primary.withOpacity(0.05),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: colors.primary),
            const SizedBox(height: 6),
            Text("Add Pages", style: TextStyle(color: colors.primary)),
          ],
        ),
      ),
    );
  }
}

