import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111A2C);
  static const Color surfaceLight = Color(0xFF1E2A40);
  static const Color primary = Color(0xFFC89B3C);
  static const Color primaryLight = Color(0xFFF0E6D3);
  static const Color accent = Color(0xFF00D4FF);
  static const Color textPrimary = Color(0xFFF0E6D3);
  static const Color textSecondary = Color(0xFFA09B8C);
  static const Color victory = Color(0xFF28C76F);
  static const Color defeat = Color(0xFFEA5455);
  static const Color border = Color(0xFF463714);

  // Tier colors
  static const Map<String, Color> tierColors = {
    'IRON': Color(0xFF5A5A5A),
    'BRONZE': Color(0xFFA97142),
    'SILVER': Color(0xFFC0C0C0),
    'GOLD': Color(0xFFFFD700),
    'PLATINUM': Color(0xFF00BFA5),
    'EMERALD': Color(0xFF50C878),
    'DIAMOND': Color(0xFFB9F2FF),
    'MASTER': Color(0xFFB347D9),
    'GRANDMASTER': Color(0xFFE74C3C),
    'CHALLENGER': Color(0xFFF1C40F),
  };

  // Role colors
  static const Map<String, Color> roleColors = {
    'TOP': Color(0xFFE74C3C),
    'JUNGLE': Color(0xFF27AE60),
    'MID': Color(0xFFF39C12),
    'ADC': Color(0xFFC89B3C),
    'BOTTOM': Color(0xFFC89B3C),
    'SUPPORT': Color(0xFF3498DB),
    'UTILITY': Color(0xFF3498DB),
  };
}

class AppStrings {
  static const String appName = 'LoL Stats';
  static const String searchHint = 'Search summoner...';
  static const String noFavorites = 'No favorites yet';
  static const String noMatches = 'No matches found';
  static const String error = 'Something went wrong';
}

class AppSizes {
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
}
