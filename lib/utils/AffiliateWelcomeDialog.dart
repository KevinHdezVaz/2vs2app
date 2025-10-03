import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AffiliateWelcomeDialog extends StatelessWidget {
  final String affiliateCode;

  const AffiliateWelcomeDialog({Key? key, required this.affiliateCode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 80),
            const SizedBox(height: 20),
            Text(
              '¡Beneficio Activado!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Gracias por usar el código de nuestro socio. ¡Hemos activado tus beneficios especiales en la app!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'CONTINUAR',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
