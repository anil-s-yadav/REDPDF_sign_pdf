import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/pdf_provider.dart';
import 'package:sign_pdf_redpdf/providers/signature_provider.dart';
import 'package:sign_pdf_redpdf/models/pdf_document_model.dart';
import 'package:sign_pdf_redpdf/models/signature_model.dart';
import 'package:share_plus/share_plus.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to delete all signed PDFs and signatures? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PdfProvider>(context, listen: false).clearAllSignedDocuments();
              Provider.of<SignatureProvider>(context, listen: false).clearAllSignatures();
              Navigator.pop(ctx);
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
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
                tabs: const [
                  Tab(text: "Signed Documents"),
                  Tab(text: "My Signatures"),
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
          const Text(
            "Files",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
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
            hintText: "Search your PDFs...",
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (val) {
            Provider.of<PdfProvider>(context, listen: false).setSearchQuery(val);
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
          return const Center(child: Text("No signed documents found."));
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
                Text("Signed on: $dateStr • $sizeKb KB",
                    style: TextStyle(color: pdfColor.light, fontSize: 12)),
              ],
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
                Provider.of<PdfProvider>(context, listen: false)
                    .removeSignedDocument(doc.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'open', child: Text('Open')),
              const PopupMenuItem(value: 'share', child: Text('Share')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          )
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
          return const Center(child: Text("No signatures found."));
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
                color: pdfColor.card,
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
    if ((sig.type == 'draw' || sig.type == 'image')  && sig.path != null) {
      final file = File(sig.path!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain, height: 80);
      }
    } else if (sig.type == 'text' && sig.text != null) {
      // If we saved text and font, just render text. 
      // But we can't reliably load GoogleFonts asynchronously in sync build, 
      // so let's fallback if font isn't loaded or simply display it.
      return FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            sig.text!,
            style: TextStyle(fontSize: 32, fontFamily: sig.font),
          ),
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
