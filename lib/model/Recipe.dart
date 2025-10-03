// models/recipe.dart
class Recipe {
  final String id;
  final String title;
  final String description;
  final String mealType; // 'desayuno', 'almuerzo', 'cena', 'snack'
  final int prepTime;
  final int calories;
  final Map<String, dynamic> macros;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String? imageUrl;
  final String? videoUrl;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.mealType,
    required this.prepTime,
    required this.calories,
    required this.macros,
    required this.ingredients,
    required this.instructions,
    this.tags = const [],
    this.imageUrl,
    this.videoUrl,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? '',
      mealType: json['meal_type'] ?? 'desayuno',
      prepTime: json['prep_time'] ?? 0,
      calories: json['calories'] ?? 0,
      macros: json['macros'] ?? {'carbs': 0, 'protein': 0, 'fat': 0},
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
    );
  }
}
