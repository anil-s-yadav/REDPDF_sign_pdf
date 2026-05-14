import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'terms_screen.dart';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UPDATE THESE URLs before publishing
// ─────────────────────────────────────────────────────────────────────────────
const String _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.redpdf.sign_pdf_redpdf';
const String _kDeveloperUrl =
    'https://play.google.com/store/apps/developer?id=RedPDF';
const String _kPrivacyPolicyUrl =
    'https://redpdf.app/privacy-policy';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _saveLocation = '/storage/emulated/0/Download/RedPdf_sign';

  @override
  void initState() {
    super.initState();
    _loadSaveLocation();
  }

  Future<void> _loadSaveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveLocation = prefs.getString('save_location') ??
          '/storage/emulated/0/Download/RedPdf_sign';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('save_location_updated'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider languageProvider,
    AppColors color,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: color.card,
          title: Text("Select Language", style: TextStyle(color: color.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _languageOption("English", "en", languageProvider, color),
                _languageOption("हिन्दी (Hindi)", "hi", languageProvider, color),
                _languageOption("Español (Spanish)", "es", languageProvider, color),
                _languageOption("Português (Brasil)", "pt", languageProvider, color),
                _languageOption("Bahasa Indonesia", "id", languageProvider, color),
                _languageOption("Français (French)", "fr", languageProvider, color),
                _languageOption("Deutsch (German)", "de", languageProvider, color),
                _languageOption("العربية (Arabic)", "ar", languageProvider, color),
                _languageOption("Русский (Russian)", "ru", languageProvider, color),
                _languageOption("Türkçe (Turkish)", "tr", languageProvider, color),
                _languageOption("Tiếng Việt (Vietnamese)", "vi", languageProvider, color),
                _languageOption("日本語 (Japanese)", "ja", languageProvider, color),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption(
    String label,
    String code,
    LanguageProvider provider,
    AppColors color,
  ) {
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? color.primary : color.text,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        provider.changeLanguage(code);
        Navigator.pop(context);
      },
      trailing: isSelected ? Icon(Icons.check, color: color.primary) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.darkColors : AppTheme.lightColors;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Text("A product by: ",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            Icon(Icons.picture_as_pdf, color: color.danger),
            const SizedBox(width: 8),
            Text(
              "RedPDF",
              style: TextStyle(
                color: color.danger,
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
              _sectionTitle(loc.translate('settings').toUpperCase()),
              _card(
                color.card,
                child: Column(
                  children: [
                    SwitchListTile(
                      thumbColor: WidgetStatePropertyAll(
                        color.primary.withAlpha(200),
                      ),
                      trackOutlineColor: WidgetStatePropertyAll(
                        color.primary.withAlpha(200),
                      ),
                      activeThumbColor: color.text.withAlpha(200),
                      activeTrackColor: Colors.black54,
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (val) =>
                          context.read<ThemeProvider>().toggleDarkMode(val),
                      title: Text(loc.translate('theme_mode')),
                      secondary: Container(
                        height: 50,
                        width: 50,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: color.primary.withOpacity(0.1),
                        ),
                        child: Icon(Icons.dark_mode, color: color.primary),
                      ),
                    ),
                    _tile(
                      loc.translate('storage_location'),
                      _saveLocation.split('/').last,
                      color,
                      Icons.storage,
                      Icons.edit,
                      _pickSaveLocation,
                    ),
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return _tile(
                          loc.translate('language'),
                          languageProvider.locale.languageCode.toUpperCase(),
                          color,
                          Icons.language,
                          null,
                          () => _showLanguageDialog(
                            context, languageProvider, color),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 📣 SUPPORT & INFO
              _sectionTitle(
                '${loc.translate('share_file')} & ${loc.translate('privacy_policy')}',
              ),
              _card(
                color.card,
                child: Column(
                  children: [
                    // ⭐ Rate Us — featured card
                    _featuredTile(color, loc),

                    // 📱 Other Apps
                    _tile(
                      loc.translate('other_apps'),
                      null,
                      color,
                      Icons.apps,
                      Icons.open_in_new,
                      () => _launchUrl(_kDeveloperUrl),
                    ),

                    // 🔒 Privacy Policy
                    _tile(
                      loc.translate('privacy_policy'),
                      null,
                      color,
                      Icons.privacy_tip_outlined,
                      Icons.arrow_forward_ios,
                      () => _launchUrl(_kPrivacyPolicyUrl),
                    ),

                    // 📜 Terms & Conditions
                    _tile(
                      loc.translate('terms'),
                      null,
                      color,
                      Icons.gavel_outlined,
                      Icons.arrow_forward_ios,
                      _openTerms,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "${loc.translate('version').toUpperCase()} 1.0.0 (1) • A Product by - REDPDF",
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.primary.withOpacity(0.1),
          ),
          child: Icon(icon1, color: color.primary),
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
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _featuredTile(AppColors color, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primary, color.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _launchUrl(_kPlayStoreUrl),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('rate_us'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loc.translate('feedback'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
