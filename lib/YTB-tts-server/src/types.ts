/**
 * TTS Server — Type Definitions
 */

// --- Provider names ---

export type ProviderName = "elevenlabs" | "google";

// --- TTS Request ---

export interface TTSRequest {
  /** Text to synthesize */
  text: string;
  /** Provider to use (default: env TTS_DEFAULT_PROVIDER) */
  provider?: ProviderName;
  /** Voice ID or name */
  voice?: string;
  /** Language code: 'ko', 'en', 'ja', etc. */
  language?: string;
  /** Speed multiplier 0.5–2.0 (default 1.0) */
  speed?: number;
  /** ElevenLabs: stability 0–1 */
  stability?: number;
  /** ElevenLabs: similarity boost 0–1 */
  similarityBoost?: number;
  /** Output format */
  outputFormat?: "mp3" | "wav" | "pcm";
}

// --- TTS Response ---

export interface TTSResponse {
  /** Base64-encoded audio */
  audio: string;
  /** Audio duration in seconds */
  duration: number;
  /** Voice used */
  voice: string;
  /** Provider used */
  provider: string;
  /** MIME type */
  mimeType: string;
  /** Character-level timing (ElevenLabs only) */
  alignment?: {
    characters: string[];
    startTimes: number[];
    endTimes: number[];
  };
}

// --- Voice listing ---

export interface VoiceInfo {
  id: string;
  name: string;
  provider: string;
  language: string;
  gender: "male" | "female" | "neutral";
  description?: string;
  previewUrl?: string;
}

// --- Provider options (passed to generate) ---

export interface TTSOptions {
  voice?: string;
  language?: string;
  speed?: number;
  stability?: number;
  similarityBoost?: number;
  outputFormat?: "mp3" | "wav" | "pcm";
}

// --- Provider result (internal) ---

export interface TTSResult {
  audio: Buffer;
  duration: number;
  voice: string;
  mimeType: string;
  alignment?: {
    characters: string[];
    startTimes: number[];
    endTimes: number[];
  };
}

// --- Async job ---

export type JobStatus = "queued" | "processing" | "completed" | "failed";

export interface Job {
  id: string;
  status: JobStatus;
  createdAt: number;
  completedAt?: number;
  request: TTSRequest;
  result?: TTSResponse;
  error?: string;
}
