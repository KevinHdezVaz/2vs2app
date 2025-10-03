import 'package:flutter/material.dart';

class ChatMessage {
  final int id;
  final int chatSessionId;
  final int? userId;
  final String? text; // <-- MODIFICADO: Ahora puede ser nulo
  final String? imagePath; // <-- AÑADIDO: Para la ruta de la imagen local
  final String?
      imageUrl; // <-- MANTENIDO: Para la URL de la imagen en el servidor
  final bool isUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? analysisData;

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    this.userId,
    this.text,
    this.imagePath,
    this.imageUrl,
    this.analysisData, // <-- Añadido al constructor

    required this.isUser,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(
            text != null ||
                imagePath != null ||
                imageUrl != null ||
                analysisData != null, // <-- Añadida la nueva condición
            'Un mensaje debe tener contenido (texto, imagen o datos de análisis).');

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.tryParse(json['id'].toString()) ?? -1,
      chatSessionId: int.tryParse(json['chat_session_id'].toString()) ?? -1,
      userId: json['user_id'] != null
          ? int.tryParse(json['user_id'].toString())
          : null,
      text:
          json['text'] as String?, // <-- MODIFICADO: Acepta nulos directamente
      isUser: json['is_user'] is bool
          ? json['is_user']
          : (json['is_user'] == 1 || json['is_user'].toString() == 'true'),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      // Nota: 'imagePath' no se incluye aquí porque es una propiedad local del cliente,
      // no algo que vendría en el JSON del servidor.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'user_id': userId,
      'text': text,
      'is_user': isUser,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Nota: 'imagePath' tampoco se envía al servidor en el JSON. La imagen se subiría
      // por separado (ej. como multipart/form-data).
    };
  }
}
