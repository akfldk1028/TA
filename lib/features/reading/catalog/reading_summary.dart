import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/tts/widgets/tts_button.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['ReadingSummary']),
    'title': S.string(
      description: 'Summary title, e.g. "Your Reading Summary".',
    ),
    'summary': S.string(
      description:
          'The holistic interpretation weaving all cards together. 3-6 sentences.',
    ),
    'advice': S.string(
      description: 'A short piece of actionable advice. 1-2 sentences.',
    ),
  },
  required: ['component', 'summary'],
);

final readingSummary = CatalogItem(
  name: 'ReadingSummary',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final title = data['title']?.toString() ?? 'Reading Summary';
    final summary = data['summary']?.toString() ?? '';
    final advice = data['advice']?.toString();

    return _ReadingSummaryWidget(
      title: title,
      summary: summary,
      advice: advice,
    );
  },
);

class _ReadingSummaryWidget extends StatelessWidget {
  const _ReadingSummaryWidget({
    required this.title,
    required this.summary,
    this.advice,
  });

  final String title;
  final String summary;
  final String? advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TaroColors.gold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: TaroColors.gold),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TaroColors.gold,
                  ),
                ),
              ],
            ),
            Divider(color: TaroColors.gold.withAlpha(64), height: 24),
            Text(summary, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TtsButton(
                text: '$summary${advice != null ? '\n$advice' : ''}',
                showLabel: true,
              ),
            ),
            if (advice != null && advice!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TaroColors.gold.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 20, color: TaroColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advice!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

