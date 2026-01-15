// lib/pages/screens/home/HomePage.dart
import 'package:Frutia/pages/screens/SessionControl/ModeratorLoginDialog.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/createSession/CreateSessionFlow.dart';
import 'package:Frutia/pages/screens/drafts/MyDraftsScreen.dart';
import 'package:Frutia/services/2vs2/HistoryService.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/CustomDrawer.dart';
import 'package:Frutia/utils/SpectatorCodeDialog.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← NUEVO
import 'package:flutter/services.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();
  int _totalUniquePlayers = 0;
  String _userName = "Usuario";
  String _userEmail = "";
  List<dynamic> _activeSessions = [];
  List<dynamic> _recentSessions = [];
  List<dynamic> _completedSessions = [];
  List<dynamic> _draftSessions = [];
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
    _loadData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDataJson = await _storage.getUserData();
      print('[HomePage] Raw user JSON: $userDataJson'); // ← DEBUG

      if (userDataJson == null || userDataJson.isEmpty) {
        print('[HomePage] No user data');
        return;
      }

      final userData = json.decode(userDataJson);
      final name = userData['name']?.toString().trim();

      setState(() {
        _userName = (name?.isNotEmpty == true) ? name! : "Usuario";
        _userEmail = userData['email'] ?? "";
      });

      print('[HomePage] Nombre cargado: $_userName');
    } catch (e) {
      print('[HomePage] Error: $e');
    }
  }

  // ==================== CARGAR TODOS LOS DATOS ====================
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ✅ PASO 1: Cargar sesiones del servidor
      final activeSessions = await SessionService.getActiveSessions();
      final completedSessions = await HistoryService.getHistory();

      // ✅ PASO 2: Cargar drafts LOCALES desde SharedPreferences
      final localDrafts = await _loadLocalDrafts();

      // ✅ PASO 3: Cargar drafts del servidor (opcional, si los tienes)
      List<dynamic> serverDrafts = [];
      try {
        serverDrafts = await HistoryService.getDrafts();
      } catch (e) {
        print('[HomePage] Server drafts not available: $e');
      }

      // ✅ PASO 4: Combinar drafts locales y del servidor
      final allDrafts = [...localDrafts, ...serverDrafts];

      // Ordenar sesiones activas: más recientes + progreso
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

      int totalParticipants = 0;
      for (var session in [...activeSessions, ...completedSessions]) {
        totalParticipants += (session['number_of_players'] as int?) ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _activeSessions = activeSessions;
        _recentSessions = activeSessions;
        _completedSessions = completedSessions;
        _draftSessions = allDrafts; // ← Drafts combinados
        _totalUniquePlayers = totalParticipants;
        _isLoading = false;
      });

      print('[HomePage] Dashboard Data:');
      print(' - Active: ${activeSessions.length}');
      print(' - Drafts (local): ${localDrafts.length}');
      print(' - Drafts (server): ${serverDrafts.length}');
      print(' - Drafts (total): ${allDrafts.length}');
      print(' - Completed: ${completedSessions.length}');
      print(' - Total Participants: $totalParticipants');
    } catch (e) {
      print('[HomePage] Error loading data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading sessions: ${e.toString()}',
              style: TextStyle(
                  color: FrutiaColors.primary, fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ NUEVO MÉTODO: Cargar drafts locales desde SharedPreferences
  Future<List<dynamic>> _loadLocalDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString('session_drafts') ?? '[]';
      final List<dynamic> drafts = json.decode(draftsJson);

      // Ordenar por fecha (más recientes primero)
      drafts.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] ?? '2000-01-01');
        final dateB = DateTime.parse(b['created_at'] ?? '2000-01-01');
        return dateB.compareTo(dateA);
      });

      print('[HomePage] Loaded ${drafts.length} local drafts');
      return drafts;
    } catch (e) {
      print('[HomePage] Error loading local drafts: $e');
      return [];
    }
  }

  // ==================== UI PRINCIPAL ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FrutiaColors.secondaryBackground,
      drawer: CustomDrawer(userName: _userName, userEmail: _userEmail),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: FrutiaColors.primary),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leadingWidth: 40,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        titleSpacing: 16,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icons/logoAppBueno.png',
              height: 40,
              fit: BoxFit.contain,
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
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    _buildAccountSummary(),
                    const SizedBox(height: 28),
                    _buildMainActions(),
                    const SizedBox(height: 28),
                    _buildSessionsTabs(),
                    const SizedBox(height: 10),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              ),
            ),
    );
  }

  // ==================== WIDGETS DE UI ====================

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
            child: Icon(Icons.person_outline,
                color: FrutiaColors.primary, size: 28),
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
                          fontSize: 14, color: FrutiaColors.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
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
    int completedSessions = _completedSessions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Summary',
            style: GoogleFonts.oswald(
              fontSize: 24, // ← Un poco más grande
              fontWeight: FontWeight.w700, // ← Bold (700), no w600
              fontStyle: FontStyle.italic, // ← Italic
              color: FrutiaColors.primary,
              letterSpacing: 0.5, // ← Letter spacing
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FrutiaColors.LighterNavy,
                  FrutiaColors.LighterNavy.withOpacity(0.9)
                ],
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.check_circle_outline,
                  value: completedSessions.toString(),
                  label: 'Sessions \nCompleted',
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildSummaryItem(
                  icon: Icons.play_circle_outline,
                  value: activeSessions.toString(),
                  label: 'Sessions \nIn Progress',
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildSummaryItem(
                  icon: Icons.group_outlined,
                  value: _totalUniquePlayers.toString(),
                  label: 'Total \nParticipants',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildSummaryItem(
      {required IconData icon, required String value, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.ElectricLime)),
            Text(
              label,
              style: GoogleFonts.lato(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16), // ✅ Reducido de 20
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // ✅ Reducido de 12
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24), // ✅ Reducido de 30
            ),
            const SizedBox(width: 12), // ✅ Reducido de 14
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center, // ✅ Centrado vertical
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16, // ✅ Reducido de 18
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2), // ✅ Reducido de 4
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 12, // ✅ Reducido de 13
                      color: textColor.withOpacity(0.9),
                    ),
                    maxLines: 2, // ✅ Permitir 2 líneas si es necesario
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                color: iconColor, size: 16), // ✅ Reducido de 18
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.oswald(
              fontSize: 24, // ← Más grande
              fontWeight: FontWeight.w700, // ← Bold
              fontStyle: FontStyle.italic, // ← Italic
              color: FrutiaColors.primary,
              letterSpacing: 0.5, // ← Spacing
            ),
          ),
          const SizedBox(height: 16),

          // ✅ BOTÓN 1: Create New Session
          SizedBox(
            height: 75, // ✅ Un poco más para evitar overflow
            child: _buildPrimaryActionButton(
              icon: Icons.add_circle,
              title: 'Create New Session',
              subtitle: 'Start a new Open Play session',
              textColor: FrutiaColors.primary,
              iconColor: FrutiaColors.primary,
              gradientColors: [
                FrutiaColors.ElectricLime,
                FrutiaColors.ElectricLime
              ],
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateSessionFlow()),
                );
                if (result == true) _loadData();
              },
            ),
          ),
          const SizedBox(height: 10),

          // ✅ BOTÓN 2: Join as Spectator
          SizedBox(
            height: 75,
            child: _buildPrimaryActionButton(
              icon: Icons.remove_red_eye,
              title: 'Join as Spectator',
              subtitle: 'Follow a live Open Play session',
              textColor: FrutiaColors.primary,
              iconColor: FrutiaColors.primary,
              gradientColors: [
                FrutiaColors.SpectatorGreen,
                FrutiaColors.SpectatorGreen
              ],
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => const SpectatorCodeDialog()),
            ),
          ),
          const SizedBox(height: 10),

          // ✅ BOTÓN 3: Join as Moderator
          SizedBox(
            height: 75,
            child: _buildPrimaryActionButton(
              icon: Icons.admin_panel_settings,
              title: 'Join as Moderator',
              subtitle: 'Help manage a live session',
              gradientColors: [
                FrutiaColors.ModeratorTea,
                FrutiaColors.ModeratorTea
              ],
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => const ModeratorLoginDialog()),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ==================== PESTAÑAS PREMIUM ====================
  Widget _buildSessionsTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Sessions',
              style: GoogleFonts.oswald(
                fontSize: 24, // ← Más grande
                fontWeight: FontWeight.w700, // ← Bold
                fontStyle: FontStyle.italic, // ← Italic
                color: FrutiaColors.primary,
                letterSpacing: 0.5, // ← Spacing
              ),
            ),
            const SizedBox(height: 16),

            // TAB BAR
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: FrutiaColors.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FrutiaColors.disabledText.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      FrutiaColors.primary,
                      FrutiaColors.primary.withOpacity(0.8)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FrutiaColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: FrutiaColors.secondaryText,
                labelPadding: EdgeInsets.zero,
                tabs: [
                  _buildPremiumTab(
                      'Active', _activeSessions.length, Icons.play_circle),
                  _buildPremiumTab(
                      'Drafts', _draftSessions.length, Icons.edit_square),
                  _buildPremiumTab(
                      'Done', _completedSessions.length, Icons.check_circle),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  _buildSessionList(_activeSessions, isActive: true),
                  _buildSessionList(_draftSessions, isDraft: true),
                  _buildSessionList(_completedSessions, isCompleted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildPremiumTab(String label, int count, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== CARD DE SESIÓN COMPLETADA O BORRADOR ====================
  Widget _buildCompletedSessionCard(Map<String, dynamic> session) {
    String getSessionTypeAbbreviation(String type) {
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
          return 'Session';
      }
    }

    final isDraft = session['status'] == 'draft';
    final isLocalDraft = session['draft_id'] != null; // ← Detectar draft local

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FrutiaColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDraft || isLocalDraft)
              ? FrutiaColors.ModeratorTea
              : FrutiaColors.LighterNavy,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          // ✅ Si es draft (local o servidor), ir a CreateSessionFlow
          if (isDraft || isLocalDraft) {
            print('[HomePage] Opening draft for editing');
            print('   - Is local draft: $isLocalDraft');
            print('   - Draft ID: ${session['draft_id'] ?? session['id']}');

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateSessionFlow(
                  draftData: session,
                ),
              ),
            );

            if (result == true && mounted) {
              print('[HomePage] Draft was modified, reloading data...');
              _loadData();
            }
          } else {
            // Si es sesión completada, ir a SessionControlPanel
            print('[HomePage] Opening completed session #${session['id']}');

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionControlPanel(
                  sessionId: session['id'],
                ),
              ),
            );

            if (result == true && mounted) {
              print(
                  '[HomePage] Returning from completed session, reloading...');
              _loadData();
            }
          }
        },
        onLongPress:
            isLocalDraft ? () => _showDeleteDraftDialog(session) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDraft || isLocalDraft)
                          ? FrutiaColors.ModeratorTea.withOpacity(0.1)
                          : FrutiaColors.LighterNavy.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (isDraft || isLocalDraft)
                          ? Icons.edit_square
                          : Icons.check_circle,
                      color: (isDraft || isLocalDraft)
                          ? FrutiaColors.ModeratorTea
                          : FrutiaColors.LighterNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['session_name'] ?? 'No name',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              (isDraft || isLocalDraft) ? 'Draft' : 'Completed',
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: (isDraft || isLocalDraft)
                                    ? FrutiaColors.ModeratorTea
                                    : FrutiaColors.LighterNavy,
                              ),
                            ),
                            // ✅ Badge para drafts locales
                            if (isLocalDraft) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FrutiaColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      getSessionTypeAbbreviation(session['session_type'] ?? ''),
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // INFO ROW
              Row(
                children: [
                  Icon(Icons.group_outlined,
                      size: 16, color: FrutiaColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${session['number_of_players'] ?? 0}',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/icons/cancha_home.png',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session['number_of_courts'] ?? 0}',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today,
                      size: 14, color: FrutiaColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateCompact(
                        session['completed_at'] ?? session['created_at']),
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                ],
              ),

              // ✅ HINT para long press en drafts locales
              if (isLocalDraft) ...[
                const SizedBox(height: 8),
                Text(
                  'Hold to delete',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: FrutiaColors.disabledText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionList(
    List<dynamic> sessions, {
    bool isActive = false,
    bool isDraft = false,
    bool isCompleted = false,
  }) {
    if (sessions.isEmpty) {
      return Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive
                    ? Icons.play_circle_outline
                    : isDraft
                        ? Icons.edit_square
                        : Icons.check_circle_outline,
                size: 56, // Un poco más grande para impacto
                color: FrutiaColors.disabledText.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${isDraft ? 'draft' : isActive ? 'active' : 'completed'} sessions',
                style: GoogleFonts.lato(
                  color: FrutiaColors.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isActive
                    ? 'Create one to get started!'
                    : isDraft
                        ? 'Your drafts will appear here'
                        : 'Completed sessions will show here',
                style: GoogleFonts.lato(
                  color: FrutiaColors.disabledText,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const Spacer(flex: 2), // Más espacio abajo para balance
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        if (isCompleted || isDraft) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCompletedSessionCard(session),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSessionCard(session),
          );
        }
      },
    );
  }

  // ==================== CARD DE SESIÓN ACTIVA ====================
  Widget _buildSessionCard(Map<String, dynamic> session) {
    String status = session['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'active':
        statusColor = FrutiaColors.SpectatorGreen;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FrutiaColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SessionControlPanel(sessionId: session['id'])),
          );
          if (result == true && mounted) _loadData();
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
                        shape: BoxShape.circle),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                                'Type: ${getSessionTypeName(session['session_type'] ?? '')}',
                                style: GoogleFonts.lato(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: FrutiaColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(session['created_at'])}',
                          style: GoogleFonts.lato(
                              fontSize: 13, color: FrutiaColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSessionInfoChipWithIcon(Icons.group_outlined,
                      '${session['number_of_players']} Players'),
                  const SizedBox(width: 12),
                  _buildSessionInfoChip(
                    Image.asset('assets/icons/cancha_home.png',
                        width: 16, height: 16),
                    '${session['number_of_courts']} Court${session['number_of_courts'] > 1 ? 's' : ''}',
                  ),
                  const Spacer(),
                  Text(
                    statusText,
                    style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
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
                        Text('Progress',
                            style: GoogleFonts.lato(
                                fontSize: 12,
                                color: FrutiaColors.secondaryText)),
                        Text(
                            '${(session['progress_percentage'] ?? 0).toInt()}%',
                            style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: FrutiaColors.primaryText)),
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

  // ✅ NUEVO MÉTODO: Mostrar diálogo para eliminar draft
  Future<void> _showDeleteDraftDialog(Map<String, dynamic> draft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
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
                      color: FrutiaColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: FrutiaColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Draft?',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.primaryText,
                          ),
                        ),
                        Text(
                          'This action cannot be undone',
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

              const SizedBox(height: 20),

              // ==================== CONTENT ====================
              Text(
                'Are you sure you want to delete "${draft['session_name']}"?',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: FrutiaColors.secondaryText,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'All draft data will be permanently lost.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // ==================== BUTTONS ====================
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: FrutiaColors.primaryText.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delete button
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
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
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
      ),
    );

    if (confirm == true) {
      await _deleteLocalDraft(draft['draft_id']);
    }
  }

  // ✅ NUEVO MÉTODO: Eliminar draft local
  Future<void> _deleteLocalDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString('session_drafts') ?? '[]';
      final List<dynamic> drafts = json.decode(draftsJson);

      // Remover el draft
      drafts.removeWhere((d) => d['draft_id'] == draftId);

      await prefs.setString('session_drafts', json.encode(drafts));

      print('[HomePage] Draft deleted: $draftId');

      // Recargar datos
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Draft deleted successfully!',
              style: TextStyle(
                  fontSize: 16,
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[HomePage] Error deleting draft: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting draft: ${e.toString()}',
              style: TextStyle(color: FrutiaColors.primary),
            ),
            backgroundColor: FrutiaColors.ElectricLime,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSessionInfoChip(Widget icon, String label) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 12, color: FrutiaColors.secondaryText)),
      ],
    );
  }

  Widget _buildSessionInfoChipWithIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FrutiaColors.secondaryText),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 12, color: FrutiaColors.secondaryText)),
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

  String _formatDateCompact(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year.toString().substring(2)}';
    } catch (e) {
      return 'N/A';
    }
  }
}
