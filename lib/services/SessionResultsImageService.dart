// lib/services/SessionResultsImage.dart
// ✅ ACTUALIZADO: Incluye Point Won % en las tarjetas de jugadores

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

// Definición de colores clave
const Color _primaryColorDark = Color(0xFF2B5F5F); // Teal oscuro
const Color _backgroundColor =
    Color(0xFF1E4D4D); // Fondo más oscuro para el header

class SessionResultsImageService {
  /// Genera y comparte una imagen con los resultados de la sesión
  static Future<void> generateAndShareResultsImage({
    required BuildContext context,
    required Map<String, dynamic> sessionData,
    required List<dynamic> players,
    required String sessionType,
    List<dynamic>? playoffWinners,
  }) async {
    try {
      // Generar la imagen
      final imageBytes = await _generateImage(
        context: context,
        sessionData: sessionData,
        players: players,
        sessionType: sessionType,
        playoffWinners: playoffWinners,
      );

      // Guardar temporalmente
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/session_results_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      final sessionName = sessionData['session_name'] ?? 'Session';

      await Share.shareXFiles(
        [XFile(filePath)],
        text: _buildEmailText(sessionName),
        subject: 'PickleBracket Results: $sessionName is complete! 🏆',
      );

      // Limpiar después de un tiempo
      Future.delayed(const Duration(minutes: 5), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      print('❌ Error generating results image: $e');
      rethrow;
    }
  }

  static String _buildEmailText(String sessionName) {
    return '''
The scores are in! Check out the final results and top performers from the $sessionName session in the image below.

Organized with PickleBracket. Create and run competitive and fun Open Play sessions quickly and smoothly. Pick from different game modes and see who shines today!

Learn more: www.picklebracket.pro
''';
  }

  /// Genera la imagen de resultados usando RepaintBoundary
  static Future<Uint8List> _generateImage({
    required BuildContext context,
    required Map<String, dynamic> sessionData,
    required List<dynamic> players,
    required String sessionType,
    List<dynamic>? playoffWinners,
  }) async {
    // Crear un GlobalKey para capturar el widget
    final GlobalKey repaintKey = GlobalKey();

    // Crear el widget que se va a renderizar
    final widget = RepaintBoundary(
      key: repaintKey,
      child: _ResultsImageWidget(
        sessionData: sessionData,
        players: players,
        sessionType: sessionType,
        playoffWinners: playoffWinners,
      ),
    );

    // Renderizar el widget en un overlay temporal
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        left: -10000, // Fuera de la pantalla
        top: -10000,
        child: Material(
          child: Container(
            width: 1080, // Ancho fijo para la imagen
            color: Colors.white,
            child: widget,
          ),
        ),
      ),
    );

    // Agregar al overlay
    Overlay.of(context).insert(overlay);

    // Esperar a que se renderice
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Capturar la imagen
      final RenderRepaintBoundary boundary = repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      // Remover del overlay
      overlay.remove();

      return byteData!.buffer.asUint8List();
    } catch (e) {
      overlay.remove();
      rethrow;
    }
  }

  static String _getSessionTypeName(String sessionType) {
    switch (sessionType) {
      case 'S':
        return 'MAX VARIETY';
      case 'P4':
        return 'TOP 4 PLAYOFFS';
      case 'P8':
        return 'TOP 8 PLAYOFFS';
      case 'T':
        return 'COMPETITIVE MAX';
      case 'O':
        return 'Optimized';
      default:
        return sessionType;
    }
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

/// Widget que se renderiza como imagen
class _ResultsImageWidget extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final List<dynamic> players;
  final String sessionType;
  final List<dynamic>? playoffWinners;

  const _ResultsImageWidget({
    required this.sessionData,
    required this.players,
    required this.sessionType,
    this.playoffWinners,
  });

  @override
  Widget build(BuildContext context) {
    final int topRankCount = players.length < 12 ? players.length : 12;

    return Container(
      width: 1080,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          _buildHeader(),

          // SESSION INFO
          _buildSessionInfo(),

          // MEDAL WINNERS (solo para playoffs)
          if (sessionType == 'P4' || sessionType == 'P8') _buildMedalWinners(),

          // TOP RANKINGS
          const SizedBox(height: 30),
          _buildTopRankings(showTop: topRankCount),

          // FOOTER
          const SizedBox(height: 40),
          _buildFooterSimple(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final sessionName = sessionData['session_name']?.toString().toUpperCase() ??
        'SESSION RESULTS';
    final sessionTypeFormatted =
        SessionResultsImageService._getSessionTypeName(sessionType);
    final dateFormatted = SessionResultsImageService._formatDate(
      sessionData['created_at']?.toString(),
    );

    return Container(
      width: 1080,
      decoration: const BoxDecoration(
        color: _backgroundColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      child: Column(
        children: [
          // Título de la sesión
          Text(
            sessionName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 15),

          // Session type y fecha
          Text(
            '$sessionTypeFormatted | $dateFormatted',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    int duration = 0;
    if (sessionData['elapsed_seconds'] != null) {
      duration = sessionData['elapsed_seconds'] as int;
    } else if (sessionData['duration_seconds'] != null) {
      duration = sessionData['duration_seconds'] as int;
    }

    final numberOfPlayers = sessionData['number_of_players'] ?? 0;
    final numberOfCourts = sessionData['number_of_courts'] ?? 0;

    // Calcular juegos completados de forma real
    int completedGames = 0;
    if (players.isNotEmpty && players[0]['games_played'] != null) {
      int totalGamesPlayed = 0;
      for (var player in players) {
        totalGamesPlayed += (player['games_played'] as int? ?? 0);
      }
      completedGames = (totalGamesPlayed / 4).floor();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoBox('$numberOfPlayers', 'PLAYERS', Icons.people),
          _buildInfoBox('$numberOfCourts', 'COURTS', Icons.sports_tennis),
          _buildInfoBox(
            SessionResultsImageService._formatDuration(duration),
            'DURATION',
            Icons.access_time,
          ),
          _buildInfoBox('$completedGames', 'GAMES PLAYED', Icons.sports_score),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColorDark.withOpacity(0.1),
          ),
          child: Icon(icon, size: 32, color: _primaryColorDark),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5A5A),
          ),
        ),
      ],
    );
  }

  Widget _buildMedalWinners() {
    if (playoffWinners == null || playoffWinners!.isEmpty) {
      print('⚠️  No playoff winners data available');
      return const SizedBox.shrink();
    }

    print('');
    print('🏆 Building medal winners:');
    print('   Total teams: ${playoffWinners!.length}');

    final champions = playoffWinners!.length > 0 ? playoffWinners![0] : null;
    final runnersUp = playoffWinners!.length > 1 ? playoffWinners![1] : null;
    final thirdPlace = playoffWinners!.length > 2 ? playoffWinners![2] : null;

    print('   Champions: $champions');
    print('   Runners-up: $runnersUp');
    print('   Third Place: $thirdPlace');
    print('');

    if (champions == null) {
      print('⚠️  No champions data - skipping medals section');
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          Text(
            '-- FINALISTS --',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (runnersUp != null) _buildMedalCard('SILVER', runnersUp),
              _buildMedalCard('GOLD', champions),
              if (thirdPlace != null) _buildMedalCard('BRONZE', thirdPlace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedalCard(String medal, dynamic team) {
    print('🎴 Building medal card for $medal with data: $team');

    String teamNames = 'Team';

    if (team is List && team.isNotEmpty) {
      final player1 = _getPlayerNameWithInitial(team[0]);
      final player2 = team.length > 1 ? _getPlayerNameWithInitial(team[1]) : '';

      teamNames = player2.isNotEmpty ? '$player1 & $player2' : player1;
      print('   ✅ List format: $teamNames');
    } else if (team is Map) {
      final p1FirstName = team['first_name']?.toString() ?? '';
      final p1LastInitial = team['last_initial']?.toString() ?? '';
      final p2FirstName = team['second_player_name']?.toString() ?? '';
      final p2LastInitial =
          team['second_player_last_initial']?.toString() ?? '';

      final player1 = p1LastInitial.isNotEmpty
          ? '$p1FirstName ${p1LastInitial}.'
          : p1FirstName;

      final player2 = p2FirstName.isNotEmpty && p2LastInitial.isNotEmpty
          ? '& $p2FirstName ${p2LastInitial}.'
          : (p2FirstName.isNotEmpty ? '& $p2FirstName' : '');

      teamNames = player2.isNotEmpty ? '$player1 $player2' : player1;
      print('   ✅ Map format: $teamNames');
    } else {
      print('   ⚠️  Unknown format, using default');
      teamNames = 'Team Name';
    }

    final Gradient cardGradient;
    final Color textColor;
    final String medalEmoji;

    switch (medal) {
      case 'GOLD':
        cardGradient = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFEC8B), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFF8B6914);
        medalEmoji = '🥇';
        break;

      case 'SILVER':
        cardGradient = const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFFF0F0F0), Color(0xFFC0C0C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFF505050);
        medalEmoji = '🥈';
        break;

      case 'BRONZE':
        cardGradient = const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFE8B886), Color(0xFFCD7F32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFF5D4037);
        medalEmoji = '🥉';
        break;

      default:
        cardGradient =
            const LinearGradient(colors: [Colors.grey, Colors.white]);
        textColor = Colors.black;
        medalEmoji = '🏅';
    }

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            medalEmoji,
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 15),
          Text(
            teamNames,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRankings({int showTop = 12}) {
    final topPlayers = players.take(showTop).toList();

    if (topPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    final leftColumn = <dynamic>[];
    final rightColumn = <dynamic>[];

    for (int i = 0; i < topPlayers.length; i++) {
      if (i < 6) {
        leftColumn.add(topPlayers[i]);
      } else {
        rightColumn.add(topPlayers[i]);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          Text(
            '-- FINAL RANKINGS --',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: List.generate(
                    leftColumn.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildPlayerRankCardCompact(
                          index + 1, leftColumn[index]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(
                    rightColumn.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildPlayerRankCardCompact(
                        index + 7,
                        rightColumn[index],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ ACTUALIZADO: Card con Point Won %
  Widget _buildPlayerRankCardCompact(int rank, dynamic player) {
    final gamesWon = player['games_won'] ?? 0;
    final gamesLost = player['games_lost'] ?? 0;
    final currentRating = player['current_rating']?.round() ?? 0;

    // ✅ NUEVO: Calcular Point Won %
    final pointsWon = player['points_won'] ?? 0;
    final pointsLost = player['points_lost'] ?? 0;
    final totalPoints = pointsWon + pointsLost;

// ✅ CORREGIDO en _buildPlayerRankCardCompact
    final pointWonPct = player['points_won_percentage'] != null
        ? (player['points_won_percentage'] as num).round()
        : (totalPoints > 0 ? ((pointsWon / totalPoints) * 100).round() : 0);

    final Color rankColor =
        (rank == 1 || rank == 2) ? _primaryColorDark : const Color(0xFF5A5A5A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // RANK NUMBER
          SizedBox(
            width: 50,
            child: Text(
              '#$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                Text(
                  _getPlayerNameWithInitial(player),
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Rating y Record en la MISMA línea
                Row(
                  children: [
                    Text(
                      'Rating: $currentRating',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A5A5A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: const Color(0xFF5A5A5A),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'W:$gamesWon L:$gamesLost',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A5A5A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // ✅ NUEVO: Point Won %
                Text(
                  'Pts Won: $pointWonPct%',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryColorDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSimple() {
    return Container(
      width: 1080,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          Text(
            '-- CREATED BY PICKLEBRACKET --',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A5A5A),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Create and run competitive and fun Open Play sessions quickly and smoothly.\nPick from different game modes and see who shines today!',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 18,
              color: const Color(0xFF5A5A5A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _primaryColorDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('PB',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Learn more: www.picklebracket.pro',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primaryColorDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPlayerNameWithInitial(dynamic player) {
    if (player == null) return 'Unknown Player';

    if (player is String) return player;

    final firstName = player['first_name']?.toString() ?? '';
    final lastInitial = player['last_initial']?.toString() ??
        (player['last_name']?.toString().isNotEmpty == true
            ? player['last_name'].toString().substring(0, 1)
            : '');

    if (firstName.isNotEmpty && lastInitial.isNotEmpty) {
      if (lastInitial.endsWith('.')) {
        return '$firstName $lastInitial';
      }
      return '$firstName ${lastInitial}.';
    } else if (firstName.isNotEmpty) {
      return firstName;
    }

    return 'Unknown Player';
  }
}
