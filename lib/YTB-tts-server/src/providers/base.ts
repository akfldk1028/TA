/**
 * ITTSProvider — 모든 TTS 프로바이더가 구현하는 인터페이스
 */

import type { TTSOptions, TTSResult, VoiceInfo } from "../types";

export interface ITTSProvider {
  readonly name: string;
  generate(text: string, options?: TTSOptions): Promise<TTSResult>;
  listVoices(language?: string): Promise<VoiceInfo[]>;
  isAvailable(): Promise<boolean>;
}
