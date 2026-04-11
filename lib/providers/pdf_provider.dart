import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_document_model.dart';

class PdfProvider with ChangeNotifier {
  List<PdfDocumentModel> _signedDocuments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<PdfDocumentModel> get signedDocuments {
    if (_searchQuery.isEmpty) return _signedDocuments;
    return _signedDocuments
        .where(
          (doc) => doc.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  PdfProvider() {
    loadSignedDocuments();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadSignedDocuments() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? docsJson = prefs.getString('signed_documents');
    
    if (docsJson != null) {
      final List<dynamic> decoded = json.decode(docsJson);
      _signedDocuments = decoded.map((item) => PdfDocumentModel.fromJson(item)).toList();
    }

    // Sort by date descending
    _signedDocuments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSignedDocument(PdfDocumentModel doc) async {
    _signedDocuments.insert(0, doc);
    notifyListeners();
    await _saveSignedDocuments();
  }

  Future<void> removeSignedDocument(String id) async {
    final doc = _signedDocuments.firstWhere((d) => d.id == id);
    final file = File(doc.path);
    if (await file.exists()) {
      await file.delete();
    }
    _signedDocuments.removeWhere((d) => d.id == id);
    notifyListeners();
    await _saveSignedDocuments();
  }

  Future<void> clearAllSignedDocuments() async {
    for (var doc in _signedDocuments) {
      final file = File(doc.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _signedDocuments.clear();
    notifyListeners();
    await _saveSignedDocuments();
  }

  Future<void> _saveSignedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _signedDocuments.map((d) => d.toJson()).toList(),
    );
    await prefs.setString('signed_documents', encoded);
  }

  Future<String> getSignedDocsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/signed_documents';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }
}
