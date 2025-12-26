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

class _SpectatorCodeDialogState extends State<SpectatorCodeDialog>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _searchSession() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty || code.length != 6) {
      _showErrorDialog('Please enter a valid 6-character code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sessionData = await SessionService.findSessionByCode(code);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Mostrar diálogo de confirmación con detalles
      _showSessionConfirmationDialog(sessionData);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(
          'No active session was found using the code entered. Please verify the session code and try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: FrutiaColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: FrutiaColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: FrutiaColors.primaryText,
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
  }

  void _showSessionConfirmationDialog(Map<String, dynamic> sessionData) {
    final session = sessionData['session'];

    // Extraer datos
    final String sessionName = session['session_name'] ?? 'Unknown Session';
    final int numPlayers = session['number_of_players'] ?? 0;
    final int numCourts = session['number_of_courts'] ?? 0;
    final String sessionType = _getSessionTypeName(session['session_type']);
    final double progressPercentage =
        (session['progress_percentage'] ?? 0).toDouble();
    final String? userName = session['user']?['name'];
    final String sessionLead =
        userName?.isNotEmpty == true ? _getInitials(userName!) : 'N/A';

    // ✅ CAMBIO: Separar fecha y hora usando el nuevo método
    final Map<String, String> dateTimeParts = session['created_at'] != null
        ? _formatDateTimeToMap(session['created_at'])
        : {'date': 'N/A', 'time': 'N/A'};

    // Formatear fecha
    final String createdAt = session['created_at'] != null
        ? _formatDateTime(session['created_at'])
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
                color: FrutiaColors.warning.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
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
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.remove_red_eye,
                          color: FrutiaColors.primary, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join as Spectator',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are about to join session',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sessionName',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.warning,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // TEXTO MEJORADO: más grande, mismo estilo
                    Text(
                      'As a spectator, you will be able to see the order of games, results, and rankings.',
                      style: GoogleFonts.lato(
                        fontSize: 13, // Más grande
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // SESSION DETAILS
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ), // Reducido
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12), // Reducido

                    _buildDetailRow('Players:', numPlayers.toString()),
                    const SizedBox(height: 10),
                    _buildDetailRow('Courts:', numCourts.toString()),
                    const SizedBox(height: 10),
                    _buildDetailRow('Session Type:', sessionType),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Session Date:', dateTimeParts['date'] ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Session Time:', dateTimeParts['time'] ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Progress:',
                        '${progressPercentage.toInt()}% Completed'),
                    const SizedBox(height: 16),
                    // MENSAJE DE CONFIRMACIÓN MEJORADO
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FrutiaColors.warning
                            .withOpacity(0.15), // Fondo más claro
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: FrutiaColors.warning.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: FrutiaColors.warning, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please confirm this is the session you want to join.',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87, // Más oscuro
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
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
                            colors: [
                              FrutiaColors.warning,
                              FrutiaColors.warning.withOpacity(0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: FrutiaColors.warning.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionControlPanel(
                                  sessionId: session['id'],
                                  isSpectator: true,
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
                          child: Text(
                            'Confirm',
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

  Map<String, String> _formatDateTimeToMap(String dateStr) {
    try {
      final dateNY = DateTime.parse(dateStr);

      final hour = dateNY.hour % 12 == 0 ? 12 : dateNY.hour % 12;
      final minute = dateNY.minute.toString().padLeft(2, '0');
      final ampm = dateNY.hour >= 12 ? 'PM' : 'AM';

      // ✅ SIN "ET" - Solo hora y AM/PM
      final timeString = '$hour:$minute $ampm';

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

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
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

    if (parts.length == 1) {
      return parts[0]
          .substring(0, parts[0].length > 3 ? 3 : parts[0].length)
          .toUpperCase();
    }

    final firstName = parts[0];
    final lastInitial = parts[parts.length - 1][0];
    final initials =
        firstName.substring(0, firstName.length > 3 ? 3 : firstName.length) +
            lastInitial;
    return initials.toUpperCase();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ HEADER VERDE
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FrutiaColors.SpectatorGreen,
                      FrutiaColors.SpectatorGreen
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.remove_red_eye,
                        color: FrutiaColors.primary.withOpacity(0.9),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join as Spectator',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: FrutiaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ CONTENIDO BLANCO
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Enter the Session Code',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // Label "SESSION CODE"
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SESSION CODE',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Code Input
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      enabled: !_isLoading,
                      style: GoogleFonts.robotoMono(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.qr_code,
                            color: FrutiaColors.SpectatorGreen),
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
                              color:
                                  FrutiaColors.SpectatorGreen.withOpacity(0.6),
                              width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: FrutiaColors.SpectatorGreen, width: 2),
                        ),
                        filled: true,
                        fillColor:
                            FrutiaColors.SpectatorGreen.withOpacity(0.05),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // INFO BOX
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ask the Session Owner for the code to spectate.',
                              style: GoogleFonts.lato(
                                fontSize: 12,
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

              // BOTONES
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
                                    FrutiaColors.SpectatorGreen,
                                    FrutiaColors.SpectatorGreen
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: _isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        FrutiaColors.SpectatorGreen.withOpacity(
                                            0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _searchSession,
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
