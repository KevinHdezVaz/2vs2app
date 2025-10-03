// PANTALLA 3: Detalles de Jugadores
import 'package:Frutia/model/2vs2p/SessionData.dart';
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
            'Detalles de Jugadores',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa la información de los jugadores',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Alternar configuraciones avanzadas
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Configuraciones Avanzadas',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Switch(
                value: _showAdvancedSettings,
                activeColor: const Color(0xFFE63946),
                onChanged: (value) {
                  setState(() {
                    _showAdvancedSettings = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de jugadores
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildPlayerRow(index);
              },
            ),
          ),

          const SizedBox(height: 32),

          // Botones de navegación
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE63946)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Atrás',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE63946),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _areAllPlayersFilled() ? widget.onStartSession : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Iniciar Sesión',
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
            ],
          ),
          
          if (!_areAllPlayersFilled()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completa los nombres de todos los jugadores para iniciar la sesión',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.orange[800],
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
              // Número del jugador
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE63946).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE63946),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Nombre
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _firstNameControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFE63946),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      player.firstName = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Inicial del Apellido
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _lastInitialControllers[index],
                  maxLength: 1,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFE63946),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      player.lastInitial = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          // Configuraciones avanzadas
          if (_showAdvancedSettings) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 48),
                // Nivel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: player.level,
                        isDense: true,
                        isExpanded: true,
                        items: ['Por encima del promedio', 'Promedio', 'Por debajo del promedio']
                            .map((level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(
                                    level,
                                    style: GoogleFonts.lato(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            player.level = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Mano Dominante
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: player.dominantHand,
                        isDense: true,
                        isExpanded: true,
                        items: ['Zurdo', 'Diestro', 'Ninguna']
                            .map((hand) => DropdownMenuItem(
                                  value: hand,
                                  child: Text(
                                    hand,
                                    style: GoogleFonts.lato(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            player.dominantHand = value!;
                          });
                        },
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