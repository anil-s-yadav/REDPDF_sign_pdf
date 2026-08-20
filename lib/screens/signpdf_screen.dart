import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/signature_provider.dart';
import 'package:sign_pdf_redpdf/providers/pdf_provider.dart';
import 'package:sign_pdf_redpdf/models/signature_model.dart';
import 'package:sign_pdf_redpdf/models/pdf_document_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../utils/download_helper.dart';

class SignPdfScreen extends StatefulWidget {
  const SignPdfScreen({super.key});

  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class SignatureInstance {
  final String id;
  final SignatureModel signature;
  int pageIndex;
  // Normalized coordinates (0.0 - 1.0) relative to the specific PDF page
  double normX;
  double normY;
  double normWidth;
  double normHeight;
  double aspectRatio;
  // For text signatures: path to a cached PNG rendered at placement time (preserves Google Font exactly)
  String? cachedTextImagePath;

  SignatureInstance({
    required this.id,
    required this.signature,
    required this.pageIndex,
    required this.normX,
    required this.normY,
    required this.normWidth,
    required this.normHeight,
    required this.aspectRatio,
    this.cachedTextImagePath,
  });
}

class _SignPdfScreenState extends State<SignPdfScreen> {
  final List<SignatureInstance> _addedSignatures = [];
  String? _pdfPath;
  PdfDocument? _pdfDocument; // Syncfusion doc for saving only
  int _pageCount = 1;
  int _currentPageIndex = 0;
  final pdfrx.PdfViewerController _viewerController =
      pdfrx.PdfViewerController();
  String? _selectedSignatureId;

  @override
  void dispose() {
    _pdfDocument?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pdfPath == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is String) {
        _pdfPath = args;
        _loadPdfDocument();
      }
    }
  }

  // Load Syncfusion PdfDocument for save logic only
  Future<void> _loadPdfDocument() async {
    if (_pdfPath == null) return;
    try {
      final bytes = await File(_pdfPath!).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      if (mounted) {
        setState(() {
          _pdfDocument = doc;
          _pageCount = doc.pages.count;
        });
      }
    } catch (_) {}
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

    // Normalized defaults: ~35% width centered on page
    const double normW = 0.35;
    const double normH = 0.18;
    const double aspect = normW / normH;
    final double normX = (0.5 - normW / 2).clamp(0.0, 1.0 - normW);
    final double normY = (0.5 - normH / 2).clamp(0.0, 1.0 - normH);

    final instance = SignatureInstance(
      id: newId,
      signature: sig,
      pageIndex: _currentPageIndex,
      normX: normX,
      normY: normY,
      normWidth: normW,
      normHeight: normH,
      aspectRatio: aspect,
    );

    if (sig.type == 'text' && sig.text != null) {
      final Color color = sig.color != null ? Color(sig.color!) : Colors.black;
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

  Future<Uint8List?> _renderTextToImageBytes(
    String text,
    String? fontName,
    Color color, {
    double width = 600,
    double height = 240,
    double fontSize = 80,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

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
    bool forPdfOverlay = false,
  }) {
    if ((sig.type == 'draw' || sig.type == 'image') && sig.path != null) {
      final file = File(sig.path!);
      if (file.existsSync()) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.file(file, fit: BoxFit.contain),
        );
      }
    } else if (sig.type == 'text' && sig.text != null) {
      final Color textColor = forPdfOverlay
          ? Colors.black
          : (sig.color != null ? Color(sig.color!) : Colors.black);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              sig.text!,
              style: sig.font != null
                  ? GoogleFonts.getFont(
                      sig.font!,
                      textStyle: TextStyle(fontSize: 40, color: textColor),
                    )
                  : TextStyle(fontSize: 40, color: textColor),
            ),
          ),
        ),
      );
    }
    return const Icon(Icons.error);
  }

  void _addTextPrompt() {
    final textController = TextEditingController();
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
    final textController = TextEditingController();
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

    try {
      final File original = File(_pdfPath!);
      final PdfDocument document = PdfDocument(
        inputBytes: await original.readAsBytes(),
      );

      for (var instance in _addedSignatures) {
        if (instance.pageIndex >= 0 &&
            instance.pageIndex < document.pages.count) {
          final PdfPage page = document.pages[instance.pageIndex];
          final double pw = page.size.width;
          final double ph = page.size.height;

          // Exact page-relative coordinates in PDF points
          final double x = instance.normX * pw;
          final double y = instance.normY * ph;
          final double width = instance.normWidth * pw;
          final double height = instance.normHeight * ph;

          final sig = instance.signature;

          if ((sig.type == 'draw' || sig.type == 'image') && sig.path != null) {
            final File imgFile = File(sig.path!);
            if (await imgFile.exists()) {
              final PdfBitmap image = PdfBitmap(await imgFile.readAsBytes());

              // Calculate contain bounds for drawing on PDF
              final double imgW = image.width.toDouble();
              final double imgH = image.height.toDouble();
              final double imgRatio = imgW / imgH;
              final double boxRatio = width / height;

              double drawW = width;
              double drawH = height;
              double drawX = x;
              double drawY = y;

              if (imgRatio > boxRatio) {
                drawW = width;
                drawH = width / imgRatio;
                drawY = y + (height - drawH) / 2;
              } else {
                drawH = height;
                drawW = height * imgRatio;
                drawX = x + (width - drawW) / 2;
              }

              page.graphics.drawImage(
                image,
                Rect.fromLTWH(drawX, drawY, drawW, drawH),
              );
            }
          } else if (sig.type == 'text' && sig.text != null) {
            Uint8List? imgBytes;

            if (instance.cachedTextImagePath != null &&
                File(instance.cachedTextImagePath!).existsSync()) {
              imgBytes = await File(
                instance.cachedTextImagePath!,
              ).readAsBytes();
            } else {
              final Color textColor = sig.color != null
                  ? Color(sig.color!)
                  : Colors.black;
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
                Rect.fromLTWH(x, y, width, height),
              );
            }
          }
        }
      }

      final List<int> bytes = document.saveSync();
      document.dispose();

      final fileName = 'signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final Uint8List uint8Bytes = Uint8List.fromList(bytes);

      // Save to cache for guaranteed preview/share access
      final tempDir = await getTemporaryDirectory();
      final cachePath = '${tempDir.path}/$fileName';
      await File(cachePath).writeAsBytes(uint8Bytes, flush: true);

      // Export to Downloads or custom location for the user
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('save_location');

      if (customPath != null) {
        final dir = Directory(customPath);
        if (!await dir.exists()) await dir.create(recursive: true);
        await File('$customPath/$fileName').writeAsBytes(uint8Bytes, flush: true);
      } else {
        await DownloadHelper.savePdfToDownloads(
          bytes: uint8Bytes,
          fileName: fileName,
        );
      }

      if (!mounted) return;
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      final doc = PdfDocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Signed_${original.uri.pathSegments.last}",
        path: cachePath,
        sizeInBytes: uint8Bytes.length,
      );

      await pdfProvider.addSignedDocument(doc);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/sign_success',
          arguments: cachePath,
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
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Modern Top Bar
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_pageCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _currentPageIndex > 0
                                  ? () {
                                      if (_viewerController.isReady) {
                                        _viewerController.goToPage(
                                          pageNumber: _currentPageIndex,
                                        );
                                      }
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 20,
                                  color: _currentPageIndex > 0
                                      ? colors.primary
                                      : colors.text.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${_currentPageIndex + 1} / $_pageCount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _currentPageIndex < _pageCount - 1
                                  ? () {
                                      if (_viewerController.isReady) {
                                        _viewerController.goToPage(
                                          pageNumber: _currentPageIndex + 2,
                                        );
                                      }
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: _currentPageIndex < _pageCount - 1
                                      ? colors.primary
                                      : colors.text.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 📄 PDF Viewer (pdfrx with per-page overlays)
            Expanded(
              child: _pdfPath != null
                  ? pdfrx.PdfViewer.file(
                      _pdfPath!,
                      controller: _viewerController,
                      params: pdfrx.PdfViewerParams(
                        pageOverlaysBuilder: _buildPageOverlays,
                        onPageChanged: (pageNumber) {
                          setState(() {
                            _currentPageIndex = (pageNumber ?? 1) - 1;
                            _selectedSignatureId = null;
                          });
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('select_pdf'),
                      ),
                    ),
            ),

            _bottomPanel(colors),
          ],
        ),
      ),
    );
  }

  // Build per-page signature overlays
  List<Widget> _buildPageOverlays(
    BuildContext context,
    Rect pageRect,
    pdfrx.PdfPage page,
  ) {
    final pageIndex = page.pageNumber - 1;
    final signaturesOnPage = _addedSignatures.where(
      (inst) => inst.pageIndex == pageIndex,
    );

    return signaturesOnPage.map((instance) {
      final isSelected = instance.id == _selectedSignatureId;
      final double left = instance.normX * pageRect.width;
      final double top = instance.normY * pageRect.height;
      final double width = instance.normWidth * pageRect.width;
      final double height = instance.normHeight * pageRect.height;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedSignatureId = instance.id);
          },
          onPanUpdate: (details) {
            setState(() {
              _selectedSignatureId = instance.id;
              instance.normX += details.delta.dx / pageRect.width;
              instance.normY += details.delta.dy / pageRect.height;
              instance.normX = instance.normX.clamp(
                0.0,
                1.0 - instance.normWidth,
              );
              instance.normY = instance.normY.clamp(
                0.0,
                1.0 - instance.normHeight,
              );
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: width,
                height: height,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _buildSignaturePreview(
                  instance.signature,
                  forPdfOverlay: true,
                ),
              ),
              if (isSelected)
                Positioned(
                  right: -14,
                  top: -14,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _addedSignatures.remove(instance);
                        _selectedSignatureId = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      setState(() {
                        _selectedSignatureId = instance.id;
                        double newW =
                            instance.normWidth * pageRect.width +
                            details.delta.dx;
                        newW = newW.clamp(
                          40.0,
                          pageRect.width * (1.0 - instance.normX),
                        );
                        double newH = newW / instance.aspectRatio;
                        if (newH > pageRect.height * (1.0 - instance.normY)) {
                          newH = pageRect.height * (1.0 - instance.normY);
                          newW = newH * instance.aspectRatio;
                        }
                        instance.normWidth = newW / pageRect.width;
                        instance.normHeight = newH / pageRect.height;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.zoom_out_map,
                          size: 14,
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
    }).toList();
  }

  Widget _bottomPanel(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _toolItem(
                AppLocalizations.of(context)!.translate('sign'),
                Icons.edit,
                colors,
                _showSignaturePicker,
              ),
              _toolItem(
                AppLocalizations.of(context)!.translate('text_tool'),
                Icons.text_fields,
                colors,
                _addTextPrompt,
              ),
              _toolItem(
                AppLocalizations.of(context)!.translate('date_tool'),
                Icons.calendar_today,
                colors,
                _addDate,
              ),
              _toolItem(
                AppLocalizations.of(context)!.translate('initials_tool'),
                Icons.person,
                colors,
                _addInitialsPrompt,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: colors.text,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('cancel'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _saveSignedPdf,
                    icon: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('save_signed_pdf'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      elevation: 2,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolItem(
    String text,
    IconData icon,
    AppColors colors,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(height: 2),
            Text(
              text,
              style: TextStyle(
                color: colors.text,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
