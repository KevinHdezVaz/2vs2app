import 'package:flutter/material.dart';

class ChatSession {
  final int id;
  final int userId;
  final String title;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    this.isSaved = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    try {
      return ChatSession(
        id: int.tryParse(json['id'].toString()) ?? -1,
        userId: int.tryParse(json['user_id'].toString()) ?? -1,
        title: json['title']?.toString() ?? 'Sin título',
        isSaved: json['is_saved'] is bool
            ? json['is_saved']
            : (json['is_saved'] == 1 || json['is_saved'].toString() == 'true'),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        deletedAt: json['deleted_at'] != null
            ? DateTime.tryParse(json['deleted_at'].toString())
            : null,
      );
    } catch (e) {
      throw FormatException('Error parsing ChatSession: $e');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'is_saved': isSaved,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  ChatSession copyWith({
    int? id,
    int? userId,
    String? title,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;

  @override
  String toString() {
    return 'ChatSession{id: $id, userId: $userId, title: $title, '
        'isSaved: $isSaved, createdAt: $createdAt, '
        'updatedAt: $updatedAt, deletedAt: $deletedAt}';
  }
}
