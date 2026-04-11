// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// enum PdfPageSize { a4, letter, a3, legal }

// enum PdfPageOrientation { portrait, landscape }

// class SettingsProvider with ChangeNotifier {
//   PdfPageSize _defaultPageSize = PdfPageSize.a4;
//   PdfPageOrientation _defaultOrientation = PdfPageOrientation.portrait;

//   PdfPageSize get defaultPageSize => _defaultPageSize;
//   PdfPageOrientation get defaultOrientation => _defaultOrientation;

//   SettingsProvider() {
//     _loadSettings();
//   }

//   Future<void> _loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     _defaultPageSize = PdfPageSize.values[prefs.getInt('defaultPageSize') ?? 0];
//     _defaultOrientation =
//         PdfPageOrientation.values[prefs.getInt('defaultOrientation') ?? 0];
//     notifyListeners();
//   }

//   Future<void> setDefaultPageSize(PdfPageSize size) async {
//     _defaultPageSize = size;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('defaultPageSize', size.index);
//     notifyListeners();
//   }

//   Future<void> setDefaultOrientation(PdfPageOrientation orientation) async {
//     _defaultOrientation = orientation;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('defaultOrientation', orientation.index);
//     notifyListeners();
//   }

//   // Helper strings for UI
//   String get pageSizeString {
//     switch (_defaultPageSize) {
//       case PdfPageSize.a4:
//         return 'A4';
//       case PdfPageSize.letter:
//         return 'Letter';
//       case PdfPageSize.a3:
//         return 'A3';
//       case PdfPageSize.legal:
//         return 'Legal';
//     }
//   }

//   String get orientationString {
//     switch (_defaultOrientation) {
//       case PdfPageOrientation.portrait:
//         return 'Portrait';
//       case PdfPageOrientation.landscape:
//         return 'Landscape';
//     }
//   }
// }
