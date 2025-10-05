// lib/pages/screens/home/HomePage.dart
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/createSession/CreateSessionFlow.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/CustomDrawer.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();

  String _userName = "Usuario";
  String _userEmail = "";

  List<dynamic> _activeSessions = [];
  List<dynamic> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadData();
  }


@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Esto se llama cada vez que regresas a esta pantalla
  _loadData();
}

  Future<void> _loadUserData() async {
    try {
      final userDataJson = await _storage.getUserData();
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        setState(() {
          _userName = userData['name'] ?? "Usuario";
          _userEmail = userData['email'] ?? "";
        });
        print('[HomePage] Usuario cargado: $_userName');
      }
    } catch (e) {
      print('[HomePage] Error al cargar datos del usuario: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeSessions = await SessionService.getActiveSessions();

      activeSessions.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] ?? '2000-01-01');
        final dateB = DateTime.parse(b['created_at'] ?? '2000-01-01');
        final dateComparison = dateB.compareTo(dateA);

        if (dateComparison == 0) {
          final progressA = (a['progress_percentage'] ?? 0).toDouble();
          final progressB = (b['progress_percentage'] ?? 0).toDouble();
          return progressB.compareTo(progressA);
        }

        return dateComparison;
      });

      setState(() {
        _activeSessions = activeSessions;
        _recentSessions = activeSessions;
        _isLoading = false;
      });
    } catch (e) {
      print('[HomePage] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sessions: ${e.toString()}'),
            backgroundColor: FrutiaColors.error,
          ),
        );
      }
    }
  }

  void _showActiveSessionsList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a session',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            if (_activeSessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No active sessions',
                    style: GoogleFonts.lato(color: FrutiaColors.disabledText),
                  ),
                ),
              )
            else
              ..._activeSessions.map((session) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FrutiaColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_circle_filled,
                        color: FrutiaColors.success),
                  ),
                  title: Text(
                    session['session_name'] ?? 'No name',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    '${session['number_of_players']} players | ${session['number_of_courts']} courts',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: FrutiaColors.primary),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionControlPanel(
                          sessionId: session['id'],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FrutiaColors.secondaryBackground,
      drawer: CustomDrawer(
        userName: _userName,
        userEmail: _userEmail,
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: FrutiaColors.primary,
          ),
        ),
        leadingWidth: 40,
        title: Image.asset(
          'assets/icons/LogoAppWorkana.png',
          height: 59,
          fit: BoxFit.contain,
        ),
        titleSpacing: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 120),
              child: Text(
                'Session Manager', // 👈 Tu texto aquí
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: FrutiaColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader2(),
                    const SizedBox(height: 10),
                    Divider(thickness: 1, color: Colors.black.withOpacity(0.1)),
                    const SizedBox(height: 24),
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    _buildAccountSummary(),
                    const SizedBox(height: 28),
                    _buildMainActions(),
                    const SizedBox(height: 28),
                    _buildRecentSessions(),
                    const SizedBox(height: 100),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create & Manage your Open Play Sessions.",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 62, 87, 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2);
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: FrutiaColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: FrutiaColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetingIcon, size: 18, color: FrutiaColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2);
  }

  Widget _buildAccountSummary() {
    int activeSessions = _activeSessions.length;
    int totalPlayers = 0;

    for (var session in _activeSessions) {
      totalPlayers += (session['number_of_players'] as int? ?? 0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FrutiaColors.primary, FrutiaColors.primary.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FrutiaColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Summary',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.check_circle_outline,
                value: '0',
                label: 'Completed',
              ),
              Container(height: 50, width: 1, color: Colors.white30),
              _buildSummaryItem(
                icon: Icons.play_circle_outline,
                value: activeSessions.toString(),
                label: 'In Progress',
              ),
              Container(height: 50, width: 1, color: Colors.white30),
              _buildSummaryItem(
                icon: Icons.group_outlined,
                value: totalPlayers.toString(),
                label: 'Players',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildMainActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Sessions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildPrimaryActionButton(
            icon: Icons.add_circle,
            title: 'Create New Session',
            subtitle: 'Start a new Optimized or playoff',
            gradientColors: [
              FrutiaColors.success,
              FrutiaColors.success.withOpacity(0.8)
            ],
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateSessionFlow()),
              );

              if (result == true) {
                _loadData();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Sessions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.sports_tennis,
                        size: 64, color: FrutiaColors.disabledText),
                    const SizedBox(height: 16),
                    Text(
                      'No active sessions',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: FrutiaColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentSessions
                .map((session) => _buildSessionCard(session))
                .toList(),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    String status = session['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'active':
        statusColor = FrutiaColors.success;
        statusIcon = Icons.play_circle_filled;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = FrutiaColors.error;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      default:
        statusColor = FrutiaColors.disabledText;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
    }

    String getSessionTypeName(String type) {
      switch (type) {
        case 'T':
          return 'Optimized';
        case 'P4':
          return 'Playoff 4';
        case 'P8':
          return 'Playoff 8';
        default:
          return 'Session';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FrutiaColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SessionControlPanel(sessionId: session['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session['session_name'] ?? 'No name',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: FrutiaColors.primaryText,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: FrutiaColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Type: '+ getSessionTypeName(
                                    session['session_type'] ?? ''),
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: FrutiaColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(session['created_at'])}',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: FrutiaColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSessionInfoChip(
                    Icons.group_outlined,
                    '${session['number_of_players']} Players',
                  ),
                  const SizedBox(width: 12),
                  _buildSessionInfoChip(
                    Icons.sports_tennis,
                    '${session['number_of_courts']} Court${session['number_of_courts'] > 1 ? 's' : ''}',
                  ),
                  const Spacer(),
                  Text(
                    statusText,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              if (status == 'active') ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: FrutiaColors.secondaryText,
                          ),
                        ),
                        Text(
                          '${(session['progress_percentage'] ?? 0).toInt()}%',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FrutiaColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (session['progress_percentage'] ?? 0) / 100,
                      backgroundColor: FrutiaColors.secondaryBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
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

  Widget _buildSessionInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FrutiaColors.secondaryText),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: FrutiaColors.secondaryText,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
