class PdfDocumentModel {
  final String id;
  final String title;
  final String path;
  final int sizeInBytes;
  final DateTime createdAt;

  PdfDocumentModel({
    required this.id,
    required this.title,
    required this.path,
    required this.sizeInBytes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'sizeInBytes': sizeInBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PdfDocumentModel.fromJson(Map<String, dynamic> json) {
    return PdfDocumentModel(
      id: json['id'],
      title: json['title'],
      path: json['path'],
      sizeInBytes: json['sizeInBytes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
