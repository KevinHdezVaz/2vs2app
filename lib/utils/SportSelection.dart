import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:Frutia/utils/ChoiceChipCard.dart';
import 'package:Frutia/utils/CustomTextField.dart';

class SportSelection extends StatelessWidget {
  final String name;
  final List<String>? initialValue;
  final ValueChanged<List<String>?>? onChanged;

  const SportSelection({
    super.key,
    required this.name,
    this.initialValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos los deportes con sus emojis correspondientes
    final Map<String, String> sportsWithEmojis = {
      '💪 Gym': 'Gym',
      '⚽ Fútbol': 'Fútbol',
      '🏃 Running': 'Running',
      '🎾 Tenis': 'Tenis',
      '✏️ Otro': 'Otro',
      '❌ Ninguno': 'Ninguno',
    };

    return FormBuilderField<List<String>>(
      name: name,
      initialValue: initialValue ?? [],
      onChanged: onChanged,
      builder: (FormFieldState<List<String>> field) {
        final selectedSports = field.value ?? [];
        bool isOtherSelected = selectedSports.contains('Otro');
        bool hasCustomSport = selectedSports.any((sport) =>
            !sportsWithEmojis.values.contains(sport) && sport.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: [
                ...sportsWithEmojis.entries.map((entry) {
                  final isSelected = selectedSports.contains(entry.value);
                  final isOther = entry.value == 'Otro';

                  return ChoiceChipCard(
                    label: entry.key,
                    isSelected: isSelected,
                    onTap: () {
                      final newSelection = List<String>.from(selectedSports);
                      if (isSelected) {
                        newSelection.remove(entry.value);
                        // Si deselecciona "Otro", también quitamos el deporte personalizado
                        if (isOther) {
                          newSelection.removeWhere((sport) =>
                              !sportsWithEmojis.values.contains(sport));
                        }
                      } else {
                        newSelection.add(entry.value);
                      }
                      field.didChange(newSelection);
                    },
                  );
                }).toList(),
              ],
            ),
            if (isOtherSelected || hasCustomSport)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: CustomTextField(
                  label: '✏️ Especifica tu deporte',
                  initialValue: hasCustomSport
                      ? selectedSports.firstWhere(
                          (sport) => !sportsWithEmojis.values.contains(sport),
                          orElse: () => '')
                      : null,
                  onChanged: (newValue) {
                    final newSelection = List<String>.from(selectedSports)
                      ..removeWhere(
                          (sport) => !sportsWithEmojis.values.contains(sport));

                    if (newValue != null && newValue.isNotEmpty) {
                      newSelection.add(newValue);
                    }

                    // Mantenemos "Otro" seleccionado si el campo no está vacío
                    if (newValue?.isNotEmpty == true &&
                        !newSelection.contains('Otro')) {
                      newSelection.add('Otro');
                    }

                    field.didChange(newSelection);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
