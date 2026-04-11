import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import '../providers/theme_provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _saveLocation = '/storage/emulated/0/Download/signpdf_refpdf';

  @override
  void initState() {
    super.initState();
    _loadSaveLocation();
  }

  Future<void> _loadSaveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveLocation =
          prefs.getString('save_location') ??
          '/storage/emulated/0/Download/signpdf_refpdf';
    });
  }

  Future<void> _pickSaveLocation() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('save_location', selectedDirectory);
      setState(() {
        _saveLocation = selectedDirectory;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save location updated!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.darkColors : AppTheme.lightColors;

    return Scaffold(
      backgroundColor: color.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "A product by: ",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Icon(Icons.picture_as_pdf, color: color.primary),
            const SizedBox(width: 8),
            Text(
              "RedPDF",
              style: TextStyle(
                color: color.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 25),

              /// ⚙️ SETTINGS
              _sectionTitle("SETTINGS"),

              _card(
                color.card,
                child: Column(
                  children: [
                    SwitchListTile(
                      thumbColor: WidgetStatePropertyAll(Colors.blue),
                      trackOutlineColor: WidgetStatePropertyAll(Colors.blue),
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (val) =>
                          context.read<ThemeProvider>().toggleDarkMode(val),
                      title: const Text("Dark Mode"),
                      secondary: Container(
                        height: 50,
                        width: 50,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue.shade50,
                        ),
                        child: const Icon(Icons.dark_mode, color: Colors.blue),
                      ),
                    ),
                    _tile(
                      "Storage Location",
                      _saveLocation.split('/').last,
                      color,
                      Icons.storage,
                      Icons.edit,
                      _pickSaveLocation,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 📄 SUPPORT
              _sectionTitle("SUPPORT & LEGAL"),

              _card(
                color.card,
                child: Column(
                  children: [
                    _tile(
                      "Rate Us",
                      null,
                      color,
                      Icons.star,
                      Icons.open_in_new,
                      null,
                    ),
                    _tile(
                      "Our Other Apps",
                      null,
                      color,
                      Icons.apps,
                      Icons.open_in_new,
                      null,
                    ),
                    _tile(
                      "Privacy Policy",
                      null,
                      color,
                      Icons.privacy_tip_outlined,
                      Icons.arrow_forward_ios,
                      null,
                    ),
                    _tile(
                      "Terms & Conditions",
                      null,
                      color,
                      Icons.gavel_outlined,
                      Icons.arrow_forward_ios,
                      null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 10),

              Text(
                "VERSION 1.0.0 (1) • A Product by - REDPDF",
                style: TextStyle(fontSize: 12, color: color.text),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Card Wrapper
  Widget _card(Color color, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _tile(
    String title,
    String? trailingText,
    AppColors color,
    IconData? icon1,
    IconData? icon2,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          height: 50,
          width: 50,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.blue.shade50,
          ),
          child: Icon(icon1, color: Colors.blue),
        ),
        title: Text(title),
        trailing: trailingText != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingText.length > 15
                        ? "...${trailingText.substring(trailingText.length - 12)}"
                        : trailingText,
                    style: TextStyle(color: color.primary),
                  ),
                  if (icon2 != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon2, size: 16, color: color.primary),
                  ],
                ],
              )
            : Icon(icon2, size: 16),
      ),
    );
  }

  /// 🔹 Section Title
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 1,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
