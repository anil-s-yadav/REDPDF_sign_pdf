import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Saves PDF files to the public Downloads/RedPdf_sign/ folder
/// using MediaStore API (no storage permissions required on Android 10+).
class DownloadHelper {
  static const _channel = MethodChannel('com.redpdf/download');

  /// Saves [bytes] as a PDF to Downloads/RedPdf_sign/[fileName].
  /// Returns the file path on success.
  /// Falls back to app documents directory if MediaStore fails.
  static Future<String> savePdfToDownloads({
    required Uint8List bytes,
    required String fileName,
    String subDir = 'RedPdf_sign',
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': bytes,
        'fileName': fileName,
        'subDir': subDir,
      });
      return result!;
    } catch (e) {
      // Fallback: save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory('${appDir.path}/$subDir');
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      final file = File('${fallbackDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  }
}
