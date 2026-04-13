import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    this.onFlip,
    this.isFlipped = false,
    this.size = const Size(100, 150),
  });

  final Widget front;
  final VoidCallback? onFlip;
  final bool isFlipped;
  final Size size;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    _controller.addListener(() {
      if (_controller.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
    if (widget.isFlipped) {
      _controller.value = 1.0;
      _showFront = true;
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped && !oldWidget.isFlipped) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isFlipped ? null : widget.onFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBack = _animation.value < 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack ? _buildBack() : _buildFront(),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: widget.size.width,
      height: widget.size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D1B69),
            Color(0xFF1A0A2E),
          ],
        ),
        border: Border.all(color: TaroColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TaroColors.gold.withAlpha(40),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: TaroColors.gold.withAlpha(180), size: 28),
            const SizedBox(height: 4),
            Text(
              '\u2726',
              style: TextStyle(
                color: TaroColors.gold.withAlpha(120),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: widget.front,
      ),
    );
  }
}
