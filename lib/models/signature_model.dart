import 'dart:convert';

class SignatureModel {
  final String id;
  final String type; // 'draw', 'image', 'text'
  final String? path; // for image/draw
  final String? text; // for text
  final String? font; // for text
  final int? color; // for text color (ARGB)
  final DateTime createdAt;

  SignatureModel({
    required this.id,
    required this.type,
    this.path,
    this.text,
    this.font,
    this.color,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'path': path,
      'text': text,
      'font': font,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SignatureModel.fromJson(Map<String, dynamic> json) {
    return SignatureModel(
      id: json['id'],
      type: json['type'],
      path: json['path'],
      text: json['text'],
      font: json['font'],
      color: json['color'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
