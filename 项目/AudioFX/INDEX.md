# AudioFX 项目知识索引

> 最后更新：2026-07-10 | 更新人：子任务(5项目入体系)
> 用途：任何智能体接手AudioFX相关任务时，先读本文件了解项目全貌

## 共享规范
→ ./共享知识/项目规范/（宪法层，改一次全局生效）
- 目录结构规范：最后同步 2026-07-10
- 协作规范：最后同步 2026-07-10
- 热规则规范：最后同步 2026-07-10
本项目已对齐：新建项目，按规范骨架建立

## 热规则
→ 规划/hot-rules.md（派发任务时必须注入，防重复踩坑）

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|
| （暂无偏差，项目按规范新建） | | |

## 目录自愈

此项目按开发类目录结构规范，执行任何操作前运行：
```bash
mkdir -p ./回收站 && mkdir -p ./项目/AudioFX/规划 ./项目/AudioFX/src ./项目/AudioFX/tests/integration ./项目/AudioFX/tests/fixtures ./项目/AudioFX/docs/dev-log ./项目/AudioFX/docs/knowledge ./项目/AudioFX/assets/images ./项目/AudioFX/assets/templates ./项目/AudioFX/assets/data ./项目/AudioFX/output ./项目/AudioFX/config ./项目/AudioFX/scripts ./项目/AudioFX/feedback
```

⚠️ 文件安全铁律：删除→mv到./回收站/AudioFX-$(date +%m%d)/，禁止rm

## 项目定位

**AudioFX是VC插件的基础库——C++/JUCE实现的DSP效果器引擎。**

- 当下：26个VC插件的底层DSP实现（C++/JUCE）
- 近未来：独立VST3/CLAP插件，可被任何DAW加载
- 远期：插件市场，社区可贡献效果器

一句话：**OpenDAW的灵魂在AI，AudioFX的灵魂在DSP。**

→ GitHub仓库：https://github.com/youbanzhishi/AudioFX

## 领域术语

| 术语 | 本项目含义 | 别义/易混 | 备注 |
|------|-----------|----------|------|
| VC插件 | VocalChain系列效果器/乐器（26个）| 通用VST插件 | 23效果器+3乐器，CLI运行 |
| 效果器/Effect | 音频信号处理器（EQ/Compressor/Reverb等）| 音效/SFX | DSP实现，非录音音效 |
| 乐器/Instrument | MIDI可控的音源（3个）| 物理乐器 | VC插件中3个为乐器 |
| DSP | 数字信号处理（本项目的核心算法层）| 通用数字信号 | C++/JUCE实现 |
| JUCE | 跨平台C++音频应用框架 | — | 支持VST3/AU/AAX/CLAP/StandAlone |
| Deploy Key | 仓库专用SSH密钥（id_ed25519）| 全局SSH密钥 | AudioFX仓库独立权限 |

## 核心知识

### 产品特性（开发↔运营 共享）

| 特性 | 说明 | 详见 |
|------|------|------|
| 26个VC插件 | 23效果器+3乐器，CLI运行 | [../OpenDAW/INDEX.md](../OpenDAW/INDEX.md) |
| JUCE框架 | 跨平台音频插件开发标准 | 规划/hot-rules.md |
| DSP引擎 | 实时音频处理核心 | docs/knowledge/ |
| VST3/CLAP输出 | 编译为独立插件格式 | 规划/roadmap.md |

### 技术架构（开发关注）

| 维度 | 选择 | 详见 |
|------|------|------|
| 语言 | C++17/20 | JUCE要求 |
| 框架 | JUCE 7.x | 跨平台音频插件 |
| 构建系统 | CMake + JUCE CMake | |
| CI | GitHub Actions（cmake→build→test） | .github/workflows/ |
| Deploy Key | id_ed25519（AudioFX仓库专用） | |

## 项目状态

| 阶段 | 状态 | 说明 |
|------|------|------|
| Phase 1：核心DSP效果器 | ✅ 已完成 | 26个VC插件 |
| Phase 2：独立VST3/CLAP编译 | 📋 规划中 | 脱离Python独立运行 |
| Phase 3：插件市场 | 📋 规划中 | 社区贡献+审核 |

- GitHub仓库：https://github.com/youbanzhishi/AudioFX
- Deploy Key：~/.ssh/id_ed25519（AudioFX仓库权限）

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
| OpenDAW | AudioFX的宿主，调用VC插件 | [../OpenDAW/INDEX.md](../OpenDAW/INDEX.md) |
| open-dev-tools | 共享CI模板（C++/JUCE justfile） | [../open-dev-tools/INDEX.md](../open-dev-tools/INDEX.md) |
| 共享知识库 | 踩坑记录+CI模式 | [../../共享知识/README.md](../../共享知识/README.md) |

## 关联技能
- C++/JUCE插件开发
- DSP信号处理
- CMake跨平台构建

## 最近变更

| 日期 | 变更 | 详见 |
|------|------|------|
| 2026-07-10 | 项目入知识体系，建骨架+INDEX.md | 本文件 |
| 2026-07-10 | 补充scripts(mixing-analysis+部署脚本)+docs/混音报告 | 本文件 |
## ⛔ 禁止项

- **禁止直接操作ECS服务器**：所有服务器操作（SSH/Remote Gateway/Docker管理）只能由ECS运维角色执行
- 需要部署/运维时：通过主对话转派给ECS运维角色，不要自己动手

## 部署信息
| 项目 | 部署文档 | 部署脚本 | 部署方式 | 服务器 |
|------|----------|----------|----------|--------|
| AudioFX | 待补充 | scripts/vc_mix.sh | VCMix(Docker@ECS) | 39.103.203.162 |


## 凭据

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | `github.pat` | 仓库 push/pull/CI |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。

## 关联角色

- 系统开发者（主）：C++/JUCE开发、DSP引擎设计

## 可用工具

### scripts/mixing-analysis/ — 混音分析脚本

| 文件 | 用途 |
|------|------|
| `jiuwan_v10_spectral.py` | 九万字混音分析v10（频谱对比，最终版） |
| `jiuwan_v11_minimal.py` | 九万字混音分析v11（极简版，最终版） |
| `generate_plots.py` | 生成频谱/响度等可视化图表 |
| `九万字-VCMix-project.yaml` | VCMix项目配置 |
| `九万字-VCMix-v9-project.yaml` | VCMix v9项目配置 |
| `analysis_v11.json` | v11版分析数据 |
| `grammy_analysis_results.json` | Grammy标准参考分析数据 |
| `九万字-干声分析报告.json` | 干声分析数据 |
| `archive/` | 中间版本归档（v4~v9脚本+历史分析数据） |

### scripts/ — 部署与测试脚本

| 文件 | 用途 |
|------|------|
| `vc_mix.sh` | VCMix部署脚本 |
| `run_tune_test.sh` | VC-Tune测试运行 |
| `compile_tune.sh` | VC-Tune编译 |

### docs/混音报告/ — 混音分析报告

15份混音分析/对比/处理报告（MD格式），涵盖VCMix各版本、母带修复、信号路由等
## 反哺检查门（不过不算任务完成）

> 铁律4：产出结果≠任务完成。以下每项必须过，sub-agent返回时必须汇报反哺情况。
1. 更新本INDEX.md的"最近变更"
2. 项目特有事实 → 本项目 docs/knowledge/
3. 通用经验 → ./角色/系统开发者/knowledge/
4. 踩坑2次 → 本项目 规划/hot-rules.md
5. 发现跨角色通用模式 → ./共享知识/

## 已同步版本: 2026-05-11-v10
