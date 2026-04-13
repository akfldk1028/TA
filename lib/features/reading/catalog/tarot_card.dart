import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/tarot_card_data.dart';
import '../../../shared/widgets/card_face.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['TarotCard']),
    'cardName': S.string(
      description: 'The name of the tarot card, e.g. "The Fool", "Ten of Cups".',
    ),
    'position': S.string(
      description:
          'The position meaning in the spread, e.g. "Past", "Present", "Future".',
    ),
    'isReversed': S.boolean(
      description: 'Whether the card is reversed (upside-down).',
    ),
    'interpretation': S.string(
      description:
          'The interpretation of this card in context of the question and position. 2-4 sentences.',
    ),
  },
  required: ['component', 'cardName', 'position', 'interpretation'],
);

final tarotCard = CatalogItem(
  name: 'TarotCard',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return _TarotCardWidget(
      cardName: data['cardName']?.toString() ?? '',
      position: data['position']?.toString() ?? '',
      isReversed: data['isReversed'] as bool? ?? false,
      interpretation: data['interpretation']?.toString() ?? '',
    );
  },
);

class _TarotCardWidget extends StatefulWidget {
  const _TarotCardWidget({
    required this.cardName,
    required this.position,
    required this.isReversed,
    required this.interpretation,
  });

  final String cardName;
  final String position;
  final bool isReversed;
  final String interpretation;

  @override
  State<_TarotCardWidget> createState() => _TarotCardWidgetState();
}

class _TarotCardWidgetState extends State<_TarotCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  static const _majorArcana = {
    'The Fool', 'The Magician', 'The High Priestess', 'The Empress',
    'The Emperor', 'The Hierophant', 'The Lovers', 'The Chariot',
    'Strength', 'The Hermit', 'Wheel of Fortune', 'Justice',
    'The Hanged Man', 'Death', 'Temperance', 'The Devil',
    'The Tower', 'The Star', 'The Moon', 'The Sun',
    'Judgement', 'The World',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMajor = _majorArcana.contains(widget.cardName);
    final cardData = TarotDeck.instance?.findByName(widget.cardName);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: Opacity(opacity: _fadeIn.value, child: child),
        );
      },
      child: Card(
        elevation: 4,
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isMajor
                ? TaroColors.gold
                : theme.colorScheme.outline.withAlpha(80),
            width: isMajor ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card image + name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card thumbnail
                  if (cardData != null)
                    CardFace(
                      card: cardData,
                      isReversed: widget.isReversed,
                      size: const Size(52, 78),
                    )
                  else
                    Container(
                      width: 52, height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: TaroColors.gold.withAlpha(20),
                        border: Border.all(color: TaroColors.gold.withAlpha(60)),
                      ),
                      child: const Icon(Icons.style, color: TaroColors.gold, size: 22),
                    ),
                  const SizedBox(width: 12),
                  // Position + name + reversed badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TaroColors.gold.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.position,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: TaroColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.cardName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.isReversed) ...[
                          const SizedBox(height: 2),
                          Text(
                            'common.reversed'.tr(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.redAccent.shade100,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interpretation
              Text(
                widget.interpretation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
