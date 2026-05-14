import 'package:sign_pdf_redpdf/screens/allfiles_screen.dart';
import 'package:sign_pdf_redpdf/screens/homescreen.dart';
import 'package:sign_pdf_redpdf/screens/profilescreen.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _fileTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-initialize selected index if any arguments exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkArguments();
    });
  }

  void _checkArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      setState(() {
        if (args.containsKey('index')) {
          _selectedIndex = args['index'] as int;
        }
        if (args.containsKey('tabIndex')) {
          _fileTabIndex = args['tabIndex'] as int;
        }
      });
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final appColors = AppTheme.lightColors;

    final List<Widget> pages = [
      const HomeScreen(),
      FilesScreen(initialTabIndex: _fileTabIndex),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: appColors.primary,
      body: pages[_selectedIndex],
      // floatingActionButton: _selectedIndex == 0
      //     ? FloatingActionButton.extended(
      //         onPressed: () => Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (_) => const ImageToPdfScreen()),
      //         ),
      //         backgroundColor: appColors.primary,
      //         elevation: 4,
      //         // shape: const CircleBorder(),
      //         isExtended: true,
      //         label: Row(
      //           children: [
      //             const Icon(Icons.add, color: Colors.white, size: 32),
      //             Text("IMG to Pdf", style: TextStyle(color: Colors.white)),
      //           ],
      //         ),
      //       )
      //     : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.surface,
        elevation: 10,
        selectedItemColor: appColors.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context)!.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: AppLocalizations.of(context)!.translate('all_files'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppLocalizations.of(context)!.translate('profile'),
          ),
        ],
      ),
    );
  }
}
