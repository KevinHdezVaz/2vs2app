class Miembro {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImage;
  final bool verified;
  final String? posicion;
  final MiembroPivot pivot;

  Miembro({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profileImage,
    required this.verified,
    this.posicion,
    required this.pivot,
  });

  factory Miembro.fromJson(Map<String, dynamic> json) {
    return Miembro(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profileImage: json['profile_image']?.toString(),
      verified: json['verified'] == 1 || json['verified'] == true,
      posicion: json['posicion']?.toString(),
      pivot: MiembroPivot.fromJson(json['pivot'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MiembroPivot {
  final int equipoId;
  final int userId;
  final String rol;
  final String estado;
  final String? posicion;

  MiembroPivot({
    required this.equipoId,
    required this.userId,
    required this.rol,
    required this.estado,
    this.posicion,
  });

  factory MiembroPivot.fromJson(Map<String, dynamic> json) {
    return MiembroPivot(
      equipoId: json['equipo_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      rol: json['rol']?.toString() ?? 'miembro',
      estado: json['estado']?.toString() ?? 'pendiente',
      posicion: json['posicion']?.toString(),
    );
  }
} 