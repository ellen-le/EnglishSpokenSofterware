import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { PracticeHistory, UserSettings, defaultSettings } from '../model/Practice';
const HISTORY_KEY: string = 'history-v1';
const SETTINGS_KEY: string = 'settings-v1';
const MAX_HISTORY: number = 50;
export class PracticeRepository {
  private store?: preferences.Preferences;
  async open(context: common.UIAbilityContext): Promise<void> {
    this.store = await preferences.getPreferences(context, { name: 'speaking-v1' });
  }
  private ready(): preferences.Preferences {
    if (!this.store) { throw new Error('本地存储尚未就绪，请重试。'); }
    return this.store;
  }
  async list(): Promise<PracticeHistory[]> {
    const raw = await this.ready().get(HISTORY_KEY, '[]');
    if (typeof raw !== 'string') { throw new Error('历史格式异常，原数据已保留。'); }
    const records = JSON.parse(raw) as PracticeHistory[];
    if (!Array.isArray(records)) { throw new Error('历史格式异常，原数据已保留。'); }
    records.forEach((record: PracticeHistory) => {
      if (!record || typeof record.id !== 'string' || !record.session || !record.report ||
        record.id !== record.session.id || record.report.sessionId !== record.id ||
        record.sceneId !== record.session.sceneId || record.sceneId !== record.report.sceneId ||
        !Array.isArray(record.session.turns) || !Array.isArray(record.report.results) ||
        !Array.isArray(record.report.suggestions) || typeof record.report.completed !== 'boolean' ||
        typeof record.session.startedAt !== 'number' || !Number.isFinite(record.session.startedAt)) {
        throw new Error('历史关联异常，原数据已保留。');
      }
      record.session.turns.forEach((turn) => {
        if (!turn || typeof turn.id !== 'string' || typeof turn.text !== 'string' ||
          turn.sessionId !== record.id || (turn.role !== 'user' && turn.role !== 'partner')) {
          throw new Error('历史对话格式异常，原数据已保留。');
        }
      });
      record.report.results.forEach((result) => {
        if (!result || typeof result.taskId !== 'string' || typeof result.label !== 'string' ||
          typeof result.evidence !== 'string' || typeof result.reference !== 'string' || typeof result.completed !== 'boolean') {
          throw new Error('历史报告格式异常，原数据已保留。');
        }
      });
      if (record.report.suggestions.some((item: string) => typeof item !== 'string')) {
        throw new Error('历史建议格式异常，原数据已保留。');
      }
    });
    return records;
  }
  private async write(key: string, value: string): Promise<void> {
    const store = this.ready();
    const previous = await store.get(key, key === HISTORY_KEY ? '[]' : '');
    try {
      await store.put(key, value);
      await store.flush();
    } catch (error) {
      // Do not leave an unflushed replacement visible in the in-process cache.
      await store.put(key, previous);
      throw new Error('本地写入未完成，请重试。');
    }
  }
  async save(record: PracticeHistory): Promise<void> {
    if (record.id !== record.session.id || record.report.sessionId !== record.id ||
      record.report.sceneId !== record.sceneId || record.session.sceneId !== record.sceneId) {
      throw new Error('记录与报告不匹配，未保存。');
    }
    const records = await this.list();
    const next = records.filter((item: PracticeHistory) => item.id !== record.id);
    if (next.length >= MAX_HISTORY) { throw new Error('已保存50次练习，请先删除不需要的历史。'); }
    next.unshift(record);
    await this.write(HISTORY_KEY, JSON.stringify(next));
  }
  async remove(id: string): Promise<void> {
    const records = await this.list();
    await this.write(HISTORY_KEY, JSON.stringify(records.filter((item: PracticeHistory) => item.id !== id)));
  }
  async clearHistory(): Promise<void> {
    await this.write(HISTORY_KEY, '[]');
  }
  async settings(): Promise<UserSettings> {
    const raw = await this.ready().get(SETTINGS_KEY, '');
    if (raw === '') { return defaultSettings(); }
    if (typeof raw !== 'string') { throw new Error('设置读取失败。'); }
    const settings = JSON.parse(raw) as UserSettings;
    if (!settings || settings.id !== SETTINGS_KEY || typeof settings.showHints !== 'boolean' || settings.mode !== 'offline') {
      throw new Error('设置格式异常，原数据已保留。');
    }
    return settings;
  }
  async saveSettings(settings: UserSettings): Promise<void> {
    await this.write(SETTINGS_KEY, JSON.stringify(settings));
  }
}
