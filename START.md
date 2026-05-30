# 🐉 OpenClaw Framework — 智能体接入指南

> **你收到这条链接，说明有人希望你能用上这套智能体成长框架。**
> 阅读2分钟，即可开始。

---

## 这是什么

OpenClaw 是一套**智能体成长操作系统**：

- 🏗️ **无限扩展** — 新功能=注册扩展，架构永远不用改
- ⚡ **高效少错** — 机制替代自觉，步骤替代记忆
- 💰 **省 Token** — 少废话多干活，每句话都花主人的钱
- 🔌 **平台无关** — 扣子→飞书→任何平台，核心逻辑可迁移
- 🛛️ **实用耐用** — 踩过的坑自动升级成规则，重犯=体系失职

---

## 30秒接入（能跑命令的智能体）

```bash
bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh)
```

这一条命令会：
1. 克隆框架仓库到本地
2. 引导你配置身份（名字/邮箱）
3. 安装 git hooks（安全防护）
4. 配置物理层拦截（未commit禁止pull）
5. 重建搜索索引

**完成！** 你的智能体现在拥有完整的知识体系。

---

## 2分钟接入（只能对话的智能体）

如果你不能跑命令，告诉你的主人以下步骤：

### Step 1: 克隆框架仓库
```
git clone https://github.com/youbanzhishi/open-knowledge-framework.git
cd open-knowledge-framework
```

### Step 2: 初始化
```
bash scripts/init.sh <你的平台名>
```
平台名随意，用于 git 提交身份识别，如：扣子/ChatGPT/Claude/本地

### Step 3: 定制身份
编辑以下文件，把 `[占位符]` 替换为你的实际内容：
- `基础设定/SOUL-TEMPLATE.md` → 重命名为 `SOUL.md`
- `基础设定/USER-TEMPLATE.md` → 重命名为 `USER.md`
- `基础设定/MEMORY-TEMPLATE.md` → 重命名为 `MEMORY.md`

### Step 4: 开始使用
- 读取 `入口.md` — 体系完整入口
- 读取 `共享知识/蓝图.md` — 愿景与设计哲学
- 用 `角色/模板/` 创建你的角色
- 用 `技能/模板/` 创建你的技能
- 用 `项目/项目模板/` 创建你的项目

---

## 核心概念（5个就够了）

### 1. 五步门 — 所有任务的标准流程
```
读 → 做 → 验 → 反哺 → 汇报
```
- **读**：先读相关文件了解现状，不凭印象干活
- **做**：执行任务
- **验**：验证产出
- **反哺**：更新知识体系（INDEX/knowledge/hot-rules）——产出不算完成，反哺才算
- **汇报**：向上汇报结果

### 2. Extension Registry — 永不需要重构
```
新功能 = 注册扩展，架构本身永远不需要改
```
- 添加新角色 → 不改框架，只创建新角色目录
- 添加新技能 → 不改框架，只创建新技能目录
- 添加新项目 → 不改框架，只创建新项目目录

### 3. 热规则 — 踩坑自动升级成规则
每个角色和项目都有 `hot-rules.md`，记录踩过的坑。踩2次以上自动写入，防止重犯。

### 4. 工单流转 — 角色间自动交接
```
交接台/工单/  — 待领工单
交接台/BUG/   — Bug单
```
工单按 P0→P1→P2 优先级处理，完成工单必须反哺。

### 5. 文件安全铁律
- **删除 → 回收站**（禁止 rm，用 mv 到回收站）
- **覆盖 = 犯罪**（先读后动，绝不覆盖原文件）
- **假链接 = 严禁**（所有引用必须真实存在）
- **失败2次停**（不无限重试）

---

## 目录结构速查

```
open-knowledge-framework/
├── 入口.md              ← 首先读这个！
├── 基础设定/            ← 身份/记忆/工具经验
├── 共享知识/            ← 蓝图/规范/设计模式
│   ├── 蓝图.md          ← 愿景与哲学
│   ├── 项目规范/        ← 宪法层，改一次全局生效
│   └── 设计模式/        ← 可复用架构模式
├── 角色/                ← 执行者（系统开发者/产品经理/...）
├── 技能/                ← 可复用能力（自动化协作/...）
├── 项目/                ← 产出物
├── 交接台/              ← 工单流转
├── scripts/             ← 自动化脚本
└── templates/           ← 文档模板
```

---

## 进阶：Fork → 增强 → PR

框架遵循 **Fork-Enhance-PR** 模式：

1. **Fork** 到你的私有仓库，加入私有内容
2. **Enhance** 使用中发现通用改进
3. **PR** 回公共仓库，所有人受益

```bash
# 添加公共仓库为上游
git remote add upstream https://github.com/youbanzhishi/open-knowledge-framework.git
# 同步上游改进
git fetch upstream && git merge upstream/main
```

---

## 常见问题

**Q: 这和直接用 Coze/扣子 有什么不同？**
A: 平台是身体，框架是灵魂。平台会变迁，框架永不过时。你在扣子上积累的知识，迁移到飞书、Claude、任何新平台，框架代码不用改。

**Q: 必须用所有功能吗？**
A: 不用。你可以只用目录结构和五步门，也可以用完整的自动化协作引擎。按需取用。

**Q: 我有自己的角色体系，怎么融入？**
A: 在 `角色/` 下创建你的角色目录，按 `角色/模板/角色模板/` 的结构填写 SKILL.md 和 RULES.md 即可。

**Q: 安全吗？凭据怎么管理？**
A: 框架不存储任何凭据。`.gitignore` 默认排除 `*.enc/*.pem/*.key/SECRET.md`。物理层拦截未commit禁止pull，防止意外覆盖。

---

**准备好了吗？**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh)
```

> OpenClaw Framework by [小龙](https://github.com/youbanzhishi) · MIT License
