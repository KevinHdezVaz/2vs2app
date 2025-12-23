// lib/services/SessionResultsImage.dart
// ✅ DISEÑO ACTUALIZADO: Basado en el mockup HTML con estilo moderno y compacto

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores del brand - confirmados del HTML
const Color _navy = Color(0xFF061848);
const Color _lime = Color(0xFFE9FE1F);
const Color _teal = Color(0xFF0D505D);
const Color _bgCard = Color(0x0DFFFFFF); // rgba(255, 255, 255, 0.05)

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
    final GlobalKey repaintKey = GlobalKey();

    final widget = RepaintBoundary(
      key: repaintKey,
      child: _ResultsImageWidget(
        sessionData: sessionData,
        players: players,
        sessionType: sessionType,
        playoffWinners: playoffWinners,
      ),
    );

    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        left: -10000,
        top: -10000,
        child: Material(
          child: Container(
            width: 1080,
            color: const Color(0xFF1A1A1A),
            child: widget,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final RenderRepaintBoundary boundary = repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

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
        return 'OPTIMIZED';
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
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(40),
      child: Container(
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _lime, width: 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 80,
              offset: const Offset(0, 40),
            ),
          ],
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // COMPACT HEADER
            _buildCompactHeader(),

            // FINALISTS (solo para playoffs)
            if (sessionType == 'P4' || sessionType == 'P8') ...[
              const SizedBox(height: 30),
              _buildFinalistsSection(),
            ],

            // FINAL RANKINGS
            const SizedBox(height: 30),
            _buildFinalRankings(showTop: topRankCount),

            // FOOTER
            const SizedBox(height: 30),
            _buildModernFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final sessionName = sessionData['session_name']?.toString().toUpperCase() ??
        'SESSION RESULTS';
    final sessionTypeFormatted =
        SessionResultsImageService._getSessionTypeName(sessionType);
    final dateFormatted = SessionResultsImageService._formatDate(
      sessionData['created_at']?.toString(),
    );

    // Calcular datos de sesión
    int duration = 0;
    if (sessionData['elapsed_seconds'] != null) {
      duration = sessionData['elapsed_seconds'] as int;
    } else if (sessionData['duration_seconds'] != null) {
      duration = sessionData['duration_seconds'] as int;
    }

    final numberOfPlayers = sessionData['number_of_players'] ?? 0;
    final numberOfCourts = sessionData['number_of_courts'] ?? 0;

    int completedGames = 0;
    if (players.isNotEmpty && players[0]['games_played'] != null) {
      int totalGamesPlayed = 0;
      for (var player in players) {
        totalGamesPlayed += (player['games_played'] as int? ?? 0);
      }
      completedGames = (totalGamesPlayed / 4).floor();
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Session name and type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: GoogleFonts.oswald(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$sessionTypeFormatted • $dateFormatted',
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    color: _lime,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // RIGHT: Stats strip (enlarged)
          Row(
            children: [
              _buildStatBox('$numberOfPlayers', 'Players'),
              const SizedBox(width: 24),
              _buildStatBox('$numberOfCourts', 'Courts'),
              const SizedBox(width: 24),
              _buildStatBox(
                SessionResultsImageService._formatDuration(duration),
                'Duration',
              ),
              const SizedBox(width: 24),
              _buildStatBox('$completedGames', 'Games'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.robotoMono(
            fontSize: 9,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalistsSection() {
    if (playoffWinners == null || playoffWinners!.isEmpty) {
      return const SizedBox.shrink();
    }

    final champions = playoffWinners!.length > 0 ? playoffWinners![0] : null;
    final runnersUp = playoffWinners!.length > 1 ? playoffWinners![1] : null;
    final thirdPlace = playoffWinners!.length > 2 ? playoffWinners![2] : null;

    if (champions == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text(
          'FINALISTS',
          style: GoogleFonts.oswald(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SILVER (Runner-up) - Left
            if (runnersUp != null)
              Expanded(
                flex: 10,
                child: _buildMedalCard('SILVER', runnersUp, isGold: false),
              ),
            if (runnersUp != null) const SizedBox(width: 15),

            // GOLD (Champions) - Center (slightly larger)
            Expanded(
              flex: 11,
              child: _buildMedalCard('GOLD', champions, isGold: true),
            ),

            // BRONZE (3rd Place) - Right
            if (thirdPlace != null) const SizedBox(width: 15),
            if (thirdPlace != null)
              Expanded(
                flex: 10,
                child: _buildMedalCard('BRONZE', thirdPlace, isGold: false),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedalCard(String medal, dynamic team, {required bool isGold}) {
    String teamNames = _getTeamNames(team);

    final Color circleStartColor;
    final Color circleEndColor;
    final String medalNumber;
    final String medalLabel;

    switch (medal) {
      case 'GOLD':
        circleStartColor = const Color(0xFFFFD700);
        circleEndColor = const Color(0xFFB8860B);
        medalNumber = '1';
        medalLabel = 'CHAMPIONS';
        break;
      case 'SILVER':
        circleStartColor = const Color(0xFFE0E0E0);
        circleEndColor = const Color(0xFF8E8E8E);
        medalNumber = '2';
        medalLabel = 'RUNNER UP';
        break;
      case 'BRONZE':
        circleStartColor = const Color(0xFFCD7F32);
        circleEndColor = const Color(0xFF8B4513);
        medalNumber = '3';
        medalLabel = '3RD PLACE';
        break;
      default:
        circleStartColor = Colors.grey;
        circleEndColor = Colors.grey;
        medalNumber = '?';
        medalLabel = 'FINALIST';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isGold ? 24 : 16,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: isGold ? _lime.withOpacity(0.05) : _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGold ? _lime : Colors.white.withOpacity(0.1),
          width: isGold ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [circleStartColor, circleEndColor],
              ),
            ),
            child: Center(
              child: Text(
                medalNumber,
                style: GoogleFonts.oswald(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Winner names
          Text(
            teamNames,
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              fontSize: isGold ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: isGold ? _lime : Colors.white,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Medal label
          Text(
            medalLabel,
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalRankings({int showTop = 12}) {
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

    return Column(
      children: [
        Text(
          'FINAL RANKINGS',
          style: GoogleFonts.oswald(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 2,
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRankRow(index + 1, leftColumn[index]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 25),
            Expanded(
              child: Column(
                children: List.generate(
                  rightColumn.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRankRow(index + 7, rightColumn[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRankRow(int rank, dynamic player) {
    final gamesWon = player['games_won'] ?? 0;
    final gamesLost = player['games_lost'] ?? 0;
    final currentRating = player['current_rating']?.round() ?? 0;

    final pointsWon = player['points_won'] ?? 0;
    final pointsLost = player['points_lost'] ?? 0;
    final totalPoints = pointsWon + pointsLost;

    final pointWonPct = player['points_won_percentage'] != null
        ? (player['points_won_percentage'] as num).round()
        : (totalPoints > 0 ? ((pointsWon / totalPoints) * 100).round() : 0);

    final bool isTopTier = rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isTopTier ? _lime : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 35,
            child: Text(
              '#$rank',
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _lime,
              ),
            ),
          ),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPlayerNameWithInitial(player),
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rating: $currentRating • W:$gamesWon L:$gamesLost',
                  style: GoogleFonts.robotoMono(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

          // Point won percentage
          Text(
            '$pointWonPct%',
            style: GoogleFonts.robotoMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _lime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 25),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand tag
          RichText(
            text: TextSpan(
              style: GoogleFonts.oswald(
                fontSize: 16,
                letterSpacing: 1,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: 'CREATED BY '),
                TextSpan(
                  text: 'PICKLEBRACKET',
                  style: GoogleFonts.oswald(
                    color: _lime,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Web link
          RichText(
            text: TextSpan(
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
              ),
              children: [
                const TextSpan(text: 'Learn more at '),
                TextSpan(
                  text: 'www.picklebracket.pro',
                  style: GoogleFonts.robotoMono(
                    color: _lime,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTeamNames(dynamic team) {
    if (team is List && team.isNotEmpty) {
      final player1 = _getPlayerNameWithInitial(team[0]);
      final player2 = team.length > 1 ? _getPlayerNameWithInitial(team[1]) : '';
      return player2.isNotEmpty ? '$player1 & $player2' : player1;
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

      return player2.isNotEmpty ? '$player1 $player2' : player1;
    }
    return 'Team Name';
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
