import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
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
                'Términos y Condiciones de Uso',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                'Bienvenido(a) a Frutia. Al utilizar nuestra aplicación, aceptas cumplir con los siguientes términos y condiciones. Por favor, léelos cuidadosamente antes de continuar usando nuestros servicios.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '1. Aceptación de los Términos\nAl descargar, instalar o usar la aplicación Frutia, aceptas estos términos y condiciones en su totalidad. Si no estás de acuerdo con alguna parte, te pedimos que no utilices la aplicación.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '2. Uso de la Aplicación\nFrutia está diseñada para proporcionar planes de nutrición personalizados basados en tus preferencias, metas y estilo de vida. No garantizamos resultados específicos, ya que los resultados pueden variar según el usuario. Debes usar la aplicación bajo tu propia responsabilidad y consultar a un profesional de la salud antes de realizar cambios significativos en tu dieta.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '3. Privacidad\nTu privacidad es importante para nosotros. La información que compartas con Frutia será tratada de acuerdo con nuestra Política de Privacidad, que puedes consultar en la aplicación o en nuestro sitio web.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '4. Propiedad Intelectual\nTodo el contenido de la aplicación, incluyendo textos, gráficos, logotipos y software, es propiedad de Frutia o sus licenciantes y está protegido por las leyes de propiedad intelectual. No puedes copiar, modificar, distribuir o reproducir ningún contenido sin nuestro consentimiento expreso.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '5. Modificaciones\nNos reservamos el derecho de modificar estos términos y condiciones en cualquier momento. Te notificaremos sobre cambios significativos a través de la aplicación o por otros medios. El uso continuado de la aplicación implica la aceptación de los términos actualizados.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.secondaryText,
                ),
              ).animate().fadeIn(delay: 1400.ms, duration: 800.ms),
              const SizedBox(height: 16),
              Text(
                '6. Contacto\nSi tienes preguntas sobre estos términos, puedes contactarnos en soporte@frutia.com.',
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
