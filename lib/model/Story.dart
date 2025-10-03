class Story {
  final int id;
  final String title;
  final String imageUrl;
  final String? videoUrl;
  final bool isActive;
  final DateTime expiresAt;
  final Map<String, dynamic>? administrator;

  Story({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.videoUrl,
    required this.isActive,
    required this.expiresAt,
    this.administrator,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'], // La URL ya viene completa del backend
      videoUrl: json['video_url'],
      isActive: json['is_active'] ?? true,
      expiresAt: DateTime.parse(json['expires_at']),
      administrator: json['administrator'],
    );
  }
}