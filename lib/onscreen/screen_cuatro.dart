import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Frutia/auth/auth_check.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

import 'constants2.dart';

class OnBoardingCuatro extends StatefulWidget {
  final PageController pageController;

  const OnBoardingCuatro({Key? key, required this.pageController})
      : super(key: key);

  @override
  _OnBoardingCuatroState createState() => _OnBoardingCuatroState();
}

class _OnBoardingCuatroState extends State<OnBoardingCuatro> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Initialize the video controller
    _videoController = VideoPlayerController.asset(
      'assets/images/videoFrutiaProgreso.mp4',
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _videoController.setLooping(true); // Set video to loop
          _videoController.setVolume(0.0); // Mute the video
          _videoController.play(); // Start playing automatically
        }
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playButtonSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sonidos/sonido2.mp3'));
    } catch (e) {
      print('Error al reproducir sonido: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark;
    }

    Color fondo = isDarkMode(context) ? Colors.white : Colors.black;

    Size size = MediaQuery.of(context).size;

    Widget FeatureItem(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget BenefitItem(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Esto centra el Row completo
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign
                    .center, // Esto centra el texto dentro del Expanded
                style: const TextStyle(
                  fontSize: 19,
                  color: Colors.black,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondoPantalla1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Contenido principal (título y lista) en la parte superior
              Positioned(
                top: size.height * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Este es el primer paso hacia el cambio que mereces",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 32,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BenefitItem("🌟 Y no estarás solo en el camino"),
                            BenefitItem("🍓 Frutia te acompaña en cada paso"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Video en la parte inferior, reemplazando la imagen
              Positioned(
                bottom: size.height * 0.10,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipOval(
                    child: Container(
                      height: 300,
                      width: 350,
                      color:
                          Colors.black, // Fondo negro mientras carga el video
                      child: _isInitialized
                          ? VideoPlayer(_videoController)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Indicadores de página
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageIndicator(false),
                    const SizedBox(width: 8),
                    _buildPageIndicator(false),
                    const SizedBox(width: 8),
                    _buildPageIndicator(false),
                    const SizedBox(width: 8),
                    _buildPageIndicator(true),
                  ],
                ),
              ),

              // Botón de acción
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  onPressed: () async {
                    // Reproducir sonido y vibrar
                    await _playButtonSound();
                    await _storeOnboardInfo();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthCheckMain(),
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),

              // Botón "Omitir"
              Padding(
                padding:
                    EdgeInsets.only(top: appPadding * 2, right: appPadding),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () async {
                      await _storeOnboardInfo();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthCheckMain(),
                        ),
                      );
                    },
                    child: Text(
                      "OMITIR",
                      style: TextStyle(
                        color: fondo,
                        fontSize: 20.0,
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

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.black87 : Colors.grey[400],
        border: Border.all(
          color: Colors.black87,
          width: 1,
        ),
      ),
    );
  }

  Future<void> _storeOnboardInfo() async {
    print("Shared pref called");
    int isViewed = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onBoard', isViewed);
    print(prefs.getInt('onBoard'));
  }
}
