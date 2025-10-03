
// Clase para manejar recomendaciones con colores
import 'package:flutter/material.dart';

class RecommendationItem {
  final String text;
  final Color color;
  final IconData mealIcon;
  final IconData macroIcon;

  RecommendationItem({
    required this.text,
    required this.color,
    required this.mealIcon,
    required this.macroIcon,
  });
}
 