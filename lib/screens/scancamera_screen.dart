import 'package:flutter/material.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.lightColors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 📷 Camera Preview Placeholder
          Container(color: Colors.black87),

          // 🔝 Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.close, color: Colors.white),
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.white),
                      SizedBox(width: 16),
                      Icon(Icons.settings, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🔲 Scan Frame
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: colors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 🔵 Document Detected
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "DOCUMENT DETECTED",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // 🔻 Bottom Controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Capture Button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),

                const SizedBox(height: 10),

                // Modes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _mode("ARD", false),
                    _mode("DOCUMENT", true),
                    _mode("BOOK", false),
                    _mode("WHITEBOARD", false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mode(String text, bool selected) {
    return Text(
      text,
      style: TextStyle(
        color: selected ? Colors.blue : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
