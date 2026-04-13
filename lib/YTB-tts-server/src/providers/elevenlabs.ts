/**
 * ElevenLabs TTS Provider
 *
 * eleven_multilingual_v2 모델, character-level alignment 지원.
 */

import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";
import type { ITTSProvider } from "./base";
import type { TTSOptions, TTSResult, VoiceInfo } from "../types";
import type { TTSLogger } from "../logger";
import { logger as defaultLogger } from "../logger";

const VOICE_PRESETS: Record<string, { id: string; gender: "male" | "female"; description: string }> = {
  sarah:   { id: "EXAVITQu4vr4xnSDxMaL", gender: "female", description: "Natural and friendly" },
  matilda: { id: "XrExE9yKIg1WjnnlVkGX", gender: "female", description: "Warm and mature" },
  arfa:    { id: "Xb7hH8MSUJpSbSDYk0k2", gender: "female", description: "Young and energetic" },
  axl:     { id: "iP95p4xoKVk53GoZ742B", gender: "male",   description: "Dynamic and young" },
  adam:    { id: "pNInz6obpgDQGcFmaJgB", gender: "male",   description: "Deep and stable" },
  george:  { id: "JBFqnCBsd6RMkjVDRZzb", gender: "male",   description: "Mature and trustworthy" },
  shimmer: { id: "N2lVS1w4EtoT3dr4eOWO", gender: "female", description: "Soft and emotional" },
  river:   { id: "SAz9YHcvj6GT2YYXdXww", gender: "neutral" as "female", description: "Calm and neutral" },
};

const DEFAULT_VOICE_ID = VOICE_PRESETS.sarah.id;
const DEFAULT_MODEL = "eleven_multilingual_v2";

export class ElevenLabsProvider implements ITTSProvider {
  readonly name = "elevenlabs";
  private client: ElevenLabsClient;
  private log: TTSLogger;

  constructor(apiKey: string, logger?: TTSLogger) {
    this.client = new ElevenLabsClient({ apiKey });
    this.log = logger || defaultLogger;
  }

  async isAvailable(): Promise<boolean> {
    try {
      await this.client.voices.getAll();
      return true;
    } catch {
      return false;
    }
  }

  async generate(text: string, options?: TTSOptions): Promise<TTSResult> {
    const voiceId = this.resolveVoiceId(options?.voice);

    this.log.info(
      { voice: voiceId, textLength: text.length, model: DEFAULT_MODEL },
      "[ElevenLabs] Generating speech",
    );

    const raw = await this.client.textToSpeech.convertWithTimestamps(voiceId, {
      text,
      modelId: DEFAULT_MODEL,
      ...(options?.stability !== undefined && { stability: options.stability }),
      ...(options?.similarityBoost !== undefined && { similarity_boost: options.similarityBoost }),
    });

    const response = (raw as any).data || raw;

    if (!response.audioBase64) {
      throw new Error("ElevenLabs response missing audioBase64");
    }

    const audioBuffer = Buffer.from(response.audioBase64, "base64");

    let duration: number;
    if (response.alignment?.characterEndTimesSeconds?.length > 0) {
      duration = Math.max(...response.alignment.characterEndTimesSeconds);
    } else {
      duration = (audioBuffer.byteLength * 8) / 128000;
    }

    const alignment = response.alignment
      ? {
          characters: response.alignment.characters,
          startTimes: response.alignment.characterStartTimesSeconds,
          endTimes: response.alignment.characterEndTimesSeconds,
        }
      : undefined;

    this.log.info(
      { voice: voiceId, duration: duration.toFixed(2), size: audioBuffer.length },
      "[ElevenLabs] Speech generated",
    );

    return {
      audio: audioBuffer,
      duration,
      voice: options?.voice || "sarah",
      mimeType: "audio/mpeg",
      alignment,
    };
  }

  async listVoices(_language?: string): Promise<VoiceInfo[]> {
    return Object.entries(VOICE_PRESETS).map(([name, preset]) => ({
      id: preset.id,
      name,
      provider: "elevenlabs",
      language: "multi",
      gender: preset.gender,
      description: preset.description,
    }));
  }

  private resolveVoiceId(voice?: string): string {
    if (!voice) return DEFAULT_VOICE_ID;
    const preset = VOICE_PRESETS[voice.toLowerCase()];
    if (preset) return preset.id;
    if (voice.length > 10) return voice;
    return DEFAULT_VOICE_ID;
  }
}
