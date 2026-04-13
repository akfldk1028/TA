import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['DrawCards']),
    'count': S.integer(
      description: 'Number of cards to draw (1-3).',
      minimum: 1,
      maximum: 3,
    ),
    'reason': S.string(
      description: 'Why these cards should be drawn, e.g. "당신의 현재 상황을 더 깊이 들여다보겠습니다"',
    ),
    'positions': S.list(
      items: S.string(),
      description: 'Names for each card position, e.g. ["과거", "현재", "미래"]',
    ),
    'context': S.string(
      enumValues: ['initial', 'additional', 'new_topic'],
      description: 'When this draw happens in the reading flow.',
    ),
  },
  required: ['component', 'count', 'reason', 'positions', 'context'],
);

final drawCards = CatalogItem(
  name: 'DrawCards',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final positions = (data['positions'] as List<Object?>?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    return _DrawCardsWidget(
      count: (data['count'] as num?)?.toInt() ?? 1,
      reason: data['reason']?.toString() ?? '',
      positions: positions,
    );
  },
);

class _DrawCardsWidget extends StatefulWidget {
  const _DrawCardsWidget({
    required this.count,
    required this.reason,
    required this.positions,
  });

  final int count;
  final String reason;
  final List<String> positions;

  @override
  State<_DrawCardsWidget> createState() => _DrawCardsWidgetState();
}

class _DrawCardsWidgetState extends State<_DrawCardsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TaroColors.gold.withAlpha(50),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TaroColors.gold.withAlpha(12),
                TaroColors.background.withAlpha(200),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TaroColors.gold.withAlpha(60),
                      TaroColors.gold.withAlpha(15),
                    ],
                  ),
                  border: Border.all(
                    color: TaroColors.gold.withAlpha(80),
                  ),
                ),
                child: const Icon(
                  Icons.style,
                  size: 24,
                  color: TaroColors.gold,
                ),
              ),
              const SizedBox(height: 14),
              // Reason text
              Text(
                widget.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: TaroColors.gold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              // Draw instruction
              Text(
                '${widget.count}장의 카드를 뽑아주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TaroColors.gold.withAlpha(220),
                ),
              ),
              if (widget.positions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.positions.join(' · '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: TaroColors.gold.withAlpha(140),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
