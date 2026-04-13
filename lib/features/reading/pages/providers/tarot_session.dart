import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';

import '../../../../core/config/ai_config.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../models/reading_category.dart';
import '../../../../models/spread_type.dart';
import '../../prompts/prompt_builder.dart';
import '../../../../models/tarot_card_data.dart';
import '../../catalog/tarot_catalog.dart';
import '../../models/oracle_persona.dart';
import '../../models/tarot_message.dart';
import '../../../../main.dart' show talker;
import '../../services/ai_client.dart';
import '../../services/transport.dart';

enum ConsultationPhase { question, personaPick, picking, reading, chatting }
enum ReadingMode { manual, auto }

final tarotSessionProvider =
    ChangeNotifierProvider.autoDispose<TarotSession>((ref) {
  return TarotSession();
});

class TarotSession extends ChangeNotifier {
  TarotSession({AiClient? aiClient}) {
    _client = aiClient ??
        (AiConfig.useEdgeFunction
            ? RetryAiClient(
                primary: EdgeFunctionAiClient(),
                fallback: GeminiAiClient(),
              )
            : GeminiAiClient());
  }

  late final AiClient _client;
  TaroContentGenerator? _contentGenerator;
  A2uiMessageProcessor? _processor;
  GenUiConversation? _conversation;
  bool _initialized = false;

  static const _tag = 'TarotSession';

  // --- Phase transition guard ---
  static const _validTransitions = <ConsultationPhase, Set<ConsultationPhase>>{
    ConsultationPhase.question: {ConsultationPhase.personaPick},
    ConsultationPhase.personaPick: {ConsultationPhase.picking},
    ConsultationPhase.picking: {ConsultationPhase.reading},
    ConsultationPhase.reading: {ConsultationPhase.chatting, ConsultationPhase.picking},
    ConsultationPhase.chatting: {ConsultationPhase.question, ConsultationPhase.picking},
  };

  void _setPhase(ConsultationPhase next) {
    if (_phase == next) return;
    final allowed = _validTransitions[_phase];
    if (allowed == null || !allowed.contains(next)) {
      talker.warning('[$_tag] Invalid phase transition: $_phase → $next');
      return;
    }
    talker.info('[$_tag] Phase: $_phase → $next');
    _phase = next;
    notifyListeners();
  }

  // --- Consultation state ---
  ConsultationPhase _phase = ConsultationPhase.question;
  ConsultationPhase get phase => _phase;

  ReadingCategory _category = ReadingCategory.general;
  ReadingCategory get category => _category;

  int _requestedDrawCount = 0;
  int get requestedDrawCount => _requestedDrawCount;
  List<String> _requestedPositions = [];
  List<String> get requestedPositions => List.unmodifiable(_requestedPositions);

  String _drawContext = 'initial';
  String get drawContext => _drawContext;

  /// Number of cards in the original spread (before additional draws).
  int? _initialCardCount;
  int? get initialCardCount => _initialCardCount;

  String? _userQuestion;
  String get userQuestion => _userQuestion ?? '';

  OraclePersona _persona = OraclePersona.mystic;
  OraclePersona get persona => _persona;
  set persona(OraclePersona value) {
    _persona = value;
    notifyListeners();
  }

  String _locale = 'en';

  final List<DrawnCard> _allDrawnCards = [];
  List<DrawnCard> get allDrawnCards => List.unmodifiable(_allDrawnCards);

  SpreadType? _currentSpread;
  SpreadType? get currentSpread => _currentSpread;

  int _activeCardIndex = -1;
  int get activeCardIndex => _activeCardIndex;

  int _revealedCount = 0;

  ReadingMode _readingMode = ReadingMode.manual;
  ReadingMode get readingMode => _readingMode;
  bool _autoReading = false;
  bool get isAutoReading => _autoReading;
  final List<String> _pendingSpokenTexts = [];

  /// Set reading mode before starting card interpretations.
  void setReadingMode(ReadingMode mode) {
    _readingMode = mode;
    notifyListeners();
  }

  /// Start auto-reading: reveals and interprets cards one by one.
  /// [onReveal] flips the card in the UI.
  /// [onSpeak] plays TTS and returns when finished.
  Future<void> startAutoReading({
    required void Function(int cardIndex) onReveal,
    required Future<void> Function(String text) onSpeak,
  }) async {
    _autoReading = true;
    notifyListeners();

    for (var i = 0; i < _allDrawnCards.length && _autoReading; i++) {
      if (_revealedCount > i) continue;

      _pendingSpokenTexts.clear();
      onReveal(i);
      await interpretCard(i);

      // Speak all collected texts (TarotCard interpretation + OracleMessage)
      for (final text in _pendingSpokenTexts) {
        if (!_autoReading) break;
        await onSpeak(text);
      }

      // Pause between cards
      if (_autoReading && i < _allDrawnCards.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _autoReading = false;
    notifyListeners();
  }

  void stopAutoReading() {
    _autoReading = false;
    notifyListeners();
  }

  // --- GenUI state ---
  GenUiHost? get host => _conversation?.host;
  bool get isProcessing => _conversation?.isProcessing.value ?? false;

  final List<TarotMessage> _messages = [];
  List<TarotMessage> get messages => List.unmodifiable(_messages);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final systemPrompt = PromptBuilder.build(
      category: _category,
      spread: _currentSpread ?? SpreadType.generalReading,
      persona: _persona,
    );

    _contentGenerator = TaroContentGenerator(
      aiClient: _client,
      systemPrompt: systemPrompt,
      onSpokenTextDetected: (text) {
        _pendingSpokenTexts.add(text);
      },
      onDrawCardsDetected: (count, positions, context) {
        _requestedDrawCount = count;
        _requestedPositions = positions;
        _drawContext = context;
        if (context == 'new_topic') {
          _allDrawnCards.clear();
          _revealedCount = 0;
          _initialCardCount = null;
          // New topic → full flow: chatting → question
          _setPhase(ConsultationPhase.question);
        } else {
          // Additional → straight to picking
          _setPhase(ConsultationPhase.picking);
        }
      },
    );
    _processor = A2uiMessageProcessor(catalogs: [taroCatalog]);
    _conversation = GenUiConversation(
      contentGenerator: _contentGenerator!,
      a2uiMessageProcessor: _processor!,
      onSurfaceAdded: _onSurfaceAdded,
      onSurfaceUpdated: _onSurfaceUpdated,
      onTextResponse: _onTextResponse,
      onError: _onError,
    );

    _conversation!.isProcessing.addListener(notifyListeners);
    _conversation!.conversation.addListener(notifyListeners);
    _initialized = true;
  }

  // --- Public API ---

  /// Start consultation — no AI call, just set up state.
  void startConsultation({required String locale, required ReadingCategory category}) {
    _locale = locale;
    _category = category;
    _phase = ConsultationPhase.question;
    TtsService.instance.setLocale(locale);
    notifyListeners();
  }

  /// User submitted their question → go to persona pick (no AI call).
  void handleUserQuestion(String question) {
    _userQuestion = question;
    _setPhase(ConsultationPhase.personaPick);
  }

  /// User confirmed persona → transition to card picking.
  void confirmPersona() {
    _setPhase(ConsultationPhase.picking);
    TtsService.instance.setVoice(_persona.voiceId);
  }

  /// Cards drawn — brief acknowledgement only, no interpretation.
  Future<void> handleCardsDrawn(
    List<DrawnCard> cards,
    SpreadType spread,
  ) async {
    _currentSpread = spread;
    _allDrawnCards
      ..clear()
      ..addAll(cards);
    _revealedCount = 0;
    _initialCardCount = null;
    final isNewTopic = _drawContext == 'new_topic';
    _drawContext = 'initial';
    _setPhase(ConsultationPhase.reading);

    final langHint = _locale != 'en' ? '[Please respond in language code: $_locale]\n' : '';

    await _sendToAi(
      '${langHint}PERSONA: ${_persona.aiPrompt}\n'
      '${isNewTopic ? "The seeker wants to explore a NEW TOPIC. Previous cards have been cleared.\n" : ""}'
      'The seeker drew ${cards.length} cards for a ${spread.displayName} spread.\n'
      'Give a BRIEF OracleMessage (1-2 sentences) saying the cards are revealed. '
      'Say you will read them one by one. Do NOT interpret any cards yet.',
    );
  }

  /// User tapped/flipped a card — interpret ONLY this card.
  Future<void> interpretCard(int cardIndex) async {
    if (cardIndex >= _allDrawnCards.length) return;
    if (isProcessing) return; // prevent concurrent AI calls

    final card = _allDrawnCards[cardIndex];
    _activeCardIndex = cardIndex;
    _revealedCount++;
    notifyListeners();

    final isLast = _revealedCount >= _allDrawnCards.length;
    final langHint = _locale != 'en' ? '[Please respond in language code: $_locale]\n' : '';

    final isSingleCard = _allDrawnCards.length == 1;

    try {
      await _sendToAi(
        '${langHint}PERSONA: ${_persona.aiPrompt}\n'
        'SEEKER\'S QUESTION: "${_userQuestion ?? "general reading"}"\n'
        'The seeker revealed: ${card.card.name} in the "${card.position}" position'
        '${card.isReversed ? " (Reversed)" : ""}.\n'
        '${isSingleCard
            ? 'This is the ONLY card. Give a DETAILED TarotCard interpretation (5-8 sentences). Then a warm OracleMessage with advice.'
            : isLast
                ? 'This is the LAST card. Interpret with TarotCard + OracleMessage. Then give a comprehensive OracleMessage tying ALL cards together with advice.'
                : 'Interpret ONLY this one card with a TarotCard component + brief OracleMessage. Do NOT give a summary yet — more cards to come.'}',
      );
    } finally {
      _activeCardIndex = -1;
      if (isLast) {
        _setPhase(ConsultationPhase.chatting);
        _saveReadingHistory();
      }
      notifyListeners();
    }
  }

  void _saveReadingHistory() {
    final cardMaps = _allDrawnCards.map((c) => {
      'name': c.card.name,
      'position': c.position,
      'isReversed': c.isReversed,
    }).toList();

    // Local (Hive)
    CacheService.instance.saveReading(
      question: _userQuestion ?? '',
      cards: cardMaps,
      persona: _persona.name,
      timestamp: DateTime.now(),
    );

    // Remote (Supabase)
    SupabaseService.instance.saveReading(
      question: _userQuestion ?? '',
      cards: cardMaps,
      persona: _persona.name,
      spreadType: _currentSpread?.name,
      locale: _locale,
    );
  }

  /// Follow-up message from user.
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    await _ensureInitialized();

    _messages.add(TarotMessage(isUser: true, text: text));
    notifyListeners();

    final message = UserMessage.text(text);
    await _conversation!.sendRequest(message);
  }

  /// Additional card draw — adds to existing spread.
  /// [onRevealed] callback to mark cards as revealed in the UI.
  Future<void> handleAdditionalDraw(List<DrawnCard> cards, {void Function(int startIndex, int count)? onRevealed}) async {
    _initialCardCount ??= _allDrawnCards.length;
    final startIdx = _allDrawnCards.length;
    _allDrawnCards.addAll(cards);
    _activeCardIndex = startIdx;
    _setPhase(ConsultationPhase.reading);
    onRevealed?.call(startIdx, cards.length);

    final langHint = _locale != 'en' ? '[Please respond in language code: $_locale]\n' : '';

    final buffer = StringBuffer();
    buffer.writeln('${langHint}PERSONA: ${_persona.aiPrompt}');
    buffer.writeln('SEEKER\'S QUESTION: "${_userQuestion ?? "general reading"}"');
    buffer.writeln('The seeker drew ${cards.length} additional clarification card(s):');
    for (final drawn in cards) {
      buffer.write('- ${drawn.card.name} in "${drawn.position}"');
      if (drawn.isReversed) buffer.write(' (Reversed)');
      buffer.writeln();
    }
    buffer.writeln('Interpret these cards in context of the previous reading and their question.');
    buffer.writeln('After interpreting, transition to chatting.');

    try {
      await _sendToAi(buffer.toString());
    } finally {
      _activeCardIndex = -1;
      _setPhase(ConsultationPhase.chatting);
    }
  }

  // --- Private ---

  Future<void> _sendToAi(String text) async {
    await _ensureInitialized();
    final message = UserMessage.text(text);
    await _conversation!.sendRequest(message);
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    final exists = _messages.any((m) => m.surfaceId == update.surfaceId);
    if (!exists) {
      final componentName = _contentGenerator?.surfaceComponentNames[update.surfaceId];
      _messages.add(TarotMessage(
        isUser: false,
        surfaceId: update.surfaceId,
        componentName: componentName,
      ));
      notifyListeners();
    }

    // DrawCards detection is handled via onDrawCardsDetected callback
    // in TaroContentGenerator (transport.dart) — no duplicate check needed here.
  }

  void _onSurfaceUpdated(SurfaceUpdated update) => notifyListeners();

  void _onTextResponse(String text) {
    if (text.trim().isEmpty) return;
    _messages.add(TarotMessage(isUser: false, text: text));
    notifyListeners();
  }

  void _onError(ContentGeneratorError error) {
    talker.error('[$_tag] AI error', error.error);
    _messages.add(TarotMessage(isUser: false, text: 'reading.error'.tr(), isError: true));
    notifyListeners();
  }

  @override
  void dispose() {
    if (_initialized) {
      _conversation!.isProcessing.removeListener(notifyListeners);
      _conversation!.conversation.removeListener(notifyListeners);
      _conversation!.dispose();
    }
    _client.dispose();
    super.dispose();
  }
}
