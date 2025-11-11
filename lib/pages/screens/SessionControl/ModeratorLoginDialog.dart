// lib/utils/ModeratorLoginDialog.dart
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ModeratorLoginDialog extends StatefulWidget {
  const ModeratorLoginDialog({super.key});

  @override
  State<ModeratorLoginDialog> createState() => _ModeratorLoginDialogState();
}

class _ModeratorLoginDialogState extends State<ModeratorLoginDialog> {
  final TextEditingController _sessionCodeController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _sessionCodeController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final sessionCode = _sessionCodeController.text.trim().toUpperCase();
    final verificationCode = _verificationCodeController.text.trim();

    if (sessionCode.isEmpty || sessionCode.length != 6) {
      _showError('Please enter a valid 6-character Session Code');
      return;
    }
    if (verificationCode.isEmpty ||
        verificationCode.length != 2 ||
        !RegExp(r'^\d{2}$').hasMatch(verificationCode)) {
      _showError('Please enter a valid 2-digit Verification Code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('[ModeratorLogin] Attempting login with Session: $sessionCode, Verification: $verificationCode');
      final response = await SessionService.moderatorLoginWithSessionCode(sessionCode, verificationCode);

      if (!mounted) return;

      final sessionId = response['session']['id'];
      final isModerator = response['is_moderator'] ?? false;
      final isOwner = response['is_owner'] ?? false;

      print('[ModeratorLogin] Login successful! Session ID: $sessionId, Moderator: $isModerator, Owner: $isOwner');

      Navigator.of(context).pop();

      Fluttertoast.showToast(
        msg: isOwner ? 'Welcome back, Session Owner!' : 'Moderator access granted!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: FrutiaColors.success,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SessionControlPanel(
            sessionId: sessionId,
            isModerator: isModerator,
            isOwner: isOwner,
          ),
        ),
      );
    } catch (e) {
      print('[ModeratorLogin] Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('not found') || errorMessage.contains('Invalid')) {
        _showError('Invalid session code or verification code');
      } else {
        _showError('Error: $errorMessage');
      }
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: FrutiaColors.error,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: FrutiaColors.primaryBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================== HEADER ====================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FrutiaColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: FrutiaColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moderator Access',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: FrutiaColors.primaryText,
                          ),
                        ),
                        Text(
                          'Enter the Session Code and Moderator Key.',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: FrutiaColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ==================== SESSION CODE FIELD ====================
              TextField(
                controller: _sessionCodeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                enabled: !_isLoading,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  labelText: 'Session Code',
                  prefixIcon: const Icon(Icons.qr_code, color: FrutiaColors.warning),
                  hintText: 'e.g., A1B2C3',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: FrutiaColors.secondaryText,
                    letterSpacing: 1.5,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: FrutiaColors.warning, width: 2),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),

              // ==================== VERIFICATION CODE FIELD ====================
              TextField(
                controller: _verificationCodeController,
                keyboardType: TextInputType.number,
                maxLength: 2,
                textAlign: TextAlign.center,
                enabled: !_isLoading,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  labelText: 'Moderator Key',
                  prefixIcon: const Icon(Icons.security, color: FrutiaColors.primary),
                  hintText: 'e.g., 12',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: FrutiaColors.secondaryText,
                    letterSpacing: 1.5,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: FrutiaColors.primary, width: 2),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              const SizedBox(height: 24),

              // ==================== INFO BOX ====================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FrutiaColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FrutiaColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: FrutiaColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ask the Session Owner for both codes to begin moderation.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==================== ACTION BUTTONS ====================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: FrutiaColors.disabledText),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: FrutiaColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrutiaColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}