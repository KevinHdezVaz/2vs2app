import 'package:Frutia/model/2vs2p/SessionData.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/createSession/CourtDetailsScreen.dart';
import 'package:Frutia/pages/screens/createSession/PlayerDetailsScreen.dart';
import 'package:Frutia/pages/screens/createSession/SessionDetailScreen.dart';
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
        backgroundColor: FrutiaColors.primary,
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
                            ? FrutiaColors.accent
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

  // 🔥 Mostrar loading AQUÍ
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
            'Creando sesión...',
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
    print('[CreateSessionFlow] Creando sesión...');
    
    final response = await SessionService.createSession(_sessionData.toJson());
    print('[CreateSessionFlow] Sesión creada: ${response['session']['id']}');
    
    final sessionId = response['session']['id'];
    
    print('[CreateSessionFlow] Iniciando sesión...');
    await SessionService.startSession(sessionId);
    print('[CreateSessionFlow] Sesión iniciada exitosamente');

   if (!mounted) return;

Navigator.of(context).pop(); // Cerrar loading
Navigator.of(context).pop(); // Cerrar CreateSessionFlow

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('¡Sesión iniciada con éxito!'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);

// 🔥 pushAndRemoveUntil para limpiar el stack y volver a HomePage
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => SessionControlPanel(sessionId: sessionId),
  ),
  (route) => route.isFirst, // Mantiene solo HomePage (la primera ruta)
);

  } catch (e) {
    print('[CreateSessionFlow] Error: $e');
    
    if (!mounted) return;
    
    Navigator.of(context).pop(); // Cerrar loading

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al crear sesión: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// Simplificar el diálogo de confirmación (sin loading aquí)
Future<bool> _showConfirmationDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Crear Sesión'),
      content: const Text(
        '¿Estás seguro? La mayoría de las configuraciones no podrán modificarse después de iniciar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Revisar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: FrutiaColors.primary,
          ),
          child: const Text(
            'CREAR SESIÓN', 
            style: TextStyle(color: Colors.white)
          ),
        ),
      ],
    ),
  ) ?? false;
}

 }
