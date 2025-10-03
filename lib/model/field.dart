import 'dart:convert';
import 'package:flutter/material.dart';

class Field {
  final int id;
  final String name;
  final String description;
  final String? municipio; // Hacerlo nullable
  final double? latitude;
  final double? longitude;
  final bool is_active;
  final List<String> types; // Lista de strings para tipos
  final Map<String, List<String>> available_hours;
  final List<String>? amenities;
  final List<String>? images;
  final double price_per_match;

  Field({
    required this.id,
    required this.name,
    required this.description,
    this.municipio,
    this.latitude,
    this.longitude,
    required this.is_active,
    required this.types, // Lista requerida, pero puede ser vacía
    required this.available_hours,
    this.amenities,
    this.images,
    required this.price_per_match,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    debugPrint('\n=== PARSEANDO CAMPO ===');
    debugPrint('JSON recibido: $json');

    final lat = json['latitude'];
    final lng = json['longitude'];

    debugPrint('Latitude raw: $lat (${lat.runtimeType})');
    debugPrint('Longitude raw: $lng (${lng.runtimeType})');

    final parsedLat = lat != null ? double.tryParse(lat.toString()) : null;
    final parsedLng = lng != null ? double.tryParse(lng.toString()) : null;

    debugPrint('Latitude parsed: $parsedLat');
    debugPrint('Longitude parsed: $parsedLng');

    // Procesar types de manera flexible
    final typesData = json['types'];
    final types = _parseTypes(typesData);

    // Procesar imágenes
    List<String>? imagesList;
    var imagesData = json['images'];
    try {
      if (imagesData != null) {
        if (imagesData is String) {
          imagesList = List<String>.from(jsonDecode(imagesData));
        } else if (imagesData is List) {
          imagesList = imagesData.map((e) => e.toString()).toList();
        }
        debugPrint('Lista de imágenes procesada: $imagesList');
      }
    } catch (e) {
      print('Error procesando imágenes: $e');
      imagesList = null;
    }

    // Procesar available_hours
    Map<String, List<String>> processedHours = {};
    var availableHours = json['available_hours'];
    try {
      if (availableHours != null) {
        if (availableHours is String) {
          if (availableHours != '[]') {
            var decodedHours = jsonDecode(availableHours);
            if (decodedHours is Map) {
              decodedHours.forEach((key, value) {
                if (value is List) {
                  processedHours[key.toString()] = List<String>.from(value);
                }
              });
            }
          }
        } else if (availableHours is Map) {
          availableHours.forEach((key, value) {
            if (value is List) {
              processedHours[key.toString()] = List<String>.from(value);
            }
          });
        }
      }
    } catch (e) {
      print('Error procesando available_hours: $e');
      processedHours = {};
    }

    // Procesar amenities
    List<String>? amenitiesList;
    try {
      var amenities = json['amenities'];
      if (amenities != null) {
        if (amenities is String) {
          amenitiesList = List<String>.from(jsonDecode(amenities));
        } else if (amenities is List) {
          amenitiesList = List<String>.from(amenities);
        }
      }
    } catch (e) {
      print('Error procesando amenities: $e');
      amenitiesList = null;
    }

    return Field(
      id: json['id'] as int? ?? 0, // Valor por defecto si id falta
      name: json['name'] as String? ?? 'Sin nombre', // Maneja null
      description: json['description'] as String? ?? '', // Maneja null
      municipio: json['municipio'] as String?, // Nullable
      latitude: parsedLat,
      longitude: parsedLng,
      is_active: json['is_active'] as bool? ?? true, // Valor por defecto
      types: types,
      available_hours: processedHours,
      amenities: amenitiesList,
      images: imagesList,
      price_per_match: double.tryParse(json['price_per_match']?.toString() ?? '0') ?? 0.0,
    );
  }

static List<String> _parseTypes(dynamic typesData) {
  if (typesData == null) return [];

  // Si typesData es una cadena, intentar parsearla como JSON
  if (typesData is String) {
    try {
      // Eliminar comillas adicionales si es necesario
      if (typesData.startsWith('"') && typesData.endsWith('"')) {
        typesData = typesData.substring(1, typesData.length - 1);
      }

      // Parsear la cadena JSON
      final parsedData = jsonDecode(typesData);
      if (parsedData is List) {
        return List<String>.from(parsedData);
      } else if (parsedData is String) {
        return [parsedData];
      }
    } catch (e) {
      print('Error parsing types: $e');
    }
  }

  // Si typesData es una lista, convertirla a List<String>
  if (typesData is List) {
    return typesData.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  // Valor por defecto si no es ni cadena ni lista
  return [];
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'municipio': municipio,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': is_active,
      'types': types,
      'available_hours': available_hours,
      'amenities': amenities,
      'images': images,
      'price_per_match': price_per_match,
    };
  }
}