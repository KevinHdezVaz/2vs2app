// lib/pages/screens/createSession/PlayerDetailsScreen.dart

import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final SessionData sessionData;
  final VoidCallback onBack;
  final void Function({bool saveAsDraft}) onStartSession;

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

    // ✅ CRÍTICO: Asegurar que la lista de players tenga el tamaño correcto
    print('[PlayerDetailsScreen] initState called');
    print('   - numberOfPlayers: ${widget.sessionData.numberOfPlayers}');
    print('   - players.length: ${widget.sessionData.players.length}');

    // ✅ Si la lista está vacía o tiene tamaño incorrecto, inicializarla
    if (widget.sessionData.players.length !=
        widget.sessionData.numberOfPlayers) {
      print('   ⚠️  Player list size mismatch, reinitializing...');
      widget.sessionData.initializePlayers();
    }

    // ✅ AHORA SÍ: Inicializar controladores con los datos correctos
    _firstNameControllers = List.generate(
      widget.sessionData.numberOfPlayers,
      (index) {
        final firstName = widget.sessionData.players[index].firstName;
        print('   Loading Player ${index + 1}: "$firstName"');
        return TextEditingController(text: firstName);
      },
    );

    _lastInitialControllers = List.generate(
      widget.sessionData.numberOfPlayers,
      (index) {
        final lastInitial = widget.sessionData.players[index].lastInitial;
        return TextEditingController(text: lastInitial);
      },
    );

    // ✅ VERIFICAR QUÉ SE CARGÓ
    print('[PlayerDetailsScreen] Controllers initialized:');
    for (var i = 0; i < _firstNameControllers.length; i++) {
      print(
          '   Player ${i + 1}: "${_firstNameControllers[i].text}" "${_lastInitialControllers[i].text}"');
    }
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
      if (_firstNameControllers[i].text.trim().isEmpty ||
          _lastInitialControllers[i].text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _updatePlayerDataFromControllers() {
    for (var i = 0; i < widget.sessionData.numberOfPlayers; i++) {
      widget.sessionData.players[i].firstName =
          _firstNameControllers[i].text.trim();
      widget.sessionData.players[i].lastInitial =
          _lastInitialControllers[i].text.trim();
    }
    print('[PlayerDetailsScreen] Updated player data from controllers');
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
          // Navigation buttons - DISEÑO MEJORADO EN 2 LÍNEAS
          Column(
            children: [
              // PRIMERA LÍNEA: Start Session button (más ancho)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _areAllPlayersFilled()
                      ? () {
                          _updatePlayerDataFromControllers();
                          widget.onStartSession(saveAsDraft: false);
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 24),
                  label: Text(
                    'Start Session',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FrutiaColors.accent,
                    disabledBackgroundColor: FrutiaColors.disabledText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: FrutiaColors.accent.withOpacity(0.4),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // SEGUNDA LÍNEA: Back y Save Draft
              Row(
                children: [
                  // Back button
                  Expanded(
                    child: SizedBox(
                      height: 50,
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
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FrutiaColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save Draft button
                  Expanded(
                    child: Container(
                      color: FrutiaColors.warning.withOpacity(0.15),
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _updatePlayerDataFromControllers();
                            widget.onStartSession(saveAsDraft: true);
                          },
                          icon: Icon(
                            Icons.save_outlined,
                            size: 20,
                            color: FrutiaColors.warning,
                          ),
                          label: Text(
                            'Save Draft',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: FrutiaColors.warning,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: FrutiaColors.warning),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                    border: Border.all(
                        color: FrutiaColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: FrutiaColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete all player names to start the session (you can save as draft anytime)',
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
            ],
          ),

          

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

              // First Name
              Expanded(
                child: TextFormField(
                  controller: _firstNameControllers[index],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFDDE5DC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFDDE5DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: FrutiaColors.primary, width: 2),
                    ),
                    labelStyle:
                        GoogleFonts.lato(color: FrutiaColors.primaryText),
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

              // Last Name
              Expanded(
                child: TextFormField(
                  controller: _lastInitialControllers[index],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFDDE5DC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFDDE5DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: FrutiaColors.primary, width: 2),
                    ),
                    labelStyle:
                        GoogleFonts.lato(color: FrutiaColors.primaryText),
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: FrutiaColors.tertiaryBackground),
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
                        style:
                            GoogleFonts.lato(color: FrutiaColors.primaryText),
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
