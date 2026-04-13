import "dotenv/config";
import { ElevenLabsProvider } from "./providers/elevenlabs";
import { GoogleTTSProvider } from "./providers/google-tts";
import { TTSClient } from "./tts-client";
import { createServer } from "./server";
import { logger } from "./logger";
import type { ITTSProvider } from "./providers/base";

const port = parseInt(process.env.PORT || "3201", 10);
const defaultProvider = process.env.TTS_DEFAULT_PROVIDER || "elevenlabs";

// --- Initialize providers ---

const providers = new Map<string, ITTSProvider>();

// ElevenLabs
const elevenLabsKey = process.env.ELEVENLABS_API_KEY;
if (elevenLabsKey) {
  providers.set("elevenlabs", new ElevenLabsProvider(elevenLabsKey));
  logger.info({}, "ElevenLabs provider initialized");
}

// Google Cloud TTS (uses GOOGLE_APPLICATION_CREDENTIALS)
try {
  const googleProvider = new GoogleTTSProvider();
  providers.set("google", googleProvider);
  logger.info({}, "Google TTS provider initialized");
} catch (error) {
  logger.warn({ error }, "Google TTS not available (missing credentials?)");
}

if (providers.size === 0) {
  logger.fatal({}, "No TTS providers configured. Set ELEVENLABS_API_KEY or GOOGLE_APPLICATION_CREDENTIALS.");
  process.exit(1);
}

// Validate default provider
if (!providers.has(defaultProvider)) {
  const first = [...providers.keys()][0];
  logger.warn(
    { requested: defaultProvider, fallback: first },
    "Requested default provider not available, using fallback",
  );
}

const resolvedDefault = providers.has(defaultProvider) ? defaultProvider : [...providers.keys()][0];

// --- Start server ---

const client = new TTSClient(providers, resolvedDefault);
const app = createServer(client);

app.listen(port, "0.0.0.0", () => {
  logger.info(
    { port, providers: [...providers.keys()], default: resolvedDefault },
    "TTS server is running",
  );
});
