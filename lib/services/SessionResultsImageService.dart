// lib/services/SessionResultsImage.dart
// ✅ DISEÑO ACTUALIZADO: 100% idéntico al mockup HTML final

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores del brand - exactos del HTML
const Color _navy = Color(0xFF061848);
const Color _navyCard = Color(0xFF0A1E5A);
const Color _lime = Color(0xFFE9FE1F);
const Color _white = Color(0xFFFFFFFF);
const Color _gold = Color(0xFFF2C94C);
const Color _silver = Color(0xFFE0E0E0);
const Color _bronze = Color(0xFFCD7F32);

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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
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
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: _lime, width: 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 100,
              offset: const Offset(0, 40),
            ),
          ],
        ),
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            _buildHeader(),

            // FINALISTS (solo para playoffs)
            if (sessionType == 'P4' || sessionType == 'P8') ...[
              const SizedBox(height: 40),
              _buildFinalistsSection(),
            ],

            // INDIVIDUAL RANKINGS
            const SizedBox(height: 40),
            _buildIndividualRankings(showTop: topRankCount),

            // FOOTER
            const SizedBox(height: 50),
            _buildFooter(),
          ],
        ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // LEFT: Session name and type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: GoogleFonts.oswald(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    height: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '$sessionTypeFormatted • $dateFormatted',
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: _lime,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // RIGHT: Stats strip
          Row(
            children: [
              _buildStatBox('$numberOfPlayers', 'Players'),
              const SizedBox(width: 30),
              _buildStatBox('$numberOfCourts', 'Courts'),
              const SizedBox(width: 30),
              _buildStatBox(
                SessionResultsImageService._formatDuration(duration),
                'Duration',
              ),
              const SizedBox(width: 30),
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
          style: GoogleFonts.oswald(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: _white,
            height: 1,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            color: _white,
            fontWeight: FontWeight.w400,
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
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // SILVER (Runner-up) - Left
            if (runnersUp != null)
              Expanded(
                child: _buildPodiumCard(
                    '2', runnersUp, 'RUNNER UP', _silver, false),
              ),
            if (runnersUp != null) const SizedBox(width: 20),

            // GOLD (Champions) - Center (slightly taller)
            Expanded(
              child: _buildPodiumCard('1', champions, 'CHAMPIONS', _gold, true),
            ),

            // BRONZE (3rd Place) - Right
            if (thirdPlace != null) const SizedBox(width: 20),
            if (thirdPlace != null)
              Expanded(
                child: _buildPodiumCard(
                    '3', thirdPlace, '3RD PLACE', _bronze, false),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumCard(String number, dynamic team, String label,
      Color medalColor, bool isGold) {
    String teamNames = _getTeamNames(team);

    return Container(
      height: isGold ? 210 : 180,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: isGold ? _navyCard : _navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGold ? _lime : Colors.transparent,
          width: 2,
        ),
        gradient: isGold
            ? RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  _lime.withOpacity(0.1),
                  _navyCard,
                ],
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // ✅ Cambiado a min
        children: [
          // Medal circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Team names - ✅ Wrapped in Flexible
          Flexible(
            child: Text(
              teamNames,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _white,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Label
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              color: isGold ? _lime : const Color(0xFF888888),
              fontWeight: isGold ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualRankings({int showTop = 12}) {
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
          'INDIVIDUAL RANKINGS',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 30),
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

    // Color del número según el ranking
    Color numColor = _white;
    if (rank == 1) numColor = _gold;
    if (rank == 2) numColor = _silver;
    if (rank == 3) numColor = _bronze;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 45,
            child: Text(
              '#$rank',
              style: GoogleFonts.oswald(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: numColor,
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Player info con stats al lado
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Nombre
                Flexible(
                  child: Text(
                    _getPlayerNameWithInitial(player),
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 12),

                // Stats
                Text(
                  'Rating: $currentRating | $gamesWon-$gamesLost',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: _white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          // Points won percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pointWonPct%',
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: _lime,
                  height: 1,
                ),
              ),
              Text(
                'POINTS WON',
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  color: _lime.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 30),
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
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                color: _white,
                fontWeight: FontWeight.w400,
              ),
              children: [
                const TextSpan(text: 'CREATED BY '),
                TextSpan(
                  text: 'PICKLEBRACKET',
                  style: GoogleFonts.robotoMono(
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
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: _white,
              ),
              children: [
                const TextSpan(text: 'www.picklebracket'),
                TextSpan(
                  text: '.pro',
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
