import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A text widget that fades + slides in dramatically.
class DramaticText extends StatefulWidget {
  const DramaticText({
    super.key,
    required this.text,
    this.fontSize = 30,
    this.delay = Duration.zero,
    this.color,
    this.fontWeight = FontWeight.w300,
    this.italic = false,
    this.letterSpacing = 0.5,
    this.height = 1.6,
  });

  final String text;
  final double fontSize;
  final Duration delay;
  final Color? color;
  final FontWeight fontWeight;
  final bool italic;
  final double letterSpacing;
  final double height;

  @override
  State<DramaticText> createState() => _DramaticTextState();
}

class _DramaticTextState extends State<DramaticText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideUp,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            fontStyle: widget.italic ? FontStyle.italic : FontStyle.normal,
            color: widget.color ?? TaroColors.gold,
            height: widget.height,
            letterSpacing: widget.letterSpacing,
          ),
        ),
      ),
    );
  }
}

/// A simple fade-in widget with optional delay.
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
