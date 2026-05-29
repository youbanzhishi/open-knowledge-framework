# OpenClaw Framework — 智能体成长框架

> **让任何智能体从"能用"到"好用"到"自己变更好用"**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Framework Version](https://img.shields.io/badge/Framework-v1.0-green.svg)](docs/CHANGELOG.md)

## 这是什么

OpenClaw Framework 是一套**智能体成长操作系统**——不是工具箱，不是模板库，是一套让智能体持续进化、高效协作、平台无关的成长机制。

### 核心哲学

| 哲学 | 含义 |
|------|------|
| 无限扩展 | 新功能=注册扩展，架构本身永远不需要改 |
| 高效少错 | 机制替代自觉，步骤替代记忆 |
| 省 Token | 每句话都花钱，少废话多干活 |
| 平台无关 | 抽象掉平台差异，核心逻辑可迁移 |
| 实用耐用 | 规则写在文件里，不靠人记住 |

## 快速开始

### 1. Fork 本仓库

```bash
# 在 GitHub 上 Fork 本仓库到你自己的账号
# 然后 clone 你的 Fork
git clone https://github.com/<你的用户名>/open-knowledge-framework.git
cd open-knowledge-framework
```

### 2. 一键初始化

```bash
bash scripts/init.sh <平台名>
# 平台名：扣子/元宝/云电脑/本地（必填，用于git提交身份识别）
```

init.sh 会自动：
- 配置 git 用户/token/remote
- 安装 git hooks（禁止强推、敏感文件检测）
- 配置物理层安全拦截（未 commit 禁止 pull）
- 重建搜索索引

### 3. 定制你的体系

```bash
# 1. 编辑身份设定
vim 基础设定/SOUL.md     # 你的智能体身份、性格、行为风格
vim 基础设定/USER.md     # 你的个人信息

# 2. 添加角色
cp -r 角色/模板/角色模板 角色/你的角色名
# 编辑 SKILL.md（能力说明）和 RULES.md（行为规则）

# 3. 添加项目
cp -r 项目/项目模板 项目/你的项目名
# 编辑 INDEX.md（项目知识索引）和 规划/roadmap.md

# 4. 添加技能
cp -r 技能/模板/技能模板 技能/你的技能名
# 编辑 SKILL.md（技能执行说明）
```

## 目录结构

```
open-knowledge-framework/
├── 入口.md                  # 体系入口（所有智能体首先读取）
├── 入口-快速启动.md          # 新智能体快速启动指南
├── README.md                # 本文件
├── LICENSE                  # MIT 许可证
├── 基础设定/
│   ├── SOUL.md              # 身份定义（需要定制）
│   ├── USER.md              # 用户画像（需要定制）
│   ├── TOOLS.md             # 工具操作经验（通用）
│   └── MEMORY.md            # 记忆管理规范（通用）
├── 共享知识/
│   ├── 蓝图.md              # 体系愿景与设计哲学
│   ├── 项目规范/            # 目录结构/协作/热规则等规范
│   ├── 设计模式/            # Extension Registry等可复用模式
│   └── CI模式库/            # 持续集成模式
├── 角色/
│   ├── INDEX.md             # 角色体系索引
│   └── 模板/                # 角色创建模板
├── 技能/
│   ├── INDEX.md             # 技能体系索引
│   └── 模板/                # 技能创建模板
├── 项目/
│   └── 模板/                # 项目创建模板
├── 交接台/                   # 工单流转系统
│   └── README.md            # 工单使用说明
├── scripts/                  # 自动化脚本
│   ├── init.sh              # 一键初始化
│   ├── push.sh              # 安全推送
│   ├── safe-pull.sh         # 安全拉取（未commit禁止pull）
│   ├── auto-collab.sh       # 自动化协作引擎
│   ├── act.sh               # 角色切换+意图检索
│   └── ...
├── templates/                # 文档模板
└── docs/
    ├── ARCHITECTURE.md       # 架构设计说明
    ├── CONTRIBUTING.md       # 贡献指南
    └── CHANGELOG.md          # 变更日志
```

## 核心机制

### 五步门（所有任务的标准流程）

1. **读** — 读取相关文件，了解现状
2. **做** — 执行任务
3. **验** — 验证产出
4. **反哺** — 更新知识体系（INDEX/knowledge/hot-rules）
5. **汇报** — 向上汇报结果

### 自动化协作引擎

支持四种模式：

| 模式 | 适用场景 | 说明 |
|------|---------|------|
| 匀速 | 日常维护 | 每4小时触发，3轮上限 |
| 加速 | 单项目冲刺 | 循环往复直到蓝图达标 |
| 并行 | 多项目推进 | 项目分组并行处理 |
| 聚焦 | 项目优先级不同 | 白名单项目优先，其他冻结 |

### 物理层安全

- **未 commit 禁止 pull**：git alias + shell function 双重拦截
- **禁止强推**：pre-push hook 自动拦截
- **敏感文件检测**：pre-commit hook 检测 SECRET/key/pem 文件
- **Token 泄露检测**：pre-commit hook 扫描明文 token

## Fork → 增强 → PR

本框架遵循 **Fork-Enhance-PR** 模式：

1. **Fork** — 克隆到你的私有仓库，加入你的私有内容（项目/角色/凭据）
2. **Enhance** — 使用过程中发现通用改进 → 提交 PR 回公共仓库
3. **Upstream Sync** — 定期从公共仓库拉取通用改进到你的私有仓库

```bash
# 添加公共仓库为上游
git remote add upstream https://github.com/youbanzhishi/open-knowledge-framework.git

# 同步上游通用改进
git fetch upstream
git merge upstream/main
```

### 什么应该 PR 回来

- ✅ 通用角色模板改进
- ✅ 脚本 bug 修复或功能增强
- ✅ 新的通用设计模式
- ✅ 规范文档改进
- ✅ 新的角色/技能/项目模板

### 什么不应该 PR

- ❌ 你的私有项目内容
- ❌ 你的个人信息/凭据
- ❌ 与你的具体业务相关的定制

## 创始人

**OpenClaw Framework** 由 [小龙](https://github.com/youbanzhishi) 发起并维护。

灵感来源于在 Coze/扣子平台上构建智能体知识体系的实践经验，希望让更多人和智能体受益于这套成长机制。

## 许可证

MIT License — 自由使用、修改、分发。详见 [LICENSE](LICENSE)。
