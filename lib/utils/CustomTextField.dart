import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final Function(String) onChanged;
  final TextInputType? keyboardType;
  final String? initialValue;
  final TextEditingController? controller;
  final String? errorText;
  final String? emoji; // Nuevo parámetro para el emoji

  const CustomTextField({
    super.key,
    required this.label,
    required this.onChanged,
    this.keyboardType,
    this.initialValue,
    this.controller,
    this.errorText,
    this.emoji, // Emoji opcional
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: FrutiaColors.primaryText),
      decoration: InputDecoration(
        labelText:
            emoji != null ? '$emoji $label' : label, // Combina emoji y label
        labelStyle: const TextStyle(color: FrutiaColors.secondaryText),
        errorText: errorText,
        filled: true,
        fillColor: FrutiaColors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: FrutiaColors.disabledText.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FrutiaColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
