// lib/pages/screens/sessionControl/widgets/ScoreEntryDialog.dart
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreEntryDialog extends StatefulWidget {
  final Map<String, dynamic> game;
  final Map<String, dynamic> session;
  final VoidCallback onScoreSubmitted;
  final bool isEditing;

  const ScoreEntryDialog({
    super.key,
    required this.game,
    required this.session,
    required this.onScoreSubmitted,
    this.isEditing = false,
  });

  @override
  State<ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<ScoreEntryDialog> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();

  final _team1Set1Controller = TextEditingController();
  final _team2Set1Controller = TextEditingController();
  final _team1Set2Controller = TextEditingController();
  final _team2Set2Controller = TextEditingController();
  final _team1Set3Controller = TextEditingController();
  final _team2Set3Controller = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _enableSet3 = false;

  String _formatPlayerName(Map<String, dynamic> player) {
    final firstName = player['first_name'] ?? '';
    final lastInitial = player['last_initial'] ?? '';
    if (lastInitial.isEmpty) return firstName;
    return '$firstName ${lastInitial[0].toUpperCase()}.';
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      if (_isBestOf3()) {
        _team1Set1Controller.text =
            widget.game['team1_set1_score']?.toString() ?? '';
        _team2Set1Controller.text =
            widget.game['team2_set1_score']?.toString() ?? '';
        _team1Set2Controller.text =
            widget.game['team1_set2_score']?.toString() ?? '';
        _team2Set2Controller.text =
            widget.game['team2_set2_score']?.toString() ?? '';
        _team1Set3Controller.text =
            widget.game['team1_set3_score']?.toString() ?? '';
        _team2Set3Controller.text =
            widget.game['team2_set3_score']?.toString() ?? '';
        _checkIfSet3Needed();
      } else {
        _team1Controller.text = widget.game['team1_score']?.toString() ?? '';
        _team2Controller.text = widget.game['team2_score']?.toString() ?? '';
      }
    }
    if (_isBestOf3()) {
      _team1Set1Controller.addListener(_checkIfSet3Needed);
      _team2Set1Controller.addListener(_checkIfSet3Needed);
      _team1Set2Controller.addListener(_checkIfSet3Needed);
      _team2Set2Controller.addListener(_checkIfSet3Needed);
    }
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _team1Set1Controller.dispose();
    _team2Set1Controller.dispose();
    _team1Set2Controller.dispose();
    _team2Set2Controller.dispose();
    _team1Set3Controller.dispose();
    _team2Set3Controller.dispose();
    super.dispose();
  }

  bool _isBestOf3() {
    return widget.session['number_of_sets'].toString() == '3';
  }

  void _checkIfSet3Needed() {
    if (!_isBestOf3()) return;
    final set1Team1 = int.tryParse(_team1Set1Controller.text);
    final set1Team2 = int.tryParse(_team2Set1Controller.text);
    final set2Team1 = int.tryParse(_team1Set2Controller.text);
    final set2Team2 = int.tryParse(_team2Set2Controller.text);

    if (set1Team1 == null ||
        set1Team2 == null ||
        set2Team1 == null ||
        set2Team2 == null) {
      setState(() => _enableSet3 = false);
      return;
    }

    if (!_isSetValid(set1Team1, set1Team2) ||
        !_isSetValid(set2Team1, set2Team2)) {
      setState(() => _enableSet3 = false);
      return;
    }

    final team1Sets =
        (set1Team1 > set1Team2 ? 1 : 0) + (set2Team1 > set2Team2 ? 1 : 0);
    final team2Sets =
        (set1Team2 > set1Team1 ? 1 : 0) + (set2Team2 > set2Team1 ? 1 : 0);

    setState(() => _enableSet3 = (team1Sets == 1 && team2Sets == 1));
  }

  bool _isScoreValid() {
    return _isBestOf3() ? _isScoreValidBestOf3() : _isScoreValidBestOf1();
  }

  bool _isScoreValidBestOf1() {
    if (_team1Controller.text.isEmpty || _team2Controller.text.isEmpty)
      return false;
    final team1Score = int.tryParse(_team1Controller.text);
    final team2Score = int.tryParse(_team2Controller.text);
    if (team1Score == null || team2Score == null) return false;

    final pointsPerGame = widget.session['points_per_game'] as int;
    final winBy = widget.session['win_by'] as int;

    if (team1Score == team2Score) {
      setState(() => _errorMessage = 'Ties are not allowed');
      return false;
    }

    final winnerScore = team1Score > team2Score ? team1Score : team2Score;
    final loserScore = team1Score > team2Score ? team2Score : team1Score;
    final scoreDiff = winnerScore - loserScore;

    if (winBy == 2) {
      if (winnerScore == pointsPerGame) {
        if (loserScore > pointsPerGame - 2) {
          setState(() => _errorMessage =
              'With winner at $pointsPerGame, loser cannot have more than ${pointsPerGame - 2} points');
          return false;
        }
      } else if (winnerScore > pointsPerGame) {
        if (loserScore < pointsPerGame - 1) {
          setState(() => _errorMessage =
              'With winner above $pointsPerGame, loser must have at least ${pointsPerGame - 1} points');
          return false;
        }
        if (scoreDiff != 2) {
          setState(() => _errorMessage =
              'With scores above $pointsPerGame, must win by exactly 2 points');
          return false;
        }
      } else {
        setState(() =>
            _errorMessage = 'Winner must have at least $pointsPerGame points');
        return false;
      }
    }

    if (winBy == 1) {
      if (winnerScore > pointsPerGame) {
        setState(() => _errorMessage =
            'With win by 1, maximum score is $pointsPerGame points (no overtime)');
        return false;
      }
      if (winnerScore < pointsPerGame) {
        setState(() =>
            _errorMessage = 'Winner must have at least $pointsPerGame points');
        return false;
      }
      if (scoreDiff < 1) {
        setState(() => _errorMessage = 'Must win by at least 1 point');
        return false;
      }
    }

    setState(() => _errorMessage = null);
    return true;
  }

  bool _isScoreValidBestOf3() {
    if (_team1Set1Controller.text.isEmpty ||
        _team2Set1Controller.text.isEmpty ||
        _team1Set2Controller.text.isEmpty ||
        _team2Set2Controller.text.isEmpty) {
      setState(() => _errorMessage = 'Sets 1 and 2 are required');
      return false;
    }

    final set1Team1 = int.tryParse(_team1Set1Controller.text);
    final set1Team2 = int.tryParse(_team2Set1Controller.text);
    final set2Team1 = int.tryParse(_team1Set2Controller.text);
    final set2Team2 = int.tryParse(_team2Set2Controller.text);

    if (set1Team1 == null ||
        set1Team2 == null ||
        set2Team1 == null ||
        set2Team2 == null) {
      setState(() => _errorMessage = 'Invalid scores in Sets 1 or 2');
      return false;
    }

    if (!_isSetValid(set1Team1, set1Team2)) {
      setState(() => _errorMessage = 'Set 1 has invalid scores');
      return false;
    }
    if (!_isSetValid(set2Team1, set2Team2)) {
      setState(() => _errorMessage = 'Set 2 has invalid scores');
      return false;
    }

    int team1SetsWon = 0;
    int team2SetsWon = 0;
    if (set1Team1 > set1Team2)
      team1SetsWon++;
    else
      team2SetsWon++;
    if (set2Team1 > set2Team2)
      team1SetsWon++;
    else
      team2SetsWon++;

    if (team1SetsWon == 1 && team2SetsWon == 1) {
      if (_team1Set3Controller.text.isEmpty ||
          _team2Set3Controller.text.isEmpty) {
        setState(() => _errorMessage = 'Set 3 is required (tied 1-1)');
        return false;
      }
      final set3Team1 = int.tryParse(_team1Set3Controller.text);
      final set3Team2 = int.tryParse(_team2Set3Controller.text);
      if (set3Team1 == null || set3Team2 == null) {
        setState(() => _errorMessage = 'Invalid scores in Set 3');
        return false;
      }
      if (!_isSetValid(set3Team1, set3Team2)) {
        setState(() => _errorMessage = 'Set 3 has invalid scores');
        return false;
      }
      if (set3Team1 > set3Team2)
        team1SetsWon++;
      else
        team2SetsWon++;
    }

    if (team1SetsWon != 2 && team2SetsWon != 2) {
      setState(() => _errorMessage = 'One team must win 2 sets');
      return false;
    }

    setState(() => _errorMessage = null);
    return true;
  }

  bool _isSetValid(int score1, int score2) {
    final pointsPerGame = widget.session['points_per_game'] as int;
    final winBy = widget.session['win_by'] as int;

    if (score1 == score2) return false;

    final winnerScore = score1 > score2 ? score1 : score2;
    final loserScore = score1 > score2 ? score2 : score1;
    final scoreDiff = winnerScore - loserScore;

    if (winBy == 2) {
      if (winnerScore == pointsPerGame) {
        if (loserScore > pointsPerGame - 2) return false;
      } else if (winnerScore > pointsPerGame) {
        if (loserScore < pointsPerGame - 1) return false;
        if (scoreDiff != 2) return false;
      } else {
        return false;
      }
    }

    if (winBy == 1) {
      if (winnerScore > pointsPerGame) return false;
      if (winnerScore < pointsPerGame) return false;
      if (scoreDiff < 1) return false;
    }

    return true;
  }

  int _calculateSetsWon(bool isTeam1) {
    final set1Team1 = int.tryParse(_team1Set1Controller.text) ?? 0;
    final set1Team2 = int.tryParse(_team2Set1Controller.text) ?? 0;
    final set2Team1 = int.tryParse(_team1Set2Controller.text) ?? 0;
    final set2Team2 = int.tryParse(_team2Set2Controller.text) ?? 0;
    final set3Team1 = int.tryParse(_team1Set3Controller.text) ?? 0;
    final set3Team2 = int.tryParse(_team2Set3Controller.text) ?? 0;

    int setsWon = 0;
    if (isTeam1) {
      if (set1Team1 > set1Team2) setsWon++;
      if (set2Team1 > set2Team2) setsWon++;
      if (_enableSet3 && set3Team1 > set3Team2) setsWon++;
    } else {
      if (set1Team2 > set1Team1) setsWon++;
      if (set2Team2 > set2Team1) setsWon++;
      if (_enableSet3 && set3Team2 > set3Team1) setsWon++;
    }
    return setsWon;
  }

  int _getTotalScore(bool isTeam1) {
    final set1 = int.tryParse(
            isTeam1 ? _team1Set1Controller.text : _team2Set1Controller.text) ??
        0;
    final set2 = int.tryParse(
            isTeam1 ? _team1Set2Controller.text : _team2Set2Controller.text) ??
        0;
    final set3 = int.tryParse(
            isTeam1 ? _team1Set3Controller.text : _team2Set3Controller.text) ??
        0;
    return set1 + set2 + set3;
  }

  Future<void> _submitScore() async {
    if (!_isScoreValid()) return;
    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        await _handleScoreEditWithRecalculation();
        return;
      }

      if (_isBestOf3()) {
        await _submitBestOf3Score();
      } else {
        await _submitBestOf1Score();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Score recorded successfully!',
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
      widget.onScoreSubmitted();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: TextStyle(
                  fontSize: 17,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleScoreEditWithRecalculation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Recalculating all ratings...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('This may take a moment',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );

    try {
      Map<String, dynamic> result;
      if (_isBestOf3()) {
        result = await SessionService.updateScoreBestOf3WithRecalculation(
          gameId: widget.game['id'],
          team1TotalScore: _getTotalScore(true),
          team2TotalScore: _getTotalScore(false),
          team1Set1Score: int.parse(_team1Set1Controller.text),
          team2Set1Score: int.parse(_team2Set1Controller.text),
          team1Set2Score: int.parse(_team1Set2Controller.text),
          team2Set2Score: int.parse(_team2Set2Controller.text),
          team1Set3Score: _team1Set3Controller.text.isNotEmpty
              ? int.parse(_team1Set3Controller.text)
              : null,
          team2Set3Score: _team2Set3Controller.text.isNotEmpty
              ? int.parse(_team2Set3Controller.text)
              : null,
          team1SetsWon: _calculateSetsWon(true),
          team2SetsWon: _calculateSetsWon(false),
        );
      } else {
        result = await SessionService.updateScoreWithRecalculation(
          gameId: widget.game['id'],
          team1Score: int.parse(_team1Controller.text),
          team2Score: int.parse(_team2Controller.text),
        );
      }

      if (mounted) Navigator.of(context).pop();

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Score updated! Rankings recalculated',
                style: TextStyle(
                    fontSize: 17,
                    color: FrutiaColors.primary,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: FrutiaColors.ElectricLime,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
        widget.onScoreSubmitted();
        if (mounted) Navigator.of(context).pop();
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: TextStyle(
                  fontSize: 17,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _submitBestOf1Score() async {
    final team1Score = int.parse(_team1Controller.text);
    final team2Score = int.parse(_team2Controller.text);
    if (widget.isEditing) {
      await SessionService.updateScore(
          widget.game['id'], team1Score, team2Score);
    } else {
      await SessionService.submitScore(
          widget.game['id'], team1Score, team2Score);
    }
  }

  Future<void> _submitBestOf3Score() async {
    final set1Team1 = int.parse(_team1Set1Controller.text);
    final set1Team2 = int.parse(_team2Set1Controller.text);
    final set2Team1 = int.parse(_team1Set2Controller.text);
    final set2Team2 = int.parse(_team2Set2Controller.text);
    int? set3Team1;
    int? set3Team2;
    if (_enableSet3 &&
        _team1Set3Controller.text.isNotEmpty &&
        _team2Set3Controller.text.isNotEmpty) {
      set3Team1 = int.parse(_team1Set3Controller.text);
      set3Team2 = int.parse(_team2Set3Controller.text);
    }

    final team1Total = set1Team1 + set2Team1 + (set3Team1 ?? 0);
    final team2Total = set1Team2 + set2Team2 + (set3Team2 ?? 0);
    final team1SetsWon = _calculateSetsWon(true);
    final team2SetsWon = _calculateSetsWon(false);

    if (widget.isEditing) {
      await SessionService.updateScoreBestOf3(
        widget.game['id'],
        team1Total,
        team2Total,
        set1Team1,
        set1Team2,
        set2Team1,
        set2Team2,
        set3Team1,
        set3Team2,
        team1SetsWon,
        team2SetsWon,
      );
    } else {
      await SessionService.submitScoreBestOf3(
        widget.game['id'],
        team1Total,
        team2Total,
        set1Team1,
        set1Team2,
        set2Team1,
        set2Team2,
        set3Team1,
        set3Team2,
        team1SetsWon,
        team2SetsWon,
      );
    }
  }

  Widget _buildSetRow({
    required String setLabel,
    required TextEditingController team1Controller,
    required TextEditingController team2Controller,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              setLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? FrutiaColors.primaryText
                    : FrutiaColors.disabledText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: team1Controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? FrutiaColors.primaryText
                    : FrutiaColors.disabledText,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: FrutiaColors.disabledText),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.tertiaryBackground)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.tertiaryBackground)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color:
                            FrutiaColors.tertiaryBackground.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: enabled
                    ? FrutiaColors.primaryBackground
                    : FrutiaColors.tertiaryBackground.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('vs',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: FrutiaColors.disabledText)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: team2Controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? FrutiaColors.primaryText
                    : FrutiaColors.disabledText,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: FrutiaColors.disabledText),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.tertiaryBackground)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.tertiaryBackground)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color:
                            FrutiaColors.tertiaryBackground.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: enabled
                    ? FrutiaColors.primaryBackground
                    : FrutiaColors.tertiaryBackground.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required String player1Name,
    required String player2Name,
    required TextEditingController controller,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor, width: 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$player1Name / $player2Name',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: FrutiaColors.disabledText),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.tertiaryBackground)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.tertiaryBackground)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: FrutiaColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: FrutiaColors.primaryBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team1Player1 = widget.game['team1_player1'];
    final team1Player2 = widget.game['team1_player2'];
    final team2Player1 = widget.game['team2_player1'];
    final team2Player2 = widget.game['team2_player2'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isEditing ? 'Edit Score' : 'Submit Score',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primaryText),
              ),
              const SizedBox(height: 6),
              Text(
                'Game to ${widget.session['points_per_game']} points | Win by ${widget.session['win_by']}' +
                    (_isBestOf3() ? ' | Best of 3' : ''),
                style: GoogleFonts.lato(
                    fontSize: 11, color: FrutiaColors.secondaryText),
              ),
              const SizedBox(height: 18),
              if (_isBestOf3())
                _buildBestOf3UI(
                    team1Player1, team1Player2, team2Player1, team2Player2)
              else
                _buildBestOf1UI(
                    team1Player1, team1Player2, team2Player1, team2Player2),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FrutiaColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FrutiaColors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded,
                          color: FrutiaColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.lato(
                              fontSize: 11, color: FrutiaColors.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side:
                            BorderSide(color: FrutiaColors.tertiaryBackground),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: FrutiaColors.secondaryText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_isSubmitting ? _submitScore : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.primary,
                        disabledBackgroundColor:
                            FrutiaColors.tertiaryBackground,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
                            )
                          : Text(
                              widget.isEditing ? 'Update' : 'Submit',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: FrutiaColors.ElectricLime),
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

  Widget _buildBestOf3UI(
    Map<String, dynamic> team1Player1,
    Map<String, dynamic> team1Player2,
    Map<String, dynamic> team2Player1,
    Map<String, dynamic> team2Player2,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 50),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: FrutiaColors.accentLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(_formatPlayerName(team1Player1),
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: FrutiaColors.primary)),
                    Text(_formatPlayerName(team1Player2),
                        style: GoogleFonts.lato(
                            fontSize: 14, color: FrutiaColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('vs', style: GoogleFonts.poppins(fontSize: 10)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: FrutiaColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(_formatPlayerName(team2Player1),
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: FrutiaColors.primary)),
                    Text(_formatPlayerName(team2Player2),
                        style: GoogleFonts.lato(
                            fontSize: 14, color: FrutiaColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSetRow(
            setLabel: 'Set 1',
            team1Controller: _team1Set1Controller,
            team2Controller: _team2Set1Controller,
            enabled: true),
        _buildSetRow(
            setLabel: 'Set 2',
            team1Controller: _team1Set2Controller,
            team2Controller: _team2Set2Controller,
            enabled: true),
        _buildSetRow(
            setLabel: 'Set 3',
            team1Controller: _team1Set3Controller,
            team2Controller: _team2Set3Controller,
            enabled: _enableSet3),
        if (_enableSet3) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: FrutiaColors.ElectricLime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: FrutiaColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tied 1-1! Set 3 is now active',
                    style: GoogleFonts.lato(
                        fontSize: 11, color: FrutiaColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBestOf1UI(
    Map<String, dynamic> team1Player1,
    Map<String, dynamic> team1Player2,
    Map<String, dynamic> team2Player1,
    Map<String, dynamic> team2Player2,
  ) {
    return Column(
      children: [
        _buildTeamRow(
          player1Name: _formatPlayerName(team1Player1),
          player2Name: _formatPlayerName(team1Player2),
          controller: _team1Controller,
          backgroundColor: FrutiaColors.ElectricLime.withOpacity(0.13),
        ),
        const SizedBox(height: 12),
        Text('VS',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.disabledText)),
        const SizedBox(height: 12),
        _buildTeamRow(
          player1Name: _formatPlayerName(team2Player1),
          player2Name: _formatPlayerName(team2Player2),
          controller: _team2Controller,
          backgroundColor: FrutiaColors.secondaryBackground,
        ),
      ],
    );
  }
}
