import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GenderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String? selectedValue;
  final Function(String) onTap;

  const GenderCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? FrutiaColors.accent2
              : FrutiaColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FrutiaColors.accent
                : FrutiaColors.disabledText.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FrutiaColors.accent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 40,
                color: isSelected ? Colors.white : FrutiaColors.secondaryText),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : FrutiaColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
