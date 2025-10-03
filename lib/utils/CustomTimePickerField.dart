import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeSelectorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay? selectedTime; // Ahora recibe y devuelve un TimeOfDay
  final ValueChanged<TimeOfDay?> onTimeSelected;

  const TimeSelectorCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),

          // --- AQUÍ ESTÁ LA MAGIA PARA CAMBIAR LOS COLORES ---
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: FrutiaColors.secondaryBackground,
                  hourMinuteTextColor: FrutiaColors.primaryText,
                  hourMinuteColor: FrutiaColors.accent.withOpacity(0.1),
                  dialHandColor: FrutiaColors.accent,
                  dialBackgroundColor: FrutiaColors.primaryBackground,
                  dayPeriodTextColor: FrutiaColors.primaryText,
                  dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                      states.contains(MaterialState.selected)
                          ? FrutiaColors.accent
                          : FrutiaColors.primaryBackground),
                  helpTextStyle:
                      const TextStyle(color: FrutiaColors.primaryText),
                  confirmButtonStyle: TextButton.styleFrom(
                    foregroundColor: FrutiaColors.accent,
                  ),
                  cancelButtonStyle: TextButton.styleFrom(
                    foregroundColor: FrutiaColors.secondaryText,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        // Devolvemos el objeto TimeOfDay completo
        if (pickedTime != null) {
          onTimeSelected(pickedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: FrutiaColors.secondaryText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: Icon(icon, color: FrutiaColors.accent),
          suffixIcon: selectedTime != null
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => onTimeSelected(null),
                )
              : null,
        ),
        child: Text(
          // Usamos .format(context) para mostrar la hora y el minuto de forma localizada
          selectedTime?.format(context) ?? 'Seleccionar hora',
          style: GoogleFonts.lato(
            color:
                selectedTime != null ? FrutiaColors.primaryText : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
