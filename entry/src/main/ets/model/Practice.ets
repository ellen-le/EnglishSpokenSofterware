export interface SceneTask {
  id: string;
  label: string;
  prompt: string;
  reference: string;
  patterns: string[];
}
export interface Scene {
  id: string;
  title: string;
  subtitle: string;
  userRole: string;
  partnerRole: string;
  opening: string;
  tasks: SceneTask[];
}
export interface DialogueTurn {
  id: string;
  sessionId: string;
  role: string;
  text: string;
  time: number;
}
export interface DialogueSession {
  id: string;
  sceneId: string;
  status: string;
  startedAt: number;
  turns: DialogueTurn[];
}
export interface TaskResult {
  taskId: string;
  label: string;
  completed: boolean;
  evidenceTurnId: string;
  evidence: string;
  reference: string;
}
export interface PracticeReport {
  id: string;
  sessionId: string;
  sceneId: string;
  createdAt: number;
  completed: boolean;
  results: TaskResult[];
  suggestions: string[];
  source: string;
}
export interface PracticeHistory {
  id: string;
  sceneId: string;
  session: DialogueSession;
  report: PracticeReport;
}
export interface UserSettings {
  id: string;
  showHints: boolean;
  mode: string;
}
let serial: number = 0;
export function makeId(prefix: string): string {
  serial += 1;
  return prefix + '-' + Date.now().toString() + '-' + serial.toString() + '-' +
    Math.floor(Math.random() * 1000000000).toString();
}
export function defaultSettings(): UserSettings {
  return { id: 'settings-v1', showHints: true, mode: 'offline' };
}
