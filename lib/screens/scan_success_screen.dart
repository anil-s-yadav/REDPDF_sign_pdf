import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';

class ScanSuccessScreen extends StatelessWidget {
  const ScanSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We expect the path of the newly scanned PDF to be passed as arguments
    final String? pdfPath = ModalRoute.of(context)?.settings.arguments as String?;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text("Scan Complete"),
        automaticallyImplyLeading: false, // Don't show back arrow usually on success
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colors.text),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Graphic
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                "Successfully Scanned!",
                style: TextStyle(
                  color: colors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your document has been scanned and converted into a PDF securely on your device.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.light,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Preview File Component
              if (pdfPath != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/viewer', arguments: pdfPath);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: colors.primary, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pdfPath.split(Platform.pathSeparator).last,
                                style: TextStyle(
                                  color: colors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap to open preview",
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new, color: colors.light, size: 20),
                      ],
                    ),
                  ),
                ),

              const Spacer(),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (pdfPath != null) {
                          Share.shareXFiles([XFile(pdfPath)]);
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colors.card,
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (pdfPath != null) {
                          Navigator.pushNamed(context, '/signpdf', arguments: pdfPath);
                        }
                      },
                      icon: const Icon(Icons.edit_document),
                      label: const Text("Sign Now"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
