// lib/services/SessionResultsImage.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Frutia/utils/colors.dart';

/// Servicio para generar y compartir imágenes de resultados de sesión
/// 
/// Este servicio crea una imagen PNG de alta calidad con los resultados
/// de la sesión y permite compartirla usando el sistema nativo del OS.

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

      // Compartir usando Share Plus
      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'Check out the results from ${sessionData['session_name']}! 🎾',
        subject: '${sessionData['session_name']} - Session Results',
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

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
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

  /// Método alternativo: Genera la imagen usando CustomPainter (más control)
  static Future<Uint8List> _generateImageWithPainter({
    required Map<String, dynamic> sessionData,
    required List<dynamic> players,
    required String sessionType,
    List<dynamic>? playoffWinners,
  }) async {
    // Dimensiones de la imagen
    const width = 1080.0;
    const height = 1920.0;

    // Crear el recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    // Fondo
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      backgroundPaint,
    );

    // Header con gradiente
    final headerGradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(1080, 400),
      [
        FrutiaColors.primary,
        FrutiaColors.primary.withOpacity(0.8),
      ],
    );

    final headerPaint = Paint()..shader = headerGradient;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 1080, 400),
        const Radius.circular(0),
      ),
      headerPaint,
    );

    // Crear la imagen final
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // Helpers
  static String _getSessionTypeName(String sessionType) {
    switch (sessionType) {
      case 'O':
        return 'Optimized';
      case 'T':
        return 'Tournament';
      case 'P4':
        return 'Playoff (4)';
      case 'P8':
        return 'Playoff (8)';
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
    final isPlayoffMode = sessionType == 'P4' || sessionType == 'P8';

    return Container(
      width: 1080,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════
          // HEADER CON GRADIENTE
          // ═══════════════════════════════════════
          _buildHeader(),

          // ═══════════════════════════════════════
          // SESSION INFO
          // ═══════════════════════════════════════
          _buildSessionInfo(),

          // ═══════════════════════════════════════
          // RESULTS SECTION
          // ═══════════════════════════════════════
          if (isPlayoffMode)
            _buildPlayoffResults()
          else
            _buildTopPlayersResults(),

          // ═══════════════════════════════════════
          // FOOTER
          // ═══════════════════════════════════════
          _buildFooter(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Header con gradiente y logo
  Widget _buildHeader() {
    return Container(
      width: 1080,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FrutiaColors.primary,
            FrutiaColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/raaqueta.png',
              width: 80,
              height: 80,
            ),
          ),

          const SizedBox(height: 24),

          // Título
          Text(
            sessionData['session_name'] ?? 'Session Results',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Subtítulo
          Text(
            '🏆 Session Complete',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  /// Session info summary
  Widget _buildSessionInfo() {
    // ✅ CALCULAR duración desde elapsed_seconds o created_at
    int duration = 0;
    if (sessionData['elapsed_seconds'] != null) {
      duration = sessionData['elapsed_seconds'] as int;
    } else if (sessionData['duration_seconds'] != null) {
      duration = sessionData['duration_seconds'] as int;
    }
    
    final numberOfPlayers = sessionData['number_of_players'] ?? 0;
    final numberOfCourts = sessionData['number_of_courts'] ?? 0;
    
    // ✅ OBTENER completed games count desde la lista de players o calcular
    int completedGames = 0;
    if (players.isNotEmpty && players[0]['games_played'] != null) {
      // Calcular desde los juegos de los jugadores
      int totalGamesPlayed = 0;
      for (var player in players) {
        totalGamesPlayed += (player['games_played'] as int? ?? 0);
      }
      // Cada juego cuenta 4 veces (2 jugadores por equipo)
      completedGames = (totalGamesPlayed / 4).floor();
    }

    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: FrutiaColors.secondaryBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FrutiaColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            SessionResultsImageService._getSessionTypeName(sessionType),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoBox('$numberOfPlayers', 'Players', Icons.people),
              _buildInfoBoxWithImage('$numberOfCourts', 'Courts', 'assets/icons/icono_cancha.png'),
              _buildInfoBox(
                SessionResultsImageService._formatDuration(duration),
                'Duration',
                Icons.timer,
              ),
              _buildInfoBox('$completedGames', 'Games', Icons.emoji_events),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: FrutiaColors.primary),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 18,
            color: FrutiaColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBoxWithImage(String value, String label, String assetPath) {
    return Column(
      children: [
        Image.asset(
          assetPath,
          width: 60,
          height: 60,
          color: FrutiaColors.primary,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 18,
            color: FrutiaColors.secondaryText,
          ),
        ),
      ],
    );
  }

  /// Resultados para modo Playoff (Podio)
  Widget _buildPlayoffResults() {
    if (playoffWinners == null || playoffWinners!.isEmpty) {
      return _buildTopPlayersResults(); // Fallback
    }

    // Extraer ganadores
    final champions = playoffWinners!.length > 0 ? playoffWinners![0] : null;
    final runnersUp = playoffWinners!.length > 1 ? playoffWinners![1] : null;
    final thirdPlace = playoffWinners!.length > 2 ? playoffWinners![2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            '🏆 Congratulations Winners',
            style: GoogleFonts.poppins(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 32),

          // 🥇 Champions
          if (champions != null) _buildPodiumCard('🥇', 'CHAMPIONS', champions, const Color(0xFFFFD700)),

          const SizedBox(height: 20),

          // 🥈 Runners-up
          if (runnersUp != null) _buildPodiumCard('🥈', 'RUNNERS UP', runnersUp, const Color(0xFFC0C0C0)),

          // 🥉 Third Place
          if (thirdPlace != null) ...[
            const SizedBox(height: 20),
            _buildPodiumCard('🥉', 'THIRD PLACE', thirdPlace, const Color(0xFFCD7F32)),
          ],
        ],
      ),
    );
  }

  Widget _buildPodiumCard(String emoji, String title, dynamic team, Color color) {
    // team puede ser una lista de jugadores
    final players = team is List ? team : [team];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final player in players)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getPlayerName(player),
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Resultados para modo Optimized (Top 5)
  Widget _buildTopPlayersResults() {
    final topPlayers = players.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            '🎯 Top Performers',
            style: GoogleFonts.poppins(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 32),

          for (var i = 0; i < topPlayers.length; i++)
            _buildPlayerRankCard(i + 1, topPlayers[i]),
        ],
      ),
    );
  }

  Widget _buildPlayerRankCard(int rank, dynamic player) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '';

    Color? backgroundColor;
    if (rank == 1) {
      backgroundColor = const Color(0xFFFFD700).withOpacity(0.15);
    } else if (rank == 2) {
      backgroundColor = const Color(0xFFC0C0C0).withOpacity(0.15);
    } else if (rank == 3) {
      backgroundColor = const Color(0xFFCD7F32).withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? FrutiaColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
              ? (rank == 1
                  ? const Color(0xFFFFD700)
                  : rank == 2
                      ? const Color(0xFFC0C0C0)
                      : const Color(0xFFCD7F32))
              : FrutiaColors.tertiaryBackground,
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank/Medal
          SizedBox(
            width: 80,
            child: Text(
              medal.isNotEmpty ? medal : '#$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPlayerName(player),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player['games_played'] ?? 0} games • ${player['win_percentage']?.toInt() ?? 0}% win rate',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    color: FrutiaColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Rating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: FrutiaColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${player['current_rating']?.round().toString() ?? '0'}',
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 40, bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FrutiaColors.tertiaryBackground,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Generated by Picklebracket',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SessionResultsImageService._formatDate(
              sessionData['created_at']?.toString(),
            ),
            style: GoogleFonts.lato(
              fontSize: 18,
              color: FrutiaColors.secondaryText.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlayerName(dynamic player) {
    if (player == null) return 'Unknown Player';

    final firstName = player['first_name']?.toString() ?? '';
    final lastInitial = player['last_initial']?.toString() ?? '';

    if (firstName.isNotEmpty && lastInitial.isNotEmpty) {
      return '$firstName $lastInitial.';
    } else if (firstName.isNotEmpty) {
      return firstName;
    }

    return 'Unknown Player';
  }
}