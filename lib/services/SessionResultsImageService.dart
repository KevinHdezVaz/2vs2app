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

/// Servicio para generar y compartir imágenes de resultados de sesión
/// 
/// Este servicio crea una imagen PNG de alta calidad con los resultados
/// de la sesión y permite compartirla usando el sistema nativo del OS.

// Definición de colores clave
const Color _primaryColorDark = Color(0xFF2B5F5F); // Teal oscuro
const Color _backgroundColor = Color(0xFF1E4D4D); // Fondo más oscuro para el header

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
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
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
    // ✅ CAMBIO 2: Mostrar hasta 12 jugadores siempre
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

  /// ✅ CAMBIO 1: Header sin "SESSION COMPLETE" y subtitulo más grande
  Widget _buildHeader() {
    final sessionName = sessionData['session_name']?.toString().toUpperCase() ?? 'SESSION RESULTS';
    final sessionTypeFormatted = SessionResultsImageService._getSessionTypeName(sessionType);
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

          // ✅ Session type y fecha MÁS GRANDE
          Text(
            '$sessionTypeFormatted | $dateFormatted',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24, // ← Aumentado de 20 a 24
              fontWeight: FontWeight.w600, // ← Más bold
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  /// Session info summary
  Widget _buildSessionInfo() {
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
          _buildInfoBox('${numberOfPlayers == 0 ? 12 : numberOfPlayers}', 'PLAYERS', Icons.people),
          _buildInfoBox('${numberOfCourts == 0 ? 3 : numberOfCourts}', 'COURTS', Icons.sports_tennis),
          _buildInfoBox(
            SessionResultsImageService._formatDuration(duration == 0 ? 6300 : duration),
            'DURATION',
            Icons.access_time,
          ),
          _buildInfoBox('${completedGames == 0 ? 28 : completedGames}', 'GAMES PLAYED', Icons.sports_score),
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

  /// ✅ CAMBIO 4: Oro en el centro, plata a la izquierda, bronce a la derecha
  Widget _buildMedalWinners() {
    final champions = playoffWinners!.length > 0 ? playoffWinners![0] : null;
    final runnersUp = playoffWinners!.length > 1 ? playoffWinners![1] : null;
    final thirdPlace = playoffWinners!.length > 2 ? playoffWinners![2] : null;

    final dummyGold = {'first_name': 'Juan Pablo', 'last_initial': 'R', 'second_player_name': 'Rafaela', 'second_player_last_initial': 'M'};
    final dummySilver = {'first_name': 'Alesandro', 'last_initial': 'G', 'second_player_name': 'Nazli', 'second_player_last_initial': 'K'};
    final dummyBronze = {'first_name': 'Ricardo', 'last_initial': 'S', 'second_player_name': 'Carmen', 'second_player_last_initial': 'L'};

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

          // ✅ NUEVO ORDEN: Plata - Oro - Bronce
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMedalCard('SILVER', runnersUp ?? dummySilver),
              _buildMedalCard('GOLD', champions ?? dummyGold),
              _buildMedalCard('BRONZE', thirdPlace ?? dummyBronze),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ CAMBIO 3: Agregar inicial del apellido
  Widget _buildMedalCard(String medal, dynamic team) {
    String teamNames;
    if (team is List) {
      final player1 = _getPlayerNameWithInitial(team[0]);
      final player2 = team.length > 1 ? '& ${_getPlayerNameWithInitial(team[1])}' : '';
      teamNames = '$player1 $player2';
    } else if (team is Map) {
      final p1FirstName = team['first_name']?.toString() ?? 'Player';
      final p1LastInitial = team['last_initial']?.toString() ?? '';
      final p2FirstName = team['second_player_name']?.toString() ?? '';
      final p2LastInitial = team['second_player_last_initial']?.toString() ?? '';
      
      final player1 = p1LastInitial.isNotEmpty ? '$p1FirstName ${p1LastInitial}.' : p1FirstName;
      final player2 = p2FirstName.isNotEmpty && p2LastInitial.isNotEmpty 
          ? '& $p2FirstName ${p2LastInitial}.' 
          : (p2FirstName.isNotEmpty ? '& $p2FirstName' : '');
      
      teamNames = player2.isNotEmpty ? '$player1 $player2' : player1;
    } else {
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
        cardGradient = const LinearGradient(colors: [Colors.grey, Colors.white]);
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
 
  /// ✅ CAMBIO 2: Grid de 2 columnas para mostrar todos los jugadores (hasta 12)
  Widget _buildTopRankings({int showTop = 12}) {
    final topPlayers = players.take(showTop).toList();
    
    final List<Map<String, dynamic>> dummyPlayers = [
      {'first_name': 'Juan Pablo', 'last_initial': 'R', 'current_rating': 1045, 'games_won': 7, 'games_lost': 1},
      {'first_name': 'Ricardo', 'last_initial': 'S', 'current_rating': 1045, 'games_won': 7, 'games_lost': 1},
      {'first_name': 'Alesandro', 'last_initial': 'G', 'current_rating': 1040, 'games_won': 7, 'games_lost': 1},
      {'first_name': 'Nazli', 'last_initial': 'K', 'current_rating': 1035, 'games_won': 6, 'games_lost': 2},
      {'first_name': 'Risma', 'last_initial': 'T', 'current_rating': 1030, 'games_won': 6, 'games_lost': 2},
      {'first_name': 'Alex', 'last_initial': 'M', 'current_rating': 1025, 'games_won': 5, 'games_lost': 3},
      {'first_name': 'Laura', 'last_initial': 'P', 'current_rating': 1020, 'games_won': 5, 'games_lost': 3},
      {'first_name': 'David', 'last_initial': 'H', 'current_rating': 1015, 'games_won': 4, 'games_lost': 4},
      {'first_name': 'Maria', 'last_initial': 'C', 'current_rating': 1010, 'games_won': 4, 'games_lost': 4},
      {'first_name': 'Carlos', 'last_initial': 'L', 'current_rating': 1005, 'games_won': 3, 'games_lost': 5},
      {'first_name': 'Sofia', 'last_initial': 'V', 'current_rating': 1000, 'games_won': 3, 'games_lost': 5},
      {'first_name': 'Miguel', 'last_initial': 'N', 'current_rating': 995, 'games_won': 2, 'games_lost': 6},
    ];
    
    final List<dynamic> playersToDisplay = topPlayers.isEmpty 
        ? dummyPlayers.take(showTop).toList() 
        : topPlayers;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          Text(
            '-- TOP ${showTop} RANKINGS --',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 20),

          // ✅ Grid de 2 columnas
          Wrap(
            spacing: 15,
            runSpacing: 12,
            children: List.generate(
              playersToDisplay.length,
              (index) {
                return _buildPlayerRankCardCompact(index + 1, playersToDisplay[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ CAMBIO 2 y 3: Card más compacta con inicial del apellido
/// ✅ CAMBIO 2 y 3: Card más compacta con inicial del apellido - ANCHO DE RANK CORREGIDO
Widget _buildPlayerRankCardCompact(int rank, dynamic player) {
  final gamesWon = player['games_won'] ?? 0;
  final gamesLost = player['games_lost'] ?? 0;
  final currentRating = player['current_rating']?.round() ?? 0; 

  final Color rankColor = (rank == 1 || rank == 2) 
      ? _primaryColorDark 
      : const Color(0xFF5A5A5A);

  return Container(
    width: 485,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ✅ RANK NUMBER - MÁS ANCHO PARA 2 DÍGITOS
        SizedBox(
          width: 55, // ← AUMENTADO de 45 a 55
          child: Text(
            '#$rank',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24, // ← REDUCIDO de 26 a 24 (opcional)
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          ),
        ),

        const SizedBox(width: 10), // ← REDUCIDO de 12 a 10

        // Player name con inicial del apellido + Rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getPlayerNameWithInitial(player),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '(Rating: $currentRating)',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
            ],
          ),
        ),
        
        // Win/Loss record
        _buildStatBadge('W: $gamesWon / L: $gamesLost', Colors.grey.shade100, const Color(0xFF5A5A5A)),
      ],
    ),
  );
}

  Widget _buildStatBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '($text)',
        style: GoogleFonts.lato(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
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
                  child: Text('PB', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildFooter() => _buildFooterSimple();

  /// ✅ CAMBIO 3: Método mejorado para obtener nombre con inicial del apellido
  String _getPlayerNameWithInitial(dynamic player) {
    if (player == null) return 'Unknown Player';

    if (player is String) return player;
    
    final firstName = player['first_name']?.toString() ?? '';
    
    // ✅ CORREGIDO: Priorizar 'last_initial' que viene del backend
    final lastInitial = player['last_initial']?.toString() ?? 
                        (player['last_name']?.toString().isNotEmpty == true 
                            ? player['last_name'].toString().substring(0, 1) 
                            : '');

    if (firstName.isNotEmpty && lastInitial.isNotEmpty) {
      // ✅ Si last_initial ya incluye el punto, no agregarlo de nuevo
      if (lastInitial.endsWith('.')) {
        return '$firstName $lastInitial';
      }
      return '$firstName ${lastInitial}.';
    } else if (firstName.isNotEmpty) {
      return firstName;
    }

    return 'Unknown Player';
  }

  String _getPlayerName(dynamic player) => _getPlayerNameWithInitial(player);
}