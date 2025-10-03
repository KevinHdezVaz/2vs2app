import 'package:Frutia/pages/home_page.dart';
import 'package:Frutia/pages/screens/SessionControl/SessionControlPanel.dart';
import 'package:Frutia/pages/screens/SessionControl/SpectatorSessionsListPage.dart';
import 'package:Frutia/services/2vs2/SessionService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:Frutia/auth/auth_check.dart';
import 'package:Frutia/auth/auth_service.dart';
import 'package:Frutia/auth/forget_pass_page.dart';
import 'package:Frutia/utils/colors.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const LoginPage({super.key, required this.showLoginPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool isRemember = false;
  bool isObscure = true;

  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '237230625824-uhg81q3ro2at559t31bnorjqrlooe3lr.apps.googleusercontent.com',
  );
  final _authService = AuthService();

  // Animations
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset(0, 0)).animate(
      CurvedAnimation(
          parent: _controller,
          curve: Interval(0.3, 0.8, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    print('====================================');
    print('🔵 INICIO LOGIN');
    print('====================================');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
        ),
      ),
    );

    try {
      print('🔵 Llamando a _authService.login()...');
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      print('🟢 Login exitoso: $response');

      if (!mounted) return;

      // Cierra el diálogo de carga
      Navigator.of(context).pop();

      // 👇 CAMBIA ESTO: Navega directo a HomePage
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // Elimina todas las rutas anteriores
      );
    } on AuthException catch (e) {
      print('🔴 AuthException: ${e.message}');
      if (!mounted) return;
      Navigator.of(context).pop(); // Cierra el diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: FrutiaColors.error,
        ),
      );
    } catch (e) {
      print('🔴 Error genérico: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Cierra el diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: FrutiaColors.error,
        ),
      );
    }
  }

  bool validateLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showErrorSnackBar("Por favor complete todos los campos");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      showErrorSnackBar("Correo electrónico inválido");
      return false;
    }

    if (_passwordController.text.length < 6) {
      showErrorSnackBar("La contraseña debe tener al menos 6 caracteres");
      return false;
    }

    return true;
  }

  void _showSpectatorDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.remove_red_eye, color: FrutiaColors.accent),
            SizedBox(width: 8),
            Text(
              'Modo Espectador',
              style: GoogleFonts.poppins(
                color: FrutiaColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa el código de la sesión para verla en vivo',
              style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: codeController,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: 'ABC12345',
                hintStyle: GoogleFonts.robotoMono(
                  color: FrutiaColors.disabledText,
                  letterSpacing: 4,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: FrutiaColors.accent.withOpacity(0.5),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: FrutiaColors.accent,
                    width: 2.0,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lato(color: FrutiaColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) {
                showErrorSnackBar('Ingresa un código válido');
                return;
              }

              Navigator.pop(context); // Cierra el diálogo
              await _joinAsSpectator(codeController.text.trim().toUpperCase());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FrutiaColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Unirse',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinAsSpectator(String code) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.accent),
        ),
      ),
    );

    try {
      final response = await SessionService.joinWithCode(code);

      if (!mounted) return;
      Navigator.of(context).pop(); // Cierra el loading

      // Navega al SessionControlPanel en modo espectador
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SessionControlPanel(
            sessionId: response['session_id'],
            isSpectator: true, // 👈 Nuevo parámetro
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cierra el loading
      showErrorSnackBar('Código inválido o sesión no encontrada');
    }
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: FrutiaColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              FrutiaColors.primary, // Slate Teal
              FrutiaColors.accent // Lime
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Contenido principal
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      color: Colors.white.withOpacity(0.9),
                      child: Container(
                        width: size.width * 0.9,
                        padding: EdgeInsets.all(24.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 20),

                              Text(
                                "Bienvenido a PickleBracket",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: FrutiaColors.primaryText,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Ingresa tus credenciales para continuar",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      FrutiaColors.primaryText.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 40),
                              // Email TextField
                              SlideTransition(
                                position: _slideAnimation,
                                child: TextField(
                                  cursorColor: FrutiaColors.primary,
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: FrutiaColors.accent
                                            .withOpacity(0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: FrutiaColors.primary,
                                        width: 2.0,
                                      ),
                                    ),
                                    labelText: "Correo",
                                    labelStyle: GoogleFonts.lato(
                                      color: FrutiaColors.primaryText
                                          .withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: FrutiaColors.primary,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 20),
                                  ),
                                  style: GoogleFonts.lato(
                                    color: FrutiaColors.primaryText,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              // Password TextField
                              SlideTransition(
                                position: _slideAnimation,
                                child: TextField(
                                  cursorColor: FrutiaColors.primary,
                                  controller: _passwordController,
                                  obscureText: isObscure,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: FrutiaColors.accent
                                            .withOpacity(0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: FrutiaColors.primary,
                                        width: 2.0,
                                      ),
                                    ),
                                    labelText: "Contraseña",
                                    labelStyle: GoogleFonts.lato(
                                      color: FrutiaColors.primaryText
                                          .withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: FrutiaColors.primary,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isObscure = !isObscure;
                                        });
                                      },
                                      icon: Icon(
                                        isObscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: FrutiaColors.primary,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 20),
                                  ),
                                  style: GoogleFonts.lato(
                                    color: FrutiaColors.primaryText,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              // Remember Me and Forget Password Row
                              SlideTransition(
                                position: _slideAnimation,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: isRemember,
                                          onChanged: (value) {
                                            setState(() {
                                              isRemember = value ?? false;
                                            });
                                          },
                                          activeColor: FrutiaColors.primary,
                                          checkColor: Colors.white,
                                        ),
                                        Text(
                                          'Recordarme',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            color: FrutiaColors.primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgetPassPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Olvidé mi contraseña",
                                        style: GoogleFonts.lato(
                                          color: FrutiaColors.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                          decorationColor: FrutiaColors.primary,
                                          decorationThickness: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40),
                              // Sign In Button
                              SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  width: size.width * 0.8,
                                  child: ElevatedButton(
                                    onPressed: signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FrutiaColors.primary,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      "Entrar",
                                      style: GoogleFonts.lato(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                         
                         /*
                              SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  width: size.width * 0.8,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      try {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Center(
                                            child: CircularProgressIndicator(
                                              color: FrutiaColors.primary,
                                            ),
                                          ),
                                        );

                                        final success = await _authService
                                            .signInWithGoogle();

                                        if (!mounted) return;
                                        Navigator.pop(
                                            context); // Cierra el diálogo de carga

                                        if (success) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    AuthCheckMain()),
                                          );
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        Navigator.pop(
                                            context); // Cierra el diálogo de carga
                                        showErrorSnackBar(
                                            "Error al iniciar sesión con Google");
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(
                                          color: FrutiaColors.primary,
                                          width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icons/google.png',
                                          height: 24,
                                          width: 24,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.account_circle,
                                              color: FrutiaColors.primary,
                                              size: 24,
                                            );
                                          },
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Unirse con Google",
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: FrutiaColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              */
                              // Después del botón "Unirse con Google" (línea ~448)
                              SizedBox(height: 10),

// 🆕 Botón Unirse como Espectador
                              SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  width: size.width * 0.8,
                                  child: OutlinedButton(
                                    onPressed: () {
  Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SpectatorSessionsListPage(), // 👈 Primero a la lista
          ),
        );                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          FrutiaColors.warning.withOpacity(0.1),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(
                                          color: FrutiaColors.warning,
                                          width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.remove_red_eye_outlined,
                                          color: FrutiaColors.warning,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Unirse como Espectador",
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: FrutiaColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 40),

                              TextButton(
                                onPressed: widget.showLoginPage,
                                child: Text(
                                  "Crea tu cuenta",
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: FrutiaColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: FrutiaColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
