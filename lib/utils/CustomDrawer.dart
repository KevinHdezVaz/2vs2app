import 'package:Frutia/pages/screens/drawer/HistoryScreen.dart';
import 'package:Frutia/pages/screens/drawer/PlayersScreen.dart';
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
                style: GoogleFonts.poppins(
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
        await StorageService().removeToken();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPageCheck()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: FrutiaColors.error,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // Make the dialog slightly wider
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PickleBracket is designed to make your Open Play sessions more organized, varied, and fun by taking the stress out of managing matches.',
                  style: GoogleFonts.lato(
                    fontSize: 14, // Smaller font size
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Smart Scheduling: We use intelligent, dynamic pairing logic to ensure balanced, meaningful matchups every time.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Balance & Variety: Never worry about who you play with or against—our system maximizes variety so everyone gets great games.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Insights, Not Rankings: We show how everyone performed using simple, session-only insights—these are not permanent ratings or public rankings. Play without the stress of official DUPR stakes!',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: FrutiaColors.primary, size: 28),
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
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Information We Collect',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'We only collect information necessary to provide and improve the PickleBracket service:\n'
                  '• Account Data: When you create an account, we collect your name (or preferred nickname) and email address. This is used solely for logging in and managing your sessions.\n'
                  '• Session Data: We collect the scores, match results, and session management details you input. This data is used only to run your live sessions, generate session-only performance insights, and track historical results within your private account.\n'
                  '• Usage Data: We may collect non-identifying data related to how the app is used (e.g., number of sessions created, features accessed) to improve performance and features.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '2. How We Use Your Data',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'Your data is used exclusively to:\n'
                  '• Operate and personalize your PickleBracket experience.\n'
                  '• Manage your active and completed sessions.\n'
                  '• Communicate with you regarding service updates or account issues.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '3. Data Sharing',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'We do not sell your personal data or session performance metrics to third parties. We may share non-personally identifiable, aggregated data with business partners for analytics purposes.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '4. Your Control',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'You maintain full control over your session data and can delete your account at any time through the app settings.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
        );
      },
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Acceptance of Terms',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'You must be at least 13 years old to use this Service. By accessing or using the Service, you confirm that you have read, understood, and agreed to be bound by these Terms.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '2. Use of the Service',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'Account Responsibility: You are responsible for all activity that occurs under your account. You agree to use the Service only for lawful purposes related to organizing and tracking recreational pickleball sessions.\n'
                  'Non-Official Use: The session insights and performance metrics generated by PickleBracket are for entertainment and organizational purposes only and are not official or permanent rankings.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '3. Intellectual Property',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'The PickleBracket name, logo, software, and all content provided through the Service are the property of PickleBracket.Pro and are protected by copyright. You are granted a non-exclusive, non-transferable right to use the Service for personal, non-commercial use only.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '4. Disclaimer of Warranty',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'The Service is provided on an "as-is" and "as-available" basis. We do not guarantee that the app will be error-free or uninterrupted. We are not responsible for any issues that arise from technical errors, scheduling disputes, or user-inputted data errors.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
        );
      },
    );
  }

  Future<void> _showYourAccountDialog(BuildContext context) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.account_circle_outlined, color: FrutiaColors.primary, size: 28),
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
                Text(
                  'Account Information',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Name: $userName\nEmail: $userEmail',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Account',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FrutiaColors.primaryText,
                  ),
                ),
                Text(
                  'You can delete your account below. This action is permanent and will remove all your account data, including session history.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ],
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
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FrutiaColors.error,
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
          ],
        );
      },
    );

    if (confirmDelete == true && context.mounted) {
      try {
        // Assuming a method in StorageService to delete account data
      //  await StorageService().deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPageCheck()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account deleted successfully'),
              backgroundColor: FrutiaColors.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: FrutiaColors.error,
            ),
          );
        }
      }
    }
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
              FrutiaColors.accentLight,
              FrutiaColors.primaryBackground,
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
                    onTap: () {
                      Navigator.pop(context);
                      _showYourAccountDialog(context);
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
    _showPrivacyPolicyDialog(context); // ¡Error! Debería ser _showPrivacyPolicyDialog
  },
),
_buildDrawerItem(
  icon: Icons.book_outlined,
  title: 'Terms of Service',
  onTap: () {
    Navigator.pop(context);
    _showTermsOfServiceDialog(context); // ¡Error! Debería ser _showTermsOfServiceDialog
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
                    color: FrutiaColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: FrutiaColors.primary,
                  ),
                ),
                title: Text(
                  'Log Out',
                  style: GoogleFonts.poppins(
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
        color: FrutiaColors.primary,
      ),
      title: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: FrutiaColors.primaryText,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}