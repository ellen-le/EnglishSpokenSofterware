// Contract only. No fake recognition output; the current UI explicitly uses text input.
export interface SpeechCapabilities {
  recognitionAvailable: boolean;
  synthesisAvailable: boolean;
  supportsEnglish: boolean;
  reason: string;
}
export interface SpeechService {
  capabilities(): Promise<SpeechCapabilities>;
  cancel(): Promise<void>;
  release(): Promise<void>;
}
