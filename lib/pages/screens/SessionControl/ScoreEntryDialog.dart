// lib/pages/screens/sessionControl/widgets/ScoreEntryDialog.dart
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreEntryDialog extends StatefulWidget {
  final Map<String, dynamic> game;
  final Map<String, dynamic> session;
  final VoidCallback onScoreSubmitted;
  final bool isEditing;

  const ScoreEntryDialog({
    super.key,
    required this.game,
    required this.session,
    required this.onScoreSubmitted,
    this.isEditing = false,
  });

  @override
  State<ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<ScoreEntryDialog> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _team1Controller.text = widget.game['team1_score']?.toString() ?? '';
      _team2Controller.text = widget.game['team2_score']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }


bool _isScoreValid() {
  if (_team1Controller.text.isEmpty || _team2Controller.text.isEmpty) {
    return false;
  }

  final team1Score = int.tryParse(_team1Controller.text);
  final team2Score = int.tryParse(_team2Controller.text);

  if (team1Score == null || team2Score == null) {
    return false;
  }

  final pointsPerGame = widget.session['points_per_game'] as int;
  final winBy = widget.session['win_by'] as int;

  // ✅ No empates
  if (team1Score == team2Score) {
    setState(() {
      _errorMessage = 'Ties are not allowed';
    });
    return false;
  }

  final winnerScore = team1Score > team2Score ? team1Score : team2Score;
  final loserScore = team1Score > team2Score ? team2Score : team1Score;
  final scoreDiff = winnerScore - loserScore;

  // ✅ VALIDACIÓN PARA "WIN BY 2"
  if (winBy == 2) {
    // CASO A: Ganador tiene exactamente pointsPerGame puntos (juego normal)
    if (winnerScore == pointsPerGame) {
      // El perdedor debe tener (pointsPerGame - 2) puntos o menos
      if (loserScore > pointsPerGame - 2) {
        setState(() {
          _errorMessage = 'With winner at $pointsPerGame, loser cannot have more than ${pointsPerGame - 2} points';
        });
        return false;
      }
    }
    // CASO B: Ganador tiene más de pointsPerGame puntos (juego extendido)
    else if (winnerScore > pointsPerGame) {
      // 1. El perdedor debe tener al menos (pointsPerGame - 1) puntos
      if (loserScore < pointsPerGame - 1) {
        setState(() {
          _errorMessage = 'With winner above $pointsPerGame, loser must have at least ${pointsPerGame - 1} points';
        });
        return false;
      }
      
      // 2. Debe haber diferencia de exactamente 2 puntos
      if (scoreDiff != 2) {
        setState(() {
          _errorMessage = 'With scores above $pointsPerGame, must win by exactly 2 points';
        });
        return false;
      }
      
      // 3. Límite máximo razonable: pointsPerGame + 10
      if (winnerScore > pointsPerGame + 10) {
        setState(() {
          _errorMessage = 'Score too high. Maximum allowed is ${pointsPerGame + 10} points';
        });
        return false;
      }
    }
    // CASO C: Ganador tiene menos de pointsPerGame puntos - INVÁLIDO
    else {
      setState(() {
        _errorMessage = 'Winner must have at least $pointsPerGame points';
      });
      return false;
    }
  }

  // ✅ VALIDACIÓN PARA "WIN BY 1"
  if (winBy == 1) {
    // 1. Ganador debe tener al menos pointsPerGame puntos
    if (winnerScore < pointsPerGame) {
      setState(() {
        _errorMessage = 'Winner must have at least $pointsPerGame points';
      });
      return false;
    }
    
    // 2. Debe ganar por al menos 1 punto
    if (scoreDiff < 1) {
      setState(() {
        _errorMessage = 'Must win by at least 1 point';
      });
      return false;
    }
    
    // 3. Si ganador tiene exactamente pointsPerGame, perdedor máximo (pointsPerGame - 1)
    if (winnerScore == pointsPerGame && loserScore >= pointsPerGame) {
      setState(() {
        _errorMessage = 'With winner at $pointsPerGame, loser cannot have $pointsPerGame or more points';
      });
      return false;
    }
    
    // 4. Límite máximo razonable
    if (winnerScore > pointsPerGame + 10) {
      setState(() {
        _errorMessage = 'Score too high. Maximum allowed is ${pointsPerGame + 10} points';
      });
      return false;
    }
  }

  setState(() {
    _errorMessage = null;
  });
  return true;
}

  Future<void> _submitScore() async {
    if (!_isScoreValid()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final team1Score = int.parse(_team1Controller.text);
      final team2Score = int.parse(_team2Controller.text);

      if (widget.isEditing) {
        await GameService.updateScore(
          widget.game['id'],
          team1Score,
          team2Score,
        );
      } else {
        await GameService.submitScore(
          widget.game['id'],
          team1Score,
          team2Score,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
      widget.onScoreSubmitted();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Score updated successfully' : 'Score registered successfully!',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[ScoreEntryDialog] Error: $e');

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error ${widget.isEditing ? 'updating' : 'registering'}: ${e.toString()}';
      });
    }
  }

  Widget _buildTeamRow({
    required String player1Name,
    required String player2Name,
    required TextEditingController controller,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Player names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player1Name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  player2Name,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: FrutiaColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score input
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: FrutiaColors.disabledText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FrutiaColors.tertiaryBackground),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FrutiaColors.tertiaryBackground),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FrutiaColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: FrutiaColors.primaryBackground,
              ),
              // ✅ ELIMINADO: onChanged que validaba en tiempo real
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team1Player1 = widget.game['team1_player1'];
    final team1Player2 = widget.game['team1_player2'];
    final team2Player1 = widget.game['team2_player1'];
    final team2Player2 = widget.game['team2_player2'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.isEditing ? 'Edit Score' : 'Submit Score',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FrutiaColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Game to ${widget.session['points_per_game']} points | Win by ${widget.session['win_by']}',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: FrutiaColors.secondaryText,
                ),
              ),
              const SizedBox(height: 18),

              // Team 1
              _buildTeamRow(
                player1Name: '${team1Player1['first_name']} ${team1Player1['last_initial']}.',
                player2Name: '${team1Player2['first_name']} ${team1Player2['last_initial']}.',
                controller: _team1Controller,
                backgroundColor: FrutiaColors.accentLight,
              ),

              const SizedBox(height: 12),

              // VS Divider
              Text(
                'VS',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.disabledText,
                ),
              ),

              const SizedBox(height: 12),

              // Team 2
              _buildTeamRow(
                player1Name: '${team2Player1['first_name']} ${team2Player1['last_initial']}.',
                player2Name: '${team2Player2['first_name']} ${team2Player2['last_initial']}.',
                controller: _team2Controller,
                backgroundColor: FrutiaColors.secondaryBackground,
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FrutiaColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FrutiaColors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: FrutiaColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: FrutiaColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: FrutiaColors.tertiaryBackground),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_isSubmitting ? _submitScore : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.primary,
                        disabledBackgroundColor: FrutiaColors.tertiaryBackground,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.isEditing ? 'Update' : 'Submit',
                              style: GoogleFonts.poppins(
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
        ),
      ),
    );
  }
}