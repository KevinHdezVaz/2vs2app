import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Política de Privacidad',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Política de Privacidad',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                'En Frutia, tu privacidad es una prioridad. Esta Política de Privacidad explica cómo recopilamos, usamos, protegemos y compartimos tu información cuando utilizas nuestra aplicación. Al usar Frutia, aceptas las prácticas descritas a continuación.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '1. Información que Recopilamos\nRecopilamos información que nos proporcionas directamente, como tu nombre, correo electrónico, preferencias alimenticias, metas de salud y datos sobre tu rutina. También podemos recopilar datos generados por tu uso de la aplicación, como interacciones con el sistema y preferencias de configuración.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '2. Uso de la Información\nUtilizamos tu información para personalizar tus planes de nutrición, mejorar la funcionalidad de la aplicación y ofrecerte una experiencia adaptada a tus necesidades. También podemos usar datos anonimizados para análisis y mejoras del servicio.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '3. Compartir Información\nNo vendemos ni compartimos tu información personal con terceros, salvo en casos requeridos por la ley o para proteger los derechos de Frutia. Podemos compartir datos anonimizados con socios para fines de investigación o mejora del servicio.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '4. Seguridad de los Datos\nImplementamos medidas de seguridad técnicas y organizativas para proteger tu información. Sin embargo, ningún sistema es completamente infalible, por lo que te recomendamos tomar precauciones adicionales, como usar contraseñas seguras.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '5. Tus Derechos\nPuedes acceder, corregir o eliminar tu información personal en cualquier momento desde la configuración de la aplicación. Si tienes dudas o necesitas asistencia, contáctanos en soporte@frutia.com.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1400.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '6. Cambios en esta Política\nNos reservamos el derecho de actualizar esta política. Te notificaremos sobre cambios significativos a través de la aplicación o por correo electrónico. El uso continuado de Frutia implica la aceptación de la política actualizada.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1600.ms, duration: 800.ms),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Volver',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 1800.ms, duration: 800.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
