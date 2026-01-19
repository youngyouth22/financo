import 'package:flutter/material.dart';

class AppColors {
  // Primary color
  static Color get primary => const Color(0xff5E00F5);
  static Color get primary500 => const Color(0xff7722FF);
  static Color get primary20 => const Color(0xff924EFF);
  static Color get primary10 => const Color(0xffAD7BFF);
  static Color get primary5 => const Color(0xffC9A7FF);
  static Color get primary0 => const Color(0xffE4D3FF);

  //  Accent primary color
  static Color get accent => const Color(0xffFF7966);
  static Color get accentP50 => const Color(0xffFFA699);
  static Color get accentP0 => const Color(0xffFFD2CC);

  // Accent Secondary
  static Color get accentS => const Color(0xff00FAD9);
  static Color get accentS50 => const Color(0xff7DFFEE);

  // Grayscale color
  static Color get gray => const Color(0xff0E0E12);
  static Color get gray80 => const Color(0xff1C1C23);
  static Color get gray70 => const Color(0xff353542);
  static Color get gray60 => const Color(0xff4E4E61);
  static Color get gray50 => const Color(0xff666680);
  static Color get gray40 => const Color(0xff83839C);
  static Color get gray30 => const Color(0xffA2A2B5);
  static Color get gray20 => const Color(0xffC1C1CD);
  static Color get gray10 => const Color(0xffE0E0E6);
  static Color get border => const Color(0xffCFCFFC);
  static Color get white => Colors.white;
  static Color get card => const Color(0xff2A2A30);

  // Status color
  static Color get success => const Color(0xff00D16C);
  static Color get error => const Color(0xffFF4D4D);
  static Color get warning => const Color(0xffFFAA00);

  // Gradient color
  static Gradient get primaryGradient => LinearGradient(
        colors: [
          AppColors.accent,
          Color.fromARGB(255, 249, 132, 116),
          AppColors.accent,
        ],
        begin: Alignment.topRight,
      );

  // disable button gradient
  static Gradient get grayGradientDisabled => LinearGradient(
        colors: [
          AppColors.gray30.withAlpha(220),
          AppColors.gray30,
        ],
        begin: Alignment.topRight,
      );

  static Gradient get googleGradient => LinearGradient(
        colors: [
          AppColors.white.withAlpha(220),
          AppColors.white,
        ],
        begin: Alignment.topRight,
      );

  static Gradient get blackGradient => LinearGradient(
        colors: [
          AppColors.gray70,
          AppColors.gray70.withAlpha(220),
        ],
        begin: Alignment.topRight,
      );
}
