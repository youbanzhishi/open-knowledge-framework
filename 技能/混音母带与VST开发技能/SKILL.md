# 混音母带与VST开发技能

## 技能说明

提供**音频混音/母带处理**、**VST插件开发**、**AI编曲/扒带**三大能力线。覆盖贴唱混音、整体母带修复、23个VC插件+VCMix混音宿主、AI编曲引擎、AI扒带风格迁移的完整工具链。

---

## 技能信息
- 加载模式：progressive
- 触发关键词：[混音, 母带, VST, 插件]
- 摘要：混音母带处理+VST插件开发

## 版本信息

- **版本**：6.0.0
- **创建日期**：2026-05-06
- **最后更新**：2026-05-09
- **变更日志**：
  - v6.0.0 Phase 20完成：5个Rust crate(9,736行)已merge到main+v0.23.0全线CI通过+三平台Desktop Build+Docker镜像+GitHub Release发布。新增：Extension Registry四柱+Plugin Host(VC/CLAP/VST3)+Audio Engine(CPAL)+JSFX解释器(EEL2 VM)+opendaw-core胶水层
  - v5.0.0 九万字混音实战迭代(v4→v12)+格莱美实测基准+VC-BreathControl(第26插件)+VCMix YAML混音铁律+Send/Return原生铁律+数据驱动混音(先分析再下刀)+频谱重塑经验(温和±4dB不硬拉)+动态控制(行业DR=5-8dB)
  - v4.0.0 全面升级：23插件全部完成(20效果器+3乐器)、VCMix从原型→成熟宿主(YAML+Web UI+实时引擎+AI API)、AI编曲引擎(music_theory+composer+smart_mixer+arrangement_mixer)、AI扒带(逆向分析+风格迁移+Remix)、DSP验证套件(137测试)、预设系统(36预设)、CLI命令完整化、跨平台打包(Docker+Tauri)、协作编辑(WebSocket+LWW)
  - v3.1.0 新增VCMix里程碑M15~M18；AI Agent差异化追加AI扒带/编曲分析/编曲混音一体化
  - v3.0.0 新增VCMix无界面混音宿主设计、10个插件全部开发完成+CLI测试通过
  - v2.0.0 贴唱混音流程链重构、DSP/CLI/VST3三层分离架构、CI自动化测试
  - v1.0.0 初始版本

---

## 能力概览

| 能力 | 说明 | 状态 |
|------|------|------|
| 混音分析 | 频谱/响度/动态/声像/共振峰全维度分析 | ✅ 成熟 |
| 贴唱混音 | 人声+伴奏两轨混音处理 | ✅ 成熟 |
| 整体母带修复 | 无分轨情况下的整体EQ/限幅/响度修复 | ✅ 成熟 |
| VC插件系列 | 26个插件(20效果器+3乐器+VC-BreathControl+Template+2待定)，13个Gen2升级 | ✅ 完成 |
| VCMix混音宿主 | YAML驱动+AI Agent友好+Web UI+实时引擎+Send/Return | ✅ 成熟 |
| AI编曲引擎 | 自动编曲+智能混音闭环+编曲混音一体化 | ✅ 成熟 |
| AI扒带 | 参考曲逆向分析+风格迁移+一键Remix | ✅ 成熟 |
| DSP验证 | 23插件137测试音频质量验证套件 | ✅ 成熟 |
| 跨平台打包 | Docker+CI矩阵+wheel+Tauri桌面(三平台) | ✅ 成熟 |
| 协作编辑 | WebSocket多用户+LWW冲突+版本管理 | ✅ 成熟 |
| Rust引擎 | 5个crate(9,736行)+CPAL实时+Extension Registry+JSFX解释器 | ✅ v0.23.0 |

### 产品线（唯一信源：`项目/OpenDAW/docs/knowledge/VocalChain插件系列产品设计文档.md`）

#### 效果器插件（20个）

| 插件 | 对标 | 状态 | Gen2升级 |
|------|------|------|----------|
| VC-EQ | FabFilter Pro-Q / Waves Q10 | ✅ 完成 | — |
| VC-Comp | Waves RComp | ✅ 完成 | — |
| VC-Smooth | Oeksound Soothe2 / Baby Audio Reso | ✅ 完成 | — |
| VC-DeEsser | Waves DeEsser / FabFilter Pro-DS | ✅ 完成 | — |
| VC-Reverb | Waves RVerb / FabFilter Pro-R | ✅ 完成 | ✅ FDN升级 |
| VC-Delay | Waves H-Delay / FabFilter Timeless | ✅ 完成 | ✅ 乒乓+交叉反馈 |
| VC-Limiter | Waves L2 / FabFilter Pro-L | ✅ 完成 | — |
| VC-Saturator | — | ✅ 完成 | — |
| VC-Gain | — | ✅ 完成 | — |
| VC-DynamicEQ | — | ✅ 完成 | — |
| VC-Distortion | Waves Berzerk / FabFilter Saturn | ✅ 完成 | ✅ 非对称增益偶次谐波 |
| VC-Noise | MDA Test Tone / Signalizer | ✅ 完成 | — |
| VC-SurgicalDeEsser | 手工精准去齿音 | ✅ 完成 | — |
| VC-Chorus | — | ✅ 完成 | — |
| VC-Stereo | — | ✅ 完成 | — |
| VC-Compressor | — | ✅ 完成 | ✅ VCA/FET/Opto多模式 |
| VC-Harmonizer | — | ✅ 完成 | ✅ 多声部归一化 |
| VC-PitchShift | — | ✅ 完成 | — |
| VC-Flanger | — | ✅ 完成 | — |
| VC-Phaser | — | ✅ 完成 | — |

#### 乐器插件（3个）

| 插件 | 说明 | 状态 |
|------|------|------|
| VC-Synth | 16复音减法合成器(VA振荡器+Moog滤波+ADSR+LFO) | ✅ 完成 |
| VC-Drum | 4引擎鼓机(采样+合成+弹拨+噪声)+GM打击乐映射 | ✅ 完成 |
| VC-Arp | 7模式琶音器(上行/下行/上下/随机/和弦/拆解/自定义) | ✅ 完成 |

#### 混音宿主

| 产品 | 说明 | 状态 |
|------|------|------|
| VCMix | YAML驱动+Web UI+实时引擎+AI Agent API+23插件全集成 | ✅ 完成 |

> ⚠️ 所有插件的功能规格、参数范围、UI设计决策都记录在产品设计文档中，新会话启动时读取该文档即可无缝衔接。

---

## 一、混音分析

### 触发条件
- 用户提供音频文件，要求分析混音问题
- 混音/母带处理前必做分析

### 分析维度与工具

| 维度 | 工具 | 产出 |
|------|------|------|
| 频谱能量分布 | librosa + scipy | 频谱图、频段能量分布图 |
| 响度测量 | ffmpeg ebur128 | LUFS、LRA、True Peak |
| 动态范围 | numpy RMS/峰值计算 | RMS包络、Crest Factor、LRA直方图 |
| 立体声声像 | librosa + numpy | Mid/Side能量对比、Lissajous图、立体声宽度 |
| 时变频谱 | librosa Mel频谱 | 频谱热力图 |
| 共振峰 | scipy 频率响应分析 | 频率响应曲线+共振峰标注 |

### 问题诊断分级

🔴 **必须修复**：
- True Peak 超过 0dBFS → 限幅至 -1 dBTP
- 削波失真 → 降低增益

🟠 **重点改进**：
- 高频缺失（2-12kHz能量不足）→ EQ提升
- Air感不足（12-20kHz接近无声）→ 高频搁架提升
- 响度偏低（LUFS < -16）→ 增益/压缩调整
- 低频浑浊（100-300Hz堆积）→ 低频衰减/低切
- 动态异常（LRA >10 或 <3）→ 压缩调整

✅ **良好指标**：
- 立体声平衡：左右差 <0.5dB
- Crest Factor：10-15dB
- 低频单声道兼容性：相关性 >0.85

### 流行音乐参考标准

| 指标 | 目标值 |
|------|--------|
| Integrated LUFS | -14 ~ -10 |
| True Peak | ≤ -1 dBTP |
| LRA | 4 ~ 8 dB |
| Crest Factor | 10-15 dB |

### 执行流程
```
1. 读取音频文件
2. ffprobe 获取基本信息（采样率、位深、声道、时长）
3. ffmpeg ebur128 测量 LUFS/LRA/True Peak
4. Python 生成各维度分析图表
5. 汇总问题诊断，生成 Markdown 报告
6. 所有产出保存到 ./混音分析/ 目录
```

---

## 二、贴唱混音

### 触发条件
- 用户提供人声干声 + 伴奏文件
- 用户说"帮我混音"、"做贴唱混音"等

### 输入要求
- **人声**：WAV格式，纯干声（不加任何效果）
- **伴奏**：WAV/FLAC格式
- **可选**：参考曲（风格相近的成品曲，用于对标）

### 人声处理链

> ⚠️ **v2.0核心原则：先融合再清晰，处理层数越少越好**
>
> 融合是地基，清晰是装修。地基没打好就装修，一动全白费。
> 处理层数越少越好——每层都吃动态，四层轻处理叠加=一层重处理。

#### 推荐处理链（v6验证版）

```
人声干声
  → [1] 人声压缩（2.5:1, 统一动态，主歌副歌音量均衡）
  → [2] [可选] 动态EQ微修（只压2-3个最冒的共振峰，最大2-3dB）
  → [3] [可选] 轻微混响（Plate, wet 10-12%, 高频衰减保清晰）
  → [4] [可选] De-essing（齿音明显时加）
  ↓
音量平衡（人声比伴奏高1-2dB）
  ↓
混合 → 总线粘合压缩（1.2:1, 0.5-1dB衰减）
  ↓
响度标准化（-14 LUFS, -1.5 dBTP）
```

#### 处理优先级（必须按顺序）
1. **必须**：人声压缩 + 音量平衡 + 总线粘合 → 这是融合的底子
2. **建议**：轻微混响（带高频衰减）→ 共享空间=融合+清晰兼得
3. **按需**：动态EQ微修 → 只修最冒的点，不是全面处理
4. **按需**：De-essing → 有齿音才加

#### 1. 人声压缩（最关键！）

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| Ratio | 2.5:1 | 统一动态，主歌副歌音量差变小 |
| Threshold | 人声RMS下方3-4dB | 让主歌也进入压缩 |
| Attack | 10ms | 快速响应峰值 |
| Release | 100ms | 慢速释放，避免抽吸 |
| Makeup Gain | 补偿增益衰减量 | 保持整体响度 |
| 目标增益衰减 | 3-5dB | 不要压太狠 |

> 压缩的核心价值：让声音从"时有时无的信号"变成"持续饱满的存在"。

#### 2. EQ原则

> ⚠️ **衰减用动态EQ，提升用静态EQ**

| 频段 | 频率 | 类型 | 增益 | Q值 | 用途 |
|------|------|------|------|-----|------|
| 低切 | 80Hz | 高通 | - | 6dB/oct | 去闷声和低频噪音 |
| 箱体共振 | 250Hz | 钟形 | -1.5~-2dB | 1.5 | 减少浑浊感 |
| 人声存在感1 | 3.5kHz | 钟形 | +2~+4dB | 1.2 | 歌词清晰度 |
| 人声存在感2 | 4.5kHz | 钟形 | +2~+3dB | 1.5 | 补充存在感 |
| 亮度 | 8kHz | 钟形 | +2~+2.5dB | 1.2 | 增加亮度 |
| 空气感 | 12kHz | 高频搁架 | +1.5~+2dB | - | 增加空间感 |

⚠️ EQ提升要保守，每个处理步骤后检查峰值。**色彩EQ要"补"不要"抢"**——对着伴奏的频谱空位做。

#### 3. 动态EQ微修（可选，解决"偶尔冒"）

只压2-3个最突出的共振峰，每个最多衰减2-3dB，只在超标时压。

#### 4. 混响（可选，补空间感+融合）

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| 风格 | Plate（板式） | 适合流行人声 |
| 干湿比 | wet 10-12% | 极轻，现代趋势：干声为主 |
| 衰减时间 | 1.5~2秒 | 中国风/抒情可稍长 |
| Pre-delay | 20~30ms | 让干声先出来，避免糊 |
| 高频衰减 | 6kHz以上渐衰 | **关键！** 低中频混响给融合，高频衰减保清晰 |

> ⚠️ 混响实现必须用Schroeder算法（4梳状+2全通）或FDN算法，禁止用延迟线+随机噪声模拟！
> 高频衰减必须加在混响湿信号上，不是IR上。

#### 5. 去齿音（可选）

- 检测频段：5-8kHz
- 衰减不超过3dB
- 只在明显时才加

### 伴奏处理

- 伴奏已是成品，尽量少动
- 2-4kHz 轻微衰减 -1~-1.5dB，给人声腾频段空间（侧链融合）

### ⚠️ 音量平衡（最关键）

**核心痛点**：静态音量平衡解决不了动态跨度大的问题——副歌人声大、主歌人声小。

#### 贴唱音量平衡四法

1. **LUFS对齐法（最客观）**：人声LUFS比伴奏高1-2dB
2. **聊天音量法（最直觉）**：调到日常聊天音量，人声每个字清楚但不吵
3. **闭眼测试**：人声在面前、伴奏在后面=对了
4. **手机喇叭测试**：手机外放频段窄，平衡不对特别明显

### 总线处理（增加融合度）

| 参数 | 值 | 说明 |
|------|-----|------|
| Ratio | 1.2:1 | 极轻粘合，不是压平 |
| Threshold | 混音RMS以下约6dB | — |
| Attack | 50ms | 中速响应 |
| Release | 200ms | 慢速释放 |
| 目标增益衰减 | 0.5-1dB | 超过1dB就太多了 |

### 母带处理

| 步骤 | 目标 |
|------|------|
| True Peak 限幅 | ≤ -1 dBTP |
| 响度标准化 | -14 LUFS |
| 输出格式 | WAV 16bit 44.1kHz + MP3 320kbps |

### 执行流程
```
1. 分析干声和伴奏的频谱/响度/动态
2. 确认采样率/时长对齐
3. 人声压缩（统一动态，最关键！）
4. [可选] 动态EQ微修（只修最冒的点）
5. [可选] 轻微混响（带高频衰减，补空间感）
6. [可选] 去齿音（有齿音才加）
7. 音量平衡（人声比伴奏高1-2dB）
8. 混合 → 总线粘合压缩（极轻，0.5-1dB）
9. 母带处理：True Peak ≤ -1.5dBTP, 响度 -14 LUFS
10. 验证：测量最终LUFS/True Peak/LRA
11. 生成前后对比图和报告
```

### 输出规范
- 所有产出保存到 `./混音分析/` 目录
- 文件命名：`{歌名}-混音成品.wav`、`{歌名}-混音成品.mp3`、`{歌名}-人声处理后.wav`
- **先出MP3试听，用户满意后再出WAV**（省时间）
- 报告：`{歌名}-混音处理报告.md`，记录所有参数和REAPER复现步骤

### ⚠️ 混音处理报告规范（强制执行）

1. **频谱共振检测结果**（精确到Hz、时间点、dB量）
2. **每个处理环节的详细参数**
3. **每个问题的"诊断→处理→效果"三段式**
4. **REAPER复现指南**

---

## 贴唱混音核心认知（v2.0）

### 融合的本质：共同点

**融合 = 共同点。人声和伴奏共享的东西越多，听感越一体。**

1. **共享空间**（最有效）：混响/房间模拟=同一个"房间"
2. **共享总线处理**（最直接）：总线粘合压缩="一起呼吸"
3. **共享音色**（音色一致性）：同暖同亮=一家人
4. **频率避让**（最底层）：解决"能听清"，不解决"融得好"

### 清晰度 vs 融合度的矛盾与解法

- 分频段分配：低频让给融合，高频让给清晰
- 混响高频衰减是核心解法

### 混响实现铁律

- ❌ 禁止用延迟线+随机噪声模拟混响
- ✅ 必须用Schroeder算法（4梳状+2全通）或FDN算法
- ✅ 高频衰减加在混响湿信号（wet_signal）上

---

## 三、整体母带修复

### 触发条件
- 用户只有最终混音文件，没有分轨
- 用户说"修一下母带"、"修修频谱"等

### EQ修复参考参数

| 频段 | 频率 | 增益 | 说明 |
|------|------|------|------|
| 人声存在感 | 3000Hz | +3~+4dB | 钟形 |
| 清晰度 | 6500Hz | +2~+3dB | 钟形 |
| 亮度 | 10000Hz | +3~+4dB | 钟形 |
| Air感 | 14000Hz | +2~+3.5dB | 高频搁架 |

### 动态处理
- 温和总体压缩（ratio 1.5:1-2:1）
- 目标 LRA 6-8dB

### 母带标准
- True Peak ≤ -1 dBTP
- 响度 -14 LUFS

---

## 四、VST插件开发

### 触发条件
- 用户要求开发VST/AU音频插件
- 用户说"做个插件"、"开发VST"等

### 技术选型：JUCE 框架（C++）

| 优势 | 说明 |
|------|------|
| 多格式输出 | VST3 / AU / AAX / Standalone 一次开发 |
| 内置DSP模块 | 滤波器、压缩、延迟、混响算法 |
| 自带UI框架 | 旋钮、推子、频谱显示组件 |
| 社区成熟 | 教程和示例代码丰富 |

### UI方案选型

| 方案 | 性能 | 视觉效果 | 推荐 |
|------|------|---------|------|
| 预渲染图片 | ⭐最低 | 好 | ⭐首选 |
| JUCE自绘 | 低 | 取决于投入 | 定制化需求 |
| Web UI | 🔴高 | 最好 | 需要前端资源 |

**推荐方案：预渲染图片 + 轻量DSP**

### JUCE线程架构
```
UI线程 ←→ 参数桥（原子操作）←→ DSP线程（实时音频）
```

### 开发流程
```
1. 从VC-Plugin-Template模板创建项目
2. 编写DSP核心算法（Source/DSP/）
3. 编写VST3壳（Source/PluginProcessor）调用DSP
4. 编写CLI壳（Source/CLI/）调用同一DSP
5. 编写UI（Source/PluginEditor）
6. 编写测试（tests/verify_{name}.py + 测试音频）
7. ⚠️ 本地编译验证（铁律：推GitHub前必须本地编译通过）
8. 本地运行CLI测试通过
9. 推送到GitHub → CI自动build+test → 三平台全绿才发版
```

### DSP/CLI/VST3三层分离架构（强制规范）

```
VC-{PluginName}/
├── Source/
│   ├── DSP/                ← 核心算法（插件和命令行共用）
│   │   ├── {PluginName}DSP.h
│   │   └── {PluginName}DSP.cpp
│   ├── PluginProcessor.h   ← VST3插件壳
│   ├── PluginEditor.h      ← VST3 UI壳
│   └── CLI/                ← 命令行工具
│       └── main.cpp
├── tests/
│   ├── test_audio/         ← 测试用音频
│   ├── golden/             ← golden reference
│   └── verify_{name}.py    ← 验证脚本
├── CMakeLists.txt          ← 同时构建VST3 + CLI两个target
└── README.md
```

### VST3乐器插件开发要点

> ⚠️ 乐器插件与效果器有3个关键差异：

1. **CMakeLists.txt**：`IS_SYNTH TRUE` + `NEEDS_MIDI_INPUT TRUE`，无输入总线
2. **processBlock**：清零buffer → 处理MIDI NoteOn/Off → 调用DSP render → 输出
3. **类名不能用连字符**：`VC-DrumProcessor`非法 → `VCDrumProcessor`

#### VC-Drum GM打击乐映射

| 音符 | 乐器 | 音符 | 乐器 |
|------|------|------|------|
| 36 (C1) | Kick | 42 (F#1) | HiHat Closed |
| 38 (D1) | Snare | 46 (A#1) | HiHat Open |
| 39 (Eb1) | Clap | 49 (C#2) | Crash |
| 41 (F1) | Low Tom | 51 (Eb2) | Ride |

#### VC-Arp 琶音器

- 维护mHeldNotes跟踪按住音符 → setChordNotes → 琶音渲染
- 7种模式：上行/下行/上下/随机/和弦/拆解/自定义

### CI自动化测试规范（强制规范）

**编译通过≠插件正确，测试通过才算真通过。**

- **功能测试**：已知输入→预期输出
- **参数边界测试**：参数=0→输出=输入（bypass）；参数=最大值→不崩溃
- **跨平台一致性测试**：三平台输出差异在float精度内
- **回归测试**：存golden reference，每次对比

### ⚠️ 本地编译验证铁律

**推送到GitHub前，必须在云电脑上本地编译验证通过！**

- 编译命令：`cd {插件}/build && cmake .. -DJUCE_PATH=/opt/JUCE && cmake --build . --config Release`
- 本地通过后再 `git push`

---

## 五、VCMix 混音宿主

> 详细参考：`references/VCMix-CLI参考.md`

### 触发条件
- 用户需要多轨混音项目管理（超过2轨）
- 用户需要 Send/Return 路由、Bus 分组、侧链
- AI Agent 需要自动完成混音流程（零 GUI 操作）

### 三大核心要求

**跨平台 — 全平台可用**
- Windows / macOS / Linux 全覆盖
- Python 核心逻辑天然跨平台
- 路径用 pathlib.Path 不用硬编码分隔符

**资源占用小 + 性能强**
- Python + numpy 向量化运算
- 增量渲染：只重算改动的轨道/效果器（SHA-256 缓存指纹）
- 多轨并行：无依赖的轨道用多进程并行渲染（依赖图→拓扑排序→ThreadPoolExecutor按层并行）
- AudioCache：LRU+threading.Lock+mtime/size验证+eviction

**AI Agent 友好 — 核心差异化**
- YAML 声明式配置，AI Agent 可直接读写理解整个项目结构
- CLI 零 GUI 操作：一条命令完成
- AI混音闭环：分析→诊断→建议→应用→验证
- 设计原则：任何人类通过 GUI 能做的事，AI 通过 YAML+CLI 也要能做到

### YAML 配置格式概述

```yaml
project:
  name: 九万字
  bpm: 62
  sample_rate: 44100

tracks:
  - name: vocal
    file: 干声.wav
    volume: 0.8
    effects:
      - VC-DeEsser: {threshold: -40, reduction: -6}
      - VC-Gain: {gain: 6}
      - VC-EQ: {}
      - VC-Comp: {}
    sends:
      - {bus: reverb, level: 0.10}
      - {bus: delay, level: 0.05}

buses:
  - name: reverb
    effects:
      - VC-Reverb: {room: 30, decay: 35, mix: 100, wetlpf: 5000}
  - name: delay
    effects:
      - VC-Delay: {time: 1/4, feedback: 12, mix: 100}

master:
  effects:
    - VC-Comp: {ratio: 2, threshold: -6}
    - VC-Limiter: {ceiling: -1.0}
  output: 混音输出.mp3
```

### 里程碑完成状态（M0~M18 → Phase 19 ✅ → Phase 20 ✅）

| 里程碑 | 内容 | 状态 |
|--------|------|------|
| M0 | 设计文档完成 | ✅ |
| M1 | YAML 解析器 + 参数校验 | ✅ |
| M2 | 信号路由图构建 + 拓扑排序 | ✅ |
| M3 | 插件适配器框架 | ✅ |
| M4 | 基本轨道 + Insert + Master 输出 | ✅ |
| M5 | CLI render/validate 命令 | ✅ |
| M6 | 20秒截断测试 | ✅ |
| M7 | Send/Return 总线 | ✅ |
| M8 | Bus 效果链 + 并行渲染 | ✅ |
| M9 | BPM 同步换算 | ✅ |
| M10 | 侧链路由 | ✅ |
| M11 | 增量渲染 + 缓存管理 | ✅ |
| M12 | 参数自动化（envelope） | ✅ |
| M13 | A/B 对比 + MP3 输出 | ✅ |
| M14 | vcmix suggest/analyze 初版 | ✅ |
| M15 | 音源分离与逆向分析（Demucs拆分+逆向→VCMix配置） | ✅ |
| M16 | 编曲智能模板（编曲结构/乐器进出→自动套用） | ✅ |
| M17 | 编曲混音一体化（SmartTrack+智能协同+自适应混音） | ✅ |
| M18 | 完整开源DAW（Web UI+VST3 Host+MIDI+AI API） | ✅ |

#### Phase 20 ✅ 完成 — Rust引擎 + Plugin Host + JSFX

**5个Rust crate已入库main分支（9,736行），v0.23.0全线CI通过并发布**：

| 开发线 | Crate | 代码量 | 内容 | 状态 |
|--------|-------|--------|------|------|
| 四柱接口 | opendaw-extension | 1,654行 | Plugin API + Script Runtime + Model Bus + Hook System + ExtensionRegistry | ✅ 完成 |
| 插件宿主 | plugin-host | 3,477行 | VC/CLAP/VST3统一适配 + PluginChain + ParamManager + PresetManager + Scanner | ✅ 完成 |
| 音频引擎 | audio-engine | 1,233行 | CPAL实时播放 + AudioBuffer + RingBuffer + Scheduler + Track | ✅ 完成 |
| JSFX解释器 | jsfx-engine | 2,587行 | EEL2 Parser→AST→VM执行 + 60+内置函数 + VcPlugin适配器 | ✅ 完成 |
| 核心胶水 | opendaw-core | 785行 | Project管理 + Mixer + OfflineRenderer | ✅ 完成 |

**发布产物**：
- GitHub Release: https://github.com/youbanzhishi/OpenDAW/releases/tag/v0.23.0
- 三平台桌面安装包（Windows exe/msi、macOS dmg、Linux AppImage/deb/rpm）
- Docker镜像: `ghcr.io/youbanzhishi/opendaw/vcmix:0.23.0`

**JSFX兼容引擎（jsfx-engine crate）**：
- 战略价值：⭐⭐⭐ 杀手级差异化，Reaper独家格式，无其他DAW能跑JSFX
- Reaper用户迁移零成本，JSFX脚本直接用
- JSFX本质：纯文本EEL2脚本，@sample逐采样处理
- 先支持核心子集：@init/@slider/@sample + 基本运算 + spl0/spl1 + sliderN
- 通过adapter.rs适配VcPlugin trait，与现有VC插件体系统一

---

## 六、AI Agent API

### 架构

FastAPI + Pydantic v2，项目ID用SHA-256 hash前12字符，YAML文件存储。

### REST 端点（16个）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/projects | 创建项目 |
| GET | /api/projects | 列出项目 |
| GET | /api/projects/{id} | 获取项目详情 |
| DELETE | /api/projects/{id} | 删除项目 |
| POST | /api/projects/{id}/render | 提交渲染任务 |
| GET | /api/projects/{id}/status | 查询渲染状态 |
| POST | /api/projects/{id}/stop | 停止渲染 |
| GET | /api/projects/{id}/result | 下载渲染结果 |
| POST | /api/projects/{id}/analyze | 提交分析任务 |
| GET | /api/projects/{id}/analysis | 获取分析结果 |
| POST | /api/projects/{id}/suggest | AI混音建议 |
| POST | /api/projects/{id}/apply | 应用AI建议 |
| POST | /api/projects/{id}/validate | 验证项目配置 |
| GET | /api/projects/{id}/graph | 获取信号路由图 |
| POST | /api/projects/{id}/snapshot | 创建项目快照 |
| GET | /api/projects/{id}/snapshots | 列出快照 |

### WebSocket 端点（2个）

| 路径 | 说明 |
|------|------|
| /ws/render/{id} | 渲染进度推送 |
| /ws/collab/{id} | 协作编辑（LWW冲突解决） |

### AI混音闭环

```
分析 → 诊断 → 建议 → 应用 → 验证
  ↑                        |
  └──── 不满意则循环 ←──────┘
```

支持逐步模式（每步确认）和一键模式（自动闭环）。

---

## 七、AI编曲引擎

> 详细参考：`references/AI编曲引擎参考.md`

### 触发条件
- 用户要求自动编曲、生成伴奏
- VCMix项目中需要编曲混音一体化

### 模块架构

```
AI编曲引擎
├── music_theory/       ← 乐理基础
│   ├── 12音阶体系
│   ├── 18和弦类型（大三/小三/属七/大七/减七/增/挂留/9th/11th/13th...）
│   ├── 22和弦进程（I-V-vi-IV/I-vi-IV-V/ii-V-I/12bar blues...）
│   └── K-S调性检测（chroma直方图→24调profile相关）
├── composer/           ← 编曲生成
│   ├── 和弦进程生成
│   ├── 旋律生成
│   ├── 鼓组生成
│   ├── 贝斯生成
│   └── 乐器分配
├── smart_mixer/        ← 智能混音
│   ├── 编曲模板自动匹配混音预设
│   └── 段落切换自动调整参数
└── arrangement_mixer/  ← 编曲混音一体化
    ├── 模板→预设→渲染→闭环迭代
    └── 自适应混音参数调整
```

### 编曲模板（8种）

| 模板 | 风格 | BPM范围 |
|------|------|---------|
| Pop | 流行 | 90-130 |
| EDM | 电子 | 120-150 |
| Rock | 摇滚 | 110-140 |
| Hip-Hop | 嘻哈 | 80-110 |
| R&B | 节奏蓝调 | 70-100 |
| Progressive | 渐进 | 120-160 |
| Lo-fi | 低保真 | 70-90 |
| Orchestral | 管弦 | 60-120 |

### 编曲-混音一体化流程

```
模板选择 → 和弦进程生成 → 乐器轨道生成 → 混音预设匹配
    → VCMix渲染 → AI混音分析 → 参数调整 → 再渲染 → 满意输出
```

### ⚠️ 关键经验

- Transport.tempo避免递归：用beat 0处的tempo而非position_beats
- 罗马数字解析器按长度降序匹配避免前缀冲突（vi不误匹配V+i）
- numpy类型→YAML序列化必须转原生Python（.item()）

---

## 八、AI扒带

### 触发条件
- 用户提供参考曲，要求逆向分析
- 用户要求风格迁移、一键Remix

### 完整管线

```
参考曲 → Demucs分离 → 逆向分析 → BPM/调性检测 → VCMix项目
                                         ↓
                                    风格分类 → 风格迁移 → Remix输出
```

### 核心模块

| 模块 | 说明 |
|------|------|
| AITranscription | Demucs音源分离+逆向混音分析5维 |
| ReferenceMatcherV2 | BPM/调性/风格匹配 |
| StyleTransfer | EQ/压缩/混响参数按stem类别映射迁移 |
| RemixEngine | 一键Remix，叠加新风格 |

### 逆向混音分析5维

| 维度 | 方法 |
|------|------|
| EQ | FFT包络分析 |
| 压缩 | RMS直方图膝点检测 |
| 混响 | 尾部RT60测量 |
| 延迟 | 自相关检测 |
| 声像 | LR能量比分析 |

### 编曲结构分析

多轨能量包络 → 总能量 → 边界检测 → 段落命名（Intro/Verse/Chorus/Bridge/Outro）

### 风格分类规则引擎

| 条件 | 风格 |
|------|------|
| BPM>130 + 4-on-floor | EDM |
| 80-110 + 强低频 | Hip-Hop |
| 120-140 + 失真吉他 | Rock |
| 90-130 + 人声为主 | Pop |

### EQ迁移映射

按stem类别：vocals→Vocal, drums→Drums, bass→Bass, other→Instrument

---

## 九、实时音频引擎

### 架构

```
RealtimeEngine
├── AudioDriver       ← sounddevice后端，buffer_size可调低延迟
├── Transport         ← 时间转换 samples↔秒↔MBT，TempoTrack
├── VST3HostBridge    ← ctypes桥接C++，自动mock回退
└── StateSnapshotManager ← undo/redo，undo弹出当前到redo
```

### VST3 Host桥接

- ctypes桥接C++ VST3 SDK
- 无.so时自动mock回退（不报错）
- 支持效果器和乐器插件加载

---

## 十、预设系统

### 规范

- JSON Schema v1.0：schema_version/plugin/preset_name/parameters必填
- 预设管理CLI：list/export/import/apply
- 批量处理：ThreadPoolExecutor并行，--workers N
- 效果器链：JSON/YAML配置 → 依次CLI处理 → 中间临时WAV → 最终输出

### 覆盖情况

- 36预设覆盖15个插件
- ⚠️ VC-CLI bypass逻辑反转：`--bypass 0`=启用bypass，`--bypass 1`=禁用 → 预设文件跳过bypass:0

---

## 十一、DSP验证

> 详细参考：`references/DSP验证参考.md`

### 测试覆盖

- **信号完整性**：No clipping/Peak≤1.0/No NaN-Inf/No silence/Reasonable gain(0.01-100)
- **频率响应**：sweep→FFT→验证EQ曲线/混响RT60/延迟时间/压缩曲线/降噪SNR
- **立体声**：VC-Stereo MS编解码/VC-Chorus展宽/VC-Delay乒乓
- **延迟测试**：所有效果器+乐器插件
- **总计**：137测试，4个已知bug全部修复

### 已修复DSP Bug（4案例）

| Bug | 问题 | 修复 |
|-----|------|------|
| VC-Harmonizer削波 | 多声部叠加无归一化，Peak=64.67 | 1/(1+numActiveVoices) + 硬clamp |
| VC-Limiter bypass反转 | CLI层`--bypass 1`→enabled=true(反了) | CLI层+DSP层双重修复 |
| VC-Delay乒乓 | 相同L/R输入无立体声分离 | 交替抽头声像+交叉反馈，分离比0.80 |
| VC-Distortion偶次谐波 | tanh对称削波只产生奇次谐波 | 非对称增益曲线(正半周软/负半周硬)，H2=-37.3dB |

### ⚠️ LR4分频测试陷阱

全通相移 → sample-by-sample SNR极低但幅度完全平坦(-0.015dB)；验证重建必须用RMS比较非逐样本。

---

## 十二、CLI命令完整清单

> 详细参数说明：`references/VCMix-CLI参考.md`

### VCMix CLI

| 命令 | 说明 |
|------|------|
| `vcmix render <yaml>` | 渲染混音项目 |
| `vcmix render <yaml> --force` | 强制全量渲染 |
| `vcmix render <yaml> -t 20` | 20秒截断测试 |
| `vcmix validate <yaml>` | 验证YAML配置 |
| `vcmix analyze <yaml>` | AI混音分析 |
| `vcmix automix <yaml>` | AI自动混音 |
| `vcmix graph <yaml>` | 输出信号路由图 |
| `vcmix compare <A> <B>` | A/B对比渲染 |
| `vcmix cache <yaml> list` | 缓存管理 |
| `vcmix serve [--port 8080]` | 启动Web UI+API服务 |
| `vcmix snapshot <yaml>` | 创建项目快照 |
| `vcmix export <yaml>` | 多格式导出 |
| `vcmix arrangement <yaml> --template Pop` | 编曲模板应用 |
| `vcmix compose <yaml> --key C --mode major` | AI编曲生成 |
| `vcmix auto-mix <yaml>` | 编曲混音一体化 |
| `vcmix transcribe <ref_audio>` | AI扒带（参考曲→VCMix项目） |
| `vcmix match-style <yaml> <ref_audio>` | 风格匹配 |
| `vcmix style-transfer <yaml> --style EDM` | 风格迁移 |
| `vcmix remix <ref_audio> --style Lo-fi` | 一键Remix |

### AudioFX CLI（单插件）

```bash
# 通用格式
vc-{plugin} input.wav -o output.wav [参数...]

# 示例
vc-eq input.wav -o output.wav --band 1:1000:2:3
vc-comp input.wav -o output.wav --ratio 2.5 --threshold -18
vc-reverb input.wav -o output.wav --room 30 --decay 35 --mix 30
```

### ⚠️ CLI负数参数修复（v2.6.0）

parseArgs()中`argv[i+1][0]!='-'`跳过负数 → 改用isOption() lambda：
- `--flag`(长选项)/`-h`(短帮助)/`-x`(短选项) → 是选项
- `-20`/`-3.5` → 不是选项是值
- 支持`--`分隔符停止选项解析

---

## 十三、跨平台打包

### Python包

- pyproject.toml可选依赖：[web]/[ai]/[audio]/[dev]/[all]
- wheel分发

### Docker部署（v0.22.2+，双方案）

**按需加载架构**：`VCMIX_PROFILE=core/full` 控制启动模式

| 模式 | 预构建镜像体积 | 运行内存 | 适合 | 包含功能 |
|------|--------------|---------|------|---------|
| core | ~450MB | ~300MB | 1G服务器 | 渲染/插件/预设/MIDI/自动化/编曲/自动混音/Agent API |
| full | ~2GB | ~1.5GB | 4G+服务器 | core全部 + AI转录/Demucs/协作/可视化 |

#### 方案B：预构建镜像（推荐，v0.22.2+）

**适用场景**：快速部署、服务器内存不足无法build、不想编译

```bash
cp .env.example .env    # 改端口/模式在这里
docker compose up -d    # 自动pull预构建镜像
# 访问 http://IP:8000
```

**预构建镜像地址**：
- core：`ghcr.io/youbanzhishi/vcmix:core-latest` (~450MB)
- full：`ghcr.io/youbanzhishi/vcmix:full-latest` (~2GB)
- 版本标签：`core-v0.22.2`、`full-v0.22.2` 等

**只需2个文件**：`docker-compose.yml` + `.env`（不需要Dockerfile）
- 公开镜像无需 `docker login`
- 国内用户可能需要镜像加速（见DEPLOY.md）

#### 方案A：自建镜像（原有方案）

**适用场景**：需要自定义版本、网络无法访问ghcr.io、想修改源码

```bash
cp .env.example .env    # 改端口/模式/版本在这里
docker compose up -d --build    # 本地构建（需要Dockerfile，至少2G内存）
# 访问 http://IP:8000
```

**需要3个文件**：`Dockerfile` + `docker-compose.yml` + `.env`
- Dockerfile已配置国内镜像源（apt阿里云+pip阿里云），国内服务器直接build
- 构建时自动从GitHub下载源码(archive) + CLI二进制(release)
- 版本在.env中控制：`OPENDAW_VERSION`、`AUDIOFX_RELEASE_VERSION`

#### CLI插件二进制（24个，共~1.3MB）

- 预构建镜像已内置，无需额外下载
- 自建方案：Docker构建时自动从GitHub Release下载（VocalChain-CLI-Linux-${ARCH}.tar.gz）
- 容器内路径：`/app/plugins/VC-{Name}/VC-{Name}-CLI-Standalone`
- 环境变量 `VC_AUDIOFX_DIR=/app/plugins` 指定搜索路径

#### 关键环境变量

| 变量 | 默认值 | 说明 | 方案 |
|------|-------|------|------|
| VCMIX_IMAGE_TAG | latest | 预构建镜像标签 | B |
| VCMIX_PROFILE | core | 运行模式 | A+B |
| VCMIX_PORT | 8000 | 宿主机端口 | A+B |
| VCMIX_MEMORY_LIMIT | 512M | 容器内存上限(full建议2G) | A+B |
| VCMIX_MEMORY_RESERVATION | 256M | 容器内存保底(full建议1G) | A+B |
| VCMIX_CPU_LIMIT | 1.0 | 容器CPU核数 | A+B |
| VC_AUDIOFX_DIR | /app/plugins | CLI插件路径 | A+B |
| OPENDAW_VERSION | v0.22.2 | 源码版本（构建时下载archive） | A |
| AUDIOFX_RELEASE_VERSION | v2.8.0 | CLI插件版本（构建时下载） | A |

#### 构建历史

- v0.22.2：新增预构建镜像方案（ghcr.io），CI自动构建推送；full模式安装策略改为PyTorch官方源先装torch再装demucs；WebUI pre-flight check；cache-bust注释
- v0.22.1：git clone → GitHub archive下载（更快更稳）；网络请求自动重试；apt源兼容DEB822；构建步骤失败立即可见；构建后验证CLI数量

**部署文件同步位置**（修改时必须全部同步）：
1. OpenDAW仓库根目录（Dockerfile/docker-compose.yml/.env.example/DEPLOY.md）
2. `项目/OpenDAW/docs/knowledge/VCMix-Dockerfile`
3. `项目/OpenDAW/docs/knowledge/VCMix-docker-compose.yml`
4. `项目/OpenDAW/docs/knowledge/VCMix-env-example`
5. 本SKILL.md Docker章节

### CI矩阵

- 3OS × 4Python版本，fail-fast:false
- JUCE版本统一：8.0.12

### Tauri桌面

- Windows: NSIS安装包
- macOS: DMG
- Linux: AppImage + deb

---

## 十四、协作编辑

### WebSocket协作

- LWW冲突解决（最后写入胜出）
- 多用户实时编辑

### 项目版本管理

- 快照CRUD + diff比较 + 恢复（自动备份当前版本）
- StateSnapshotManager：undo弹出当前到redo，恢复undo栈顶

### 多格式导出

| 格式 | 库 |
|------|-----|
| WAV | soundfile |
| MP3 | ffmpeg |
| FLAC | soundfile |
| OGG | ffmpeg |
| MIDI | mido |

Stem导出：逐轨 + 按总线两种模式

---

## 十五、开源DAW路线图

### 阶段路径

```
VC 插件（✅完成）    VCMix（✅完成）           完整 DAW（持续迭代）
┌──────────┐     ┌──────────────┐        ┌──────────────┐
│ 23个VC插件 │     │ YAML驱动宿主  │        │  开源 DAW    │
│ CLI+VST3  │     │ AI Agent友好  │        │  GUI + 实时  │
│ 独立可用   │     │ Web UI+实时   │        │  录音+MIDI   │
└──────────┘     └──────────────┘        └──────────────┘
```

### AI Agent 差异化

1. **YAML 声明式**：项目文件即配置，AI 可直接读写理解
2. **CLI 零 GUI**：所有操作可通过命令行完成
3. **自动分析**：AI 可自动诊断音频问题并生成修复方案
4. **API 驱动**：16 REST + 2 WebSocket端点
5. **AI扒带能力**：参考曲→逆向分析→自动套用
6. **编曲分析能力**：曲式/乐器进出→自动套用
7. **编曲混音一体化**：SmartTrack+轨道间智能协同

---

## 技术栈汇总

| 类别 | 工具 |
|------|------|
| 音频分析 | Python + librosa, scipy, numpy |
| 音频处理（主力） | VC插件CLI（23个vc-*命令） |
| 音频处理（辅助） | sox, scipy.signal, numpy |
| 响度测量 | ffmpeg ebur128 / loudnorm |
| 混响实现 | Schroeder/FDN算法 |
| VST开发 | JUCE 8.0.12 + CMake + C++ |
| VCMix宿主 | Python + FastAPI + Pydantic v2 + sounddevice |
| AI编曲 | music_theory + composer + smart_mixer |
| AI扒带 | Demucs + AITranscription + StyleTransfer |
| 实时引擎 | RealtimeEngine + VST3HostBridge(ctypes) |
| 协作 | WebSocket + LWW冲突解决 |
| 打包 | Docker + Tauri + wheel |
| CI测试 | GitHub Actions + 137 DSP测试 |
| 预设管理 | JSON Schema v1.0 + 预设CLI |

---

## 输出目录规范

```
./混音分析/
├── {歌名}-混音成品.wav
├── {歌名}-混音成品.mp3
├── {歌名}-人声处理后.wav
├── {歌名}-混音处理报告.md
├── {歌名}-母带修复.wav
├── {歌名}-母带修复.mp3
├── {歌名}-母带修复报告.md
├── 频谱图.png
├── 响度分析.png
├── 动态范围.png
├── 声像分析.png
├── 时变频谱.png
├── 共振峰分析.png
├── 混音前后对比.png
└── analysis_data.json
```

---

## 关键经验（从TOOLS.md v4.0提取）

### CLI负数参数修复（isOption lambda）

parseArgs()中`argv[i+1][0]!='-'`跳过负数参数 → 改用isOption() lambda判断已知flag名称集合。

### DSP Bug修复4案例

1. **Harmonizer削波**：多声部叠加无归一化 → 1/(1+numActiveVoices)+硬clamp
2. **Limiter bypass反转**：CLI层+DSP层双重修复
3. **Delay乒乓**：交替抽头声像+交叉反馈
4. **Distortion偶次谐波**：非对称增益曲线替代DC偏移方案

### JUCE VST3乐器开发

- `IS_SYNTH TRUE` + `NEEDS_MIDI_INPUT TRUE`，无输入总线
- processBlock：清零buffer → 处理MIDI → DSP render → 输出
- 类名不能用连字符
- VC-Drum：GM打击乐映射（Kick=36, Snare=38, HiHat=42/46, Clap=39）

### 编曲-混音一体化

模板 → 预设 → 渲染 → 闭环迭代：
1. 选择编曲模板
2. 自动匹配混音预设
3. VCMix渲染
4. AI混音分析验证
5. 不满意则调整参数再渲染

---

## 踩坑记录

### v1→v2 教训：电平平衡是第一优先级
- **结论**：电平平衡 > 一切效果处理

### v2→v3 教训：过犹不及
- 电平差3-4dB是贴唱甜区
- 总线粘合压缩是人声融入伴奏的关键
- EQ增益要保守，每步检查峰值

### 整体母带修复教训
- 无分轨时EQ必须保守
- 高频提升幅度3-5dB是安全范围
- 使用ffmpeg loudnorm做响度标准化更准确

### v2.0 贴唱混音实战教训（九万字迭代）

| 版本 | 处理 | 结果 | 教训 |
|------|------|------|------|
| v4 | 六层重处理 | 完全没感情 | 过处理杀动态 |
| v5 | 四层轻处理 | 波形压扁 | 叠加效应 |
| 极简版 | 音量平衡+总线微压 | 融合OK但偶尔冒 | 融合的基础 |
| v6 | +人声压缩2.5:1 | **动听！** | 压缩是关键 |
| v7-fix | +动态EQ+Schroeder混响 | 待验证 | 混响铁律 |

### VST3开发踩坑汇总

| 日期 | 问题 | 教训 |
|------|------|------|
| 2026-05-06 | CMake juceaide报错 | project()必须声明`LANGUAGES C CXX` |
| 2026-05-06 | 找不到JUCE模块 | 用`add_subdirectory`而非`include` |
| 2026-05-06 | IIR API差异 | JUCE 8中`makePeakEQ`改`makePeakFilter` |
| 2026-05-06 | GTK/WebKit缺失 | 禁用：`JUCE_USE_GTK=0 JUCE_WEB_BROWSER=0` |
| 2026-05-06 | VC-Comp Limiter冲突 | 自定义类名与JUCE冲突，重命名`VCLimiter` |
| 2026-05-06 | Mac Xcode编译JUCE失败 | 改用Ninja generator |
| 2026-05-06 | Windows PowerShell语法 | 所有run步骤必须加`shell: bash` |
| 2026-05-06 | JUCE 8.0.0+macOS Sequoia不兼容 | 升级到8.0.12 |

---

## ⚠️ UI自检流程（强制执行）

### 布局自检

| 检查项 | 标准 |
|--------|------|
| 控件间距 | 同类≥20px，不同类≥30px |
| 输入左/输出右 | Input相关左侧，Output右侧 |
| 呼吸空间 | 各区域间有明显分隔 |
| Padding | 窗口边缘至少15px内边距 |

### 交互自检

| 检查项 | 标准 |
|--------|------|
| Bypass可见 | 旁通按钮必须醒目 |
| A/B可达 | 切换按钮在显眼位置 |
| 频谱占主面积 | EQ类频谱≥50%面积 |
| 旋钮大小统一 | 同类直径一致(50-60px) |

### UI版本管理规则（强制执行）

1. 每个版本保存到独立目录 `VocalChain-UI/v{版本号}/`
2. 每次迭代记录在 `VocalChain-UI/版本记录.md`
3. **不覆盖旧版**：严禁直接覆盖上一版图片

---

## 仓库信息

| 仓库 | 版本 | 说明 |
|------|------|------|
| AudioFX | v2.8.0 | 26个VC插件源码+CI+CLI smoke test |
| OpenDAW | v0.22.2 | VCMix+Web UI+AI引擎+实时引擎+Docker双方案 |

- AudioFX SSH: `git@github.com:youbanzhishi/AudioFX.git`
- AudioFX HTTPS: `https://github.com/youbanzhishi/AudioFX`
- 用户名: `youbanzhishi`

---

## 与其他技能的协作

### 可调用本技能的场景
- **Auto-RedNote**：小红书音频笔记的混音处理
- **知识沉淀技能**：混音相关知识的沉淀触发
- **topic_tracking**：音频制作话题追踪

### 本技能依赖
- 云电脑环境（音频处理和VST编译验证）
- Python音频库（librosa, scipy, numpy, pydub, sounddevice）
- ffmpeg / SoX
- JUCE框架 8.0.12（VST开发时）
- GitHub Actions CI（跨平台编译）
- SSH Key（云电脑 /root/.ssh/id_ed25519，公钥已添加到 GitHub）
- Demucs（音源分离）
- FastAPI + Pydantic v2（VCMix API）
- Tauri（桌面打包）

### GitHub Actions CI架构（v2）

**三阶段流水线**：detect → build → release

- JUCE版本统一：8.0.12
- 所有run步骤必须加 `shell: bash`
- Mac/Linux用Ninja generator，Windows用VS 17 2022
- push paths: `VC-*/**` + `.github/workflows/**`

---

## 自动更新机制

1. 每次混音任务完成后，将新的踩坑经验追加到"踩坑记录"章节
2. 参数优化结果实时更新到对应参数表
3. 版本号遵循语义化版本：主版本.次版本.修订号
4. 重大架构变更升主版本，参数调整升次版本，修bug升修订号

---

## 文档化与踩坑经验沉淀规则（强制执行）

1. **流程必须文档化** — 存放到 `知识沉淀/` 目录
2. **踩坑必须记录** — 问题现象 → 原因分析 → 解决方案
3. **文档必须实时更新** — 不要等"做完再补"
4. **文档受众 = 其他开发者** — 包含完整命令、版本号、错误信息原文
5. **跨平台经验独立成文 + 交叉引用**

---

## ⚠️ 混音流程铁律（v5.0新增，强制执行）

### 1. 必须用VCMix YAML跑混音
- **禁止写脚本一条条调CLI**，已开发宿主不用=浪费token+浪费时间
- 混音配置模板：`./测试目录/jiuwan_v12.yaml`
- 以后混音：改参数只改YAML → `python -m vcmix.mix --config xxx.yaml`

### 2. Send/Return必须用VCMix原生
- **禁止手搓发送**（复制干声→跑100%wet→手动混合）
- VCMix已实现Send/Return（Phase 18-19），YAML配置sends+buses即可
- 正确方式：
  ```yaml
  tracks:
    - name: vocal
      sends:
        - {bus: reverb, level: 0.10}
        - {bus: delay, level: 0.08}
  buses:
    - name: reverb
      effects:
        - VC-Reverb: {mix: 100, ...}
  ```

### 3. 数据驱动，不掏公式
- **先分析干声频谱数据，再决定EQ参数**
- 禁止上来就"250Hz-3dB、3.5kHz+3dB"这种模板思维
- 哪里多了减哪里，哪里少了补哪里，看数据下刀

### 4. 频谱重塑温和过渡
- 每个EQ频段增益不超过±4dB（Round1），Round2最多±2dB微调
- 用High Shelf提Air（8kHz+），不要用窄bell在10kHz猛提
- 对标行业基准不硬拉，分轮走

### 5. 参考曲实测对标
- 参考 `./角色/混音母带工程师/knowledge/audio/混音分析/格莱美成品实测基准.md`
- 格莱美Pop母带基准：DR=5-8dB, LRA≈5.5LU, Air≈14%
- 混音阶段目标：DR=8-12dB, Crest=8-12dB（母带后会进一步压缩）

### 6. 人声处理链参考（Waves地平线7步法→VC映射）
1. VC-BreathControl → 气声控制
2. VC-EQ → 润泽人声（先分析数据再定参数）
3. VC-Comp → 光学慢压（2:1, attack 10ms, release 150ms, GR 3-4dB）
4. VC-SurgicalDeEsser → 去齿音（压缩后去，因为压缩放大齿音）
5. VC-Saturator → Tape温暖染色
6. VC-Limiter → 靠前+密度
7. VC-Reverb + VC-Delay → Send模式制造深度

### 九万字混音迭代全记录（v4→v12）

| 版本 | 处理 | 结果 | 教训 |
|------|------|------|------|
| v4 | 六层重处理 | 完全没感情 | 过处理杀动态 |
| v5 | 四层轻处理 | 波形压扁 | 叠加效应 |
| 极简版 | 音量平衡+总线微压 | 融合OK但偶尔冒 | 融合的基础 |
| v6 | +人声压缩2.5:1 | **动听！** | 压缩是关键 |
| v8-fix | Python全链路 | 接近甜区 | 第一套模式终点 |
| VCv4 | VC插件链混音 | 动态自然 | VC插件的验证 |
| VCMix | 全插件链 | Crest最低 | Limiter+噪声门丢动态 |
| v9 | 频谱重塑(±10dB) | 底噪大+损伤 | **EQ硬拉=灾难** |
| v10 | 温和重塑(±6dB) | 亮但不舒服 | 数据对≠听感对 |
| v11 | 极简4步 | 自然但缺空间 | 减法到极致也不行 |
| v12 | 7步法+Send空间 | 待验证 | 宿主YAML+数据驱动 |
