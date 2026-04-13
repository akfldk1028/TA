# TARO lib/ 폴더 구조

```
lib/
├── main.dart                           # 초기화 (EasyLocalization + ProviderScope)
├── app.dart                            # TaroApp (MaterialApp.router)
│
├── core/
│   ├── config/ai_config.dart           # AI 모델명, maxHistory, reversalProbability
│   ├── constants/app_colors.dart       # TaroColors (gold, background, seedPurple)
│   ├── services/api_key_service.dart   # GEMINI_API_KEY (dart-define)
│   └── theme/app_theme.dart            # ThemeData 정의
│
├── models/
│   └── tarot_card_data.dart            # TarotCardData, DrawnCard, SpreadType, TarotDeck
│
├── shared/
│   └── widgets/
│       ├── card_face.dart              # 카드 앞면 렌더러
│       └── flip_card.dart              # 3D 플립 애니메이션
│
├── i18n/
│   ├── multi_file_asset_loader.dart    # 다중 JSON 로더 (17개 언어)
│   └── {ko,en,ja,...}/                 # common, home, card_selection, reading, splash, menu
│
├── router/
│   ├── routes.dart                     # Routes 상수 (splash, menu, consultation)
│   ├── app_router.dart                 # GoRouter (@riverpod)
│   └── app_router.g.dart              # 생성 코드
│
└── features/
    ├── splash/pages/screens/
    │   └── splash_screen.dart          # 브랜딩 스플래시
    │
    ├── menu/pages/screens/
    │   └── menu_screen.dart            # 스프레드 선택 (One/Three/Celtic)
    │
    └── reading/
        ├── models/
        │   ├── tarot_message.dart       # TarotMessage (text/surface/user)
        │   └── oracle_persona.dart      # OraclePersona enum (mystic/analyst/friend/direct)
        ├── services/
        │   ├── ai_client.dart           # AiClient + GeminiAiClient
        │   └── transport.dart           # TaroContentGenerator (A2UI JSON 파싱)
        ├── catalog/
        │   ├── tarot_card.dart          # TarotCard A2UI
        │   ├── reading_summary.dart     # ReadingSummary A2UI
        │   ├── spread_picker.dart       # SpreadPicker A2UI
        │   ├── oracle_message.dart      # OracleMessage A2UI
        │   ├── draw_prompt.dart         # DrawPrompt A2UI
        │   └── tarot_catalog.dart       # 카탈로그 등록
        └── pages/
            ├── providers/
            │   └── tarot_session.dart    # 상담 세션 (Phase 상태 머신)
            ├── screens/
            │   └── consultation_screen.dart  # 단일 상담 화면 (질문→뽑기→해석→대화)
            └── widgets/
                ├── chat_input_field.dart     # 채팅 입력
                └── persona_selector.dart     # 페르소나 선택 칩
```

## 상담 Phase 상태 머신

```
question (질문+페르소나) → picking (78장 팬) → reading (한 장씩 해석) → chatting (자유 대화)
```

## 기술 스택

| 분류 | 기술 |
|------|------|
| State | Riverpod 3.0 (router) + ChangeNotifier (session) |
| Routing | go_router (splash → menu → consultation) |
| i18n | easy_localization (17개 언어) |
| AI | Gemini (dartantic_ai) + A2UI (GenUI) |
| Personas | mystic, analyst, friend, direct |
