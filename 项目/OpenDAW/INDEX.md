# OpenDAW 项目知识索引

> 最后更新：2026-07-10 | 更新人：主对话
> 用途：任何智能体接手OpenDAW相关任务时，先读本文件了解项目全貌

## 共享规范
→ ./共享知识/项目规范/（宪法层，改一次全局生效）
- 目录结构规范：最后同步 2026-07-10
- 协作规范：最后同步 2026-07-10
- 热规则规范：最后同步 2026-07-10
本项目已对齐：混合类（DAW+插件），规范骨架已建，中文目录待迁移

## 热规则
→ 规划/hot-rules.md（派发任务时必须注入，防重复踩坑）

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|
| 目录结构 | 混存中文目录（内容/开发日志/知识沉淀/运营）| 历史原因，后续迭代迁移到docs/下 |
| 混合类 | output下有releases/mixes子目录 | DAW特有需求（发布产物+混音导出） |

## 目录自愈

此项目按混合类（DAW+插件）目录结构规范，执行任何操作前运行：
```bash
mkdir -p ./回收站 && mkdir -p ./项目/OpenDAW/规划 ./项目/OpenDAW/src ./项目/OpenDAW/tests ./项目/OpenDAW/docs/dev-log ./项目/OpenDAW/docs/knowledge ./项目/OpenDAW/assets/images ./项目/OpenDAW/assets/templates ./项目/OpenDAW/assets/data ./项目/OpenDAW/output/releases ./项目/OpenDAW/output/mixes ./项目/OpenDAW/config ./项目/OpenDAW/scripts ./项目/OpenDAW/feedback
```

⚠️ 文件安全铁律：删除→mv到./回收站/OpenDAW-$(date +%m%d)/，禁止rm

## 项目定位

**OpenDAW不是又一个DAW，是AI原生的开源音频工作站——让DAW长出大脑。**

- 当下：Rust重写CLI+API+WebSocket引擎 + 9个Rust crate + Tauri v2桌面应用(AppImage/dmg/exe/msi) + Python VCMix(历史版)
- 近未来：完整桌面DAW体验 + VST3/CLAP插件宿主 + JSFX兼容 + 大师级AI助手
- 远期：超越Reaper的开源DAW，无限扩展性是核心护城河

一句话：**Reaper有的我们要有，Reaper没有的也要有。**

→ 终极架构蓝图：[docs/knowledge/OpenDAW-终极架构蓝图.md](../docs/knowledge/OpenDAW-终极架构蓝图.md)

## 领域术语

| 术语 | 本项目含义 | 别义/易混 | 备注 |
|------|-----------|----------|------|
| 扩展/Extension | Extension Registry注册的功能模块 | Skill扩展（体系级）| 新功能=注册扩展，架构本身不改 |
| 插件/Plugin | 运行在DAW内的音频处理器（VST3/CLAP/JSFX）| 浏览器插件 | AudioFX产出VST3/CLAP，JSFX是Reaper脚本插件 |
| JSFX | Reaper自定义效果器脚本语言 | VST3插件 | EEL2 VM执行，OpenDAW杀手级差异化 |
| 混音链/Chain | 多个效果器的串联组合 | 信号链/Signal Chain | VC-Chain兼容Waves StudioRack .xps格式 |
| Agent Plugin | 嵌入DAW的AI混音助手 | 外部MCP Agent | 内置对话+可进化，区别于外部操控的MCP Server |
| MCP Server | 外部Agent操控DAW的接口 | 内置Agent Plugin | OpenClaw/Hermes等通过MCP协议操控 |
| 宿主/Host | 加载并运行插件的DAW程序 | 服务器主机 | plugin-host crate负责VST3/CLAP加载 |
| 轨道/Track | 音频/MIDI的时间线容器 | Git分支/追踪 | 前端14模块核心概念 |
| Crate | Rust编译单元（OpenDAW有9个）| Cargo crate | core/api/ws/cli/engine/extension/plugin-host/desktop/jsfx |
| Phase | 开发阶段编号（已完成35个Phase）| 构建阶段 | Phase 1-35对应CLI→AI→v1.0发布完整路线 |

## 核心知识

### 产品特性（开发↔运营 共享）

| 特性 | 说明 | 详见 |
|------|------|------|
| 26个VC插件 | 23效果器+3乐器，CLI运行 | [docs/knowledge/VocalChain插件系列产品设计文档.md](../docs/knowledge/VocalChain插件系列产品设计文档.md) |
| YAML混音宿主 | 纯文本定义项目，git友好 | [docs/knowledge/VCMix架构总览.md](../docs/knowledge/VCMix架构总览.md) |
| Agent Plugin | 嵌入DAW的AI混音助手，可对话+可进化 | [docs/knowledge/VCMix-AgentPlugin设计.md](../docs/knowledge/VCMix-AgentPlugin设计.md) |
| MCP Server | OpenClaw/Hermes等外部Agent可操控DAW | 同上 |
| WebSocket实时推送 | Agent操作用户实时可见 | [docs/knowledge/开发日志-20260509.md](../docs/knowledge/开发日志-20260509.md) |
| VC-Chain混音链 | 兼容Waves StudioRack .xps，社区分享 | [docs/knowledge/VC-Chain设计.md](../docs/knowledge/VC-Chain设计.md) |
| Extension Registry | 四柱：Plugin API/Script Runtime/Model Bus/Hook System | [共享知识/设计模式/extension-registry.md](../../共享知识/设计模式/extension-registry.md) |
| JSFX兼容 | EEL2 VM跑Reaper自定义效果器，其他DAW做不到 | [docs/knowledge/REAPER-JS插件vs-VST3插件对比.md](../docs/knowledge/REAPER-JS插件vs-VST3插件对比.md) |
| 62个API端点 | 55原有+7 Agent接口，完整操控DAW | 仓库 /tmp/OpenDAW/ |
| Agent发现协议 | `/.well-known/agent.json` — 智能体自发现端点 | crates/opendaw-api/src/api.rs |

### 文档体系（2026-05-11 标配）

| 文档 | 路径 | 说明 |
|------|------|------|
| 用户文档 | docs/user-guide.md | 完整使用指南（安装/AI模型配置/Agent功能/混音/导出/FAQ） |
| Agent指南 | docs/agent-guide.md | AI智能体内置指南（API速查/工作流/对话协议/YAML格式） |
| Agent发现 | GET /.well-known/agent.json | 智能体自发现端点（capabilities/API/配置/links） |
| API参考 | docs/api-reference.md | HTTP API完整参考 |
| 架构文档 | docs/architecture.md | 系统架构设计 |
| 部署指南 | docs/deployment.md | Docker+二进制+源码+systemd+生产环境 |

### 技术架构（开发关注）

| 维度 | 选择 | 详见 |
|------|------|------|
| 语言 | Python(业务层) + Rust(引擎层) | [共享知识/设计模式/extension-registry.md#Python+Rust混合架构](../../共享知识/设计模式/extension-registry.md) |
| 框架 | FastAPI(Python) + Axum(Rust,规划中) | [docs/knowledge/VCMix架构总览.md](../docs/knowledge/VCMix架构总览.md) |
| 桌面壳 | Tauri v2 + WebView + 专业DAW前端(触控支持) | [docs/knowledge/Phase13-Tauri桌面壳深化.md](../docs/knowledge/Phase13-Tauri桌面壳深化.md) |
| Rust引擎 | 9 crate: opendaw-core, opendaw-api, opendaw-ws, opendaw-cli, audio-engine, jsfx-engine, opendaw-extension, plugin-host, desktop/src-tauri(Tauri v2) | [docs/knowledge/OpenDAW-v0.24.0-集成方案.md](../docs/knowledge/OpenDAW-v0.24.0-集成方案.md) |
| 核心哲学 | 新功能=注册扩展，架构永远不需要改 | [共享知识/设计模式/extension-registry.md](../../共享知识/设计模式/extension-registry.md) |
| 混合架构 | Tauri(AppState)→Rust后端(内置，不再走Python) | [共享知识/CI模式库/python-ci.md#9](../../共享知识/CI模式库/python-ci.md) |
| CI | GitHub Actions（check→test→fmt + Release + Docker + Desktop Build） | justfile + scripts/ |
| 发布 | GHCR Docker镜像+GitHub Release二进制+Tauri桌面安装包 | .github/workflows/release.yml |

### 前端架构（2026-05-12 重做）

| 维度 | 选择 | 说明 |
|------|------|------|
| 框架 | 纯 HTML/CSS/JS（无 React/Vue） | 保持轻量，Tauri WebView 直接加载 |
| 布局 | 专业 DAW 四面板 | 传输栏/轨道列表(左)/编曲区(中)/检视器(右)+混音台(底) |
| 渲染 | Canvas 波形/时间线/MIDI | 500+ 音轨性能要求 |
| 触控 | Pointer Events API | 统一鼠标/触摸/笔，双指缩放，长按菜单 |
| 响应式 | CSS Grid + media queries | 桌面/平板/手机三档自动切换 |
| 主题 | CSS 自定义属性 | dark/midnight 两套 |
| 模块 | 14 JS IIFE 模块 | components/ + canvas/ + utils/ + app.js |
| 虚拟键盘 | 多指触控钢琴 | 底部弹出，支持 MIDI 输入 |

→ 前端踩坑经验：[../../角色/前端开发/knowledge/OpenDAW前端踩坑.md](../../角色/前端开发/knowledge/OpenDAW前端踩坑.md)

### 运营卖点（运营关注）

- **核心差异化**：传统DAW你调参数，OpenDAW你跟AI说话——"人声太闷"自动修
- **目标用户**：独立音乐人 / 卧室制作人 / 混音新手 / 开源爱好者
- **一句话定位**：让DAW长出大脑——AI原生的开源音频工作站
- **核心类比**：Cursor之于代码编辑器 = OpenDAW之于传统DAW
- **Waves兼容**：能导入Waves StudioRack的混音链，零成本迁移
- **开放生态**：MCP协议让任何Agent框架都能操控DAW，不是孤岛
- **无限扩展**：新功能=装插件，DAW本身永远不需要改

### 内容素材（内容关注）

- **教程方向**：YAML混音入门 → AI助手对话 → 混音链分享 → 插件开发 → Rust引擎
- **核心类比**：Cursor for DAW / Agent是录音棚首席工程师 / VC-Chain是开源版StudioRack
- **与Reaper的对比**：JSFX兼容=杀手级差异化，YAML项目文件=git友好
- **与OpenLink的关系**：同架构不同领域，Rust+Extension Registry统一哲学

## 项目状态

| 阶段 | 状态 | 说明 |
|------|------|------|
| Phase 1-7：CLI插件+预设 | ✅ 已完成 | 26个VC插件 |
| Phase 8-10：Web UI+频谱+MIDI | ✅ 已完成 | FastAPI+前端 |
| Phase 11-13：AI混音+Tauri桌面壳 | ✅ 已完成 | Demucs+Tauri v2 |
| Phase 14-16：VST3宿主+实时引擎+打包 | ✅ 已完成 | Rust引擎5 crate |
| Phase 17-18：AI编曲+协作编辑 | ✅ 已完成 | 风格迁移+多人协作 |
| Phase 19：Rust引擎核心开发 | ✅ 已完成 | feature/daw-next 9491行 |
| Phase 20：技术债修复+集成 | ✅ 已完成 | 4个技术债全部修完 |
| Phase 21-23：核心引擎层(JSFX+PluginHost+MIDI) | ✅ 已完成 | 5 Rust crate, 176/177测试绿 |
| Phase 26-28：服务层(项目格式+高级混音+编曲) | ✅ 已完成 | +5382行, commit 8181938+6a54bdb |
| Phase 29-30：AI引擎深度集成+跨DAW格式兼容 | ✅ 已完成 | transcription+smart_mix+style_transfer+import+export |
| Phase 31-32：接口层后端 | ✅ 已完成 | REST API+WebSocket+CLI Shell+插件市场 |
| Phase 33-34：插件市场完善+CRDT协作 | ✅ 已完成 | PluginRepository+Review+CRDT+CommentThread |
| Phase 35：v1.0发布与生态 | ✅ 已完成 | 版本1.0.0+OpenAPI+模板+音频导出+文档+CI |

- GitHub仓库：https://github.com/youbanzhishi/OpenDAW
- Docker镜像：ghcr.io/youbanzhishi/opendaw/opendaw:latest
- 当前版本：**v1.0.1** | ~47000行Rust | 9 crates
- OpenLink镜像：ghcr.io/youbanzhishi/openlink/openlink:latest → [部署文档](https://github.com/youbanzhishi/OpenLink/blob/main/docs/deployment.md)
- OpenVault镜像：ghcr.io/youbanzhishi/openvault/openvault:latest → [部署文档](https://github.com/youbanzhishi/OpenVault/blob/main/docs/deployment.md)
- 交付步门：①check ②test ③本地build+smoke ④CI多平台Release ⑤Tauri桌面应用构建(仅GUI项目)

## 联盟项目
| 项目 | 路径 | 关系 | 共享知识 |
|------|------|------|----------|
| OpenDAW | ./项目/OpenDAW/ | DAW核心+插件宿主 | 音频引擎/信号链/扩展注册 |
| AudioFX | ./项目/AudioFX/ | VC插件基础(C++/JUCE) | DSP/插件设计/混音经验 |
| OpenLink | ./项目/OpenLink/ | 同架构不同领域 | Extension Registry/架构模式 |
| OpenVault | ./项目/OpenVault/ | 保险层 | 存储引擎/备份策略 |
| open-dev-tools | ./项目/open-dev-tools/ | 共享构建工具链 | CI模板/构建脚本 |

| 项目 | 关系 | 详见 |
|------|------|------|
| AudioFX | VC插件的基础，C++/JUCE | [../AudioFX/INDEX.md](../AudioFX/INDEX.md) |
| OpenLink | 同架构不同领域，Extension Registry同构 | [../OpenLink/INDEX.md](../OpenLink/INDEX.md) |
| OpenVault | 保险层，OpenLink管运输OpenVault管不丢 | [../OpenVault/INDEX.md](../OpenVault/INDEX.md) |
| open-dev-tools | 共享构建工具链和CI模板 | [../open-dev-tools/INDEX.md](../open-dev-tools/INDEX.md) |
| 共享知识库 | 踩坑记录+CI模式+设计模式 | [../../共享知识/README.md](../../共享知识/README.md) |

## 职能分工

| 职能 | 负责session | 产出目录 |
|------|------------|---------|
| 开发 | 主对话 | 仓库 /tmp/OpenDAW/ + [docs/knowledge/](../docs/knowledge/) |
| 运营 | 待分配 | [项目/OpenDAW/运营/](运营/) |
| 内容 | 待分配 | [项目/OpenDAW/内容/](内容/) |

## 最近变更

| 日期 | 变更 | 详见 |
|------|------|------|
| 2026-07-10 | **视觉驱动UI测试方案储备** 基于Peekaboo v3分析，评估远期技术路线：渐进式三阶段（Playwright→Rust框架→视觉驱动框架） | [docs/knowledge/视觉驱动UI测试方案储备.md](docs/knowledge/视觉驱动UI测试方案储备.md) |
| 2026-07-10 | **ADR-001决策** OpenDAW视觉驱动UI测试采用渐进演进路径，非直接复刻或等待 | [docs/adr/ADR-001-视觉驱动UI测试技术路线.md](docs/adr/ADR-001-视觉驱动UI测试技术路线.md) |
| 2026-05-11 | **v1.0.1发布** 品牌升级VCMix→OpenDAW + Rust 1.86 + Docker镜像3仓库全就绪 + desktop.yml恢复 + 部署文档完善(3仓库) + 非Docker部署补充 | 本次更新 |
| 2026-05-10 | **v1.0.0发布** Phase21-35全部完成，9 crate ~47000行Rust | [docs/dev-log/2026-05-10.md](docs/dev-log/2026-05-10.md) |
| 2026-05-10 | **测试修复全绿** 16个测试失败修复，621测试全绿，commit d40960d | 同上 |
| 2026-05-10 | **第三步门通过** Linux x86_64 release构建+二进制上传Release | 同上 |
| 2026-05-10 | Phase35: 版本1.0.0+OpenAPI+5模板+音频导出+3文档+CI/CD | 同上 |
| 2026-05-10 | Phase33-34: 插件市场+CRDT协作，77测试 | 同上 |
| 2026-05-10 | Phase31-32: REST API+WebSocket+CLI Shell+插件市场，88测试 | 同上 |
| 2026-05-10 | Phase29-30: AI引擎+跨DAW格式兼容 | 同上 |
| 2026-05-09 | v0.23.0发布（CI修复6轮+GLIBC兼容性） | [docs/knowledge/开发日志-20260509.md](../docs/knowledge/开发日志-20260509.md) |
| 2026-05-09 | 4个技术债全部修完（jsfx/bridge/plugin-host/tauri） | 同上 |
| 2026-05-09 | WebSocket实时推送（API操作→前端实时刷新） | 同上 |
| 2026-05-09 | Agent Plugin Phase 22a（Runtime+ToolBox+MCP+ChatPanel） | [docs/knowledge/VCMix-AgentPlugin设计.md](../docs/knowledge/VCMix-AgentPlugin设计.md) |
| 2026-05-09 | VC-Chain混音链（.xps兼容+8Macro+ChainVerse） | [docs/knowledge/VC-Chain设计.md](../docs/knowledge/VC-Chain设计.md) |
| 2026-05-09 | CI重构（用共享知识库最佳实践） | justfile + scripts/ |
| 2026-05-09 | 贡献3个踩坑记录到共享知识库 | [共享知识/踩坑记录/rust-oom.md](../../共享知识/踩坑记录/rust-oom.md) |
## ⛔ 禁止项

- **禁止直接操作ECS服务器**：所有服务器操作（SSH/Remote Gateway/Docker管理）只能由ECS运维角色执行
- 需要部署/运维时：通过主对话转派给ECS运维角色，不要自己动手


## 部署信息

| 项目 | 部署文档 | 部署脚本 | 部署方式 | 服务器 |
|------|----------|----------|----------|--------|
| OpenDAW | `docs/deploy.md` | `scripts/deploy.sh` | Docker(ECS)/二进制(云电脑) | ECS+云电脑 |

> ⚠️ 以上路径为体系仓库内 `项目/OpenDAW/` 下的相对路径

**部署文档**：`角色/ECS运维/knowledge/快速部署指南.md`（Docker/二进制/源码编译三种方式）

**实际部署状态（2026-05-13）**：
- **ECS（Docker）**：可部署 ✅（v1.0.2 Docker镜像已含opendaw-api+Web UI，端口8080）
  - `docker pull ghcr.io/youbanzhishi/opendaw/opendaw:latest`
  - 浏览器访问 http://IP:8080/ → Web UI
  - API: http://IP:8080/api/v1/
- **云电脑（二进制直跑）**：等待opendaw-api二进制发布到Release
- 🔧 v1.0.2修复：Dockerfile改为构建opendaw-api + 打包前端到/app/static/ + tauri-bridge同源API

## 凭据

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | `github.pat` | 仓库 push/pull/CI |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。

## 关联角色

- 系统开发者（主）：Rust音频引擎开发、架构设计

## 可用工具

暂无，通过关联角色获得跨项目通用工具
## 反哺检查门（不过不算任务完成）

> 铁律4：产出结果≠任务完成。以下每项必须过，sub-agent返回时必须汇报反哺情况。
1. 更新本INDEX.md的"最近变更"
2. 项目特有事实 → 本项目 docs/knowledge/
3. 通用经验 → ./角色/系统开发者/knowledge/
4. 踩坑2次 → 本项目 规划/hot-rules.md
5. 发现跨角色通用模式 → ./共享知识/

## 已同步版本: 2026-05-11-v10

## CI/CD

| 项目 | 地址 |
|------|------|
| 仓库 | https://github.com/youbanzhishi/OpenDAW |
| Actions | https://github.com/youbanzhishi/OpenDAW/actions |
| CI | https://github.com/youbanzhishi/OpenDAW/actions/workflows/CI/ |
| Desktop Build | https://github.com/youbanzhishi/OpenDAW/actions/workflows/Desktop%20Build/ |
| Auto Format Fix | https://github.com/youbanzhishi/OpenDAW/actions/workflows/Auto%20Format%20Fix/ |
