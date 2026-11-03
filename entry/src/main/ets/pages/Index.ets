import { common } from '@kit.AbilityKit';
import { Scene, SceneTask, DialogueSession, DialogueTurn, PracticeReport, PracticeHistory, TaskResult,
  UserSettings, defaultSettings } from '../model/Practice';
import { SCENES, sceneById } from '../config/Scenes';
import { LocalDialogueService, MAX_INPUT } from '../service/dialogue/DialogueService';
import { PracticeRepository } from '../repository/PracticeRepository';

@Entry
@Component
struct Index {
  @State view: string = 'home';
  @State selected: Scene = SCENES[0];
  @State session: DialogueSession = new LocalDialogueService().start(SCENES[0]);
  @State report: PracticeReport = new LocalDialogueService().finish(SCENES[0], this.session);
  @State history: PracticeHistory[] = [];
  @State settings: UserSettings = defaultSettings();
  @State input: string = '';
  @State error: string = '';
  @State notice: string = '';
  @State busy: boolean = false;
  @State ready: boolean = false;
  @State saved: boolean = false;
  @State wide: boolean = false;
  private engine: LocalDialogueService = new LocalDialogueService();
  private repository: PracticeRepository = new PracticeRepository();
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void { this.initialize(); }

  private async initialize(): Promise<void> {
    this.busy = true;
    this.error = '';
    try {
      await this.repository.open(this.getUIContext().getHostContext() as common.UIAbilityContext);
      this.history = await this.repository.list();
      this.settings = await this.repository.settings();
      this.ready = true;
    } catch (error) { this.error = '本地数据读取失败，原数据不会被自动清空。请重试。'; }
    finally { this.busy = false; }
  }

  private go(view: string): void {
    if (this.busy) { return; }
    this.error = '';
    this.notice = '';
    this.view = view;
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }

  private start(sceneId: string): void {
    if (this.busy) { return; }
    try {
      this.selected = sceneById(sceneId);
      this.session = this.engine.start(this.selected);
      this.input = '';
      this.saved = false;
      this.go('practice');
    } catch (error) { this.error = '场景不可用，请重新选择。'; }
  }

  private sceneTitle(sceneId: string): string {
    const scene = SCENES.find((item: Scene) => item.id === sceneId);
    return scene ? scene.title : '暂不可用的场景';
  }

  private send(): void {
    if (this.busy || !this.input.trim()) { return; }
    this.busy = true;
    this.error = '';
    try {
      this.session = this.engine.send(this.selected, this.session, this.input);
      this.input = '';
    } catch (error) { this.error = '无法发送：请检查是否超过20轮或输入限制。'; }
    finally { this.busy = false; }
  }

  private finish(): void {
    if (this.busy) { return; }
    try {
      this.report = this.engine.finish(this.selected, this.session);
      this.session = { id: this.session.id, sceneId: this.session.sceneId, startedAt: this.session.startedAt,
        status: 'finished', turns: this.session.turns };
      this.go('report');
    } catch (error) { this.error = '生成报告失败，请返回场景重新练习。'; }
  }

  private async save(): Promise<void> {
    if (this.busy || this.saved || !this.ready) { return; }
    this.busy = true;
    this.error = '';
    try {
      const record: PracticeHistory = { id: this.session.id, sceneId: this.selected.id,
        session: this.session, report: this.report };
      await this.repository.save(record);
      this.history = await this.repository.list();
      this.saved = true;
      this.notice = '已保存到本机，可在历史中复盘。';
    } catch (error) { this.error = '保存未完成，请检查存储或历史数量后重试。'; }
    finally { this.busy = false; }
  }

  private async remove(id: string): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    try {
      await this.repository.remove(id);
      this.history = await this.repository.list();
      this.notice = '已删除这条记录。';
    } catch (error) { this.error = '删除失败，请重试。'; }
    finally { this.busy = false; }
  }

  private async toggleHints(): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    try {
      const next: UserSettings = { id: 'settings-v1', showHints: !this.settings.showHints, mode: 'offline' };
      await this.repository.saveSettings(next);
      this.settings = next;
    } catch (error) { this.error = '设置保存失败，请重试。'; }
    finally { this.busy = false; }
  }

  @Builder
  heading(title: string, subtitle: string) {
    Column({ space: 8 }) {
      Text(title).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#163F3A')
      Text(subtitle).fontSize(15).fontColor('#546761').lineHeight(23)
    }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 18 })
  }

  @Builder
  home() {
    this.heading('情境开口', '每次练习，完成一个真实交流任务。')
    Column({ space: 16 }) {
      Text('从一段有目标的对话开始。').fontSize(22).fontWeight(FontWeight.Medium)
      Text('先看目标，再尝试表达，最后带着具体建议重练。').fontColor('#546761')
      Button('选择练习场景').onClick(() => this.go('scenes')).width('100%')
      Text('离线文字版 · 3个场景 · 本地记录').fontSize(13).fontColor('#546761')
    }.padding(24).width('100%').backgroundColor('#E0EDE4').borderRadius(20)
    Text(this.history.length === 0 ? '还没有保存的练习。' : '已保存 ' + this.history.length.toString() + ' 次练习。')
      .fontColor('#546761').margin({ top: 24 })
    Button('查看历史').onClick(() => this.go('history')).margin({ top: 16 })
    Button('设置与隐私').onClick(() => this.go('settings')).margin({ top: 12 })
  }

  @Builder
  scenes() {
    this.heading('选择一个场景', '不比聊天轮数，练习把事情说清楚。')
    ForEach(SCENES, (scene: Scene) => {
      Column({ space: 10 }) {
        Text(scene.title).fontSize(23).fontWeight(FontWeight.Bold)
        Text(scene.subtitle).fontColor('#546761')
        Text(scene.tasks.length.toString() + ' 个交流目标').fontSize(13)
        Button('查看任务').onClick(() => { this.selected = scene; this.go('detail'); })
      }.alignItems(HorizontalAlign.Start).width('100%').padding(22)
        .backgroundColor(Color.White).borderRadius(18).margin({ bottom: 14 })
    }, (scene: Scene) => scene.id)
  }

  @Builder
  taskList() {
    Column({ space: 14 }) {
      Text('本轮目标').fontSize(20).fontWeight(FontWeight.Bold)
      ForEach(this.selected.tasks, (task: SceneTask) => {
        Column({ space: 5 }) {
          Text('• ' + task.label).fontWeight(FontWeight.Medium)
          if (this.settings.showHints) { Text(task.reference).fontSize(14).fontColor('#546761') }
        }.alignItems(HorizontalAlign.Start).width('100%')
      }, (task: SceneTask) => task.id)
    }.padding(20).width('100%').alignItems(HorizontalAlign.Start).backgroundColor('#E0EDE4').borderRadius(18)
  }

  @Builder
  detail() {
    this.heading(this.selected.title, this.selected.subtitle)
    Text('你的身份：' + this.selected.userRole).margin({ bottom: 8 })
    Text('对话角色：' + this.selected.partnerRole).margin({ bottom: 18 })
    this.taskList()
    Button('开始练习').onClick(() => this.start(this.selected.id)).width('100%').margin({ top: 20 })
    Text('本版使用本地脚本，不调用AI。任务判断覆盖有限表达，可查看原句证据。')
      .fontSize(13).fontColor('#546761').margin({ top: 14 })
  }

  @Builder
  turns() {
    ForEach(this.session.turns, (turn: DialogueTurn) => {
      Column({ space: 6 }) {
        Text(turn.role === 'user' ? '你' : this.selected.partnerRole).fontSize(12).fontColor('#546761')
        Text(turn.text).fontSize(17).lineHeight(25).fontColor('#183E39')
      }.alignItems(HorizontalAlign.Start).width('100%').padding(16).borderRadius(14)
        .backgroundColor(turn.role === 'user' ? '#D9EBE8' : '#FFFFFF').margin({ top: 10 })
    }, (turn: DialogueTurn) => turn.id)
  }

  @Builder
  conversation() {
    this.heading(this.selected.title, '本地脚本模式 · 每句话最多500字符 · 最多20轮')
    if (this.wide) {
      Row({ space: 20 }) {
        Column() { this.taskList() }.width('34%')
        Column() { this.turns() }.layoutWeight(1)
      }.alignItems(VerticalAlign.Top).width('100%')
    } else {
      this.taskList()
      this.turns()
    }
    TextArea({ text: this.input, placeholder: '输入你要说的英语…' }).onChange((value: string) => this.input = value)
      .maxLength(MAX_INPUT).height(110).margin({ top: 18 }).backgroundColor(Color.White)
    Text('语音尚未接入，可使用文字完成本轮。').fontSize(13).fontColor('#546761').margin({ top: 8 })
    Row({ space: 12 }) {
      Button('发送').enabled(!this.busy && this.input.trim().length > 0).onClick(() => this.send()).layoutWeight(1)
      Button('结束并复盘').enabled(!this.busy).onClick(() => this.finish()).layoutWeight(1)
    }.width('100%').margin({ top: 16 })
    Button('取消练习').onClick(() => {
      this.getUIContext().showAlertDialog({ title: '丢弃本轮练习？', message: '本轮尚未保存，取消后不会进入历史。',
        primaryButton: { value: '继续练习', action: () => {} },
        secondaryButton: { value: '丢弃', action: () => { this.session.status = 'cancelled'; this.go('scenes'); } } });
    }).margin({ top: 12 })
  }

  @Builder
  reportBody() {
    this.heading(this.report.completed ? '本轮任务已命中' : '还有可以补充的表达',
      '离线规则判断 · 不代表语法或发音评分')
    ForEach(this.report.results, (result: TaskResult) => {
      Column({ space: 7 }) {
        Text((result.completed ? '✓ ' : '○ ') + result.label).fontSize(18).fontWeight(FontWeight.Medium)
        Text(result.completed ? '你的原句：' + result.evidence : '尚未找到符合规则的用户表达').fontSize(14)
        Text('参考：' + result.reference).fontSize(14).fontColor('#546761')
      }.alignItems(HorizontalAlign.Start).width('100%').padding(18).backgroundColor(Color.White)
        .borderRadius(14).margin({ bottom: 10 })
    }, (result: TaskResult) => result.taskId)
    Text('下次怎样练').fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 14 })
    ForEach(this.report.suggestions, (suggestion: string) => {
      Text(suggestion).lineHeight(24).margin({ top: 10 }).fontColor('#355B54')
    }, (suggestion: string) => suggestion)
    Text('本轮对话').fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 20 })
    this.turns()
    if (this.view === 'report') {
      Button(this.saved ? '已保存' : '保存本轮记录').enabled(!this.busy && !this.saved && this.ready)
        .onClick(() => this.save()).width('100%').margin({ top: 20 })
    }
    Button('再次练习这个场景').onClick(() => this.start(this.selected.id)).width('100%').margin({ top: 12 })
    Button('查看历史').onClick(() => this.go('history')).margin({ top: 12 })
  }

  @Builder
  histories() {
    this.heading('练习历史', '记录保存在本机，最多50次。')
    if (this.history.length === 0) { Text('还没有保存的练习，先选一个场景试试。').fontColor('#546761') }
    ForEach(this.history, (record: PracticeHistory) => {
      Column({ space: 10 }) {
        Text(this.sceneTitle(record.sceneId)).fontSize(20).fontWeight(FontWeight.Bold)
        Text(new Date(record.session.startedAt).toLocaleString()).fontSize(13).fontColor('#546761')
        Text((record.report.completed ? '任务已命中' : '有遗漏任务') + ' · ' +
          record.session.turns.filter((turn: DialogueTurn) => turn.role === 'user').length.toString() + ' 轮')
        Row({ space: 14 }) {
          Button('查看复盘').onClick(() => {
            try {
              this.selected = sceneById(record.sceneId); this.session = record.session;
              this.report = record.report; this.saved = true; this.go('history-detail');
            } catch (error) { this.error = '这条历史的场景暂不可用，原数据已保留。'; }
          })
          Button('删除').onClick(() => {
            this.getUIContext().showAlertDialog({ title: '删除这次练习？', message: '将删除本机的对话与报告，无法在应用中恢复。',
              primaryButton: { value: '保留', action: () => {} },
              secondaryButton: { value: '删除', action: () => { this.remove(record.id); } } });
          }).enabled(!this.busy)
        }
      }.alignItems(HorizontalAlign.Start).width('100%').padding(20).backgroundColor(Color.White)
        .borderRadius(16).margin({ bottom: 12 })
    }, (record: PracticeHistory) => record.id)
  }

  @Builder
  privacy() {
    this.heading('设置与隐私', '学习记录由你掌握。')
    Text('离线脚本模式：不调用外部AI、不上传对话、不保存录音、不请求麦克风。').lineHeight(26).margin({ bottom: 18 })
    Text('报告依据用户文字和有限规则，不提供专业发音评分，也不声称自动诊断语法。').lineHeight(26).margin({ bottom: 18 })
    Button(this.settings.showHints ? '隐藏参考表达' : '显示参考表达').onClick(() => this.toggleHints()).enabled(!this.busy)
    Text('可在历史页逐条删除记录。卸载应用可能删除全部本地数据。').lineHeight(26).margin({ top: 18 })
    Text('版本0.1.0：语音、服务卡片和跨设备尚未实现。').fontSize(13).fontColor('#546761').margin({ top: 18 })
  }

  build() {
    Column() {
      Row() {
        Text('SPEAK WITH A PURPOSE').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#175D58').layoutWeight(1)
        if (this.view !== 'home' && this.view !== 'practice') {
          Button('首页').onClick(() => this.go('home')).fontSize(13).enabled(!this.busy)
        }
      }.width('100%').padding({ left: 24, right: 24, top: 14, bottom: 10 })
      Scroll(this.scroller) {
        Column() {
          if (this.busy) { Text('正在处理本地数据…').fontColor('#546761').margin({ bottom: 12 }) }
          if (this.error) {
            Text(this.error).fontColor('#A03127').padding(14).width('100%').backgroundColor('#FCEAE5').borderRadius(12)
            if (!this.ready) { Button('重试读取').onClick(() => this.initialize()).enabled(!this.busy) }
          }
          if (this.notice) { Text(this.notice).fontColor('#175D58').padding(12) }
          if (this.view === 'home') { this.home() }
          else if (this.view === 'scenes') { this.scenes() }
          else if (this.view === 'detail') { this.detail() }
          else if (this.view === 'practice') { this.conversation() }
          else if (this.view === 'report' || this.view === 'history-detail') { this.reportBody() }
          else if (this.view === 'history') { this.histories() }
          else if (this.view === 'settings') { this.privacy() }
        }.width('100%').constraintSize({ maxWidth: 1100 }).alignItems(HorizontalAlign.Start).padding(24)
      }.layoutWeight(1).width('100%').align(Alignment.Top)
    }.width('100%').height('100%').backgroundColor('#F4F6F0')
      .onAreaChange((oldArea: Area, newArea: Area) => { this.wide = Number(newArea.width) >= 840; })
  }
}
