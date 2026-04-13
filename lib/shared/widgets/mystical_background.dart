import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A decorative background with subtle constellation dots and connecting lines.
class MysticalBackground extends StatelessWidget {
  const MysticalBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: TaroColors.backgroundGradient),
      child: CustomPaint(
        painter: _ConstellationPainter(),
        child: child,
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Fixed seed for consistent pattern
    final starPaint = Paint()..color = TaroColors.gold.withAlpha(13); // 5%
    final linePaint = Paint()
      ..color = TaroColors.gold.withAlpha(8)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Generate star positions
    final stars = <Offset>[];
    for (var i = 0; i < 60; i++) {
      stars.add(Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      ));
    }

    // Draw stars
    for (final star in stars) {
      final radius = 0.5 + rng.nextDouble() * 1.5;
      canvas.drawCircle(star, radius, starPaint);
    }

    // Draw connecting lines between nearby stars
    for (var i = 0; i < stars.length; i++) {
      for (var j = i + 1; j < stars.length; j++) {
        final dist = (stars[i] - stars[j]).distance;
        if (dist < 120 && rng.nextDouble() > 0.6) {
          canvas.drawLine(stars[i], stars[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A glass-morphism container with configurable appearance.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.borderColor,
    this.gradient,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient ?? TaroColors.surfaceGradient,
        border: Border.all(
          color: borderColor ?? TaroColors.glassBorder,
          width: 1,
        ),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!, blurRadius: 20, spreadRadius: -2)]
            : null,
      ),
      child: child,
    );
  }
}
