import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ModeratorLoginDialog extends StatefulWidget {
  const ModeratorLoginDialog({super.key});

  @override
  State<ModeratorLoginDialog> createState() => _ModeratorLoginDialogState();
}

class _ModeratorLoginDialogState extends State<ModeratorLoginDialog> {
  final TextEditingController _sessionCodeController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _sessionCodeController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final sessionCode = _sessionCodeController.text.trim().toUpperCase();
    final verificationCode = _verificationCodeController.text.trim();

    if (sessionCode.isEmpty || sessionCode.length != 6) {
      _showError('Please enter a valid 6-character Session Code');
      return;
    }
    if (verificationCode.isEmpty ||
        verificationCode.length != 2 ||
        !RegExp(r'^\d{2}$').hasMatch(verificationCode)) {
      _showError('Please enter a valid 2-digit Moderator Key');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await SessionService.moderatorLoginWithSessionCode(
          sessionCode, verificationCode);
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showSessionConfirmationDialog(response);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      _showError(
          errorMessage.contains('not found') || errorMessage.contains('Invalid')
              ? 'Invalid session code or moderator key'
              : 'Error: $errorMessage');
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

  void _showSessionConfirmationDialog(Map<String, dynamic> sessionData) {
    final session = sessionData['session'];
    final String sessionName = session['session_name'] ?? 'Unknown Session';
    final int numPlayers = session['number_of_players'] ?? 0;
    final int numCourts = session['number_of_courts'] ?? 0;
    final String sessionType = _getSessionTypeName(session['session_type']);
    final double progressPercentage =
        (session['progress_percentage'] ?? 0).toDouble();

    print('🔍 [DEBUG] Session completa: $session');
    print('🔍 [DEBUG] User data: ${session['user']}');
    print('🔍 [DEBUG] User name: ${session['user']?['name']}');

    // ✅ AGREGADO: Session Owner
    final String? userName = session['user']?['name'];
    final String sessionOwner =
        userName?.isNotEmpty == true ? userName! : 'N/A';

    // ✅ MODIFICADO: Solo obtener la fecha
    final String sessionDate = session['created_at'] != null
        ? _formatDate(session['created_at'])
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: FrutiaColors.primary.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FrutiaColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: FrutiaColors.primary, width: 2),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: FrutiaColors.primary, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text('Join as Moderator',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(height: 8),
                    Text('You are about to join session',
                        style: GoogleFonts.lato(
                            fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('$sessionName',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: FrutiaColors.primary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    // ✅ MODIFICADO: Aumentado el fontSize a 16 (mismo que "You are about to join session")
                    Text(
                      'As a Moderator, you will be able to manage games and enter scores.',
                      style: GoogleFonts.lato(
                          fontSize: 16, color: Colors.black87, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // DETAILS
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session Details',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    const SizedBox(height: 12),

                    // ✅ AGREGADO: Session Owner
                    _buildDetailRow('Session Owner:', sessionOwner),
                    const SizedBox(height: 10),

                    _buildDetailRow('Players:', numPlayers.toString()),
                    const SizedBox(height: 10),
                    _buildDetailRow('Courts:', numCourts.toString()),
                    const SizedBox(height: 10),
                    _buildDetailRow('Session Type:', sessionType),
                    const SizedBox(height: 10),

                    // ✅ MODIFICADO: Cambiado a "Start Date" y removido Session Time
                    _buildDetailRow('Start Date:', sessionDate),
                    const SizedBox(height: 10),

                    _buildDetailRow('Progress:',
                        '${progressPercentage.toInt()}% Completed'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FrutiaColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: FrutiaColors.warning.withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: FrutiaColors.warning, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please confirm this is the session you want to moderate.',
                              style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ACTIONS
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                              color: Colors.black.withOpacity(0.5), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [
                            FrutiaColors.primary,
                            FrutiaColors.primary.withOpacity(0.8)
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: FrutiaColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar confirmación
                            Navigator.pop(context); // Cerrar diálogo principal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionControlPanel(
                                  sessionId: session['id'],
                                  isModerator:
                                      sessionData['is_moderator'] ?? false,
                                  isOwner: sessionData['is_owner'] ?? false,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Confirm',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ NUEVO MÉTODO: Solo formatea la fecha (sin hora)
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
        Text(value,
            style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black)),
      ],
    );
  }

  String _getSessionTypeName(String type) {
    switch (type) {
      case 'S':
        return 'MAX VARIETY';
      case 'P4':
        return 'TOP 4 PLAYOFFS';
      case 'P8':
        return 'TOP 8 PLAYOFFS';
      case 'T':
        return 'COMPETITIVE MAX';
      case 'O':
        return 'Optimized';
      default:
        return type;
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return 'N/A';
    if (parts.length == 1)
      return parts[0]
          .substring(0, parts[0].length > 3 ? 3 : parts[0].length)
          .toUpperCase();
    final firstName = parts[0];
    final lastInitial = parts.last[0];
    return (firstName.substring(
                0, firstName.length > 3 ? 3 : firstName.length) +
            lastInitial)
        .toUpperCase();
  }

  Map<String, String> _formatDateTime(String dateStr) {
    try {
      final dateNY = DateTime.parse(dateStr);

      final hour = dateNY.hour % 12 == 0 ? 12 : dateNY.hour % 12;
      final minute = dateNY.minute.toString().padLeft(2, '0');
      final ampm = dateNY.hour >= 12 ? 'PM' : 'AM';

      // QUITAR "ET" - SOLO HORA Y AM/PM
      final timeString = '$hour:$minute $ampm'; // <- Eliminado "ET"

      final dateString =
          '${dateNY.day.toString().padLeft(2, '0')}/${dateNY.month.toString().padLeft(2, '0')}/${dateNY.year}';

      return {
        'date': dateString,
        'time': timeString,
      };
    } catch (e) {
      return {'date': 'N/A', 'time': 'N/A'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: FrutiaColors.primary.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          // <--- AÑADIDO
          padding: const EdgeInsets.only(bottom: 20), // Espacio para teclado
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === HEADER (sin cambios) ===
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FrutiaColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: FrutiaColors.primary, width: 2),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: FrutiaColors.primary, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join as Moderator',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the Session Code and Moderator Key',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // === INPUTS (reducimos un poco el font para seguridad) ===
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Session Code
                    TextField(
                      controller: _sessionCodeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      enabled: !_isLoading,
                      style: GoogleFonts.robotoMono(
                        fontSize: 24, // Reducido de 28 → 24
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.qr_code,
                            color: FrutiaColors.warning),
                        hintText: 'e.g., A1B2C3',
                        hintStyle: GoogleFonts.lato(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: FrutiaColors.secondaryText,
                          letterSpacing: 1.5,
                        ),
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: FrutiaColors.primary.withOpacity(0.6),
                              width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: FrutiaColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: FrutiaColors.primary.withOpacity(0.05),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Moderator Key
                    TextField(
                      controller: _verificationCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      textAlign: TextAlign.center,
                      enabled: !_isLoading,
                      style: GoogleFonts.robotoMono(
                        fontSize: 24, // Reducido de 28 → 24
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.security,
                            color: FrutiaColors.primary),
                        hintText: 'e.g., 12',
                        hintStyle: GoogleFonts.lato(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: FrutiaColors.secondaryText,
                          letterSpacing: 1.5,
                        ),
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: FrutiaColors.primary.withOpacity(0.6),
                              width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: FrutiaColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: FrutiaColors.primary.withOpacity(0.05),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 20),

                    // INFO BOX
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FrutiaColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: FrutiaColors.warning.withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: FrutiaColors.warning, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ask the Session Owner for both codes to begin moderation.',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // === BOTONES (sin cambios) ===
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                              color: Colors.black.withOpacity(0.5), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
                          gradient: LinearGradient(
                            colors: _isLoading
                                ? [
                                    FrutiaColors.disabledText,
                                    FrutiaColors.disabledText
                                  ]
                                : [
                                    FrutiaColors.primary,
                                    FrutiaColors.primary.withOpacity(0.8)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: _isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        FrutiaColors.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Search',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
