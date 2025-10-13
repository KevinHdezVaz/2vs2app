// lib/pages/screens/sessionControl/SessionControlPanel.dart
import 'package:Frutia/pages/screens/SessionControl/ScoreEntryDialog.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

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

      // ✅ OBTENER USER_ID ACTUAL para verificar propiedad
      final currentUserId =
          await _getCurrentUserId(); // Necesitarás implementar esto

      // ✅ VERIFICAR SI REALMENTE ES SPECTATOR
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
          // ✅ GUARDAR SI REALMENTE ES SPECTATOR
          _isReallySpectator = isReallySpectator;

             // ✅ AGREGAR ESTE DEBUGGING AQUÍ
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
          print('  Game #${game['game_number']}: stage=${game['stage']}, status=${game['status']}');
        }
      } else {
        print('\n✅ NO HAY NEXT GAMES (debería mostrar botón)');
      }
      print('🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍\n');
    });

       


        // 👇 DETENER TIMERS SI LA SESIÓN ESTÁ COMPLETADA
        if (session['status'] == 'completed') {
          _sessionTimer?.cancel();
          _refreshTimer?.cancel();

          // Opcional: Mostrar mensaje de sesión completada
          if (!isReallySpectator) {
            // ← Usar isReallySpectator en lugar de widget.isSpectator
            _showSessionCompletedDialog();
          }
        }

        // ✅ USAR isReallySpectator EN LUGAR DE widget.isSpectator
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

        // Mostrar error al usuario
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
          actions: [
            Center(
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
    if (_liveGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.6, // Ajusta la opacidad (0.0 a 1.0)
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.grey.shade400, // Puedes usar diferentes tonos de gris
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
  final shouldShowFinalsButton = _shouldShowStartFinalsButton();

  if (_nextGames.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (shouldShowFinalsButton) ...[
            _buildStartFinalsButton(),
          ] else ...[
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
          
          // ✅ ARREGLAR: Agregar 'T' a la condición
          if (_sessionData != null &&
              (_sessionData!['session_type'] == 'P4' ||
                  _sessionData!['session_type'] == 'P8' ||
                  _sessionData!['session_type'] == 'T') &&  // ← ✅ AGREGAR ESTO
              _liveGames.isEmpty &&
              !shouldShowFinalsButton)
            _buildAdvanceStageButton(),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: () => _loadSessionData(),
    color: FrutiaColors.primary,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nextGames.length + (shouldShowFinalsButton ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (shouldShowFinalsButton && index == _nextGames.length) {
          return _buildStartFinalsButton();
        }

        if (index == _nextGames.length + (shouldShowFinalsButton ? 1 : 0)) {
          return _buildAdvanceStageButton();
        }

        return _buildGameCard(
          _nextGames[index],
          queuePosition: index + 1,
        );
      },
    ),
  );
}

bool _shouldShowStartFinalsButton() {
  if (_sessionData == null) return false;
  if (_sessionData!['session_type'] != 'P8') return false;

  // ✅ CORREGIDO: Comparar con 1 en lugar de true
  final completedSemifinals = _completedGames.where((g) {
    final isPlayoff = g['is_playoff_game'] == 1 || g['is_playoff_game'] == true;
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
              backgroundColor: FrutiaColors.accent2
              ,
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
    final hasPendingGamesInCurrentStage = _nextGames.any((game) => 
      game['stage'] == currentStage
    );
    print('[DEBUG] Has pending games in stage $currentStage: $hasPendingGamesInCurrentStage');
    
    if (hasPendingGamesInCurrentStage) {
      print('[DEBUG] Showing next games stages:');
      for (var game in _nextGames) {
        print('  - Game #${game['game_number']}: stage=${game['stage']}');
      }
    }
  }
  print('==========================================');

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

    final hasPendingGamesInCurrentStage = _nextGames.any((game) => 
      game['stage'] == currentStage
    );

    if (hasPendingGamesInCurrentStage) {
      print('[DEBUG] ❌ Not showing: Has pending games in current stage');
      return const SizedBox.shrink();
    }

    print('[DEBUG] ✅ SHOWING BUTTON: Advance to Stage ${currentStage + 1}');
    
    // ... resto del código que ya tienes
    // ✅ Si llegamos aquí, mostrar botón de avance
    String buttonText = 'Advance to Stage ${currentStage + 1}';
    String description = 'Generate Stage ${currentStage + 1} matches based on Stage $currentStage results';
    
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
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

  // ✅ PARA PLAYOFFS: Lógica existente
  final hasActivePlayoffGames =
      _liveGames.any((game) => (game['is_playoff_game'] == 1 || game['is_playoff_game'] == true)) ||
          _nextGames.any((game) => (game['is_playoff_game'] == 1 || game['is_playoff_game'] == true));

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
    margin: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
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
        const SizedBox(height: 20),
        Container(
          height: 1,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
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
}// Reemplaza SOLO el método _showAdvanceStageConfirmation en SessionControlPanel.dart
// Busca el método existente (aproximadamente línea 300-350) y reemplázalo con este:

// AGREGAR estos 3 métodos AL FINAL del archivo

  Color _getPlayoffColor(String? playoffRound) {
    switch (playoffRound) {
      case 'semifinal':
        return const Color.fromARGB(255, 100, 97, 100); // Morado
      case 'gold':
        return const Color(0xFFFFD700); // Dorado
      case 'bronze':
        return const Color(0xFFCD7F32); // Bronce
      default:
        return FrutiaColors.accent;
    }
  }

  List<Color> _getPlayoffGradient(String? playoffRound) {
    switch (playoffRound) {
      case 'semifinal':
        return [
          const Color.fromARGB(255, 79, 79, 79), // Morado oscuro
          const Color.fromARGB(255, 85, 85, 85), // Morado claro
        ];
      case 'gold':
        return [
          const Color(0xFFFFD700), // Dorado
          const Color(0xFFFFC107), // Amarillo dorado
        ];
      case 'bronze':
        return [
          const Color(0xFFCD7F32), // Bronce oscuro
          const Color(0xFFD4A574), // Bronce claro
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
      allSemifinals.sort((a, b) => (a['game_number'] ?? 0).compareTo(b['game_number'] ?? 0));
      
      final index = allSemifinals.indexWhere((g) => g['game_number'] == gameNumber);
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

  Future<void> _executeAdvanceStage() async {
    try {
      final sessionType = _sessionData?['session_type'];

      if (sessionType == 'P4' || sessionType == 'P8') {
        await SessionService.generatePlayoffBracket(widget.sessionId);
      } else if (sessionType == 'T') {
        await SessionService.advanceToNextStage(widget.sessionId);
      }

      // Reset flags
      _hasShownPlayoffDialog = false;
      _hasShownStageDialog = false;

      // Recargar datos después de un breve delay
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadSessionData();

      // Mostrar mensaje de éxito
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

      // Reset flags on error
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
          Icon(Icons.check_circle, size: 64, color: FrutiaColors.disabledText),
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
    final aIsPlayoff = a['is_playoff_game'] == 1 || a['is_playoff_game'] == true;
    final bIsPlayoff = b['is_playoff_game'] == 1 || b['is_playoff_game'] == true;
    
    // Si ambos son playoff, ordenar por jerarquía
    if (aIsPlayoff && bIsPlayoff) {
      final aRound = a['playoff_round']?.toString().toLowerCase() ?? '';
      final bRound = b['playoff_round']?.toString().toLowerCase() ?? '';
      
      // Mapa de prioridad (menor número = más arriba)
      final priority = {
        'gold': 1,      // Final - Primero
        'bronze': 2,    // Bronze - Segundo
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
      padding: const EdgeInsets.all(16),
      itemCount: sortedGames.length,
      itemBuilder: (context, index) {
        return _buildGameCard(sortedGames[index], isCompleted: true);
      },
    ),
  );
}  Widget _buildPlayerStatsTab() {
    if (_players.isEmpty) {
      return Center(
        child: Text(
          'No players',
          style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: podiumColor ?? FrutiaColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor ?? FrutiaColors.tertiaryBackground,
                width: rank <= 3 ? 2 : 1,
              ),
              boxShadow: rank <= 3
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10), // ← Reducido horizontal padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🏅 Rank badge - MOVIDO MÁS A LA IZQUIERDA
                  Container(
                    width: 32, // ← Ligeramente más pequeño
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? (rank == 1
                              ? const Color(0xFFFFD700)
                              : rank == 2
                                  ? const Color(0xFFC0C0C0)
                                  : const Color(0xFFCD7F32))
                          : FrutiaColors.secondaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14, // ← Fuente ligeramente más pequeña
                          fontWeight: FontWeight.bold,
                          color: rank <= 3
                              ? Colors.white
                              : FrutiaColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // ← Reducido de 12 a 10

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

// SOLO LA PARTE DEL MÉTODO _buildGameCard QUE NECESITAS REEMPLAZAR

  Widget _buildGameCard(Map<String, dynamic> game,
      {bool isLive = false, bool isCompleted = false, int? queuePosition}) {
    final team1Player1 = game['team1_player1'];
    final team1Player2 = game['team1_player2'];
    final team2Player1 = game['team2_player1'];
    final team2Player2 = game['team2_player2'];
    final court = game['court'];
    final isPending = !isLive && !isCompleted;
    final isPlayoffGame = game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;

    // ✅ CORREGIDO: Verificar correctamente si tiene cancha asignada Y disponible
    final hasCourtAssigned = court != null && game['court_id'] != null;
    final courtStatus = court?['status'] ?? 'unknown';
    final isCourtAvailable = hasCourtAssigned && courtStatus == 'available';
    final isFirstInQueue = queuePosition == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Queue number card (solo si es pending)
            if (queuePosition != null) ...[
              Container(
                width: 50,
                decoration: BoxDecoration(
                  color: FrutiaColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FrutiaColors.primary.withOpacity(0.3),
                    width: 1,
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
                          color: FrutiaColors.primary,
                        ),
                      ),
                      Text(
                        queuePosition.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: FrutiaColors.primary,
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
                          : FrutiaColors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive
                        ? FrutiaColors.success
                        : (isPlayoffGame && isCompleted)
                            ? FrutiaColors.accent
                            : FrutiaColors.tertiaryBackground,
                    width: (isLive || (isPlayoffGame && isCompleted)) ? 2 : 1,
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
                      // Header: Court info and action buttons
                      Row(
                        children: [
// ✅ AGREGAR ESTO:
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
                            const SizedBox(width: 8),
                          ],
// MOSTRAR información del court en juegos LIVE y COMPLETED
if (court != null && (isLive || isCompleted)) ...[  // ← AGREGAR: (isLive || isCompleted)
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
],

                          
                          if (isPlayoffGame && isCompleted) ...[
                            if (court != null) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: FrutiaColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emoji_events,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    game['playoff_round']?.toUpperCase() ??
                                        'PLAYOFF',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (isLive) ...[
                            if (court != null) const SizedBox(width: 8),
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

                          // ✅ CORREGIDO: Skip the Line button (NO para el primero)
                          if (isPending &&
                              !hasCourtAssigned &&
                              !isFirstInQueue &&
                              !widget.isSpectator) ...[
                            InkWell(
                              onTap: () => _showSkipLineConfirmation(game),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: FrutiaColors.primary.withOpacity(0.1),
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
                                          color: FrutiaColors.secondaryText),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.lato(
                                              color:
                                                  FrutiaColors.secondaryText),
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
                                  color: FrutiaColors.warning.withOpacity(0.1),
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
                                          color: FrutiaColors.secondaryText),
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
                                    await GameService.cancelGame(game['id']);
                                    _loadSessionData();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Game canceled!',
                                            style: TextStyle(fontSize: 17),
                                          ),
                                          backgroundColor: FrutiaColors.success,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}'),
                                          backgroundColor: FrutiaColors.error,
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
                                  color: FrutiaColors.error.withOpacity(0.1),
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
                                      color:
                                          FrutiaColors.accent.withOpacity(0.15),
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
                                      color:
                                          FrutiaColors.accent.withOpacity(0.15),
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

                        // Pending game with court assigned
                        if (isPending &&
                            hasCourtAssigned &&
                            isCourtAvailable) ...[
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
  // ✅ AGREGAR: Mostrar loading
  if (!mounted) return;
  
  // Mostrar diálogo de carga
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
    
    await _loadSessionData();
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
