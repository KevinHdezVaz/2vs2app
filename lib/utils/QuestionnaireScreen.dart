import 'package:flutter/material.dart';

class QuestionnaireScreen extends StatelessWidget {
  final Widget child;
  const QuestionnaireScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: child,
    );
  }
}
