// lib/utils/SpectatorCodeDialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';

class SpectatorCodeDialog extends StatefulWidget {
  const SpectatorCodeDialog({super.key});

  @override
  State<SpectatorCodeDialog> createState() => _SpectatorCodeDialogState();
}

class _SpectatorCodeDialogState extends State<SpectatorCodeDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty || code.length != 6) {
      _showError('Please enter a valid 6-character code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SessionService.findSessionByCode(code);
      
      if (!mounted) return;
      
      Navigator.pop(context); // Close dialog
      
      // Navigate to session in spectator mode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionControlPanel(
            sessionId: response['session']['id'],
            isSpectator: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Session not found or not active');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FrutiaColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FrutiaColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove_red_eye,
                color: FrutiaColors.warning,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Join as Spectator',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: FrutiaColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Enter the 6-character session code',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: FrutiaColors.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            
            // Code Input
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              autofocus: true,
              style: GoogleFonts.robotoMono(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: FrutiaColors.primaryText,
              ),
              decoration: InputDecoration(
                hintText: 'AB1234',
                hintStyle: GoogleFonts.robotoMono(
                  fontSize: 32,
                  letterSpacing: 8,
                  color: FrutiaColors.disabledText,
                ),
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: FrutiaColors.warning.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: FrutiaColors.warning,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: FrutiaColors.warning.withOpacity(0.05),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => _joinSession(),
            ),
            const SizedBox(height: 28),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: FrutiaColors.tertiaryBackground,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isLoading ? [] : [
                        BoxShadow(
                          color: FrutiaColors.warning.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _joinSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.warning,
                        disabledBackgroundColor: FrutiaColors.disabledText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Join',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 16,
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
    );
  }
}