import 'package:flutter/material.dart';
import 'package:genui/genui.dart' show GenUiSurface, GenUiHost;

import '../../../../core/constants/app_colors.dart';
import '../../models/tarot_message.dart';

class MessageListWidget extends StatelessWidget {
  const MessageListWidget({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isProcessing,
    required this.host,
    required this.buildPulsingDots,
  });

  final List<TarotMessage> messages;
  final ScrollController scrollController;
  final bool isProcessing;
  final GenUiHost? host;
  final Widget Function() buildPulsingDots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (messages.isEmpty && !isProcessing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nights_stay_outlined, color: TaroColors.gold.withAlpha(60), size: 28),
            const SizedBox(height: 12),
            CircularProgressIndicator(color: TaroColors.gold.withAlpha(80), strokeWidth: 1.5),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index >= messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(Icons.nights_stay_outlined, size: 14, color: TaroColors.violet.withAlpha(120)),
                const SizedBox(width: 8),
                buildPulsingDots(),
              ],
            ),
          );
        }
        final msg = messages[index];
        if (msg.surfaceId != null) {
          // Merge OracleMessage visually into preceding TarotCard
          final prev = index > 0 ? messages[index - 1] : null;
          final isOracleAfterCard = msg.componentName == 'OracleMessage' &&
              prev?.componentName == 'TarotCard';
          return Padding(
            padding: EdgeInsets.only(
              top: isOracleAfterCard ? 0 : 6,
              bottom: 6,
            ),
            child: host != null
                ? GenUiSurface(host: host!, surfaceId: msg.surfaceId!)
                : const SizedBox.shrink(),
          );
        }
        // User message — gold glass bubble, right-aligned
        if (msg.isUser) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TaroColors.gold.withAlpha(25),
                    TaroColors.gold.withAlpha(12),
                  ],
                ),
                border: Border.all(color: TaroColors.gold.withAlpha(40)),
              ),
              child: Text(msg.text ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(220),
                    height: 1.4,
                  )),
            ),
          );
        }
        // Oracle message — star icon + italic text
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(Icons.nights_stay_outlined,
                    size: 14, color: TaroColors.violet.withAlpha(140)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(msg.text ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(190),
                  height: 1.6,
                  letterSpacing: 0.2,
                ))),
            ],
          ),
        );
      },
    );
  }
}