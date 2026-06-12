# OpenLink 路线图

> 提取自 [项目规划.md](../项目规划.md) 第九~十一章
> 最后更新：2026-05-30

---

## Phase 1：地基 — 核心原语 + 基础短链 ✅ 已完成

**目标：跑通最短路径，传统短链能力100%覆盖**

- [x] 5个核心原语的数据结构定义
- [x] 路由引擎核心：Context → Rule匹配 → Action调度
- [x] Extension Registry框架（注册/查询/调用）
- [x] Redirect Action（传统短链重定向）
- [x] HTTP API：短链CRUD + 重定向
- [x] SQLite存储
- [x] Docker单容器部署

**验收标准：** `curl d.aw/abc` 返回302重定向，传统短链完全可用

**成果：** 3270行/36文件/30测试通过

---

## Phase 2：扩展骨架 — 动态路由 + Hook ✅ 已完成

**目标：证明架构的扩展性**

- [x] 条件路由（identity/device/location匹配）
- [x] Webhook Action扩展
- [x] BeforeRoute/AfterRoute Hook机制
- [x] 访问日志 + 基础统计
- [x] API认证（Token）

**验收标准：** 同一短链，浏览器访问跳网页，curl访问返回JSON

**成果：** 5237行/43文件/72测试/5扩展

### Phase 2.5：Agent发现 + 知识体系一键加入 ✅ 已完成（代码已实现，蓝图补录）

**目标：一条链接让任何智能体自动加入知识体系**

> 核心价值：用户只负责发链接，智能体自动发现体系、下载仓库、理解规则、按规范工作。

**已实现功能：**
- [x] `/.well-known/agent.json` — Agent发现协议握手（schema v0.3.0）
  - identity：主人和代理的身份信息
  - capabilities：体系能力声明（搜索知识库/访问保险箱/部署服务/混音/创作/加入知识体系）
  - knowledge_system：知识体系仓库地址+入口+协议+加入端点
  - preferences：交互风格/搜索优先级/格式偏好
  - auth：代理委托模式
- [x] `POST /api/v1/agent/join` — Agent加入知识体系API
  - Agent报上名字和能力 → 返回仓库clone命令 + 入口文档 + 角色清单 + 工作协议
- [x] `POST /api/v1/agent/resolve` — 批量解析短链
- [x] `POST /api/v1/agent/discover` — 发现可用Link

**工作流程：**
```
用户发 https://openlink.xxx 给智能体
  → 智能体访问 GET /.well-known/agent.json
  → 发现 knowledge_system 字段
  → 调 POST /api/v1/agent/join
  → 获取仓库clone命令 + 入口文档 + 角色清单 + 工作协议
  → 自动clone仓库、读RULES、按规则工作
```

**验收标准：** 智能体收到链接后自动完成发现→加入→理解→工作全流程，用户零干预

---

## Phase 3：Agent接入 + 文件中转 — SDK + 跨设备传输 ⏳ 待启动

**目标：Agent能直接用 + 跨设备文件共享（云存储）**

- [ ] Rust Agent SDK
- [ ] Agent身份识别Condition扩展
- [ ] Workflow Action扩展（多步编排）
- [ ] Agent专用API（resolve/batch/discover）
- [ ] FileTransfer Action扩展 — CloudRelay模式
  - 存储后端抽象trait（StorageBackend: upload/download/presigned_url/delete）
  - Cloudflare R2实现（推荐主力）
  - 阿里云OSS实现（备选）
  - 城通网盘实现（归档场景）
  - WebDAV实现（加密中转）
  - SFTP实现（传统服务器）
  - ECS本地实现（测试用）
  - 自定义后端（Extension注册）
- [ ] 存储路由（Storage Router）— 跟Link路由引擎同构
- [ ] 文件上传：Presigned URL直传模式
- [ ] 多Agent并发访问同一文件
- [ ] PostgreSQL存储（可选切换）
- [ ] **KnowledgeSync协议原语**（ADR-009） — Agent间知识同步：discover→auth→read/write→callback
- [ ] **Tool Search三桥模式** — Extension Registry延迟加载，解决"工具税"问题
  - `extension_search(query, limit)` — 搜索Extension目录
  - `extension_describe(name)` — 按需加载Extension完整schema
  - `extension_execute(name, args)` — 执行Extension

**验收标准：** Agent通过SDK创建带路由规则的短链，不同Agent访问得到不同结果；文件Link在不同设备间智能传输

---

## Phase 3.5：Identity Card — 个人名片 📋 规划中

**目标：从短链到个人身份，让每个Link变成一张智能名片**

> 名片是什么？人在互联网上的入口。OpenLink是什么？智能体互联网的入口协议。DNA一致。

### 核心理念

同一个URL，**人类看到精美的HTML名片，AI Agent看到结构化身份（JSON-LD）**。这不是两个页面，是路由引擎根据访问者Context自动选择渲染方式。

```
https://card.openlink.dev/xiaolong
  ├── 浏览器访问 → 渲染HTML名片（头像/简介/社交链接/项目展示）
  ├── curl/AI访问 → 返回JSON-LD结构化身份（Person schema）
  └── Agent协议访问 → 返回Agent发现协议握手数据
```

### 数据模型

一张名片 = 一个**Link** + 富元数据，不需要新的核心原语：

```json
{
  "code": "xiaolong",
  "type": "identity_card",
  "payload": {
    "display_name": "小龙",
    "bio": "AI原生开源DAW开发者",
    "avatar": "https://...",
    "social": {
      "github": "youbanzhishi",
      "掘金": "乱码三千",
      "小红书": "奶香小红薯"
    },
    "projects": ["OpenDAW", "OpenLink", "OpenVault"],
    "tags": ["Rust", "音频", "开源"],
    "theme": "dark"
  },
  "routes": [
    {"condition": {"type": "identity-type", "params": {"type": "agent"}}, "target": {"action": "json-ld"}},
    {"condition": {"type": "identity-type", "params": {"type": "human"}}, "target": {"action": "render-card"}}
  ]
}
```

### 功能清单

- [ ] **Card CRUD API** — `POST /v1/cards` 创建名片，复用Link底层存储
- [ ] **HTML渲染** — `GET /card/:code` 返回响应式名片页面
  - 多主题支持（dark/light/minimal/gradient）
  - 社交平台图标自动匹配（GitHub/掘金/小红书/知乎/Twitter等）
  - 项目展示区（关联GitHub仓库，自动拉取star/description）
  - 自定义域名绑定（复用Phase4的自定义域名）
- [ ] **JSON-LD渲染** — AI Agent访问时返回Schema.org Person结构化数据
  - `Accept: application/ld+json` 或 `User-Agent` 含bot/agent关键词
  - 符合W3C DID规范方向，为Agent发现协议铺路
- [ ] **社交链接路由** — 每个社交平台链接走OpenLink路由，带访问统计
  - `GET /card/xiaolong/github` → 302跳转GitHub（记录统计）
  - 支持条件路由：不同访问者跳不同社交主页
- [ ] **名片模板** — 内置3-5套模板，用户选模板+填内容+选主题
- [ ] **OG Meta** — 社交平台分享时显示精美预览卡（OpenGraph + Twitter Card）
- [ ] **QR Code** — `GET /card/:code/qr` 返回名片二维码
- [ ] **访问统计** — 复用现有stats，名片专属统计面板（PV/UV/点击热力图）
- [ ] **Person Agent Schema知识扩展** — v0.3.0，支持KnowledgeSync知识源声明
- [ ] **KnowledgeSync callback机制** — 知识变更通知+webhook推送
- [ ] **MCP双向能力** — OpenLink既做MCP Client也做MCP Server

### 技术实现

| 层 | 方案 | 说明 |
|---|------|------|
| 存储层 | 复用Link + 扩展payload | 名片只是type=identity_card的Link |
| 渲染层 | 服务端模板（Askama/Tera） | SEO友好，首屏快，不依赖JS |
| 路由层 | 复用Route + Context | 人类→HTML，Agent→JSON-LD |
| 统计层 | 复用现有stats | 名片链接自带访问统计 |
| 静态资源 | 内嵌或CDN | CSS/字体/图标打包进二进制或走CDN |

### 与未来Phase的关系

```
Phase 3.5: Identity Card（名片）
  ↓ 名片中的身份数据
Phase 6: Agent发现协议（Agent通过名片发现你）
  ↓ Agent发现后
Phase 3/4: 文件传输/协作（Agent通过你的名片找到服务）
```

名片是Agent发现的前置——Agent先看到你的名片，才知道你能做什么、怎么跟你协作。

### 验收标准

1. 浏览器访问 `card.openlink.dev/xiaolong` 看到精美HTML名片
2. `curl card.openlink.dev/xiaolong` 返回JSON-LD结构化身份
3. 社交链接点击有统计，分享到微信/推特有OG预览
4. 名片创建API可用，模板可选

---

## Phase 4：局域网直传 + DAW生态 📋 规划中

**目标：同LAN设备Gbps直传 + OpenDAW打通**

- [ ] OpenLink Node — 轻量设备端守护进程
  - mDNS广播
  - 文件服务
  - 心跳上报
- [ ] DirectTransfer Action — 局域网直传
- [ ] 传输路由（Transfer Router）— 根据网络拓扑自动选择最优传输路径
- [ ] 多Agent并发访问：不同Agent根据Context走不同路径
- [ ] OpenDAW扩展分发Action
- [ ] JSFX脚本加载Action
- [ ] 项目分享（深链接拉起）
- [ ] 自定义域名绑定

**验收标准：** 同LAN设备间文件直传Gbps；不同网络位置的Agent访问同一文件自动选最优路径；DAW插件一键安装

---

## Phase 5：内网穿透 + 边缘化 + 规模化 📋 规划中

**目标：异地P2P + 生产级部署**

- [ ] P2PTransfer Action — 内网穿透
  - Tailscale集成（首选，零配置）
  - STUN/TURN降级
- [ ] openlink-edge编译为WASM
- [ ] Cloudflare Workers部署
- [ ] 重定向层与管理层拆分
- [ ] Redis缓存热链
- [ ] 监控告警

**验收标准：** 异地设备通过P2P穿透直传文件，无需公网IP；生产级高可用

---

## Phase 6：协议层 — 智能体互联网 📋 规划中

**目标：超越HTTP**

- [ ] MCP协议适配器
- [ ] Agent-to-Agent协议适配器
- [ ] Agent发现与能力市场
- [ ] 去中心化路由（多节点同步）

**验收标准：** Agent通过MCP/A2A协议自动发现并协作

---

## 设计哲学：去中心化与云端共存

**核心类比：PPS播放器的进化版——人越多越快，但永远不断流。**

| 模式 | 适用场景 | 特点 |
|------|---------|------|
| p2p-first | 大文件分享 | P2P优先，云端兜底 |
| cloud-first | 隐私敏感文件 | 云端优先，P2P加速 |
| adaptive（默认） | 通用 | 路由引擎动态选最优 |
| cloud-only | 关闭P2P | 传统CDN模式 |

**冷启动→热传播飞轮：**
1. 第1个Agent → CloudRelay（云端源）
2. 第2个Agent（同LAN） → DirectTransfer（从第1个直传，Gbps）
3. 第3个Agent（异地） → P2PTransfer（穿透直连，Mbps）
4. 越多节点做种 → 路径选择越多 → 云端源压力下降
5. 最终云端只服务冷启动和极端弱网

**关键原则：保底能力比峰值性能更重要。**
