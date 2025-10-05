import 'package:Frutia/services/2vs2/HistoryService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 import 'package:Frutia/utils/colors.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<dynamic> _players = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final players = await HistoryService.getAllPlayers();
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Players',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: FrutiaColors.primaryText,
          ),
        ),
        backgroundColor: FrutiaColors.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: FrutiaColors.primary),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: FrutiaColors.primary,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: FrutiaColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading players',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: FrutiaColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: FrutiaColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPlayers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrutiaColors.primary,
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.lato(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : _players.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 80,
                            color: FrutiaColors.disabledText,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No players yet',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              color: FrutiaColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPlayers,
                      color: FrutiaColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          return _buildPlayerCard(player);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: FrutiaColors.primary.withOpacity(0.2),
              child: Text(
                player['display_name'][0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: FrutiaColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player['display_name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player['session']['name']} • ${_getSessionTypeLabel(player['session']['type'])}',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: FrutiaColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(
                        'Games',
                        player['games_played'].toString(),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Won',
                        player['games_won'].toString(),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Win%',
                        '${player['win_percentage']}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: FrutiaColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    player['current_rating'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: FrutiaColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: FrutiaColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FrutiaColors.accentLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.lato(
          fontSize: 10,
          color: FrutiaColors.secondaryText,
        ),
      ),
    );
  }

  String _getSessionTypeLabel(String type) {
    switch (type) {
      case 'T':
        return 'Tournament';
      case 'P4':
        return 'Playoff 4';
      case 'P8':
        return 'Playoff 8';
      default:
        return type;
    }
  }
}