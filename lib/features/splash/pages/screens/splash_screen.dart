import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../router/routes.dart';
import '../../../../shared/widgets/mystical_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleUp;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _scaleUp = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _glowPulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) context.go(Routes.menu);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: MysticalBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _scaleUp.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celestial eye symbol with radial glow
                AnimatedBuilder(
                  animation: _glowPulse,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TaroColors.gold.withAlpha((40 * _glowPulse.value).round()),
                            TaroColors.violet.withAlpha((15 * _glowPulse.value).round()),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: TaroColors.gold.withAlpha((20 * _glowPulse.value).round()),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.visibility_rounded,
                        color: TaroColors.gold,
                        size: 52,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'splash.title'.tr(),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontFamily: 'NotoSerifKR',
                    color: TaroColors.gold,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 6,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 60,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        TaroColors.gold.withAlpha(120),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'splash.subtitle'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: TaroColors.violet.withAlpha(180),
                    letterSpacing: 3,
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 56),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: TaroColors.gold.withAlpha(80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
