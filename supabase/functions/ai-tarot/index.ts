import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * ai-tarot Edge Function v4
 * Qwen 3.5 Flash + FC preflight (tarot-tools)
 * SJ ai-gemini v78 패턴 기반
 *
 * v4: tool calling 추가
 *   - get_card_knowledge: DB에서 카드 지식 조회
 *   - get_combination_rules: 카드 조합 규칙 조회
 *   - FC preflight → 도구 결과 포함 → SSE 스트리밍
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const QWEN_API_KEY = Deno.env.get("QWEN_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const QWEN_BASE_URL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";

const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  'qwen3.5-flash': { input: 0.10, output: 0.40 },
};

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface TarotRequest {
  messages: ChatMessage[];
  model?: string;
  temperature?: number;
  max_tokens?: number;
}

// ═══════════════════════════════════════════
// Tarot Tools — OpenAI function calling 형식
// ═══════════════════════════════════════════

const tarotToolDeclarations = [
  {
    type: "function" as const,
    function: {
      name: "get_card_knowledge",
      description: "타로 카드의 상세 해석 지식을 조회합니다. 카드를 해석하기 전에 반드시 이 도구로 의미/상징/키워드를 확인해야 합니다. 도구 없이 추측하면 부정확한 해석이 나옵니다.",
      parameters: {
        type: "object",
        properties: {
          card_name: {
            type: "string",
            description: "카드 영문명 (예: 'The Fool', 'Ace of Wands', 'Queen of Cups')",
          },
        },
        required: ["card_name"],
      },
    },
  },
  {
    type: "function" as const,
    function: {
      name: "get_combination_rules",
      description: "여러 카드 간 상호작용 규칙을 조회합니다. 스프레드 해석 시 카드 간 관계를 분석할 때 사용합니다.",
      parameters: {
        type: "object",
        properties: {
          rule_type: {
            type: "string",
            enum: ["elemental_dignities", "combination_patterns", "narrative_flow", "suit_overview"],
            description: "규칙 유형",
          },
        },
        required: ["rule_type"],
      },
    },
  },
];

// ═══════════════════════════════════════════
// Tool 실행 함수
// ═══════════════════════════════════════════

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function executeToolCall(name: string, args: Record<string, unknown>): Promise<unknown> {
  switch (name) {
    case "get_card_knowledge": {
      const cardName = args.card_name as string;
      const { data, error } = await supabase
        .from("tarot_cards")
        .select("data")
        .eq("name", cardName)
        .maybeSingle();
      if (error || !data) {
        console.error(`[tarot-tools] Card not found: ${cardName}`, error?.message);
        return { error: `Card '${cardName}' not found` };
      }
      console.log(`[tarot-tools] get_card_knowledge(${cardName}) OK`);
      return data.data;
    }
    case "get_combination_rules": {
      const ruleType = args.rule_type as string;
      const { data, error } = await supabase
        .from("tarot_rules")
        .select("data")
        .eq("slug", ruleType)
        .maybeSingle();
      if (error || !data) {
        console.error(`[tarot-tools] Rule not found: ${ruleType}`, error?.message);
        return { error: `Rule '${ruleType}' not found` };
      }
      console.log(`[tarot-tools] get_combination_rules(${ruleType}) OK`);
      return data.data;
    }
    default:
      return { error: `Unknown tool: ${name}` };
  }
}

// ═══════════════════════════════════════════
// 반복 패턴 감지 (SJ v36)
// ═══════════════════════════════════════════

function detectRepetition(text: string): boolean {
  if (text.length < 20) return false;
  const tail = text.slice(-100);
  if (/(.)\1{19,}/.test(tail)) return true;
  if (/(.{2,4})\1{9,}/.test(tail)) return true;
  return false;
}

// ═══════════════════════════════════════════
// FC Preflight + SSE Streaming (SJ v78 패턴)
// ═══════════════════════════════════════════

async function handleRequest(
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number
): Promise<Response> {
  // Build qwen messages with cache_control
  const qwenMessages: { [k: string]: unknown }[] = [];
  for (const m of messages) {
    if (m.role === "system") {
      qwenMessages.push({
        role: "system",
        content: [{ type: "text", text: m.content, cache_control: { type: "ephemeral" } }],
      });
    } else {
      qwenMessages.push({ role: m.role, content: m.content });
    }
  }

  if (qwenMessages.filter(m => m.role === "user").length === 0) {
    return new Response(
      JSON.stringify({ error: "No user message provided" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // ── FC Preflight: 도구 호출 먼저 해결 ──
  const MAX_FC = 5;
  let preflightFinalContent: string | null = null;
  let totalPreflightUsage = { prompt_tokens: 0, completion_tokens: 0 };
  let lastCompTokens = 0;

  for (let i = 0; i < MAX_FC; i++) {
    const prefBody: Record<string, unknown> = {
      model,
      messages: qwenMessages,
      max_tokens: maxTokens,
      temperature,
      stream: false,
      enable_thinking: false,
      tools: tarotToolDeclarations,
      tool_choice: i === 0 ? "auto" : "auto",
    };

    const prefResp = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${QWEN_API_KEY}` },
      body: JSON.stringify(prefBody),
    });

    if (!prefResp.ok) {
      console.error(`[ai-tarot v4] FC preflight error ${prefResp.status}`);
      break;
    }

    const prefData = await prefResp.json();
    const prefUsage = prefData.usage || {};
    totalPreflightUsage.prompt_tokens += prefUsage.prompt_tokens || 0;
    totalPreflightUsage.completion_tokens += prefUsage.completion_tokens || 0;
    lastCompTokens = prefUsage.completion_tokens || 0;

    const prefChoice = prefData.choices?.[0];
    if (!prefChoice) break;

    const toolCalls = prefChoice.message?.tool_calls;
    if (!toolCalls || toolCalls.length === 0) {
      // 도구 호출 없음 → 텍스트 응답
      if (prefChoice.message?.content) {
        preflightFinalContent = prefChoice.message.content;
        console.log(`[ai-tarot v4] FC preflight final: ${preflightFinalContent!.length} chars, ${i} FC rounds`);
      }
      break;
    }

    // 도구 호출 실행
    qwenMessages.push(prefChoice.message);
    for (const tc of toolCalls) {
      const fnName = tc.function.name;
      const fnArgs = JSON.parse(tc.function.arguments || "{}");
      const result = await executeToolCall(fnName, fnArgs);
      console.log(`[ai-tarot v4] FC[${i}]: ${fnName}(${JSON.stringify(fnArgs)})`);
      qwenMessages.push({ role: "tool", tool_call_id: tc.id, content: JSON.stringify(result) });
    }
  }

  // ── Paragraph repetition check (SJ v105) ──
  if (preflightFinalContent && preflightFinalContent.length > 500) {
    const blk = preflightFinalContent.substring(0, 200);
    const idx = preflightFinalContent.indexOf(blk, 200);
    if (idx !== -1) {
      console.warn(`[ai-tarot v4] Paragraph repetition at ${idx}, truncating`);
      preflightFinalContent = preflightFinalContent.substring(0, idx).trimEnd();
    }
  }

  // ── SSE Response ──
  const encoder = new TextEncoder();

  if (preflightFinalContent !== null) {
    // FC에서 최종 답변 확보 → 청크 단위 SSE 변환
    const pricing = MODEL_PRICING[model] || MODEL_PRICING['qwen3.5-flash'];
    const cost = (totalPreflightUsage.prompt_tokens * pricing.input / 1_000_000) +
                 (totalPreflightUsage.completion_tokens * pricing.output / 1_000_000);

    const stream = new ReadableStream({
      start(controller) {
        // 청크 단위로 전송 (50자씩)
        const text = preflightFinalContent!;
        const chunkSize = 50;
        for (let i = 0; i < text.length; i += chunkSize) {
          const chunk = text.substring(i, i + chunkSize);
          const sseData = JSON.stringify({ text: chunk, done: false });
          controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
        }
        // Done event
        const doneData = JSON.stringify({
          text: "", done: true,
          usage: {
            prompt_tokens: totalPreflightUsage.prompt_tokens,
            completion_tokens: lastCompTokens,
            total_tokens: totalPreflightUsage.prompt_tokens + lastCompTokens,
          },
        });
        controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));

        // Record cost
        if (totalPreflightUsage.prompt_tokens > 0 || lastCompTokens > 0) {
          supabase.rpc("increment_tarot_usage", {
            p_user_id: null, p_reading_count: 0,
            p_token_count: totalPreflightUsage.prompt_tokens + lastCompTokens,
            p_gemini_cost: cost,
          }).then(() => {
            console.log(`[ai-tarot v4] Cost: $${cost.toFixed(6)} (p=${totalPreflightUsage.prompt_tokens}, c=${lastCompTokens})`);
          }).catch((e: unknown) => console.error("[ai-tarot v4] Cost recording failed:", e));
        }

        controller.close();
      },
    });

    return new Response(stream, {
      headers: { ...corsHeaders, "Content-Type": "text/event-stream", "Cache-Control": "no-cache", "Connection": "keep-alive" },
    });
  }

  // ── No FC result → 일반 스트리밍 (도구 없이) ──
  const streamBody = {
    model, messages: qwenMessages, max_tokens: maxTokens, temperature,
    stream: true, enable_thinking: false,
  };

  const qwenResp = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": `Bearer ${QWEN_API_KEY}` },
    body: JSON.stringify(streamBody),
  });

  if (!qwenResp.ok) {
    const errText = await qwenResp.text();
    console.error(`[ai-tarot v4] Stream error ${qwenResp.status}:`, errText);
    return new Response(JSON.stringify({ error: `Qwen error: ${qwenResp.status}` }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  let sPrompt = totalPreflightUsage.prompt_tokens;
  let sComp = totalPreflightUsage.completion_tokens;
  let totalTextLen = 0;

  const outStream = new ReadableStream({
    async start(controller) {
      const reader = qwenResp.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      let accText = "";
      let repDetected = false;

      function processLine(line: string) {
        if (repDetected || !line.startsWith("data: ")) return;
        const json = line.slice(6).trim();
        if (!json || json === "[DONE]") return;
        try {
          const d = JSON.parse(json);
          if (d.usage) { sPrompt += d.usage.prompt_tokens || 0; sComp += d.usage.completion_tokens || 0; }
          const text = d.choices?.[0]?.delta?.content || "";
          if (text) {
            accText += text;
            if (accText.length > 200) accText = accText.slice(-200);
            if (detectRepetition(accText)) {
              repDetected = true;
              controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: "\n\n[AI 응답 오류. 다시 시도해주세요.]", done: false })}\n\n`));
              controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: "", done: true })}\n\n`));
              return;
            }
            totalTextLen += text.length;
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text, done: false })}\n\n`));
          }
        } catch {}
      }

      try {
        while (!repDetected) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";
          for (const l of lines) { processLine(l); if (repDetected) break; }
        }
        if (!repDetected) {
          buffer += decoder.decode(new Uint8Array(), { stream: false });
          if (buffer.trim()) for (const l of buffer.split("\n")) processLine(l);
          const pricing = MODEL_PRICING[model] || MODEL_PRICING['qwen3.5-flash'];
          const cost = (sPrompt * pricing.input + sComp * pricing.output) / 1_000_000;
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: "", done: true, usage: { prompt_tokens: sPrompt, completion_tokens: sComp, total_tokens: sPrompt + sComp } })}\n\n`));
          if (sPrompt > 0 || sComp > 0) {
            supabase.rpc("increment_tarot_usage", { p_user_id: null, p_reading_count: 0, p_token_count: sPrompt + sComp, p_gemini_cost: cost })
              .then(() => console.log(`[ai-tarot v4] Cost: $${cost.toFixed(6)}`))
              .catch((e: unknown) => console.error("[ai-tarot v4] Cost fail:", e));
          }
        }
      } catch (e) {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: "Stream error", done: true })}\n\n`));
      } finally { controller.close(); }
    },
  });

  return new Response(outStream, {
    headers: { ...corsHeaders, "Content-Type": "text/event-stream", "Cache-Control": "no-cache", "Connection": "keep-alive" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    if (!QWEN_API_KEY) throw new Error("QWEN_API_KEY is not configured");
    const { messages, model = "qwen3.5-flash", max_tokens = 8192, temperature = 0.9 }: TarotRequest = await req.json();
    if (!messages || messages.length === 0) throw new Error("messages is required");
    console.log(`[ai-tarot v4] Request: model=${model}, msgs=${messages.length}`);
    return await handleRequest(messages, model, max_tokens, temperature);
  } catch (error) {
    console.error("[ai-tarot v4] Error:", error);
    return new Response(JSON.stringify({ error: (error as Error).message || "Unknown error" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
