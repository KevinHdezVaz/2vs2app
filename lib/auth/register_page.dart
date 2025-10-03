import 'package:Frutia/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:Frutia/auth/auth_check.dart';
import 'package:Frutia/auth/auth_service.dart';
import 'package:Frutia/auth/login_page.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/colors.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  bool isObscure = true;
  bool isObscureConfirm = true;
  String _fullPhoneNumber = '';

  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '237230625824-uhg81q3ro2at559t31bnorjqrlooe3lr.apps.googleusercontent.com',
  );

  final _affiliateCodeController = TextEditingController();

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
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _affiliateCodeController.dispose();
    super.dispose();
  }

  Future<void> signInWithGoogle() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary))),
    );

    try {
      final bool success = await _authService.signInWithGoogle();

      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthCheckMain()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorSnackBar('Error al unirse con Google. Inténtalo de nuevo.');
    }
  }

Future<void> signUp() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(FrutiaColors.primary),
      ),
    ),
  );

  try {
    final response = await _authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _fullPhoneNumber,
      password: _passwordController.text,
      affiliateCode: _affiliateCodeController.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Cierra el loading

    final userName = response['user']['name'];
    
    // Mostrar mensaje de bienvenida
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Bienvenido, $userName! Registro exitoso.'),
        backgroundColor: FrutiaColors.success,
      ),
    );

    // 🆕 Navegar a HomePage después del registro exitoso
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false, // Elimina todas las rutas anteriores
    );
    
  } on AuthException catch (e) {
    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: FrutiaColors.error,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocurrió un error inesperado. Por favor, inténtalo de nuevo.'),
        backgroundColor: FrutiaColors.error,
      ),
    );
  }
}

  bool validateRegister() {
    if (_passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      showErrorSnackBar("Las contraseñas no coinciden");
      return false;
    }

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      showErrorSnackBar("Por favor complete todos los campos obligatorios");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      showErrorSnackBar("Correo electrónico inválido");
      return false;
    }
    if (_nameController.text.contains(RegExp(r'[^a-zA-Z\s]'))) {
      showErrorSnackBar("El nombre solo debe contener letras");
      return false;
    }
    if (_passwordController.text.length < 6) {
      showErrorSnackBar("La contraseña debe tener al menos 6 caracteres");
      return false;
    }

    return true;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              FrutiaColors.accent    // Lime
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Contenido principal
              Column(
                children: [
                  AppBar(
                    title: const Text("Registro"),
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginPage(showLoginPage: widget.showLoginPage),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 20.0),
                          child: Card(
                            elevation: 20,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              height: size.height * 0.75,
                              width: size.width * 0.9,
                              padding: EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 20),
                                    // Welcome Text
                                    Text(
                                      "Bienvenido, Completa tu registro.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lato(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: FrutiaColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    // Name TextField
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: TextField(
                                        cursorColor: FrutiaColors.primary,
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.secondaryText,
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          labelText: "Nombre completo",
                                          labelStyle: TextStyle(
                                              color: FrutiaColors.primaryText),
                                          prefixIcon: Icon(
                                            Icons.person,
                                            color: FrutiaColors.primary,
                                          ),
                                          filled: true,
                                          fillColor:
                                              FrutiaColors.primaryBackground,
                                        ),
                                        style:
                                            TextStyle(color: FrutiaColors.primaryText),
                                      ),
                                    ),

                                    SizedBox(height: 20),
                                    // Email TextField
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: TextField(
                                        cursorColor: FrutiaColors.primary,
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.secondaryText,
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          labelText: "Correo electrónico",
                                          labelStyle: TextStyle(
                                              color: FrutiaColors.primaryText),
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: FrutiaColors.primary,
                                          ),
                                          filled: true,
                                          fillColor:
                                              FrutiaColors.primaryBackground,
                                        ),
                                        style:
                                            TextStyle(color: FrutiaColors.primaryText),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    // Phone Field con selector de país
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: IntlPhoneField(
                                        decoration: InputDecoration(
                                          labelText: 'Número de teléfono',
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.secondaryText,
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor:
                                              FrutiaColors.primaryBackground,
                                          labelStyle: TextStyle(
                                              color: FrutiaColors.primaryText),
                                        ),
                                        initialCountryCode: 'MX',
                                        onChanged: (phone) {
                                          setState(() {
                                            _fullPhoneNumber =
                                                phone.completeNumber;
                                          });
                                        },
                                        validator: (phoneNumber) {
                                          if (phoneNumber == null ||
                                              phoneNumber.number.isEmpty) {
                                            return 'Por favor ingresa un número';
                                          }
                                          if (!phoneNumber.isValidNumber()) {
                                            return 'El número de teléfono no es válido para el país seleccionado.';
                                          }
                                          return null;
                                        },
                                        style:
                                            TextStyle(color: FrutiaColors.primaryText),
                                        cursorColor: FrutiaColors.primary,
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.secondaryText,
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          labelText: "Contraseña",
                                          labelStyle: TextStyle(
                                              color: FrutiaColors.primaryText),
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
                                          fillColor:
                                              FrutiaColors.primaryBackground,
                                        ),
                                        style:
                                            TextStyle(color: FrutiaColors.primaryText),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    // Confirm Password TextField
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: TextField(
                                        cursorColor: FrutiaColors.primary,
                                        controller: _confirmPasswordController,
                                        obscureText: isObscureConfirm,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.secondaryText,
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: FrutiaColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          labelText: "Confirmar Contraseña",
                                          labelStyle: TextStyle(
                                              color: FrutiaColors.primaryText),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color: FrutiaColors.primary,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                isObscureConfirm =
                                                    !isObscureConfirm;
                                              });
                                            },
                                            icon: Icon(
                                              isObscureConfirm
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: FrutiaColors.primary,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor:
                                              FrutiaColors.primaryBackground,
                                        ),
                                        style:
                                            TextStyle(color: FrutiaColors.primaryText),
                                      ),
                                    ),
 
                                    SizedBox(height: 40),

                                    // Sign Up Button
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: Container(
                                        width: size.width * 0.8,
                                        child: ElevatedButton(
                                          onPressed: signUp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                FrutiaColors.primary,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 8,
                                          ),
                                          child: Text(
                                            "Crea tu cuenta",
                                            style: GoogleFonts.inter(
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
                                          onPressed: () => signInWithGoogle(),
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            side: BorderSide(
                                                color: FrutiaColors.primary,
                                                width: 1.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                errorBuilder: (context, error,
                                                    stackTrace) {
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
                                                style: GoogleFonts.inter(
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
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}