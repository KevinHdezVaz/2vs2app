import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChoiceChipCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const ChoiceChipCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FrutiaColors.accent
              : FrutiaColors.secondaryBackground,
          borderRadius: BorderRadius.circular(
              50), // Bordes redondeados para estilo "pill"
          border: Border.all(
            color: isSelected ? FrutiaColors.accent : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FrutiaColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : FrutiaColors.secondaryText,
              ),
            if (icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 15,
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
