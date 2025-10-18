// lib/pages/screens/sessionControl/SessionControlPanel.dart
import 'package:Frutia/pages/screens/SessionControl/ScoreEntryDialog.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math'; // ← AGREGAR ESTA LÍNEA

class SessionControlPanel extends StatefulWidget {
  final int sessionId;
  final bool isSpectator;

  const SessionControlPanel({
    super.key,
    required this.sessionId,
    this.isSpectator = false,
  });

  @override
  State<SessionControlPanel> createState() => _SessionControlPanelState();
}

class _SessionControlPanelState extends State<SessionControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  Timer? _sessionTimer;
  bool _hasShownCompletedDialog = false;
  bool _isReallySpectator = false;

  Map<String, dynamic>? _sessionData;
  List<dynamic> _liveGames = [];
  List<dynamic> _nextGames = [];
  List<dynamic> _completedGames = [];
  List<dynamic> _players = [];
  Map<String, dynamic>? _primaryActiveGame;
  int? _primaryActiveGameId;
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
    _refreshTimer?.cancel();
    _sessionTimer?.cancel();
    _tabController.dispose();
    super.dispose(); // ← SUPER AL FINAL
  }

  void _startTimers() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
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

  // ✅ NUEVO MÉTODO: Cargar el juego primario activo
  Future<void> _loadPrimaryActiveGame() async {
    try {
      if (_isReallySpectator) return; // No necesario para espectadores

      final response =
          await SessionService.getPrimaryActiveGame(widget.sessionId);

      if (mounted) {
        setState(() {
          _primaryActiveGame = response['primary_active_game'];
          _primaryActiveGameId = _primaryActiveGame?['id'];
        });

        print('🎯 Primary Active Game Loaded:');
        print('   - ID: $_primaryActiveGameId');
        print('   - Game Number: ${_primaryActiveGame?['game_number']}');
        print('   - Court: ${_primaryActiveGame?['court']?['court_name']}');
      }
    } catch (e) {
      print('Error loading primary active game: $e');
      // No es crítico, continuar sin esta información
    }
  }

  Future<void> _loadSessionData({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final sessionResponse = widget.isSpectator
          ? await SessionService.getPublicSession(widget.sessionId)
          : await SessionService.getSession(widget.sessionId);

      if (!mounted) return;

      final session = sessionResponse['session'];

      final currentUserId = await _getCurrentUserId();
      final isReallySpectator =
          widget.isSpectator || (session['user_id'] != currentUserId);

      final liveGames = widget.isSpectator
          ? await SessionService.getPublicGamesByStatus(
              widget.sessionId, 'active')
          : await SessionService.getGamesByStatus(widget.sessionId, 'active');

      if (!mounted) return;

      final nextGames = widget.isSpectator
          ? await SessionService.getPublicGamesByStatus(
              widget.sessionId, 'pending')
          : await SessionService.getGamesByStatus(widget.sessionId, 'pending');

      if (!mounted) return;

      final completedGames = widget.isSpectator
          ? await SessionService.getPublicGamesByStatus(
              widget.sessionId, 'completed')
          : await SessionService.getGamesByStatus(
              widget.sessionId, 'completed');

      if (!mounted) return;

      final players = widget.isSpectator
          ? await SessionService.getPublicPlayerStats(widget.sessionId)
          : await SessionService.getPlayerStats(widget.sessionId);

      if (mounted) {
        setState(() {
          _elapsedSeconds = sessionResponse['elapsed_seconds'] ?? 0;
          _sessionData = session;
          _liveGames = liveGames;
          _nextGames = nextGames;
          _completedGames = completedGames;
          _players = players;
          _isLoading = false;
          _isReallySpectator = isReallySpectator;

          print('\n🔍🔍🔍 DATOS CARGADOS DESDE API 🔍🔍🔍');
          print('Session Type: ${session['session_type']}');
          print('Current Stage: ${session['current_stage']}');
          print('Status: ${session['status']}');
          print('Next Games Count: ${nextGames.length}');
          print('Live Games Count: ${liveGames.length}');
          print('Completed Games Count: ${completedGames.length}');

          if (nextGames.isNotEmpty) {
            print('\n📋 NEXT GAMES:');
            for (var game in nextGames) {
              print(
                  '  Game #${game['game_number']}: stage=${game['stage']}, status=${game['status']}');
            }
          } else {
            print('\n✅ NO HAY NEXT GAMES (debería mostrar botón)');
          }
          print('🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍\n');
        });

        // ✅ CORREGIDO: Cargar Primary Active Game SIEMPRE que no sea espectador
        if (!isReallySpectator) {
          await _loadPrimaryActiveGame();
        }

        if (session['status'] == 'completed') {
          _sessionTimer?.cancel();
          _refreshTimer?.cancel();

          if (!isReallySpectator) {
            _showSessionCompletedDialog();
          }
        }

        if (!isReallySpectator) {
          _checkForStageOrPlayoffCompletion();
        }
      }
    } catch (e) {
      print('[SessionControlPanel] Error loading session data: $e');

      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading session: ${e.toString()}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

// ✅ MÉTODO AUXILIAR PARA OBTENER USER_ID ACTUAL
  Future<int> _getCurrentUserId() async {
    try {
      // Depende de cómo tengas implementada la autenticación
      // Ejemplo 1: Si usas shared_preferences
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getInt('user_id') ?? 0;

      // Ejemplo 2: Si tienes un AuthService
      // return await AuthService.getCurrentUserId();

      // Ejemplo 3: Temporal - mientras implementas la solución real
      return 0; // Cambiar por tu lógica real
    } catch (e) {
      print('Error getting current user ID: $e');
      return 0;
    }
  }

  void _showSessionCompletedDialog() {
    // Solo mostrar una vez
    if (_hasShownCompletedDialog) return;
    _hasShownCompletedDialog = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 24), // Larger dialog
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            actionsPadding: const EdgeInsets.only(bottom: 12, right: 16),

            title: Row(
              children: [
                Icon(Icons.check_circle, color: FrutiaColors.success, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Session Completed',
                  style: GoogleFonts.poppins(
                    color: FrutiaColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            content: Text(
              'All games have been completed! Check the final statistics in the Rankings tab to see the results.',
              style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _tabController.animateTo(3); // Go to Rankings tab
                },
                child: Text(
                  'View Rankings',
                  style: GoogleFonts.lato(
                    color: FrutiaColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  // MEJORAR _checkForStageOrPlayoffCompletion
  void _checkForStageOrPlayoffCompletion() {
    if (!mounted || _sessionData == null) return; // ← AGREGAR mounted

    final sessionType = _sessionData!['session_type'];
    final status = _sessionData!['status'];
    final currentStage = _sessionData!['current_stage'] ?? 1;

    if (status != 'active') return;

    if (sessionType == 'T') {
      final hasPendingGamesInCurrentStage =
          _nextGames.any((game) => game['stage'] == currentStage);
      final hasActiveGamesInCurrentStage =
          _liveGames.any((game) => game['stage'] == currentStage);

      if (!hasActiveGamesInCurrentStage &&
          !hasPendingGamesInCurrentStage &&
          currentStage < 3 &&
          !_hasShownStageDialog) {
        _hasShownStageDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showStageAdvanceDialog('Advance to Stage ${currentStage + 1}');
          }
        });
      }
    }

    if (sessionType == 'P4' || sessionType == 'P8') {
      final hasPlayoffGames =
          _liveGames.any((game) => game['is_playoff_game'] == true) ||
              _nextGames.any((game) => game['is_playoff_game'] == true) ||
              _completedGames.any((game) => game['is_playoff_game'] == true);

      if (!hasPlayoffGames &&
          _liveGames.isEmpty &&
          _nextGames.isEmpty &&
          !_hasShownPlayoffDialog) {
        _hasShownPlayoffDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showStageAdvanceDialog('Advance to Playoffs');
          }
        });
      }
    }
  }

  void _showStageAdvanceDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: FrutiaColors.primary, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: FrutiaColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'All games in this phase are complete! New matches will be created based on current rankings.',
          style:
              GoogleFonts.lato(color: FrutiaColors.secondaryText, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Cerrar diálogo primero
              Navigator.pop(context);

              // Luego ejecutar la operación
              await _executeAdvanceStage();
            },
            child: Text(
              'Continue',
              style: GoogleFonts.lato(
                color: FrutiaColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
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
          title: const Text('Loading...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              Navigator.of(context).pop(true); // ← Envía señal de "recargar"
              // Forzar recarga llamando al método del HomePage
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
          ),
        ),
      );
    }

    final sessionName = _sessionData?['session_name'] ?? 'Session';
    final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
    final numberOfPlayers = _sessionData?['number_of_players'] ?? 0;
    final progressPercentage = _sessionData?['progress_percentage'] ?? 0.0;

    return PopScope(
      canPop: false, // Previene el pop automático
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: FrutiaColors.secondaryBackground,
        appBar: AppBar(
          backgroundColor: FrutiaColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop(true); // ← Envía señal de recarga
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isReallySpectator)
                Text(
                  sessionName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              Text(
                '$numberOfCourts Courts | $numberOfPlayers Players | ${progressPercentage.toInt()}%',
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),

// Y CÁMBIALA POR ESTA VERSIÓN CLICKEABLE:
          actions: [
            GestureDetector(
              onTap: _showSessionInfoDialog,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        // En la parte del build method, reemplaza la sección del TabBar con esto:
        body: Column(
          children: [
            Container(
              height: 4,
              child: LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: FrutiaColors.tertiaryBackground,
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
              ),
            ),
            // TabBar con espacio mejorado
            Container(
              color: FrutiaColors.primaryBackground,
              padding: const EdgeInsets.only(top: 14),
              child: TabBar(
                controller: _tabController,
                labelColor: FrutiaColors.primary,
                unselectedLabelColor: FrutiaColors.disabledText,
                indicatorColor: FrutiaColors.primary,
                indicatorWeight: 3, // ← Grosor de la línea
                labelPadding:
                    const EdgeInsets.only(bottom: 9), // ← TEXTOS MÁS ARRIBA
                tabs: [
                  Tab(
                    icon: const Icon(Icons.play_circle_filled),
                    child: Text(
                      'Live\n(${_liveGames.length})',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.queue),
                    child: Text(
                      'Next\n(${_nextGames.length})',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.check_circle),
                    child: Text(
                      'Completed\n(${_completedGames.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.leaderboard),
                    child: Text(
                      'Rankings\n',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
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
      ),
    );
  }

  Widget _buildLiveGamesTab() {
    final shouldShowFinalResults = _shouldShowFinalResults();

    return Column(
      children: [
        // ✅ RESULTADOS FINALES ARRIBA
        if (shouldShowFinalResults) _buildFinalResultsCard(),

        // ✅ CONTENIDO NORMAL DEL LIVE TAB
        if (_liveGames.isEmpty && !shouldShowFinalResults)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.grey.shade400,
                        BlendMode.modulate,
                      ),
                      child: Image(
                        image: AssetImage('assets/icons/raaqueta.png'),
                        width: 120,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No active games',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_liveGames.isNotEmpty)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadSessionData(),
              color: FrutiaColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _liveGames.length,
                itemBuilder: (context, index) {
                  return _buildGameCard(_liveGames[index], isLive: true);
                },
              ),
            ),
          ),
      ],
    );
  }

Widget _buildNextGamesTab() {
  final shouldShowFinalsButton = _shouldShowStartFinalsButton();
  final shouldShowFinalizeButton = _shouldShowFinalizeButton();
  final shouldShowFinalResults = _shouldShowFinalResults();
// ✅ AGREGAR esta validación
  final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
  final liveGamesCount = _liveGames.length;
  final availableStartSlots = max<int>(0, numberOfCourts - liveGamesCount);

  if (_nextGames.isEmpty) {
    return Column(
      children: [
        if (shouldShowFinalResults) _buildFinalResultsCard(),
        if (!shouldShowFinalResults)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ PRIORIDAD 1: Botón de finalizar
                  if (shouldShowFinalizeButton) _buildFinalizeButton(),
                  
                  // ✅ PRIORIDAD 2: Botón de finals (P8)
                  if (!shouldShowFinalizeButton && shouldShowFinalsButton)
                    _buildStartFinalsButton(),
                  
                  // ✅ PRIORIDAD 3: Mensaje vacío
                  if (!shouldShowFinalizeButton && !shouldShowFinalsButton) ...[
                    Icon(Icons.queue, size: 64, color: FrutiaColors.disabledText),
                    const SizedBox(height: 16),
                    Text(
                      'No games in queue',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: FrutiaColors.secondaryText,
                      ),
                    ),
                  ],
                  
                  // ✅ PRIORIDAD 4: Botón de avanzar stage (SOLO si no hay nada más que hacer)
                  if (_sessionData != null &&
                      (_sessionData!['session_type'] == 'P4' ||
                          _sessionData!['session_type'] == 'P8' ||
                          _sessionData!['session_type'] == 'T') &&
                      _liveGames.isEmpty &&
                      !shouldShowFinalsButton &&
                      !shouldShowFinalizeButton &&
                      !shouldShowFinalResults)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildAdvanceStageButton(),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

    // ✅ SI HAY NEXT GAMES
    return Column(
      children: [
        if (shouldShowFinalResults) _buildFinalResultsCard(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadSessionData(),
            color: FrutiaColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _nextGames.length +
                  (shouldShowFinalizeButton ? 1 : 0) +
                  (shouldShowFinalsButton ? 1 : 0) +
                  1,
              itemBuilder: (context, index) {
                if (shouldShowFinalizeButton && index == 0) {
                  return _buildFinalizeButton();
                }

                final finalizeOffset = shouldShowFinalizeButton ? 1 : 0;

                if (shouldShowFinalsButton &&
                    index == _nextGames.length + finalizeOffset) {
                  return _buildStartFinalsButton();
                }

                if (index ==
                    _nextGames.length +
                        finalizeOffset +
                        (shouldShowFinalsButton ? 1 : 0)) {
                  return _buildAdvanceStageButton();
                }

                final gameIndex = index - finalizeOffset;
                final game = _nextGames[gameIndex];

                // ✅ NUEVA LÓGICA: Determinar si mostrar "Start Game"
                final shouldShowStartGame = gameIndex < availableStartSlots;

                print(
                    '🎯 Game #${game['game_number']} - Show Start: $shouldShowStartGame (Position: ${gameIndex + 1}, Slot: ${gameIndex < availableStartSlots})');

                return _buildGameCard(
                  game,
                  queuePosition: gameIndex + 1,
                  shouldShowStartGame: shouldShowStartGame, // ← NUEVO PARÁMETRO
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalResultsCard() {
    final sessionName = _sessionData?['session_name'] ?? 'Session';
    final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
    final numberOfPlayers = _sessionData?['number_of_players'] ?? 0;
    final duration = _formatTimer(_elapsedSeconds);

    // ✅ CORREGIDO: Tomar los 3 primeros del ranking actual
    final topPlayers = _players.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FrutiaColors.success.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FrutiaColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: FrutiaColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Complete! 🎉',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check out the final results for session "$sessionName" below:',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Session Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FrutiaColors.secondaryBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('$numberOfPlayers', 'Players'),
                _buildSummaryItem('$numberOfCourts', 'Courts'),
                _buildSummaryItem(duration, 'Duration'),
                _buildSummaryItem('${_completedGames.length}', 'Games'),
              ],
            ),
          ),

          // ✅ CORREGIDO: Mostrar TOP 3 del ranking aquí
          if (topPlayers.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTop3Section(topPlayers),
          ],

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _tabController.animateTo(3); // Go to Rankings
              },
              icon: Icon(Icons.leaderboard,
                  size: 18, color: FrutiaColors.primary),
              label: Text(
                'View Rankings',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: FrutiaColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ CORREGIDO: Sección del Top 3 - MÁS SIMPLE
  Widget _buildTop3Section(List<dynamic> topPlayers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 3 Players',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        // 🥇 1st Place
        _buildTop3PlayerLine('🥇', '1st Place', topPlayers[0]),

        // 🥈 2nd Place
        if (topPlayers.length > 1) ...[
          const SizedBox(height: 8),
          _buildTop3PlayerLine('🥈', '2nd Place', topPlayers[1]),
        ],

        // 🥉 3rd Place
        if (topPlayers.length > 2) ...[
          const SizedBox(height: 8),
          _buildTop3PlayerLine('🥉', '3rd Place', topPlayers[2]),
        ],
      ],
    );
  }

// ✅ CORREGIDO: Línea individual - SOLO NOMBRE
  Widget _buildTop3PlayerLine(String emoji, String position, dynamic player) {
    // ✅ CORREGIDO: Obtener nombre correctamente
    String playerName = 'Unknown Player';

    // Intentar diferentes formas de obtener el nombre
    if (player['display_name'] != null) {
      playerName = player['display_name'].toString();
    } else if (player['first_name'] != null && player['last_initial'] != null) {
      playerName = '${player['first_name']} ${player['last_initial']}.';
    } else if (player['first_name'] != null) {
      playerName = player['first_name'].toString();
    }

    // ✅ DEBUG: Ver qué datos tenemos
    print('🎯 Player data for $position:');
    print('   - display_name: ${player['display_name']}');
    print('   - first_name: ${player['first_name']}');
    print('   - last_initial: ${player['last_initial']}');
    print('   - Final name: $playerName');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FrutiaColors.secondaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$position - $playerName', // ← SOLO NOMBRE Y POSICIÓN
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ NUEVO MÉTODO: Sección de ganadores
  Widget _buildWinnersSection(List champions, List runnersUp, List thirdPlace) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Winners',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        // 🥇 Champions
        if (champions.isNotEmpty) _buildWinnerLine('🥇', 'Winners', champions),

        // 🥈 Runners-up
        if (runnersUp.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildWinnerLine('🥈', 'Runners Up', runnersUp),
        ],

        // 🥉 Third Place
        if (thirdPlace.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildWinnerLine('🥉', 'Third Place', thirdPlace),
        ],
      ],
    );
  }

// ✅ NUEVO MÉTODO: Línea individual de ganador
  Widget _buildWinnerLine(String emoji, String title, List players) {
    // Formatear nombres: primeras 3-4 letras + inicial apellido
    final formattedNames = players.map((player) {
      final fullName = player['display_name']?.toString() ?? 'Unknown';
      final parts = fullName.split(' ');
      if (parts.length >= 2) {
        final firstName = parts[0];
        final lastNameInitial = parts[1].substring(0, 1);
        // Tomar máximo 4 letras del primer nombre
        final shortFirstName =
            firstName.length > 4 ? firstName.substring(0, 4) : firstName;
        return '$shortFirstName $lastNameInitial.';
      } else {
        // Si solo hay un nombre, tomar máximo 5 letras
        return fullName.length > 5 ? fullName.substring(0, 5) : fullName;
      }
    }).join(' & ');

    return Row(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$title - $formattedNames',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: FrutiaColors.primaryText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

// Método auxiliar existente (sin cambios)
  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: FrutiaColors.primaryText,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 10,
            color: FrutiaColors.secondaryText,
          ),
        ),
      ],
    );
  }

  bool _shouldShowStartFinalsButton() {
    if (_sessionData == null) return false;
    if (_sessionData!['session_type'] != 'P8') return false;

    // ✅ CORREGIDO: Comparar con 1 en lugar de true
    final completedSemifinals = _completedGames.where((g) {
      final isPlayoff =
          g['is_playoff_game'] == 1 || g['is_playoff_game'] == true;
      final round = g['playoff_round']?.toString().toLowerCase();
      return isPlayoff && round == 'semifinal';
    }).toList();

    // Verificar que NO haya finals ya generadas
    final hasFinals = _nextGames.any((g) =>
            (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
            (g['playoff_round'] == 'gold' || g['playoff_round'] == 'bronze')) ||
        _completedGames.any((g) =>
            (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
            (g['playoff_round'] == 'gold' || g['playoff_round'] == 'bronze'));

    return completedSemifinals.length == 2 && !hasFinals;
  }

// ✅ AGREGAR MÉTODO AUXILIAR
  bool _isPlayoffGame(Map<String, dynamic> game) {
    final value = game['is_playoff_game'];
    if (value == null) return false;

    // Manejar todos los posibles formatos
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';

    return false;
  }

  Widget _buildStartFinalsButton() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FrutiaColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FrutiaColors.accent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ AGREGADO
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: FrutiaColors.accent, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for the Finals?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Both semifinals are complete! Generate the Final and Bronze Match.',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          // ✅ BOTÓN SIN SizedBox wrapper
          ElevatedButton.icon(
            onPressed: () => _showStartFinalsConfirmation(),
            icon: Icon(Icons.emoji_events, color: Colors.white, size: 20),
            label: Text(
              'Start Finals',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.accent2,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStartFinalsConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FrutiaColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: FrutiaColors.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ready for the Finals?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will generate the Final (winners) and Bronze Match (losers) based on the semifinal results.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: FrutiaColors.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: FrutiaColors.primaryText.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: FrutiaColors.accent.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Start Finals!',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

    if (confirm == true) {
      await _executeStartFinals();
    }
  }

  Future<void> _executeStartFinals() async {
    try {
      // ✅ Llamar al endpoint para generar finals
      await SessionService.generateP8Finals(widget.sessionId);

      await Future.delayed(const Duration(milliseconds: 500));
      await _loadSessionData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Finals generated successfully!',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('[SessionControlPanel] Error generating finals: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAdvanceStageButton() {
    final sessionType = _sessionData?['session_type'];
    final currentStage = _sessionData?['current_stage'] ?? 1;
    final status = _sessionData?['status'];

    // ✅ AGREGAR DEBUGGING
    print('========== DEBUG ADVANCE BUTTON ==========');
    print('[DEBUG] Session Type: $sessionType');
    print('[DEBUG] Current Stage: $currentStage');
    print('[DEBUG] Status: $status');
    print('[DEBUG] Live games: ${_liveGames.length}');
    print('[DEBUG] Next games: ${_nextGames.length}');

    if (sessionType == 'T') {
      final hasPendingGamesInCurrentStage =
          _nextGames.any((game) => game['stage'] == currentStage);
      print(
          '[DEBUG] Has pending games in stage $currentStage: $hasPendingGamesInCurrentStage');

      if (hasPendingGamesInCurrentStage) {
        print('[DEBUG] Showing next games stages:');
        for (var game in _nextGames) {
          print('  - Game #${game['game_number']}: stage=${game['stage']}');
        }
      }
    }
    print('==========================================');

    // ✅ AGREGAR: No mostrar si ya hay que generar las finals de P8
    if (sessionType == 'P8' && _shouldShowStartFinalsButton()) {
      print(
          '[DEBUG] ❌ Not showing Advance button: Finals button takes priority');
      return const SizedBox.shrink();
    }

    // ✅ No mostrar si hay juegos activos
    if (_liveGames.isNotEmpty) {
      print('[DEBUG] ❌ Not showing: Has live games');
      return const SizedBox.shrink();
    }

    // ✅ No mostrar si la sesión está completada
    if (status == 'completed') {
      print('[DEBUG] ❌ Not showing: Session completed');
      return const SizedBox.shrink();
    }

    // ✅ PARA TORNEOS
    if (sessionType == 'T') {
      if (currentStage >= 3) {
        print('[DEBUG] ❌ Not showing: Already in stage 3');
        return const SizedBox.shrink();
      }

      final hasPendingGamesInCurrentStage =
          _nextGames.any((game) => game['stage'] == currentStage);

      if (hasPendingGamesInCurrentStage) {
        print('[DEBUG] ❌ Not showing: Has pending games in current stage');
        return const SizedBox.shrink();
      }

      print('[DEBUG] ✅ SHOWING BUTTON: Advance to Stage ${currentStage + 1}');

      // ... resto del código que ya tienes
      // ✅ Si llegamos aquí, mostrar botón de avance
      String buttonText = 'Advance to Stage ${currentStage + 1}';
      String description =
          'Generate Stage ${currentStage + 1} matches based on Stage $currentStage results';

      return Container(
        margin: const EdgeInsets.only(
            top: 24,
            bottom: 100,
            left: 16,
            right: 16), // ← CAMBIAR bottom de 16 a 80

        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FrutiaColors.nutrition.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FrutiaColors.nutrition,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: FrutiaColors.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for the Next Stage?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAdvanceStageConfirmation(),
              icon: Icon(Icons.flag, color: Colors.white, size: 20),
              label: Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FrutiaColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ PARA PLAYOFFS: Lógica existente
    final hasActivePlayoffGames = _liveGames.any((game) =>
            (game['is_playoff_game'] == 1 ||
                game['is_playoff_game'] == true)) ||
        _nextGames.any((game) =>
            (game['is_playoff_game'] == 1 || game['is_playoff_game'] == true));

    if ((sessionType == 'P4' || sessionType == 'P8') && hasActivePlayoffGames) {
      return const SizedBox.shrink();
    }

    String buttonText = '';
    String description = '';
    IconData buttonIcon = Icons.arrow_forward;

    if (sessionType == 'P4' || sessionType == 'P8') {
      buttonText = 'Advance to Playoffs';
      description = 'Generate playoff bracket based on current rankings';
      buttonIcon = Icons.emoji_events;

      if (_nextGames.isNotEmpty) {
        description =
            'This will clear all pending games (${_nextGames.length}) and generate the Playoffs bracket';
      }
    }

    if (buttonText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 70, left: 16, right: 16),
      padding: const EdgeInsets.only(right: 20, left: 20, bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: FrutiaColors.nutrition.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FrutiaColors.nutrition,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: FrutiaColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for the Next Phase?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAdvanceStageConfirmation(),
            icon: Icon(buttonIcon, color: Colors.white, size: 20),
            label: Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  } // Reemplaza SOLO el método _showAdvanceStageConfirmation en SessionControlPanel.dart
// Busca el método existente (aproximadamente línea 300-350) y reemplázalo con este:

// AGREGAR estos 3 métodos AL FINAL del archivo

  Color _getPlayoffColor(String? playoffRound) {
    switch (playoffRound) {
      case 'semifinal':
        return const Color(0xFFFF6B35); // ← CAMBIAR de gris a naranja
      case 'gold':
        return const Color(0xFFFFD700);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return FrutiaColors.accent;
    }
  }

  List<Color> _getPlayoffGradient(String? playoffRound) {
    switch (playoffRound) {
      case 'semifinal':
        return [
          const Color(0xFFFF6B35), // ← CAMBIAR
          const Color(0xFFFF8C42), // ← CAMBIAR
        ];
      case 'gold':
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFC107),
        ];
      case 'bronze':
        return [
          const Color(0xFFCD7F32),
          const Color(0xFFD4A574),
        ];
      default:
        return [FrutiaColors.accent, FrutiaColors.accent.withOpacity(0.8)];
    }
  }

  IconData _getPlayoffIcon(String? playoffRound) {
    switch (playoffRound) {
      case 'semifinal':
        return Icons.stars;
      case 'gold':
        return Icons.emoji_events;
      case 'bronze':
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events;
    }
  }

  Future<void> _showAdvanceStageConfirmation() async {
    final sessionType = _sessionData?['session_type'];
    final currentStage = _sessionData?['current_stage'] ?? 1;

    String title = '';
    String message = '';
    String confirmText = '';
    IconData titleIcon = Icons.emoji_events;

    if (sessionType == 'P4' || sessionType == 'P8') {
      title = 'Ready to start the Playoffs?';
      message =
          'Ready for the finale? This action uses the current ranking to create the playoffs bracket. It cannot be undone.';
      confirmText = 'Start Playoffs!';
      titleIcon = Icons.emoji_events;
    } else if (sessionType == 'T') {
      title = 'Ready to start the Next Phase?';
      if (currentStage == 1) {
        message =
            'Ready for Stage 2? This action uses the current ranking to create new matches. It cannot be undone.';
        confirmText = 'Start Stage 2!';
      } else if (currentStage == 2) {
        message =
            'Ready for Stage 3? This action uses the current ranking to create new matches. It cannot be undone.';
        confirmText = 'Start Stage 3!';
      }
      titleIcon = Icons.flag;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FrutiaColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                titleIcon,
                color: FrutiaColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: FrutiaColors.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                // Cancel button (Ghost style)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: FrutiaColors.primaryText.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm button (Green with shadow)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: FrutiaColors.success.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

    if (confirm == true) {
      await _executeAdvanceStage();
    }
  }

  String? _getPlayoffLabel(Map<String, dynamic> game) {
    // ✅ CORREGIDO: Verificar con 1 o true
    if (game['is_playoff_game'] != 1 && game['is_playoff_game'] != true) {
      return null;
    }

    final playoffRound = game['playoff_round'];

    if (playoffRound == 'semifinal') {
      final gameNumber = game['game_number'];

      // Buscar en TODOS los juegos (next + completed)
      final allSemifinals = [..._nextGames, ..._completedGames]
          .where((g) =>
              (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
              g['playoff_round'] == 'semifinal')
          .toList();

      if (allSemifinals.isNotEmpty) {
        allSemifinals.sort(
            (a, b) => (a['game_number'] ?? 0).compareTo(b['game_number'] ?? 0));

        final index =
            allSemifinals.indexWhere((g) => g['game_number'] == gameNumber);
        if (index >= 0) {
          return 'Semifinal ${index + 1}';
        }
      }
      return 'Semifinal';
    }

    if (playoffRound == 'gold') return 'Final';
    if (playoffRound == 'bronze') return 'Bronze Match';

    return playoffRound?.toUpperCase();
  }

// AGREGAR ESTOS MÉTODOS NUEVOS a la clase _SessionControlPanelState

// Método para mostrar el diálogo de información de sesión con opción de finalizar
  void _showSessionInfoDialog() {
    final sessionName = _sessionData?['session_name'] ?? 'Session';
    final sessionType = _sessionData?['session_type'] ?? 'Unknown';
    final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
    final numberOfPlayers = _sessionData?['number_of_players'] ?? 0;
    final progressPercentage = _sessionData?['progress_percentage'] ?? 0.0;
    final status = _sessionData?['status'] ?? 'unknown';
    final currentStage = _sessionData?['current_stage'] ?? 1;

    // Mapear tipos de sesión a nombres legibles
    String getSessionTypeName(String type) {
      switch (type) {
        case 'O':
          return 'Optimized';
        case 'T':
          return 'Tournament';
        case 'P4':
          return 'Playoff (4)';
        case 'P8':
          return 'Playoff (8)';
        default:
          return type;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info, color: FrutiaColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Session Info',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Name
            _buildInfoRow('Session Name', sessionName),
            const SizedBox(height: 12),

            // Session Type
            _buildInfoRow('Type', getSessionTypeName(sessionType)),
            const SizedBox(height: 12),

            // Status
            _buildInfoRow('Status', status.toUpperCase(),
                valueColor: status == 'completed'
                    ? FrutiaColors.success
                    : FrutiaColors.primary),
            const SizedBox(height: 12),

            // Current Stage (solo para torneos)
            if (sessionType == 'T') ...[
              _buildInfoRow('Current Stage', 'Stage $currentStage'),
              const SizedBox(height: 12),
            ],

            // Courts & Players
            _buildInfoRow('Courts', numberOfCourts.toString()),

            _buildInfoRow('Players', numberOfPlayers.toString()),

            const SizedBox(height: 12),

            // Progress
            _buildInfoRow('Progress', '${progressPercentage.toInt()}%'),
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: progressPercentage / 100,
              backgroundColor: FrutiaColors.tertiaryBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                  progressPercentage >= 100
                      ? FrutiaColors.success
                      : FrutiaColors.primary),
            ),
            const SizedBox(height: 8),

            // Duration
            _buildInfoRow('Duration', _formatTimer(_elapsedSeconds)),

            // Solo mostrar botón de finalizar si la sesión no está completada
            if (status != 'completed') ...[
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),

              // Finalize Session Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar este diálogo primero
                    _showFinalizeConfirmation(); // Mostrar confirmación
                  },
                  icon: Icon(Icons.flag, size: 20, color: Colors.red),
                  label: Text(
                    'Finalize Session',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: FrutiaColors.error,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget auxiliar para mostrar filas de información
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: FrutiaColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? FrutiaColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

// Método para mostrar confirmación de finalización (ya existe, pero lo mejoramos)
  Future<void> _showFinalizeConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: FrutiaColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'Finalize Session?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: FrutiaColors.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will:',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            _buildWarningItem('Cancel all current matches'),
            _buildWarningItem('Finalize the rankings'),
            _buildWarningItem('Mark session as completed'),
            const SizedBox(height: 12),
            Text(
              'You will NOT be able to resume play or edit scores. This cannot be undone!',
              style: GoogleFonts.lato(
                color: FrutiaColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Go Back',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: FrutiaColors.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FrutiaColors.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Finalize Session',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _executeFinalizeSession();
    }
  }

// Widget auxiliar para items de advertencia
  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.close, size: 16, color: FrutiaColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: FrutiaColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAdvanceStage() async {
    try {
      final sessionType = _sessionData?['session_type'];

      // ✅ CAMBIO: Todos usan el mismo endpoint
      if (sessionType == 'P4' || sessionType == 'P8') {
        await SessionService.advanceToNextStage(
            widget.sessionId); // ← CAMBIAR AQUÍ
      } else if (sessionType == 'T') {
        await SessionService.advanceToNextStage(widget.sessionId);
      }

      // Reset flags
      _hasShownPlayoffDialog = false;
      _hasShownStageDialog = false;

      await Future.delayed(const Duration(milliseconds: 500));
      await _loadSessionData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sessionType == 'T'
                  ? '✅ Advanced to next stage successfully!'
                  : '✅ Playoff bracket generated successfully!',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('[SessionControlPanel] Error al avanzar stage: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _hasShownPlayoffDialog = false;
      _hasShownStageDialog = false;
    }
  }

  Widget _buildCompletedGamesTab() {
    if (_completedGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle,
                size: 64, color: FrutiaColors.disabledText),
            const SizedBox(height: 16),
            Text(
              'No completed games',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: FrutiaColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ ORDENAR juegos por jerarquía de playoff
    final sortedGames = List<dynamic>.from(_completedGames);

    sortedGames.sort((a, b) {
      final aIsPlayoff =
          a['is_playoff_game'] == 1 || a['is_playoff_game'] == true;
      final bIsPlayoff =
          b['is_playoff_game'] == 1 || b['is_playoff_game'] == true;

      // Si ambos son playoff, ordenar por jerarquía
      if (aIsPlayoff && bIsPlayoff) {
        final aRound = a['playoff_round']?.toString().toLowerCase() ?? '';
        final bRound = b['playoff_round']?.toString().toLowerCase() ?? '';

        // Mapa de prioridad (menor número = más arriba)
        final priority = {
          'gold': 1, // Final - Primero
          'bronze': 2, // Bronze - Segundo
          'semifinal': 3, // Semifinals - Tercero
          'quarterfinal': 4,
        };

        final aPriority = priority[aRound] ?? 999;
        final bPriority = priority[bRound] ?? 999;

        // Si tienen diferente prioridad, ordenar por prioridad
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        // Si son el mismo round (ej: 2 semifinals), ordenar por game_number descendente
        return (b['game_number'] ?? 0).compareTo(a['game_number'] ?? 0);
      }

      // Si uno es playoff y otro no, playoff primero
      if (aIsPlayoff && !bIsPlayoff) return -1;
      if (!aIsPlayoff && bIsPlayoff) return 1;

      // Si ninguno es playoff, ordenar por game_number descendente (más reciente primero)
      return (b['game_number'] ?? 0).compareTo(a['game_number'] ?? 0);
    });

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            16, 16, 16, 80), // ← CAMBIAR: agregar 80 al bottom
        itemCount: sortedGames.length,
        itemBuilder: (context, index) {
          return _buildGameCard(sortedGames[index], isCompleted: true);
        },
      ),
    );
  }

  Widget _buildPlayerStatsTab() {
    if (_players.isEmpty) {
      return Center(
        child: Text(
          'No players',
          style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
        ),
      );
    }

    // ✅ AGREGAR: Determinar cuántos clasifican según session_type
    final sessionType = _sessionData?['session_type'];
    final playoffCutoff =
        sessionType == 'P8' ? 8 : (sessionType == 'P4' ? 4 : 0);

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          final rank = player['current_rank'] ?? (index + 1);

          // 🎖 Podium colors for top 3
          Color? podiumColor;
          Color? borderColor;
          if (rank == 1) {
            podiumColor = const Color(0xFFFFD700).withOpacity(0.15); // Gold
            borderColor = const Color(0xFFFFD700).withOpacity(0.3);
          } else if (rank == 2) {
            podiumColor = const Color(0xFFC0C0C0).withOpacity(0.15); // Silver
            borderColor = const Color(0xFFC0C0C0).withOpacity(0.3);
          } else if (rank == 3) {
            podiumColor = const Color(0xFFCD7F32).withOpacity(0.15); // Bronze
            borderColor = const Color(0xFFCD7F32).withOpacity(0.3);
          }
          // ✅ AGREGAR: Color para clasificados a playoffs (4-8 o 4)
          else if (playoffCutoff > 0 && rank <= playoffCutoff) {
            podiumColor =
                FrutiaColors.success.withOpacity(0.08); // Verde muy claro
            borderColor = FrutiaColors.success.withOpacity(0.25);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: podiumColor ?? FrutiaColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor ?? FrutiaColors.tertiaryBackground,
                width:
                    (rank <= 3 || (playoffCutoff > 0 && rank <= playoffCutoff))
                        ? 2
                        : 1, // ✅ Border más grueso
              ),
              boxShadow: (rank <= 3 ||
                      (playoffCutoff > 0 &&
                          rank <= playoffCutoff)) // ✅ Sombra para clasificados
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🏅 Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? (rank == 1
                              ? const Color(0xFFFFD700)
                              : rank == 2
                                  ? const Color(0xFFC0C0C0)
                                  : const Color(0xFFCD7F32))
                          : (playoffCutoff > 0 &&
                                  rank <=
                                      playoffCutoff) // ✅ Verde para clasificados
                              ? FrutiaColors.success.withOpacity(0.2)
                              : FrutiaColors.secondaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3
                              ? Colors.white
                              : (playoffCutoff > 0 &&
                                      rank <=
                                          playoffCutoff) // ✅ Verde oscuro para número
                                  ? FrutiaColors.success
                                  : FrutiaColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ... resto del código sin cambios

                  // 👤 Player name - CON ANCHO FIJO Y TRUNCAMIENTO
                  Container(
                    width: 100, // ← ANCHO FIJO para nombres
                    child: Text(
                      _truncateName(
                          '${player['first_name']} ${player['last_initial']}.'),
                      style: GoogleFonts.poppins(
                        fontSize: 13, // ← Fuente ligeramente más pequeña
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // 📊 Stats section - CON ANCHOS FIJOS Y MEJOR DISTRIBUCIÓN
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceEvenly, // ← Distribución uniforme
                      children: [
                        _buildStatColumn(
                          '${player['games_played'] ?? 0}',
                          'Games',
                          width: 40, // ← ANCHO FIJO
                        ),

                        _buildStatColumn(
                          '${player['win_percentage']?.toInt() ?? 0}%',
                          'Win',
                          width: 40, // ← ANCHO FIJO
                        ),

                        _buildStatColumn(
                          '${player['points_won_percentage']?.toInt() ?? 0}%',
                          'Pts',
                          width: 40, // ← ANCHO FIJO
                        ),

                        // ⭐ Rating con ancho fijo
                        Container(
                          width: 45, // ← ANCHO FIJO ligeramente reducido
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4), // ← Padding reducido
                          decoration: BoxDecoration(
                            color: FrutiaColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            player['current_rating']?.toInt().toString() ?? '0',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12, // ← Fuente ligeramente más pequeña
                              fontWeight: FontWeight.bold,
                              color: FrutiaColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Método auxiliar para truncar nombres
  String _truncateName(String fullName) {
    const maxLength = 12; // ← MÁXIMO 12 CARACTERES
    if (fullName.length <= maxLength) {
      return fullName;
    }
    return '${fullName.substring(0, maxLength - 1)}…';
  }

// Widget _buildStatColumn actualizado para aceptar ancho fijo
  Widget _buildStatColumn(String value, String label, {double width = 40}) {
    return Container(
      width: width, // ← ANCHO FIJO
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 12, // ← Fuente ligeramente más pequeña
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 9,
              color: FrutiaColors.secondaryText,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FrutiaColors.success,
            FrutiaColors.success.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FrutiaColors.success.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Complete!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to see the final results?',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _executeFinalizeSession(),
            icon:
                Icon(Icons.check_circle, color: FrutiaColors.success, size: 22),
            label: Text(
              'Finalize Session & See Results',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FrutiaColors.success,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: FrutiaColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeFinalizeSession() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(FrutiaColors.success),
                ),
                const SizedBox(height: 16),
                Text(
                  'Finalizing session...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Llamar al endpoint
      final result = await SessionService.finalizeSession(widget.sessionId);

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      // ✅ CORREGIDO: Actualizar sessionData con los datos del podio
      if (mounted) {
        setState(() {
          _sessionData = {
            ..._sessionData!, // Mantener datos existentes
            'status': 'completed',
            'podium_data': result['podium'], // ← AGREGAR datos del podio
          };
        });
      }

      // Mostrar podio
      if (mounted) {
        await _showPodiumDialog(result['podium']);
      }

      // Recargar datos completos
      await _loadSessionData();
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.pop(context);

      print('[SessionControlPanel] Error finalizing session: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showPodiumDialog(Map<String, dynamic> podiumData) async {
    print('🎯 SHOWING PODIUM DIALOG WITH RANKING DATA:');
    print('   - Players count: ${_players.length}');

    final topPlayers = _players.take(3).toList();

    print('   - Top 3 players from ranking:');
    for (var i = 0; i < topPlayers.length; i++) {
      print(
          '     ${i + 1}. ${topPlayers[i]['first_name']} ${topPlayers[i]['last_initial']} - ${topPlayers[i]['current_rating']}');
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxWidth: 360, // ✅ Reducido de 380 a 360
              maxHeight: 500),
          padding: const EdgeInsets.all(16), // ✅ Reducido de 20 a 16
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), // ✅ Reducido de 12 a 10
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FrutiaColors.accent,
                          FrutiaColors.accent.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 28, // ✅ Reducido de 32 a 28
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // ✅ AGREGADO Expanded
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 15, // ✅ Reducido de 16 a 15
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Congratulations to the winning teams!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: FrutiaColors.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // ✅ Reducido de 20 a 16

              // ✅ Top 3 del ranking
              _buildTopPlayersFromRanking(topPlayers),

              const SizedBox(height: 16), // ✅ Reducido de 20 a 16

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _tabController.animateTo(3);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10), // ✅ Reducido
                        side: BorderSide(
                          color: FrutiaColors.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Rankings',
                        style: GoogleFonts.poppins(
                          fontSize: 13, // ✅ Reducido
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: FrutiaColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrutiaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10), // ✅ Reducido
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 13, // ✅ Reducido
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

// ✅ NUEVO MÉTODO: Mostrar top 3 del ranking
  Widget _buildTopPlayersFromRanking(List<dynamic> topPlayers) {
    if (topPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FrutiaColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Check Rankings for detailed results!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...topPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;

          final medals = ['🥇', '🥈', '🥉'];
          final colors = [
            const Color(0xFFFFD700), // Gold
            const Color(0xFFC0C0C0), // Silver
            const Color(0xFFCD7F32) // Bronze
          ];

          // ✅ CONSTRUIR EL NOMBRE desde first_name y last_initial
          String playerName = 'Unknown Player';
          if (player['first_name'] != null && player['last_initial'] != null) {
            playerName = '${player['first_name']} ${player['last_initial']}.';
          } else if (player['first_name'] != null) {
            playerName = player['first_name'].toString();
          }

          return Container(
            margin: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors[index].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  medals[index],
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Rating: ${player['current_rating']?.round().toString() ?? '0'}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

// Versión compacta para playoffs
  Widget _buildCompactPlayoffPodium(
      Map<String, dynamic> podiumData, String sessionType) {
    final champions = (podiumData['champions']?['players'] as List?) ?? [];
    final secondPlace = (podiumData['second_place']?['players'] as List?) ?? [];
    final thirdPlace = sessionType == 'P8'
        ? (podiumData['third_place']?['players'] as List?) ?? []
        : null;

    return Column(
      children: [
        if (champions.isNotEmpty)
          _buildCompactPodiumCard(
            position: 1,
            title: 'Champions',
            color: const Color(0xFFFFD700),
            players: champions,
          ),
        if (secondPlace.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildCompactPodiumCard(
            position: 2,
            title: 'Runners-up',
            color: const Color(0xFFC0C0C0),
            players: secondPlace,
          ),
        ],
        if (thirdPlace != null && thirdPlace.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildCompactPodiumCard(
            position: 3,
            title: 'Third Place',
            color: const Color(0xFFCD7F32),
            players: thirdPlace,
          ),
        ],
      ],
    );
  }

// Versión compacta para optimized
  Widget _buildCompactOptimizedResults(Map<String, dynamic> podiumData) {
    final topPlayers = podiumData['top_players'] as List? ?? [];

    if (topPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FrutiaColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Check Rankings for detailed results!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...topPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          if (player == null) return const SizedBox.shrink();

          final medals = ['🥇', '🥈', '🥉'];
          final colors = [
            const Color(0xFFFFD700),
            const Color(0xFFC0C0C0),
            const Color(0xFFCD7F32)
          ];

          return Container(
            margin: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors[index].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  index < medals.length ? medals[index] : '🏅',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['display_name']?.toString() ?? 'Unknown Player',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.primaryText,
                        ),
                      ),
                      Text(
                        'Rating: ${player['rating']?.toString() ?? '0'}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

// Tarjeta compacta para podio
  Widget _buildCompactPodiumCard({
    required int position,
    required String title,
    required Color color,
    required List players,
  }) {
    final validPlayers = players.where((player) => player != null).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...validPlayers
              .map((player) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            player['display_name']?.toString() ??
                                'Unknown Player',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: FrutiaColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPlayoffPodium(
      Map<String, dynamic> podiumData, String sessionType) {
    // ✅ MANEJAR CASOS NULL DE FORMA SEGURA
    final champions = (podiumData['champions']?['players'] as List?) ?? [];
    final secondPlace = (podiumData['second_place']?['players'] as List?) ?? [];
    final thirdPlace = sessionType == 'P8'
        ? (podiumData['third_place']?['players'] as List?) ?? []
        : null;

    return Column(
      children: [
        // 🥇 Champions - ✅ SOLO MOSTRAR SI HAY DATOS
        if (champions.isNotEmpty) ...[
          _buildPodiumCard(
            position: 1,
            title: 'Champions',
            color: const Color(0xFFFFD700),
            icon: Icons.emoji_events,
            players: champions,
          ),
          const SizedBox(height: 16),
        ],

        // 🥈 Second Place - ✅ SOLO MOSTRAR SI HAY DATOS
        if (secondPlace.isNotEmpty) ...[
          _buildPodiumCard(
            position: 2,
            title: 'Runners-up',
            color: const Color(0xFFC0C0C0),
            icon: Icons.workspace_premium,
            players: secondPlace,
          ),
        ],

        // 🥉 Third Place (solo P8) - ✅ SOLO MOSTRAR SI HAY DATOS
        if (thirdPlace != null && thirdPlace.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPodiumCard(
            position: 3,
            title: 'Third Place',
            color: const Color(0xFFCD7F32),
            icon: Icons.military_tech,
            players: thirdPlace,
          ),
        ],

        // ✅ MENSAJE SI NO HAY DATOS DE PODIO
        if (champions.isEmpty &&
            secondPlace.isEmpty &&
            (thirdPlace?.isEmpty ?? true)) ...[
          const SizedBox(height: 20),
          Text(
            'No podium data available',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: FrutiaColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPodiumCard({
    required int position,
    required String title,
    required Color color,
    required IconData icon,
    required List players,
  }) {
    // ✅ FILTRAR JUGADORES NULOS
    final validPlayers = players.where((player) => player != null).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),

          // ✅ MOSTRAR JUGADORES VÁLIDOS O MENSAJE
          if (validPlayers.isNotEmpty) ...[
            ...validPlayers
                .map((player) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              player['display_name']?.toString() ??
                                  'Unknown Player',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: FrutiaColors.primaryText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: FrutiaColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${player['rating']?.toString() ?? '0'}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: FrutiaColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ] else ...[
            Text(
              'No players data',
              style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimizedResults(Map<String, dynamic> podiumData) {
    // ✅ MANEJAR CASO NULL de forma segura
    final topPlayers = podiumData['top_players'] as List? ?? [];

    // ✅ SI NO HAY TOP PLAYERS, mostrar mensaje
    if (topPlayers.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FrutiaColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: FrutiaColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: FrutiaColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Session Complete!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check the Rankings tab for detailed player statistics',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FrutiaColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FrutiaColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: FrutiaColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Top Performers',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: FrutiaColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View Rankings to see how each player performed today!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Top 3 players - ✅ USAR topPlayers.length PARA EVITAR ERRORES
        ...topPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final medals = ['🥇', '🥈', '🥉'];

          // ✅ MANEJAR CASO CUANDO player ES NULL
          if (player == null) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FrutiaColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FrutiaColors.tertiaryBackground,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  index < medals.length ? medals[index] : '🏅',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['display_name']?.toString() ?? 'Unknown Player',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.primaryText,
                        ),
                      ),
                      Text(
                        '${player['games_played'] ?? 0} games • ${player['win_percentage']?.toString() ?? '0'}% win rate',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: FrutiaColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${player['rating']?.toString() ?? '0'}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: FrutiaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  bool _shouldShowFinalResults() {
    return _sessionData != null && _sessionData!['status'] == 'completed';
  }

 bool _shouldShowFinalizeButton() {
  if (_sessionData == null) return false;

  // ✅ NO mostrar si la sesión ya está completada
  if (_sessionData!['status'] == 'completed') {
    return false;
  }

  final sessionType = _sessionData!['session_type'];
  
  // ✅ AGREGAR PARA TOURNAMENT
  if (sessionType == 'T') {
    final currentStage = _sessionData!['current_stage'] ?? 1;
    
    // Si está en Stage 3 y no hay juegos pendientes ni activos
    if (currentStage == 3) {
      return _nextGames.isEmpty && _liveGames.isEmpty && _completedGames.isNotEmpty;
    }
    
    return false;
  }

  // Para P8: Final Y Bronze completados
  if (sessionType == 'P8') {
    final goldCompleted = _completedGames.any((g) =>
        (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
        g['playoff_round'] == 'gold');

    final bronzeCompleted = _completedGames.any((g) =>
        (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
        g['playoff_round'] == 'bronze');

    return goldCompleted && bronzeCompleted && _liveGames.isEmpty;
  }

  // Para P4: Solo Final completada
  if (sessionType == 'P4') {
    final finalCompleted = _completedGames.any((g) =>
        (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
        g['playoff_round'] == 'final');

    return finalCompleted && _liveGames.isEmpty;
  }

  // Para Optimized: Todos los juegos completados
  if (sessionType == 'O') {
    return _nextGames.isEmpty &&
        _liveGames.isEmpty &&
        _completedGames.isNotEmpty;
  }

  return false;
}

  Color _getWinnerBackgroundColor(Map<String, dynamic> game) {
    final isPlayoffGame =
        game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;

    if (!isPlayoffGame) {
      // Partidos normales: verde como antes
      return FrutiaColors.accent.withOpacity(0.15);
    }

    final playoffRound = game['playoff_round']?.toString().toLowerCase();

    switch (playoffRound) {
      case 'gold':
        // Final: Dorado suave
        return const Color(0xFFFFD700).withOpacity(0.3);
      case 'bronze':
        // Bronze Match: Bronce suave
        return const Color(0xFFCD7F32).withOpacity(0.3);
      case 'semifinal':
        // Semifinals: Verde como antes

        return const Color(0xFFFF6B35).withOpacity(0.3);

      default:
        return FrutiaColors.accent.withOpacity(0.15);
    }
  }

  Widget _buildGameCard(
    Map<String, dynamic> game, {
    bool isLive = false,
    bool isCompleted = false,
    int? queuePosition,
    bool shouldShowStartGame = false,
  }) {
    final team1Player1 = game['team1_player1'];
    final team1Player2 = game['team1_player2'];
    final team2Player1 = game['team2_player1'];
    final team2Player2 = game['team2_player2'];
    final court = game['court'];
    final isPending = !isLive && !isCompleted;
    final isPlayoffGame =
        game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;

    // ✅ CORREGIDO: Solo verificar si tiene cancha asignada
    final hasCourtAssigned = court != null && game['court_id'] != null;
    final courtStatus = court?['status'] ?? 'unknown';
    final isCourtAvailable = hasCourtAssigned && courtStatus == 'available';

    // ✅ NUEVA LÓGICA: Usar el parámetro shouldShowStartGame que viene del cálculo
    final showStartGameButton = isPending &&
        hasCourtAssigned &&
        isCourtAvailable &&
        shouldShowStartGame &&
        !widget.isSpectator;

    print('🔄 Game Card Debug - Game #${game['game_number']}:');
    print('   - hasCourtAssigned: $hasCourtAssigned');
    print('   - isCourtAvailable: $isCourtAvailable');
    print('   - shouldShowStartGame: $shouldShowStartGame');
    print('   - showStartGameButton: $showStartGameButton');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Queue number card (solo si es pending y tiene posición)
            if (queuePosition != null) ...[
              Container(
                width: 50,
                decoration: BoxDecoration(
                  color: showStartGameButton
                      ? FrutiaColors.success.withOpacity(0.2)
                      : FrutiaColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showStartGameButton
                        ? FrutiaColors.success
                        : FrutiaColors.primary.withOpacity(0.3),
                    width: showStartGameButton ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: showStartGameButton
                              ? FrutiaColors.success
                              : FrutiaColors.primary,
                        ),
                      ),
                      Text(
                        queuePosition.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: showStartGameButton
                              ? FrutiaColors.success
                              : FrutiaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Main game card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isLive
                      ? FrutiaColors.success.withOpacity(0.1)
                      : (isPlayoffGame && isCompleted)
                          ? FrutiaColors.accent.withOpacity(0.05)
                          : (showStartGameButton)
                              ? FrutiaColors.success.withOpacity(0.05)
                              : FrutiaColors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive
                        ? FrutiaColors.success
                        : (isPlayoffGame && isCompleted)
                            ? FrutiaColors.accent
                            : (showStartGameButton)
                                ? FrutiaColors.success
                                : FrutiaColors.tertiaryBackground,
                    width: (isLive ||
                            (isPlayoffGame && isCompleted) ||
                            showStartGameButton)
                        ? 2
                        : 1,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Playoff label (si es playoff)
                          if (isPlayoffGame) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _getPlayoffGradient(
                                      game['playoff_round']),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _getPlayoffColor(game['playoff_round'])
                                            .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPlayoffIcon(game['playoff_round']),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getPlayoffLabel(game) ?? 'PLAYOFF',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Court info y LIVE badge
                          Row(
                            children: [
                              // Court info (solo mostrar en LIVE y COMPLETED)
                              if (court != null && (isLive || isCompleted)) ...[
                                Transform.rotate(
                                  angle: 90 * 3.1416 / 180,
                                  child: Image.asset(
                                    'assets/icons/padel.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  court['court_name'] ?? 'Court',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: FrutiaColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              // LIVE badge
                              if (isLive) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: FrutiaColors.success,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'LIVE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],

                              const Spacer(),

                              // Botones de acción (skip, edit, cancel)
                              if (isPending &&
                                  !hasCourtAssigned &&
                                  queuePosition != 1 &&
                                  !widget.isSpectator) ...[
                                InkWell(
                                  onTap: () => _showSkipLineConfirmation(game),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          FrutiaColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.skip_next,
                                      size: 18,
                                      color: FrutiaColors.primary,
                                    ),
                                  ),
                                ),
                              ],

                              // Edit button for completed games
                              if (isCompleted && !widget.isSpectator) ...[
                                InkWell(
                                  onTap: () async {
                                    final shouldEdit = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Edit Score?',
                                          style: GoogleFonts.poppins(
                                              color: FrutiaColors.primaryText),
                                        ),
                                        content: Text(
                                          'Any changes to scores will recalculate ratings and rankings as if this game was replayed NOW - these changes cannot be reverted.',
                                          style: GoogleFonts.lato(
                                              color:
                                                  FrutiaColors.secondaryText),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Cancel',
                                              style: GoogleFonts.lato(
                                                  color: FrutiaColors
                                                      .secondaryText),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Continue',
                                              style: GoogleFonts.lato(
                                                  color: FrutiaColors.primary,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldEdit == true && mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => ScoreEntryDialog(
                                          game: game,
                                          session: _sessionData!,
                                          onScoreSubmitted: () {
                                            _loadSessionData();
                                          },
                                          isEditing: true,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          FrutiaColors.warning.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: FrutiaColors.warning,
                                    ),
                                  ),
                                ),
                              ],

                              // Cancel button for live games
                              if (isLive && !widget.isSpectator) ...[
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Cancel game?',
                                          style: GoogleFonts.poppins(
                                              color: FrutiaColors.primaryText),
                                        ),
                                        content: Text(
                                          'Are you sure you want to cancel this game? It will be moved back to the list of pending matches.',
                                          style: GoogleFonts.lato(
                                              color:
                                                  FrutiaColors.secondaryText),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              "Don't cancel",
                                              style: GoogleFonts.lato(
                                                fontWeight: FontWeight.bold,
                                                color: FrutiaColors.primary,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Cancel',
                                              style: GoogleFonts.lato(
                                                  fontWeight: FontWeight.bold,
                                                  color: FrutiaColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await GameService.cancelGame(
                                            game['id']);
                                        _loadSessionData();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Game canceled!',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                              backgroundColor:
                                                  FrutiaColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}'),
                                              backgroundColor:
                                                  FrutiaColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          FrutiaColors.error.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: FrutiaColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Game matchup
                      Row(
                        children: [
                          // Team 1
                          Expanded(
                            child: Container(
                              padding:
                                  isCompleted ? const EdgeInsets.all(8) : null,
                              decoration: isCompleted &&
                                      (game['team1_score'] ?? 0) >
                                          (game['team2_score'] ?? 0)
                                  ? BoxDecoration(
                                      color: _getWinnerBackgroundColor(game),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${team1Player1['first_name']} ${team1Player1['last_initial']}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: FrutiaColors.primaryText,
                                    ),
                                  ),
                                  Text(
                                    '${team1Player2['first_name']} ${team1Player2['last_initial']}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: FrutiaColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Score or VS
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
                          const SizedBox(width: 12),

                          // Team 2
                          Expanded(
                            child: Container(
                              padding:
                                  isCompleted ? const EdgeInsets.all(8) : null,
                              decoration: isCompleted &&
                                      (game['team2_score'] ?? 0) >
                                          (game['team1_score'] ?? 0)
                                  ? BoxDecoration(
                                      color: _getWinnerBackgroundColor(game),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${team2Player1['first_name']} ${team2Player1['last_initial']}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: FrutiaColors.primaryText,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    '${team2Player2['first_name']} ${team2Player2['last_initial']}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: FrutiaColors.primaryText,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✅ Action buttons
                      if (!widget.isSpectator) ...[
                        // Live game button
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Record Result',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ✅ Start Game button - SOLO cuando shouldShowStartGame es true
                        if (showStartGameButton) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _startGame(game),
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: Text(
                                'Start Game',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FrutiaColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Método para confirmar Skip the Line
  Future<void> _showSkipLineConfirmation(Map<String, dynamic> game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Skip the Line?',
          style: GoogleFonts.poppins(color: FrutiaColors.primaryText),
        ),
        content: Text(
          'Are you sure you want this game to skip the line and be played next?',
          style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Skip the Line',
              style: GoogleFonts.lato(
                color: FrutiaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _skipToCourt(game);
    }
  }

  Future<void> _skipToCourt(Map<String, dynamic> game) async {
    try {
      await GameService.skipToCourt(game['id']);
      _loadSessionData();
      _tabController.animateTo(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game moved to court!', // ← Agregué !
              style: TextStyle(fontSize: 17), // ← Agregué fontSize
            ),
            backgroundColor: FrutiaColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('No courts available')
                  ? 'No courts available. Complete active games first.'
                  : 'Error: ${e.toString()}',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: FrutiaColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _startGame(Map<String, dynamic> game) async {
    if (!mounted) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Starting game...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await GameService.startGame(game['id']);

      // ✅ Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      // ✅ RECARGAR DATOS COMPLETOS para ver cambios en la cola
      await _loadSessionData();

      // ✅ IR A LA PESTAÑA LIVE
      _tabController.animateTo(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game started!',
              style: TextStyle(fontSize: 17),
            ),
            backgroundColor: FrutiaColors.success,
          ),
        );
      }
    } catch (e) {
      // ✅ Cerrar diálogo de carga en caso de error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        String errorMessage = 'Error: ${e.toString()}';

        if (e.toString().contains('ocupada') ||
            e.toString().contains('occupied')) {
          errorMessage =
              'This court is already in use. Complete active games first or use "Skip the Line".';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: FrutiaColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
