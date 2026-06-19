import 'package:flutter/material.dart';

class AppColors {
  static const Color flipkartBlue = Color(0xFF2874F0);
  static const Color flipkartYellow = Color(0xFFFFE500);
  static const Color background = Color(0xFFF1F3F6);
  static const Color darkNavy = Color(0xFF172337);
  
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF878787);
  
  static const Color emeraldGreen = Color(0xFF388E3C);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFF57C00);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.flipkartBlue,
        primary: AppColors.flipkartBlue,
        secondary: AppColors.flipkartYellow,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.flipkartBlue,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.flipkartYellow,
          foregroundColor: AppColors.flipkartBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.flipkartBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
