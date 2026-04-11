import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/signature_model.dart';

class SignatureProvider with ChangeNotifier {
  List<SignatureModel> _signatures = [];
  bool _isLoading = true;

  List<SignatureModel> get signatures => _signatures;
  bool get isLoading => _isLoading;

  SignatureProvider() {
    loadSignatures();
  }

  Future<void> loadSignatures() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? sigsJson = prefs.getString('signatures');
    
    if (sigsJson != null) {
      final List<dynamic> decoded = json.decode(sigsJson);
      _signatures = decoded.map((item) => SignatureModel.fromJson(item)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSignature(SignatureModel signature) async {
    _signatures.insert(0, signature);
    notifyListeners();
    await _saveSignatures();
  }

  Future<void> removeSignature(String id) async {
    final signature = _signatures.firstWhere((s) => s.id == id);
    if (signature.path != null) {
      final file = File(signature.path!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _signatures.removeWhere((s) => s.id == id);
    notifyListeners();
    await _saveSignatures();
  }

  Future<void> clearAllSignatures() async {
    for (var sig in _signatures) {
      if (sig.path != null) {
        final file = File(sig.path!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    _signatures.clear();
    notifyListeners();
    await _saveSignatures();
  }

  Future<void> _saveSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _signatures.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('signatures', encoded);
  }

  Future<String> getSignaturesPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/signatures';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }
}
