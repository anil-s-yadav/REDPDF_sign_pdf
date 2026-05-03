import 'package:flutter/material.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  // Terms content per language
  static const Map<String, List<_TermsSection>> _content = {
    'en': _enTerms,
    'hi': _hiTerms,
    'es': _esTerms,
    'pt': _ptTerms,
    'id': _idTerms,
    'fr': _frTerms,
    'de': _deTerms,
    'ar': _arTerms,
    'ru': _ruTerms,
    'tr': _trTerms,
    'vi': _viTerms,
    'ja': _jaTerms,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.darkColors : AppTheme.lightColors;
    final locale = Localizations.localeOf(context).languageCode;
    final sections = _content[locale] ?? _enTerms;
    final isRtl = locale == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: color.bg,
        appBar: AppBar(
          backgroundColor: color.card,
          title: Text(
            AppLocalizations.of(context)!.translate('terms'),
            style: TextStyle(color: color.text, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: color.text),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.primary, color.primary.withAlpha(180)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.gavel_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('terms'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RedPDF Sign — Last updated: May 2025',
                      style: TextStyle(
                          color: Colors.white.withAlpha(200), fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            final section = sections[index - 1];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      color: color.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: TextStyle(
                        color: color.text, fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TermsSection {
  final String title;
  final String body;
  const _TermsSection(this.title, this.body);
}

// ─── English ────────────────────────────────────────────────────────────────
const List<_TermsSection> _enTerms = [
  _TermsSection('1. Acceptance of Terms',
      'By downloading or using RedPDF Sign, you agree to be bound by these Terms & Conditions. If you do not agree, please uninstall the app immediately.'),
  _TermsSection('2. Use of the App',
      'RedPDF Sign is a tool for digitally signing and managing PDF documents. You agree to use the app only for lawful purposes and in accordance with these terms.'),
  _TermsSection('3. Intellectual Property',
      'All content, design, and code within the app are the property of RedPDF. You may not copy, modify, or distribute any part of the app without written permission.'),
  _TermsSection('4. Privacy',
      'All processing happens locally on your device. We do not collect, upload, or share your documents or signatures. Please review our Privacy Policy for full details.'),
  _TermsSection('5. Disclaimer',
      'RedPDF Sign is provided "as is" without warranties of any kind. We are not responsible for any damage resulting from use or inability to use the app.'),
  _TermsSection('6. Changes',
      'We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms.'),
  _TermsSection('7. Contact',
      'For questions regarding these terms, contact us at anilyadav44x@gmail.com'),
];

// ─── Hindi ───────────────────────────────────────────────────────────────────
const List<_TermsSection> _hiTerms = [
  _TermsSection('1. शर्तों की स्वीकृति',
      'RedPDF Sign डाउनलोड या उपयोग करके, आप इन नियमों और शर्तों से बंधे होने के लिए सहमत हैं।'),
  _TermsSection('2. ऐप का उपयोग',
      'RedPDF Sign एक डिजिटल हस्ताक्षर और PDF प्रबंधन उपकरण है। आप केवल कानूनी उद्देश्यों के लिए इसका उपयोग करने के लिए सहमत हैं।'),
  _TermsSection('3. बौद्धिक संपदा',
      'ऐप की सभी सामग्री, डिज़ाइन और कोड RedPDF की संपत्ति हैं। लिखित अनुमति के बिना किसी भी भाग की नकल, संशोधन या वितरण नहीं किया जा सकता।'),
  _TermsSection('4. गोपनीयता',
      'सभी प्रसंस्करण आपके डिवाइस पर स्थानीय रूप से होता है। हम आपके दस्तावेज़ों या हस्ताक्षरों को एकत्र, अपलोड या साझा नहीं करते।'),
  _TermsSection('5. अस्वीकरण',
      'RedPDF Sign बिना किसी वारंटी के "जैसा है" प्रदान किया जाता है। हम ऐप के उपयोग से होने वाले किसी भी नुकसान के लिए जिम्मेदार नहीं हैं।'),
  _TermsSection('6. परिवर्तन',
      'हम किसी भी समय इन शर्तों को संशोधित करने का अधिकार सुरक्षित रखते हैं।'),
  _TermsSection('7. संपर्क', 'प्रश्नों के लिए: anilyadav44x@gmail.com'),
];

// ─── Spanish ──────────────────────────────────────────────────────────────────
const List<_TermsSection> _esTerms = [
  _TermsSection('1. Aceptación de términos',
      'Al descargar o usar RedPDF Sign, aceptas estar sujeto a estos Términos y Condiciones.'),
  _TermsSection('2. Uso de la aplicación',
      'RedPDF Sign es una herramienta para firmar y gestionar documentos PDF digitalmente. Aceptas usarla solo para fines lícitos.'),
  _TermsSection('3. Propiedad intelectual',
      'Todo el contenido, diseño y código de la aplicación son propiedad de RedPDF.'),
  _TermsSection('4. Privacidad',
      'Todo el procesamiento ocurre localmente en tu dispositivo. No recopilamos, subimos ni compartimos tus documentos.'),
  _TermsSection('5. Exención de responsabilidad',
      'RedPDF Sign se proporciona "tal cual" sin garantías de ningún tipo.'),
  _TermsSection('6. Cambios',
      'Nos reservamos el derecho de modificar estos términos en cualquier momento.'),
  _TermsSection('7. Contacto', 'Para consultas: anilyadav44x@gmail.com'),
];

// ─── Portuguese ───────────────────────────────────────────────────────────────
const List<_TermsSection> _ptTerms = [
  _TermsSection('1. Aceitação dos Termos',
      'Ao baixar ou usar o RedPDF Sign, você concorda em estar vinculado a estes Termos e Condições.'),
  _TermsSection('2. Uso do Aplicativo',
      'RedPDF Sign é uma ferramenta para assinar e gerenciar documentos PDF digitalmente.'),
  _TermsSection('3. Propriedade Intelectual',
      'Todo o conteúdo, design e código do aplicativo são propriedade da RedPDF.'),
  _TermsSection('4. Privacidade',
      'Todo o processamento ocorre localmente no seu dispositivo. Não coletamos nem compartilhamos seus documentos.'),
  _TermsSection('5. Isenção de Responsabilidade',
      'O RedPDF Sign é fornecido "como está" sem garantias de qualquer tipo.'),
  _TermsSection('6. Alterações',
      'Reservamo-nos o direito de modificar estes termos a qualquer momento.'),
  _TermsSection('7. Contato', 'Para dúvidas: anilyadav44x@gmail.com'),
];

// ─── Indonesian ───────────────────────────────────────────────────────────────
const List<_TermsSection> _idTerms = [
  _TermsSection('1. Penerimaan Syarat',
      'Dengan mengunduh atau menggunakan RedPDF Sign, Anda setuju untuk terikat oleh Syarat & Ketentuan ini.'),
  _TermsSection('2. Penggunaan Aplikasi',
      'RedPDF Sign adalah alat untuk menandatangani dan mengelola dokumen PDF secara digital.'),
  _TermsSection('3. Kekayaan Intelektual',
      'Semua konten, desain, dan kode dalam aplikasi adalah milik RedPDF.'),
  _TermsSection('4. Privasi',
      'Semua pemrosesan terjadi secara lokal di perangkat Anda. Kami tidak mengumpulkan atau berbagi dokumen Anda.'),
  _TermsSection('5. Penafian',
      'RedPDF Sign disediakan "apa adanya" tanpa jaminan apa pun.'),
  _TermsSection('6. Perubahan',
      'Kami berhak mengubah ketentuan ini kapan saja.'),
  _TermsSection('7. Kontak', 'Hubungi kami: anilyadav44x@gmail.com'),
];

// ─── French ───────────────────────────────────────────────────────────────────
const List<_TermsSection> _frTerms = [
  _TermsSection("1. Acceptation des conditions",
      "En téléchargeant ou utilisant RedPDF Sign, vous acceptez d'être lié par ces Termes et Conditions."),
  _TermsSection("2. Utilisation de l'application",
      "RedPDF Sign est un outil pour signer et gérer des documents PDF numériquement."),
  _TermsSection('3. Propriété intellectuelle',
      "Tout le contenu, la conception et le code de l'application appartiennent à RedPDF."),
  _TermsSection('4. Confidentialité',
      'Tout le traitement se fait localement sur votre appareil. Nous ne collectons ni ne partageons vos documents.'),
  _TermsSection('5. Avertissement',
      'RedPDF Sign est fourni "tel quel" sans garanties d\'aucune sorte.'),
  _TermsSection('6. Modifications',
      'Nous nous réservons le droit de modifier ces conditions à tout moment.'),
  _TermsSection('7. Contact', 'Pour toute question: anilyadav44x@gmail.com'),
];

// ─── German ───────────────────────────────────────────────────────────────────
const List<_TermsSection> _deTerms = [
  _TermsSection('1. Annahme der Bedingungen',
      'Durch das Herunterladen oder Verwenden von RedPDF Sign stimmen Sie diesen Nutzungsbedingungen zu.'),
  _TermsSection('2. Nutzung der App',
      'RedPDF Sign ist ein Tool zum digitalen Unterzeichnen und Verwalten von PDF-Dokumenten.'),
  _TermsSection('3. Geistiges Eigentum',
      'Alle Inhalte, Designs und Code der App sind Eigentum von RedPDF.'),
  _TermsSection('4. Datenschutz',
      'Alle Verarbeitungen erfolgen lokal auf Ihrem Gerät. Wir sammeln oder teilen Ihre Dokumente nicht.'),
  _TermsSection('5. Haftungsausschluss',
      'RedPDF Sign wird "wie besehen" ohne jegliche Garantien bereitgestellt.'),
  _TermsSection('6. Änderungen',
      'Wir behalten uns das Recht vor, diese Bedingungen jederzeit zu ändern.'),
  _TermsSection('7. Kontakt', 'Bei Fragen: anilyadav44x@gmail.com'),
];

// ─── Arabic ───────────────────────────────────────────────────────────────────
const List<_TermsSection> _arTerms = [
  _TermsSection('١. قبول الشروط',
      'بتنزيل أو استخدام RedPDF Sign، فإنك توافق على الالتزام بهذه الشروط والأحكام.'),
  _TermsSection('٢. استخدام التطبيق',
      'RedPDF Sign هو أداة للتوقيع الرقمي وإدارة ملفات PDF. توافق على استخدامه للأغراض القانونية فقط.'),
  _TermsSection('٣. الملكية الفكرية',
      'جميع المحتويات والتصاميم والرموز البرمجية في التطبيق هي ملك لـ RedPDF.'),
  _TermsSection('٤. الخصوصية',
      'تتم جميع المعالجات محليًا على جهازك. نحن لا نجمع أو نشارك مستنداتك.'),
  _TermsSection('٥. إخلاء المسؤولية',
      'يُقدَّم RedPDF Sign "كما هو" دون أي ضمانات من أي نوع.'),
  _TermsSection('٦. التغييرات',
      'نحتفظ بالحق في تعديل هذه الشروط في أي وقت.'),
  _TermsSection('٧. التواصل', 'للاستفسارات: anilyadav44x@gmail.com'),
];

// ─── Russian ──────────────────────────────────────────────────────────────────
const List<_TermsSection> _ruTerms = [
  _TermsSection('1. Принятие условий',
      'Загружая или используя RedPDF Sign, вы соглашаетесь соблюдать настоящие Условия и положения.'),
  _TermsSection('2. Использование приложения',
      'RedPDF Sign — инструмент для цифровой подписи и управления PDF-документами.'),
  _TermsSection('3. Интеллектуальная собственность',
      'Всё содержимое, дизайн и код приложения являются собственностью RedPDF.'),
  _TermsSection('4. Конфиденциальность',
      'Вся обработка происходит локально на вашем устройстве. Мы не собираем и не передаём ваши документы.'),
  _TermsSection('5. Отказ от ответственности',
      'RedPDF Sign предоставляется «как есть» без каких-либо гарантий.'),
  _TermsSection('6. Изменения',
      'Мы оставляем за собой право изменять эти условия в любое время.'),
  _TermsSection('7. Контакты', 'По вопросам: anilyadav44x@gmail.com'),
];

// ─── Turkish ──────────────────────────────────────────────────────────────────
const List<_TermsSection> _trTerms = [
  _TermsSection('1. Koşulların Kabulü',
      'RedPDF Sign\'ı indirerek veya kullanarak bu Şartlar ve Koşullar\'a uymayı kabul etmiş olursunuz.'),
  _TermsSection('2. Uygulamanın Kullanımı',
      'RedPDF Sign, PDF belgelerini dijital olarak imzalamak ve yönetmek için bir araçtır.'),
  _TermsSection('3. Fikri Mülkiyet',
      'Uygulamadaki tüm içerik, tasarım ve kod RedPDF\'e aittir.'),
  _TermsSection('4. Gizlilik',
      'Tüm işlemler cihazınızda yerel olarak gerçekleşir. Belgelerinizi toplamaz veya paylaşmayız.'),
  _TermsSection('5. Sorumluluk Reddi',
      'RedPDF Sign herhangi bir garanti olmaksızın "olduğu gibi" sunulmaktadır.'),
  _TermsSection('6. Değişiklikler',
      'Bu koşulları istediğimiz zaman değiştirme hakkını saklı tutarız.'),
  _TermsSection('7. İletişim', 'Sorularınız için: anilyadav44x@gmail.com'),
];

// ─── Vietnamese ───────────────────────────────────────────────────────────────
const List<_TermsSection> _viTerms = [
  _TermsSection('1. Chấp nhận điều khoản',
      'Bằng cách tải xuống hoặc sử dụng RedPDF Sign, bạn đồng ý bị ràng buộc bởi các Điều khoản và Điều kiện này.'),
  _TermsSection('2. Sử dụng ứng dụng',
      'RedPDF Sign là công cụ ký số và quản lý tài liệu PDF.'),
  _TermsSection('3. Sở hữu trí tuệ',
      'Tất cả nội dung, thiết kế và mã trong ứng dụng là tài sản của RedPDF.'),
  _TermsSection('4. Quyền riêng tư',
      'Tất cả quá trình xử lý diễn ra cục bộ trên thiết bị của bạn. Chúng tôi không thu thập hay chia sẻ tài liệu của bạn.'),
  _TermsSection('5. Tuyên bố miễn trách nhiệm',
      'RedPDF Sign được cung cấp "nguyên trạng" không có bảo hành dưới bất kỳ hình thức nào.'),
  _TermsSection('6. Thay đổi',
      'Chúng tôi có quyền sửa đổi các điều khoản này bất kỳ lúc nào.'),
  _TermsSection('7. Liên hệ', 'Mọi thắc mắc: anilyadav44x@gmail.com'),
];

// ─── Japanese ─────────────────────────────────────────────────────────────────
const List<_TermsSection> _jaTerms = [
  _TermsSection('1. 利用規約への同意',
      'RedPDF Signをダウンロードまたは使用することで、これらの利用規約に同意したものとみなされます。'),
  _TermsSection('2. アプリの利用',
      'RedPDF SignはPDF文書にデジタル署名し、管理するためのツールです。'),
  _TermsSection('3. 知的財産',
      'アプリ内のすべてのコンテンツ、デザイン、コードはRedPDFの所有物です。'),
  _TermsSection('4. プライバシー',
      'すべての処理はお使いのデバイス上でローカルに行われます。文書を収集・共有することはありません。'),
  _TermsSection('5. 免責事項',
      'RedPDF Signはいかなる保証もなく「現状のまま」提供されます。'),
  _TermsSection('6. 変更',
      'いつでもこれらの規約を変更する権利を留保します。'),
  _TermsSection('7. お問い合わせ', 'ご質問は: anilyadav44x@gmail.com'),
];
