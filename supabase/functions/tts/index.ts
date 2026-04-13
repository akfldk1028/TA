import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const VOICE_PRESETS: Record<string, string> = {
  sarah: "EXAVITQu4vr4xnSDxMaL",
  matilda: "XrExE9yKIg1WjnnlVkGX",
  shimmer: "N2lVS1w4EtoT3dr4eOWO",
  river: "SAz9YHcvj6GT2YYXdXww",
  adam: "pNInz6obpgDQGcFmaJgB",
  george: "JBFqnCBsd6RMkjVDRZzb",
  roger: "CwhRBWXzGAHq8TQ4Fs17",
};

const DEFAULT_VOICE = "SAz9YHcvj6GT2YYXdXww"; // river (calm, warm)
const MODEL = "eleven_multilingual_v2";

function resolveVoiceId(voice?: string): string {
  if (!voice) return DEFAULT_VOICE;
  const preset = VOICE_PRESETS[voice.toLowerCase()];
  if (preset) return preset;
  if (voice.length > 10) return voice; // raw voice ID
  return DEFAULT_VOICE;
}

Deno.serve(async (req: Request) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/tts/, "");

  // Health check
  if (path === "/health" || path === "") {
    return new Response(JSON.stringify({ status: "ok", provider: "elevenlabs" }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  // Voices list
  if (path === "/api/voices") {
    const voices = Object.entries(VOICE_PRESETS).map(([name, id]) => ({
      id, name, provider: "elevenlabs", language: "multi",
    }));
    return new Response(JSON.stringify(voices), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }

  // Generate TTS
  if (path === "/api/generate" && req.method === "POST") {
    const apiKey = Deno.env.get("ELEVENLABS_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "ELEVENLABS_API_KEY not set" }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const body = await req.json();
    const text = body.text as string;
    if (!text || text.trim().length === 0) {
      return new Response(JSON.stringify({ error: "text is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const voiceId = resolveVoiceId(body.voice);
    const stability = body.stability ?? 0.3;
    const similarityBoost = body.similarity_boost ?? 0.8;
    const style = body.style ?? 0.3;
    const useSpeakerBoost = body.use_speaker_boost ?? true;

    try {
      const elRes = await fetch(
        `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}/with-timestamps`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "xi-api-key": apiKey,
          },
          body: JSON.stringify({
            text,
            model_id: MODEL,
            voice_settings: {
              stability,
              similarity_boost: similarityBoost,
              style,
              use_speaker_boost: useSpeakerBoost,
            },
          }),
        }
      );

      if (!elRes.ok) {
        const errText = await elRes.text();
        return new Response(JSON.stringify({ error: `ElevenLabs error: ${elRes.status}`, detail: errText }), {
          status: elRes.status,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      const data = await elRes.json();
      const audioBase64 = data.audio_base64;
      if (!audioBase64) {
        return new Response(JSON.stringify({ error: "No audio in response" }), {
          status: 500,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      // Calculate duration from alignment or estimate
      let duration = 0;
      if (data.alignment?.character_end_times_seconds?.length > 0) {
        duration = Math.max(...data.alignment.character_end_times_seconds);
      } else {
        const bytes = (audioBase64.length * 3) / 4;
        duration = (bytes * 8) / 128000;
      }

      return new Response(JSON.stringify({
        audioBase64,
        duration,
        voice: body.voice || "river",
        mimeType: "audio/mpeg",
        alignment: data.alignment ? {
          characters: data.alignment.characters,
          startTimes: data.alignment.character_start_times_seconds,
          endTimes: data.alignment.character_end_times_seconds,
        } : null,
      }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: `TTS failed: ${e.message}` }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }
  }

  return new Response(JSON.stringify({ error: "Not found" }), {
    status: 404,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
});
