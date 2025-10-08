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
    // Show confirmation dialog
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

    // If confirmed, proceed with logout
    if (confirm == true && context.mounted) {
      try {
        // Remove the token
        await StorageService().removeToken();

        // Navigate to login and remove all previous routes
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPageCheck()),
            (route) => false,
          );
        }
      } catch (e) {
        // Show error if something goes wrong
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
                  'PickleBracket makes Open Play sessions more organized, varied, and fun.',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'It takes the guesswork out of who plays with whom — using smart scheduling to create balanced, dynamic matchups so everyone gets great games.',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'At the end of each session, PickleBracket shows how everyone performed, giving you simple, session-only insights — not permanent ratings or public rankings. You\'ll see how well you played without the stress or stakes of official DUPR matches.',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: FrutiaColors.primaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Behind the scenes, PickleBracket uses intelligent pairing logic to keep rotations fair, results meaningful, and Open Play running smoothly from start to finish.',
                  style: GoogleFonts.lato(
                    fontSize: 16,
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
                    icon: Icons.history,
                    title: 'History',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.group_outlined,
                    title: 'Players',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlayersScreen()),
                      );
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
                    icon: Icons.help_outline,
                    title: 'Help',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help
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