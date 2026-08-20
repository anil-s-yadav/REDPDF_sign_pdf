import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class SignSuccessScreen extends StatelessWidget {
  const SignSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? pdfPath =
        ModalRoute.of(context)?.settings.arguments as String?;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('sign_complete')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colors.text),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 5.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // const SizedBox(height: 16),
                    // Success Graphic with Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.2),
                                  blurRadius: 20 * value,
                                  spreadRadius: 5 * value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.verified,
                              color: colors.primary,
                              size: 80 * value,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('sign_success_msg'),
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.translate('sign_body_msg'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.light,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Preview File Component
                    if (pdfPath != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/viewer',
                            arguments: pdfPath,
                          );
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
                              Icon(
                                Icons.picture_as_pdf,
                                color: colors.primary,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pdfPath
                                          .split(Platform.pathSeparator)
                                          .last,
                                      style: TextStyle(
                                        color: colors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('tap_to_preview'),
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: colors.light,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Banner Ad Placeholder Space
            // Container(
            //   height: 80, // Standard Mobile Banner height
            //   width: 320, // Standard Mobile Banner width
            //   decoration: BoxDecoration(
            //     color: colors.card,
            //     border: Border.all(color: colors.border, width: 1),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   alignment: Alignment.center,
            //   child: Text(
            //     'Banner Ad Space',
            //     style: TextStyle(
            //       color: colors.light,
            //       fontSize: 12,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),

            // Bottom Fixed Section (Actions + Ad)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Action: Share
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (pdfPath != null) {
                          Share.shareXFiles([XFile(pdfPath)]);
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: Text(
                        AppLocalizations.of(context)!.translate('share_file'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Close Action
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      },
                      child: Text(
                        AppLocalizations.of(context)!.translate('done'),
                        style: TextStyle(
                          color: colors.light,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
