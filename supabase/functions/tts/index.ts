import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Fish Audio TTS Edge Function (Phase 1: ElevenLabs → Fish Audio).
// 기존 API 시그니처 유지 — 클라이언트(tts_remote_client.dart) 변경 불필요.
//
// Secrets 요구:
//   FISH_AUDIO_API_KEY       — https://fish.audio/app/api-keys/
//   FISH_AUDIO_VOICE_MATILDA — 신비 현자 (여성) reference_id
//   FISH_AUDIO_VOICE_RIVER   — 분석가 (중성) reference_id
//   FISH_AUDIO_VOICE_SHIMMER — 친구 (여성) reference_id
//   FISH_AUDIO_VOICE_ADAM    — 직설가 (남성) reference_id
//
// Voice ID는 https://fish.audio/ 에서 보이스 선택 후 URL `/m/<id>/` 의 <id> 부분.
// 또는 voice cloning으로 자체 제작 후 대시보드에서 확인.

const FISH_API_URL = "https://api.fish.audio/v1/tts";
const DEFAULT_MODEL = "s1"; // s1 (표준) / speech-1.6 (저가) / s2-pro (프리미엄, 크레딧 더 소모)

// ElevenLabs preset name → Fish Audio reference_id 매핑.
// 환경변수로 주입 가능 (voice ID는 사용자 대시보드 의존).
function resolveVoiceRef(voice?: string): string | null {
  const preset = (voice ?? "river").toLowerCase();
  const envKey = {
    matilda: "FISH_AUDIO_VOICE_MATILDA",
    river: "FISH_AUDIO_VOICE_RIVER",
    shimmer: "FISH_AUDIO_VOICE_SHIMMER",
    adam: "FISH_AUDIO_VOICE_ADAM",
  }[preset];

  if (envKey) {
    const ref = Deno.env.get(envKey);
    if (ref && ref.length > 0) return ref;
  }

  // voice 값이 바로 Fish reference_id일 수도 있음 (raw ID pass-through)
  if (voice && voice.length >= 16) return voice;

  return null;
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/tts/, "");

  if (path === "/health" || path === "") {
    return new Response(
      JSON.stringify({ status: "ok", provider: "fish-audio" }),
      { headers: { "Content-Type": "application/json", ...CORS_HEADERS } },
    );
  }

  if (path === "/api/voices") {
    const presets = ["matilda", "river", "shimmer", "adam"];
    const voices = presets.map((name) => {
      const ref = resolveVoiceRef(name);
      return {
        id: ref ?? "<not-configured>",
        name,
        provider: "fish-audio",
        language: "multi",
      };
    });
    return new Response(JSON.stringify(voices), {
      headers: { "Content-Type": "application/json", ...CORS_HEADERS },
    });
  }

  if (path === "/api/generate" && req.method === "POST") {
    const apiKey = Deno.env.get("FISH_AUDIO_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "FISH_AUDIO_API_KEY not set" }),
        { status: 500, headers: { "Content-Type": "application/json", ...CORS_HEADERS } },
      );
    }

    const body = await req.json();
    const text = body.text as string | undefined;
    if (!text || text.trim().length === 0) {
      return new Response(JSON.stringify({ error: "text is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json", ...CORS_HEADERS },
      });
    }

    const voiceRef = resolveVoiceRef(body.voice);
    if (!voiceRef) {
      return new Response(
        JSON.stringify({
          error: "Voice not configured",
          detail:
            "Set FISH_AUDIO_VOICE_<MATILDA|RIVER|SHIMMER|ADAM> secrets, or pass a raw reference_id via 'voice' field.",
        }),
        { status: 500, headers: { "Content-Type": "application/json", ...CORS_HEADERS } },
      );
    }

    // 기존 ElevenLabs 필드 → Fish Audio 대응.
    // stability/similarity_boost 는 Fish에 없음 (무시).
    // speed 는 prosody.speed 로 매핑.
    const speed = typeof body.speed === "number" ? body.speed : 1;
    const model = (body.model as string | undefined) ?? DEFAULT_MODEL;

    try {
      const fishRes = await fetch(FISH_API_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          "model": model,
        },
        body: JSON.stringify({
          text,
          reference_id: voiceRef,
          format: "mp3",
          sample_rate: 44100,
          mp3_bitrate: 128,
          prosody: {
            speed,
            volume: 0,
            normalize_loudness: true,
          },
          chunk_length: 300,
          normalize: true,
          latency: "normal",
        }),
      });

      if (!fishRes.ok) {
        const errText = await fishRes.text();
        return new Response(
          JSON.stringify({
            error: `Fish Audio error: ${fishRes.status}`,
            detail: errText,
          }),
          {
            status: fishRes.status,
            headers: { "Content-Type": "application/json", ...CORS_HEADERS },
          },
        );
      }

      // Fish Audio 응답은 binary audio bytes (MP3)
      const audioBuf = await fishRes.arrayBuffer();
      const audioBytes = new Uint8Array(audioBuf);

      // base64 인코딩 (Deno btoa 안전하게 처리)
      let binary = "";
      const chunk = 0x8000;
      for (let i = 0; i < audioBytes.length; i += chunk) {
        binary += String.fromCharCode.apply(
          null,
          Array.from(audioBytes.subarray(i, i + chunk)),
        );
      }
      const audioBase64 = btoa(binary);

      // duration 추정: 128kbps MP3 기준 bytes * 8 / bitrate
      const duration = (audioBytes.length * 8) / 128000;

      return new Response(
        JSON.stringify({
          audioBase64,
          duration,
          voice: body.voice || "river",
          provider: "fish-audio",
          mimeType: "audio/mpeg",
          alignment: null,
        }),
        { headers: { "Content-Type": "application/json", ...CORS_HEADERS } },
      );
    } catch (e) {
      return new Response(
        JSON.stringify({ error: `TTS failed: ${(e as Error).message}` }),
        {
          status: 500,
          headers: { "Content-Type": "application/json", ...CORS_HEADERS },
        },
      );
    }
  }

  return new Response(JSON.stringify({ error: "Not found" }), {
    status: 404,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
});
