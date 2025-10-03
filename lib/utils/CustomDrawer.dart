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
    this.userName = "Coordinador",
    this.userEmail = "coordinador@sport.com",
  });

  Future<void> _logout(BuildContext context) async {
    // Mostrar diálogo de confirmación
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
                'Cerrar Sesión',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FrutiaColors.primaryText,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: FrutiaColors.secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
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
                'Cerrar Sesión',
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

    // Si confirmó, cerrar sesión
    if (confirm == true && context.mounted) {
      try {
        // Eliminar el token
        await StorageService().removeToken();

        // Navegar al login y eliminar todas las rutas anteriores
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPageCheck()),
            (route) => false,
          );
        }
      } catch (e) {
        // Mostrar error si algo sale mal
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
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
            
            // Opciones del menú
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Inicio',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                 
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: 'Historial',
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar al historial
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.group_outlined,
                    title: 'Jugadores',
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar a jugadores
                    },
                  ),
                  
                 
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Ayuda',
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar a ayuda
                    },
                  ),
                ],
              ),
            ),
            
            // Botón de cerrar sesión
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
                  'Cerrar Sesión',
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
            
            // Versión de la app
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Versión 1.0.0',
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