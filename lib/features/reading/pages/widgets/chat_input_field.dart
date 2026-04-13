import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.onMicTap,
    this.isListening = false,
  });

  final Function(String) onSend;
  final bool enabled;
  /// Called when mic button is tapped. null = hide mic button.
  final VoidCallback? onMicTap;
  /// Whether the mic is actively listening.
  final bool isListening;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final active = _hasText && widget.enabled;
    final showMic = !_hasText && widget.onMicTap != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TaroColors.background.withAlpha(200),
            TaroColors.background,
          ],
        ),
        border: Border(
          top: BorderSide(color: TaroColors.gold.withAlpha(20)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E1035), Color(0xFF140B28)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.isListening
                        ? TaroColors.gold.withAlpha(120)
                        : active
                            ? TaroColors.gold.withAlpha(60)
                            : TaroColors.gold.withAlpha(25),
                  ),
                  boxShadow: widget.isListening
                      ? [BoxShadow(color: TaroColors.gold.withAlpha(20), blurRadius: 16)]
                      : active
                          ? [BoxShadow(color: TaroColors.gold.withAlpha(8), blurRadius: 12)]
                          : null,
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled && !widget.isListening,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: widget.isListening
                        ? 'reading.listening'.tr()
                        : 'reading.inputHint'.tr(),
                    hintStyle: TextStyle(
                      color: widget.isListening
                          ? TaroColors.gold.withAlpha(140)
                          : TaroColors.gold.withAlpha(60),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (showMic) {
                  widget.onMicTap?.call();
                } else {
                  _handleSend();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (active || widget.isListening)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isListening
                              ? [const Color(0xFFE05555), const Color(0xFFC04040)]
                              : [const Color(0xFFD4AF37), const Color(0xFFB8962E)],
                        )
                      : null,
                  color: (active || widget.isListening) ? null : TaroColors.surface,
                  border: (active || widget.isListening)
                      ? null
                      : Border.all(color: TaroColors.gold.withAlpha(25)),
                  boxShadow: widget.isListening
                      ? [BoxShadow(color: const Color(0xFFE05555).withAlpha(60), blurRadius: 16)]
                      : active
                          ? [BoxShadow(color: TaroColors.gold.withAlpha(40), blurRadius: 12)]
                          : null,
                ),
                child: Icon(
                  showMic
                      ? (widget.isListening ? Icons.stop_rounded : Icons.mic_rounded)
                      : Icons.arrow_upward_rounded,
                  size: 22,
                  color: (active || widget.isListening)
                      ? Colors.white
                      : TaroColors.gold.withAlpha(80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
