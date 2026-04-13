import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" } });
  }
  try {
    const { cards, rules } = await req.json();
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    let cardCount = 0;
    let ruleCount = 0;

    if (cards && Array.isArray(cards)) {
      for (const card of cards) {
        const { error } = await supabase
          .from("tarot_cards")
          .update({ data: card, card_id: card.id })
          .eq("name", card.name);
        if (error) {
          console.error(`Failed to update ${card.name}:`, error.message);
        } else {
          cardCount++;
        }
      }
    }

    if (rules && Array.isArray(rules)) {
      for (const rule of rules) {
        const { error } = await supabase
          .from("tarot_rules")
          .upsert({ slug: rule.slug, data: rule.data }, { onConflict: "slug" });
        if (error) {
          console.error(`Failed to upsert rule ${rule.slug}:`, error.message);
        } else {
          ruleCount++;
        }
      }
    }

    return new Response(JSON.stringify({ ok: true, cards: cardCount, rules: ruleCount }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), { status: 500 });
  }
});
