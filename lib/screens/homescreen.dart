import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:sign_pdf_redpdf/providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickPdf(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      Navigator.pushNamed(
        context,
        '/signpdf',
        arguments: result.files.single.path,
      );
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
          "SignPDF",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: _circleIcon(Icons.settings, colors.light),
          ),
          const SizedBox(width: 15),
        ],
      ),
      //  Floating Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        onPressed: () => _pickPdf(context),
        child: const Icon(Icons.add_circle, color: Colors.white, size: 28),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 🔷 Scan Document Card
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/scanpdf'),
                child: _toolCard(
                  context,
                  colors: colors,
                  icon: Icons.document_scanner,
                  title: "Scan Document",
                  subtitle: "Scan paper documents into PDF",
                  bgColor: colors.card,
                  iconBg: colors.primary,
                ),
              ),

              const SizedBox(height: 16),

              //  Sign PDF Card
              GestureDetector(
                onTap: () => _pickPdf(context),
                child: _toolCard(
                  context,
                  colors: colors,
                  icon: Icons.edit_document,
                  title: "Sign PDF",
                  subtitle: "Add your signature to PDF",
                  bgColor: colors.card,
                  iconBg: Colors.purple,
                ),
              ),

              const SizedBox(height: 16),

              //  Create Signature Card
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/createsign'),
                child: _toolCard(
                  context,
                  colors: colors,
                  icon: Icons.draw,
                  title: "Create Signature",
                  subtitle: "Draw or upload your digital signature",
                  bgColor: colors.card,
                  iconBg: Colors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Circle Icon (top right)
  Widget _circleIcon(IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg.withOpacity(0.2), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: bg),
    );
  }

  //  Tool Card Widget
  Widget _toolCard(
    BuildContext context, {
    required AppColors colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: iconBg.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: iconBg.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconBg.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),

              Icon(Icons.chevron_right, color: colors.light),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconBg,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: colors.light, fontSize: 13)),
        ],
      ),
    );
  }
}
