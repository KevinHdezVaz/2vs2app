// lib/utils/custom_checkbox.dart
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';

class CustomCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final IconData? icon;
  final bool
      isListTile; // Para decidir si usar CheckboxListTile o Checkbox simple

  const CustomCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.isListTile = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isListTile) {
      return CheckboxListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: const TextStyle(
            color: FrutiaColors.primaryText,
            fontSize: 16,
          ),
        ),
        secondary:
            icon != null ? Icon(icon, color: FrutiaColors.secondaryText) : null,
        value: value,
        onChanged: onChanged,
        activeColor: FrutiaColors.accent,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: FrutiaColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: FrutiaColors.primaryText,
              fontSize: 16,
            ),
          ),
        ],
      );
    }
  }
}
