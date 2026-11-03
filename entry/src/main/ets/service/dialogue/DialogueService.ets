import { Scene, DialogueSession, DialogueTurn, PracticeReport, TaskResult, makeId } from '../../model/Practice';
export const MAX_INPUT: number = 500;
export const MAX_USER_TURNS: number = 20;
export interface DialogueService {
  start(scene: Scene): DialogueSession;
  send(scene: Scene, session: DialogueSession, text: string): DialogueSession;
  finish(scene: Scene, session: DialogueSession): PracticeReport;
}
// Conservative per-turn matching, never a pronunciation or semantic score.
function isNegative(text: string, taskId: string): boolean {
  if (/\b(?:not|never|don't|do not|can't|cannot|won't|without)\b/i.test(text)) { return true; }
  return taskId !== 'airport-baggage' && /\bno\b/i.test(text);
}
export function evaluate(scene: Scene, session: DialogueSession): TaskResult[] {
  if (session.sceneId !== scene.id) { throw new Error('场景与会话不匹配。'); }
  const results: TaskResult[] = [];
  scene.tasks.forEach((task) => {
    const evidence = session.turns.find((turn: DialogueTurn) =>
      turn.role === 'user' && turn.sessionId === session.id && !isNegative(turn.text, task.id) &&
      task.patterns.every((pattern: string) => new RegExp(pattern, 'i').test(turn.text)));
    results.push({ taskId: task.id, label: task.label, completed: evidence !== undefined,
      evidenceTurnId: evidence ? evidence.id : '', evidence: evidence ? evidence.text : '', reference: task.reference });
  });
  return results;
}
export class LocalDialogueService implements DialogueService {
  start(scene: Scene): DialogueSession {
    const id = makeId('session');
    return { id: id, sceneId: scene.id, status: 'active', startedAt: Date.now(),
      turns: [{ id: makeId('turn'), sessionId: id, role: 'partner', text: scene.opening, time: Date.now() }] };
  }
  send(scene: Scene, session: DialogueSession, text: string): DialogueSession {
    const input = text.trim();
    if (session.status !== 'active') { throw new Error('练习已结束，请重新开始。'); }
    if (!input) { throw new Error('请先输入一句英语。'); }
    if (input.length > MAX_INPUT) { throw new Error('每句话最多500个字符。'); }
    if (session.turns.filter((turn: DialogueTurn) => turn.role === 'user').length >= MAX_USER_TURNS) {
      throw new Error('已达到20轮上限，请结束练习并查看报告。');
    }
    const turns: DialogueTurn[] = session.turns.slice();
    turns.push({ id: makeId('turn'), sessionId: session.id, role: 'user', text: input, time: Date.now() });
    const next: DialogueSession = { id: session.id, sceneId: session.sceneId, status: 'active',
      startedAt: session.startedAt, turns: turns };
    const results = evaluate(scene, next);
    const missing = results.find((result: TaskResult) => !result.completed);
    const task = missing ? scene.tasks.find((item) => item.id === missing.taskId) : undefined;
    turns.push({ id: makeId('turn'), sessionId: session.id, role: 'partner',
      text: task ? task.prompt : 'Thank you! We have covered the practice goals. You can finish and review now.', time: Date.now() });
    return next;
  }
  finish(scene: Scene, session: DialogueSession): PracticeReport {
    if (session.status !== 'active') { throw new Error('无法为已结束或取消的练习重复生成报告。'); }
    const results = evaluate(scene, session);
    const missing = results.filter((result: TaskResult) => !result.completed);
    const suggestions: string[] = missing.slice(0, 3).map((result: TaskResult) =>
      '下次补充“' + result.label + '”，可尝试：' + result.reference);
    if (suggestions.length === 0) {
      suggestions.push('本轮已命中全部任务规则。请隐藏提示，再用自己的表达练习一次。');
    }
    return { id: 'report-' + session.id, sessionId: session.id, sceneId: scene.id, createdAt: Date.now(),
      completed: missing.length === 0, results: results, suggestions: suggestions, source: 'offline-rules-v1' };
  }
}
