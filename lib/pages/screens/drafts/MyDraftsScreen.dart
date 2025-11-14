// lib/pages/screens/drafts/MyDraftsScreen.dart
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyDraftsScreen extends StatefulWidget {
  const MyDraftsScreen({super.key});

  @override
  State<MyDraftsScreen> createState() => _MyDraftsScreenState();
}

class _MyDraftsScreenState extends State<MyDraftsScreen> {
  List<dynamic> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drafts = await SessionService.getDrafts();
      
      if (!mounted) return;

      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });

      print('[MyDrafts] Loaded ${drafts.length} drafts');
    } catch (e) {
      print('[MyDrafts] Error: $e');
      
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading drafts: ${e.toString()}'),
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
          'My Drafts',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDrafts,
              color: FrutiaColors.primary,
              child: _drafts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      itemCount: _drafts.length,
                      itemBuilder: (context, index) {
                        final draft = _drafts[index];
                        return _buildDraftCard(draft, index);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drafts_outlined,
            size: 80,
            color: FrutiaColors.disabledText,
          ),
          const SizedBox(height: 20),
          Text(
            'No drafts yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a session and save it as draft\nto start working on it later',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: FrutiaColors.secondaryText,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> draft, int index) {
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FrutiaColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con nombre y tipo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FrutiaColors.warning.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FrutiaColors.warning.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_document,
                    color: FrutiaColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft['session_name'] ?? 'No name',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: FrutiaColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getSessionTypeName(draft['session_type'] ?? ''),
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: FrutiaColors.warning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DRAFT',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body con información
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.group_outlined,
                      '${draft['number_of_players']} Players',
                    ),
                    const SizedBox(width: 20),
                    _buildInfoItem(
                      Icons.sports_tennis,
                      '${draft['number_of_courts']} Court${draft['number_of_courts'] > 1 ? 's' : ''}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.timer_outlined,
                      '${draft['duration_hours']} Hour${draft['duration_hours'] > 1 ? 's' : ''}',
                    ),
                    const SizedBox(width: 20),
                    _buildInfoItem(
                      Icons.score_outlined,
                      '${draft['points_per_game']} Points',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Códigos de sesión
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FrutiaColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: FrutiaColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCodeItem(
                        'Session Code',
                        draft['session_code'] ?? 'N/A',
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: FrutiaColors.disabledText,
                      ),
                      _buildCodeItem(
                        'Verification',
                        draft['verification_code'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(draft),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FrutiaColors.error,
                          side: BorderSide(color: FrutiaColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _activateDraft(draft),
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        label: Text(
                          'Activate Session',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrutiaColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
     .fadeIn(duration: 400.ms)
     .slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FrutiaColors.secondaryText),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 13,
            color: FrutiaColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeItem(String label, String code) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            color: FrutiaColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          code,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FrutiaColors.primary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _activateDraft(Map<String, dynamic> draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.play_circle_outline, color: FrutiaColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Activate Session',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'This will generate games and start the session "${draft['session_name']}". Ready to begin?',
          style: GoogleFonts.lato(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: FrutiaColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Activate',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Activating session...',
              style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await SessionService.activateDraft(draft['id']);
      final sessionId = response['session']['id'];

      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session activated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar al SessionControlPanel
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => SessionControlPanel(sessionId: sessionId),
        ),
        (route) => route.isFirst,
      );

    } catch (e) {
      print('[MyDrafts] Error activating: $e');
      
      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: FrutiaColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: FrutiaColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'Delete Draft',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${draft['session_name']}"? This action cannot be undone.',
          style: GoogleFonts.lato(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: FrutiaColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SessionService.deleteDraft(draft['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadDrafts(); // Reload list

    } catch (e) {
      print('[MyDrafts] Error deleting: $e');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: FrutiaColors.error,
        ),
      );
    }
  }
}