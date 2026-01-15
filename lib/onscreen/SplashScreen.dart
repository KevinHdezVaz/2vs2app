import 'package:flutter/material.dart';
import 'package:Frutia/auth/auth_check.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final int isviewed;
  const SplashScreen({super.key, required this.isviewed});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loaderAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateAfterDelay();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _loaderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthCheckMain(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF061848), // Navy - 50%
              Color(0xFF061848), // Navy - continuación
              Color(0xFF004d4d), // Teal - 50%
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Content area (logo + text)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ajuste: Mover el logo un poco más arriba
                      const SizedBox(height: 20),

                      // Logo: PNG Image - 15% más grande (180 → 207)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildPickleballLogo(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 45),

                      // Title: PICKLE BRACKET (Oswald Italic)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'PICKLE\nBRACKET',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            fontSize: 43,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 0.9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tagline: open play leveled up! (Roboto Mono)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'open play leveled up!',
                          style: GoogleFonts.robotoMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: FrutiaColors.ElectricLime,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Footer: Loader
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 40,
                  bottom: 60,
                ),
                child: _buildAnimatedLoader(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logo: PNG Image - SIN sombra y 15% más grande
  Widget _buildPickleballLogo() {
    return ClipOval(
      child: Image.asset(
        'assets/icons/logoAppBueno.png',
        width: 207, // 180 * 1.15 = 207
        height: 207,
        fit: BoxFit.cover,
      ),
    );
  }

  // ✅ Animated Loader - EXACTO COMO EL HTML
  Widget _buildAnimatedLoader() {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _loaderAnimation,
            builder: (context, child) {
              final progress = _loaderAnimation.value;
              final totalWidth = constraints.maxWidth;

              // Calcular left y width exactamente como el CSS
              double leftPercent;
              double widthPercent;

              if (progress <= 0.5) {
                // 0% → 50%: left va de -100% a 0%, width va de 20% a 50%
                leftPercent = -1.0 + (progress * 2.0);
                widthPercent = 0.2 + (0.3 * (progress * 2.0));
              } else {
                // 50% → 100%: left va de 0% a 100%, width va de 50% a 20%
                leftPercent = (progress - 0.5) * 2.0;
                widthPercent = 0.5 - (0.3 * ((progress - 0.5) * 2.0));
              }

              final left = leftPercent * totalWidth;
              final width = widthPercent * totalWidth;

              return Stack(
                children: [
                  Positioned(
                    left: left,
                    child: Container(
                      width: width,
                      height: 6,
                      decoration: BoxDecoration(
                        color: FrutiaColors.ElectricLime,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: FrutiaColors.ElectricLime.withOpacity(0.6),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
