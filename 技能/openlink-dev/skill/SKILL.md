# OpenLink 开发技能

> 项目代号：OpenLink
> 技能类型：项目级开发技能（项目上下文 + 开发规范 + 迭代指引）
> 目标：任何智能体加载此技能后，能0成本接手OpenLink项目的开发和迭代

---

## 一、项目定位

**OpenLink 不是短链服务，是智能体时代的通用路由与编排协议。**

- 当下：短链重定向（入口场景，必须保留）
- 近未来：Agent间的发现、握手、协作
- 远未来：智能体互联网的 DNS + 路由 + 编排

一句话：URL是人类互联网的入口协议，OpenLink是智能体互联网的入口协议。

---

## 二、核心哲学

**新功能 = 注册扩展，架构本身永远不需要改。**

这条原则跟OpenDAW完全同构。任何时候你想加新能力，都不应该改核心代码，而是通过Extension Registry注册新的扩展。

---

## 三、5大核心原语

这是架构的基石，永不需要新增原语：

### 3.1 Link（链接实体）
可寻址、可识别的实体。短链是Link的最简形态。
- id: 全局唯一标识
- code: 人类可读短码 (d.aw/abc)
- payload: 结构化元数据（链接即数据包）
- owner: 创建者
- metadata: 扩展元数据（不影响路由）

### 3.2 Route（路由规则）
从Link到Action的映射，支持条件分支。
- rules: 有序规则列表，命中即停
- default: 兜底目标（传统短链重定向 = 只有default的Route）

### 3.3 Action（执行动作）
Link被解析后"做什么"。不只是重定向，一切皆Action。
| 内置: Redirect | FileTransfer | Webhook | Workflow | Transform | Delegate
| 扩展: Custom（通过Extension注册，核心永远不改）

### 3.4 Context（请求上下文）
路由决策的输入，决定走哪条路。
- identity: 谁在访问（人类/Agent/服务）
- device / location / time / intent / session
- custom: 扩展上下文（Extension填充）

### 3.5 Hook（钩子）
路由前后的拦截器。
- BeforeRoute: 改写Context
- AfterRoute: 记录日志、触发通知
- OnError: 降级处理、告警

---

## 四、分层架构

```
Protocol Layer（协议层）     ← HTTP/WebSocket/MCP/A2A/自定义协议适配
Routing Engine（路由引擎）   ← Context解析 → Rule匹配 → Action调度
Action Layer（动作层）       ← Redirect | Webhook | Workflow | Extension...
Core Store（核心存储）       ← Link | Route | Context | Hook | Stats
Extension Registry（扩展注册表）← 自定义Action | Condition | Hook | Protocol
```

### Extension Registry 四柱

| 柱 | 功能 | 注册什么 |
|----|------|---------|
| Action API | 注册新动作 | 新的执行行为 |
| Condition API | 注册新条件 | 新的路由判断逻辑 |
| Hook API | 注册新拦截器 | BeforeRoute/AfterRoute/OnError |
| Protocol API | 注册新协议适配器 | MCP/A2A/自定义 |

---

## 五、项目结构

```
openlink/
├── Cargo.toml                    # workspace
├── crates/
│   ├── openlink-core/            # 核心原语 + 路由引擎 + Extension Registry
│   ├── openlink-store/           # 存储抽象层（trait + SQLite/PG实现）
│   ├── openlink-api/             # HTTP API（Axum）
│   ├── openlink-edge/            # 边缘重定向（WASM，远期）
│   └── openlink-sdk/             # Agent SDK（远期）
├── extensions/                   # 官方扩展
│   ├── ext-redirect/             # 重定向Action
│   ├── ext-webhook/              # Webhook Action
│   ├── ext-workflow/             # Workflow Action
│   ├── ext-daw/                  # OpenDAW集成
│   ├── ext-agent-identity/       # Agent身份识别
│   └── ext-mcp/                  # MCP协议适配
├── config/
│   └── default.toml              # 默认配置
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
└── deploy/
    └── deploy-openlink.sh
```

### Crate 职责边界

| Crate | 职责 | 不做什么 |
|-------|------|---------|
| openlink-core | 原语定义 + 路由引擎 + Registry | 不知道HTTP/数据库的存在 |
| openlink-store | 数据持久化（trait抽象） | 不知道路由逻辑 |
| openlink-api | HTTP接口 + 请求处理 | 不知道存储细节，通过core的trait调用 |
| openlink-edge | 极简重定向（WASM） | 只有Redirect，不依赖core |
| openlink-sdk | Agent客户端 | 调API，不直接操作存储 |

---

## 六、API 设计

### 短链管理
```
POST   /v1/links              # 创建短链
GET    /v1/links/:code        # 查询短链信息
PUT    /v1/links/:code        # 更新短链
DELETE /v1/links/:code        # 删除短链
GET    /v1/links/:code/stats  # 访问统计
```

### 路由规则
```
POST   /v1/links/:code/routes        # 创建路由规则
PUT    /v1/links/:code/routes/:id    # 更新路由规则
DELETE /v1/links/:code/routes/:id    # 删除路由规则
```

### 扩展管理
```
POST   /v1/extensions          # 注册扩展
GET    /v1/extensions          # 列出扩展
PUT    /v1/extensions/:name    # 更新扩展
DELETE /v1/extensions/:name    # 卸载扩展
```

### 重定向（无需认证）
```
GET    /:code                   # 短链重定向（核心路径，必须最快）
```

### Agent专用
```
POST   /v1/agent/resolve        # Agent解析短链（返回JSON而非重定向）
POST   /v1/agent/batch          # 批量创建短链
GET    /v1/agent/discover       # 发现可用的Action/Extension
```

---

## 七、技术栈

| 组件 | 选择 | 备注 |
|------|------|------|
| 语言 | Rust (edition 2021+) | 与OpenDAW统一 |
| 异步运行时 | Tokio | 成熟稳定 |
| Web框架 | Axum | Tokio生态，中间件灵活 |
| 数据库 | SQLx (SQLite → PG) | 初期SQLite，后期可切 |
| 序列化 | serde + serde_json | 标配 |
| 错误处理 | thiserror | 惯例 |
| 日志 | tracing + tracing-subscriber | 异步友好 |
| 配置 | toml | 简单 |
| 短码生成 | base62, 6位 | 568亿组合 |

---

## 八、开发铁律

1. **核心层零业务逻辑** — 路由引擎不知道"短链"是什么，只知道Context→Action
2. **新功能=注册扩展** — 任何新场景都不改核心代码
3. **存储层可替换** — 核心逻辑通过trait抽象，不绑定具体数据库
4. **协议层可插拔** — HTTP只是第一个协议，不是唯一协议
5. **配置优于代码** — 路由规则、Hook顺序、扩展启停，全部可配置
6. **兼容性第一** — 传统短链(`GET /:code → 302`)永远零配置开箱即用
7. **可观测内置** — 每次路由决策都有完整上下文记录，不可关闭
8. **代码注释** — 每个模块必须有用途注释，关键设计决策必须注释说明
9. **测试覆盖** — 核心路由引擎和Extension Registry必须有单元测试

---

## 九、部署规范

### Docker
- 遵循主人现有部署工作流
- 目录：`/root/songjian/docker-compose/openlink/`
- 使用deploy脚本部署，禁止手动docker compose
- 单容器起步，后期按需拆分

### GitHub
- 仓库：`youbanzhishi/OpenLink`
- 分支策略：main(稳定) + feature/*(开发)
- CI：GitHub Actions（后期加）

### 配置文件 (config/default.toml)
```toml
[server]
host = "0.0.0.0"
port = 3000

[store]
type = "sqlite"        # sqlite | postgres
path = "data/openlink.db"

[shortener]
length = 6             # 短码长度
alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

[log]
level = "info"
```

---

## 十、当前进度与路线图

### Phase 1：地基 — 核心原语 + 基础短链 【进行中】
- [ ] 5个核心原语数据结构
- [ ] 路由引擎核心
- [ ] Extension Registry框架
- [ ] Redirect Action扩展
- [ ] HTTP API
- [ ] SQLite存储
- [ ] Docker单容器部署
- **验收：** `curl d.aw/abc` 返回302

### Phase 2：扩展骨架 — 动态路由 + Hook
- 条件路由 / Webhook Action / Hook机制 / 访问日志 / API认证

### Phase 3：Agent接入 + 文件中转 — SDK + 跨设备传输（云存储）
- Rust Agent SDK / Agent身份识别 / Workflow / Agent专用API
- FileTransfer CloudRelay模式 + StorageBackend trait（R2/OSS/城通网盘/WebDAV/SFTP/本地/自定义）
- 存储路由（Storage Router）+ Presigned URL直传
- 多Agent并发访问同一文件，各自走最优路径

### Phase 4：局域网直传 + DAW生态
- OpenLink Node（mDNS + 文件服务 + 心跳上报）
- DirectTransfer Action（LAN直传Gbps + LAN文件分发）
- 传输路由（Transfer Router）：同LAN→直传 / 跨NAT可打洞→P2P / 不可打洞→云中转
- 多Agent并发：同LAN从已下载节点直传，异地走P2P/云中转
- OpenDAW扩展分发 / JSFX脚本 / 项目分享 / 自定义域名

### Phase 5：内网穿透 + 边缘化 + 规模化
- P2PTransfer Action（Tailscale首选 / STUN/TURN降级）
- WASM边缘部署 / Cloudflare Workers / Redis缓存 / 监控

### Phase 6：协议层 — 智能体互联网
- MCP适配 / A2A适配 / Agent发现与能力市场 / 去中心化路由

---

## 十一、与OpenDAW的架构映射

两个项目共享同一套设计哲学，架构同构：

| OpenDAW | OpenLink | 共同模式 |
|---------|----------|---------|
| Extension Registry | Extension Registry | 注册即扩展 |
| Plugin API | Action API | 行为可插拔 |
| Script Runtime | Condition API | 逻辑可编程 |
| Model Bus | Context Bus | 数据可流转 |
| Hook System | Hook System | 流程可拦截 |

**未来可能共享的crate：**
- `open-registry`：通用扩展注册表实现
- `open-hooks`：通用Hook调度器
- `open-bus`：通用消息总线

---

## 十二、关键决策记录

| 决策 | 选择 | 理由 | 日期 |
|------|------|------|------|
| 语言 | Rust | 与DAW统一技术栈，AI基建生态位 | 2026-05-09 |
| 数据库 | SQLite→PG | 初期零依赖，后期按需升级 | 2026-05-09 |
| Web框架 | Axum | Tokio生态，中间件灵活 | 2026-05-09 |
| 部署 | 先单容器后混合 | 快速启动，量级上来再拆 | 2026-05-09 |
| 域名 | d.aw（理想） | 短+DAW关联 | 2026-05-09 |
| Extension四柱 | Action/Condition/Hook/Protocol | 覆盖所有扩展场景 | 2026-05-09 |

---

*此技能文档随项目进展持续更新，保持与代码同步*
*最后更新：2026-05-09*

---

## 十三、项目资料目录

所有项目相关资料集中存放，方便迁移和打包：

```
./项目文档/OpenLink/
├── README.md              # 项目总览 + 目录导航
├── 项目规划.md            # 架构设计、技术选型、路线图
├── 开发日志/              # 按日期的开发记录（进展、决策、踩坑）
├── 知识沉淀/              # 项目相关的技术知识
├── docs/                  # API设计、数据模型等详细文档
└── openlink/              # 代码（Rust workspace）
```

**铁律：所有项目产出物必须放到上述目录下，不要散落在其他位置。**

---

## 十四、文件上传设计（Presigned URL 直传 + 存储路由）

### 核心原则
**ECS不碰文件本身，只处理元数据，文件直传存储后端。**

### 存储路由（Storage Router）
跟Link路由引擎同构，根据文件特征匹配存储后端：
- 大文件→R2 / 归档文件→网盘 / 临时文件→本地 / 敏感文件→加密WebDAV
- 支持分流：同一文件类型按权重分配到不同后端（负载均衡/容灾）
- 路由条件：文件大小/类型/用途标签/来源设备/自定义条件（Extension扩展）

### 存储后端（StorageBackend trait，注册即用）
- Cloudflare R2（推荐主力，下行免费，S3兼容）
- 阿里云OSS / 城通网盘（归档）/ WebDAV（加密中转）/ SFTP / 本地（测试）
- 自定义后端通过Extension注册

### 架构
```
上传：客户端 → API(存储路由匹配后端) → 客户端直传存储后端 → 确认创建Link
下载：客户端 → API(存储路由匹配后端) → 客户端直连存储后端下载
```

### API
- `POST /v1/files/upload-request` → 存储路由匹配后端，返回presigned URL + file_id
- `POST /v1/files/confirm` → 上传完成确认，创建Link
- `GET /:code` → 普通访问302到presigned download URL
- `POST /v1/agent/resolve` → Agent访问返回元数据+presigned URL
- `GET/DELETE /v1/files/:id` → 文件元数据查询/删除
- `GET/POST/DELETE /v1/storage/backends` → 存储后端管理
- `GET/POST/PUT/DELETE /v1/storage/routes` → 存储路由规则管理

### 配置示例
```toml
[storage]
default_backend = "r2"

[storage.backends.r2]
type = "r2"
bucket = "openlink-files"

[storage.backends.ctdisk]
type = "ctdisk"

[storage.backends.webdav]
type = "webdav"
url = "https://dav.example.com"

[[storage.routes]]
condition = { file_size_gt = "100MB" }
backend = "r2"

[[storage.routes]]
condition = { tag = "archive" }
backend = "ctdisk"

[[storage.routes]]
condition = { tag = "encrypted" }
backend = "webdav"
```

### 设备策略
- 云电脑：原文件直传 | 手机：可选压缩 | Agent：程序化上传 | SDK：一键上传

### 安全
- Presigned URL TTL 15分钟 | 上传需API Token | 文件大小可配置(默认100MB) | 类型白名单

---

## 十五、传输路由（Transfer Router）

### 设计理念
文件传输路径本身也是路由决策，跟Link路由引擎同构。同一个文件，不同Agent根据自身Context自动选择最优传输方式，用户无感。

### 设计哲学：去中心化与云端共存
**核心类比：PPS播放器的进化版——人越多越快，但永远不断流。**

不是纯去中心化，也不是纯云端，而是路由引擎动态决策的最优路径选择：
- p2p-first：P2P优先，云端兜底（大文件分享）
- cloud-first：云端优先，P2P加速（隐私敏感）
- adaptive（默认）：路由引擎动态选最优
- cloud-only：纯云端，关闭P2P

**冷启动→热传播飞轮：** 第1个Agent走云端 → 第2个同LAN从第1个直传Gbps → 第3个异地P2P → 越多人越快 → 云端压力逐渐下降

**关键原则：保底能力比峰值性能更重要。** P2P没人做种就废了，OpenLink最差走CloudRelay，速度有下限。

### 三种传输路径

```
同LAN？      → DirectTransfer（直传，Gbps，零延迟）
跨NAT可打洞？ → P2PTransfer（Tailscale/STUN穿透，Mbps）
跨NAT不可打洞？ → CloudRelay（R2/OSS/网盘中转）
自定义？     → Extension注册
```

### 多Agent并发访问同一文件
```
d.aw/project-audio → 同一份文件

Agent A（同LAN）  → DirectTransfer，从NAS直传，Gbps
Agent B（同LAN）  → DirectTransfer，从已下载的A直传（LAN分发），Gbps
Agent C（异地）   → P2PTransfer，Tailscale穿透，Mbps
Agent D（远程）   → CloudRelay，R2中转，按带宽走
```

### OpenLink Node（设备端守护进程）
每个设备运行一个轻量Node：
- mDNS广播：告诉局域网"我是OpenLink节点"
- 文件服务：接收局域网内其他节点的直传请求
- 心跳上报：告诉Server网络状态（公网IP/LAN IP/在线状态/已有文件缓存）

### LAN文件分发
同LAN设备已下载文件后，其他同LAN设备可从该节点直传，类似BT的局域网分片，比每个人都去源站取更高效。

### 内网穿透方案
- 首选：Tailscale（零配置，基于WireGuard）
- 降级：STUN打洞 → TURN中继
- 自动选择：Tailscale可用→走Tailscale / 不可用→STUN/TURN

### Action扩展
```rust
Action::DirectTransfer { target_node, local_addr }   // 局域网直传
Action::P2PTransfer { target_node, method }           // NAT穿透
Action::CloudRelay { storage_backend, presigned_url } // 云中转
```

---

## 十六、链接与文件生命周期

### 链接过期
- expires_at：到期自动失效
- max_clicks：达到点击上限自动失效
- expired_action：Gone(410) / Redirect(提示页) / Custom(Extension)

### 文件过期
- 默认7天，按标签可覆盖（temp→1天 / archive→365天）
- 文件过期 → 所有关联Link自动失效
- 引用计数：文件只在无Link指向且自身过期时删除
- 定时清理任务扫描过期资源

### Link与文件联动
- Link过期 ≠ 文件删除（可能有其他Link指向）
- 文件过期 = 所有关联Link失效
- 删除条件：引用计数=0 且 文件已过期

---

## 十七、安全防火墙（国内合规红线）

**三道防线，全部做成Hook扩展，不改核心代码。**

### 第一道：URL过滤（链接创建时）
- 域名黑名单 + 关键词过滤
- 第三方URL安全API（阿里云/腾讯云）
- 可疑URL进入人工审核队列

### 第二道：文件内容扫描（文件上传时）
- 图片：色情/暴恐识别（阿里云内容安全/腾讯云天御）
- 文本：敏感词 + 语意分析
- 文件哈希：MD5/SHA256违规黑名单
- 待审文件暂存，审核通过才可访问

### 第三道：访问行为监控（运行时）
- 异常访问模式检测
- 举报机制 + 自动降级
- 被举报达阈值自动暂停 + 进入审核

### 配置
```toml
[safety]
enabled = true
[safety.url_filter]
third_party_api = "aliyun"
[safety.content_scan]
scan_images = true
scan_text = true
auto_block = true
[safety.monitor]
abuse_detection = true
report_button = true
auto_suspend_threshold = 100
```
