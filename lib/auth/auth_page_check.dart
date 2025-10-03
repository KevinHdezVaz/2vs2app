import 'package:flutter/material.dart';
import 'package:Frutia/auth/login_page.dart';
import 'package:Frutia/auth/register_page.dart';

class AuthPageCheck extends StatefulWidget {
  const AuthPageCheck({super.key});

  @override
  State<AuthPageCheck> createState() => _AuthPageCheckState();
}

class _AuthPageCheckState extends State<AuthPageCheck> {
  bool showLoginPage = true;

  void toggelScreen() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showLoginPage: toggelScreen);
    } else {
      return RegisterPage(
        showLoginPage: toggelScreen,
      );
    }
  }
}
