# 网文创作技能 (网文创作技能/SKILL.md)
## Core Capabilities
1. **Novel Writing**: 自动生成符合平台规范的网文内容，支持诸天万界/异界大陆等题材
2. **Format Repair**: 自动修复网文格式问题（行首句号、章节标题规范等）
3. **Platform Publishing**: 支持七猫/起点等平台的上传流程规范
4. **Self-Check**: 内置grep去重扫描和写作规则验证

## Qimao Upload Rules (铁律)
### Upload Process
1. **Copy Strategy**: 电脑端复制章节内容→手机端七猫作家后台粘贴（禁用一键复制，改用手动长按全选）
2. **Title Rule**: 仅输入章节名称，后台自动添加"第X章"前缀
3. **Content Check**: 粘贴后必须检查开头无空行/乱码，内容与原文件一致

### Format Requirements
1. **Paragraph Rule**: 单段≤3句，同一动作链不拆段
2. **Scene Switch**: 使用`……`分隔场景，禁用`---`
3. **Line Break**: 段落间空行分隔，标题独占一行后接空行
4. **Forbidden Elements**: 禁用Markdown格式（#、**、-列表等），禁用"前言"标题

## Writing Standards (铁律必须遵守)
### 1. 排版规则
- 场景切换用`……`，禁用`---`分隔线
- 单段≤3句，同一动作链不拆段
- 主语指代清晰，段落间空行分隔
- 标题独占一行，后接空行

### 2. Narrative Rules
- **Show, Don't Tell**: 用动作/选择体现性格，禁止情绪标签（如"心里五味杂陈"）
- **No Self-Exposition**: 禁止角色直接陈述动机（如"我是在利用你"）
- **Humor Principle**: 冷幽默/情境幽默优先，禁止刻意抖包袱
- **Rhythm Control**: 每3-5章一个小高潮，章末留钩子

### 3. Forbidden Content
- 禁用"仿佛/宛如/似乎/不禁/竟然"等弱化表达
- 禁用排比渲染、大段内心独白
- 禁用AI味结尾（如"故事才刚刚开始"）

## Format Repair Tools
### Common Fixes
1. **Leading Period Removal**: `grep -c "^。 " ./玄幻小说-异界大陆/第*.md`（结果应为0）
2. **Title Standardization**: 统一为`# 第X章：标题`格式
3. **Paragraph Merge**: 合并断行诗式的零散段落（仅拟声词/转折点可独占一行）

## Self-Check Flow (每章必做)
### 7-Dimension Scan
1. **AI Remove**: 禁用仿佛/宛如等词、排比渲染、旁白评价
2. **Dialogue Identity**: 角色语气符合身份、有区分度
3. **Scene Description**: 情绪用画面传达，不用抽象词
4. **Emotion Progression**: 段落情绪递进，高潮释放充分
5. **Rhythm Control**: 段落≤3句，爆发点单独成行
6. **Character Consistency**: 行为/语气符合人设
7. **Logical Coherence**: 主语清晰、动作链连贯、伏笔合理

### Output Requirements
- 问题按优先级（高→中→低）排序
- 提供5列对比表：序号/问题/改前/改后/理由
- 用户确认后统一修改

## File Management
- **Backup**: 每次修改前备份原文件到`./网文创作/backup/`，命名格式`章节名_vX.md`
- **Version Control**: 保留最近5个版本
- **Directory Structure**:
```
小说名/
├── 大纲/
│   ├── 总大纲.md
│   ├── 卷纲/
│   └── 人物设定/
├── 章节/
│   ├── 第001章_标题.md
│   └── ...
├── 素材/
│   ├── 参考资料/
│   └── 图片素材/
└── 版本记录/
    └── 更新日志.md
```