import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: Colors.white,
    primary: Colors.black, // Celeste principal
    secondary: Color(0xFFA8D5FF), // Celeste claro
    onPrimary: Colors.black, // Celeste oscuro
    onSecondary: Color(0xFFE8F4FF), // Gris muy claro
    onSurface: Colors.black, // Celeste brillante
    background: Color(0xFFF5F5F5), // Blanco hueso
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: Colors.white,
    primary: Colors.white,
    secondary: Color.fromARGB(255, 238, 238, 238),
  ),
);
