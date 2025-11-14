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
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateSessionFlow extends StatefulWidget {
  final Map<String, dynamic>? draftData; // ← Recibir draft data
  
  const CreateSessionFlow({
    super.key,
    this.draftData,
  });

  @override
  State<CreateSessionFlow> createState() => _CreateSessionFlowState();
}

class _CreateSessionFlowState extends State<CreateSessionFlow> {
  final PageController _pageController = PageController();
  late final SessionData _sessionData; // ← late final
  int _currentPage = 0;
  bool _isCreating = false;
  String? _draftId; // ← Guardar ID del draft (ahora es String para UUID local)

  @override
  void initState() {
    super.initState();
    
    // ✅ Inicializar SessionData con datos del draft si existe
    if (widget.draftData != null) {
      _sessionData = SessionData.fromJson(widget.draftData!);
      _draftId = widget.draftData!['draft_id']; // ← UUID local
      print('[CreateSessionFlow] Loading draft $_draftId');
    } else {
      _sessionData = SessionData();
      print('[CreateSessionFlow] Creating new session');
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
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
          _draftId != null ? 'Edit Draft' : 'Create New Session',
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
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 4; i++) ...[
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
                  if (i < 3) const SizedBox(width: 8),
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
                SessionDetailsScreen(
                  sessionData: _sessionData,
                  onNext: _nextPage,
                ),
                SessionTypeScreen(
                  sessionData: _sessionData,
                  onNext: _nextPage, 
                  onBack: _previousPage,
                ),
                CourtDetailsScreen(
                  sessionData: _sessionData,
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
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

 void _showCancelDialog() async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning, color: FrutiaColors.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'Cancel Session \nCreation?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: FrutiaColors.error,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action will:',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
     
          const SizedBox(height: 12),
          Text(
            'All settings entered will be lost',
            style: GoogleFonts.lato(
              color: FrutiaColors.error,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Continue Setup',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText,
            ),
          ),
        ),
        Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel Session',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // Si el usuario confirma
  if (confirm == true) {
    Navigator.pop(context); // Cierra el diálogo de creación
    Navigator.pop(context); // Regresa al pantalla anterior
  }
}
  // ========================================
  // ✅ VERSIÓN SIMPLIFICADA CON SHAREDPREFERENCES
  // ========================================

  Future<void> _handleStartSession({bool saveAsDraft = false}) async {
    if (!saveAsDraft) {
      final confirmed = await _showConfirmationDialog();
      if (!confirmed) return;
    }

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
              saveAsDraft 
                ? (_draftId != null ? 'Updating draft...' : 'Saving draft...')
                : 'Creating session...',
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
      if (saveAsDraft) {
        // ✅ GUARDAR COMO DRAFT LOCAL
        await _saveDraftLocally();
        
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading
        Navigator.of(context).pop(true); // Close CreateSessionFlow

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _draftId != null 
                      ? 'Draft saved successfully!'
                      : 'Draft saved successfully!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: FrutiaColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // ✅ CREAR SESIÓN EN EL SERVIDOR
        print('[CreateSessionFlow] Creating session on server...');

        final sessionData = _sessionData.toJson();
        final response = await SessionService.createSession(sessionData);

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading

        // ✅ Si venía de un draft, eliminarlo
        if (_draftId != null) {
          await _deleteDraftLocally(_draftId!);
        }

        final sessionId = response['session']['id'];

        Navigator.of(context).pop(); // Close CreateSessionFlow

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session started successfully!', style: TextStyle(fontSize: 17)),
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
      }
    } catch (e) {
      print('[CreateSessionFlow] Error: $e');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      String errorMessage = e.toString();
      
      if (errorMessage.contains('configuration has not been created') ||
          errorMessage.contains('You need at least') ||
          errorMessage.contains('players for')) {
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: FrutiaColors.warning, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configuration Not Available',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              errorMessage.replaceAll('Exception: ', ''),
              style: GoogleFonts.lato(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.lato(
                    color: FrutiaColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: FrutiaColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ GUARDAR DRAFT LOCALMENTE
  Future<void> _saveDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generar ID si es nuevo draft
      if (_draftId == null) {
        _draftId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Preparar datos del draft
      final draftData = {
        'draft_id': _draftId,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'draft',
        ..._sessionData.toJson(),
      };

      // Obtener lista actual de drafts
      final draftsJson = prefs.getString('session_drafts') ?? '[]';
      final List<dynamic> drafts = json.decode(draftsJson);

      // Buscar si ya existe este draft
      final existingIndex = drafts.indexWhere((d) => d['draft_id'] == _draftId);

      if (existingIndex >= 0) {
        // Actualizar draft existente
        drafts[existingIndex] = draftData;
        print('[CreateSessionFlow] Draft updated: $_draftId');
      } else {
        // Agregar nuevo draft
        drafts.add(draftData);
        print('[CreateSessionFlow] New draft saved: $_draftId');
      }

      // Guardar de vuelta
      await prefs.setString('session_drafts', json.encode(drafts));
      print('[CreateSessionFlow] Total drafts: ${drafts.length}');
    } catch (e) {
      print('[CreateSessionFlow] Error saving draft: $e');
      rethrow;
    }
  }

  // ✅ ELIMINAR DRAFT LOCALMENTE
  Future<void> _deleteDraftLocally(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString('session_drafts') ?? '[]';
      final List<dynamic> drafts = json.decode(draftsJson);

      // Remover el draft
      drafts.removeWhere((d) => d['draft_id'] == draftId);

      await prefs.setString('session_drafts', json.encode(drafts));
      print('[CreateSessionFlow] Draft deleted: $draftId');
    } catch (e) {
      print('[CreateSessionFlow] Error deleting draft: $e');
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.play_circle_outline, color: FrutiaColors.primary, size: 28),
            SizedBox(width: 12),
            Text(
              _draftId != null ? 'Start Draft Session' : 'Start Session',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.primaryText,
              ),
            ),
          ],
        ),
        content: Text(
          _draftId != null
            ? 'Ready to start this draft session? Settings cannot be changed once started.'
            : 'All set! Ready to start? Settings cannot be changed once started.',
          style: GoogleFonts.lato(
            fontSize: 16,
            color: FrutiaColors.secondaryText,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: FrutiaColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FrutiaColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Start Session',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }
}