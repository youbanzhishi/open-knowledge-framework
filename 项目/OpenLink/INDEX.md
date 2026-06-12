# OpenLink 项目知识索引

> 最后更新：2026-05-13 | 更新人：主对话
> 用途：任何智能体接手OpenLink相关任务时，先读本文件了解项目全貌

## 共享规范
→ ./共享知识/项目规范/（宪法层，改一次全局生效）
- 目录结构规范：最后同步 2026-05-09
- 协作规范：最后同步 2026-05-09
- 热规则规范：最后同步 2026-05-09
本项目已对齐：大部分（INDEX.md+justfile+.github/workflows+规划/+assets/+output/+feedback/ 已建，docs/中文目录待迁移）

## 热规则
→ 规划/hot-rules.md（派发任务时必须注入，防重复踩坑）

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|
| 目录结构 | docs/下暂用"开发日志""知识沉淀"中文目录 | 历史原因，后续迭代对齐为docs/dev-log + docs/knowledge |

## 目录自愈

此项目按开发类目录结构规范，执行任何操作前运行：
```bash
mkdir -p ./回收站 && mkdir -p ./项目/OpenLink/{
  规划,src,tests/{integration,fixtures},
  docs/{dev-log,knowledge},
  assets/{images,templates,data},
  output,config,scripts,feedback
}
```

⚠️ 文件安全铁律：删除→mv到./回收站/OpenLink-$(date +%m%d)/，禁止rm

## 项目定位

**OpenLink不是短链服务，是智能体互联网的基础协议层。**

- 当下：短链重定向（入口功能）
- 近未来：Agent间的发现、握手、协作
- 远未来：智能体互联网的DNS + 路由 + 编排

一句话：**URL是人类互联网的入口协议，OpenLink是智能体互联网的入口协议。**

→ 完整规划：[项目规划.md](项目规划.md)

## 核心知识

### 产品特性（开发↔运营 共享）

| 特性 | 说明 | 详见 |
|------|------|------|
| 5大核心原语 | Link/Route/Action/Context/Hook | [项目规划.md#二](项目规划.md) |
| Extension Registry | 四柱模型：Action/Condition/Hook/Protocol | [项目规划.md#四](项目规划.md) |
| 动态路由 | 同一短链根据访问者路由到不同目标 | [docs/knowledge/设计哲学与决策依据.md#一](docs/knowledge/设计哲学与决策依据.md) |
| 公私分治 | 公开内容过审，私密内容端到端加密不过审 | [docs/knowledge/设计哲学与决策依据.md#十一](docs/knowledge/设计哲学与决策依据.md) |
| 人形机器人对接 | 机器人=PhysicalAgent，注册扩展即可 | [docs/knowledge/设计哲学与决策依据.md#十三](docs/knowledge/设计哲学与决策依据.md) |
| PPS模式 | 人越多越快但不断流，云端保底 | [docs/knowledge/设计哲学与决策依据.md#十](docs/knowledge/设计哲学与决策依据.md) |
| 存储路由 | 跟Link路由引擎同构，文件走不同后端 | [项目规划.md#三-Phase3](项目规划.md) |
| 传输路由 | LAN直传/P2P穿透/云中转自动切换 | [项目规划.md#三-Phase4](项目规划.md) |
| Identity Card（名片） | 同一URL，人类看HTML名片，AI看JSON-LD身份 | [规划/roadmap.md#Phase-3.5](规划/roadmap.md) |
| 安全防火墙 | 三道防线（仅公开内容） | [项目规划.md#十三](项目规划.md) |

### 文档体系（2026-05-11 标配）

| 文档 | 路径 | 说明 |
|------|------|------|
| 用户文档 | docs/user-guide.md | 使用指南（短链/条件路由/名片/API认证/curl示例/FAQ） |
| Agent指南 | docs/agent-guide.md | AI智能体内置指南（核心原语/API速查/名片/JSON-LD/接入步骤） |
| Agent发现 | GET /.well-known/agent.json | 智能体自发现端点（capabilities/context_awareness/core_primitives/links） |
| 部署指南 | docs/deployment.md | Docker+二进制+源码+systemd+生产环境 |

### 技术架构（开发关注）

| 维度 | 选择 | 详见 |
|------|------|------|
| 语言 | Rust（与OpenDAW统一技术栈） | [docs/knowledge/设计哲学与决策依据.md#二](docs/knowledge/设计哲学与决策依据.md) |
| 框架 | Axum + SQLite→PG | [项目规划.md#七](项目规划.md) |
| 核心哲学 | 新功能=注册扩展，架构永远不改 | [项目规划.md#十一](项目规划.md) |
| 与OpenDAW同构 | Extension Registry + 共享crate可能 | [项目规划.md#十](项目规划.md) |
| CI | GitHub Actions（check→clippy→test→fmt→docker） | [docs/knowledge/设计哲学与决策依据.md#十四](docs/knowledge/设计哲学与决策依据.md) |
| 编译环境 | 云电脑开发 / Actions编译 / ECS部署 | [docs/knowledge/设计哲学与决策依据.md#十四](docs/knowledge/设计哲学与决策依据.md) |

### 运营卖点（运营关注）

- **核心差异化**：传统短链是静态映射，OpenLink是动态路由引擎
- **目标用户**：AI开发者 / 智能体运营者 / 开源社区 / 独立开发者
- **一句话定位**：URL是人类互联网的入口协议，OpenLink是智能体互联网的入口协议
- **核心类比**：PPS播放器进化版——人越多越快但不断流
- **安全背书**：三道防线 + 公私分治 → 国内合规无忧
- **开放生态**：Extension Registry让任何人都能扩展能力

### 内容素材（内容关注）

- **教程方向**：短链入门 → 动态路由 → Agent协作 → 文件中转 → DAW集成 → 人形机器人
- **核心类比**：PPS播放器进化版 / Extension Registry像App Store / 短链是Agent的URL
- **与OpenDAW的关系**：同架构不同领域，Rust统一技术栈，共享crate
- **与OpenVault的关系**：OpenLink管"到得了"，OpenVault管"丢不了"

## 项目状态

| 阶段 | 状态 | 说明 |
|------|------|------|
| Phase 1：核心原语+基础短链 | ✅ 已完成 | 3270行/36文件/30测试通过 |
| Phase 2：动态路由+Hook | ✅ 已完成 | 5237行/43文件/72测试/5扩展 |
| Phase 3-4：Agent接入+文件中转+局域网直传+DAW | ✅ 已完成 | SDK+FileTransfer+存储路由+DirectTransfer+DAW分发 |
| Phase 5-6：WASM沙箱+DAG+A2A消息 | ✅ 已完成 | 边缘化+DAG执行器+A2A协议基础 |
| Phase 7：监控+限流+认证 | ✅ 已完成 | 健康检查+限流+认证增强 |
| Phase 8：存储后端+SDK增强+DAW生态 | ✅ 已完成 | OSS+WebDAV+SFTP+Batch+熔断+PluginRegistry |
| Phase 9：P2P+边缘+去中心化路由 | ✅ 已完成 | NAT穿透+分块续传+Gossip |
| Phase 10：协议层 | ✅ 已完成 | MCP适配器+A2A市场+信任+协商+DHT+协议桥接 |
| Phase 11：生产部署+SDK+文档+v1.0.0 | ✅ 已完成 | Docker+Nginx+监控+Builder+重试+中间件+5篇文档+CI |

- GitHub仓库：https://github.com/youbanzhishi/OpenLink
- 当前版本：**v1.0.1** | ~37050行Rust | 9 crates + 12 extensions
- CI：已上线 | Docker：生产级配置就绪
- Docker镜像：ghcr.io/youbanzhishi/openlink/openlink:latest
- 部署文档：docs/deployment.md（Docker+二进制+源码编译+systemd+生产环境）

## 关联项目

| 项目 | 关系 | 详见 |
|------|------|------|
| OpenVault | 保险层，调用OpenLink做运输 | [../OpenVault/项目规划.md](../OpenVault/项目规划.md) |
| open-dev-tools | 共享构建工具链 | [../open-dev-tools/README.md](../open-dev-tools/README.md) |
| OpenDAW | 架构同构，共享Extension Registry模式 | [../../共享知识/设计模式/extension-registry.md](../../共享知识/设计模式/extension-registry.md) |

## 职能分工

| 职能 | 负责人 | 关注点 | 产出目录 |
|------|--------|--------|---------|
| 开发 | 主对话+sub-agent | 代码/架构/CI | openlink/ + 知识沉淀/ |
| 运营 | 待定 | 文案/推广/用户 | 运营/ |
| 内容 | 待定 | 教程/FAQ/科普 | 内容/ |

| 2026-05-15 | 内嵌Web管理面板：Dashboard+Links+Routes+Extensions+Agent五页面，HTMX+Alpine.js暗色主题，根路径不再404 |

## 最近变更（2026-05-30）

- **ADR-009** KnowledgeSync协议原语：discover→auth→read/write→callback，对标ima+WorkBuddy知识闭环 → [docs/adr/009-knowledge-sync-protocol.md](docs/adr/009-knowledge-sync-protocol.md)
- **WO-040/WO-041联合结论**：Hermes Agent+ima+WorkBuddy产品+技术双评估完成，KnowledgeSync纳入Phase 3 → [docs/knowledge/WO040-WO041联合结论.md](docs/knowledge/WO040-WO041联合结论.md)
- **Hermes Agent评估报告（产品侧）** v2：新增ima+WorkBuddy竞品分析 → [docs/knowledge/Hermes-Agent评估报告.md](docs/knowledge/Hermes-Agent评估报告.md)
- **Hermes Agent技术评估（技术侧）** v2：基于v0.14.0源码分析，新增MCP Catalog/Tool Search/hermes-mcp深度分析 → [docs/knowledge/Hermes-Agent技术评估.md](docs/knowledge/Hermes-Agent技术评估.md)
- **Tool Search POC**：借鉴Hermes三桥模式的Extension Registry延迟加载方案（设计中）

## 最近变更（2026-05-13）

- **Person Agent Schema v0.2.0** — 人的数字身份协议：`/.well-known/agent.json` + auto-config API → [docs/person-agent-schema.md](docs/person-agent-schema.md)
- **ADR-008** 记录Person Agent Schema决策 → [OpenDAW docs/adr/008](https://github.com/youbanzhishi/OpenDAW/blob/main/docs/adr/008-person-agent-schema.md)
- 自动配置：注册服务触发verify/index/notify工作流，一句话接入新服务
- 三层安全：公开/授权/私密，私密层永远不暴露，通过代理授权

## 最近变更（2026-05-10）

- **v1.0.0发布** Phase5-11全部完成，9 crate+12 ext ~37050行Rust → [docs/dev-log/2026-05-10.md](docs/dev-log/2026-05-10.md)
- **测试修复全绿** 7编译错误+1运行时失败修复，228测试全绿，commit 8a9bfa0
- **第三步门通过** Linux x86_64 release构建+二进制上传Release
- Phase 11: Docker生产部署+SDK增强(Builder+重试+中间件)+5篇文档+CI/CD+v1.0.0, commit 1f47884
- Phase 10: MCP适配器+A2A市场+信任+协商+DHT+协议桥接, 3582行, 85测试, commit 47ca83e
- Phase 9: P2P传输(NAT穿透+分块续传)+边缘运行时+Gossip, commit ba897df
- Phase 8: 存储后端(OSS+WebDAV+SFTP)+SDK增强+DAW生态, commit 9583161
- Phase 7: 监控+限流+认证增强, commit d700b90
- Phase 5-6: WASM沙箱+DAG+A2A消息总线, commit ef950df
- GitHub Actions CI上线（ci.yml + release.yml）
- 新增人形机器人对接设计 → [docs/knowledge/设计哲学与决策依据.md#十三](docs/knowledge/设计哲学与决策依据.md)
- 新增公私分治：公开内容过审，私密内容端到端加密 → [docs/knowledge/设计哲学与决策依据.md#十一](docs/knowledge/设计哲学与决策依据.md)
- open-dev-tools升级为跨语言工具链
- 共享知识库建立 `./共享知识/` → [../../共享知识/README.md](../../共享知识/README.md)

## 开发技能拆解补充（2026-05-10）

> 以下内容原属 `技能/openlink-dev/`，现已拆解回项目INDEX。

### 部署规范

**云电脑二进制直跑（当前方案）**：
- 二进制：`/opt/openlink/openlink`（从GitHub Release下载）
- systemd服务：`openlink.service`（开机自启，断线10秒重连）
- 端口：3001（避免与OpenDAW的3000冲突）
- Nginx反代：`/link/` → localhost:3001
- 配置文件：`/opt/openlink/config/default.toml`
- 外部访问：cpolar隧道 → Nginx:8888 → /link/

**GitHub**：
- 仓库：`youbanzhishi/OpenLink`
- 分支策略：main(稳定) + feature/*(开发)
- CI：GitHub Actions（后期加）

**配置文件 (config/default.toml)**：
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

### 文件上传设计（Presigned URL 直传 + 存储路由）

**核心原则**：ECS不碰文件本身，只处理元数据，文件直传存储后端。

**存储路由（Storage Router）**：跟Link路由引擎同构，根据文件特征匹配存储后端
- 大文件→R2 / 归档文件→网盘 / 临时文件→本地 / 敏感文件→加密WebDAV
- 支持分流：同一文件类型按权重分配到不同后端（负载均衡/容灾）
- 路由条件：文件大小/类型/用途标签/来源设备/自定义条件（Extension扩展）

**存储后端（StorageBackend trait，注册即用）**：
- Cloudflare R2（推荐主力，下行免费，S3兼容）
- 阿里云OSS / 城通网盘（归档）/ WebDAV（加密中转）/ SFTP / 本地（测试）
- 自定义后端通过Extension注册

**架构**：
```
上传：客户端 → API(存储路由匹配后端) → 客户端直传存储后端 → 确认创建Link
下载：客户端 → API(存储路由匹配后端) → 客户端直连存储后端下载
```

**API**：
- `POST /v1/files/upload-request` → 存储路由匹配后端，返回presigned URL + file_id
- `POST /v1/files/confirm` → 上传完成确认，创建Link
- `GET /:code` → 普通访问302到presigned download URL
- `POST /v1/agent/resolve` → Agent访问返回元数据+presigned URL
- `GET/DELETE /v1/files/:id` → 文件元数据查询/删除
- `GET/POST/DELETE /v1/storage/backends` → 存储后端管理
- `GET/POST/PUT/DELETE /v1/storage/routes` → 存储路由规则管理

**配置示例**：
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

**设备策略**：云电脑：原文件直传 | 手机：可选压缩 | Agent：程序化上传 | SDK：一键上传

**安全**：Presigned URL TTL 15分钟 | 上传需API Token | 文件大小可配置(默认100MB) | 类型白名单

### 传输路由（Transfer Router）

**设计理念**：文件传输路径本身也是路由决策，跟Link路由引擎同构。同一个文件，不同Agent根据自身Context自动选择最优传输方式，用户无感。

**设计哲学：去中心化与云端共存**：核心类比：PPS播放器的进化版——人越多越快，但永远不断流。

不是纯去中心化，也不是纯云端，而是路由引擎动态决策的最优路径选择：
- p2p-first：P2P优先，云端兜底（大文件分享）
- cloud-first：云端优先，P2P加速（隐私敏感）
- adaptive（默认）：路由引擎动态选最优
- cloud-only：纯云端，关闭P2P

**冷启动→热传播飞轮**：第1个Agent走云端 → 第2个同LAN从第1个直传Gbps → 第3个异地P2P → 越多人越快 → 云端压力逐渐下降

**关键原则：保底能力比峰值性能更重要。** P2P没人做种就废了，OpenLink最差走CloudRelay，速度有下限。

**三种传输路径**：
```
同LAN？      → DirectTransfer（直传，Gbps，零延迟）
跨NAT可打洞？ → P2PTransfer（Tailscale/STUN穿透，Mbps）
跨NAT不可打洞？ → CloudRelay（R2/OSS/网盘中转）
自定义？     → Extension注册
```

**多Agent并发访问同一文件**：
```
d.aw/project-audio → 同一份文件

Agent A（同LAN）  → DirectTransfer，从NAS直传，Gbps
Agent B（同LAN）  → DirectTransfer，从已下载的A直传（LAN分发），Gbps
Agent C（异地）   → P2PTransfer，Tailscale穿透，Mbps
Agent D（远程）   → CloudRelay，R2中转，按带宽走
```

**OpenLink Node（设备端守护进程）**：每个设备运行一个轻量Node：
- mDNS广播：告诉局域网"我是OpenLink节点"
- 文件服务：接收局域网内其他节点的直传请求
- 心跳上报：告诉Server网络状态（公网IP/LAN IP/在线状态/已有文件缓存）

**LAN文件分发**：同LAN设备已下载文件后，其他同LAN设备可从该节点直传，类似BT的局域网分片，比每个人都去源站取更高效。

**内网穿透方案**：
- 首选：Tailscale（零配置，基于WireGuard）
- 降级：STUN打洞 → TURN中继
- 自动选择：Tailscale可用→走Tailscale / 不可用→STUN/TURN

**Action扩展**：
```rust
Action::DirectTransfer { target_node, local_addr }   // 局域网直传
Action::P2PTransfer { target_node, method }           // NAT穿透
Action::CloudRelay { storage_backend, presigned_url } // 云中转
```

### 链接与文件生命周期

**链接过期**：
- expires_at：到期自动失效
- max_clicks：达到点击上限自动失效
- expired_action：Gone(410) / Redirect(提示页) / Custom(Extension)

**文件过期**：
- 默认7天，按标签可覆盖（temp→1天 / archive→365天）
- 文件过期 → 所有关联Link自动失效
- 引用计数：文件只在无Link指向且自身过期时删除
- 定时清理任务扫描过期资源

**Link与文件联动**：
- Link过期 ≠ 文件删除（可能有其他Link指向）
- 文件过期 = 所有关联Link失效
- 删除条件：引用计数=0 且 文件已过期

### 安全防火墙（国内合规红线）

**三道防线，全部做成Hook扩展，不改核心代码。**

**第一道：URL过滤（链接创建时）**
- 域名黑名单 + 关键词过滤
- 第三方URL安全API（阿里云/腾讯云）
- 可疑URL进入人工审核队列

**第二道：文件内容扫描（文件上传时）**
- 图片：色情/暴恐识别（阿里云内容安全/腾讯云天御）
- 文本：敏感词 + 语意分析
- 文件哈希：MD5/SHA256违规黑名单
- 待审文件暂存，审核通过才可访问

**第三道：访问行为监控（运行时）**
- 异常访问模式检测
- 举报机制 + 自动降级
- 被举报达阈值自动暂停 + 进入审核

**配置**：
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
## ⛔ 禁止项

- **禁止直接操作ECS服务器**：所有服务器操作（SSH/Remote Gateway/Docker管理）只能由ECS运维角色执行
- 需要部署/运维时：通过主对话转派给ECS运维角色，不要自己动手

## 部署信息
| 项目 | 部署文档 | 部署脚本 | 部署方式 | 服务器 |
|------|----------|----------|----------|--------|
| OpenLink | docs/deployment.md | 待补充 | Docker(ECS)/二进制(云电脑) | ECS+云电脑 |
| openlink-admin | 静态托管 | - | 静态HTML(Cloudflare Pages/Vercel) | 任意静态托管 |

**openlink-admin（管理后台）**：
- 仓库：https://github.com/youbanzhishi/openlink-admin
- 技术栈：HTMX + Alpine.js（轻量方案）
- 部署：静态HTML，可托管到任意静态服务
- API配置：在管理界面设置中配置后端地址

**部署文档**：`角色/ECS运维/knowledge/快速部署指南.md`（Docker/二进制/源码编译三种方式）

**实际部署状态（2026-05-11）**：
- **ECS（Docker）**：未部署（端口3000）
- **云电脑（二进制直跑）**：✅ 已运行
  - 二进制：`/opt/openlink/openlink`，端口3001
  - systemd服务：`openlink.service`（已启用开机自启）
  - Nginx反代：`/link/` → localhost:3001
  - 配置文件：`/opt/openlink/config/default.toml`
  - 外部访问：cpolar隧道 → Nginx:8888 → `/link/`


## 凭据

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | `github.pat` | 仓库 push/pull/CI |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。

## 关联角色

- 系统开发者（主）：Rust开发、Extension Registry架构设计

## 可用工具

暂无，通过关联角色获得跨项目通用工具
## 反哺检查门（不过不算任务完成）

> 铁律4：产出结果≠任务完成。以下每项必须过，sub-agent返回时必须汇报反哺情况。
1. 更新本INDEX.md的"最近变更"
2. 项目特有事实 → 本项目 docs/knowledge/
3. 通用经验 → ./角色/系统开发者/knowledge/
4. 踩坑2次 → 本项目 规划/hot-rules.md
5. 发现跨角色通用模式 → ./共享知识/

## 已同步版本: 2026-05-30-v11

## CI/CD

| 项目 | 地址 |
|------|------|
| 仓库 | https://github.com/youbanzhishi/OpenLink |
| Actions | https://github.com/youbanzhishi/OpenLink/actions |
| CI | https://github.com/youbanzhishi/OpenLink/actions/workflows/CI/ |
| Auto Format Fix | https://github.com/youbanzhishi/OpenLink/actions/workflows/Auto%20Format%20Fix/ |
