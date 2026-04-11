import 'dart:io';
import 'dart:typed_data';
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

  final List<String> _fonts = [
    'Dancing Script',
    'Pacifico',
    'Satisfy',
    'Great Vibes',
    'Caveat',
    'Handlee',
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Remove background
      final originalImage = img.decodeImage(
        await File(pickedFile.path).readAsBytes(),
      );
      if (originalImage != null) {
        final processedImage = img.Image(
          width: originalImage.width,
          height: originalImage.height,
        );
        for (var y = 0; y < originalImage.height; y++) {
          for (var x = 0; x < originalImage.width; x++) {
            final pixel = originalImage.getPixel(x, y);
            // Calculate luminance
            final num luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
            if (luminance > 160) {
              // Light pixel, likely background -> Transparent
              processedImage.setPixelRgba(
                x,
                y,
                pixel.r,
                pixel.g,
                pixel.b,
                0,
              );
            } else {
              // Dark pixel, likely signature -> Opaque
              processedImage.setPixelRgba(
                x,
                y,
                pixel.r,
                pixel.g,
                pixel.b,
                255,
              );
            }
          }
        }

        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/processed_signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(imagePath);
        await file.writeAsBytes(img.encodePng(processedImage));

        setState(() {
          _uploadedImage = file;
        });
      }
    }
  }

  Future<void> _saveSignature() async {
    final signatureProvider = Provider.of<SignatureProvider>(
      context,
      listen: false,
    );
    final String id = DateTime.now().millisecondsSinceEpoch.toString();

    if (selectedTab == 0) {
      if (_signatureController.isEmpty) return;

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
      if (_uploadedImage == null) return;

      final dir = await signatureProvider.getSignaturesPath();
      final path = '$dir/upload_$id.png';
      final file = await _uploadedImage!.copy(path);

      final sig = SignatureModel(id: id, type: 'image', path: file.path);
      await signatureProvider.addSignature(sig);
    } else if (selectedTab == 2) {
      if (_typedText.isEmpty) return;

      final sig = SignatureModel(
        id: id,
        type: 'text',
        text: _typedText,
        font: _fonts[_selectedFontIndex],
      );
      await signatureProvider.addSignature(sig);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text("Create Signature"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _tabs(colors),
            const SizedBox(height: 10),
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
                            "SIGNATURE CANVAS",
                            style: TextStyle(
                              color: colors.light,
                              letterSpacing: 1,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _signatureController.undo(),
                                child: _actionText("Undo", Icons.undo, colors),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _signatureController.clear(),
                                child: _actionText(
                                  "Clear",
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
                        "UPLOAD SIGNATURE",
                        style: TextStyle(color: colors.light, letterSpacing: 1),
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
                          child: _uploadedImage != null
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
                                      "Tap to upload from Gallery",
                                      style: TextStyle(color: colors.light),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Image'),
                        onPressed: _pickImage,
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
                          hintText: 'Enter your name...',
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
                      const SizedBox(height: 20),
                      if (_typedText.isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: _fonts.length,
                            itemBuilder: (context, index) {
                              final fontName = _fonts[index];
                              final isSelected = _selectedFontIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFontIndex = index;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
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
                                    child: Text(
                                      _typedText,
                                      style: GoogleFonts.getFont(
                                        fontName,
                                        textStyle: TextStyle(
                                          fontSize: 32,
                                          color: isSelected
                                              ? colors.primary
                                              : colors.text,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
    final tabs = ["Draw", "Upload", "Presets"];

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
          Text("PEN COLOR", style: TextStyle(color: colors.light)),
          const SizedBox(height: 10),
          Row(
            children: [
              _colorCircle(Colors.black),
              _colorCircle(colors.primary),
              _colorCircle(colors.danger),
              _colorCircle(colors.success),
            ],
          ),
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
              child: const Text("Cancel"),
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
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Save Signature",
                        style: TextStyle(
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
