import 'package:Frutia/utils/LoadingMessagesWidget.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class PlanGenerationDialog extends StatelessWidget {
  final bool isEditing;

  const PlanGenerationDialog({super.key, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.white,
        // --- CORRECCIÓN ---
        // Se reduce el padding para que el diálogo ocupe más espacio en la pantalla.
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        // Se elimina el ConstrainedBox para permitir que el diálogo se expanda.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FrutiaColors.secondaryBackground.withOpacity(0.95),
                FrutiaColors.primaryBackground.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: Colors.white, // <-- Fondo blanco sólido

            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animación de carga
                SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              FrutiaColors.accent),
                          strokeWidth: 7,
                          backgroundColor: Colors.grey[300],
                          value: null,
                        ),
                      ),
                      Lottie.asset(
                        'assets/images/loaderFruta.json',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Título principal
                Text(
                  isEditing
                      ? 'Actualizando tu plan personalizado...'
                      : 'Generando tu plan personalizado...',
                  style: GoogleFonts.lato(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: FrutiaColors.primaryText,
                    letterSpacing: 0.7,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 18),

                // Mensaje de tiempo estimado
                Text(
                  'El proceso puede tomar 4-6 minutos aproximadamente.',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    height: 1.4,
                    color: FrutiaColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                // Mensaje importante
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Por favor no cierres la aplicación',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                // Widget de mensajes de carga
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: LoadingMessagesWidget(),
                ),

                const SizedBox(height: 15),

                // Texto final
                Text(
                  '⏳ Procesando tu solicitud...',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.disabledText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}
