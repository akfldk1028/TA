/**
 * TTS Client — 통합 클라이언트
 *
 * Provider 선택 + 자동 fallback + Logger 주입
 *
 * Usage:
 *   const client = new TTSClient(providers, 'elevenlabs');
 *   const result = await client.generate({ text: '안녕', provider: 'google' });
 */

import type { ITTSProvider } from "./providers/base";
import type { TTSRequest, TTSResponse, VoiceInfo } from "./types";
import { logger as defaultLogger, type TTSLogger } from "./logger";

export class TTSClient {
  private providers: Map<string, ITTSProvider>;
  private defaultProvider: string;
  private log: TTSLogger;

  constructor(
    providers: Map<string, ITTSProvider>,
    defaultProvider: string,
    logger?: TTSLogger,
  ) {
    this.providers = providers;
    this.defaultProvider = defaultProvider;
    this.log = logger || defaultLogger;
  }

  async generate(req: TTSRequest): Promise<TTSResponse> {
    const providerName = req.provider || this.defaultProvider;
    const provider = this.providers.get(providerName);

    if (!provider) {
      throw new Error(`Unknown TTS provider: ${providerName}. Available: ${[...this.providers.keys()].join(", ")}`);
    }

    try {
      const result = await provider.generate(req.text, {
        voice: req.voice,
        language: req.language,
        speed: req.speed,
        stability: req.stability,
        similarityBoost: req.similarityBoost,
        outputFormat: req.outputFormat,
      });

      return {
        audio: result.audio.toString("base64"),
        duration: result.duration,
        voice: result.voice,
        provider: provider.name,
        mimeType: result.mimeType,
        alignment: result.alignment,
      };
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      this.log.warn({ provider: providerName, error: msg }, "[TTSClient] Primary provider failed, trying fallback");

      // Fallback: try other providers
      for (const [name, fallback] of this.providers) {
        if (name === providerName) continue;
        try {
          this.log.info({ fallback: name }, "[TTSClient] Trying fallback provider");
          const result = await fallback.generate(req.text, {
            voice: req.voice,
            language: req.language,
            speed: req.speed,
            outputFormat: req.outputFormat,
          });

          return {
            audio: result.audio.toString("base64"),
            duration: result.duration,
            voice: result.voice,
            provider: fallback.name,
            mimeType: result.mimeType,
            alignment: result.alignment,
          };
        } catch (fallbackError) {
          const fbMsg = fallbackError instanceof Error ? fallbackError.message : String(fallbackError);
          this.log.warn({ fallback: name, error: fbMsg }, "[TTSClient] Fallback provider also failed");
        }
      }

      throw new Error(`All TTS providers failed. Primary (${providerName}): ${msg}`);
    }
  }

  async listVoices(provider?: string, language?: string): Promise<VoiceInfo[]> {
    if (provider) {
      const p = this.providers.get(provider);
      if (!p) return [];
      return p.listVoices(language);
    }

    const all: VoiceInfo[] = [];
    for (const p of this.providers.values()) {
      const voices = await p.listVoices(language);
      all.push(...voices);
    }
    return all;
  }

  getProviderNames(): string[] {
    return [...this.providers.keys()];
  }
}
