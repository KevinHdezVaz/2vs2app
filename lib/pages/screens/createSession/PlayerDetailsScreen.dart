// SCREEN 3: Player Details
import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final SessionData sessionData;
  final VoidCallback onBack;
  final VoidCallback onStartSession;

  const PlayerDetailsScreen({
    super.key,
    required this.sessionData,
    required this.onBack,
    required this.onStartSession,
  });

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late List<TextEditingController> _firstNameControllers;
  late List<TextEditingController> _lastInitialControllers;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _firstNameControllers = List.generate(
      widget.sessionData.numberOfPlayers,
      (index) => TextEditingController(),
    );
    _lastInitialControllers = List.generate(
      widget.sessionData.numberOfPlayers,
      (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in _firstNameControllers) {
      controller.dispose();
    }
    for (var controller in _lastInitialControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _areAllPlayersFilled() {
    for (int i = 0; i < widget.sessionData.numberOfPlayers; i++) {
      if (_firstNameControllers[i].text.isEmpty ||
          _lastInitialControllers[i].text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player Details',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter player information',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: FrutiaColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),

          // Toggle advanced settings
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Advanced Settings',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.primaryText,
                ),
              ),
              Switch(
                value: _showAdvancedSettings,
                activeColor: FrutiaColors.primary,
                onChanged: (value) {
                  setState(() {
                    _showAdvancedSettings = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Player list
          Container(
            decoration: BoxDecoration(
              color: FrutiaColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.sessionData.numberOfPlayers,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: FrutiaColors.tertiaryBackground,
              ),
              itemBuilder: (context, index) {
                return _buildPlayerRow(index);
              },
            ),
          ),

          const SizedBox(height: 32),

          // Navigation buttons - CORREGIDOS para misma altura
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56, // Altura fija para ambos botones
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: FrutiaColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back: Court Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56, // Misma altura fija
                  child: ElevatedButton(
                    onPressed:
                        _areAllPlayersFilled() ? widget.onStartSession : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrutiaColors.accent,
                      disabledBackgroundColor: FrutiaColors.disabledText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4, // ← Más sombra al botón
                      shadowColor: FrutiaColors.accent.withOpacity(0.4), // ← Color de sombra
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white, size: 28), // ← Icono más grande (28)
                        const SizedBox(width: 8),
                        Text(
                          'Start Session',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (!_areAllPlayersFilled()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FrutiaColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: FrutiaColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: FrutiaColors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete all player names to start the session',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: FrutiaColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

Widget _buildPlayerRow(int index) {
  final player = widget.sessionData.players[index];

  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            // Player number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FrutiaColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // First Name - CAMBIADO: Initial Caps en lugar de ALL CAPS
            Expanded(
              child: TextFormField(
                controller: _firstNameControllers[index],
                textCapitalization: TextCapitalization.words, // ← Cambiado de .characters a .words
                decoration: InputDecoration(
                  labelText: 'First Name',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFDDE5DC)), // ← Borde más sutil
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFDDE5DC)), // ← Borde más sutil
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FrutiaColors.primary, width: 2),
                  ),
                  labelStyle: GoogleFonts.lato(color: FrutiaColors.primaryText),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.lato(color: FrutiaColors.primaryText),
                onChanged: (value) {
                  setState(() {
                    player.firstName = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),

            // Last Name - CAMBIADO: Initial Caps en lugar de ALL CAPS
            Expanded(
              child: TextFormField(
                controller: _lastInitialControllers[index],
                textCapitalization: TextCapitalization.words, // ← Cambiado de .characters a .words
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFDDE5DC)), // ← Borde más sutil
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFDDE5DC)), // ← Borde más sutil
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FrutiaColors.primary, width: 2),
                  ),
                  labelStyle: GoogleFonts.lato(color: FrutiaColors.primaryText),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.lato(color: FrutiaColors.primaryText),
                onChanged: (value) {
                  setState(() {
                    player.lastInitial = value;
                  });
                },
              ),
            ),
          ],
        ),

        // Advanced settings
        if (_showAdvancedSettings) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 44),
              // Label
              SizedBox(
                width: 100,
                child: Text(
                  'Starting Rating',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: FrutiaColors.tertiaryBackground),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: player.level,
                      isDense: true,
                      isExpanded: true,
                      dropdownColor: FrutiaColors.primaryBackground,
                      items: ['Above Average', 'Average', 'Below Average']
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(
                                  level,
                                  style: GoogleFonts.lato(
                                    fontSize: 13,
                                    color: FrutiaColors.primaryText,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          player.level = value!;
                        });
                      },
                      style: GoogleFonts.lato(color: FrutiaColors.primaryText),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
}