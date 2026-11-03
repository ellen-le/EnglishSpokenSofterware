// B must verify format, permission and lifecycle against the installed SDK before implementation.
export interface AudioService {
  start(): Promise<void>;
  stop(): Promise<string>;
  cancel(): Promise<void>;
  release(): Promise<void>;
}
