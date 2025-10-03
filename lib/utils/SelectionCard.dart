import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectionCard extends StatelessWidget {
  final String title;
  final String value;
  final String? groupValue;
  final Function(String) onTap;

  const SelectionCard({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shadowColor: isSelected
            ? FrutiaColors.accent.withOpacity(0.3)
            : Colors.black.withOpacity(0.1),
        color: FrutiaColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isSelected ? FrutiaColors.accent : Colors.grey[300]!,
              width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                  child: Text(
                title,
                style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText),
              )),
              if (isSelected)
                Icon(Icons.check_circle, color: FrutiaColors.accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
