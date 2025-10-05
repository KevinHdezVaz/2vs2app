import 'package:Frutia/services/2vs2/HistoryService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 import 'package:Frutia/utils/colors.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await HistoryService.getHistory();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
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
                        'Error loading history',
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
                        onPressed: _loadHistory,
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
              : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: FrutiaColors.disabledText,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No completed sessions yet',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              color: FrutiaColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: FrutiaColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final completedAt = DateTime.parse(session['completed_at']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(completedAt);
    final formattedTime = DateFormat('hh:mm a').format(completedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navegar al detalle de la sesión si es necesario
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      session['session_name'],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FrutiaColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getSessionTypeLabel(session['session_type']),
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: FrutiaColors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: FrutiaColors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.group,
                    '${session['number_of_players']} Players',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.sports_tennis,
                    '${session['number_of_courts']} Courts',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.timer,
                    '${session['duration_hours']}h',
                  ),
                ],
              ),
              if (session['winner'] != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: FrutiaColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Winner: ',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.secondaryText,
                      ),
                    ),
                    Text(
                      session['winner']['display_name'] ?? 'N/A',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FrutiaColors.accentLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FrutiaColors.secondaryText),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: FrutiaColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}