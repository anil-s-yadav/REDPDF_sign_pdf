import 'package:sign_pdf_redpdf/screens/allfiles_screen.dart';
import 'package:sign_pdf_redpdf/screens/create_sign_screen.dart';
import 'package:sign_pdf_redpdf/screens/editsign_screen.dart';
import 'package:sign_pdf_redpdf/screens/homescreen.dart';
import 'package:sign_pdf_redpdf/screens/navigation.dart';
import 'package:sign_pdf_redpdf/screens/pdf_viewer_screen.dart';
import 'package:sign_pdf_redpdf/screens/profilescreen.dart';
import 'package:sign_pdf_redpdf/screens/scan_pdf_screen.dart';
import 'package:sign_pdf_redpdf/screens/scancamera_screen.dart';
import 'package:sign_pdf_redpdf/screens/scan_success_screen.dart';
import 'package:sign_pdf_redpdf/screens/signpdf_screen.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/signature_provider.dart';
import 'providers/pdf_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SignatureProvider()),
        ChangeNotifierProvider(create: (_) => PdfProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PDF Master',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const NavigationPage(),
            '/home': (context) => const HomeScreen(),
            '/allfiles': (context) => const FilesScreen(),
            '/scanpdf': (context) => const ScanPdfScreen(),
            '/scancamera': (context) => const ScanCameraScreen(),
            '/createsign': (context) => const CreateSignatureScreen(),
            '/editsign': (context) => const EditSignatureScreen(),
            '/scan_success': (context) => const ScanSuccessScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/viewer') {
              final String pdfPath = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => PdfViewerScreen(pdfPath: pdfPath),
              );
            }
            if (settings.name == '/signpdf') {
              final String? pdfPath = settings.arguments as String?;
              return MaterialPageRoute(
                // we'll update SignPdfScreen constructor to take pdfPath if needed, but the original might just read it differently. 
                // Let's pass it anyway or remove from here if SignPdf doesn't accept. We'll update SignPdfScreen.
                builder: (context) => const SignPdfScreen(),
                settings: settings,
              );
            }
            return null;
          },
        );
      },
    );
  }
}
