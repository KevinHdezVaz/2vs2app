// lib/pages/spectator_sessions_list_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';

class SpectatorSessionsListPage extends StatefulWidget {
  const SpectatorSessionsListPage({super.key});

  @override
  State<SpectatorSessionsListPage> createState() => _SpectatorSessionsListPageState();
}

class _SpectatorSessionsListPageState extends State<SpectatorSessionsListPage> {
  List<dynamic> _activeSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
  }

  Future<void> _loadActiveSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await SessionService.getPublicActiveSessions();
      setState(() {
        _activeSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sessions: $e'),
          backgroundColor: FrutiaColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FrutiaColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: FrutiaColors.primary,
        title: Text(
          'Active Sessions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.accent),
              ),
            )
          : _activeSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_tennis, size: 64, color: FrutiaColors.disabledText),
                      SizedBox(height: 16),
                      Text(
                        'No active sessions',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadActiveSessions,
                  color: FrutiaColors.accent,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _activeSessions.length,
                    itemBuilder: (context, index) {
                      final session = _activeSessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
                ),
    );
  }


  // Reemplaza el Container del badge "LIVE" con este código:

Widget _buildStatusBadge(Map<String, dynamic> session) {
  final isCompleted = (session['progress_percentage'] ?? 0) >= 100;
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isCompleted ? FrutiaColors.primary : FrutiaColors.success,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      isCompleted ? 'COMPLETED' : 'LIVE',
      style: GoogleFonts.lato(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
} 

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FrutiaColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FrutiaColors.primary.withOpacity(0.4), width: 2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionControlPanel(
                sessionId: session['id'],
                isSpectator: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_tennis, color: FrutiaColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session['session_name'] ?? 'Session',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText,
                      ),
                    ),
                  ),
                  _buildStatusBadge(session),

                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: FrutiaColors.secondaryText),
                  SizedBox(width: 4),
                  Text(
                    '${session['number_of_players']} players',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: FrutiaColors.secondaryText),
                  SizedBox(width: 4),
                  Text(
                    '${session['number_of_courts']} courts',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: (session['progress_percentage'] ?? 0) / 100,
                backgroundColor: FrutiaColors.tertiaryBackground,
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.accent),
              ),
              SizedBox(height: 4),
              Text(
                '${(session['progress_percentage'] ?? 0).toInt()}% completed',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: FrutiaColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}