// lib/auth/auth_check_main.dart

import 'package:Frutia/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:Frutia/auth/auth_page_check.dart';
 import 'package:Frutia/services/storage_service.dart';

// 1. Convierte el widget a StatefulWidget
class AuthCheckMain extends StatefulWidget {
  const AuthCheckMain({super.key});

  @override
  State<AuthCheckMain> createState() => _AuthCheckMainState();
}

class _AuthCheckMainState extends State<AuthCheckMain> {
  // 2. Declara una variable para guardar la future
  late Future<String?> _checkTokenFuture;

  @override
  void initState() {
    super.initState();
    // 3. Llama a tu función UNA SOLA VEZ aquí y asigna la future
    _checkTokenFuture = StorageService().getToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      // 4. Usa la variable que no cambia en cada reconstrucción
      future: _checkTokenFuture,
      builder: (context, snapshot) {
        // Esta lógica ya estaba correcta y no necesita cambios
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        return const AuthPageCheck();
      },
    );
  }
}
