import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionDetailsScreen extends StatefulWidget {
  final SessionData sessionData;
  final VoidCallback onNext;

  const SessionDetailsScreen({
    super.key,
    required this.sessionData,
    required this.onNext,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sessionNameController.text = widget.sessionData.sessionName;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de la Sesión',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configura los parámetros de tu sesión',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Nombre de la Sesión
            TextFormField(
              controller: _sessionNameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Sesión',
                hintText: 'p. ej., Torneo de Fin de Semana',
                prefixIcon: const Icon(Icons.sports_tennis, color: Color(0xFFE63946)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE63946), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un nombre de sesión';
                }
                return null;
              },
              onChanged: (value) {
                widget.sessionData.sessionName = value;
              },
            ),
            const SizedBox(height: 20),

            // Número de Canchas
            _buildNumberSelector(
              label: 'Número de Canchas',
              value: widget.sessionData.numberOfCourts,
              min: 1,
              max: 4,
              icon: Icons.sports_tennis,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.numberOfCourts = value;
                  _updatePlayerLimits();
                });
              },
            ),

            // Duración
            _buildNumberSelector(
              label: 'Duración (Horas)',
              value: widget.sessionData.durationHours,
              min: 1,
              max: 3,
              icon: Icons.timer,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.durationHours = value;
                });
              },
            ),

            // Número de Jugadores
            _buildNumberSelector(
              label: 'Número de Jugadores',
              value: widget.sessionData.numberOfPlayers,
              min: widget.sessionData.numberOfCourts * 4,
              max: widget.sessionData.numberOfCourts * 8,
              icon: Icons.group,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.numberOfPlayers = value;
                });
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Text(
              'Configuraciones del Juego',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),

            // Puntos por Partido
            _buildDropdownField(
              label: 'Puntos por Partido',
              value: widget.sessionData.pointsPerGame.toString(),
              items: ['7', '11', '15', '21'],
              icon: Icons.scoreboard,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.pointsPerGame = int.parse(value!);
                });
              },
            ),

            // Ganar Por
            _buildDropdownField(
              label: 'Ganar Por',
              value: widget.sessionData.winBy.toString(),
              items: ['1', '2'],
              icon: Icons.trending_up,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.winBy = int.parse(value!);
                });
              },
            ),

            // Número de Sets
            _buildDropdownField(
              label: 'Número de Sets',
              value: widget.sessionData.numberOfSets,
              items: ['1', 'Best of 3', 'Best of 5'],
              icon: Icons.repeat,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.numberOfSets = value!;
                });
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Text(
              'Tipo de Sesión',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),

            // Selección de Tipo de Sesión
            ...['T', 'P4', 'P8'].map((type) => _buildSessionTypeCard(type)),

            const SizedBox(height: 32),

            // Botón Siguiente
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.sessionData.initializeCourts();
                    widget.sessionData.initializePlayers();
                    widget.onNext();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Siguiente: Detalles de Cancha',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _updatePlayerLimits() {
    final minPlayers = widget.sessionData.numberOfCourts * 4;
    final maxPlayers = widget.sessionData.numberOfCourts * 8;
    
    if (widget.sessionData.numberOfPlayers < minPlayers) {
      widget.sessionData.numberOfPlayers = minPlayers;
    } else if (widget.sessionData.numberOfPlayers > maxPlayers) {
      widget.sessionData.numberOfPlayers = maxPlayers;
    }
  }

  Widget _buildNumberSelector({
    required String label,
    required int value,
    required int min,
    required int max,
    required IconData icon,
    required Function(int) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFE63946), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: value > min
                          ? () => onChanged(value - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFFE63946),
                    ),
                    IconButton(
                      onPressed: value < max
                          ? () => onChanged(value + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFFE63946),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFE63946), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      items: items.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTypeCard(String type) {
    final isSelected = widget.sessionData.sessionType == type;
    String title;
    String description;
    IconData icon;

    switch (type) {
      case 'T':
        title = 'Torneo';
        description = 'Torneo estructurado en 3 etapas con rotación y juego clasificado';
        icon = Icons.emoji_events;
        break;
      case 'P4':
        title = 'Playoff 4';
        description = 'Partidos aleatorios que llevan a la final con los 4 mejores jugadores';
        icon = Icons.filter_4;
        break;
      case 'P8':
        title = 'Playoff 8';
        description = 'Partidos aleatorios, luego semifinales y finales con los 8 mejores';
        icon = Icons.filter_8;
        break;
      default:
        title = '';
        description = '';
        icon = Icons.sports;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.sessionData.sessionType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE63946).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE63946)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE63946).withOpacity(0.2)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFE63946)
                    : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFE63946)
                          : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFE63946),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}