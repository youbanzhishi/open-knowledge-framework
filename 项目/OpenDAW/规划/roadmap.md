# OpenDAW 路线图

> 提取自项目INDEX.md、终极架构蓝图及对话历史
> 最后更新：2026-07-14

---

## 已完成阶段

### Phase 1-7：CLI 插件 + 预设 ✅

- [x] 26个VC插件（23效果器+3乐器）
- [x] CLI运行框架
- [x] 预设系统

### Phase 8-10：Web UI + 频谱 + MIDI ✅

- [x] FastAPI Web服务
- [x] 频谱可视化
- [x] MIDI基础解析

### Phase 11-13：AI 混音 + Tauri 桌面壳 ✅

- [x] Demucs音源分离集成
- [x] AI自动混音
- [x] Tauri v2桌面应用骨架

### Phase 14-16：VST3 宿主 + 实时引擎 + 打包 ✅

- [x] Rust引擎5 crate初始版本
- [x] VST3 Host Bridge
- [x] 实时引擎原型

### Phase 17-18：AI 编曲 + 协作编辑 ✅

- [x] 风格迁移引擎
- [x] 多人协作基础

### Phase 19：Rust 引擎核心开发 ✅

- [x] feature/daw-next分支，9491行Rust

### Phase 20：VST3 + CLAP + 技术债修复 ✅

- [x] VST3适配器（rack crate + Vst3Adapter）
- [x] CLAP适配器（clack-host + ClapAdapter）
- [x] 4个技术债修复（jsfx/bridge/plugin-host/tauri）

### Phase 21：JSFX EEL2 VM ✅

- [x] EEL2 Parser → AST → 字节码编译 → VM执行
- [x] @init/@slider/@sample支持
- [x] 基本运算 + spl0/spl1 + sliderN
- [x] 内置函数（sin/cos/min/max等）
- [x] 37个测试全绿

### Phase 22：MIDI 引擎增强 ✅

- [x] 硬件MIDI设备管理
- [x] 量化（Quantize）
- [x] Humanize
- [x] CC映射
- [x] 虚拟MIDI通道管理

### Phase 23：Plugin Host 统一抽象 ✅

- [x] 统一VcPlugin接口
- [x] PluginAdapter适配器体系
- [x] 信号链处理

### Phase 24：ClapHost 集成 ✅

- [x] VST3/AU/LV2 → CLAP Wrapper

### Phase 25：引擎集成测试 ✅

- [x] 三引擎联合测试
- [x] 延迟基准 + 内存基准
- [x] 176/177测试绿

### Phase 26：项目格式升级 ✅

- [x] 多轨 + 效果链 + 自动化 + 快照
- [x] YAML ↔ JSON ↔ Binary互转
- [x] 命令模式 Undo/Redo

### Phase 27：高级混音 ✅

- [x] Sidechain路由
- [x] 多级Bus
- [x] 自动化曲线编辑器

### Phase 28：编曲引擎增强 ✅

- [x] Pattern库
- [x] 和弦进行生成器
- [x] 时间线管理

### Phase 29：AI 引擎深度集成 ✅

- [x] 扒带→项目闭环（transcription）
- [x] 智能混音v2（smart_mix）
- [x] 风格迁移v2（style_transfer）

### Phase 30：跨 DAW 格式兼容 ✅

- [x] Reaper RPP导入
- [x] Ableton ALS解析
- [x] MIDI导出

### Phase 31-32：接口层后端 ✅

- [x] REST API完整实现
- [x] WebSocket实时同步
- [x] CLI Shell增强
- [x] 插件市场骨架

### Phase 33-34：插件市场 + CRDT 协作 ✅

- [x] PluginRepository + Review体系
- [x] CRDT冲突解决
- [x] CommentThread协作

### Phase 35：v1.0 发布与生态 ✅

- [x] 版本1.0.0
- [x] OpenAPI文档
- [x] 5个项目模板
- [x] 音频导出
- [x] 完整文档体系
- [x] CI/CD（check→test→fmt + Release + Docker + Desktop Build）

---

## 未来阶段

### Phase 36：LV2 插件支持

- [ ] LV2插件适配器
- [ ] Linux生态补充

### Phase 37：AU 插件支持（macOS）

- [ ] Audio Unit适配器（rack crate macOS分支）
- [ ] macOS专属插件宿主

### Phase 38：Analyzer 数据驱动混音

- [ ] Analyzer模块完整实现
- [ ] LUFS/RMS/频谱实时分析
- [ ] 数据驱动混音建议引擎
- [ ] 混音报告生成

### Phase 39：实时协作深化

- [ ] OT/CRDT性能优化
- [ ] 大规模协作压力测试
- [ ] 协作权限细粒度控制

### Phase 40+：AI 混音智能体

- [ ] 全自动AI混音（输入音频→输出混音成品）
- [ ] AI母带处理
- [ ] AI辅助编曲深化
- [ ] 用户模型微调（自带模型→注册→立即可用）

### 🔴 Phase 41：生态互联 — OpenLink + 知识体系 + Agent发现 📋 规划中

**目标：OpenDAW成为AI原生生态的核心节点，通过OpenLink协议与外部智能体互联**

> 这是OpenDAW从"独立工具"升级为"生态核心"的关键一步。Agent通过OpenLink发现知识体系→理解规则→使用DAW。

**功能清单：**
- [ ] OpenLink Agent发现协议集成
  - DAW注册到 `/.well-known/agent.json` 的 capabilities 中
  - 外部Agent通过OpenLink发现DAW的音频处理能力
- [ ] 知识体系互联
  - DAW角色（混音工程师/编曲助手）作为知识体系的一等公民
  - Agent通过OpenLink加入知识体系后，自动获取DAW相关角色RULES
  - 混音经验/预设/插件知识沉淀到知识体系
- [ ] OpenLink文件传输集成
  - 音频文件通过OpenLink CloudRelay/DirectTransfer传输
  - 项目文件分享（深链接拉起DAW）
- [ ] JSFX脚本分发
  - JSFX脚本通过OpenLink Action分发安装
  - 用户创作JSFX → 注册到扩展市场 → 一键安装到其他DAW实例
- [ ] AI Agent直接操控DAW
  - Agent通过API/CLI/YAML完全操控DAW（GUI不含业务逻辑）
  - Agent可执行：创建项目→导入音频→加载效果器→混音→导出
  - 三层记忆架构：Agent记住用户偏好/混音习惯/审美画像

**验收标准：**
1. 外部Agent通过OpenLink链接自动发现DAW能力
2. Agent通过知识体系RULES理解如何使用DAW
3. Agent可完全通过API完成混音工作流（无需GUI）
4. 音频/项目文件可通过OpenLink跨设备传输

---

## 里程碑总览

| 里程碑 | Phase | 状态 |
|--------|-------|------|
| CLI插件体系 | 1-7 | ✅ |
| Web UI + AI | 8-13 | ✅ |
| Rust引擎奠基 | 14-20 | ✅ |
| 核心引擎层 | 21-25 | ✅ |
| 服务层完善 | 26-30 | ✅ |
| 接口层 + v1.0 | 31-35 | ✅ |
| 插件格式补全 | 36-37 | 📋 |
| AI深化 + 协作 | 38-39 | 📋 |
| AI混音智能体 | 40+ | 🔮 |
