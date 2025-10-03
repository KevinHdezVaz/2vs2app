import 'dart:convert';

class Notificacion {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final List<String>? playerIds;
  final bool read; // Nueva propiedad

  Notificacion({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.playerIds,
    required this.read, // Incluir en el constructor
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      playerIds: json['player_ids'] != null
          ? (json['player_ids'] is String
              ? List<String>.from(jsonDecode(json['player_ids']))
              : List<String>.from(json['player_ids']))
          : null,
      read: json['read'] ?? false, // Manejar el valor de 'read'
    );
  }
}
