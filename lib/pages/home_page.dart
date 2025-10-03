// lib/pages/screens/home/HomePage.dart
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/createSession/CreateSessionFlow.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/CustomDrawer.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _userName = "Coordinador";
  
  List<dynamic> _activeSessions = [];
  List<dynamic> _recentSessions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeSessions = await SessionService.getActiveSessions();
      
      setState(() {
        _activeSessions = activeSessions;
        _recentSessions = activeSessions;
        _isLoading = false;
      });
    } catch (e) {
      print('[HomePage] Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sesiones: ${e.toString()}'),
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
              'Selecciona una sesión',
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
                    'No hay sesiones activas',
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
                    child: Icon(Icons.play_circle_filled, color: FrutiaColors.success),
                  ),
                  title: Text(
                    session['session_name'] ?? 'Sin nombre',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    '${session['number_of_players']} jugadores | ${session['number_of_courts']} canchas',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: FrutiaColors.primary),
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
      drawer: const CustomDrawer(
        userName: "Coordinador",
        userEmail: "coordinador@sport.com",
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
           color: FrutiaColors.primary
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.sports_tennis, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              'Hola',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
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

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Buenos Días';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Buenas Tardes';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Buenas Noches';
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
          colors: [FrutiaColors.primary, FrutiaColors.accent.withOpacity(0.9)],
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
            'Resumen de Cuenta',
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
                label: 'Completadas',
              ),
              Container(height: 50, width: 1, color: Colors.white30),
              _buildSummaryItem(
                icon: Icons.play_circle_outline,
                value: activeSessions.toString(),
                label: 'En Progreso',
              ),
              Container(height: 50, width: 1, color: Colors.white30),
              _buildSummaryItem(
                icon: Icons.group_outlined,
                value: totalPlayers.toString(),
                label: 'Jugadores',
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
            'Acciones Rápidas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildPrimaryActionButton(
            icon: Icons.add_circle,
            title: 'Crear Nueva Sesión',
            subtitle: 'Iniciar un nuevo torneo o playoff',
            gradientColors: [FrutiaColors.success, FrutiaColors.success.withOpacity(0.8)],
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateSessionFlow()),
              );
              
              if (result == true) {
                _loadData();
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionButton(
                  icon: Icons.play_arrow_rounded,
                  title: 'Continuar Sesión',
                  color: FrutiaColors.warning,
                  onTap: () {
                    if (_activeSessions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No hay sesiones activas'),
                          backgroundColor: FrutiaColors.warning,
                        ),
                      );
                    } else {
                      _showActiveSessionsList();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryActionButton(
                  icon: Icons.visibility_outlined,
                  title: 'Unirse como Espectador',
                  color: FrutiaColors.plan,
                  onTap: () {
                    print('Entrar en modo espectador');
                  },
                ),
              ),
            ],
          ),
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
                'Sesiones Activas',
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
                    Icon(Icons.sports_tennis, size: 64, color: FrutiaColors.disabledText),
                    const SizedBox(height: 16),
                    Text(
                      'No hay sesiones activas',
                      style: GoogleFonts.lato(
                        fontSize: 16, 
                        color: FrutiaColors.secondaryText
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentSessions.map((session) => _buildSessionCard(session)).toList(),
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
        statusText = 'En Progreso';
        break;
      case 'completed':
        statusColor = FrutiaColors.error;
        statusIcon = Icons.check_circle;
        statusText = 'Completada';
        break;
      default:
        statusColor = FrutiaColors.disabledText;
        statusIcon = Icons.schedule;
        statusText = 'Pendiente';
    }

    String getSessionTypeName(String type) {
      switch (type) {
        case 'T':
          return 'Torneo';
        case 'P4':
          return 'Playoff 4';
        case 'P8':
          return 'Playoff 8';
        default:
          return 'Sesión';
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
              builder: (context) => SessionControlPanel(sessionId: session['id']),
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
                                session['session_name'] ?? 'Sin nombre',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: FrutiaColors.primaryText,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: FrutiaColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                getSessionTypeName(session['session_type'] ?? ''),
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
                          'Creada: ${_formatDate(session['created_at'])}',
                          style: GoogleFonts.lato(
                            fontSize: 13, 
                            color: FrutiaColors.secondaryText
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
                    '${session['number_of_players']} Jugadores',
                  ),
                  const SizedBox(width: 12),
                  _buildSessionInfoChip(
                    Icons.sports_tennis,
                    '${session['number_of_courts']} Cancha${session['number_of_courts'] > 1 ? 's' : ''}',
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
                          'Progreso',
                          style: GoogleFonts.lato(
                            fontSize: 12, 
                            color: FrutiaColors.secondaryText
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
            color: FrutiaColors.secondaryText
          )
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Fecha no disponible';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}