// lib/pages/screens/sessionControl/SessionControlPanel.dart
import 'package:Frutia/pages/screens/SessionControl/ScoreEntryDialog.dart';
import 'package:Frutia/pages/screens/SessionControl/StageCompleteDialog.dart';
import 'package:Frutia/pages/screens/SessionControl/PlayoffBracketDialog.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
 import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class SessionControlPanel extends StatefulWidget {
  final int sessionId;
  final bool isSpectator; // 🆕
  
  const SessionControlPanel({
    super.key,
    required this.sessionId,
    this.isSpectator = false, // 🆕 Por defecto es false
  });

  @override
  State<SessionControlPanel> createState() => _SessionControlPanelState();
}

class _SessionControlPanelState extends State<SessionControlPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  Timer? _sessionTimer;
  
  Map<String, dynamic>? _sessionData;
  List<dynamic> _liveGames = [];
  List<dynamic> _nextGames = [];
  List<dynamic> _completedGames = [];
  List<dynamic> _players = [];
  
  bool _isLoading = true;
  bool _hasShownStageDialog = false;
  bool _hasShownPlayoffDialog = false;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSessionData();
    _startTimers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadSessionData(silent: true);
    });
    
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

Future<void> _loadSessionData({bool silent = false}) async {
  if (!silent) {
    setState(() {
      _isLoading = true;
    });
  }

  try {
    final sessionResponse = widget.isSpectator 
        ? await SessionService.getPublicSession(widget.sessionId)  // 👈 Público
        : await SessionService.getSession(widget.sessionId);       // 👈 Autenticado
    
    final session = sessionResponse['session'];
    
    final liveGames = widget.isSpectator
        ? await SessionService.getPublicGamesByStatus(widget.sessionId, 'active')
        : await SessionService.getGamesByStatus(widget.sessionId, 'active');
    
    final nextGames = widget.isSpectator
        ? await SessionService.getPublicGamesByStatus(widget.sessionId, 'pending')
        : await SessionService.getGamesByStatus(widget.sessionId, 'pending');
    
    final completedGames = widget.isSpectator
        ? await SessionService.getPublicGamesByStatus(widget.sessionId, 'completed')
        : await SessionService.getGamesByStatus(widget.sessionId, 'completed');
    
    final players = widget.isSpectator
        ? await SessionService.getPublicPlayerStats(widget.sessionId)
        : await SessionService.getPlayerStats(widget.sessionId);

    if (mounted) {
      setState(() {
        _sessionData = session;
        _liveGames = liveGames;
        _nextGames = nextGames;
        _completedGames = completedGames;
        _players = players;
        _isLoading = false;
      });

      if (!widget.isSpectator) {
        _checkForStageOrPlayoffCompletion();
      }
    }
  } catch (e) {
    print('[SessionControlPanel] Error: $e');
    // ... manejo de error
  }
}
  void _checkForStageOrPlayoffCompletion() {
    if (_sessionData == null) return;

    final sessionType = _sessionData!['session_type'];
    final status = _sessionData!['status'];

    if (status != 'active') return;

    // TOURNAMENT: Check if stage is complete
    if (sessionType == 'T') {
      final currentStage = _sessionData!['current_stage'] ?? 1;
      
      final hasActiveGames = _liveGames.isNotEmpty;
      final hasPendingGamesInCurrentStage = _nextGames.any((game) => 
        game['stage'] == currentStage
      );

      if (!hasActiveGames && !hasPendingGamesInCurrentStage && currentStage < 3 && !_hasShownStageDialog) {
        _hasShownStageDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => StageCompleteDialog(
                sessionId: widget.sessionId,
                currentStage: currentStage,
                onStageAdvanced: () {
                  _hasShownStageDialog = false;
                  _loadSessionData();
                },
              ),
            );
          }
        });
      }
    }

    // PLAYOFFS: Check if random phase is done and bracket should be generated
    if (sessionType == 'P4' || sessionType == 'P8') {
      final hasPlayoffGames = _liveGames.any((game) => 
        game['is_playoff_game'] == true
      ) || _nextGames.any((game) => 
        game['is_playoff_game'] == true
      ) || _completedGames.any((game) => 
        game['is_playoff_game'] == true
      );

      if (!hasPlayoffGames && _liveGames.isEmpty && _nextGames.isEmpty && !_hasShownPlayoffDialog) {
        _hasShownPlayoffDialog = true;
        final playersToTake = sessionType == 'P4' ? 4 : 8;
        final topPlayers = _players.take(playersToTake).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PlayoffBracketDialog(
                sessionId: widget.sessionId,
                sessionType: sessionType,
                topPlayers: topPlayers,
                onBracketGenerated: () {
                  _hasShownPlayoffDialog = false;
                  _loadSessionData();
                },
              ),
            );
          }
        });
      }
    }
  }

  String _formatTimer(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      backgroundColor: FrutiaColors.secondaryBackground,
      appBar: AppBar(
        title: const Text('Cargando...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
        ),
      ),
    );
  }

  final sessionName = _sessionData?['session_name'] ?? 'Sesión';
  final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
  final numberOfPlayers = _sessionData?['number_of_players'] ?? 0;
  final progressPercentage = _sessionData?['progress_percentage'] ?? 0.0;

  return Scaffold(
    backgroundColor: FrutiaColors.secondaryBackground,
    appBar: AppBar(
      backgroundColor: widget.isSpectator 
          ? FrutiaColors.primary 
          : FrutiaColors.primary,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de espectador
          if (widget.isSpectator)
            Container(
              margin: EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_red_eye, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'MODO ESPECTADOR',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            sessionName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          Text(
            '$numberOfCourts Canchas | $numberOfPlayers Jugadores | ${progressPercentage.toInt()}%',
            style: GoogleFonts.lato(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatTimer(_elapsedSeconds),
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Container(
          height: 4,
          child: LinearProgressIndicator(
            value: progressPercentage / 100,
            backgroundColor: FrutiaColors.tertiaryBackground,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isSpectator ? FrutiaColors.primary : FrutiaColors.primary
            ),
          ),
        ),
        
        Container(
          color: FrutiaColors.primaryBackground,
          child: TabBar(
            controller: _tabController,
            labelColor: widget.isSpectator ? FrutiaColors.primary : FrutiaColors.primary,
            unselectedLabelColor: FrutiaColors.disabledText,
            indicatorColor: widget.isSpectator ? FrutiaColors.primary : FrutiaColors.primary,
            tabs: [
              Tab(
                icon: const Icon(Icons.play_circle_filled),
                text: 'En Vivo (${_liveGames.length})',
              ),
              Tab(
                icon: const Icon(Icons.queue),
                text: 'Próximos (${_nextGames.length})',
              ),
              Tab(
                icon: const Icon(Icons.check_circle),
                text: 'Completados (${_completedGames.length})',
              ),
              Tab(
                icon: const Icon(Icons.leaderboard),
                text: 'Rankings',
              ),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLiveGamesTab(),
              _buildNextGamesTab(),
              _buildCompletedGamesTab(),
              _buildPlayerStatsTab(),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLiveGamesTab() {
    if (_liveGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis, size: 64, color: FrutiaColors.disabledText),
            const SizedBox(height: 16),
            Text(
              'No hay juegos activos',
              style: GoogleFonts.lato(
                fontSize: 16, 
                color: FrutiaColors.secondaryText
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _liveGames.length,
        itemBuilder: (context, index) {
          return _buildGameCard(_liveGames[index], isLive: true);
        },
      ),
    );
  }

  Widget _buildNextGamesTab() {
    if (_nextGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue, size: 64, color: FrutiaColors.disabledText),
            const SizedBox(height: 16),
            Text(
              'No hay juegos en cola',
              style: GoogleFonts.lato(
                fontSize: 16, 
                color: FrutiaColors.secondaryText
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nextGames.length,
        itemBuilder: (context, index) {
          return _buildGameCard(_nextGames[index]);
        },
      ),
    );
  }

  Widget _buildCompletedGamesTab() {
    if (_completedGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: FrutiaColors.disabledText),
            const SizedBox(height: 16),
            Text(
              'No hay juegos completados',
              style: GoogleFonts.lato(
                fontSize: 16, 
                color: FrutiaColors.secondaryText
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedGames.length,
        itemBuilder: (context, index) {
          return _buildGameCard(_completedGames[index], isCompleted: true);
        },
      ),
    );
  }

  Widget _buildPlayerStatsTab() {
    if (_players.isEmpty) {
      return Center(
        child: Text(
          'No hay jugadores',
          style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Table(
          border: TableBorder.all(color: FrutiaColors.tertiaryBackground, width: 1),
          columnWidths: const {
            0: FixedColumnWidth(50),
            1: FlexColumnWidth(2),
            2: FixedColumnWidth(60),
            3: FixedColumnWidth(70),
            4: FixedColumnWidth(90),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: FrutiaColors.secondaryBackground),
              children: [
                _buildTableHeader('#'),
                _buildTableHeader('Jugador'),
                _buildTableHeader('Juegos'),
                _buildTableHeader('% Win'),
                _buildTableHeader('Rating'),
              ],
            ),
            ..._players.map((player) {
              return TableRow(
                children: [
                  _buildTableCell(player['current_rank']?.toString() ?? '-'),
                  _buildTableCell('${player['first_name']} ${player['last_initial']}.'),
                  _buildTableCell(player['games_played']?.toString() ?? '0'),
                  _buildTableCell('${player['win_percentage']?.toInt() ?? 0}%'),
                  _buildTableCell(player['current_rating']?.toInt().toString() ?? '0'),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, 
          fontSize: 12,
          color: FrutiaColors.primaryText,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 12,
          color: FrutiaColors.primaryText,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

Widget _buildGameCard(Map<String, dynamic> game, {bool isLive = false, bool isCompleted = false}) {
  final team1Player1 = game['team1_player1'];
  final team1Player2 = game['team1_player2'];
  final team2Player1 = game['team2_player1'];
  final team2Player2 = game['team2_player2'];
  final court = game['court'];

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isLive ? FrutiaColors.success.withOpacity(0.1) : FrutiaColors.primaryBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isLive ? FrutiaColors.success : FrutiaColors.tertiaryBackground,
        width: isLive ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (court != null)
            Row(
              children: [
                Icon(Icons.sports_tennis, size: 16, color: FrutiaColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  court['court_name'] ?? 'Cancha',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: FrutiaColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: FrutiaColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'EN VIVO',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${team1Player1['first_name']} ${team1Player1['last_initial']}.',
                      style: GoogleFonts.poppins(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                    Text(
                      '${team1Player2['first_name']} ${team1Player2['last_initial']}.',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isCompleted)
                Text(
                  '${game['team1_score']} - ${game['team2_score']}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primary,
                  ),
                )
              else
                Text(
                  'VS',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.disabledText,
                  ),
                ),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${team2Player1['first_name']} ${team2Player1['last_initial']}.',
                      style: GoogleFonts.poppins(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      '${team2Player2['first_name']} ${team2Player2['last_initial']}.',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 🔥 SOLO MOSTRAR BOTONES SI NO ES ESPECTADOR
          if (!widget.isSpectator) ...[
            // Botón Registrar Score (juegos activos)
            if (isLive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ScoreEntryDialog(
                        game: game,
                        session: _sessionData!,
                        onScoreSubmitted: () {
                          _loadSessionData();
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FrutiaColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Registrar Resultado',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        '¿Cancelar juego?',
                        style: GoogleFonts.poppins(color: FrutiaColors.primaryText),
                      ),
                      content: Text(
                        'El juego volverá a la cola de pendientes.',
                        style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'No',
                            style: GoogleFonts.lato(color: FrutiaColors.primary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Sí, cancelar',
                            style: GoogleFonts.lato(color: FrutiaColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    try {
                      await GameService.cancelGame(game['id']);
                      _loadSessionData();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Juego cancelado'),
                            backgroundColor: FrutiaColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: FrutiaColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.cancel, size: 16),
                label: Text(
                  'Cancelar Juego',
                  style: GoogleFonts.lato(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: FrutiaColors.error,
                ),
              ),
            ],
            
            // Botón Start Game (juegos pending con cancha asignada)
            if (!isLive && !isCompleted && game['status'] == 'pending' && game['court_id'] != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await GameService.startGame(game['id']);
                      _loadSessionData();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Juego iniciado'),
                            backgroundColor: FrutiaColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: FrutiaColors.error,
                          ),
                        );
                      }
                    }
                  },  
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Iniciar Juego',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FrutiaColors.success,
                    side: BorderSide(color: FrutiaColors.success, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ], // 🔥 FIN del if (!widget.isSpectator)
        ],
      ),
    ),
  );
}
}