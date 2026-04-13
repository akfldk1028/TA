import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import '../../../core/config/ai_config.dart';
import '../../../main.dart' show talker;
import 'ai_client.dart';

/// ContentGenerator that bridges dartantic_ai to GenUI.
///
/// Parses A2UI JSON blocks from the LLM text stream and emits them
/// as A2uiMessages incrementally during streaming. Non-JSON text is
/// emitted after the stream completes.
class TaroContentGenerator implements ContentGenerator {
  TaroContentGenerator({
    required this.aiClient,
    required this.systemPrompt,
    this.onDrawCardsDetected,
    this.onSpokenTextDetected,
  });

  final AiClient aiClient;
  final String systemPrompt;
  final void Function(int count, List<String> positions, String context)? onDrawCardsDetected;
  /// Called with extracted spoken text from OracleMessage and TarotCard interpretations.
  final void Function(String text)? onSpokenTextDetected;

  final StreamController<A2uiMessage> _a2uiController =
      StreamController<A2uiMessage>.broadcast();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<ContentGeneratorError> _errorController =
      StreamController<ContentGeneratorError>.broadcast();
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);
  final List<dartantic.ChatMessage> _history = [];
  static const _tag = 'Transport';
  final Set<String> _knownSurfaceIds = {};
  final Map<String, String> _surfaceComponentNames = {};

  /// Maps surfaceId → primary component name (e.g. 'TarotCard', 'OracleMessage').
  Map<String, String> get surfaceComponentNames => _surfaceComponentNames;

  bool _initialized = false;
  bool _disposed = false;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    if (!_initialized) {
      _history.add(dartantic.ChatMessage.system(systemPrompt));
      _initialized = true;
    }

    final text = switch (message) {
      UserMessage m => m.parts.whereType<TextPart>().map((p) => p.text).join(),
      UserUiInteractionMessage m =>
        m.parts.whereType<TextPart>().map((p) => p.text).join(),
      _ => '',
    };
    if (text.isEmpty) return;

    _isProcessing.value = true;
    _history.add(dartantic.ChatMessage.user(text));

    try {
      final stream = aiClient.sendStream(text, history: List.of(_history));
      final buffer = StringBuffer();
      final emittedRanges = <(int, int)>[];

      // Safety timeout: entire request must complete within 90 seconds
      await Future(() async {
        await for (final chunk in stream) {
          if (chunk.isNotEmpty) {
            buffer.write(chunk);
            _tryEmitNewBlocks(buffer.toString(), emittedRanges);
          }
        }
      }).timeout(const Duration(seconds: 90));

      final responseText = buffer.toString();
      _history.add(dartantic.ChatMessage.model(responseText));
      _trimHistory();

      _emitRemainingText(responseText, emittedRanges);
    } on TimeoutException catch (e, st) {
      talker.warning('[$_tag] Request timed out after 90s');
      if (!_disposed) _errorController.add(ContentGeneratorError(e, st));
    } catch (e, st) {
      talker.error('[$_tag] Error generating content', e, st);
      if (!_disposed) _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Scans the buffer for newly completed JSON blocks and emits them
  /// incrementally during streaming.
  void _tryEmitNewBlocks(String text, List<(int, int)> emittedRanges) {
    // Fenced JSON blocks
    final fenceRegex = RegExp(r'```(?:json)?\s*(\{)', dotAll: true);
    for (final match in fenceRegex.allMatches(text)) {
      if (_isInRange(match.start, emittedRanges)) continue;
      final jsonStart = match.start + match.group(0)!.length - 1;
      final block = _extractBalancedBraces(text, jsonStart);
      if (block == null) continue;
      final closeFence = text.indexOf('```', jsonStart + block.length);
      if (closeFence == -1) continue;
      if (_tryEmitA2ui(block)) {
        emittedRanges.add((match.start, closeFence + 3));
      }
    }

    // Bare JSON blocks
    var i = 0;
    while (i < text.length) {
      if (_isInRange(i, emittedRanges)) {
        i++;
        continue;
      }
      if (text[i] == '{') {
        final block = _extractBalancedBraces(text, i);
        if (block != null &&
            (block.contains('surfaceUpdate') ||
                block.contains('createSurface') ||
                block.contains('beginRendering') ||
                block.contains('"components"'))) {
          if (_tryEmitA2ui(block)) {
            emittedRanges.add((i, i + block.length));
          }
          i += block.length;
          continue;
        }
      }
      i++;
    }
  }

  /// Emits remaining text (non-JSON) after streaming completes.
  /// If A2UI components were emitted, skip leftover text to avoid duplication.
  void _emitRemainingText(String responseText, List<(int, int)> emittedRanges) {
    if (emittedRanges.isNotEmpty) return; // A2UI handled it — no duplicate text

    final text = responseText.trim();
    if (text.isNotEmpty && !_disposed) {
      _textController.add(text);
    }
  }

  bool _isInRange(int index, List<(int, int)> ranges) {
    for (final (start, end) in ranges) {
      if (index >= start && index < end) return true;
    }
    return false;
  }

  bool _tryEmitA2ui(String jsonBlock) {
    try {
      final json = jsonDecode(jsonBlock) as Map<String, dynamic>;
      final message = A2uiMessage.fromJson(json);
      if (_disposed) return false;

      // Drop ReadingSummary and DrawCards before emitting — not shown in UI
      if (message is SurfaceUpdate) {
        final hasReadingSummary = message.components.any(
          (c) => c.componentProperties.containsKey('ReadingSummary'),
        );
        if (hasReadingSummary) {
          talker.info('[$_tag] Dropped ReadingSummary component');
          return true;
        }

        // DrawCards: fire callback only, don't show in UI
        final hasDrawCards = message.components.any(
          (c) => c.componentProperties.containsKey('DrawCards'),
        );
        if (hasDrawCards) {
          for (final comp in message.components) {
            final props = comp.componentProperties;
            if (props.containsKey('DrawCards')) {
              final dc = props['DrawCards'] as Map<String, dynamic>;
              onDrawCardsDetected?.call(
                dc['count'] as int? ?? 1,
                (dc['positions'] as List?)?.cast<String>() ?? ['additional'],
                dc['context'] as String? ?? 'additional',
              );
              break;
            }
          }
          talker.info('[$_tag] Dropped DrawCards component (callback only)');
          return true;
        }
      }

      _a2uiController.add(message);
      talker.info('[$_tag] Emitted A2UI message');
      if (message is SurfaceUpdate) {
        // Record primary component name for this surface
        for (final comp in message.components) {
          final keys = comp.componentProperties.keys;
          if (keys.isNotEmpty) {
            _surfaceComponentNames[message.surfaceId] = keys.first;
            break;
          }
        }

        // Extract spoken text from OracleMessage and TarotCard
        for (final comp in message.components) {
          final props = comp.componentProperties;
          if (props.containsKey('OracleMessage')) {
            final om = props['OracleMessage'] as Map<String, dynamic>;
            final text = om['text'] as String?;
            if (text != null && text.isNotEmpty) {
              onSpokenTextDetected?.call(text);
            }
          } else if (props.containsKey('TarotCard')) {
            final tc = props['TarotCard'] as Map<String, dynamic>;
            final interp = tc['interpretation'] as String?;
            if (interp != null && interp.isNotEmpty) {
              onSpokenTextDetected?.call(interp);
            }
          }
        }

        if (!_knownSurfaceIds.contains(message.surfaceId)) {
          _knownSurfaceIds.add(message.surfaceId);
          if (_disposed) return true;
          final rootId = message.components.isNotEmpty
              ? message.components.first.id
              : 'root';
          _a2uiController.add(BeginRendering(
            surfaceId: message.surfaceId,
            root: rootId,
            catalogId: 'taro-catalog',
          ));
        }
      }
      return true;
    } catch (e) {
      talker.warning('[$_tag] Failed to parse A2uiMessage: $e');
      return false;
    }
  }

  void _trimHistory() {
    if (_history.length > AiConfig.maxHistoryMessages + 1) {
      _history.removeRange(1, _history.length - AiConfig.maxHistoryMessages);
    }
  }

  /// Extracts a balanced brace block starting at position [start].
  String? _extractBalancedBraces(String text, int start) {
    if (start >= text.length || text[start] != '{') return null;

    var depth = 0;
    var inString = false;
    var escape = false;

    for (var i = start; i < text.length; i++) {
      final c = text[i];

      if (escape) {
        escape = false;
        continue;
      }
      if (c == '\\' && inString) {
        escape = true;
        continue;
      }
      if (c == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _a2uiController.close();
    _textController.close();
    _errorController.close();
    _isProcessing.dispose();
  }
}
