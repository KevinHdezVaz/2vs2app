import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionTypeScreen extends StatefulWidget {
  final SessionData sessionData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const SessionTypeScreen({
    super.key,
    required this.sessionData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<SessionTypeScreen> createState() => _SessionTypeScreenState();
}

class _SessionTypeScreenState extends State<SessionTypeScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Type',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to play',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: FrutiaColors.secondaryText,
            ),
          ),
          const SizedBox(height: 24),

    // Session Type Cards
_buildSessionTypeCard('P4'),
_buildSessionTypeCard('P8'),
_buildSessionTypeCard('T'),

          const SizedBox(height: 32),

          // Buttons Row
         Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: widget.onBack,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          side: BorderSide(color: FrutiaColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Back: Detail Session',
          textAlign: TextAlign.center,  // ← Agrega esto
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primary,
          ),
        ),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      flex: 2,
      child: ElevatedButton(
        onPressed: () {
          widget.sessionData.initializeCourts();
          widget.sessionData.initializePlayers();
          widget.onNext();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: FrutiaColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Next: Court Details',
          textAlign: TextAlign.center,  // ← Agrega esto
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  ],
),
          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSessionTypeCard(String type) {
    final isSelected = widget.sessionData.sessionType == type;
    String title;
    String description;
    IconData icon;

    switch (type) {
  
      case 'P4':
        title = 'Playoff 4';
        description = 'Players rotate through games with varied partners and opponents. At the end, the top 4 players advance to playoff rounds to decide the winners.';
        icon = Icons.filter_4;
        break;
      case 'P8':
        title = 'Playoff 8';
        description = 'Extended rotations with balanced matchups across the group. The session concludes with playoffs featuring the top 8 players, giving more participants a chance at the finals.';
        icon = Icons.filter_8;
        break;
             case 'T':
        title = 'Optimized';
        description = 'A multi-stage rotation that maximizes variety and competitiveness, dynamically pairing players based on results and performance.';
        icon = Icons.emoji_events;
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