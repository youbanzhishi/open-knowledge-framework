# OpenDAW 关键设计决策

> 提取自项目INDEX.md、终极架构蓝图、共享设计模式及对话历史
> 最后更新：2026-07-14

---

## ADR-001：为什么选 Rust 重写（从 VCMix Python 迁移）

### 背景

VCMix 最初用 Python 实现（FastAPI + sounddevice + numpy），Phase 1-19 全部基于 Python。随着项目从"命令行混音工具"升级为"实时音频工作站"，Python 的 GIL 限制和实时性能瓶颈成为硬伤。

### 决策

Phase 19 起用 Rust 重写核心引擎，Python 保留为业务层（FastAPI API + AI/ML 生态），通过 PyO3 FFI 桥接。

### 理由

| 维度 | Python 限制 | Rust 优势 |
|------|------------|-----------|
| 实时性 | GIL 限制实时处理，延迟 >50ms | 零成本抽象，<10ms round-trip |
| 内存安全 | 运行时错误，buffer 竞争 | 编译期保证，无数据竞争 |
| 跨平台 | sounddevice 依赖系统库，打包复杂 | CPAL 原生跨平台 |
| AI 生态 | 强（PyTorch/Demucs） | 弱，但通过 PyO3 直接用 Python |
| 插件宿主 | 无法安全加载第三方二进制 | Rust + ClapHost 原生安全 |

### 后果

- **正面**：实时性能飞跃、内存安全、与 OpenLink/OpenVault 统一技术栈
- **负面**：开发周期加长、Rust 学习曲线、PyO3 桥接层复杂度
- **缓解**：渐进式替换（Phase 20-25 可选启用，Phase 25+ 默认 Rust），Python 引擎保留为 fallback

---

## ADR-002：为什么 JSFX 兼容是杀手级差异化

### 背景

OpenDAW 的插件兼容战略：VST3/CLAP/JSFX/LV2/AU，其中 JSFX 是 Reaper 独有的脚本效果器格式，其他 DAW 均不支持。

### 决策

Phase 21 实现完整的 JSFX 兼容层（EEL2 VM），作为核心差异化卖点。优先级仅次于 VST3/CLAP。

### 理由

1. **零迁移成本**：Reaper 用户的 JSFX 脚本可直接在 OpenDAW 运行，无需任何修改
2. **独家能力**：除 Reaper 外无任何 DAW 能运行 JSFX，这是技术护城河
3. **社区资产**：Reaper 社区积累了大量高质量 JSFX 脚本，免费资源
4. **纯文本哲学**：JSFX 是纯文本 EEL2 脚本，与 OpenDAW 的"YAML 项目文件 + CLI 一等公民"哲学高度契合
5. **脚本扩展**：JSFX 本质是一种脚本扩展，与 Extension Registry 的 Script Runtime 柱天然对接

### 后果

- **正面**：Reaper 用户迁移诱因极强、技术差异化显著、社区口碑效应
- **负面**：EEL2 语言特异，VM 实现工作量大；JSFX 生态不如 VST3 广
- **实现**：jsfx-engine crate — EEL2 Parser → AST → 字节码编译 → VM 逐采样执行

---

## ADR-003：双轨 UI 策略（CLI 给 AI，GUI 给人）

### 背景

DAW 传统上以 GUI 为中心，CLI 能力弱。AI Agent 需要程序化操控 DAW，但传统 DAW 的 GUI 优先架构导致 API 覆盖不全。

### 决策

CLI 是一等公民，所有功能必须可通过 CLI/API 完成；GUI（Tauri + Web）是 CLI 的可视化壳，不含业务逻辑。

### 理由

1. **AI Agent 友好**：Agent 通过 CLI/YAML/API 完整操控 DAW，不需要模拟点击
2. **自动化友好**：CI/CD 管道可直接调用 CLI 渲染，批量处理
3. **Git 友好**：YAML 项目文件可版本控制，diff 可读
4. **解耦**：前后端分离，GUI 可热更新，后端稳定
5. **验证**：CLI 覆盖率 = 功能覆盖率，CLI 不能做 = 功能缺失

### 后果

- **正面**：AI Agent 生态天然友好、自动化能力强、架构清晰
- **负面**：CLI 优先增加开发量、部分功能 CLI 表达不如 GUI 直观
- **设计**：Tauri 前端通过 REST API + WebSocket 与后端通信，所有操作等价于 CLI/API 调用

---

## ADR-004：Extension Registry 四柱设计

### 背景

传统 DAW 的扩展能力是后加的（如 Reaper 的 ReaScript），API 不统一、覆盖不全。OpenDAW 需要从第一天就把扩展能力作为地基。

### 决策

采用 Extension Registry 四柱模型：Plugin API + Script Runtime + Model Bus + Hook System。新功能 = 注册扩展，架构本身永远不需要改。

### 理由

| 柱 | 覆盖场景 | 注册什么 |
|----|---------|---------|
| Plugin API | 音频/DSP 效果器、乐器 | 执行行为 |
| Script Runtime | Python/Lua/JS 脚本扩展 | 逻辑可编程 |
| Model Bus | AI 模型可插拔 | 数据可流转 |
| Hook System | 事件钩子、拦截器 | 流程可拦截 |

四柱覆盖所有扩展场景，永不需要新增柱。与 OpenLink（Action/Condition/Hook/Protocol）和 OpenVault（Policy/Classifier/Inventory/Verifier）同构。

### 后果

- **正面**：核心层零业务逻辑、扩展即插即用、三个项目共享 crate（open-registry/open-hooks/open-bus）
- **负面**：扩展 API 版本化管理复杂度、注册表性能开销
- **缓解**：Extension API 一旦发布保证向后兼容，核心内部可自由重构

---

## ADR-005：品牌升级 VCMix → OpenDAW

### 背景

项目最初名为 VCMix（Vocal Chain Mixer），定位是"人声链混音工具"。Phase 1-19 扩展后已远超混音工具范畴，成为完整的音频工作站。

### 决策

Phase 35（v1.0.0）正式更名为 OpenDAW，品牌定位升级为"AI 原生的开源音频工作站"。

### 理由

1. **定位匹配**：VCMix 暗示"只是混音"，OpenDAW 明确是完整 DAW
2. **开源身份**：Open 前缀与 OpenLink/OpenVault 形成品牌矩阵
3. **AI 原生**：DAW + AI 是核心定位，不是"混音工具 + AI"
4. **生态协同**：Open* 系列共享架构哲学（Extension Registry + Rust 统一栈）
5. **社区认知**：DAW 是开发者社区通用的品类词

### 后果

- **正面**：品牌清晰、生态协同、社区识别度高
- **负面**：已有用户需适应新名、代码/文档中残留 VCMix 引用需逐步清理
- **现状**：v1.0.1 已完成品牌升级，GitHub 仓库已迁移

---

## ADR-006：Analyzer 模块的数据驱动混音愿景

### 背景

传统 DAW 的分析器是"只读仪表盘"——你看得到问题，但要手动调。AI 混音助手只能基于规则或用户描述，缺乏数据驱动的反馈闭环。

### 决策

Analyzer 模块设计为数据驱动的混音闭环：render → analyze → adjust → verify。分析结果直接喂入 AI 混音引擎，形成自动优化循环。

### 理由

1. **闭环 vs 开环**：传统 DAW 是开环（分析→人调），OpenDAW 是闭环（分析→AI调→验证）
2. **数据基础**：LUFS/RMS/频谱/相位等指标量化，AI 决策有据可依
3. **渐进增强**：Phase 1-19 的 automix 已有基础，Analyzer 让 AI 从"凭感觉"升级为"看数据"
4. **可视化**：分析数据实时推送到 GUI（WebSocket），用户也能受益

### 后果

- **正面**：AI 混音质量提升、用户也能获得专业级分析、为 AI 混音智能体铺路
- **负面**：实时分析有 CPU 开销、分析标准需持续对标行业
- **规划**：Phase 38 完整实现，当前架构已预留 Analyzer 数据流通道
