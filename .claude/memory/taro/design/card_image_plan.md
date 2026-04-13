---
name: 타로 카드 이미지 생성 계획
description: 카와이 동물 스타일 78장 이미지 생성 — Gemini 2.5 Flash Image API, Suit별 동물 매핑, Supabase Storage 저장
type: project
---

## 카드 이미지 현황 & 계획

현재 로컬 assets/cards/에 Major Arcana 15장만 존재 (가라 이미지). Minor Arcana 0장.

### 결정 사항 (2026-04-06)

- **스타일**: 카와이(kawaii) 동물 타로 — 파스텔톤, 치비, 골드 프레임
- **생성 도구**: Gemini 2.5 Flash Image API (`gemini-2.5-flash-image`)
- **비용**: 78장 × $0.039 = ~$3 (Batch API 사용 시 ~$1.5)
- **저장**: Supabase Storage `tarot-cards` 버킷 (public) → imageUrl로 로드
- **테스트 완료**: The Fool (카와이 강아지) — 풀 파이프라인 검증 승인됨 ✅

### 검증된 파이프라인 (2026-04-06)

```
1. Gemini 생성 (1024x1024, 컬러 내부 + 검정 외부)
2. 검정 배경 → 투명 (R<30, G<30, B<30 → alpha=0)
3. 불투명 영역 auto-crop (bounding box)
4. 높이 512 기준 비율 리사이즈 (약 326x512, ~2:3)
5. Supabase Storage 업로드 (tarot-cards 버킷)
```

- **스크립트**: `scripts/tarot_card_pipeline.py`
- **로컬 저장**: `clone/TARO/assets/cards/generated/`
- **Storage URL 패턴**: `https://niagjmqffibeuetxxbxp.supabase.co/storage/v1/object/public/tarot-cards/{suit}_{rank:02d}.png`
- **파일명 규칙**: `major_00.png`, `wands_01.png`, `cups_14.png` 등 (Flutter imageAsset과 동일)
- **출력**: RGBA PNG, 투명 배경, ~326x512

### Supabase Storage 설정

- 버킷: `tarot-cards` (public)
- RLS: public read, anon upload/update 허용

### Suit별 동물 매핑

```
Major Arcana (22장) → 카드별 다양한 동물
  0=puppy, 1=fox, 2=cat, 3=deer, 4=lion, 5=owl,
  6=lovebirds, 7=wolf, 8=bear, 9=tortoise, 10=chameleon,
  11=crane, 12=bat, 13=raven, 14=swan, 15=black goat,
  16=eagle, 17=firefly, 18=rabbit, 19=golden rooster,
  20=phoenix, 21=dragon

Wands (14장)       → 🦊 여우 (열정, 에너지)
Cups (14장)        → 🐱 고양이 (감정, 직관)
Swords (14장)      → 🦉 올빼미 (지성, 판단)
Pentacles (14장)   → 🐻 곰 (물질, 안정)
```

### Supabase DB: tarot_cards 테이블

```sql
tarot_cards (78 rows)
  suit TEXT, rank INTEGER, name TEXT,
  keywords TEXT[], upright_meanings TEXT[], reversed_meanings TEXT[],
  image_url TEXT
  UNIQUE(suit, rank)
  RLS: public read, anon insert/update
```

- rank 변환: page=11, knight=12, queen=13, king=14
- image_url 패턴: `{base}/tarot-cards/{suit}_{rank:02d}.png`

### 다음 단계

- [x] Supabase tarot_cards 테이블 생성 + 78장 메타데이터 insert
- [x] 78장 전체 이미지 생성 완료 (2026-04-08 확인, Supabase Storage 78장 검증)
- [x] tarot_card_data.dart: imageUrl getter (Supabase Storage URL)
- [x] card_face.dart: CachedNetworkImage + loading/fallback
- [x] cached_network_image: ^3.4.1 패키지 추가
- [ ] 로컬 assets/cards/ 가라 이미지 정리

**Why:** 기존 이미지가 불완전하고 (15/78), 앱 출시를 위해 전체 덱 필요.
**How to apply:** 78장 생성 스크립트 실행 → tarot_card_data.dart 수정 → 앱에서 네트워크 이미지 로드.
