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
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class SignPdfScreen extends StatefulWidget {
  const SignPdfScreen({super.key});

  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class SignatureInstance {
  final String id;
  final SignatureModel signature;
  // Position in document-space coordinates (at zoom=1, relative to document origin)
  Offset docPosition;
  double scale;
  int pageIndex;
  // The scroll offset when the signature was placed — used to compute page-relative position for PDF save
  Offset placementScrollOffset;
  double placementZoom;

  SignatureInstance({
    required this.id,
    required this.signature,
    required this.docPosition,
    required this.pageIndex,
    required this.placementScrollOffset,
    required this.placementZoom,
    this.scale = 1.0,
  });
}

class _SignPdfScreenState extends State<SignPdfScreen> {
  final List<SignatureInstance> _addedSignatures = [];
  String? _pdfPath;
  double zoomLevel = 1.0;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPageIndex = 0;
  String? _selectedSignatureId;
  Offset _scrollOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onViewerChanged);
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_onViewerChanged);
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _onViewerChanged() {
    final newOffset = _pdfViewerController.scrollOffset;
    final newZoom = _pdfViewerController.zoomLevel;
    if (newOffset != _scrollOffset || newZoom != zoomLevel) {
      setState(() {
        _scrollOffset = newOffset;
        zoomLevel = newZoom;
      });
    }
  }

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
                  Text(
                    AppLocalizations.of(context)!.translate('choose_signature'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(
                      AppLocalizations.of(context)!.translate('create'),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/createsign');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: sigProvider.signatures.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('no_signatures'),
                        ),
                      )
                    : GridView.builder(
                        itemCount: sigProvider.signatures.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.5,
                            ),
                        itemBuilder: (ctx, index) {
                          final sig = sigProvider.signatures[index];
                          return GestureDetector(
                            onTap: () {
                              _addSignature(sig);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                // Fix #4: Always white bg so dark signatures are visible
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _buildSignaturePreview(sig),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addSignature(SignatureModel sig) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    // Store position in document-space coordinates (zoom=1 reference)
    final docPos = Offset(
      (100 + _scrollOffset.dx) / zoomLevel,
      (200 + _scrollOffset.dy) / zoomLevel,
    );
    setState(() {
      _addedSignatures.add(
        SignatureInstance(
          id: newId,
          signature: sig,
          docPosition: docPos,
          pageIndex: _pdfViewerController.pageNumber - 1,
          placementScrollOffset: _scrollOffset,
          placementZoom: zoomLevel,
        ),
      );
      _selectedSignatureId = newId;
    });
  }

  /// Builds signature preview widget.
  /// [scale] controls text font scaling for the on-PDF overlay.
  /// [forPdfOverlay] when true, forces black text for visibility on white PDF pages.
  Widget _buildSignaturePreview(
    SignatureModel sig, {
    double scale = 1.0,
    bool forPdfOverlay = false,
  }) {
    if ((sig.type == 'draw' || sig.type == 'image') && sig.path != null) {
      final file = File(sig.path!);
      if (file.existsSync()) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.file(file, fit: BoxFit.contain),
        );
      }
    } else if (sig.type == 'text' && sig.text != null) {
      // Fix #2: Scale font size with the instance scale
      final double fontSize = 24 * scale;
      // Fix #3: Force black color for text on PDF overlay (PDF pages are white)
      final Color textColor = forPdfOverlay
          ? Colors.black
          : (sig.color != null ? Color(sig.color!) : Colors.black);

      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            sig.text!,
            style: sig.font != null
                ? GoogleFonts.getFont(
                    sig.font!,
                    textStyle: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                    ),
                  )
                : TextStyle(
                    fontSize: fontSize,
                    color: textColor,
                  ),
          ),
        ),
      );
    }
    return const Icon(Icons.error);
  }

  void _addTextPrompt() {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('enter_text')),
          content: TextField(controller: textController, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _addSignature(
                    SignatureModel(
                      id: 'temp_text_${DateTime.now().millisecondsSinceEpoch}',
                      type: 'text',
                      text: textController.text,
                      font: 'Roboto',
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context)!.translate('add')),
            ),
          ],
        );
      },
    );
  }

  void _addDate() {
    final String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _addSignature(
      SignatureModel(
        id: 'temp_date_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        text: dateStr,
        font: 'Roboto',
      ),
    );
  }

  void _addInitialsPrompt() {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.translate('enter_initials'),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLength: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _addSignature(
                    SignatureModel(
                      id: 'temp_initials_${DateTime.now().millisecondsSinceEpoch}',
                      type: 'text',
                      text: textController.text,
                      font: 'Roboto',
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context)!.translate('add')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSignedPdf() async {
    if (_pdfPath == null) return;

    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('save_location');
    String dirPath =
        customPath ?? '/storage/emulated/0/Download/signpdf_refpdf';

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

    final newPath =
        '$dirPath/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      final File original = File(_pdfPath!);

      // Real PDF modification
      final PdfDocument document = PdfDocument(
        inputBytes: await original.readAsBytes(),
      );

      for (var instance in _addedSignatures) {
        if (instance.pageIndex >= 0 &&
            instance.pageIndex < document.pages.count) {
          final PdfPage page = document.pages[instance.pageIndex];
          final sig = instance.signature;

          // Compute page-relative screen position from document coordinates
          // docPosition was stored as (screenPos + scrollOffset) / zoom at placement time
          // To get the original screen position: docPosition * placementZoom - placementScrollOffset
          final screenPos = Offset(
            instance.docPosition.dx * instance.placementZoom -
                instance.placementScrollOffset.dx,
            instance.docPosition.dy * instance.placementZoom -
                instance.placementScrollOffset.dy,
          );

          // Approximating screen offset to PDF page
          double x = screenPos.dx * 1.5;
          double y = screenPos.dy * 1.5;

          if ((sig.type == 'draw' || sig.type == 'image') && sig.path != null) {
            final File imgFile = File(sig.path!);
            if (await imgFile.exists()) {
              final PdfBitmap image = PdfBitmap(await imgFile.readAsBytes());
              page.graphics.drawImage(
                image,
                Rect.fromLTWH(x, y, 150 * instance.scale, 80 * instance.scale),
              );
            }
          } else if (sig.type == 'text' && sig.text != null) {
            // Mapping common signature-like fonts to PDF standards or using Italic
            PdfFontFamily fontFamily = PdfFontFamily.helvetica;
            PdfFontStyle fontStyle = PdfFontStyle.regular;

            if (sig.font != null) {
              final fontLower = sig.font!.toLowerCase();
              if (fontLower.contains('script') ||
                  fontLower.contains('hand') ||
                  fontLower.contains('brush')) {
                fontFamily = PdfFontFamily.timesRoman;
                fontStyle = PdfFontStyle.italic;
              }
            }

            final PdfFont font = PdfStandardFont(
              fontFamily,
              24 * instance.scale,
              style: fontStyle,
            );

            // Handle color
            PdfColor pdfColor = PdfColor(0, 0, 0);
            if (sig.color != null) {
              final color = Color(sig.color!);
              pdfColor = PdfColor(color.red, color.green, color.blue);
            }

            page.graphics.drawString(
              sig.text!,
              font,
              brush: PdfSolidBrush(pdfColor),
              bounds: Rect.fromLTWH(
                x,
                y,
                300 * instance.scale,
                100 * instance.scale,
              ),
            );
          }
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
        Navigator.pushReplacementNamed(
          context,
          '/sign_success',
          arguments: newPath,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    final fileName = _pdfPath != null
        ? _pdfPath!.split(Platform.pathSeparator).last
        : 'No File';

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
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.21,
                ),
                child: SfPdfViewer.file(
                  File(_pdfPath!),
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  onPageChanged: (details) {
                    setState(() {
                      _currentPageIndex = details.newPageNumber - 1;
                      _selectedSignatureId = null;
                    });
                  },
                  onZoomLevelChanged: (details) {
                    setState(() {
                      zoomLevel = details.newZoomLevel;
                    });
                  },
                  onTap: (details) {
                    setState(() {
                      _selectedSignatureId = null;
                    });
                  },
                ),
              )
            else
              Center(
                child: Text(
                  AppLocalizations.of(context)!.translate('select_pdf'),
                ),
              ),

            // ✍️ Draggable & Resizable Signature Boxes
            // Fix #1: Render using document-space coordinates compensated by scroll offset & zoom
            ..._addedSignatures
                .where((instance) => instance.pageIndex == _currentPageIndex)
                .map((instance) {
                  final isSelected = instance.id == _selectedSignatureId;
                  // Convert document-space position to screen position
                  final screenX =
                      instance.docPosition.dx * zoomLevel - _scrollOffset.dx;
                  final screenY =
                      instance.docPosition.dy * zoomLevel - _scrollOffset.dy;
                  return Positioned(
                    left: screenX,
                    top: screenY,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSignatureId = instance.id;
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _selectedSignatureId = instance.id;
                          // Convert screen delta to document-space delta
                          instance.docPosition += Offset(
                            details.delta.dx / zoomLevel,
                            details.delta.dy / zoomLevel,
                          );
                          // Update placement reference for accurate save
                          instance.placementScrollOffset = _scrollOffset;
                          instance.placementZoom = zoomLevel;
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: SizedBox(
                              width: 150 * instance.scale,
                              height: 80 * instance.scale,
                              // Fix #2 & #3: pass scale and forPdfOverlay flag
                              child: _buildSignaturePreview(
                                instance.signature,
                                scale: instance.scale,
                                forPdfOverlay: true,
                              ),
                            ),
                          ),
                          // ❌ Close Button
                          if (isSelected)
                            Positioned(
                              right: -20,
                              top: -20,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _addedSignatures.remove(instance);
                                    _selectedSignatureId = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // 🔄 Resize Handle
                          if (isSelected)
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  setState(() {
                                    _selectedSignatureId = instance.id;
                                    // Use horizontal drag to resize
                                    instance.scale += details.delta.dx / 100;
                                    if (instance.scale < 0.2)
                                      instance.scale = 0.2;
                                    if (instance.scale > 5.0)
                                      instance.scale = 5.0;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_out_map,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

            // 🔻 Bottom Section
            Align(
              alignment: Alignment.bottomCenter,
              child: _bottomPanel(colors),
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _showSignaturePicker,
                  child: _toolItem(
                    AppLocalizations.of(context)!.translate('sign'),
                    Icons.edit,
                    colors,
                    selected: true,
                  ),
                ),
                GestureDetector(
                  onTap: _addTextPrompt,
                  child: _toolItem(
                    AppLocalizations.of(context)!.translate('text_tool'),
                    Icons.text_fields,
                    colors,
                  ),
                ),
                GestureDetector(
                  onTap: _addDate,
                  child: _toolItem(
                    AppLocalizations.of(context)!.translate('date_tool'),
                    Icons.calendar_today,
                    colors,
                  ),
                ),
                GestureDetector(
                  onTap: _addInitialsPrompt,
                  child: _toolItem(
                    AppLocalizations.of(context)!.translate('initials_tool'),
                    Icons.person,
                    colors,
                  ),
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
                    child: Text(
                      AppLocalizations.of(context)!.translate('cancel'),
                    ),
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
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('save_signed_pdf'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _toolItem(
    String text,
    IconData icon,
    AppColors colors, {
    bool selected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? colors.primary : colors.text),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: selected ? colors.primary : colors.text,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
