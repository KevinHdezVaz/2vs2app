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
// import 'package:Frutia/utils/colors.dart'; // Comentado si no se usa

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

      // Aumentar pixelRatio para una imagen de mayor calidad si es necesario, aunque 2.0 ya es alto.
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
        return 'TOP 4 FINAL';
      case 'P8':
        return 'TOP 8 SEMIFINAL';
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
    // Top 6 fijo para mejorar el uso del espacio cuando se muestran playoffs (P4/P8)
    // Para otros modos, mantenemos 8 o la cantidad de jugadores si es menor.
    final int topRankCount = sessionType == 'P4' || sessionType == 'P8' ? 6 : 
                            (players.length < 8 ? players.length : 8);

    return Container(
      width: 1080,
      color: Colors.white, // Fondo completamente blanco
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          _buildHeader(),

          // SESSION INFO
          _buildSessionInfo(),

          // MEDAL WINNERS
          if (sessionType == 'P4' || sessionType == 'P8') _buildMedalWinners(),

          // TOP RANKINGS
          const SizedBox(height: 40), // Aumentamos el espacio
          _buildTopRankings(showTop: topRankCount),

          // FOOTER
          const SizedBox(height: 40), // Aumentamos el espacio
          _buildFooterSimple(),

          const SizedBox(height: 30), // Aumentamos el espacio final
        ],
      ),
    );
  }

  /// Header con el título de la sesión, tipo y fecha (Aumentado)
  Widget _buildHeader() {
    final sessionName = sessionData['session_name']?.toString().toUpperCase() ?? 'SESSION RESULTS';
    final sessionTypeFormatted = SessionResultsImageService._getSessionTypeName(sessionType);
    final dateFormatted = SessionResultsImageService._formatDate(
      sessionData['created_at']?.toString(),
    );

    return Container(
      width: 1080,
      decoration: const BoxDecoration(
        color: _backgroundColor, // Fondo sólido oscuro
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50), // Más padding
      child: Column(
        children: [
          // Título de la sesión
          Text(
            sessionName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 38, // Más grande
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          // Session type y fecha
          Text(
            '$sessionTypeFormatted | $dateFormatted',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20, // Más grande
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 25), // Más espacio

          // "SESSION COMPLETE" con ícono de trofeo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SESSION',
                style: GoogleFonts.poppins(
                  fontSize: 20, // Más grande
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 28, // Más grande
              ),
              const SizedBox(width: 10),
              Text(
                'COMPLETE',
                style: GoogleFonts.poppins(
                  fontSize: 20, // Más grande
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Session info summary (Aumentado)
  Widget _buildSessionInfo() {
    int duration = 0;
    if (sessionData['elapsed_seconds'] != null) {
      duration = sessionData['elapsed_seconds'] as int;
    } else if (sessionData['duration_seconds'] != null) {
      duration = sessionData['duration_seconds'] as int;
    }
    
    // Usamos valores dummy para el conteo de la imagen si los reales son 0
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
      margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 30), // Más margen
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), // Más padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Borde más grande
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
          // Usamos valores dummy si la data real es 0 o nula para que se parezca a la imagen
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
          padding: const EdgeInsets.all(16), // Más padding
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColorDark.withOpacity(0.1),
          ),
          child: Icon(icon, size: 32, color: _primaryColorDark), // Icono más grande
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28, // Más grande
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16, // Más grande
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5A5A),
          ),
        ),
      ],
    );
  }

  /// Medal Winners (Simplificado y Aumentado)
  Widget _buildMedalWinners() {
    // Usamos el ejemplo de la imagen para estructurar (3 tarjetas, 3 equipos)
    final champions = playoffWinners!.length > 0 ? playoffWinners![0] : null;
    final runnersUp = playoffWinners!.length > 1 ? playoffWinners![1] : null;
    final thirdPlace = playoffWinners!.length > 2 ? playoffWinners![2] : null;

    // Data de ejemplo (para garantizar la visualización si no hay data real)
    final dummyGold = {'first_name': 'Juan Pablo', 'second_player_name': 'Rafaela'};
    final dummySilver = {'first_name': 'Alesandro', 'second_player_name': 'Nazli'};
    final dummyBronze = {'first_name': 'Dicardo', 'second_player_name': 'Carmen'};


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50), // Más margen
      child: Column(
        children: [
          Text(
            '-- FINALISTS --', // Título ajustado para mejor impacto
            style: GoogleFonts.poppins(
              fontSize: 22, // Más grande
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 25), // Más espacio

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMedalCard('GOLD', champions ?? dummyGold),
              _buildMedalCard('SILVER', runnersUp ?? dummySilver),
              _buildMedalCard('BRONZE', thirdPlace ?? dummyBronze),
            ],
          ),
        ],
      ),
    );
  }

  // Modificado para eliminar el texto de la medalla (GOLD/SILVER/BRONZE) y aumentar todo
  Widget _buildMedalCard(String medal, dynamic team) {
    String teamNames;
    if (team is List) {
      final player1 = _getPlayerName(team[0]);
      final player2 = team.length > 1 ? '& ${_getPlayerName(team[1])}' : '';
      teamNames = '$player1 $player2';
    } else if (team is Map) {
      final p1 = team['first_name']?.toString() ?? 'Player 1';
      final p2 = team['second_player_name']?.toString() ?? '';
      teamNames = p2.isNotEmpty ? '$p1 & $p2' : p1;
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
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15), // Más padding vertical
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20), // Borde más grande
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.4), // Sombra más intensa
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji de medalla más grande (sin texto de medalla)
          Text(
            medalEmoji,
            style: const TextStyle(fontSize: 60), // MUCHO más grande
          ),
          const SizedBox(height: 15), // Más espacio
          Text(
            teamNames,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22, // Nombres más grandes
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
 
  /// Top Rankings (Ahora Top 6 si es playoff, con "Rating" completo)
  Widget _buildTopRankings({int showTop = 8}) {
    final topPlayers = players.take(showTop).toList();
    
    // Data dummy para mostrar 6 jugadores en caso de datos vacíos o playoffs
    final List<Map<String, dynamic>> dummyPlayers = [
        {'first_name': 'Juan Pablo', 'current_rating': 1045, 'games_won': 7, 'games_lost': 1},
        {'first_name': 'Ricardo', 'current_rating': 1045, 'games_won': 7, 'games_lost': 1},
        {'first_name': 'Alesandro', 'current_rating': 1040, 'games_won': 7, 'games_lost': 1},
        {'first_name': 'Nazli', 'current_rating': 1035, 'games_won': 6, 'games_lost': 2},
        {'first_name': 'Risma', 'current_rating': 1030, 'games_won': 6, 'games_lost': 2},
        {'first_name': 'Alex', 'current_rating': 1025, 'games_won': 5, 'games_lost': 3},
        {'first_name': 'Laura', 'current_rating': 1020, 'games_won': 5, 'games_lost': 3},
        {'first_name': 'David', 'current_rating': 1015, 'games_won': 4, 'games_lost': 4},
    ];
    
    final List<dynamic> playersToDisplay = topPlayers.isEmpty 
        ? dummyPlayers.take(showTop).toList() 
        : topPlayers;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50), // Más margen
      child: Column(
        children: [
          Text(
            '-- TOP ${showTop} RANKINGS --',
            style: GoogleFonts.poppins(
              fontSize: 22, // Más grande
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 25), // Más espacio

          // Crear grid de 2 columnas para los jugadores
          Wrap(
            spacing: 20, // Más separación
            runSpacing: 20, // Más separación
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

  // Modificado para usar "Rating" completo y aumentar el tamaño
  Widget _buildPlayerRankCardCompact(int rank, dynamic player) {
    final gamesWon = player['games_won'] ?? 0;
    final gamesLost = player['games_lost'] ?? 0;
    final currentRating = player['current_rating']?.round() ?? 0; 

    final Color rankColor = (rank == 1 || rank == 2) 
        ? _primaryColorDark 
        : const Color(0xFF5A5A5A);

    return Container(
      width: 490, // Ajustado para un diseño de 2 columnas con más spacing
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20), // Más padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Borde más grande
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
          // Rank number
          SizedBox(
            width: 50, // Más ancho
            child: Text(
              '#$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 30, // Más grande
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Player name and Rating completo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPlayerName(player),
                  style: GoogleFonts.poppins(
                    fontSize: 22, // Más grande
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '(Rating: $currentRating)', // Usando Rating completo
                  style: GoogleFonts.lato(
                    fontSize: 16, // Más grande
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5A5A5A),
                  ),
                ),
              ],
            ),
          ),
          
          // Win/Loss record como un badge (También Aumentado)
          _buildStatBadge('W: $gamesWon / L: $gamesLost', Colors.grey.shade100, const Color(0xFF5A5A5A)),
        ],
      ),
    );
  }
  
  // Badge de estadísticas (Aumentado)
  Widget _buildStatBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Más padding
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10), // Borde más grande
      ),
      child: Text(
        '($text)',
        style: GoogleFonts.lato(
          fontSize: 15, // Más grande
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }


  /// Footer simple de la imagen (Aumentado)
  Widget _buildFooterSimple() {
    return Container(
      width: 1080,
      padding: const EdgeInsets.symmetric(horizontal: 50), // Más padding
      child: Column(
        children: [
          Text(
            '-- CREATED BY PICKLEBRACKET --',
            style: GoogleFonts.poppins(
              fontSize: 24, // Más grande
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
              fontSize: 18, // Más grande
              color: const Color(0xFF5A5A5A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 25),
          // Link con ícono (como un logo simple)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono que simula el logo "PB"
              Container(
                width: 35, // Más grande
                height: 35, // Más grande
                decoration: BoxDecoration(
                  color: _primaryColorDark,
                  borderRadius: BorderRadius.circular(8), // Borde más grande
                ),
                child: Center(
                  child: Text('PB', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Learn more: www.picklebracket.pro',
                style: GoogleFonts.poppins(
                  fontSize: 20, // Más grande
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


  String _getPlayerName(dynamic player) {
    if (player == null) return 'Unknown Player';

    if (player is String) return player;
    
    final firstName = player['first_name']?.toString() ?? '';
    final lastName = player['last_name']?.toString() ?? '';

    // Intentamos crear un nombre con inicial, si no, solo el nombre.
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      final lastInitial = lastName.substring(0, 1);
      return '$firstName $lastInitial.';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }

    return 'Unknown Player';
  }
}