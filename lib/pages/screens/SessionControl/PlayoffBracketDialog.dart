// lib/pages/screens/sessionControl/widgets/PlayoffBracketDialog.dart
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
class PlayoffBracketDialog extends StatefulWidget {
  final int sessionId;
  final String sessionType;
  final List<dynamic> topPlayers;
  final VoidCallback onBracketGenerated;

  const PlayoffBracketDialog({
    super.key,
    required this.sessionId,
    required this.sessionType,
    required this.topPlayers,
    required this.onBracketGenerated,
  });

  @override
  State<PlayoffBracketDialog> createState() => _PlayoffBracketDialogState();
}

class _PlayoffBracketDialogState extends State<PlayoffBracketDialog> {
  bool _isGenerating = false;

  String get _title => widget.sessionType == 'P4' 
      ? 'Generar Final (Top 4)' 
      : 'Generar Semifinales (Top 8)';

  String get _description => widget.sessionType == 'P4'
      ? 'Se generará 1 juego final con los 4 mejores jugadores:\n\n#1 + #4 vs #2 + #3'
      : 'Se generarán 2 semifinales con los 8 mejores jugadores:\n\nSF1: #1 + #8 vs #3 + #6\nSF2: #2 + #7 vs #4 + #5\n\nLuego: Final de Oro y Bronce';

  Future<void> _generateBracket() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Llamar endpoint para generar bracket
      // Por ahora usamos advance stage que debería manejar esto
      await SessionService.advanceStage(widget.sessionId);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onBracketGenerated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.sessionType == 'P4' 
                ? '¡Final generada!' 
                : '¡Semifinales generadas!'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[PlayoffBracketDialog] Error: $e');

      setState(() {
        _isGenerating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar bracket: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerCount = widget.sessionType == 'P4' ? 4 : 8;

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
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fase de eliminación del playoff',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Top players
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top $playerCount Jugadores:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.topPlayers.take(playerCount).map((player) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE63946),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#${player['current_rank']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${player['first_name']} ${player['last_initial']}.',
                              style: GoogleFonts.lato(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${player['current_rating']?.toInt() ?? 0}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _description,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isGenerating ? null : () => Navigator.pop(context),
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
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateBracket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isGenerating
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
                              const Icon(Icons.emoji_events, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Generar',
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