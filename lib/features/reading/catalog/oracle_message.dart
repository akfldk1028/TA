import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/tts/widgets/tts_button.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['OracleMessage']),
    'text': S.string(
      description: 'The Oracle\'s message text. Use mystical, warm tone.',
    ),
  },
  required: ['component', 'text'],
);

final oracleMessage = CatalogItem(
  name: 'OracleMessage',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return _OracleMessageWidget(
      text: data['text']?.toString() ?? '',
    );
  },
);

class _OracleMessageWidget extends StatefulWidget {
  const _OracleMessageWidget({required this.text});

  final String text;

  @override
  State<_OracleMessageWidget> createState() => _OracleMessageWidgetState();
}

class _OracleMessageWidgetState extends State<_OracleMessageWidget>
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
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: TaroColors.gold.withAlpha(60),
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(200),
                height: 1.6,
              ),
            ),
            if (widget.text.length > 10) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TtsButton(text: widget.text),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

