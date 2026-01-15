// lib/pages/screens/sessionControl/SessionControlPanel.dart
import 'dart:convert';

import 'package:Frutia/pages/screens/SessionControl/ScoreEntryDialog.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/services/SessionResultsImageService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart'; // ← AGREGAR ESTA LÍNEA

class SessionControlPanel extends StatefulWidget {
  final int sessionId;
  final bool isSpectator;
  final bool isModerator; // ✅ NUEVO
  final bool isOwner; // ✅ NUEVO

  const SessionControlPanel({
    super.key,
    required this.sessionId,
    this.isSpectator = false,
    this.isModerator = false, // ✅ NUEVO
    this.isOwner = false, // ✅ NUEVO
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
  bool _isManualFinalization = false;
  bool _isFinalizingFromInfoDialog = false; // ← NUEVA BANDERA ESPECÍFICA

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

  // ✅ NUEVAS VARIABLES DE ESTADO
  bool _isOwner = false;
  bool _isModerator = false;
  bool _isReallySpectator = false;

  // ✅ ACTUALIZAR LOS GETTERS
  bool get isModerator => _isModerator;
  bool get isOwner => _isOwner;
  bool get isReallySpectator => _isReallySpectator;

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
      if (isReallySpectator) return; // No necesario para espectadores

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
      // ✅ PASO 1: Obtener sesión
      final sessionResponse = widget.isSpectator
          ? await SessionService.getPublicSession(widget.sessionId)
          : await SessionService.getSession(widget.sessionId);

      if (!mounted) return;

      final session = sessionResponse['session'];

      // ✅ PASO 2: Determinar roles
      final currentUserId = await _getCurrentUserId();
      final sessionOwnerId = session['user_id'] as int?;

      // ✅ CALCULAR FLAGS
      final calculatedIsOwner = !widget.isSpectator &&
          sessionOwnerId != null &&
          sessionOwnerId == currentUserId;

      final calculatedIsModerator = widget.isModerator;

      final calculatedIsReallySpectator = widget.isSpectator ||
          (sessionOwnerId != null &&
              sessionOwnerId != currentUserId &&
              !widget.isModerator);

      print('');
      print('═══════════════════════════════════════');
      print('🔍 ROLES CHECK');
      print('═══════════════════════════════════════');
      print('📱 widget.isSpectator: ${widget.isSpectator}');
      print('📱 widget.isModerator: ${widget.isModerator}');
      print('📱 widget.isOwner: ${widget.isOwner}');
      print('👤 Current User ID: $currentUserId');
      print('👑 Session Owner ID: $sessionOwnerId');
      print('');
      print('🎯 Calculated Is Owner: $calculatedIsOwner');
      print('🎯 Calculated Is Moderator: $calculatedIsModerator');
      print('🎯 Calculated Is Really Spectator: $calculatedIsReallySpectator');
      print('═══════════════════════════════════════');
      print('');

      // ✅ PASO 3: Cargar juegos
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

          // ✅ ACTUALIZAR LOS FLAGS DE ESTADO
          _isOwner = calculatedIsOwner;
          _isModerator = calculatedIsModerator;
          _isReallySpectator = calculatedIsReallySpectator;

          _isLoading = false;

          print('\n🔍🔍🔍 DATOS CARGADOS DESDE API 🔍🔍🔍');
          print('Session Type: ${session['session_type']}');
          print('Current Stage: ${session['current_stage']}');
          print('Status: ${session['status']}');
          print('Next Games Count: ${nextGames.length}');
          print('Live Games Count: ${liveGames.length}');
          print('Completed Games Count: ${completedGames.length}');
          print('🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍\n');
        });

        // ✅ Cargar Primary Active Game si no es espectador
        if (!_isReallySpectator) {
          await _loadPrimaryActiveGame();
        }

        if (session['status'] == 'completed') {
          _sessionTimer?.cancel();
          _refreshTimer?.cancel();
        }

        if (!_isReallySpectator) {
          _checkForStageOrPlayoffCompletion();
        }

        // ✅ Auto-navegación al tab Next
        if (liveGames.isEmpty && nextGames.isNotEmpty && !silent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _tabController.index == 0) {
              _tabController.animateTo(1);
              print(
                  '📍 Auto-navegando al tab Next (Live vacío, Next tiene ${nextGames.length} juegos)');
            }
          });
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
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

// En _loadSessionData() - LÍNEA ~195
  Future<int> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');

      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        final userId = userData['id'] as int?;

        // ✅ AGREGAR LOGS PARA DEBUG
        print('🔑 User Data from SharedPreferences:');
        print('   - Raw JSON: $userDataJson');
        print('   - Parsed user_id: $userId');

        return userId ?? 0;
      }

      print('⚠️ No user data found in SharedPreferences');
      return 0;
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return 0;
    }
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
            //    _showStageAdvanceDialog('Advance to Stage ${currentStage + 1}');
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
            //   _showStageAdvanceDialog('Advance to Playoffs');
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

  // ✅ NUEVO HELPER para formatear nombres
  String _formatPlayerName(Map<String, dynamic> player) {
    if (player['first_name'] == null) return 'Unknown';

    final firstName = player['first_name'].toString();
    final lastInitial = player['last_initial']?.toString() ?? '';

    // Formatear Nombre (Title Case)
    String formattedFirstName = firstName;
    if (firstName.isNotEmpty) {
      formattedFirstName = firstName[0].toUpperCase() +
          (firstName.length > 1 ? firstName.substring(1).toLowerCase() : '');
    }

    // Formatear Apellido (Solo inicial + punto)
    String formattedLastInitial = '';
    if (lastInitial.isNotEmpty) {
      // Tomar solo la primera letra y asegurar mayúscula
      formattedLastInitial = '${lastInitial[0].toUpperCase()}.';
    }

    return '$formattedFirstName $formattedLastInitial'.trim();
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

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75), // ✅ AUMENTADO de 56 → 82
          child: AppBar(
            backgroundColor: FrutiaColors.primary,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8), // ✅ Centrar verticalmente
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge de Spectator o Moderator
                  if (isReallySpectator)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: FrutiaColors.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_red_eye,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Spectator Mode',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isModerator && !isOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B9BD1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Moderator Mode',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isReallySpectator || (isModerator && !isOwner))
                    const SizedBox(height: 6), // ← Espacio después del badge

                  // Línea 1: Session Name o Courts/Players
                  Text(
                    isReallySpectator || (isModerator && !isOwner)
                        ? '$numberOfCourts Courts | $numberOfPlayers Players'
                        : sessionName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5), // ← Espacio sutil entre líneas

                  // Línea 2: Courts/Players o Session Name
                  Text(
                    isReallySpectator || (isModerator && !isOwner)
                        ? sessionName
                        : '$numberOfCourts Courts | $numberOfPlayers Players',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Solo si NO es espectador ni moderador
                  if (!isReallySpectator && !(isModerator && !isOwner)) ...[
                    const SizedBox(
                        height:
                            7), // ← Espacio antes del % Complete (el toque perfecto)

                    Text(
                      '${progressPercentage.toInt()}% Complete',
                      style: GoogleFonts.lato(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // ✅ Timer clickeable SOLO si NO es espectador
              if (!isReallySpectator)
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
                        const Icon(Icons.timer,
                            color: FrutiaColors.ElectricLime, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimer(_elapsedSeconds),
                          style: GoogleFonts.robotoMono(
                            color: FrutiaColors.ElectricLime,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // ✅ Timer NO clickeable para espectadores
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimer(_elapsedSeconds),
                        style: GoogleFonts.robotoMono(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
                indicatorColor: FrutiaColors.LighterNavy,
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
        // ✅ RESULTADOS FINALES ARRIBA (con scroll interno si es necesario)
        if (shouldShowFinalResults) ...[
          Flexible(
            // ← CAMBIO CLAVE: Flexible en lugar de solo agregar el widget
            fit: FlexFit.loose,
            child: _buildFinalResultsCard(),
          ),
        ],
        // ✅ CONTENIDO NORMAL DEL LIVE TAB
        if (_liveGames.isEmpty && !shouldShowFinalResults)
          Expanded(
            child: Column(
              children: [
                // ✅ ESPACIADO SUPERIOR (30% de la altura)
                Spacer(flex: 1),
                // ✅ BOTONES DE ACCIÓN (sin ícono de fondo)
                if (_shouldShowFinalizeButton())
                  _buildFinalizeButton()
                else if (_shouldShowStartFinalsButton())
                  _buildStartFinalsButton()
                else if (_sessionData != null &&
                    (_sessionData!['session_type'] == 'P4' ||
                        _sessionData!['session_type'] == 'P8' ||
                        _sessionData!['session_type'] == 'T' ||
                        _sessionData!['session_type'] == 'S') &&
                    !_shouldShowFinalizeButton() &&
                    !_shouldShowStartFinalsButton() &&
                    _nextGames.isEmpty)
                  _buildAdvanceStageButton()
                // ✅ ÍCONO Y TEXTO (solo si NO hay botones de acción)
                else ...[
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
                // ✅ ESPACIADO INFERIOR (70% de la altura)
                Spacer(flex: 7),
              ],
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

// ════════════════════════════════════════════════════════════════
  Widget _buildNextGamesTab() {
    final shouldShowFinalsButton = _shouldShowStartFinalsButton();
    final shouldShowFinalizeButton = _shouldShowFinalizeButton();
    final shouldShowFinalResults = _shouldShowFinalResults();
    final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
    final liveGamesCount = _liveGames.length;
    final availableStartSlots = max<int>(0, numberOfCourts - liveGamesCount);

    if (_nextGames.isEmpty) {
      return Column(
        children: [
          if (shouldShowFinalResults) _buildFinalResultsCard(),
          if (!shouldShowFinalResults)
            Expanded(
              child: Column(
                children: [
                  Spacer(flex: 1),

                  // ✅ BOTONES DE ACCIÓN
                  if (shouldShowFinalizeButton)
                    _buildFinalizeButton()
                  else if (shouldShowFinalsButton)
                    _buildStartFinalsButton()
                  else if (_sessionData != null &&
                      (_sessionData!['session_type'] == 'P4' ||
                          _sessionData!['session_type'] == 'P8' ||
                          _sessionData!['session_type'] == 'T' ||
                          _sessionData!['session_type'] == 'O' ||
                          _sessionData!['session_type'] == 'S') &&
                      _liveGames.isEmpty &&
                      !shouldShowFinalsButton &&
                      !shouldShowFinalizeButton &&
                      !shouldShowFinalResults)
                    _buildAdvanceStageButton()
                  // ✅ ÍCONO Y TEXTO (solo si NO hay botones de acción)
                  else ...[
                    Icon(Icons.queue,
                        size: 64, color: FrutiaColors.disabledText),
                    const SizedBox(height: 16),
                    Text(
                      'No games in queue',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: FrutiaColors.secondaryText,
                      ),
                    ),
                  ],
                  Spacer(flex: 7),
                ],
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
                  1 + // ← Para el botón "Copy Schedule"
                  1, // ← Para el botón de avanzar stage
              itemBuilder: (context, index) {
                // Manejar botón de Finalize
                if (shouldShowFinalizeButton && index == 0) {
                  return _buildFinalizeButton();
                }

                final finalizeOffset = shouldShowFinalizeButton ? 1 : 0;

                // Manejar botón de Finals
                if (shouldShowFinalsButton &&
                    index == _nextGames.length + finalizeOffset) {
                  return _buildStartFinalsButton();
                }

                // Manejar botón de View Schedule
                if (index ==
                    _nextGames.length +
                        finalizeOffset +
                        (shouldShowFinalsButton ? 1 : 0)) {
                  return _buildViewScheduleButton();
                }

                // Manejar botón de Advance Stage
                if (index ==
                    _nextGames.length +
                        finalizeOffset +
                        (shouldShowFinalsButton ? 1 : 0) +
                        1) {
                  return _buildAdvanceStageButton();
                }

                // ✅ Calcular el índice REAL en _nextGames
                final actualGameIndex = index - finalizeOffset;
                final game = _nextGames[actualGameIndex];

                // ════════════════════════════════════════════════════════
                // ✅ CORRECCIÓN QUIRÚRGICA - CAMBIO DE 1 LÍNEA
                // ════════════════════════════════════════════════════════
                //
                // ANTES (solo primer juego):
                // final shouldShowStartGame =
                //     (actualGameIndex == 0 && availableStartSlots > 0);
                //
                // AHORA (primeros N juegos, donde N = slots disponibles):
                final shouldShowStartGame =
                    (actualGameIndex < availableStartSlots) &&
                        !isReallySpectator;
                //
                // EJEMPLO:
                // - 2 canchas, 0 live → availableStartSlots = 2
                //   → Juegos en posición 0 y 1 muestran botón ✅
                //
                // - 2 canchas, 1 live → availableStartSlots = 1
                //   → Solo juego en posición 0 muestra botón ✅
                //
                // - 2 canchas, 2 live → availableStartSlots = 0
                //   → Ningún juego muestra botón ✅
                // ════════════════════════════════════════════════════════

                return _buildGameCard(
                  game,
                  queuePosition: actualGameIndex + 1,
                  shouldShowStartGame: shouldShowStartGame,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NUEVO WIDGET: Botón para ver schedule completo
  Widget _buildViewScheduleButton() {
    // ✅ NO MOSTRAR si es espectador
    if (isReallySpectator) {
      return const SizedBox.shrink();
    }

    // ✅ NO MOSTRAR si no hay juegos
    if (_nextGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: OutlinedButton.icon(
        onPressed: _showScheduleDialog,
        icon: Icon(
          Icons.list_alt,
          size: 18,
          color: FrutiaColors.primary,
        ),
        label: Text(
          'View & Share Schedule',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          side: BorderSide(
            color: FrutiaColors.LighterNavy,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: FrutiaColors.primary.withOpacity(0.05),
        ),
      ),
    );
  } // ✅ NUEVO MÉTODO: Mostrar diálogo con schedule completo (MEJORADO)

  Future<void> _showScheduleDialog() async {
    final sessionName = _sessionData?['session_name'] ?? 'Session';

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================== HEADER ====================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: FrutiaColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Games',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            sessionName,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================== REMAINING GAMES LABEL ====================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: FrutiaColors.primaryBackground,
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: FrutiaColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Remaining Games: ${_nextGames.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================== GAMES LIST ====================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nextGames.length,
                  itemBuilder: (context, index) {
                    final game = _nextGames[index];
                    final gameNumber = game['game_number'] ?? (index + 1);

                    // Obtener nombres de jugadores
                    final team1Player1 = game['team1_player1'];
                    final team1Player2 = game['team1_player2'];
                    final team2Player1 = game['team2_player1'];
                    final team2Player2 = game['team2_player2'];

                    // Helper para truncar nombres largos
                    String _formatPlayerName(Map<String, dynamic> player) {
                      final firstName = player['first_name'] ?? '';
                      final lastInitial = player['last_initial'] ?? '';

                      // Si el nombre es muy largo, truncar a 10 caracteres
                      final displayName = firstName.length > 10
                          ? firstName.substring(0, 10)
                          : firstName;

                      return '$displayName ${lastInitial}.';
                    }

                    final team1P1Name = _formatPlayerName(team1Player1);
                    final team1P2Name = _formatPlayerName(team1Player2);
                    final team2P1Name = _formatPlayerName(team2Player1);
                    final team2P2Name = _formatPlayerName(team2Player2);

                    // Info adicional
                    final isPlayoffGame = game['is_playoff_game'] == 1 ||
                        game['is_playoff_game'] == true;
                    final playoffLabel =
                        isPlayoffGame ? _getPlayoffLabel(game) : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isPlayoffGame
                            ? FrutiaColors.accent.withOpacity(0.08)
                            : FrutiaColors.primaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPlayoffGame
                              ? _getPlayoffColor(game['playoff_round'])
                              : FrutiaColors.tertiaryBackground,
                          width: isPlayoffGame ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Game number + playoff badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: FrutiaColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Game $gameNumber',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (playoffLabel != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _getPlayoffColor(game['playoff_round']),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    playoffLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ✅ EQUIPOS LADO A LADO
                          Row(
                            children: [
                              // Team 1
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: FrutiaColors.LighterLime,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: FrutiaColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '1',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Team 1',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    FrutiaColors.secondaryText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        team1P1Name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: FrutiaColors.primaryText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        team1P2Name,
                                        style: GoogleFonts.lato(
                                          fontSize: 11,
                                          color: FrutiaColors.secondaryText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // VS
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'VS',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),

                              // Team 2
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: FrutiaColors.NavyTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: FrutiaColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '2',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Team 2',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: FrutiaColors.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        team2P1Name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: FrutiaColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        team2P2Name,
                                        style: GoogleFonts.lato(
                                          fontSize: 11,
                                          color: FrutiaColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ==================== FOOTER BUTTONS ====================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Botón Copiar
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _copyScheduleToClipboard();
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.content_copy,
                          size: 18,
                          color: FrutiaColors.primary,
                        ),
                        label: Text(
                          'Copy',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FrutiaColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                    const SizedBox(width: 12),
                    // Botón Cerrar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrutiaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ MÉTODO AUXILIAR: Copiar schedule al clipboard (versión simple)
  Future<void> _copyScheduleToClipboard() async {
    try {
      final buffer = StringBuffer();

      // Header
      final sessionName = _sessionData?['session_name'] ?? 'Session';
      buffer.writeln('UPCOMING GAMES SCHEDULE');
      buffer.writeln('══════════════════════════');
      buffer.writeln('$sessionName');
      buffer.writeln('Total Remaining: ${_nextGames.length} games');
      buffer.writeln('══════════════════════════\n');

      // Lista de juegos
      for (int i = 0; i < _nextGames.length; i++) {
        final game = _nextGames[i];
        final gameNumber = game['game_number'] ?? (i + 1);

        final team1Player1 = game['team1_player1'];
        final team1Player2 = game['team1_player2'];
        final team2Player1 = game['team2_player1'];
        final team2Player2 = game['team2_player2'];

        final team1P1Name =
            '${team1Player1['first_name']} ${team1Player1['last_initial']}.';
        final team1P2Name =
            '${team1Player2['first_name']} ${team1Player2['last_initial']}.';
        final team2P1Name =
            '${team2Player1['first_name']} ${team2Player1['last_initial']}.';
        final team2P2Name =
            '${team2Player2['first_name']} ${team2Player2['last_initial']}.';

        buffer.writeln(
            'Game $gameNumber: $team1P1Name & $team1P2Name vs $team2P1Name & $team2P2Name');
      }

      buffer.writeln('\n══════════════════════════');

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: FrutiaColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Schedule copied!',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error copying schedule: $e');
    }
  }

  Widget _buildFinalResultsCard() {
    final sessionName = _sessionData?['session_name'] ?? 'Session';
    final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
    final numberOfPlayers = _sessionData?['number_of_players'] ?? 0;
    final duration = _formatTimer(_elapsedSeconds);
    final sessionType = _sessionData?['session_type'] ?? 'O';

    // ✅ DETERMINAR QUÉ MOSTRAR según tipo de sesión
    final isPlayoffSession = sessionType == 'P4' || sessionType == 'P8';

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
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
      // ✅ SOLUCIÓN: Usar ConstrainedBox con maxHeight
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height *
              0.7, // ← 70% de la altura de pantalla
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16), // ← Mover padding aquí
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // ← Importante: min size
            children: [
              // Header existente
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FrutiaColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: FrutiaColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Complete! 🎉',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Check out the final results for session:',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: FrutiaColors.secondaryText,
                          ),
                        ),
                        Text(
                          '"$sessionName"',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Session Summary existente
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FrutiaColors.secondaryBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FrutiaColors.primary, width: 2),
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

              // ✅ CONTENIDO DINÁMICO según tipo de sesión
              const SizedBox(height: 14),
              if (isPlayoffSession)
                _buildPlayoffWinners(sessionType)
              else
                _buildTop3Players(),

              const SizedBox(height: 14),

              // ✅ BOTONES DE ACCIÓN (Compartir + Rankings)
              Row(
                children: [
                  // Botón de compartir
                  if (!isReallySpectator) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareSessionResults,
                        icon: Icon(Icons.share,
                            size: 16, color: FrutiaColors.primary),
                        label: Text(
                          'Share Results',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: FrutiaColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: FrutiaColors.ElectricLime,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                            color: FrutiaColors.ElectricLime.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Botón de rankings
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: FrutiaColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _tabController.animateTo(3);
                        },
                        icon: Icon(Icons.leaderboard,
                            size: 16, color: FrutiaColors.ElectricLime),
                        label: Text(
                          'View Rankings',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: FrutiaColors.ElectricLime,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrutiaColors.primary,
                          foregroundColor: FrutiaColors.ElectricLime,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
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

  /// ✅ NUEVO: Mostrar ganadores de playoffs (P4/P8)
  /// ✅ CORREGIDO: Mostrar ganadores de playoffs (P4/P8)
  Widget _buildPlayoffWinners(String sessionType) {
    // Obtener juegos de playoff completados
    final playoffResults = _getPlayoffWinners(sessionType);

    if (playoffResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FrutiaColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No playoff results available',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Winners',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 10),

        // 🥇 1st Place (Champions)
        if (playoffResults['champions'] != null)
          _buildWinnerLine(
            '🥇',
            '1st Place',
            playoffResults['champions'] as List,
          ),

        // 🥈 2nd Place (Runners-up)
        if (playoffResults['runners_up'] != null) ...[
          const SizedBox(height: 6),
          _buildWinnerLine(
            '🥈',
            '2nd Place',
            playoffResults['runners_up'] as List,
          ),
        ],

        // 🥉 3rd Place (PARA P4 Y P8 - si existe)
        // ✅ CORREGIDO: Remover la validación de sessionType == 'P8'
        if (playoffResults['third_place'] != null) ...[
          const SizedBox(height: 6),
          _buildWinnerLine(
            '🥉',
            '3rd Place',
            playoffResults['third_place'] as List,
          ),
        ],
      ],
    );
  }

  /// ✅ COMPLETO: Extraer ganadores según tipo de sesión
  Map<String, List?> _getPlayoffWinners(String sessionType) {
    Map<String, List?> results = {
      'champions': null,
      'runners_up': null,
      'third_place': null,
    };

    print('');
    print('═══════════════════════════════════════');
    print('🎯 ANALYZING PLAYOFF GAMES');
    print('═══════════════════════════════════════');
    print('Session Type: $sessionType');
    print('Total Completed Games: ${_completedGames.length}');
    print('Is Special P8: ${_isSpecialP8()}');
    print('');

    // ✅ PARA OPTIMIZED Y TOURNAMENT: No hay playoffs, retornar vacío
    // El UI mostrará el top 3 del ranking directamente
    if (sessionType == 'O' || sessionType == 'T') {
      print(
          'ℹ️  Session type $sessionType uses ranking-based results (no playoff games)');
      print('═══════════════════════════════════════');
      return results;
    }

    // ✅ MOSTRAR TODOS LOS JUEGOS COMPLETADOS (solo para debugging de playoffs)
    for (var i = 0; i < _completedGames.length; i++) {
      final game = _completedGames[i];
      final isPlayoffValue = game['is_playoff_game'];
      final playoffRound = game['playoff_round'];
      final gameNumber = game['game_number'];
      final winnerTeam = game['winner_team'];

      print('Game #$gameNumber (index $i):');
      print(
          '  - is_playoff_game RAW: $isPlayoffValue (type: ${isPlayoffValue.runtimeType})');
      print(
          '  - playoff_round: $playoffRound (type: ${playoffRound.runtimeType})');
      print('  - winner_team: $winnerTeam');

      final isPlayoff = isPlayoffValue == 1 || isPlayoffValue == true;
      print('  - isPlayoff EVALUATED: $isPlayoff');

      if (game['team1_player1'] != null) {
        print(
            '  - team1: ${game['team1_player1']['first_name']} & ${game['team1_player2']?['first_name']}');
      }
      if (game['team2_player1'] != null) {
        print(
            '  - team2: ${game['team2_player1']['first_name']} & ${game['team2_player2']?['first_name']}');
      }
      print('');
    }

    try {
      // ═══════════════════════════════════════
      // P4 - BUSCAR FINAL
      // ═══════════════════════════════════════
      // ═══════════════════════════════════════
// P4 - BUSCAR FINAL Y BRONZE (SI EXISTE)
// ═══════════════════════════════════════
      if (sessionType == 'P4') {
        print('🔍 LOOKING FOR P4 FINAL + BRONZE...');

        // ✅ Buscar Final/Gold
        Map<String, dynamic>? finalGame;
        for (var game in _completedGames) {
          final isPlayoff =
              game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;
          final round = game['playoff_round']?.toString().toLowerCase();

          if (isPlayoff && (round == 'final' || round == 'gold')) {
            finalGame = game;
            print('  ✅ FOUND FINAL/GOLD GAME #${game['game_number']}');
            break;
          }
        }

        if (finalGame != null) {
          print('');
          print('✅ FINAL GAME FOUND: #${finalGame['game_number']}');
          final winnerTeam = finalGame['winner_team'] ?? 0;
          print('   Winner Team: $winnerTeam');

          results['champions'] = _getTeamPlayers(finalGame, winnerTeam);
          results['runners_up'] =
              _getTeamPlayers(finalGame, winnerTeam == 1 ? 2 : 1);

          print(
              '   Champions: ${results['champions']?.map((p) => p['first_name']).join(' & ')}');
          print(
              '   Runners-up: ${results['runners_up']?.map((p) => p['first_name']).join(' & ')}');

          // ✅ BUSCAR BRONZE MATCH (si existe)
          Map<String, dynamic>? bronzeGame;
          for (var game in _completedGames) {
            final isPlayoff =
                game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;
            final round = game['playoff_round']?.toString().toLowerCase();

            if (isPlayoff && round == 'bronze') {
              bronzeGame = game;
              print('  ✅ FOUND BRONZE GAME #${game['game_number']}');
              break;
            }
          }

          if (bronzeGame != null) {
            final bronzeWinner = bronzeGame['winner_team'] ?? 0;
            results['third_place'] = _getTeamPlayers(bronzeGame, bronzeWinner);
            print(
                '   Third Place: ${results['third_place']?.map((p) => p['first_name']).join(' & ')}');
          }
        } else {
          print('');
          print('❌ NO FINAL GAME FOUND!');
        }
      }
      // ═══════════════════════════════════════
      // P8 ESPECIAL - BUSCAR FINAL Y QUALIFIER
      // ═══════════════════════════════════════
      else if (sessionType == 'P8' && _isSpecialP8()) {
        print('🔍 LOOKING FOR P8 SPECIAL (FINAL + QUALIFIER)...');

        // Buscar Final
        Map<String, dynamic>? finalGame;
        for (var game in _completedGames) {
          final isPlayoff =
              game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;
          final round = game['playoff_round']?.toString().toLowerCase();
          if (isPlayoff && round == 'final') {
            finalGame = game;
            break;
          }
        }

        // Buscar Qualifier
        Map<String, dynamic>? qualifierGame;
        for (var game in _completedGames) {
          final isPlayoff =
              game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;
          final round = game['playoff_round']?.toString().toLowerCase();
          if (isPlayoff && round == 'qualifier') {
            qualifierGame = game;
            break;
          }
        }

        if (finalGame != null && qualifierGame != null) {
          print('✅ FOUND FINAL: #${finalGame['game_number']}');
          print('✅ FOUND QUALIFIER: #${qualifierGame['game_number']}');

          final finalWinner = finalGame['winner_team'] ?? 0;
          final qualifierWinner = qualifierGame['winner_team'] ?? 0;

          // 🥇 Champions (ganadores del Final)
          results['champions'] = _getTeamPlayers(finalGame, finalWinner);

          // 🥈 Runners-up (perdedores del Final)
          results['runners_up'] =
              _getTeamPlayers(finalGame, finalWinner == 1 ? 2 : 1);

          // 🥉 Third Place (perdedores del Qualifier)
          results['third_place'] =
              _getTeamPlayers(qualifierGame, qualifierWinner == 1 ? 2 : 1);

          print(
              '   Champions: ${results['champions']?.map((p) => p['first_name']).join(' & ')}');
          print(
              '   Runners-up: ${results['runners_up']?.map((p) => p['first_name']).join(' & ')}');
          print(
              '   Third: ${results['third_place']?.map((p) => p['first_name']).join(' & ')}');
        } else {
          print(
              '❌ Missing games - Final: ${finalGame != null}, Qualifier: ${qualifierGame != null}');
        }
      }

      // ═══════════════════════════════════════
      // P8 NORMAL - BUSCAR GOLD Y BRONZE
      // ═══════════════════════════════════════
      else if (sessionType == 'P8') {
        print('🔍 LOOKING FOR P8 NORMAL (GOLD + BRONZE)...');

        // ✅ Buscar Gold (Final)
        Map<String, dynamic>? goldGame;
        for (var game in _completedGames) {
          final isPlayoff =
              game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;
          final round = game['playoff_round']?.toString().toLowerCase();

          print(
              '  Checking game #${game['game_number']}: isPlayoff=$isPlayoff, round=$round');

          if (isPlayoff && round == 'gold') {
            goldGame = game;
            print('  ✅ FOUND GOLD GAME!');
            break;
          }
        }

        // ✅ Buscar Bronze
        Map<String, dynamic>? bronzeGame;
        for (var game in _completedGames) {
          final isPlayoff =
              game['is_playoff_game'] == 1 || game['is_playoff_game'] == true;
          final round = game['playoff_round']?.toString().toLowerCase();

          if (isPlayoff && round == 'bronze') {
            bronzeGame = game;
            print('  ✅ FOUND BRONZE GAME!');
            break;
          }
        }

        if (goldGame != null && bronzeGame != null) {
          print('');
          print('✅ GOLD GAME FOUND: #${goldGame['game_number']}');
          print('✅ BRONZE GAME FOUND: #${bronzeGame['game_number']}');

          final goldWinner = goldGame['winner_team'] ?? 0;
          final bronzeWinner = bronzeGame['winner_team'] ?? 0;

          print('   Gold winner team: $goldWinner');
          print('   Bronze winner team: $bronzeWinner');

          // 🥇 Champions (ganadores del Gold)
          results['champions'] = _getTeamPlayers(goldGame, goldWinner);

          // 🥈 Runners-up (perdedores del Gold)
          results['runners_up'] =
              _getTeamPlayers(goldGame, goldWinner == 1 ? 2 : 1);

          // 🥉 Third Place (ganadores del Bronze)
          results['third_place'] = _getTeamPlayers(bronzeGame, bronzeWinner);

          print(
              '   Champions: ${results['champions']?.map((p) => p['first_name']).join(' & ')}');
          print(
              '   Runners-up: ${results['runners_up']?.map((p) => p['first_name']).join(' & ')}');
          print(
              '   Third: ${results['third_place']?.map((p) => p['first_name']).join(' & ')}');
        } else {
          print('');
          print('❌ MISSING GAMES:');
          print('   - Gold game: ${goldGame != null ? "Found" : "NOT FOUND"}');
          print(
              '   - Bronze game: ${bronzeGame != null ? "Found" : "NOT FOUND"}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ ERROR extracting playoff winners:');
      print('   Error: $e');
      print('   Stack: $stackTrace');
    }

    print('');
    print('🎯 FINAL RESULTS:');
    print(
        '   - Champions: ${results['champions']?.map((p) => p['first_name']).join(' & ') ?? 'null'}');
    print(
        '   - Runners-up: ${results['runners_up']?.map((p) => p['first_name']).join(' & ') ?? 'null'}');
    print(
        '   - Third Place: ${results['third_place']?.map((p) => p['first_name']).join(' & ') ?? 'null'}');
    print('═══════════════════════════════════════');
    print('');

    return results;
  }

  List<Map<String, dynamic>> _getTeamPlayers(
      Map<String, dynamic> game, int team) {
    List<Map<String, dynamic>> players = [];

    try {
      if (team == 1) {
        final p1 = game['team1_player1'];
        final p2 = game['team1_player2'];
        if (p1 != null) players.add(p1);
        if (p2 != null) players.add(p2);
      } else if (team == 2) {
        final p1 = game['team2_player1'];
        final p2 = game['team2_player2'];
        if (p1 != null) players.add(p1);
        if (p2 != null) players.add(p2);
      }
    } catch (e) {
      print('❌ Error getting team players: $e');
    }

    return players;
  }

  Widget _buildWinnerLine(String emoji, String title, List players) {
    // ✅ Solución: usar whereType para filtrar nulos y tipar correctamente
    final List<Map<String, dynamic>> validPlayers =
        players.whereType<Map<String, dynamic>>().toList();

    if (validPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ahora Dart sabe que cada elemento es Map<String, dynamic>
    // → puede usar _formatPlayerName sin problemas
    final playerNames = validPlayers.map(_formatPlayerName).join(' & ');

    final isFirstPlace = title == '1st Place';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isFirstPlace
            ? FrutiaColors.LighterLime
            : FrutiaColors.secondaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFirstPlace
              ? FrutiaColors.LighterLime.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title - $playerNames',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isFirstPlace ? FrutiaColors.primary : FrutiaColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Mostrar top 3 individuales (para Optimized)
  Widget _buildTop3Players() {
    final topPlayers = _players.take(3).toList();

    if (topPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FrutiaColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No ranking data available',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 3 Players',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 10),

        // 🥇 1st Place
        _buildTop3PlayerLine('🥇', '1st Place', topPlayers[0]),

        // 🥈 2nd Place
        if (topPlayers.length > 1) ...[
          const SizedBox(height: 6),
          _buildTop3PlayerLine('🥈', '2nd Place', topPlayers[1]),
        ],

        // 🥉 3rd Place
        if (topPlayers.length > 2) ...[
          const SizedBox(height: 6),
          _buildTop3PlayerLine('🥉', '3rd Place', topPlayers[2]),
        ],
      ],
    );
  }

// ✅ CORREGIDO: Sección del Top 3 - MÁS COMPACTA
  Widget _buildTop3Section(List<dynamic> topPlayers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 3 Players',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
        const SizedBox(height: 10),

        // 🥇 1st Place
        _buildTop3PlayerLine('🥇', '1st Place', topPlayers[0]),

        // 🥈 2nd Place
        if (topPlayers.length > 1) ...[
          const SizedBox(height: 6),
          _buildTop3PlayerLine('🥈', '2nd Place', topPlayers[1]),
        ],

        // 🥉 3rd Place
        if (topPlayers.length > 2) ...[
          const SizedBox(height: 6),
          _buildTop3PlayerLine('🥉', '3rd Place', topPlayers[2]),
        ],
      ],
    );
  }

// ✅ CORREGIDO: Línea individual - SOLO NOMBRE
  Widget _buildTop3PlayerLine(String emoji, String position, dynamic player) {
    // ✅ CORREGIDO: Obtener nombre correctamente
    final playerName = _formatPlayerName(player);

    // ✅ DEBUG: Ver qué datos tenemos
    print('🎯 Player data for $position:');
    print('   - display_name: ${player['display_name']}');
    print('   - first_name: ${player['first_name']}');
    print('   - last_initial: ${player['last_initial']}');
    print('   - Final name: $playerName');

    return Container(
      padding: const EdgeInsets.all(10),
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
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$position - $playerName', // ← SOLO NOMBRE Y POSICIÓN
              style: GoogleFonts.poppins(
                fontSize: 13,
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

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: FrutiaColors.primary,
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

    // Detectar si es P8 especial (6-7 jugadores, 1 cancha)
    final bool isSpecialP8 = _isSpecialP8();

    // Contar partidos completados que califican para generar finals
    int qualifyingGamesCompleted = 0;

    if (isSpecialP8) {
      // En P8 especial: contar Qualifier completado
      qualifyingGamesCompleted = _completedGames.where((g) {
        final isPlayoff =
            g['is_playoff_game'] == 1 || g['is_playoff_game'] == true;
        final round = g['playoff_round']?.toString().toLowerCase();
        return isPlayoff && round == 'qualifier';
      }).length;
    } else {
      // En P8 normal: contar semifinales completadas
      qualifyingGamesCompleted = _completedGames.where((g) {
        final isPlayoff =
            g['is_playoff_game'] == 1 || g['is_playoff_game'] == true;
        final round = g['playoff_round']?.toString().toLowerCase();
        return isPlayoff && round == 'semifinal';
      }).length;
    }

    // Verificar que NO haya finals ya generadas
    final hasFinals = _nextGames.any((g) =>
            (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
            (g['playoff_round'] == 'gold' ||
                g['playoff_round'] == 'bronze' ||
                g['playoff_round'] == 'final')) ||
        _completedGames.any((g) =>
            (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
            (g['playoff_round'] == 'gold' ||
                g['playoff_round'] == 'bronze' ||
                g['playoff_round'] == 'final'));

    final requiredGames = isSpecialP8 ? 1 : 2; // 1 Qualifier o 2 Semifinales

    return qualifyingGamesCompleted == requiredGames && !hasFinals;
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
    // ✅ NO MOSTRAR si es espectador
    if (isReallySpectator) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FrutiaColors.ModeratorTea,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FrutiaColors.ModeratorTea,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline,
                  color: FrutiaColors.ElectricLime, size: 28),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start Final games based on semifinal results',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showStartFinalsConfirmation(),
            icon:
                Icon(Icons.emoji_events, color: FrutiaColors.primary, size: 20),
            label: Text(
              'Generate Finals',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.ElectricLime,
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
                color: FrutiaColors.LighterNavy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: FrutiaColors.LighterNavy,
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
                          color: FrutiaColors.LighterNavy.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.LighterNavy,
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
                          color: FrutiaColors.ElectricLime,
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
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
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
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// ✅ NUEVO MÉTODO: Construir el score para juegos completados
  Widget _buildCompletedScore(Map<String, dynamic> game) {
    final isBestOf3 = _sessionData?['number_of_sets'] == '3';

    if (!isBestOf3) {
      // Best of 1: Mostrar score total normal
      return Text(
        '${game['team1_score']} - ${game['team2_score']}',
        style: GoogleFonts.robotoMono(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: FrutiaColors.primary,
        ),
      );
    }

    // ✅ BEST OF 3: Mostrar cada set por separado
    final set1Team1 = game['team1_set1_score'];
    final set1Team2 = game['team2_set1_score'];
    final set2Team1 = game['team1_set2_score'];
    final set2Team2 = game['team2_set2_score'];
    final set3Team1 = game['team1_set3_score'];
    final set3Team2 = game['team2_set3_score'];

    return Column(
      children: [
        // Badge "Best of 3"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: FrutiaColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Best of 3',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Set 1
        if (set1Team1 != null && set1Team2 != null)
          Text(
            '$set1Team1 - $set1Team2',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primary,
            ),
          ),

        // Set 2
        if (set2Team1 != null && set2Team2 != null) ...[
          const SizedBox(height: 2),
          Text(
            '$set2Team1 - $set2Team2',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primary,
            ),
          ),
        ],

        // Set 3 (solo si existe)
        if (set3Team1 != null && set3Team2 != null) ...[
          const SizedBox(height: 2),
          Text(
            '$set3Team1 - $set3Team2',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FrutiaColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _finalizeSimpleSession() async {
    // Mostrar diálogo de confirmación

    if (isModerator && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Only the Session Owner can finalize the session',
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: FrutiaColors.primary,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: FrutiaColors.ElectricLime,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.flag, color: FrutiaColors.accent, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Finalize Session',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'All games are complete! Ready to finalize this session and see final rankings?',
          style: GoogleFonts.lato(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Finalize',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✅ Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Finalizing session...',
                style: GoogleFonts.lato(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Llamar al endpoint de finalización
      await SessionService.finalizeSession(widget.sessionId);

      if (!mounted) return;

      // Recargar datos de la sesión
      await _loadSessionData();

      if (!mounted) return;

      // ✅ Solo cerrar el loading, nada más
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error finalizing session: $e',
            style: TextStyle(
                color: FrutiaColors.primary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: FrutiaColors.ElectricLime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAdvanceStageButton() {
    // ✅ NO MOSTRAR si es espectador
    if (isReallySpectator) {
      return const SizedBox.shrink();
    }

    // ✅✅✅ NUEVO: AGREGAR ESTO AL INICIO ✅✅✅
    final sessionType = _sessionData?['session_type'];

// ✅ NUEVA CONDICIÓN: Ocultar si estamos esperando generar las Finals en P8 especial
    if (sessionType == 'P8' && _shouldShowStartFinalsButton()) {
      print(
          '[DEBUG] ❌ Ocultando Advance to Playoffs: Ya se debe generar Finals (P8 especial)');
      return const SizedBox.shrink();
    }

    // ✅ MODO SIMPLE: Mostrar botón/mensaje "Finalize" cuando no hay juegos pendientes
    if (sessionType == 'S') {
      final totalPendingActive = _liveGames.length + _nextGames.length;

      print('🔍 Simple Mode Check:');
      print('   - Session Type: $sessionType');
      print('   - Live games: ${_liveGames.length}');
      print('   - Next games: ${_nextGames.length}');
      print('   - Total pending/active: $totalPendingActive');
      print('   - Is Moderator: $isModerator');
      print('   - Is Owner: $isOwner');

      if (totalPendingActive == 0) {
        // ✅ SI ES MODERADOR (pero NO owner): Mostrar mensaje informativo
        if (isModerator && !isOwner) {
          print('   ⚠️  MODERATOR cannot finalize - showing info message');

          return Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FrutiaColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FrutiaColors.warning.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: FrutiaColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Complete',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All games are complete. Only the Session Owner can finalize the session and see final results.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: FrutiaColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ✅ SI ES OWNER O NO ES MODERADOR: Mostrar botón de finalizar
        print('   ✅ SHOWING FINALIZE BUTTON for Simple mode');

        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16),
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
                  Icon(Icons.emoji_events,
                      color: FrutiaColors.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Complete!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All games are complete! Ready to finalize and see final rankings?',
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _finalizeSimpleSession,
                icon: Icon(Icons.flag, color: Colors.white, size: 20),
                label: Text(
                  'Finalize Session',
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

      // Si aún hay juegos pendientes, no mostrar nada
      print('   ❌ Not showing button: Still has pending games');
      return SizedBox.shrink();
    }

    final currentStage = _sessionData?['current_stage'] ?? 1;
    final status = _sessionData?['status'];

    // ✅ LÓGICA PARA MODERADORES: Verificar si hay juegos pendientes
    bool isButtonEnabled = true;
    int pendingGamesCount = 0;
    String disabledReason = '';

    if (isModerator && !isOwner) {
      // Contar juegos pendientes (Live + Next)
      pendingGamesCount = _liveGames.length + _nextGames.length;

      // Solo habilitar si NO hay juegos pendientes
      isButtonEnabled = pendingGamesCount == 0;

      if (!isButtonEnabled) {
        disabledReason =
            'All pending games (${pendingGamesCount} must be completed to advance to the next phase.';
      }

      print('========== MODERATOR ADVANCE BUTTON CHECK ==========');
      print('[DEBUG] Is Moderator: $isModerator');
      print('[DEBUG] Is Owner: $isOwner');
      print('[DEBUG] Live games: ${_liveGames.length}');
      print('[DEBUG] Next games: ${_nextGames.length}');
      print('[DEBUG] Total pending: $pendingGamesCount');
      print('[DEBUG] Button enabled: $isButtonEnabled');
      print('===================================================');
    }

    // ✅ NUEVO: No mostrar para P4/P8 si hay semifinals completadas
    if (sessionType == 'P4' || sessionType == 'P8') {
      final completedSemifinals = _completedGames
          .where((g) =>
              (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
              g['playoff_round'] == 'semifinal' &&
              g['status'] == 'completed')
          .length;

      if (completedSemifinals > 0) {
        print(
            '[DEBUG] ❌ Not showing button: Semifinals already completed (auto-generation handled)');
        return const SizedBox.shrink();
      }
    }

    // ✅ DEBUGGING MEJORADO
    print('========== DEBUG ADVANCE BUTTON ==========');
    print('[DEBUG] Session Type: $sessionType');
    print('[DEBUG] Current Stage: $currentStage');
    print('[DEBUG] Status: $status');
    print('[DEBUG] Live games: ${_liveGames.length}');
    print('[DEBUG] Next games: ${_nextGames.length}');

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

    // ✅ PARA TOURNAMENT (T) - LÓGICA MEJORADA
    if (sessionType == 'T') {
      if (currentStage >= 3) {
        print('[DEBUG] ❌ Not showing: Already in stage 3');
        return const SizedBox.shrink();
      }

      final hasPendingGames = _nextGames.isNotEmpty;

      print('[DEBUG] Tournament Stage $currentStage:');
      print('[DEBUG] - Pending games in Next: $hasPendingGames');
      print('[DEBUG] - Live games: ${_liveGames.length}');

      print('[DEBUG] ✅ SHOWING BUTTON: Advance to Stage ${currentStage + 1}');

      String buttonText = 'Advance to Stage ${currentStage + 1}';
      String description =
          'Generate Stage ${currentStage + 1} matches based on Stage $currentStage results';

      // ✅ AGREGAR ADVERTENCIA en la descripción si hay juegos pendientes
      if (hasPendingGames) {
        description =
            '${_nextGames.length} pending games will be skipped. Generate Stage ${currentStage + 1} matches based on current rankings.';
      }

      // ✅ PARA MODERADORES: Agregar mensaje de juegos pendientes
      if (isModerator && !isOwner && !isButtonEnabled) {
        description = disabledReason;
      }

      return Container(
        margin: const EdgeInsets.only(left: 16, right: 16),
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
                          color: !isButtonEnabled
                              ? FrutiaColors.error
                              : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isModerator && !isOwner && !isButtonEnabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FrutiaColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: FrutiaColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: FrutiaColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To end this phase early, please contact the Session Owner.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: FrutiaColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              // ✅ DESHABILITAR BOTÓN PARA MODERADORES SI HAY JUEGOS PENDIENTES
              onPressed: isButtonEnabled
                  ? () => _showAdvanceStageConfirmation()
                  : null,
              icon: Icon(Icons.flag,
                  color: isButtonEnabled ? Colors.white : Colors.grey[400],
                  size: 20),
              label: Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isButtonEnabled ? Colors.white : Colors.grey[400],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isButtonEnabled ? FrutiaColors.primary : Colors.grey[300],
                foregroundColor:
                    isButtonEnabled ? Colors.white : Colors.grey[400],
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isButtonEnabled ? 2 : 0,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ PARA OPTIMIZED (O) - LÓGICA SIMILAR
    if (sessionType == 'O') {
      // Para Optimized, mostrar botón cuando no hay más juegos pendientes
      if (_nextGames.isNotEmpty || _liveGames.isNotEmpty) {
        print('[DEBUG] ❌ Not showing Optimized: Has pending/live games');
        return const SizedBox.shrink();
      }

      print('[DEBUG] ✅ SHOWING BUTTON: Generate More Games (Optimized)');

      return Container(
        margin: const EdgeInsets.only(left: 16, right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FrutiaColors.nutrition.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FrutiaColors.nutrition,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.autorenew, color: FrutiaColors.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate More Games?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create additional matches based on current rankings',
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
              onPressed: isButtonEnabled
                  ? () => _showAdvanceStageConfirmation()
                  : null,
              icon: Icon(Icons.autorenew,
                  color: isButtonEnabled ? Colors.white : Colors.grey[400],
                  size: 20),
              label: Text(
                'Generate Games',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isButtonEnabled ? Colors.white : Colors.grey[400],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isButtonEnabled ? FrutiaColors.primary : Colors.grey[300],
                foregroundColor:
                    isButtonEnabled ? Colors.white : Colors.grey[400],
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isButtonEnabled ? 2 : 0,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ LÓGICA EXISTENTE PARA P4 y P8
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
      description = 'Generate Playoff bracket based on current rankings';
      buttonIcon = Icons.emoji_events;

      if (_nextGames.isNotEmpty) {
        description =
            'This will clear all pending games (${_nextGames.length}) and generate the Playoffs bracket';
      }

      // ✅ PARA MODERADORES: Agregar mensaje de juegos pendientes
      if (isModerator && !isOwner && !isButtonEnabled) {
        description = disabledReason;
      }
    }

    if (buttonText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.only(right: 20, left: 20, bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: FrutiaColors.ModeratorTea,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FrutiaColors.ModeratorTea,
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
              Icon(Icons.help_outline,
                  color: FrutiaColors.ElectricLime, size: 24),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: !isButtonEnabled
                            ? FrutiaColors.error
                            : Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isModerator && !isOwner && !isButtonEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FrutiaColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: FrutiaColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To end this phase early, please contact the Session Owner.',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            // ✅ DESHABILITAR BOTÓN PARA MODERADORES SI HAY JUEGOS PENDIENTES
            onPressed:
                isButtonEnabled ? () => _showAdvanceStageConfirmation() : null,
            icon: Icon(buttonIcon,
                color:
                    isButtonEnabled ? FrutiaColors.primary : Colors.grey[400],
                size: 20),
            label: Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isButtonEnabled ? FrutiaColors.primary : Colors.grey[400],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isButtonEnabled
                  ? FrutiaColors.ElectricLime
                  : Colors.grey[300],
              foregroundColor:
                  isButtonEnabled ? Colors.white : Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isButtonEnabled ? 2 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlayoffColor(String? playoffRound) {
    switch (playoffRound) {
      case 'qualifier':
        return const Color(0xFF9C27B0); // Morado un poco más fuerte
      case 'bronze':
        return const Color(0xFF8E24AA); // Morado medio
      case 'semifinal':
        return const Color(0xFFFF6B35); // Naranja (igual, ya está bien)
      case 'gold':
      case 'final':
        return const Color(0xFFFFC400); // Amarillo más vibrante
      default:
        return FrutiaColors.accent;
    }
  }

  List<Color> _getPlayoffGradient(String? playoffRound) {
    switch (playoffRound) {
      case 'qualifier':
        return [
          const Color(0xFF9C27B0), // Morado
          const Color(0xFFBA68C8), // Morado claro
        ];
      case 'bronze':
        return [
          const Color(0xFF8E24AA), // Morado medio
          const Color(0xFFCE93D8), // Morado claro
        ];
      case 'semifinal':
        return [
          const Color(0xFFFF6B35),
          const Color(0xFFFF8C42),
        ];
      case 'gold':
      case 'final':
        return [
          const Color(0xFFFFC400), // Amarillo más vibrante
          const Color(0xFFFFF176), // Amarillo claro
        ];
      default:
        return [FrutiaColors.accent, FrutiaColors.accent.withOpacity(0.8)];
    }
  }

  IconData _getPlayoffIcon(String? playoffRound) {
    switch (playoffRound) {
      case 'qualifier':
        return Icons.play_arrow; // Icono para qualifier
      case 'bronze':
        return Icons.workspace_premium; // Icono para bronze
      case 'semifinal':
        return Icons.stars;
      case 'gold':
      case 'final':
        return Icons.emoji_events;
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
          'Ready for the finale? This action uses the current ranking to create the Playoffs bracket. It cannot be undone.';
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
                          color: FrutiaColors.ElectricLime.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.ElectricLime,
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
                            color: FrutiaColors.primary),
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
    if (game['is_playoff_game'] != 1 && game['is_playoff_game'] != true) {
      return null;
    }

    final playoffRound = game['playoff_round'];

    // ✅ NUEVO: Manejar "qualifier"
    if (playoffRound == 'qualifier') {
      return 'Qualifier / Bronze';
    }

    if (playoffRound == 'semifinal') {
      final gameNumber = game['game_number'];
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
    if (playoffRound == 'final') return 'Final'; // ✅ Para P8 especial

    return playoffRound?.toUpperCase();
  }

  Future<void> _shareSessionResults() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FrutiaColors.primary.withOpacity(0.03),
                FrutiaColors.primary.withOpacity(0.01),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO CON GRADIENTE E ICONO
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FrutiaColors.primary,
                          FrutiaColors.primary.withOpacity(0.7)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: FrutiaColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.share, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Share Session Results',
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to share the final results from the options below:',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: FrutiaColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // OPCIÓN 1: IMAGEN
              _buildShareOption(
                icon: Icons.photo_camera,
                iconColor: FrutiaColors.success,
                iconBgGradient: [
                  FrutiaColors.success.withOpacity(0.2),
                  FrutiaColors.success.withOpacity(0.1)
                ],
                title: 'Share as Image',
                subtitle: 'Perfect for Social Media',
                onTap: () => Navigator.pop(context, 'image'),
                borderColor: FrutiaColors.success.withOpacity(0.4),
                backgroundColor: FrutiaColors.success.withOpacity(0.08),
              ),
              const SizedBox(height: 14),

              // OPCIÓN 2: TEXTO
              _buildShareOption(
                icon: Icons.text_fields,
                iconColor: FrutiaColors.primary,
                iconBgGradient: [
                  FrutiaColors.primary.withOpacity(0.15),
                  FrutiaColors.primary.withOpacity(0.05)
                ],
                title: 'Share as Text',
                subtitle: 'Copy results to clipboard',
                onTap: () => Navigator.pop(context, 'text'),
                borderColor: FrutiaColors.primary.withOpacity(0.3),
                backgroundColor: FrutiaColors.primary.withOpacity(0.05),
              ),
              const SizedBox(height: 28),

              // BOTÓN CANCELAR
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: FrutiaColors.disabledText.withOpacity(0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor:
                        FrutiaColors.tertiaryBackground.withOpacity(0.5),
                  ),
                  child: Text(
                    'Exit',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    // === Loading + Lógica ===
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
                  strokeWidth: 5,
                ),
                const SizedBox(height: 18),
                Text(
                  choice == 'image'
                      ? 'Generating Image...'
                      : 'Preparing Text...',
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

      if (choice == 'image') {
        final sessionType = _sessionData!['session_type'] ?? 'O';
        final sessionDataWithDuration = {
          ..._sessionData!,
          'elapsed_seconds': _elapsedSeconds,
        };

        // ✅ CORREGIDO: Preparar playoffWinners con el formato correcto
        List<dynamic>? playoffWinners;

        if (sessionType == 'P4' || sessionType == 'P8') {
          final playoffResults = _getPlayoffWinners(sessionType);

          print('');
          print('📸 Preparando datos para imagen:');
          print('   Session Type: $sessionType');
          print('   Champions: ${playoffResults['champions']}');
          print('   Runners-up: ${playoffResults['runners_up']}');
          print('   Third Place: ${playoffResults['third_place']}');

          // ✅ NUEVO: Convertir a formato esperado por la imagen
          playoffWinners = [];

          // 🥇 Champions
          if (playoffResults['champions'] != null) {
            playoffWinners.add(playoffResults['champions']);
          }

          // 🥈 Runners-up
          if (playoffResults['runners_up'] != null) {
            playoffWinners.add(playoffResults['runners_up']);
          }

          // 🥉 Third Place (puede ser null si P4 con 1 cancha)
          if (playoffResults['third_place'] != null) {
            playoffWinners.add(playoffResults['third_place']);
          }

          print('   Formatted playoff winners: ${playoffWinners.length} teams');
          for (var i = 0; i < playoffWinners.length; i++) {
            print('   Team $i: ${playoffWinners[i]}');
          }
          print('');
        }

        await SessionResultsImageService.generateAndShareResultsImage(
          context: context,
          sessionData: sessionDataWithDuration,
          players: _players,
          sessionType: sessionType,
          playoffWinners: playoffWinners,
        );

        if (mounted) Navigator.pop(context);
      } else if (choice == 'text') {
        final textResults = _generateTextResults();

        if (mounted) Navigator.pop(context);

        await Clipboard.setData(ClipboardData(text: textResults));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: FrutiaColors.LighterNavy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Results copied to clipboard!',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: FrutiaColors.ElectricLime,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

// ========================================
// ✅ MÉTODO OPTIMIZADO PARA TEXTO EN CELULAR
// ========================================
//
// BUSCAR en SessionControlPanel.dart:
// String _generateTextResults() {
//
// REEMPLAZAR TODO EL MÉTODO CON ESTE:
// ========================================

  // ========================================
// ✅ MÉTODO OPTIMIZADO PARA TEXTO EN CELULAR
// ========================================
//
// BUSCAR en SessionControlPanel.dart:
// String _generateTextResults() {
//
// REEMPLAZAR TODO EL MÉTODO CON ESTE:
// ========================================

  String _generateTextResults() {
    final sessionName = _sessionData?['session_name'] ?? 'Session';
    final sessionType = _sessionData?['session_type'] ?? 'O';
    final duration = _formatTimer(_elapsedSeconds);

    String getSessionTypeName(String type) {
      switch (type) {
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
          return type;
      }
    }

    String getPlayerName(Map<String, dynamic> player) {
      final firstName = player['first_name']?.toString() ?? '';
      final lastInitial = player['last_initial']?.toString() ?? '';
      if (firstName.isNotEmpty && lastInitial.isNotEmpty) {
        return '$firstName ${lastInitial}.';
      } else if (firstName.isNotEmpty) {
        return firstName;
      }
      return 'Unknown Player';
    }

    // ✅ NUEVO: Función para calcular Point Won %
    // ✅ CORREGIDO: Función para calcular Point Won %
    String getPointWonPercentage(Map<String, dynamic> player) {
      // ✅ PRIMERO: Intentar usar el porcentaje ya calculado del backend
      if (player['points_won_percentage'] != null) {
        final percentage = player['points_won_percentage'] as num;
        return '${percentage.toStringAsFixed(1)}%';
      }

      // ✅ FALLBACK: Calcular manualmente si no existe
      final pointsWon = player['points_won'] ?? 0;
      final pointsLost = player['points_lost'] ?? 0;
      final totalPoints = pointsWon + pointsLost;

      if (totalPoints == 0) return '0.0%';

      final percentage = (pointsWon / totalPoints) * 100;
      return '${percentage.toStringAsFixed(1)}%';
    }

    final buffer = StringBuffer();

    // Header bonito
    buffer.writeln('SESSION RESULTS');
    buffer.writeln('══════════════════════════');
    buffer.writeln('$sessionName');
    buffer.writeln('${getSessionTypeName(sessionType)}');
    buffer.writeln('Duration: $duration');
    buffer.writeln('══════════════════════════\n');

    // Medallas Playoffs (solo si aplica)
    if (sessionType == 'P4' || sessionType == 'P8') {
      final playoffResults = _getPlayoffWinners(sessionType);

      final champions = playoffResults['champions'] as List<dynamic>?;
      if (champions != null && champions.isNotEmpty) {
        final names = champions
            .whereType<Map<String, dynamic>>()
            .map(getPlayerName)
            .join(' & ');
        buffer.writeln('GOLD MEDAL');
        buffer.writeln('$names\n');
      }

      final runnersUp = playoffResults['runners_up'] as List<dynamic>?;
      if (runnersUp != null && runnersUp.isNotEmpty) {
        final names = runnersUp
            .whereType<Map<String, dynamic>>()
            .map(getPlayerName)
            .join(' & ');
        buffer.writeln('SILVER MEDAL');
        buffer.writeln('$names\n');
      }

      final thirdPlace = playoffResults['third_place'] as List<dynamic>?;
      if (thirdPlace != null && thirdPlace.isNotEmpty) {
        final names = thirdPlace
            .whereType<Map<String, dynamic>>()
            .map(getPlayerName)
            .join(' & ');
        buffer.writeln('BRONZE MEDAL');
        buffer.writeln('$names\n');
      }
    }

    // FINAL RANKINGS con # y alineación perfecta + Point Won %
    buffer.writeln('FINAL RANKINGS');
    buffer.writeln('──────────────────────────');

    final sortedPlayers = List<Map<String, dynamic>>.from(_players)
      ..sort((a, b) {
        final rankA = a['rank'] ?? a['current_rank'] ?? 999;
        final rankB = b['rank'] ?? b['current_rank'] ?? 999;
        return rankA.compareTo(rankB);
      });

    for (var player in sortedPlayers) {
      final rank = player['rank'] ?? player['current_rank'] ?? '-';
      final name = getPlayerName(player);
      final rating = (player['current_rating'] as num?)?.round() ?? 0;
      final wins = player['wins'] ?? player['games_won'] ?? 0;
      final losses = player['losses'] ?? player['games_lost'] ?? 0;
      final pointWonPct = getPointWonPercentage(player); // ✅ NUEVO

      // Alineación perfecta
      final rankStr = rank.toString().padLeft(2);
      final ratingStr = rating.toString().padLeft(4);

      // ✅ NUEVO: Incluir Point Won %
      buffer.writeln(
          '#$rankStr. $name - Rating $ratingStr - W:$wins | L:$losses | Pts Won: $pointWonPct');
    }

    // Footer con branding y link
    buffer.writeln('\n══════════════════════════');
    buffer.writeln('Powered by PickleBracket');
    buffer.writeln('Learn more at www.picklebracket.pro');

    return buffer.toString();
  }

  Widget _buildShareOption({
    required IconData icon,
    required Color iconColor,
    required List<Color> iconBgGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color borderColor,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono con fondo degradado
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: iconBgGradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: FrutiaColors.secondaryText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: iconColor.withOpacity(0.6),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionInfoDialog() {
    final sessionName = _sessionData?['session_name'] ?? 'Session';
    final sessionType = _sessionData?['session_type'] ?? 'Unknown';
    final numberOfCourts = _sessionData?['number_of_courts'] ?? 0;
    final numberOfPlayers = _sessionData?['number_of_players'] ?? 0;
    final progressPercentage = _sessionData?['progress_percentage'] ?? 0.0;
    final status = _sessionData?['status'] ?? 'unknown';
    final currentStage = _sessionData?['current_stage'] ?? 1;

    // ✅ CÓDIGOS
    final sessionCode = _sessionData?['session_code'] ?? 'N/A';
    final moderatorCode = _sessionData?['moderator_code'] ?? 'N/A';
    final verificationCode = _sessionData?['verification_code'] ?? 'N/A';

    final totalGames = _sessionData?['total_games'] ?? 0;
    final completedGamesCount = _completedGames.length;

    // ✅ DEBUG - Ver qué códigos tenemos
    print('');
    print('═══════════════════════════════════════');
    print('🔑 SESSION CODES DEBUG');
    print('═══════════════════════════════════════');
    print('Session Code: $sessionCode');
    print('Moderator Code: $moderatorCode');
    print('Verification Code: $verificationCode');
    print('Is Owner: $isOwner');
    print('Is Moderator: $isModerator');
    print('Is Really Spectator: $isReallySpectator');
    print('═══════════════════════════════════════');
    print('');

    // ✅ REEMPLAZA ESTA PARTE EN _showSessionInfoDialog:
    String getSessionTypeName(String type) {
      switch (type) {
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
          return type;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== HEADER ====================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FrutiaColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: FrutiaColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Info',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: FrutiaColors.primary,
                              ),
                            ),
                            Text(
                              sessionName,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: FrutiaColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // ==================== CODES SECTION (Alturas igualadas) ====================
// ==================== CODES SECTION (Alturas igualadas) ====================
                  // ==================== CODES SECTION ====================
                  IntrinsicHeight(
                    // ← Esto asegura que ambas cajas tengan LA MISMA ALTURA
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .stretch, // ← Estirar ambas al mismo tamaño
                      children: [
                        // ==================== SESSION CODE (Izquierda - MÁS ANCHO) ====================
                        Expanded(
                          flex: 3, // ← 60% del ancho
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  FrutiaColors.SpectatorGreen.withOpacity(0.2),
                                  FrutiaColors.SpectatorGreen.withOpacity(0.2)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: FrutiaColors.SpectatorGreen,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.qr_code,
                                        color: FrutiaColors.primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Session Code',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: FrutiaColors.LighterNavy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  // ← Ocupa todo el espacio vertical disponible
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          sessionCode,
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.5,
                                            color: FrutiaColors.primary,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () async {
                                            await Clipboard.setData(
                                                ClipboardData(
                                                    text: sessionCode));
                                            Fluttertoast.showToast(
                                              msg: "Session Code copied!",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              backgroundColor:
                                                  FrutiaColors.success,
                                              textColor: Colors.white,
                                              fontSize: 14.0,
                                            );
                                          },
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.copy,
                                                    color: FrutiaColors.primary,
                                                    size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Copy',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: FrutiaColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ==================== MODERATOR KEY (Derecha - MÁS ANGOSTO) ====================
                        if (isOwner)
                          Expanded(
                            flex: 2, // ← 40% del ancho
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    FrutiaColors.ModeratorTeaLight,
                                    FrutiaColors.ModeratorTeaLight
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: FrutiaColors.ModeratorTea,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.vpn_key,
                                          color: FrutiaColors.primary,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Key',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: FrutiaColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    // ← Ocupa todo el espacio vertical disponible
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            verificationCode,
                                            style: GoogleFonts.robotoMono(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 6,
                                                color: FrutiaColors.primary),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              await Clipboard.setData(
                                                  ClipboardData(
                                                      text: verificationCode));
                                              Fluttertoast.showToast(
                                                msg: "Moderator Key copied!",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                backgroundColor:
                                                    FrutiaColors.success,
                                                textColor: Colors.white,
                                                fontSize: 14.0,
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.copy,
                                                      color:
                                                          FrutiaColors.primary,
                                                      size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Copy',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: FrutiaColors
                                                            .primary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Expanded(flex: 2, child: SizedBox.shrink()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // ==================== DETAILS ====================
                  Text(
                    'Details',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow('Type',
                      getSessionTypeName(sessionType)), // ✅ NOMBRE COMPLETO
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    'Status',
                    status.toUpperCase(),
                    valueColor: status == 'completed'
                        ? FrutiaColors.success
                        : FrutiaColors.SpectatorGreen,
                  ),
                  const SizedBox(height: 8),

                  if (sessionType == 'T') ...[
                    _buildInfoRow('Current Stage', 'Stage $currentStage'),
                    const SizedBox(height: 8),
                  ],

                  _buildInfoRow('Courts', numberOfCourts.toString()),
                  const SizedBox(height: 8),

                  _buildInfoRow('Players', numberOfPlayers.toString()),
                  const SizedBox(height: 8),

                  _buildInfoRow('Duration', _formatTimer(_elapsedSeconds)),

                  const SizedBox(height: 30),

                  // ==================== PROGRESS ====================
                  Text(
                    'Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progressPercentage.toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: progressPercentage >= 100
                              ? FrutiaColors.success
                              : FrutiaColors.ModeratorTea,
                        ),
                      ),
                      Text(
                        '$completedGamesCount / $totalGames games',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: FrutiaColors.tertiaryBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercentage >= 100
                            ? FrutiaColors.success
                            : FrutiaColors.ModeratorTea,
                      ),
                      minHeight: 10,
                    ),
                  ),

                  // ==================== FINALIZE BUTTON (Solo dueño + sesión activa) ====================
                  if (status != 'completed') ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),

                    // ✅ VALIDACIÓN: Solo el OWNER puede finalizar (no moderadores)
                    if (isOwner && !isModerator)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showFinalizeConfirmation(fromInfoDialog: true);
                          },
                          icon: Icon(Icons.flag, size: 16, color: Colors.red),
                          label: Text(
                            'Finalize Session',
                            style: GoogleFonts.poppins(
                              color: FrutiaColors.SignalRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(
                              color: FrutiaColors.error,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    // ✅ NUEVO: Mensaje para moderadores
                    else if (isModerator && !isOwner)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FrutiaColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: FrutiaColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: FrutiaColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Only the Session Owner can finalize the session',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: FrutiaColors.secondaryText,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),

                  // ==================== CLOSE BUTTON ====================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// ==================== WIDGET AUXILIAR: _buildCodeRow ====================
  Widget _buildCodeRow(String code, Color color, {bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            code,
            style: GoogleFonts.robotoMono(
              fontSize: isSmall ? 20 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: isSmall ? 4 : 6,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              Fluttertoast.showToast(
                msg: "Code copied!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: FrutiaColors.success,
                textColor: Colors.white,
                fontSize: 14.0,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.copy,
                color: color,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ NUEVO WIDGET: Fila de código con botón de copiar
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
              fontSize: 14,
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
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

// Método para mostrar confirmación de finalización (ya existe, pero lo mejoramos)
  Future<void> _showFinalizeConfirmation({bool fromInfoDialog = false}) async {
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
              'You will NOT be able to resume play or edit scores. This cannot be undone',
              style: GoogleFonts.lato(
                color: FrutiaColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: FrutiaColors.secondaryText.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 13,
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Finalize Session',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

    if (confirm == true) {
      await _executeFinalizeSession(
        fromInfoDialog: fromInfoDialog,
      );
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
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: FrutiaColors.primary, // Navy
                ),
                const SizedBox(width: 10),
                Text(
                  sessionType == 'T'
                      ? 'Advanced to next stage\nsuccessfully!'
                      : 'Playoff bracket generated\nsuccessfully!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: FrutiaColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: FrutiaColors.ElectricLime,
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
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
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
                          : (playoffCutoff > 0 && rank <= playoffCutoff)
                              ? FrutiaColors.success.withOpacity(0.2)
                              : FrutiaColors.secondaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3
                              ? Colors.white
                              : (playoffCutoff > 0 && rank <= playoffCutoff)
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
                      _truncateName(_formatPlayerName(player)),
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
    // ✅ NO MOSTRAR si es espectador
    if (isReallySpectator) {
      return const SizedBox.shrink();
    }

    // ✅ NUEVO: NO MOSTRAR si es moderador (pero no owner)
    if (isModerator && !isOwner) {
      return Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FrutiaColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FrutiaColors.warning.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: FrutiaColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Complete',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All games are complete. Only the Session Owner can finalize the session and see final results.',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: FrutiaColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ MOSTRAR BOTÓN SOLO PARA EL OWNER
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FrutiaColors.ModeratorTea,
            FrutiaColors.ModeratorTea,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FrutiaColors.ModeratorTea.withOpacity(0.3),
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
                  color: FrutiaColors.ElectricLime,
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
                Icon(Icons.check_circle, color: FrutiaColors.primary, size: 22),
            label: Text(
              'Finalize Session & See Results',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FrutiaColors.primary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.ElectricLime,
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

  Future<void> _executeFinalizeSession({bool fromInfoDialog = false}) async {
    try {
      // ✅ SETEAR LA BANDERA ESPECÍFICA SEGÚN EL ORIGEN
      if (fromInfoDialog) {
        _isFinalizingFromInfoDialog = true;
      } else {
        _isManualFinalization = true; // Para el botón de Next tab
      }

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

      // ✅ ACTUALIZAR EL ESTADO DE LA SESIÓN
      if (mounted) {
        setState(() {
          _sessionData = {
            ..._sessionData!,
            'status': 'completed',
            'podium_data': result['podium'],
          };
        });
      }

      // ✅ CONDICIÓN: Modal simple SOLO para finalización desde Info Dialog
      if (fromInfoDialog && mounted) {
        await _showSimpleSessionCompletedDialog();
      }
      // ✅ Para finalización desde el botón en Next tab, MOSTRAR PODIO
      else if (!fromInfoDialog && mounted) {
        // await _showPodiumDialog(result['podium']); // ← AGREGAR ESTA LÍNEA
      }

      // Recargar datos completos
      await _loadSessionData();

      // ✅ RESETEAR las banderas después de un tiempo
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isFinalizingFromInfoDialog = false;
            _isManualFinalization = false;
          });
        }
      });
    } catch (e) {
      // ✅ RESETEAR las banderas en caso de error
      _isFinalizingFromInfoDialog = false;
      _isManualFinalization = false;

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      print('[SessionControlPanel] Error finalizing session: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

// ✅ NUEVO MÉTODO: Modal simple para finalización MANUAL

  Future<void> _showSimpleSessionCompletedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: EdgeInsets.zero, // ← Para controlar padding manualmente
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header elegante (igual estilo que Final Results)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FrutiaColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: FrutiaColors.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: FrutiaColors.LighterNavy,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Completed!',
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: FrutiaColors.LighterNavy, // Navy
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The session has been successfully finalized.',
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
                const SizedBox(height: 28),
                // Botón Close centrado y bonito
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrutiaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: FrutiaColors.primary.withOpacity(0.3),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ✅ NUEVO MÉTODO: Mostrar podio para P8 especial
  Future<void> _showSpecialP8PodiumDialog() async {
    // Encontrar el juego "final"
    final finalGame = _completedGames.firstWhere(
      (g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          g['playoff_round'] == 'final',
      orElse: () => null,
    );

    // Encontrar el juego "qualifier"
    final qualifierGame = _completedGames.firstWhere(
      (g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          g['playoff_round'] == 'qualifier',
      orElse: () => null,
    );

    if (finalGame == null || qualifierGame == null) {
      print('❌ No se encontraron los juegos necesarios para el podio');
      // Fallback: mostrar podio simple
      // await _showPodiumDialog({});
      return;
    }

    // Determinar ganadores y perdedores
    final finalWinnerTeam = finalGame['winner_team'] ?? 0;
    final qualifierWinnerTeam = qualifierGame['winner_team'] ?? 0;

    // 🥇 Ganadores del Final (Champions)
    List champions = [];
    if (finalWinnerTeam == 1) {
      champions = [
        finalGame['team1_player1'],
        finalGame['team1_player2'],
      ];
    } else {
      champions = [
        finalGame['team2_player1'],
        finalGame['team2_player2'],
      ];
    }

    // 🥈 Perdedores del Final (Runners-up)
    List runnersUp = [];
    if (finalWinnerTeam == 1) {
      runnersUp = [
        finalGame['team2_player1'],
        finalGame['team2_player2'],
      ];
    } else {
      runnersUp = [
        finalGame['team1_player1'],
        finalGame['team1_player2'],
      ];
    }

    // 🥉 Perdedores del Qualifier (Third Place)
    List thirdPlace = [];
    if (qualifierWinnerTeam == 1) {
      thirdPlace = [
        qualifierGame['team2_player1'],
        qualifierGame['team2_player2'],
      ];
    } else {
      thirdPlace = [
        qualifierGame['team1_player1'],
        qualifierGame['team1_player2'],
      ];
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 360, maxHeight: 550),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
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
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Complete',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: FrutiaColors.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Congratulations \nto the winners!',
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
                const SizedBox(height: 16),

                // 🥇 Champions
                _buildPodiumTeamCard(
                  emoji: '🥇',
                  title: 'Champions',
                  color: const Color(0xFFFFD700),
                  players: champions,
                ),
                const SizedBox(height: 12),

                // 🥈 Runners-up
                _buildPodiumTeamCard(
                  emoji: '🥈',
                  title: 'Runners-up',
                  color: const Color(0xFFC0C0C0),
                  players: runnersUp,
                ),
                const SizedBox(height: 12),

                // 🥉 Third Place
                _buildPodiumTeamCard(
                  emoji: '🥉',
                  title: 'Third Place',
                  color: const Color(0xFFCD7F32),
                  players: thirdPlace,
                ),

                const SizedBox(height: 16),

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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                            color: FrutiaColors.primary.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'View Rankings',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
      ),
    );
  }

// ✅ NUEVO WIDGET: Tarjeta de equipo para el podio
  Widget _buildPodiumTeamCard({
    required String emoji,
    required String title,
    required Color color,
    required List players,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Players
          ...players.map((player) {
            if (player == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatPlayerName(player),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _showPodiumDialog(Map<String, dynamic> podiumData) async {
    print('🎯 SHOWING PODIUM DIALOG');
    print('   - Podium type: ${podiumData['type']}');
    print('   - Is Special P8: ${_isSpecialP8()}');

    final sessionType = _sessionData?['session_type'];

    // ✅ PARA P8 ESPECIAL: Mostrar podio basado en la Final
    if (_isSpecialP8() && sessionType == 'P8') {
      //    await _showSpecialP8PodiumDialog();
      return;
    }

    // ✅ PARA P4, P8 NORMAL, etc. - Lógica existente
    final topPlayers = _players.take(3).toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 360, maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
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
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Congratulations \nto the winners!',
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
              const SizedBox(height: 16),

              // Top 3 del ranking
              _buildTopPlayersFromRanking(topPlayers),

              const SizedBox(height: 16),

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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: FrutiaColors.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Rankings',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
          playerName = _formatPlayerName(player);

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

// ✅ NUEVO MÉTODO: Detectar si es P8 especial (1C2H6P o 1C2H7P)
  bool _isSpecialP8() {
    if (_sessionData == null) return false;

    final sessionType = _sessionData!['session_type'];
    final numberOfCourts = _sessionData!['number_of_courts'] ?? 0;
    final durationHours = _sessionData!['duration_hours'] ?? 0;
    final numberOfPlayers = _sessionData!['number_of_players'] ?? 0;

    if (sessionType != 'P8') return false;

    // Verificar si es 1C2H6P o 1C2H7P
    return (numberOfCourts == 1 &&
        durationHours == 2 &&
        (numberOfPlayers == 6 || numberOfPlayers == 7));
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
                            _formatPlayerName(player),
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
                              _formatPlayerName(player),
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

    // ✅ PARA TOURNAMENT
    if (sessionType == 'T') {
      final currentStage = _sessionData!['current_stage'] ?? 1;

      if (currentStage == 3) {
        return _nextGames.isEmpty &&
            _liveGames.isEmpty &&
            _completedGames.isNotEmpty;
      }

      return false;
    }

    // ✅ PARA P8 ESPECIAL: Solo verificar que la Final esté completada
    if (sessionType == 'P8' && _isSpecialP8()) {
      final finalCompleted = _completedGames.any((g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          g['playoff_round'] == 'final');

      return finalCompleted && _liveGames.isEmpty;
    }

    // ✅ PARA P8 NORMAL: Final Y Bronze completados
    if (sessionType == 'P8') {
      final goldCompleted = _completedGames.any((g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          g['playoff_round'] == 'gold');

      final bronzeCompleted = _completedGames.any((g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          g['playoff_round'] == 'bronze');

      return goldCompleted && bronzeCompleted && _liveGames.isEmpty;
    }

    // ✅ PARA P4: CORREGIDO - Detectar si tiene Bronze o solo Final
    if (sessionType == 'P4') {
      final numberOfCourts = _sessionData!['number_of_courts'] ?? 0;

      // ✅ Buscar Final/Gold
      final finalCompleted = _completedGames.any((g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          (g['playoff_round'] == 'final' || g['playoff_round'] == 'gold'));

      print('🔍 P4 Finalize Check:');
      print('   - Courts: $numberOfCourts');
      print('   - Final/Gold completed: $finalCompleted');

      // ✅ SI SOLO 1 CANCHA: Solo verificar Final
      if (numberOfCourts == 1) {
        final shouldFinalize = finalCompleted && _liveGames.isEmpty;
        print('   - 1C Mode: Should finalize = $shouldFinalize');
        return shouldFinalize;
      }

      // ✅ SI 2+ CANCHAS: Verificar Final + Bronze
      final bronzeCompleted = _completedGames.any((g) =>
          (g['is_playoff_game'] == 1 || g['is_playoff_game'] == true) &&
          g['playoff_round'] == 'bronze');

      print('   - Bronze completed: $bronzeCompleted');

      final shouldFinalize =
          finalCompleted && bronzeCompleted && _liveGames.isEmpty;
      print('   - 2+C Mode: Should finalize = $shouldFinalize');

      return shouldFinalize;
    }

    // ✅ PARA OPTIMIZED: Todos los juegos completados
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
      // ✅ CAMBIO: Usar FrutiaColors.primary en lugar de accent
      return FrutiaColors.LighterLime;
    }

    final playoffRound = game['playoff_round']?.toString().toLowerCase();

    switch (playoffRound) {
      case 'gold':
      case 'final':
        return const Color(0xFFFFF59D).withOpacity(0.7); // Amarillo más visible
      case 'bronze':
      case 'qualifier':
        return const Color(0xFFE1BEE7).withOpacity(0.7); // Morado más visible
      case 'semifinal':
        return const Color(0xFFFFCCBC).withOpacity(0.7); // Naranja más visible
      default:
        // ✅ CAMBIO: Usar FrutiaColors.primary en lugar de accent
        return FrutiaColors.primary.withOpacity(0.15);
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
    //final showStartGameButton = isPending && hasCourtAssigned && isCourtAvailable && shouldShowStartGame && !widget.isSpectator;

    final showStartGameButton = shouldShowStartGame;

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
                      ? FrutiaColors.ElectricLime.withOpacity(0.2)
                      : FrutiaColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showStartGameButton
                        ? FrutiaColors.ElectricLime
                        : Colors.grey,
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
                                ? FrutiaColors.primary
                                : Colors.grey),
                      ),
                      Text(
                        queuePosition.toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: showStartGameButton
                                ? FrutiaColors.primary
                                : Colors.grey),
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
                      ? FrutiaColors.LighterNavy
                      : (isPlayoffGame && isCompleted)
                          ? FrutiaColors.accent.withOpacity(0.05)
                          : (showStartGameButton)
                              ? FrutiaColors.ElectricLime.withOpacity(0.13)
                              : FrutiaColors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive
                        ? FrutiaColors.LighterNavy
                        : (isPlayoffGame && isCompleted)
                            ? _getPlayoffColor(game[
                                'playoff_round']) // ← USAR EL MÉTODO EXISTENTE
                            : (showStartGameButton)
                                ? FrutiaColors.ElectricLime
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
                                    color: isLive
                                        ? Colors.white
                                        : FrutiaColors.primary,
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
                                  !shouldShowStartGame && // ← CAMBIO CLAVE: Si NO tiene "Start Game", muestra "Skip"
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
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        title: Row(
                                          children: [
                                            Icon(Icons.warning,
                                                color: FrutiaColors.error,
                                                size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Edit Completed Game?',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: FrutiaColors.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'This action will recalculate ALL player rankings based on the updated score.',
                                              style: GoogleFonts.lato(
                                                color: FrutiaColors.primaryText,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                        actions: [
                                          // Botón: Cancelar (con borde)
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: FrutiaColors
                                                      .secondaryText
                                                      .withOpacity(0.5)),
                                            ),
                                            child: TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              child: Text(
                                                'Cancel',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Botón: Continuar (elevado con sombra roja)
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: FrutiaColors.error
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    FrutiaColors.error,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              child: Text(
                                                'Edit Score',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
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
                                          onScoreSubmitted: _loadSessionData,
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
                              if (isLive && !widget.isSpectator) ...[
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        contentPadding:
                                            const EdgeInsets.all(24),
                                        content: SizedBox(
                                          width: 380,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Icon
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: FrutiaColors.error
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.cancel_outlined,
                                                  color: FrutiaColors.error,
                                                  size: 48,
                                                ),
                                              ),
                                              const SizedBox(height: 20),

                                              // Title
                                              Text(
                                                'Cancel Game?',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      FrutiaColors.primaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 12),

                                              // Message
                                              Text.rich(
                                                textAlign: TextAlign.center,
                                                TextSpan(
                                                  style: GoogleFonts.lato(
                                                    fontSize: 15,
                                                    color: FrutiaColors
                                                        .secondaryText,
                                                    height: 1.5,
                                                  ),
                                                  children: const [
                                                    TextSpan(
                                                        text:
                                                            'Are you sure you want to cancel this game?\n'),
                                                    TextSpan(
                                                        text:
                                                            'This action will move the game back to the list of pending matches '),
                                                    TextSpan(
                                                      text: '\n(\'Next\' tab)',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: FrutiaColors
                                                            .primaryText, // ← negro o color principal (más oscuro y visible)
                                                      ),
                                                    ),
                                                    TextSpan(text: '.'),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 28),

                                              // Buttons
                                              Row(
                                                children: [
                                                  // Don't cancel button (Ghost style)
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                        side: BorderSide(
                                                          color: FrutiaColors
                                                              .primaryText
                                                              .withOpacity(0.3),
                                                          width: 1.5,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        "Don't cancel",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: FrutiaColors
                                                              .primaryText,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),

                                                  // Cancel button (Red with shadow)
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: FrutiaColors
                                                                .error
                                                                .withOpacity(
                                                                    0.4),
                                                            blurRadius: 12,
                                                            offset:
                                                                const Offset(
                                                                    0, 6),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              FrutiaColors
                                                                  .error,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        child: Text(
                                                          'Cancel Game',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w700,
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
                                                'Game moved back to the queue',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        FrutiaColors.primary),
                                              ),
                                              backgroundColor:
                                                  FrutiaColors.ElectricLime,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                                style: TextStyle(
                                                    color: FrutiaColors.primary,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              backgroundColor:
                                                  FrutiaColors.ElectricLime,
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                    _formatPlayerName(team1Player1),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isLive
                                          ? Colors.white
                                          : FrutiaColors.primary,
                                    ),
                                  ),
                                  Text(
                                    _formatPlayerName(team1Player2),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isLive
                                          ? Colors.white
                                          : FrutiaColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Score or VS
                          // Busca el método _buildGameCard y reemplaza la sección de Score (aproximadamente línea 2150)

// Dentro de _buildGameCard, reemplaza esta parte:
// Score or VS
                          const SizedBox(width: 12),
                          // Score or VS
                          if (isCompleted)
                            _buildCompletedScore(game)
                          else
                            Text(
                              'VS',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey),
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
                                    _formatPlayerName(team2Player1),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isLive
                                          ? Colors.white
                                          : FrutiaColors.primary,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    _formatPlayerName(team2Player2),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isLive
                                          ? Colors.white
                                          : FrutiaColors.primary,
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
                      if (!isReallySpectator) ...[
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
                                backgroundColor: FrutiaColors.ElectricLime,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Record Result',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: FrutiaColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (showStartGameButton) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _startGame(game),
                              label: Text(
                                'Start Game',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: FrutiaColors.ElectricLime,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FrutiaColors.primary,
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

  Future<void> _showSkipLineConfirmation(Map<String, dynamic> game) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.fast_forward, color: FrutiaColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Skip the Line?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This game will skip the queue and be moved to the "Live" tab',
              style: GoogleFonts.lato(
                color: FrutiaColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Other games will be postponed accordingly.',
              style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              // Botón: Cancelar
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: FrutiaColors.secondaryText.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón: Confirmar (elevado con sombra)
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
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrutiaColors.ElectricLime,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Skip the Line',
                      style: GoogleFonts.poppins(
                        color: FrutiaColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
              style: TextStyle(
                  fontSize: 17,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold), // ← Agregué fontSize
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().contains('No courts available')
                        ? 'No courts available. Complete live games first.'
                        : 'Error: ${e.toString()}',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: FrutiaColors.error,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating, // Add floating behavior
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
      // ✅ PASO 1: Iniciar el juego en el backend
      await GameService.startGame(game['id']);

      // ✅ PASO 2: RECARGAR DATOS COMPLETOS (mientras el loading está visible)
      await _loadSessionData();

      // ✅ PASO 3: IR A LA PESTAÑA LIVE
      if (mounted) {
        _tabController.animateTo(0);
      }

      // ✅ PASO 4: Dar un pequeño delay para que la UI se actualice
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ PASO 5: AHORA SÍ cerrar el loading
      if (mounted) Navigator.pop(context);

      // ✅ PASO 6: Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game started!',
              style: TextStyle(
                  fontSize: 17,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // ✅ Cerrar loading en caso de error
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
            content: Text(
              errorMessage,
              style: TextStyle(
                  color: FrutiaColors.primary, fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
