import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/signature_provider.dart';
import 'package:sign_pdf_redpdf/providers/pdf_provider.dart';
import 'package:sign_pdf_redpdf/models/signature_model.dart';
import 'package:sign_pdf_redpdf/models/pdf_document_model.dart';

class SignPdfScreen extends StatefulWidget {
  const SignPdfScreen({super.key});

  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class _SignPdfScreenState extends State<SignPdfScreen> {
  Offset _signaturePosition = const Offset(100, 200);
  SignatureModel? _selectedSignature;
  String? _pdfPath;
  double _zoomLevel = 1.0;
  double _signatureScale = 1.0;
  double _baseScale = 1.0;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pdfPath == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is String) {
        _pdfPath = args;
      }
    }
  }

  void _showSignaturePicker() {
    final sigProvider = Provider.of<SignatureProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Signature", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Create"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/createsign');
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: sigProvider.signatures.isEmpty
                    ? const Center(child: Text("No signatures yet."))
                    : GridView.builder(
                        itemCount: sigProvider.signatures.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                        ),
                        itemBuilder: (ctx, index) {
                          final sig = sigProvider.signatures[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSignature = sig;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _buildSignaturePreview(sig),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignaturePreview(SignatureModel sig) {
    if ((sig.type == 'draw' || sig.type == 'image')  && sig.path != null) {
      final file = File(sig.path!);
      if (file.existsSync()) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.file(file, fit: BoxFit.contain),
        );
      }
    } else if (sig.type == 'text' && sig.text != null) {
      return Center(
        child: Text(
          sig.text!,
          style: TextStyle(fontSize: 24, fontFamily: sig.font),
        ),
      );
    }
    return const Icon(Icons.error);
  }

  void _addTextPrompt() {
    TextEditingController textController = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text("Enter Text"),
        content: TextField(controller: textController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () {
            if (textController.text.isNotEmpty) {
              setState(() {
                _selectedSignature = SignatureModel(
                  id: 'temp_text',
                  type: 'text',
                  text: textController.text,
                  font: 'Roboto',
                );
              });
            }
            Navigator.pop(ctx);
          }, child: const Text("Add")),
        ]
      );
    });
  }

  void _addDate() {
    final String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _selectedSignature = SignatureModel(
        id: 'temp_date',
        type: 'text',
        text: dateStr,
        font: 'Roboto',
      );
    });
  }

  void _addInitialsPrompt() {
    TextEditingController textController = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text("Enter Initials"),
        content: TextField(controller: textController, autofocus: true, maxLength: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () {
            if (textController.text.isNotEmpty) {
              setState(() {
                _selectedSignature = SignatureModel(
                  id: 'temp_initials',
                  type: 'text',
                  text: textController.text,
                  font: 'Roboto',
                );
              });
            }
            Navigator.pop(ctx);
          }, child: const Text("Add")),
        ]
      );
    });
  }

  Future<void> _saveSignedPdf() async {
    if (_pdfPath == null) return;

    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('save_location');
    String dirPath = customPath ?? '/storage/emulated/0/Download/signpdf_refpdf';
    
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
    
    final newPath = '$dirPath/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    try {
      final File original = File(_pdfPath!);
      
      // Real PDF modification
      final PdfDocument document = PdfDocument(inputBytes: await original.readAsBytes());
      if (document.pages.count > 0 && _selectedSignature != null) {
        int pageIndex = _pdfViewerController.pageNumber - 1;
        if (pageIndex < 0 || pageIndex >= document.pages.count) pageIndex = 0;
        final PdfPage page = document.pages[pageIndex];
        
        // Approximating screen offset to PDF page
        double x = _signaturePosition.dx * 1.5;
        double y = _signaturePosition.dy * 1.5;
        
        if ((_selectedSignature!.type == 'draw' || _selectedSignature!.type == 'image') && _selectedSignature!.path != null) {
            final File imgFile = File(_selectedSignature!.path!);
            if (await imgFile.exists()) {
               final PdfBitmap image = PdfBitmap(await imgFile.readAsBytes());
               // Apply scale to dimensions
               page.graphics.drawImage(image, Rect.fromLTWH(x, y, 150 * _signatureScale, 80 * _signatureScale));
            }
        } else if (_selectedSignature!.type == 'text' && _selectedSignature!.text != null) {
            final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 24 * _signatureScale);
            page.graphics.drawString(
              _selectedSignature!.text!, 
              font, 
              brush: PdfSolidBrush(PdfColor(0, 0, 0)),
              bounds: Rect.fromLTWH(x, y, 300 * _signatureScale, 100 * _signatureScale),
            );
        }
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      await File(newPath).writeAsBytes(bytes, flush: true);
      
      // Refresh android indexing
      try {
        await MediaScanner.loadMedia(path: newPath);
      } catch (e) {
        // scanner error ignored
      }

      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      final doc = PdfDocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Signed_${original.uri.pathSegments.last}",
        path: newPath,
        sizeInBytes: await File(newPath).length(),
      );

      await pdfProvider.addSignedDocument(doc);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved Successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    final fileName = _pdfPath != null ? _pdfPath!.split(Platform.pathSeparator).last : 'No File';

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: TextStyle(color: colors.text, fontSize: 16)),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 📄 PDF Viewer
            if (_pdfPath != null)
              Container(
                margin: const EdgeInsets.only(bottom: 100), // space for bottom panel
                child: SfPdfViewer.file(
                  File(_pdfPath!),
                  controller: _pdfViewerController,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                  onZoomLevelChanged: (details) {
                    _zoomLevel = details.newZoomLevel;
                  },
                ),
              )
            else
              const Center(child: Text("No PDF Selected")),

            // ✍️ Draggable Signature Box
            if (_selectedSignature != null)
              Positioned(
                left: _signaturePosition.dx,
                top: _signaturePosition.dy,
                child: GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = _signatureScale;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _signaturePosition += details.focalPointDelta;
                      if (details.scale != 1.0) {
                        _signatureScale = _baseScale * details.scale;
                      }
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid),
                        ),
                        child: SizedBox(
                          width: 150 * _signatureScale,
                          height: 80 * _signatureScale,
                          child: Transform.scale(
                            scale: 1.0, // inner scale handles the box, widget stretches to fill box
                            child: _buildSignaturePreview(_selectedSignature!),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -15,
                        top: -15,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSignature = null;
                            });
                          },
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            // 🔻 Bottom Section
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedSignature != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.photo_size_select_small, color: colors.primary),
                          Expanded(
                            child: Slider(
                              value: _signatureScale,
                              min: 0.5,
                              max: 3.0,
                              onChanged: (val) {
                                setState(() {
                                  _signatureScale = val;
                                  _baseScale = val;
                                });
                              },
                            ),
                          ),
                          Icon(Icons.photo_size_select_large, color: colors.primary),
                        ],
                      ),
                    ),
                  _bottomPanel(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔻 Bottom Panel
  Widget _bottomPanel(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _showSignaturePicker,
                  child: _toolItem("SIGN", Icons.edit, colors, selected: true),
                ),
                GestureDetector(
                  onTap: _addTextPrompt,
                  child: _toolItem("TEXT", Icons.text_fields, colors),
                ),
                GestureDetector(
                  onTap: _addDate,
                  child: _toolItem("DATE", Icons.calendar_today, colors),
                ),
                GestureDetector(
                  onTap: _addInitialsPrompt,
                  child: _toolItem("INITIALS", Icons.person, colors),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Buttons Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.card,
                      foregroundColor: colors.text,
                      side: BorderSide(color: colors.border),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _saveSignedPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Save Signed PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolItem(String text, IconData icon, AppColors colors, {bool selected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? colors.primary : colors.text),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(color: selected ? colors.primary : colors.text, fontSize: 12),
        ),
      ],
    );
  }
}

