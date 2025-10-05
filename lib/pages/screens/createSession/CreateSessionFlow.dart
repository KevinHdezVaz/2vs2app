import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/createSession/CourtDetailsScreen.dart';
import 'package:Frutia/pages/screens/createSession/PlayerDetailsScreen.dart';
import 'package:Frutia/pages/screens/createSession/SessionDetailScreen.dart';
import 'package:Frutia/pages/screens/createSession/SessionTypeScreen.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateSessionFlow extends StatefulWidget {
  const CreateSessionFlow({super.key});

  @override
  State<CreateSessionFlow> createState() => _CreateSessionFlowState();
}

class _CreateSessionFlowState extends State<CreateSessionFlow> {
  final PageController _pageController = PageController();
  final SessionData _sessionData = SessionData();
  int _currentPage = 0;
  bool _isCreating = false;

  void _nextPage() {
    if (_currentPage < 3) {  // Cambiado de 2 a 3 porque ahora hay 4 páginas (0,1,2,3)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: FrutiaColors.primary,
        title: Text(
          'Create New Session',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showCancelDialog(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator - ACTUALIZADO A 4 PASOS
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 4; i++) ...[  // Cambiado de 3 a 4
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? FrutiaColors.accent
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 3) const SizedBox(width: 8),  // Cambiado de 2 a 3
                ],
              ],
            ),
          ),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                // Página 1: Session Details (nombre, canchas, duración, jugadores, settings)
                SessionDetailsScreen(
                  sessionData: _sessionData,
                  onNext: _nextPage,
                ),
                // Página 2: Session Type (Tournament, Playoff 4, Playoff 8)
                SessionTypeScreen(
                  sessionData: _sessionData,
                  onNext: _nextPage, 
                  onBack: _previousPage,
                ),
                // Página 3: Court Details (nombres de canchas)
                CourtDetailsScreen(
                  sessionData: _sessionData,
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                // Página 4: Player Details (nombres de jugadores)
                PlayerDetailsScreen(
                  sessionData: _sessionData,
                  onBack: _previousPage,
                  onStartSession: _handleStartSession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session Creation?'),
        content: const Text('All entered data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartSession() async {
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

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
            SizedBox(height: 16),
            Text(
              'Creating session...',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      print('[CreateSessionFlow] Creating session...');

      final response = await SessionService.createSession(_sessionData.toJson());
      print('[CreateSessionFlow] Session created: ${response['session']['id']}');

      final sessionId = response['session']['id'];

      print('[CreateSessionFlow] Starting session...');
      await SessionService.startSession(sessionId);
      print('[CreateSessionFlow] Session started successfully');

      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close CreateSessionFlow

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session started successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => SessionControlPanel(sessionId: sessionId),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      print('[CreateSessionFlow] Error: $e');

      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating session: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Session'),
        content: const Text(
          'Are you sure? Most settings cannot be modified after starting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.primary,
            ),
            child: const Text(
              'CREATE SESSION',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}