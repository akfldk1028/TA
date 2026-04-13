import 'package:flutter/material.dart';

abstract final class TaroColors {
  // Primary
  static const Color gold = Color(0xFFD4AF37);
  static const Color background = Color(0xFF0D0520);
  static const Color backgroundLight = Color(0xFF1A0A2E);
  static const Color seedPurple = Color(0xFF4A148C);

  // Secondary / Tertiary
  static const Color violet = Color(0xFF7C4DFF);
  static const Color rose = Color(0xFFE8A0BF);
  static const Color surface = Color(0xFF1E1035);

  // Glass-morphism
  static const Color glass = Color(0x991E1035); // 60% opacity
  static const Color glassBorder = Color(0x40D4AF37); // 25% gold

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundLight],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1035), Color(0xFF140B28)],
  );
}
