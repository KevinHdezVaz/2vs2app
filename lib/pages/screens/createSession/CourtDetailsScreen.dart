// SCREEN 2: Court Details
import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CourtDetailsScreen extends StatefulWidget {
  final SessionData sessionData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CourtDetailsScreen({
    super.key,
    required this.sessionData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CourtDetailsScreen> createState() => _CourtDetailsScreenState();
}

class _CourtDetailsScreenState extends State<CourtDetailsScreen> {
  late List<TextEditingController> _courtControllers;

  @override
  void initState() {
    super.initState();
    _courtControllers = List.generate(
      widget.sessionData.numberOfCourts,
      (index) => TextEditingController(
        text: widget.sessionData.courtNames[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Court Details',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize court names (optional)',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: FrutiaColors.secondaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Fields for court names
          ...List.generate(
            widget.sessionData.numberOfCourts,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _courtControllers[index],
                decoration: InputDecoration(
                  labelText: 'Court ${index + 1}',
                  prefixIcon: Icon(
                    Icons.sports_tennis,
                    color: FrutiaColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: FrutiaColors.primary,
                      width: 2,
                    ),
                  ),
                  labelStyle: GoogleFonts.lato(color: FrutiaColors.primaryText),
                  hintStyle: GoogleFonts.lato(color: FrutiaColors.disabledText),
                ),
                style: GoogleFonts.lato(color: FrutiaColors.primaryText),
                onChanged: (value) {
                  widget.sessionData.courtNames[index] = value;
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Navigation buttons
         // Navigation buttons
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: widget.onBack,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: FrutiaColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Back: Session Details',
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
        onPressed: widget.onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: FrutiaColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Next: Player Details',
          textAlign: TextAlign.center,  // ← Y también aquí
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
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
