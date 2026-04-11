import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/models/signature_model.dart';
import 'package:sign_pdf_redpdf/providers/signature_provider.dart';
import 'package:image/image.dart' as img;
import '../l10n/app_localizations.dart';

class CreateSignatureScreen extends StatefulWidget {
  const CreateSignatureScreen({super.key});

  @override
  State<CreateSignatureScreen> createState() => _CreateSignatureScreenState();
}

class _CreateSignatureScreenState extends State<CreateSignatureScreen>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  double penThickness = 2;
  Color selectedColor = Colors.black;

  // Draw Tab
  late SignatureController _signatureController;

  // Upload Tab
  File? _uploadedImage;

  // Type Tab
  final TextEditingController _textController = TextEditingController();
  String _typedText = '';
  int _selectedFontIndex = 0;
  bool _isProcessing = false;

  final List<Color> _signatureColors = [
    Colors.black,
    const Color(0xFF003366), // Navy Blue
    const Color(0xFF1B5E20), // Forest Green
    const Color(0xFFB22222), // Firebrick Red
    Colors.blue,
    Colors.purple,
  ];

  final List<String> _fonts = [
    'Noto Sans',
    'Noto Sans Devanagari', // Hindi Global
    'Noto Sans Arabic', // Arabic Global
    'Noto Sans JP', // Japanese Global
    'Tiro Devanagari Hindi', // Stylized Hindi
    'Mukta', // Hindi (Modern)
    'Hind', // Hindi (Standard)
    'Cairo', // Arabic (Contemporary)
    'Amiri', // Arabic (Classical)
    'Almarai', // Arabic (Soft)
    'Tajawal', // Arabic (Strong)
    'Sawarabi Mincho', // Japanese (Classic)
    'Lora', // Russian / Vietnamese support
    'Montserrat', // Global support
    'Lexend', // Vietnamese support
    'Be Vietnam Pro', // Vietnamese support
    'Roboto Slab', // Russian support
    'Playfair Display', // Global support
    'EB Garamond', // Global support
    'Poppins', // Multi-language Sans
    'Dancing Script',
    'Pacifico',
    'Satisfy',
    'Great Vibes',
    'Caveat',
    'Handlee',
    'Alex Brush',
    'Allura',
    'Arizonia',
    'Bad Script',
    'Bilbo',
    'Calligraffitti',
    'Clicker Script',
    'Cookie',
    'Damion',
    'Grand Hotel',
    'Homemade Apple',
    'Italianno',
    'Jim Nightshade',
    'Just Another Hand',
    'Kaushan Script',
    'League Script',
    'Marck Script',
    'Meddon',
    'Miss Fajardose',
    'Monsieur La Doulaise',
    'Mr De Haviland',
    'Mrs Saint Delafield',
    'Nothing You Could Do',
    'Parisienne',
    'Pinyon Script',
    'Playball',
    'Quintessential',
    'Rancho',
    'Rochester',
    'Sacramento',
    'Shadows Into Light',
    'Tangerine',
    'Yellowtail',
  ];

  @override
  void initState() {
    super.initState();
    _initSignatureController();
  }

  void _initSignatureController() {
    _signatureController = SignatureController(
      penStrokeWidth: penThickness,
      penColor: selectedColor,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _textController.dispose();
    super.dispose();
  }

  List<String> _getFilteredFonts() {
    if (_typedText.isEmpty) return _fonts;

    // Detect character sets
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(_typedText);
    bool hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(_typedText);
    bool hasJapanese =
        RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(_typedText);
    bool hasRussian = RegExp(r'[\u0400-\u04FF]').hasMatch(_typedText);

    List<String> prioritized = [];
    List<String> others = [];

    for (var font in _fonts) {
      bool isMatch = false;
      if (hasArabic &&
          (font.contains('Arabic') ||
              font == 'Cairo' ||
              font == 'Amiri' ||
              font == 'Almarai' ||
              font == 'Tajawal')) isMatch = true;
      if (hasDevanagari &&
          (font.contains('Devanagari') ||
              font == 'Mukta' ||
              font == 'Hind' ||
              font == 'Tiro Devanagari Hindi')) isMatch = true;
      if (hasJapanese &&
          (font.contains('JP') ||
              font == 'Sawarabi Mincho' ||
              font == 'Noto Sans JP')) isMatch = true;
      if (hasRussian &&
          (font == 'Bad Script' ||
              font == 'Roboto Slab' ||
              font == 'Lora' ||
              font == 'Montserrat' ||
              font == 'EB Garamond')) isMatch = true;

      // Latin-based (English, Spanish, etc) - most scripts work
      if (!hasArabic && !hasDevanagari && !hasJapanese && !hasRussian) {
        if (font != 'Noto Sans Devanagari' &&
            !font.contains('Arabic') &&
            !font.contains('JP')) {
          isMatch = true;
        }
      }

      if (isMatch)
        prioritized.add(font);
      else
        others.add(font);
    }

    // Always keep Noto Sans at top as universal fallback
    if (prioritized.contains('Noto Sans')) {
      prioritized.remove('Noto Sans');
      prioritized.insert(0, 'Noto Sans');
    } else if (others.contains('Noto Sans')) {
      others.remove('Noto Sans');
      prioritized.insert(0, 'Noto Sans');
    }

    return [...prioritized, ...others];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isProcessing = true);
      try {
        final bytes = await File(pickedFile.path).readAsBytes();

        // Remove background in a background isolate to avoid freezing UI
        final processedBytes = await compute(_removeBackgroundProcess, bytes);

        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/processed_signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(imagePath);
        await file.writeAsBytes(processedBytes);

        setState(() {
          _uploadedImage = file;
        });
      } catch (e) {
        debugPrint("Error processing image: $e");
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  static Uint8List _removeBackgroundProcess(Uint8List bytes) {
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) return Uint8List(0);

    final image = img.Image(
      width: originalImage.width,
      height: originalImage.height,
    );
    for (var y = 0; y < originalImage.height; y++) {
      for (var x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final num luminance =
            0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        if (luminance > 160) {
          image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
        } else {
          image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 255);
        }
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  Future<void> _saveSignature() async {
    final signatureProvider = Provider.of<SignatureProvider>(
      context,
      listen: false,
    );
    final String id = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      if (selectedTab == 0) {
        if (_signatureController.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.translate('sign_here')),
            ),
          );
          return;
        }

        final Uint8List? data = await _signatureController.toPngBytes();
        if (data != null) {
          final dir = await signatureProvider.getSignaturesPath();
          final path = '$dir/draw_$id.png';
          final file = File(path);
          await file.writeAsBytes(data);

          final sig = SignatureModel(id: id, type: 'draw', path: path);
          await signatureProvider.addSignature(sig);
        }
      } else if (selectedTab == 1) {
        if (_uploadedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('upload')),
            ),
          );
          return;
        }

        final dir = await signatureProvider.getSignaturesPath();
        final path = '$dir/upload_$id.png';
        final file = await _uploadedImage!.copy(path);

        final sig = SignatureModel(id: id, type: 'image', path: file.path);
        await signatureProvider.addSignature(sig);
      } else if (selectedTab == 2) {
        if (_typedText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('enter_name'),
              ),
            ),
          );
          return;
        }

        final filteredFonts = _getFilteredFonts();
        final sig = SignatureModel(
          id: id,
          type: 'text',
          text: _typedText,
          font: filteredFonts[_selectedFontIndex],
          color: selectedColor.value,
        );
        await signatureProvider.addSignature(sig);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('saved_successfully'),
        ),
        backgroundColor: Colors.green,
      ),
    );

    if (mounted) {
      // Adding a small delay to ensure provider state is synced before redirect
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
            arguments: {'index': 1, 'tabIndex': 1},
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('create_signature'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _tabs(colors),
            // const SizedBox(height: 5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (selectedTab == 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('draw').toUpperCase(),
                            style: TextStyle(
                              color: colors.light,
                              letterSpacing: 1,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _signatureController.undo(),
                                child: _actionText(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('undo'),
                                  Icons.undo,
                                  colors,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _signatureController.clear(),
                                child: _actionText(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('clear'),
                                  Icons.delete,
                                  colors,
                                  isDanger: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.4),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Signature(
                            controller: _signatureController,
                            height: 200,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _controlsCard(colors),
                    ] else if (selectedTab == 1) ...[
                      Text(
                        AppLocalizations.of(context)!
                            .translate(
                              'Click upload to select another signature.',
                            )
                            .toUpperCase(),
                        style: TextStyle(color: colors.light, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.primary.withOpacity(0.4),
                            ),
                          ),
                          child: _isProcessing
                              ? const Center(child: CircularProgressIndicator())
                              : _uploadedImage != null
                              ? Image.file(_uploadedImage!, fit: BoxFit.contain)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      size: 40,
                                      color: colors.light,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('upload'),
                                      style: TextStyle(color: colors.light),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.image),
                        label: Text(
                          _isProcessing
                              ? "Processing..."
                              : AppLocalizations.of(
                                  context,
                                )!.translate('upload'),
                        ),
                        onPressed: _isProcessing ? null : _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ] else if (selectedTab == 2) ...[
                      TextField(
                        controller: _textController,
                        style: TextStyle(color: colors.text),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.translate('enter_name'),
                          hintStyle: TextStyle(color: colors.light),
                          filled: true,
                          fillColor: colors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _typedText = val;
                          });
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: _signatureColors
                              .map((c) => _colorCircle(c))
                              .toList(),
                        ),
                      ),

                      ...[
                        Builder(
                          builder: (context) {
                            final filteredFonts = _getFilteredFonts();
                            if (_typedText.isEmpty) return const SizedBox.shrink();
                            
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: ListView.builder(
                                itemCount: filteredFonts.length,
                                itemBuilder: (context, index) {
                                  final fontName = filteredFonts[index];
                                  final isSelected = _selectedFontIndex == index;

                                  // Safe font rendering for preview
                                  Widget textWidget;
                                  try {
                                    textWidget = Text(
                                      _typedText,
                                      style: GoogleFonts.getFont(
                                        fontName,
                                        textStyle: TextStyle(
                                          fontSize: 30,
                                          color: isSelected
                                              ? colors.primary
                                              : selectedColor,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    textWidget = Text(
                                      _typedText,
                                      style: TextStyle(
                                        fontSize: 30,
                                        color: isSelected
                                            ? colors.primary
                                            : selectedColor,
                                      ),
                                    );
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFontIndex = index;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colors.primary.withOpacity(0.1)
                                            : colors.card,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: isSelected
                                              ? colors.primary
                                              : colors.border,
                                        ),
                                      ),
                                      child: Center(
                                        child: textWidget,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            _bottomButtons(colors),
          ],
        ),
      ),
    );
  }

  Widget _tabs(AppColors colors) {
    final tabs = [
      AppLocalizations.of(context)!.translate('draw'),
      AppLocalizations.of(context)!.translate('upload'),
      AppLocalizations.of(context)!.translate('presets'),
    ];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedTab == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = index;
              });
            },
            child: Column(
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.light,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  color: isSelected ? colors.primary : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _controlsCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pen Thickness", style: TextStyle(color: colors.text)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${penThickness.toInt()} px",
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ),
          Slider(
            value: penThickness,
            min: 1,
            max: 10,
            activeColor: colors.primary,
            onChanged: (v) {
              setState(() {
                penThickness = v;
                final points = _signatureController.points;
                _signatureController = SignatureController(
                  points: points,
                  penStrokeWidth: penThickness,
                  penColor: selectedColor,
                  exportBackgroundColor: Colors.transparent,
                );
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(
              context,
            )!.translate('choose_color').toUpperCase(),
            style: TextStyle(color: colors.light, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(children: _signatureColors.map((c) => _colorCircle(c)).toList()),
        ],
      ),
    );
  }

  Widget _colorCircle(Color color) {
    final isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          final points = _signatureController.points;
          _signatureController = SignatureController(
            points: points,
            penStrokeWidth: penThickness,
            penColor: selectedColor,
            exportBackgroundColor: Colors.transparent,
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: CircleAvatar(backgroundColor: color, radius: 14),
      ),
    );
  }

  Widget _actionText(
    String text,
    IconData icon,
    AppColors colors, {
    bool isDanger = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDanger ? colors.danger : colors.text),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: isDanger ? colors.danger : colors.text),
        ),
      ],
    );
  }

  Widget _bottomButtons(AppColors colors) {
    return Container(
      margin: const EdgeInsets.all(10),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _saveSignature,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(25),
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
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.translate('save_signature') ??
                            "",
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
    );
  }
}
