---
name: TARO Supabase MCP 연결 규칙
description: TARO는 반드시 supabase-taro MCP만 사용, 다른 프로젝트 MCP 절대 혼용 금지
type: reference
---

## TARO 전용 MCP: `supabase-taro`

- **MCP 이름**: `supabase-taro`
- **프로젝트 URL**: `https://niagjmqffibeuetxxbxp.supabase.co`
- **도구 접두사**: `mcp__supabase-taro__*`

## 절대 규칙

TARO 프로젝트의 모든 DB 작업은 **`mcp__supabase-taro__`** 도구만 사용한다.
`mcp__supabase__` (기본) 등 다른 Supabase MCP 도구를 TARO에 쓰면 안 된다.

## 다른 Supabase 프로젝트 (참고용)

| 프로젝트 | MCP | URL |
|----------|-----|-----|
| SJ (사주/만톡) | `supabase` (기본) | `https://kfciluyxkomskyxjaeat.supabase.co` |
| **TAA (TARO)** | **`supabase-taro`** | `https://niagjmqffibeuetxxbxp.supabase.co` |
| MOL | 미설정 | `https://ccqwgtemeqprpzvjghbo.supabase.co` |

**How to apply:** TARO 관련 SQL, 마이그레이션, Edge Function, 테이블 조회 등 모든 Supabase 작업 시 `mcp__supabase-taro__` 접두사 도구만 호출할 것.
