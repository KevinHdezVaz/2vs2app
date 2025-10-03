import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/createSession/CourtDetailsScreen.dart';
import 'package:Frutia/pages/screens/createSession/PlayerDetailsScreen.dart';
import 'package:Frutia/pages/screens/createSession/SessionDetailScreen.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
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
    if (_currentPage < 2) {
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE63946), Color(0xFFFF6F61)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Crear Nueva Sesión',
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
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? const Color(0xFFE63946)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          // Contenido de la página
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

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar Creación de Sesión?'),
        content: const Text('Se perderán todos los datos ingresados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar Editando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar',
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

    setState(() {
      _isCreating = true;
    });

    try {
      print('[CreateSessionFlow] Creando sesión...');
      
      // Enviar datos al backend usando SessionService
      final response = await SessionService.createSession(_sessionData.toJson());
      
      print('[CreateSessionFlow] Sesión creada: ${response['session']['id']}');
      
      final sessionId = response['session']['id'];
      
      // Iniciar la sesión (generar juegos)
      print('[CreateSessionFlow] Iniciando sesión...');
      await SessionService.startSession(sessionId);
      
      print('[CreateSessionFlow] Sesión iniciada exitosamente');

      if (!mounted) return;

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Sesión iniciada con éxito!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

   // En el método _handleStartSession, reemplaza el TODO con:
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => SessionControlPanel(sessionId: sessionId),
  ),
);

    } catch (e) {
      print('[CreateSessionFlow] Error: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear sesión: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: !_isCreating,
      builder: (context) => AlertDialog(
        title: const Text('¿Iniciar Sesión?'),
        content: _isCreating
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creando sesión...'),
                ],
              )
            : const Text(
                '¿Estás seguro? La mayoría de las configuraciones no podrán modificarse después de iniciar.',
              ),
        actions: _isCreating
            ? []
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Revisar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                  ),
                  child: const Text('Iniciar Sesión'),
                ),
              ],
      ),
    ) ?? false;
  }
}