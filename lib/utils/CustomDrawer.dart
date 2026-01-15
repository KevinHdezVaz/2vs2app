import 'package:Frutia/pages/screens/EditProfileScreen.dart';
import 'package:Frutia/pages/screens/drawer/HistoryScreen.dart';
import 'package:Frutia/pages/screens/drawer/PlayersScreen.dart';
import 'package:Frutia/services/2vs2/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/auth/auth_page_check.dart';
import 'package:Frutia/utils/colors.dart';

class CustomDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;

  const CustomDrawer({
    super.key,
    this.userName = "Coordinator",
    this.userEmail = "coordinator@sport.com",
  });

// En custom_drawer.dart - REEMPLAZAR el método _logout

  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: FrutiaColors.primary),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: FrutiaColors.secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(
                  color: FrutiaColors.disabledText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FrutiaColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      try {
        // ✅ CORREGIDO: Limpiar TODOS los datos
        final storage = StorageService();

        // Opción 1: Borrar específicamente token y user
        await storage.removeToken();
        await storage.removeUser();

        // Opción 2 (Recomendada): Limpiar todo
        // await storage.clearAll();

        print('🧹 Logout: Token y datos de usuario eliminados');

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPageCheck()),
            (route) => false,
          );
        }
      } catch (e) {
        print('❌ Error logging out: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error logging out: $e',
                style: TextStyle(
                    color: FrutiaColors.primary, fontWeight: FontWeight.bold),
              ),
              backgroundColor: FrutiaColors.ElectricLime,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: FrutiaColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'About PickleBracket',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: FrutiaColors.primaryText,
                  height: 1.55,
                ),
                children: const [
                  TextSpan(
                      text:
                          'PickleBracket is designed to make your Open Play sessions more '),
                  TextSpan(
                      text: 'organized, varied, and fun ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          'by taking the stress out of managing matches.\n\n'),
                  TextSpan(
                      text: 'Smart Scheduling: ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          'We use intelligent, dynamic pairing logic to ensure '),
                  TextSpan(
                      text: 'balanced, meaningful matchups ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: 'every time.\n\n'),
                  TextSpan(
                      text: 'Balance & Variety: ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          'Never worry about who you play with or against—our system maximizes '),
                  TextSpan(
                      text: 'player variety ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: 'so everyone gets great games.\n\n'),
                  TextSpan(
                      text: 'Insights, Not Rankings: ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          'We show how everyone performed using intelligent, '),
                  TextSpan(
                      text: 'session-only insights',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: '—these are '),
                  TextSpan(
                      text: 'not ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          'permanent ratings or public rankings. Play without the stress of official DUPR stakes!\n\n'),
                  TextSpan(
                      text: 'Learn more at ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                    text: 'picklebracket.pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: FrutiaColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  side:
                      const BorderSide(color: FrutiaColors.primary, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.lato(
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.privacy_tip_outlined,
                  color: FrutiaColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your privacy is a priority for PickleBracket. We are committed to protecting the information you share with us.',
                  style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.primaryText,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                // ... todo tu contenido actual de Privacy Policy (lo dejo igual que tenías)
                Text('1. Information We Collect',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'We only collect information necessary to provide and improve the PickleBracket service:\n• Account Data: When you create an account, we collect your name (or preferred nickname) and email address. This is used solely for logging in and managing your sessions.\n• Session Data: We collect the scores, match results, and session management details you input. This data is used only to run your live sessions, generate session-only performance insights, and track historical results within your private account.\n• Usage Data: We may collect non-identifying data related to how the app is used (e.g., number of sessions created, features accessed) to improve performance and features.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
                const SizedBox(height: 12),
                Text('2. How We Use Your Data',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'Your data is used exclusively to:\n• Operate and personalize your PickleBracket experience.\n• Manage your active and completed sessions.\n• Communicate with you regarding service updates or account issues.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
                const SizedBox(height: 12),
                Text('3. Data Sharing',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'We do not sell your personal data or session performance metrics to third parties. We may share non-personally identifiable, aggregated data with business partners for analytics purposes.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
                const SizedBox(height: 12),
                Text('4. Your Control',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'You maintain full control over your session data and can delete your account at any time through the app settings.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  side:
                      const BorderSide(color: FrutiaColors.primary, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.lato(
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        );
      },
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.book_outlined, color: FrutiaColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Terms of Service',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'By using the PickleBracket mobile application (the "Service"), you agree to the following terms and conditions.',
                  style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.primaryText,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                Text('1. Acceptance of Terms',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'You must be at least 13 years old to use this Service. By accessing or using the Service, you confirm that you have read, understood, and agreed to be bound by these Terms.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
                const SizedBox(height: 12),
                Text('2. Use of the Service',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'Account Responsibility: You are responsible for all activity that occurs under your account. You agree to use the Service only for lawful purposes related to organizing and tracking recreational pickleball sessions.\nNon-Official Use: The session insights and performance metrics generated by PickleBracket are for entertainment and organizational purposes only and are not official or permanent rankings.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
                const SizedBox(height: 12),
                Text('3. Intellectual Property',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'The PickleBracket name, logo, software, and all content provided through the Service are the property of PickleBracket.Pro and are protected by copyright. You are granted a non-exclusive, non-transferable right to use the Service for personal, non-commercial use only.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
                const SizedBox(height: 12),
                Text('4. Disclaimer of Warranty',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrutiaColors.primaryText)),
                Text(
                    'The Service is provided on an "as-is" and "as-available" basis. We do not guarantee that the app will be error-free or uninterrupted. We are not responsible for any issues that arise from technical errors, scheduling disputes, or user-inputted data errors.',
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: FrutiaColors.primaryText,
                        height: 1.5)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  side:
                      const BorderSide(color: FrutiaColors.primary, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.lato(
                  color: FrutiaColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        );
      },
    );
  }

  // ✅ MÉTODO ACTUALIZADO CON EDIT Y TELÉFONO
  Future<void> _showYourAccountDialog(BuildContext context) async {
    // Variables para guardar los datos
    late String accountCreatedDate;
    late int sessionsCompleted;
    late int activeSessions;
    late String phoneNumber;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Obtener datos reales del usuario
      final userProfile = await UserService.getUserProfile();
      final String freshName = userProfile['name'] ?? userName;
      final String freshEmail = userProfile['email'] ?? userEmail;
      // Guardar los datos
      accountCreatedDate = userProfile['created_at'] ?? 'N/A';
      sessionsCompleted = userProfile['sessions_completed'] ?? 0;
      activeSessions = userProfile['active_sessions'] ?? 0;
      phoneNumber = userProfile['phone'] ?? 'N/A'; // ✅ NUEVO

      if (!context.mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      // Esperar un frame antes de mostrar el siguiente diálogo
      await Future.delayed(const Duration(milliseconds: 100));
      if (!context.mounted) return;

      final String? action = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Row(
              children: [
                Icon(Icons.account_circle_outlined,
                    color: FrutiaColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Account',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Account Information Section
                  Text(
                    'Account Information',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FrutiaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Name
                  _buildInfoRow('Name:', freshName),
                  const SizedBox(height: 8),

                  Text(
                    'Email:',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: FrutiaColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    freshEmail,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: FrutiaColors.primaryText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Phone Number - NUEVO
                  _buildInfoRow('Phone Number:', phoneNumber),
                  const SizedBox(height: 8),

                  _buildInfoRow('Account Created:', accountCreatedDate),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Sessions Completed:', sessionsCompleted.toString()),
                  const SizedBox(height: 8),
                  _buildInfoRow('Active Sessions:', activeSessions.toString()),

                  const SizedBox(height: 24),

                  // ✅ BOTONES EDIT Y OK (arriba del Delete Account)
                  Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop('edit'),
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FrutiaColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: FrutiaColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // OK button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop('ok'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FrutiaColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Delete Account Section - Separated with red box
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FrutiaColors.error,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: FrutiaColors.error.withOpacity(0.05),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: FrutiaColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Account',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: FrutiaColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This action is permanent and will remove all your account data, including session history.',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: FrutiaColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Delete button - full width
                        // Delete button - full width
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Cerrar el diálogo actual primero
                              Navigator.of(context).pop();

                              // Mostrar confirmación de eliminación
                              final bool? confirmDelete =
                                  await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: FrutiaColors.error,
                                            size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Delete Account?',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: FrutiaColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'This action is PERMANENT.',
                                      style: GoogleFonts.lato(
                                        fontSize: 15,
                                        color: FrutiaColors.primaryText,
                                        height: 1.5,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.lato(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: FrutiaColors.error,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Delete Account',
                                          style: GoogleFonts.lato(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              // Si confirmó, proceder con la eliminación
                              if (confirmDelete == true && context.mounted) {
                                try {
                                  await UserService.deleteAccount();
                                  await StorageService().clearAll();
                                  print('🧹 Account deleted permanently');

                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AuthPageCheck()),
                                      (route) => false,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Account deleted successfully',
                                          style: TextStyle(
                                            color: FrutiaColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor:
                                            FrutiaColors.ElectricLime,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('❌ Error deleting account: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error deleting account: $e',
                                          style: const TextStyle(
                                            color: FrutiaColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor:
                                            FrutiaColors.ElectricLime,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FrutiaColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Delete Account',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
          );
        },
      );

      print('🔴 [CustomDrawer] Acción seleccionada: $action');

      // ✅ MANEJAR LAS ACCIONES
      if (!context.mounted) return;

      if (action == 'edit') {
        // ✅ Navegar a la pantalla de edición
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              currentName: freshName,
              currentEmail: freshEmail,
              currentPhone: phoneNumber != 'N/A' ? phoneNumber : null,
            ),
          ),
        );

        // Si se guardaron cambios, recargar el diálogo
        if (result == true && context.mounted) {
          await _showYourAccountDialog(context);
        }
      } else if (action == 'delete') {
        // Confirmar eliminación
        try {
          await UserService.deleteAccount();
          await StorageService().clearAll();
          print('🧹 Account deleted: All data cleared');

          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthPageCheck()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Account deleted successfully',
                  style: TextStyle(
                      color: FrutiaColors.primary, fontWeight: FontWeight.bold),
                ),
                backgroundColor: FrutiaColors.ElectricLime,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          print('❌ Error deleting account: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error deleting account: $e',
                  style: TextStyle(
                      color: FrutiaColors.primary, fontWeight: FontWeight.bold),
                ),
                backgroundColor: FrutiaColors.ElectricLime,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
      // Si action == 'ok' o null, simplemente cerrar
    } catch (e) {
      print('❌ [CustomDrawer] Error: $e');

      if (!context.mounted) return;

      // Cerrar loading si todavía está abierto
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading account information: $e',
            style: TextStyle(
                color: FrutiaColors.primary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: FrutiaColors.ElectricLime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ NUEVO HELPER METHOD
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: FrutiaColors.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: FrutiaColors.primaryText,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              FrutiaColors.LighterLime,
              FrutiaColors.LighterLime,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Menu options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_circle_outlined,
                    title: 'Your Account',
                    onTap: () async {
                      // ✅ NO cerrar el drawer todavía
                      // Llamar al método que ahora cerrará el drawer después
                      await _showYourAccountDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      _showPrivacyPolicyDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.book_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      Navigator.pop(context);
                      _showTermsOfServiceDialog(context);
                    },
                  ),
                ],
              ),
            ),
            // Logout button
            Container(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: FrutiaColors.SignalRed,
                  ),
                ),
                title: Text(
                  'Log Out',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primary,
                  ),
                ),
                onTap: () => _logout(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: FrutiaColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // App version
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: FrutiaColors.disabledText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: FrutiaColors.primary, // Navy
      ),
      title: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: FrutiaColors.primary, // ✅ CAMBIO: Navy (igual que iconos)
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
