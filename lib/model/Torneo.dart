import 'dart:convert';

class Torneo {
  final int id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final int maximoEquipos;
  final int minimoEquipos;
  final double cuotaInscripcion;
  final String? premio;
  final List<String>? imagenesTorneo;
  final String formato;

  Torneo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.maximoEquipos,
    required this.minimoEquipos,
    required this.cuotaInscripcion,
    required this.imagenesTorneo,
    this.premio,
    required this.formato,
  });

  factory Torneo.fromJson(Map<String, dynamic> json) {
    print('JSON recibido: $json');

    List<String>? imagenes;
    if (json['imagenesTorneo'] != null) {
      if (json['imagenesTorneo'] is List) {
        // Ahora las URLs ya vienen completas del backend
        imagenes = List<String>.from(json['imagenesTorneo']);
      }
      print('URLs de imágenes procesadas: $imagenes');
    }

    return Torneo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : DateTime.now(),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : DateTime.now(),
      estado: json['estado'] ?? '',
      maximoEquipos: json['maximo_equipos'] ?? 0,
      minimoEquipos: json['minimo_equipos'] ?? 0,
      cuotaInscripcion:
          double.parse((json['cuota_inscripcion'] ?? '0').toString()),
      imagenesTorneo: imagenes,
      premio: json['premio'],
      formato: json['formato'] ?? '',
    );
  }
}
