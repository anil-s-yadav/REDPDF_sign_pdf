import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
  // For text signatures: path to a cached PNG rendered at placement time (preserves Google Font exactly)
  String? cachedTextImagePath;

  SignatureInstance({
    required this.id,
    required this.signature,
    required this.docPosition,
    required this.pageIndex,
    required this.placementScrollOffset,
    required this.placementZoom,
    this.scale = 1.0,
    this.cachedTextImagePath,
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

  Future<void> _addSignature(SignatureModel sig) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    // Store position in document-space coordinates (zoom=1 reference)
    final docPos = Offset(
      (100 + _scrollOffset.dx) / zoomLevel,
      (200 + _scrollOffset.dy) / zoomLevel,
    );

    final instance = SignatureInstance(
      id: newId,
      signature: sig,
      docPosition: docPos,
      pageIndex: _pdfViewerController.pageNumber - 1,
      placementScrollOffset: _scrollOffset,
      placementZoom: zoomLevel,
    );

    // For text signatures, render to PNG NOW while the Google Font is guaranteed
    // to already be registered in Flutter's font engine (the preview just showed it).
    if (sig.type == 'text' && sig.text != null) {
      final Color color =
          sig.color != null ? Color(sig.color!) : Colors.black;
      final Uint8List? bytes = await _renderTextToImageBytes(
        sig.text!,
        sig.font,
        color,
        width: 600,
        height: 240,
        fontSize: 80,
      );
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/text_sig_$newId.png';
        await File(path).writeAsBytes(bytes);
        instance.cachedTextImagePath = path;
      }
    }

    if (mounted) {
      setState(() {
        _addedSignatures.add(instance);
        _selectedSignatureId = newId;
      });
    }
  }

  /// Builds signature preview widget.
  /// [scale] controls text font scaling for the on-PDF overlay.
  /// [forPdfOverlay] when true, forces black text for visibility on white PDF pages.
  /// Renders a text signature with the correct Google Font to a PNG byte array.
  /// This is used during PDF generation so fonts are preserved exactly as shown on screen.
  Future<Uint8List?> _renderTextToImageBytes(
    String text,
    String? fontName,
    Color color, {
    double width = 600,
    double height = 240,
    double fontSize = 80,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.transparent,
    );

    TextStyle style;
    if (fontName != null && fontName.isNotEmpty) {
      try {
        style = GoogleFonts.getFont(
          fontName,
          textStyle: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.normal,
          ),
        );
      } catch (_) {
        style = TextStyle(fontSize: fontSize, color: color);
      }
    } else {
      style = TextStyle(fontSize: fontSize, color: color);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: width);

    // Center the text in the canvas
    final xOffset = (width - textPainter.width) / 2;
    final yOffset = (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xOffset, yOffset));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

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
                    textStyle: TextStyle(fontSize: fontSize, color: textColor),
                  )
                : TextStyle(fontSize: fontSize, color: textColor),
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

          // SfPdfViewer fits the page to the screen width, but applies an 8px margin 
          // on the left, right, top, and bottom, plus an 8px gap between pages.
          final double screenWidth = MediaQuery.of(context).size.width;
          final double pageViewWidth = screenWidth - 16.0; // 8px left and 8px right
          final double pw = page.size.width;
          final double pdfScale = pw / pageViewWidth;

          // Calculate the Y offset of the top of this specific page in the continuous scroll view
          double pageTopDocY = 8.0; // 8px top margin for the document
          for (int i = 0; i < instance.pageIndex; i++) {
            final PdfPage p = document.pages[i];
            double hPixels = pageViewWidth * (p.size.height / p.size.width);
            pageTopDocY += hPixels + 8.0; // 8px spacing between pages
          }

          // docPosition is the exact absolute coordinate in the continuous scroll view at zoom=1.
          // Subtract the top margin offset and left margin offset to get local page pixels.
          final double localDocX = instance.docPosition.dx - 8.0; 
          final double localDocY = instance.docPosition.dy - pageTopDocY;

          // Convert logical pixels back to PDF points.
          // Add 4.0 to account for the EdgeInsets.all(4) padding inside the UI Container
          // so the drawn elements perfectly match the visual position of the inner SizedBox.
          final double paddingOffset = 4.0;
          double x = (localDocX + paddingOffset) * pdfScale;
          double y = (localDocY + paddingOffset) * pdfScale;

          if ((sig.type == 'draw' || sig.type == 'image') && sig.path != null) {
            final File imgFile = File(sig.path!);
            if (await imgFile.exists()) {
              final PdfBitmap image = PdfBitmap(await imgFile.readAsBytes());
              
              // Simulate BoxFit.contain and Center alignment from the UI
              final double imgWidth = image.width.toDouble();
              final double imgHeight = image.height.toDouble();
              final double boxWidth = 150 * instance.scale * pdfScale;
              final double boxHeight = 80 * instance.scale * pdfScale;

              double fittedWidth = boxWidth;
              double fittedHeight = imgHeight * (boxWidth / imgWidth);

              if (fittedHeight > boxHeight) {
                fittedHeight = boxHeight;
                fittedWidth = imgWidth * (boxHeight / imgHeight);
              }

              final double dx = x + (boxWidth - fittedWidth) / 2;
              final double dy = y + (boxHeight - fittedHeight) / 2;

              page.graphics.drawImage(
                image,
                Rect.fromLTWH(dx, dy, fittedWidth, fittedHeight),
              );
            }
          } else if (sig.type == 'text' && sig.text != null) {
            final double boxWidth = 150 * instance.scale * pdfScale;
            final double boxHeight = 80 * instance.scale * pdfScale;

            Uint8List? imgBytes;

            // Prefer the cached PNG rendered at placement time (exact Google Font)
            if (instance.cachedTextImagePath != null &&
                File(instance.cachedTextImagePath!).existsSync()) {
              imgBytes = await File(instance.cachedTextImagePath!).readAsBytes();
            } else {
              // Fallback: re-render (font should be loaded since user already saw it)
              final Color textColor =
                  sig.color != null ? Color(sig.color!) : Colors.black;
              imgBytes = await _renderTextToImageBytes(
                sig.text!,
                sig.font,
                textColor,
                width: 600,
                height: 240,
                fontSize: 80,
              );
            }

            if (imgBytes != null) {
              final PdfBitmap image = PdfBitmap(imgBytes);
              page.graphics.drawImage(
                image,
                Rect.fromLTWH(x, y, boxWidth, boxHeight),
              );
            }
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
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 📄 PDF Viewer
                  if (_pdfPath != null)
                    SfPdfViewer.file(
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
                      .where(
                        (instance) => instance.pageIndex == _currentPageIndex,
                      )
                      .map((instance) {
                        final isSelected = instance.id == _selectedSignatureId;
                        // Convert document-space position to screen position
                        final screenX =
                            instance.docPosition.dx * zoomLevel -
                            _scrollOffset.dx;
                        final screenY =
                            instance.docPosition.dy * zoomLevel -
                            _scrollOffset.dy;
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
                                          instance.scale +=
                                              details.delta.dx / 100;
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
                ],
              ),
            ),
            // 🔻 Bottom Section
            _bottomPanel(colors),
          ],
        ),
      ),
    );
  }

  // 🔻 Bottom Panel
  Widget _bottomPanel(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
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
          const SizedBox(height: 8),
          // Buttons Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: colors.card,
                      foregroundColor: colors.text,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _saveSignedPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('save_signed_pdf'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
