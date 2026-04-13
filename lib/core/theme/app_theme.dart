import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: TaroColors.seedPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: TaroColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: TaroColors.background,
          foregroundColor: TaroColors.gold,
        ),
        useMaterial3: true,
      );
}
