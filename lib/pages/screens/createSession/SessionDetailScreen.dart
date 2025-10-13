import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/utils/colors.dart';
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
              'Set up & launch a new Open Play session',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'courts, players, and time \nwe’ll handle the matchups!',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: FrutiaColors.secondaryText,
              ),
            ),
            const SizedBox(height: 24),

            // Session Name
            TextFormField(
              controller: _sessionNameController,
              decoration: InputDecoration(
                labelText: 'Session Name',
                hintText: 'e.g., Weekend Optimized',
                prefixIcon: Icon(Icons.sports_tennis, color: FrutiaColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FrutiaColors.primary, width: 2),
                ),
                labelStyle: GoogleFonts.lato(color: FrutiaColors.primaryText),
                hintStyle: GoogleFonts.lato(color: FrutiaColors.disabledText),
              ),
              style: GoogleFonts.lato(color: FrutiaColors.primaryText),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a session name';
                }
                return null;
              },
              onChanged: (value) {
                widget.sessionData.sessionName = value;
              },
            ),
            const SizedBox(height: 20),

            // Number of Courts - QUITADO LÍMITE MÁXIMO
            _buildNumberSelector(
              label: 'Number of Courts',
              value: widget.sessionData.numberOfCourts,
              min: 1,
              max: 10, // Aumentado para permitir más pruebas
              icon: Icons.sports_tennis,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.numberOfCourts = value;
                  _updatePlayerLimits();
                });
              },
            ),

            // Duration - QUITADO LÍMITE MÁXIMO
            _buildNumberSelector(
              label: 'Duration (Hours)',
              value: widget.sessionData.durationHours,
              min: 1,
              max: 10, // Aumentado para permitir más pruebas
              icon: Icons.timer,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.durationHours = value;
                });
              },
            ),

            // Number of Players - QUITADO LÍMITE BASADO EN CANCHAS
            _buildNumberSelector(
              label: 'Number of Players',
              value: widget.sessionData.numberOfPlayers,
              min: 2, // Mínimo absoluto
              max: 50, // Máximo alto para pruebas
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
              'Game Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // Points per Game
            _buildDropdownField(
              label: 'Points per Game',
              value: widget.sessionData.pointsPerGame.toString(),
              items: ['7', '11', '15', '21'],
              icon: Icons.scoreboard,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.pointsPerGame = int.parse(value!);
                });
              },
            ),

            // Win By
            _buildDropdownField(
              label: 'Win By',
              value: widget.sessionData.winBy.toString(),
              items: ['1', '2'],
              icon: Icons.trending_up,
              onChanged: (value) {
                setState(() {
                  widget.sessionData.winBy = int.parse(value!);
                });
              },
            ),

            // Number of Sets
            _buildDropdownField(
              label: 'Number of Sets',
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
           
            // Next Button
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
                  backgroundColor: FrutiaColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Next: Session Type',
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
    // QUITADA LA LÓGICA QUE LIMITABA JUGADORES BASADO EN CANCHAS
    // Ahora los jugadores pueden ser cualquier número entre min y max
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
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: FrutiaColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FrutiaColors.tertiaryBackground),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: FrutiaColors.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
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
                      color: FrutiaColors.primary,
                    ),
                    IconButton(
                      onPressed: value < max
                          ? () => onChanged(value + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: FrutiaColors.primary,
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
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: FrutiaColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FrutiaColors.tertiaryBackground),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: FrutiaColors.primary, size: 24),
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
                              color: FrutiaColors.primaryText,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                      dropdownColor: FrutiaColors.primaryBackground,
                      style: GoogleFonts.poppins(
                        color: FrutiaColors.primaryText,
                      ),
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
        title = 'Optimized';
        description = 'Structured tournament in 3 stages with rotation and ranked play';
        icon = Icons.emoji_events;
        break;
      case 'P4':
        title = 'Playoff 4';
        description = 'Random matches leading to a final with the top 4 players';
        icon = Icons.filter_4;
        break;
      case 'P8':
        title = 'Playoff 8';
        description = 'Random matches, then semifinals and finals with the top 8 players';
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
              ? FrutiaColors.primary.withOpacity(0.1)
              : FrutiaColors.primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FrutiaColors.primary
                : FrutiaColors.tertiaryBackground,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? FrutiaColors.primary.withOpacity(0.2)
                    : FrutiaColors.secondaryBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? FrutiaColors.primary
                    : FrutiaColors.secondaryText,
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
                          ? FrutiaColors.primary
                          : FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: FrutiaColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}