import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionnaireTitle extends StatelessWidget {
  final String title;
  final bool isSub;

  const QuestionnaireTitle(
      {super.key, required this.title, this.isSub = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSub ? 12 : 24, top: isSub ? 24 : 0),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: isSub ? 18 : 28,
          fontWeight: isSub ? FontWeight.w600 : FontWeight.bold,
          color: FrutiaColors.primaryText,
        ),
      ),
    );
  }
}
