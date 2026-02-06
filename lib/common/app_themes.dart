import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    fontFamily: "Inter",
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.white,
    brightness: Brightness.light,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(),
  );

  static final darkTheme = ThemeData(
    fontFamily: "Inter",
    primaryColor: AppColors.accent,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.gray,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.gray,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.gray,
        systemNavigationBarColor: AppColors.gray,
      ),
      titleTextStyle: AppTypography.headline5SemiBold.copyWith(
        color: AppColors.white,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.gray60),
        borderRadius: BorderRadius.circular(AppSpacing.twelve),
      ),
      outlineBorder: BorderSide(color: AppColors.error),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(AppSpacing.twelve),
      ),
      filled: false,
      fillColor: AppColors.gray60.withAlpha(200),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.twelve),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.error),
        borderRadius: BorderRadius.circular(AppSpacing.twelve),
      ),
      errorMaxLines: 1,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.ten,
        vertical: AppSpacing.five,
      ),
      hintStyle: AppTypography.headline1Regular.copyWith(
        color: AppColors.gray40,
      ),
    ),
    useMaterial3: true,
  );
}
