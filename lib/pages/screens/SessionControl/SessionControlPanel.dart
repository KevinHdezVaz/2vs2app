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
  final bool isSpectator;

  const SessionControlPanel({
    super.key,
    required this.sessionId,
    this.isSpectator = false,
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
          ? await SessionService.getPublicSession(widget.sessionId)
          : await SessionService.getSession(widget.sessionId);

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
          _elapsedSeconds = sessionResponse['elapsed_seconds'] ?? 0;
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
    }
  }

  void _checkForStageOrPlayoffCompletion() {
    if (_sessionData == null) return;

    final sessionType = _sessionData!['session_type'];
    final status = _sessionData!['status'];

    if (status != 'active') return;

    if (sessionType == 'T') {
      final currentStage = _sessionData!['current_stage'] ?? 1;

      final hasActiveGames = _liveGames.isNotEmpty;
      final hasPendingGamesInCurrentStage = _nextGames.any((game) => game['stage'] == currentStage);

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

    if (sessionType == 'P4' || sessionType == 'P8') {
      final hasPlayoffGames = _liveGames.any((game) => game['is_playoff_game'] == true) ||
          _nextGames.any((game) => game['is_playoff_game'] == true) ||
          _completedGames.any((game) => game['is_playoff_game'] == true);

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
          title: const Text('Loading...'),
         leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () async {
    Navigator.of(context).popUntil((route) => route.isFirst);
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

    return Scaffold(
      backgroundColor: FrutiaColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: FrutiaColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      'SPECTATOR MODE',
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
              valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
            ),
          ),

          Container(
            color: FrutiaColors.primaryBackground,
            child: TabBar(
              controller: _tabController,
              labelColor: FrutiaColors.primary,
              unselectedLabelColor: FrutiaColors.disabledText,
              indicatorColor: FrutiaColors.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.play_circle_filled),
                  text: 'Live (${_liveGames.length})',
                ),
                Tab(
                  icon: const Icon(Icons.queue),
                  text: 'Upcoming (${_nextGames.length})',
                ),
                Tab(
                  icon: const Icon(Icons.check_circle),
                  text: 'Completed (${_completedGames.length})',
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
    if (_nextGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSessionData(),
      color: FrutiaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nextGames.length + 1, // +1 for the advance button
        itemBuilder: (context, index) {
          // Show advance button at the end
          if (index == _nextGames.length) {
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

  Widget _buildAdvanceStageButton() {
    final sessionType = _sessionData?['session_type'];
    final currentStage = _sessionData?['current_stage'] ?? 1;
    
    // Don't show button if there are active games
    if (_liveGames.isNotEmpty) {
      return const SizedBox.shrink();
    }

    String buttonText = '';
    if (sessionType == 'P4' || sessionType == 'P8') {
      buttonText = 'Advance to Playoffs';
    } else if (sessionType == 'T') {
      if (currentStage == 1) {
        buttonText = 'Advance to Stage 2';
      } else if (currentStage == 2) {
        buttonText = 'Advance to Stage 3';
      } else {
        return const SizedBox.shrink(); // No more stages
      }
    }

    if (buttonText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showAdvanceStageConfirmation(),
        icon: const Icon(Icons.arrow_forward, color: Colors.white),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showAdvanceStageConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Advance to Next Stage?',
          style: GoogleFonts.poppins(color: FrutiaColors.primaryText),
        ),
        content: Text(
          'New matches will be created based on current rankings and session type - this action cannot be reverted!',
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
              'Continue',
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
      try {
        final sessionType = _sessionData?['session_type'];
        
        if (sessionType == 'P4' || sessionType == 'P8') {
          await SessionService.generatePlayoffBracket(widget.sessionId);
        } else if (sessionType == 'T') {
          await SessionService.advanceStage(widget.sessionId);
        }
        
        _loadSessionData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Advanced to next stage successfully'),
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
          
          // Podium colors for top 3
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
              boxShadow: rank <= 3 ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rank <= 3
                        ? (rank == 1 ? const Color(0xFFFFD700) :
                           rank == 2 ? const Color(0xFFC0C0C0) :
                           const Color(0xFFCD7F32))
                        : FrutiaColors.secondaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? Colors.white : FrutiaColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Player name
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${player['first_name']} ${player['last_initial']}.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Stats
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Games played
                        _buildStatColumn(
                          '${player['games_played'] ?? 0}',
                          'Games',
                        ),
                        const SizedBox(width: 12),
                        
                        // Win %
                        _buildStatColumn(
                          '${player['win_percentage']?.toInt() ?? 0}%',
                          'Win',
                        ),
                        const SizedBox(width: 12),
                        
                        // Points %
                        _buildStatColumn(
                          '${player['points_won_percentage']?.toInt() ?? 0}%',
                          'Pts',
                        ),
                        const SizedBox(width: 12),
                        
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: FrutiaColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            player['current_rating']?.toInt().toString() ?? '0',
                            style: GoogleFonts.robotoMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: FrutiaColors.primary,
                            ),
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

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FrutiaColors.primaryText,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 9,
            color: FrutiaColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, {bool isLive = false, bool isCompleted = false, int? queuePosition}) {
    final team1Player1 = game['team1_player1'];
    final team1Player2 = game['team1_player2'];
    final team2Player1 = game['team2_player1'];
    final team2Player2 = game['team2_player2'];
    final court = game['court'];
    final isPending = !isLive && !isCompleted;

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
            // Header: Queue position or Court info
            Row(
              children: [
                if (queuePosition != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FrutiaColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$queuePosition',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ),
                ] else if (court != null) ...[
                Image.asset(
  'assets/icons/padel.png',
  width: 32,
  height: 32,
),
const SizedBox(width: 4),
Text(
  court['court_name'] ?? 'Court',
  style: GoogleFonts.lato(
    fontSize: 12,
    color: FrutiaColors.secondaryText,
    fontWeight: FontWeight.w600,
  ),
),
                ],
                if (isLive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                // Cancel button for live games
                if (isLive && !widget.isSpectator) ...[
                  InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Cancel game?',
                            style: GoogleFonts.poppins(color: FrutiaColors.primaryText),
                          ),
                          content: Text(
                            'The game will return to the pending queue.',
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
                                'Yes, cancel',
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
                                content: Text('Game canceled'),
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

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: isCompleted ? const EdgeInsets.all(8) : null,
                    decoration: isCompleted && (game['team1_score'] ?? 0) > (game['team2_score'] ?? 0)
                      ? BoxDecoration(
                          color: FrutiaColors.accent.withOpacity(0.15),
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

                Expanded(
                  child: Container(
                    padding: isCompleted ? const EdgeInsets.all(8) : null,
                    decoration: isCompleted && (game['team2_score'] ?? 0) > (game['team1_score'] ?? 0)
                      ? BoxDecoration(
                          color: FrutiaColors.accent.withOpacity(0.15),
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

            if (!widget.isSpectator) ...[
              // Edit score button (completed games)
              if (isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldEdit = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Edit Score?',
                            style: GoogleFonts.poppins(color: FrutiaColors.primaryText),
                          ),
                          content: Text(
                            'Any changes to scores will recalculate ratings and rankings as if this game was replayed NOW - these changes cannot be reverted.',
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
                                'Continue',
                                style: GoogleFonts.lato(color: FrutiaColors.primary, fontWeight: FontWeight.w600),
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
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      'Edit Score',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FrutiaColors.warning,
                      side: BorderSide(color: FrutiaColors.warning, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // Live game buttons
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
                      'Record Result',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              // Pending game buttons
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _skipToCourt(game),
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: Text(
                          'Skip to Court',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FrutiaColors.primary,
                          side: BorderSide(color: FrutiaColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (game['court_id'] != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startGame(game),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: Text(
                            'Start Game',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FrutiaColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _skipToCourt(Map<String, dynamic> game) async {
    try {
      await GameService.skipToCourt(game['id']);
      _loadSessionData();
      
      // Switch to Live tab
      _tabController.animateTo(0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game moved to court'),
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
  }

  Future<void> _startGame(Map<String, dynamic> game) async {
    try {
      await GameService.startGame(game['id']);
      _loadSessionData();
      
      // Switch to Live tab
      _tabController.animateTo(0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game started'),
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
  }
    
    }