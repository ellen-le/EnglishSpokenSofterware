# 情境开口 · HarmonyOS 原生英语练习

高校英语学习者通过餐厅、机场和校园任务，完成文字对话、查看遗漏及原句证据、保存并重练。

## 当前实际状态

- 已完成原生 Stage 工程、八个视图、三个场景、离线多轮脚本、规则报告、Preferences历史及删除、提示设置。
- 标准API21构建成功，产物为**未签名**HAP；20项Node主机测试通过。
- API21模拟器安装启动、餐厅两轮文字→报告→保存→强制停止重启读取→删除→更新重启后仍为空，已实际验证。
- 完整语音MVP仍未完成：没有真机结果，其他场景的设备端完整流程、取消和异常恢复回归尚未全部测试。
- 语音、在线AI、服务卡片和跨设备尚未接入。界面明确标注离线文字版，不提供发音分数。

## 环境和构建

已核实本机路径：`F:\Apps\DevEco Studio`，IDE6.0.1.251；SDK6.0.1.112/API21；Hvigor6.21.1；内置Node18.20.1。工程没有新增第三方应用包。

在工程根目录：

```powershell
powershell -NoProfile -File scripts\build.ps1
node test\run.cjs
```

其他安装目录：`powershell -NoProfile -File scripts\build.ps1 -DevEcoRoot '你的DevEco路径'`。测试用环境变量`DEVECO_ROOT`指向IDE。脚本只引用已安装的IDE组件，不下载或安装包；首次建立工作区目录引用可能需要平台审批。不要递归跟随`.build-cache`中的工具目录链接打包源码。

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`。日志：`.hvigor/outputs/build-logs/build.log`。主机测试结果：`test/results.json`。

IDE打开本目录，选择entry/default和API21。签名配置为空；若目标设备拒绝未签名包，必须通过正常签名流程处理，不关闭验证或借用他人凭据。

## 演示步骤

首页→选择场景→餐厅点餐→查看任务→开始练习，逐句输入：

1. `I'd like two sandwiches, please.`
2. `To go, please.`
3. `That's correct. How much is it?`

结束并复盘→检查4项目标与原句→保存→历史详情→再次练习。本轮模拟器实测输入为`i want two burgers to go`和`i confirm the order`；重启保留与删除后不恢复通过。取消不保存等完整回归尚待执行。报告提示是参考表达，不是自动语法纠错。

使用现有模拟器（实例集合和镜像均位于`F:\code\OpenHarmony\Sdk`）：

```powershell
& 'F:\Apps\DevEco Studio\tools\emulator\Emulator.exe' -hvd 'Mate 70 Pro' -path 'F:\code\OpenHarmony\Sdk' -imageRoot 'F:\code\OpenHarmony\Sdk'
powershell -NoProfile -File scripts\device.ps1 -Action Install
powershell -NoProfile -File scripts\device.ps1 -Action Start
powershell -NoProfile -File scripts\device.ps1 -Action Restart
```

`-path`指实例集合目录，不能写成其`Mate 70 Pro`子目录。启动/hdc在当前平台需要真实审批；不要为了调试关闭安全验证。本轮模拟器接受未签名包，不代表手机也接受。

## 分层与限制

- `model/`稳定ID实体；`config/`场景；`service/dialogue/`规则和脚本；`repository/`平台持久化；`pages/Index.ets`八视图状态切换。
- 主机测试使用实际纯业务`.ets`，仓储测试替换平台边界；不代表真实设备存储或断电一致性。
- 每句500字符、每次20轮、历史最多50次；达到容量要求用户删除，不静默丢弃。
- 有限正则只支持部分表达，可能误判同义句和复杂否定；保留证据，未采用模型语义判定。未检测语法或音素。
- 手机/平板布局分支存在，尚未完成尺寸与无障碍实测。
- 本地对话不是加密保险库；当前不上传、不采集统计、不保存录音。

研发记录：`F:\code\OS_COM\research\harmony\speaking-app`，包括分工、能力核验、测试与竞赛交付清单。参考SpeakHub但未复制其代码，详见third-party-notices。
