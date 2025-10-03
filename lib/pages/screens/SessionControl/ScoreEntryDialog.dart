// lib/pages/screens/sessionControl/widgets/ScoreEntryDialog.dart
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
 
class ScoreEntryDialog extends StatefulWidget {
  final Map<String, dynamic> game;
  final Map<String, dynamic> session;
  final VoidCallback onScoreSubmitted;

  const ScoreEntryDialog({
    super.key,
    required this.game,
    required this.session,
    required this.onScoreSubmitted,
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

    // No puede haber empate
    if (team1Score == team2Score) {
      setState(() {
        _errorMessage = 'No puede haber empate';
      });
      return false;
    }

    final pointsPerGame = widget.session['points_per_game'] as int;
    final winBy = widget.session['win_by'] as int;

    final winnerScore = team1Score > team2Score ? team1Score : team2Score;
    final loserScore = team1Score > team2Score ? team2Score : team1Score;

    // El ganador debe llegar al mínimo de puntos
    if (winnerScore < pointsPerGame) {
      setState(() {
        _errorMessage = 'El ganador debe tener al menos $pointsPerGame puntos';
      });
      return false;
    }

    // Verificar win-by
    if ((winnerScore - loserScore) < winBy) {
      setState(() {
        _errorMessage = 'Debe ganar por al menos $winBy punto${winBy > 1 ? 's' : ''}';
      });
      return false;
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

      await GameService.submitScore(
        widget.game['id'],
        team1Score,
        team2Score,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onScoreSubmitted();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resultado registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[ScoreEntryDialog] Error: $e');

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error al registrar: ${e.toString()}';
      });
    }
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Registrar Resultado',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Juego a ${widget.session['points_per_game']} puntos | Ganar por ${widget.session['win_by']}',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Team 1
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${team1Player1['first_name']} ${team1Player1['last_initial']}.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${team1Player2['first_name']} ${team1Player2['last_initial']}.',
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _team1Controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (_) => _isScoreValid(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // VS
            Text(
              'VS',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),

            const SizedBox(height: 16),

            // Team 2
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${team2Player1['first_name']} ${team2Player1['last_initial']}.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${team2Player2['first_name']} ${team2Player2['last_initial']}.',
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _team2Controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (_) => _isScoreValid(),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isScoreValid() && !_isSubmitting) ? _submitScore : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE63946),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Aceptar',
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
    );
  }
}