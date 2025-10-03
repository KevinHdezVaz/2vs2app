import 'package:flutter/material.dart';

class QuestionnaireProvider extends ChangeNotifier {
  // --- Pantalla 1: Sobre ti ---
  String name = '';
  bool hasMedicalCondition = false;
  String medicalConditionDetails = '';
  String? mainGoal;

  // --- Pantalla 2: Tu Rutina ---
  List<String> sport = [];

  // --- LÍNEAS ELIMINADAS ---
  // String? trainingFrequency;
  // String? dailyActivityLevel;

  // --- NUEVA LÍNEA ---
  String? weeklyActivity; // <--- AQUÍ SE AGREGA LA NUEVA VARIABLE

  // --- Moviendo estas variables a la sección de alimentación para mejor orden ---
  TimeOfDay? breakfastTime;
  TimeOfDay? lunchTime;
  TimeOfDay? dinnerTime;
  String? eatsOut;

  // --- Pantalla 3: Tu Alimentación ---
  String dislikedFoods = '';
  bool hasAllergies = false;
  String allergyDetails = '';
  String? dietStyle;
  String? weeklyBudget;
 
  // --- Pantalla 4: Tus Preferencias ---
  String? communicationTone;
  String? preferredName;
  Set<String> dietDifficulties = {};
  Set<String> dietMotivations = {};

  // Método para actualizar y notificar
  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  void reset() {
    name = '';
    hasMedicalCondition = false;
    medicalConditionDetails = '';
    mainGoal = null;
    sport = [];

    // --- CAMBIO EN RESET ---
    // Se eliminan las variables viejas
    // trainingFrequency = null;
    // dailyActivityLevel = null;
    // Se añade la nueva variable a limpiar
    weeklyActivity = null;

    breakfastTime = null;
    lunchTime = null;
    dinnerTime = null;
    eatsOut = null;
    dislikedFoods = '';
    hasAllergies = false;
    allergyDetails = '';
    dietStyle = null;
    weeklyBudget = null;
     communicationTone = null;
    preferredName = null;
    dietDifficulties = {};
    dietMotivations = {};
    notifyListeners();
  }

  // Para debugging
  void printSummary() {
    debugPrint('----- RESUMEN COMPLETO DEL CUESTIONARIO -----');
    debugPrint('Nombre: $name');
    debugPrint(
        'Condición Médica: $hasMedicalCondition, Detalles: $medicalConditionDetails');
    debugPrint('Objetivo Principal: $mainGoal');
    debugPrint('---');

    // --- CAMBIO EN EL RESUMEN ---
    debugPrint('Deporte: $sport');
    debugPrint(
        'Actividad Semanal: $weeklyActivity'); // Se muestra la nueva variable

    debugPrint('Horarios: D: $breakfastTime, A: $lunchTime, C: $dinnerTime');
    debugPrint('Come fuera: $eatsOut');
    debugPrint('---');
    debugPrint('No le gusta: $dislikedFoods');
    debugPrint('Alergias: $hasAllergies, Detalles: $allergyDetails');
    debugPrint('Estilo Dieta: $dietStyle, Presupuesto: $weeklyBudget');
     debugPrint('---');
    debugPrint('Tono: $communicationTone, Nombre preferido: $preferredName');
    debugPrint('Dificultades: $dietDifficulties');
    debugPrint('Motivaciones: $dietMotivations');
    debugPrint('------------------------------------------');
  }
}
