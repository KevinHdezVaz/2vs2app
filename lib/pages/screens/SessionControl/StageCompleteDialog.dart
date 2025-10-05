// lib/pages/screens/sessionControl/widgets/StageCompleteDialog.dart
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StageCompleteDialog extends StatefulWidget {
  final int sessionId;
  final int currentStage;
  final VoidCallback onStageAdvanced;

  const StageCompleteDialog({
    super.key,
    required this.sessionId,
    required this.currentStage,
    required this.onStageAdvanced,
  });

  @override
  State<StageCompleteDialog> createState() => _StageCompleteDialogState();
}

class _StageCompleteDialogState extends State<StageCompleteDialog> {
  bool _isAdvancing = false;

  String _getStageTitle(int stage) {
    switch (stage) {
      case 1:
        return 'Stage 1: Rotation';
      case 2:
        return 'Stage 2: Rank-Based';
      case 3:
        return 'Stage 3: Finals';
      default:
        return 'Stage $stage';
    }
  }

  String _getNextStageDescription(int nextStage) {
    switch (nextStage) {
      case 2:
        return 'Players will be divided into TOP, MID, and LOW groups based on their current ratings. Balanced matchups will be generated.';
      case 3:
        return 'The finals will be played between players of the same level:\n• TOP vs TOP\n• MID vs MID\n• LOW vs LOW';
      default:
        return 'Next Optimized stage';
    }
  }

  Future<void> _advanceStage() async {
    setState(() {
      _isAdvancing = true;
    });

    try {
      await SessionService.advanceStage(widget.sessionId);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onStageAdvanced();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stage ${widget.currentStage + 1} started successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[StageCompleteDialog] Error: $e');

      setState(() {
        _isAdvancing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error advancing stage: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextStage = widget.currentStage + 1;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              '${_getStageTitle(widget.currentStage)} Completed!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All games in this stage have finished',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Next stage info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE63946).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFFE63946),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStageTitle(nextStage),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE63946),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getNextStageDescription(nextStage),
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isAdvancing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Review',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isAdvancing ? null : _advanceStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE63946),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isAdvancing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Start Stage ${nextStage}',
                                style: GoogleFonts.poppins(
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
          ],
        ),
      ),
    );
  }
}