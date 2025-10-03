import 'dart:async';
import 'package:Frutia/providers/ShoppingProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Frutia/onscreen/SplashScreen.dart';
import 'package:Frutia/services/BonoService.dart';
import 'package:Frutia/services/settings/theme_data.dart';
import 'package:Frutia/services/settings/theme_provider.dart';
import 'package:Frutia/utils/constantes.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
 
// Llaves globales que pueden ser útiles en toda la app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final BonoService _bonoService = BonoService(baseUrl: baseUrl);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int isviewed = prefs.getInt('onBoard') ?? 1;

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
         child: MyApp(isviewed: isviewed),

    ),
  );
}

// MyApp puede volver a ser un StatelessWidget, ya que no necesita manejar el estado de los deep links.
class MyApp extends StatelessWidget {
  final int isviewed;

  const MyApp({super.key, required this.isviewed});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'US'),
          ],
          locale: const Locale('es', 'ES'),
          themeMode: themeProvider.currentTheme,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: SplashScreen(isviewed: isviewed),
          
        );
      },
    );
  }
}
