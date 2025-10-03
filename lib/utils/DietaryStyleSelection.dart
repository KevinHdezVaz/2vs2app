import 'package:Frutia/utils/ChoiceChipCard.dart';
import 'package:Frutia/utils/CustomTextField.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class DietaryStyleSelection extends StatelessWidget {
  final String name;
  final String? initialValue;

  const DietaryStyleSelection({
    super.key,
    required this.name,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    const predefinedStyles = {
      'Omnívoro': Icons.restaurant_menu,
      'Vegetariano': Icons.eco,
      'Vegano': Icons.grass,
      'Keto': Icons.egg_alt_outlined,
    };

    return FormBuilderField<String>(
      name: name,
      initialValue: initialValue ?? 'Omnívoro',
      validator: FormBuilderValidators.required(
          errorText: 'Por favor, selecciona un estilo.'),
      builder: (FormFieldState<String> field) {
        bool isOtherSelected =
            field.value != null && !predefinedStyles.keys.contains(field.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: [
                ...predefinedStyles.entries.map((entry) {
                  return ChoiceChipCard(
                    label: entry.key,
                    icon: entry.value,
                    isSelected: field.value == entry.key,
                    onTap: () => field.didChange(entry.key),
                  );
                }).toList(),
                ChoiceChipCard(
                  label: 'Otro',
                  icon: Icons.edit_note_rounded,
                  isSelected: isOtherSelected,
                  onTap: () => field.didChange(''),
                ),
              ],
            ),
            if (isOtherSelected)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: CustomTextField(
                  label: 'Especifica tu estilo',
                  initialValue: field.value,
                  onChanged: (newValue) => field.didChange(newValue),
                ),
              ),
          ],
        );
      },
    );
  }
}
