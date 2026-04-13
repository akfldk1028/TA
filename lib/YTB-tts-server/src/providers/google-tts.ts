/**
 * Google Cloud TTS Provider
 *
 * Neural2 + Studio voices, SSML 지원, 한/영/일 최적화.
 */

import * as textToSpeech from "@google-cloud/text-to-speech";
import type { ITTSProvider } from "./base";
import type { TTSOptions, TTSResult, VoiceInfo } from "../types";
import type { TTSLogger } from "../logger";
import { logger as defaultLogger } from "../logger";

const VOICE_PRESETS: Record<string, { name: string; language: string; gender: "male" | "female" }> = {
  "ko-female-a": { name: "ko-KR-Neural2-A", language: "ko-KR", gender: "female" },
  "ko-female-b": { name: "ko-KR-Neural2-B", language: "ko-KR", gender: "female" },
  "ko-male":     { name: "ko-KR-Neural2-C", language: "ko-KR", gender: "male" },
  "ko-studio-f": { name: "ko-KR-Studio-A",  language: "ko-KR", gender: "female" },
  "ko-studio-m": { name: "ko-KR-Studio-B",  language: "ko-KR", gender: "male" },
  "en-female":   { name: "en-US-Neural2-C",  language: "en-US", gender: "female" },
  "en-male":     { name: "en-US-Neural2-D",  language: "en-US", gender: "male" },
  "ja-female":   { name: "ja-JP-Neural2-B",  language: "ja-JP", gender: "female" },
  "ja-male":     { name: "ja-JP-Neural2-C",  language: "ja-JP", gender: "male" },
};

const LANG_MAP: Record<string, string> = {
  ko: "ko-KR", en: "en-US", ja: "ja-JP", zh: "cmn-CN",
  es: "es-ES", fr: "fr-FR", de: "de-DE",
};

const DEFAULT_VOICE: Record<string, string> = {
  "ko-KR": "ko-KR-Neural2-A",
  "en-US": "en-US-Neural2-C",
  "ja-JP": "ja-JP-Neural2-B",
};

export class GoogleTTSProvider implements ITTSProvider {
  readonly name = "google";
  private client: textToSpeech.TextToSpeechClient;
  private log: TTSLogger;

  constructor(logger?: TTSLogger) {
    this.client = new textToSpeech.TextToSpeechClient();
    this.log = logger || defaultLogger;
  }

  async isAvailable(): Promise<boolean> {
    try {
      await this.client.listVoices({ languageCode: "ko-KR" });
      return true;
    } catch {
      return false;
    }
  }

  async generate(text: string, options?: TTSOptions): Promise<TTSResult> {
    const languageCode = this.resolveLanguage(options?.language);
    const voiceName = this.resolveVoice(options?.voice, languageCode);
    const speed = options?.speed || 1.0;

    this.log.info(
      { voice: voiceName, language: languageCode, textLength: text.length, speed },
      "[GoogleTTS] Generating speech",
    );

    const [response] = await this.client.synthesizeSpeech({
      input: { text },
      voice: { languageCode, name: voiceName },
      audioConfig: {
        audioEncoding: options?.outputFormat === "wav" ? "LINEAR16" : "MP3",
        speakingRate: speed,
        effectsProfileId: ["small-bluetooth-speaker-class-device"],
      },
    });

    if (!response.audioContent) {
      throw new Error("Google TTS returned no audio content");
    }

    const audioBuffer = Buffer.from(response.audioContent as Uint8Array);
    const isWav = options?.outputFormat === "wav";
    const duration = isWav
      ? audioBuffer.byteLength / (16000 * 2)
      : (audioBuffer.byteLength * 8) / 128000;

    this.log.info(
      { voice: voiceName, duration: duration.toFixed(2), size: audioBuffer.length },
      "[GoogleTTS] Speech generated",
    );

    return {
      audio: audioBuffer,
      duration,
      voice: options?.voice || voiceName,
      mimeType: isWav ? "audio/wav" : "audio/mpeg",
    };
  }

  async listVoices(language?: string): Promise<VoiceInfo[]> {
    const langCode = language ? this.resolveLanguage(language) : undefined;
    const entries = Object.entries(VOICE_PRESETS);
    const filtered = langCode
      ? entries.filter(([, v]) => v.language === langCode)
      : entries;

    return filtered.map(([id, preset]) => ({
      id: preset.name,
      name: id,
      provider: "google",
      language: preset.language,
      gender: preset.gender,
    }));
  }

  private resolveLanguage(lang?: string): string {
    if (!lang) return "ko-KR";
    return LANG_MAP[lang.toLowerCase()] || lang;
  }

  private resolveVoice(voice?: string, languageCode?: string): string {
    if (!voice) return DEFAULT_VOICE[languageCode || "ko-KR"] || "ko-KR-Neural2-A";
    const preset = VOICE_PRESETS[voice.toLowerCase()];
    if (preset) return preset.name;
    if (/^[a-z]{2}-[A-Z]{2}/.test(voice)) return voice;
    return DEFAULT_VOICE[languageCode || "ko-KR"] || "ko-KR-Neural2-A";
  }
}
