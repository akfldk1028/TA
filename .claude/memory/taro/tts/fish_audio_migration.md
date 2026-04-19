---
name: TTS ElevenLabs → Fish Audio 이전 (Phase 1)
description: 2026-04-16 Edge Function 교체 완료. Secret 주입 + 실기기 검증 대기. Phase 2(Live proxy) 유보
type: tts
---

# TTS Fish Audio S2 이전 (Phase 1)

## 배경

- 이전: ElevenLabs Creator $22/mo (100k chars). 초과 $165~220/1M chars — 유저 늘면 비용 폭증.
- 선정: **Fish Audio S2 Plus $11/mo annual** (250k credits). 초과 ~$45/1M chars (한국어 기준).
- 사용자 발언: "사주 이거 채팅만들다 파산할뻔" — 비용 민감도 높음. Fish 가 한국어 WER #1 + 감정 표현 #1.

## 코드 변경 (완료)

| 파일 | 변경 |
|---|---|
| `supabase/functions/tts/index.ts` | ElevenLabs → Fish Audio. API 시그니처(`audioBase64` 키 등) 유지 → 클라 무변경 |
| `lib/features/reading/pages/providers/tarot_session.dart:31` | `RetryAiClient(primary: EdgeFunctionAiClient())` — Gemini fallback 제거 |
| `lib/main.dart:31` | stale "ElevenLabs" 주석 → Fish Audio |
| `CLAUDE.md` | TTS 섹션, Persona 표, Secrets 섹션, Edge Function 표 전면 업데이트 |
| `supabase/schema.sql` | 상단 deprecated + Secret 이름 Fish Audio 로 |
| `supabase/README.md` | Secrets 표 — ELEVENLABS 는 legacy 표기 |

## Edge Function 신형 동작

```
POST /tts/api/generate
Body: { text, voice, speed?, model? }

Edge Function (tts/index.ts):
  1. resolveVoiceRef(voice) — Secret 조회 (preset='river' → FISH_AUDIO_VOICE_RIVER)
     voice 가 >=16자 raw string 이면 reference_id 로 pass-through (디버깅)
  2. POST https://api.fish.audio/v1/tts
     Authorization: Bearer ${FISH_AUDIO_API_KEY}
     model 헤더: 's1' (default) / 'speech-1.6' / 's2-pro'
     Body: { text, reference_id, format: 'mp3', sample_rate: 44100, mp3_bitrate: 128,
             prosody: { speed, volume:0, normalize_loudness:true },
             chunk_length: 300, normalize: true, latency: 'normal' }
  3. Response: binary MP3 bytes
  4. base64 encode + duration 추정 (bytes*8/128000)
  5. JSON { audioBase64, duration, voice, provider: 'fish-audio', mimeType: 'audio/mpeg', alignment: null }
```

`alignment: null` 은 기존 ElevenLabs character timing 자리. Fish 는 제공 안 함 → 클라 타이밍 로직은 이미 null safe.

## 필요 Secret (런타임 활성화)

| Secret | 용도 |
|---|---|
| `FISH_AUDIO_API_KEY` | Bearer 인증. https://fish.audio/app/api-keys/ 에서 발급 |
| `FISH_AUDIO_VOICE_MATILDA` | 신비 현자 (여성) reference_id |
| `FISH_AUDIO_VOICE_RIVER` | 분석가 (중성) reference_id |
| `FISH_AUDIO_VOICE_SHIMMER` | 친구 (여성) reference_id |
| `FISH_AUDIO_VOICE_ADAM` | 직설가 (남성) reference_id |

voice reference_id 얻는 법: fish.audio 대시보드 voice 선택 → URL `/m/<id>/` 의 `<id>`. 또는 voice cloning 후 dashboard 에서 확인.

주입 경로: Supabase Dashboard (supabase-taro) → Settings → Edge Functions → Secrets.

## 테스트

1. Secret 주입 후 `curl -X POST "{SUPABASE_URL}/functions/v1/tts/api/generate" -H "apikey: {ANON}" -H "Content-Type: application/json" -d '{"text":"테스트","voice":"river"}'` → JSON 응답 확인.
2. 앱에서 페르소나 4종 각각 speak → ExoPlayer 재생 + 한국어 발음 품질 체크.
3. Fish 고유 태그 (`[whisper]`, `[professional tone]`) 인라인 넣은 text 도 테스트.

## 롤백

- `ELEVENLABS_API_KEY` Secret **삭제 금지** — 롤백 대비.
- 롤백 시: git revert `supabase/functions/tts/index.ts` + 재배포 → 클라 불변.

## Phase 2 (유보)

Gemini Live API Supabase WebSocket proxy. 현재는 `env.json` 의 `GEMINI_API_KEY` 직접 + Google Cloud Console Android package restriction (`com.clickaround.oracle`).

**Phase 2 시작 전 건드리지 말 것**:
- `env.json` 의 `GEMINI_API_KEY`
- `lib/core/tts/live/` 하위
- `TtsService.configureLive()`
현재 Live 모드 `consultation_screen.dart:443-450` 에서 실제 작동 중.

## 하지 말 것

- voice ID 하드코딩 금지 — Secret 경유.
- Fish 에 `stability`/`similarity_boost` 보내지 말 것 (필드 없음). Edge Function 은 무시하지만 불필요한 페이로드.
- `StreamAudioSource` 로 재생 시도 금지 — Android ExoPlayer Source error. 임시파일 방식만.
