import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/config/ai_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/tts/tts_config.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../models/reading_category.dart';
import '../../../../models/spread_type.dart';
import '../../../../models/tarot_card_data.dart';
import '../../../../router/routes.dart';
import '../providers/tarot_session.dart';
import '../widgets/card_fan_widget.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_list_widget.dart';
import '../widgets/persona_pick_phase.dart';
import '../widgets/question_phase.dart';
import '../widgets/spread_display_widget.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({super.key, required this.spreadType, required this.category});
  final SpreadType spreadType;
  final ReadingCategory category;

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  void _checkAutoScroll(int currentCount) {
    if (currentCount > _lastMessageCount) {
      _lastMessageCount = currentCount;
      _scrollToBottom();
    }
  }

  // Card picking
  TarotDeck? _deck;
  List<TarotCardData> _shuffled = [];
  final List<int> _selectedIndices = [];
  final List<DrawnCard> _drawnCards = [];
  final Set<int> _revealedCards = {};
  final Random _rng = Random();
  late final AnimationController _fanAnim;
  int _cardCount = 0;
  int _hoveredIndex = -1;
  bool _cardsSubmitted = false;
  bool _modeChosen = false;
  bool _isLiveListening = false;
  ConsultationPhase _previousPhase = ConsultationPhase.question;

  // Speech-to-text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _sttAvailable = false;

  @override
  void initState() {
    super.initState();
    _fanAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _initSession();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _speech.initialize(
      onError: (e) {
        debugPrint('[STT] Error: ${e.errorMsg}');
        if (mounted) setState(() => _isLiveListening = false);
      },
      onStatus: (status) {
        debugPrint('[STT] Status: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isLiveListening = false);
            // partial result가 남아있으면 전송
            if (_partialWords.isNotEmpty) {
              _sendSpeechText(_partialWords);
              _partialWords = '';
            }
          }
        }
      },
    );
    debugPrint('[STT] Available: $_sttAvailable');
  }

  Future<void> _initSession() async {
    _deck = await TarotDeck.load();
    _shuffled = _deck!.shuffled();
    _cardCount = _shuffled.length;
    if (mounted) {
      ref.read(tarotSessionProvider).startConsultation(
        locale: context.locale.languageCode,
        category: widget.category,
      );
    }
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectCard(int index) {
    final session = ref.read(tarotSessionProvider);
    final ctx = session.drawContext;
    final requiredCount = session.requestedDrawCount > 0
        ? session.requestedDrawCount
        : widget.spreadType.cardCount;

    if (_selectedIndices.contains(index) || _drawnCards.length >= requiredCount) return;

    // For additional draws, use requestedPositions; for initial/new_topic, use spread positions
    final position = ctx == 'additional'
        ? (session.requestedPositions.length > _drawnCards.length
            ? session.requestedPositions[_drawnCards.length]
            : 'reading.supplementCard'.tr())
        : (ctx == 'new_topic' && session.requestedPositions.length > _drawnCards.length)
            ? session.requestedPositions[_drawnCards.length]
            : (_drawnCards.length < widget.spreadType.positions.length
                ? widget.spreadType.positions[_drawnCards.length]
                : 'reading.cardN'.tr(args: ['${_drawnCards.length + 1}']));

    setState(() {
      _selectedIndices.add(index);
      _drawnCards.add(DrawnCard(
        card: _shuffled[index],
        position: position,
        isReversed: _rng.nextDouble() < AiConfig.reversalProbability,
      ));
    });
    if (_drawnCards.length >= requiredCount && !_cardsSubmitted) {
      _cardsSubmitted = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          if (ctx == 'additional') {
            session.handleAdditionalDraw(_drawnCards, onRevealed: (start, count) {
              setState(() {
                for (var i = start; i < start + count; i++) {
                  _revealedCards.add(i);
                }
              });
            });
          } else {
            // Reveal ALL cards immediately
            setState(() {
              for (var i = 0; i < _drawnCards.length; i++) {
                _revealedCards.add(i);
              }
            });
            session.handleCardsDrawn(_drawnCards, widget.spreadType);
          }
        }
      });
    }
  }

  final List<int> _pendingInterpretations = [];

  void _onCardFlipped(int idx) {
    if (_revealedCards.contains(idx)) return;
    final session = ref.read(tarotSessionProvider);
    if (session.isProcessing) {
      // Queue interpretation for when AI finishes current work
      if (!_pendingInterpretations.contains(idx)) {
        _pendingInterpretations.add(idx);
      }
      return;
    }
    setState(() => _revealedCards.add(idx));
    session.interpretCard(idx);
  }

  void _processPendingInterpretations() {
    final session = ref.read(tarotSessionProvider);
    if (!session.isProcessing && _pendingInterpretations.isNotEmpty) {
      final idx = _pendingInterpretations.removeAt(0);
      if (!_revealedCards.contains(idx)) {
        setState(() => _revealedCards.add(idx));
        session.interpretCard(idx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tarotSessionProvider);
    _checkAutoScroll(session.messages.length);
    // Process queued card interpretations when AI becomes available
    if (!session.isProcessing && _pendingInterpretations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _processPendingInterpretations();
      });
    }
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 500;
    final phase = session.phase;

    // Detect new_topic: chatting/reading → question (AI triggered DrawCards with new_topic)
    if (phase == ConsultationPhase.question &&
        (_previousPhase == ConsultationPhase.chatting || _previousPhase == ConsultationPhase.reading)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndices.clear();
            _drawnCards.clear();
            _cardsSubmitted = false;
            _modeChosen = false;
            _revealedCards.clear();
            _pendingInterpretations.clear();
            _shuffled = _deck!.shuffled();
            _cardCount = _shuffled.length;
          });
        }
      });
    }

    // Detect additional: chatting/reading → picking (AI triggered DrawCards with additional)
    if (phase == ConsultationPhase.picking &&
        (_previousPhase == ConsultationPhase.chatting || _previousPhase == ConsultationPhase.reading)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndices.clear();
            _drawnCards.clear();
            _cardsSubmitted = false;
            _modeChosen = false;
            _shuffled = _deck!.shuffled();
            _cardCount = _shuffled.length;
            _fanAnim.forward(from: 0);
          });
        }
      });
    }
    _previousPhase = phase;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TaroColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(theme, phase, session),

              // --- Phase-specific content ---
              if (phase == ConsultationPhase.question) ...[
                Expanded(child: QuestionPhase(
                  category: widget.category,
                  onChipTap: (label) => ref.read(tarotSessionProvider).handleUserQuestion(label),
                )),
              ] else if (phase == ConsultationPhase.personaPick) ...[
                Expanded(child: PersonaPickPhase(
                  question: session.userQuestion,
                  selectedPersona: session.persona,
                  onPersonaChanged: (p) => ref.read(tarotSessionProvider).persona = p,
                  onConfirm: () {
                    ref.read(tarotSessionProvider).confirmPersona();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _fanAnim.forward();
                    });
                  },
                )),
              ] else if (phase == ConsultationPhase.picking) ...[
                // Card fan fills screen
                Expanded(child: CardFanWidget(
                  shuffledCards: _shuffled,
                  cardCount: _cardCount,
                  selectedIndices: _selectedIndices,
                  requiredCount: session.requestedDrawCount > 0
                      ? session.requestedDrawCount
                      : widget.spreadType.cardCount,
                  hoveredIndex: _hoveredIndex,
                  fanAnimation: _fanAnim,
                  onCardSelected: _selectCard,
                  onHoverChanged: (index) => setState(() => _hoveredIndex = index),
                  isMobile: isMobile,
                )),
              ] else ...[
                // reading / chatting — spread 30% + messages 70%
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * 0.3),
                  child: SpreadDisplayWidget(
                    drawnCards: session.allDrawnCards.isEmpty ? _drawnCards : session.allDrawnCards,
                    activeCardIndex: session.activeCardIndex,
                    revealedCards: _revealedCards,
                    onCardTap: session.readingMode == ReadingMode.auto ? null : _onCardFlipped,
                    isMobile: isMobile,
                    initialCardCount: session.initialCardCount,
                  ),
                ),
                Expanded(child: MessageListWidget(
                  messages: session.messages,
                  scrollController: _scrollController,
                  isProcessing: session.isProcessing,
                  host: session.host,
                  buildPulsingDots: _buildPulsingDots,
                )),
                // Mode selector — show after first AI message, before card tapping
                if (phase == ConsultationPhase.reading &&
                    !_modeChosen &&
                    session.messages.isNotEmpty &&
                    !session.isProcessing)
                  _buildModeSelector(theme),
              ],

              // Chat input (hidden during personaPick and picking)
              if (phase == ConsultationPhase.question ||
                  phase == ConsultationPhase.reading ||
                  phase == ConsultationPhase.chatting)
                ChatInputField(
                  enabled: !session.isProcessing && (phase == ConsultationPhase.question || phase == ConsultationPhase.chatting),
                  onSend: (text) {
                    final s = ref.read(tarotSessionProvider);
                    if (phase == ConsultationPhase.question) {
                      s.handleUserQuestion(text);
                    } else {
                      s.sendMessage(text);
                    }
                    _scrollToBottom();
                  },
                  onMicTap: _toggleMic,
                  isListening: _isLiveListening,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // \u2500\u2500\u2500\u2500 App Bar \u2500\u2500\u2500\u2500
  Widget _buildAppBar(ThemeData theme, ConsultationPhase phase, TarotSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TaroColors.gold.withAlpha(15)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: TaroColors.gold.withAlpha(180),
            onPressed: () => context.go(Routes.menu),
          ),
          Text(
            phase == ConsultationPhase.question || phase == ConsultationPhase.personaPick
                ? 'reading.title'.tr()
                : widget.spreadType.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'NotoSerifKR',
              color: TaroColors.gold.withAlpha(220),
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (phase == ConsultationPhase.picking)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                session.requestedDrawCount > 0
                    ? session.requestedDrawCount
                    : widget.spreadType.cardCount, (i) {
                final filled = i < _drawnCards.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: filled ? 10 : 6, height: filled ? 10 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? TaroColors.gold : Colors.transparent,
                    border: Border.all(
                      color: TaroColors.gold.withAlpha(filled ? 255 : 60),
                      width: 1,
                    ),
                    boxShadow: filled
                        ? [BoxShadow(color: TaroColors.gold.withAlpha(40), blurRadius: 6)]
                        : null,
                  ),
                );
              }),
            ),
          if (phase == ConsultationPhase.chatting || phase == ConsultationPhase.reading)
            GestureDetector(
              onTap: () => context.go(Routes.menu),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TaroColors.gold.withAlpha(40)),
                ),
                child: Text('reading.newReading'.tr(),
                    style: TextStyle(color: TaroColors.gold.withAlpha(160), fontSize: 12, letterSpacing: 0.5)),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _partialWords = '';
  bool _micToggling = false;

  Future<void> _toggleMic() async {
    if (_micToggling) return;
    _micToggling = true;
    try {
      if (_isLiveListening) {
        _speech.stop();
        await TtsService.instance.stopLiveSession();
        setState(() => _isLiveListening = false);
        if (_partialWords.isNotEmpty) {
          _sendSpeechText(_partialWords);
          _partialWords = '';
        }
        return;
      }

      // 1. Live WebSocket 세션 시작 (비동기, UI 블로킹 방지)
      debugPrint('[Mic] Starting live session + STT');
      await TtsService.instance.setMode(TtsMode.live);
      // fire-and-forget — setup timeout(10s)이 UI를 막지 않도록
      TtsService.instance.startLiveSession(
        systemInstruction: _buildLiveInstruction(),
      ).then((_) {
        final liveOk = TtsService.instance.liveSession?.isActive ?? false;
        debugPrint('[Mic] Live session active: $liveOk');
      });

      // 2. STT 시작 (채팅에 텍스트 표시)
      _partialWords = '';
      setState(() => _isLiveListening = true);
      if (_sttAvailable) {
        _speech.listen(
          onResult: (result) {
            debugPrint('[STT] words="${result.recognizedWords}" final=${result.finalResult}');
            _partialWords = result.recognizedWords;
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _partialWords = '';
              setState(() => _isLiveListening = false);
              _sendSpeechText(result.recognizedWords);
            }
          },
          localeId: TtsLocaleConfig.forLocale(context.locale.languageCode).ttsLanguage,
        );
      }
    } finally {
      _micToggling = false;
    }
  }

  String _buildLiveInstruction() {
    final session = ref.read(tarotSessionProvider);
    final locale = context.locale.languageCode;
    final langHint = locale != 'en' ? 'Respond in language code: $locale. ' : '';
    return '${langHint}You are a tarot reader. Persona: ${session.persona.aiPrompt}';
  }

  void _sendSpeechText(String text) {
    debugPrint('[STT] Sending: $text');
    final session = ref.read(tarotSessionProvider);
    if (session.phase == ConsultationPhase.question) {
      session.handleUserQuestion(text);
    } else {
      session.sendMessage(text);
    }
    _scrollToBottom();
  }

  void _startAutoReading() {
    final session = ref.read(tarotSessionProvider);
    session.startAutoReading(
      onReveal: (idx) {
        if (mounted) setState(() => _revealedCards.add(idx));
      },
      onSpeak: (text) {
        final completer = Completer<void>();
        TtsService.instance.speak(
          text,
          id: 'auto-$text'.hashCode.toString(),
          onComplete: () {
            if (!completer.isCompleted) completer.complete();
          },
        );
        // Safety timeout in case TTS doesn't fire completion
        return completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {},
        );
      },
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.volume_up_rounded,
              label: 'reading.autoMode'.tr(),
              sublabel: 'reading.autoModeDesc'.tr(),
              onTap: () {
                _pendingInterpretations.clear();
                setState(() => _modeChosen = true);
                ref.read(tarotSessionProvider).setReadingMode(ReadingMode.auto);
                _startAutoReading();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModeButton(
              icon: Icons.touch_app_rounded,
              label: 'reading.manualMode'.tr(),
              sublabel: 'reading.manualModeDesc'.tr(),
              onTap: () {
                setState(() => _modeChosen = true);
                ref.read(tarotSessionProvider).setReadingMode(ReadingMode.manual);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return _PulsingDot(delay: i * 200);
      }),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    _fanAnim.dispose();
    super.dispose();
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TaroColors.gold.withAlpha(60)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TaroColors.gold.withAlpha(15),
              TaroColors.gold.withAlpha(5),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: TaroColors.gold, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: TaroColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 4),
            Text(sublabel, style: TextStyle(
              color: TaroColors.gold.withAlpha(120),
              fontSize: 11,
            )),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.delay});
  final int delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + widget.delay),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = 0.3 + 0.7 * _controller.value;
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TaroColors.gold.withAlpha((value * 150).round()),
          ),
        );
      },
    );
  }
}
