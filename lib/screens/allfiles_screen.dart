import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/pdf_provider.dart';
import 'package:sign_pdf_redpdf/providers/signature_provider.dart';
import 'package:sign_pdf_redpdf/models/pdf_document_model.dart';
import 'package:sign_pdf_redpdf/models/signature_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class FilesScreen extends StatefulWidget {
  final int initialTabIndex;
  const FilesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('clear_history')),
        content: Text(
          AppLocalizations.of(context)!.translate('clear_history_msg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PdfProvider>(
                context,
                listen: false,
              ).clearAllSignedDocuments();
              Provider.of<SignatureProvider>(
                context,
                listen: false,
              ).clearAllSignatures();
              Navigator.pop(ctx);
            },
            child: Text(
              AppLocalizations.of(context)!.translate('delete_all'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pdfColor = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: pdfColor.bg,
      body: DefaultTabController(
        length: 2,
        initialIndex: widget.initialTabIndex,
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              _searchBar(pdfColor),
              TabBar(
                isScrollable: false,
                labelColor: pdfColor.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: pdfColor.primary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    text: AppLocalizations.of(
                      context,
                    )!.translate('signed_documents'),
                  ),
                  Tab(
                    text: AppLocalizations.of(
                      context,
                    )!.translate('my_signatures'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildDocumentsTab(pdfColor),
                    _buildSignaturesTab(pdfColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('all_files'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(
                  AppLocalizations.of(context)!.translate('clear_history'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar(AppColors pdfColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: pdfColor.card,
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate('search_pdfs'),
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (val) {
            Provider.of<PdfProvider>(
              context,
              listen: false,
            ).setSearchQuery(val);
          },
        ),
      ),
    );
  }

  Widget _buildDocumentsTab(AppColors pdfColor) {
    return Consumer<PdfProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.signedDocuments.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.translate('no_files')),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: provider.signedDocuments.length,
          itemBuilder: (context, index) {
            final doc = provider.signedDocuments[index];
            return _fileCard(doc, pdfColor);
          },
        );
      },
    );
  }

  Widget _fileCard(PdfDocumentModel doc, AppColors pdfColor) {
    final dateStr = doc.createdAt.toIso8601String().split('T')[0];
    final sizeKb = (doc.sizeInBytes / 1024).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pdfColor.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: pdfColor.primary.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          _pdfIcon(pdfColor),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/viewer', arguments: doc.path),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: pdfColor.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Signed on: $dateStr • $sizeKb KB",
                    style: TextStyle(color: pdfColor.light, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: pdfColor.light),
            onSelected: (action) async {
              if (action == 'open') {
                Navigator.pushNamed(context, '/viewer', arguments: doc.path);
              } else if (action == 'share') {
                await Share.shareXFiles([XFile(doc.path)]);
              } else if (action == 'delete') {
                Provider.of<PdfProvider>(
                  context,
                  listen: false,
                ).removeSignedDocument(doc.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'open',
                child: Text(AppLocalizations.of(context)!.translate('open')),
              ),
              PopupMenuItem(
                value: 'share',
                child: Text(AppLocalizations.of(context)!.translate('share')),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(AppLocalizations.of(context)!.translate('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesTab(AppColors pdfColor) {
    return Consumer<SignatureProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.signatures.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.translate('no_files')),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: provider.signatures.length,
          itemBuilder: (context, index) {
            final sig = provider.signatures[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: pdfColor.border),
              ),
              child: Stack(
                children: [
                  Center(child: _buildSignaturePreview(sig)),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        provider.removeSignature(sig.id);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSignaturePreview(SignatureModel sig) {
    if ((sig.type == 'draw' || sig.type == 'image') && sig.path != null) {
      final file = File(sig.path!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain, height: 80);
      }
    } else if (sig.type == 'text' && sig.text != null) {
      TextStyle safeStyle;
      try {
        safeStyle = sig.font != null
            ? GoogleFonts.getFont(
                sig.font!,
                textStyle: TextStyle(
                  fontSize: 32,
                  color: sig.color != null ? Color(sig.color!) : Colors.black,
                ),
              )
            : TextStyle(
                fontSize: 32,
                color: sig.color != null ? Color(sig.color!) : Colors.black,
              );
      } catch (e) {
        // Fallback to standard font if Google Font fails to load
        safeStyle = TextStyle(
          fontSize: 32,
          color: sig.color != null ? Color(sig.color!) : Colors.black,
        );
      }

      return FittedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(sig.text!, style: safeStyle),
        ),
      );
    }
    return const Icon(Icons.error);
  }

  Widget _pdfIcon(AppColors pdfColor) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: pdfColor.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.picture_as_pdf, color: pdfColor.primary),
    );
  }
}
