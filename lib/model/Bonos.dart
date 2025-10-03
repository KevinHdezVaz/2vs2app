class Bono {
  final int id;
  final String tipo;
  final String titulo;
  final String descripcion;
  final double precio;
  final int duracionDias;
  final List<String> caracteristicas;
  final bool isActive;
  final String? imagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bono({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.duracionDias,
    required this.caracteristicas,
    this.isActive = true,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory Bono.fromJson(Map<String, dynamic> json) {
    return Bono(
      id: json['id'],
      tipo: json['tipo'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      precio: double.parse(json['precio'].toString()),
      duracionDias: json['duracion_dias'],
      caracteristicas: List<String>.from(json['caracteristicas']),
      isActive: json['is_active'] ?? true,
      imagePath: json['image_path'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'duracion_dias': duracionDias,
      'caracteristicas': caracteristicas,
      'is_active': isActive,
      'image_path': imagePath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}