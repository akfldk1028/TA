import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../tts_service.dart';

/// 공통 TTS 재생 버튼.
/// [showLabel] true면 "듣기"/"중지" 텍스트 표시 (ReadingSummary용).
class TtsButton extends StatelessWidget {
  const TtsButton({
    super.key,
    required this.text,
    this.showLabel = false,
    this.iconSize = 18,
  });

  final String text;
  final bool showLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tts = TtsService.instance;
    final id = text.hashCode.toString();

    return ValueListenableBuilder<bool>(
      valueListenable: tts.isSpeaking,
      builder: (context, speaking, _) {
        final isPlaying = tts.isPlayingId(id);
        final color = TaroColors.gold.withAlpha(isPlaying ? 220 : 120);

        return GestureDetector(
          onTap: () => tts.speak(text, id: id),
          child: showLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_rounded,
                      size: iconSize - 2,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPlaying ? '\u25a0' : '\u25b6',
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                )
              : Icon(
                  isPlaying
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_rounded,
                  size: iconSize,
                  color: color,
                ),
        );
      },
    );
  }
}