import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/pdf_provider.dart';
import 'package:sign_pdf_redpdf/models/pdf_document_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../l10n/app_localizations.dart';
import '../utils/download_helper.dart';

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
      if (result.images != null && result.images!.isNotEmpty) {
        // Show loading while creating PDF
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CircularProgressIndicator(),
              ),
            ),
          );
        }

        final pdf = pw.Document();
        for (final imagePath in result.images!) {
          final file = File(imagePath.replaceFirst('file://', ''));
          if (await file.exists()) {
            final image = pw.MemoryImage(await file.readAsBytes());
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  );
                },
              ),
            );
          }
        }

        final prefs = await SharedPreferences.getInstance();
        final customPath = prefs.getString('save_location');
        final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final pdfBytes = await pdf.save();

        String newPath;
        if (customPath != null) {
          // User selected custom path — write directly
          final dir = Directory(customPath);
          if (!await dir.exists()) await dir.create(recursive: true);
          newPath = '$customPath/$fileName';
          await File(newPath).writeAsBytes(pdfBytes, flush: true);
        } else {
          // Default: save to Downloads/RedPdf_sign via MediaStore (no permissions needed)
          newPath = await DownloadHelper.savePdfToDownloads(
            bytes: Uint8List.fromList(pdfBytes),
            fileName: fileName,
          );
        }

        try {
          await MediaScanner.loadMedia(path: newPath);
        } catch (e) {}

        final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
        final doc = PdfDocumentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Scanned_${DateTime.now().millisecondsSinceEpoch}.pdf",
          path: newPath,
          sizeInBytes: pdfBytes.length,
        );

        await pdfProvider.addSignedDocument(doc);

        if (mounted) {
          Navigator.pop(context); // Remove loading
          Navigator.pushNamed(context, '/scan_success', arguments: newPath);
        }
      }
      scanner.close();
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: Text(AppLocalizations.of(context)!.translate('scan_pdf')),
        actions: [
          if (_scannedPdfPath != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _scannedPdfPath = null;
                  _scannedImagePaths = [];
                });
              },
              child: Text(
                AppLocalizations.of(context)!.translate('clear'),
                style: TextStyle(color: colors.primary),
              ),
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
                      Icon(
                        Icons.document_scanner,
                        size: 80,
                        color: colors.light,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.translate('ready_to_scan'),
                        style: TextStyle(fontSize: 18, color: colors.text),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('start_scanner'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.translate('scanned_pages').toUpperCase()} (${_scannedImagePaths.length})",
                      style: TextStyle(color: colors.light),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "HQ Scan",
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: _scannedImagePaths.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      return _imageCard(
                        colors,
                        _scannedImagePaths[index],
                        "Page ${index + 1}",
                      );
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
                          Navigator.pushNamed(
                            context,
                            '/viewer',
                            arguments: _scannedPdfPath,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(
                          AppLocalizations.of(context)!.translate('preview'),
                        ),
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
                        label: Text(
                          AppLocalizations.of(context)!.translate('share'),
                        ),
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
                          Navigator.pushNamed(
                            context,
                            '/signpdf',
                            arguments: _scannedPdfPath,
                          );
                        },
                        icon: const Icon(Icons.edit_document),
                        label: Text(
                          AppLocalizations.of(context)!.translate('sign_pdf'),
                        ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              name,
              style: TextStyle(fontSize: 12, color: colors.text),
            ),
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
            Text(
              AppLocalizations.of(context)!.translate('add_pages'),
              style: TextStyle(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
