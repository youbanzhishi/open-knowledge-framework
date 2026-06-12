# OpenVault 项目知识索引

> 最后更新：2026-05-09 | 更新人：子任务(Phase 2)
> 用途：任何智能体接手OpenVault相关任务时，先读本文件了解项目全貌

## 共享规范
→ ./共享知识/项目规范/（宪法层，改一次全局生效）
- 目录结构规范：最后同步 2026-05-09
- 协作规范：最后同步 2026-05-09
- 热规则规范：最后同步 2026-05-09
本项目已对齐：Phase 1 代码已落地，Phase 2 代码已提交

## 热规则
→ 规划/hot-rules.md（派发任务时必须注入，防重复踩坑）

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|
| （暂无偏差，项目启动时按规范建） | | |

## 目录自愈

此项目按开发类目录结构规范，执行任何操作前运行：
```bash
mkdir -p ./回收站 && mkdir -p ./项目/OpenVault/{
  规划,src,tests/{integration,fixtures},
  docs/{dev-log,knowledge},
  assets/{images,templates,data},
  output,config,scripts,feedback
}
```

⚠️ 文件安全铁律：删除→mv到./回收站/OpenVault-$(date +%m%d)/，禁止rm

## 项目定位

**OpenVault不是网盘，不是同步工具，是智能时代的文件保险系统。**

- 网盘 = 存一份，靠服务商不倒
- 同步工具 = 多端一致，但不保证容灾
- OpenVault = 多地多副本 + 完整性校验 + 自愈 + AI智能管理

一句话：**狡兔三窟，AI守护，永不丢失。**

→ 完整规划：[项目规划.md](项目规划.md)

## 核心知识

### 产品特性（开发↔运营 共享）

| 特性 | 说明 | 详见 |
|------|------|------|
| 3-2-1规则 | 3副本+2介质+1异地，默认策略 | [项目规划.md#三](项目规划.md) |
| 自愈 | 检测到损坏自动从健康副本修复 | [项目规划.md#三-3.4](项目规划.md) |
| AI智能备份 | 自动识别文件重要度，推荐策略 | [项目规划.md#四](项目规划.md) |
| 语义搜索 | 自然语言搜文件秒出结果 | [项目规划.md#四-Phase4](项目规划.md) |
| 知识整理智能体 | 自动提取归类，生成知识卡片 | [项目规划.md#四-Phase4](项目规划.md) |
| 个性化 | 学习用户习惯，自动标注优先级 | [项目规划.md#四-Phase4](项目规划.md) |
| 公私分治 | 公开文件正常备份可扫描，私密文件端到端加密零知识 | [项目规划.md#五](项目规划.md) |
| 人形机器人 | 机器人作为客户端查备份/触发恢复 | [项目规划.md#五](项目规划.md) |

### 文档体系（2026-05-11 标配）

| 文档 | 路径 | 说明 |
|------|------|------|
| 用户文档 | docs/user-guide.md | 使用指南（安装/备份策略/3-2-1合规/存储后端/自愈/AI恢复/FAQ） |
| Agent指南 | docs/agent-guide.md | AI智能体内置指南（核心概念/API速查/AI能力/接入步骤） |
| Agent发现 | GET /.well-known/agent.json | 智能体自发现端点（capabilities/storage_backends/core_concepts/links） |
| API参考 | docs/api-reference.md | HTTP API完整参考 |
| 备份策略 | docs/backup-strategies.md | 策略详解 |
| 部署指南 | docs/deployment.md | Docker+二进制+源码+systemd+生产环境 |

### 技术架构（开发关注）

| 维度 | 选择 | 说明 |
|------|------|------|
| 语言 | Rust | 与OpenLink/DAW统一 |
| Workspace | 3 crates: openvault-core / openvault-storage / openvault-cli | |
| 核心抽象 | `BackupEngine` trait (策略模式) + `VaultStorage` trait (存储抽象) | |
| 快照模型 | `Snapshot` (链式: parent_id → 完整视图) + base_snapshot_id (差异基准) | |
| 配置驱动 | YAML → `BackupConfig` (serde_yaml) | |
| 依赖 | open-storage共享crate + OpenLink运输 | [项目规划.md#七](项目规划.md) |
| 与OpenLink关系 | 保险层→运输层 | OpenVault调用OpenLink做运输 |

### Phase 2 代码架构（当前）

```
openvault/
├── crates/
│   ├── openvault-core/      # 核心抽象: BackupEngine + VaultStorage traits, Snapshot, Config
│   │   ├── strategy.rs      # FullBackup, IncrementalBackup (hash-based), DifferentialBackup
│   │   ├── storage.rs       # VaultStorage trait + build_complete_file_map default impl
│   │   ├── snapshot.rs      # Snapshot (含 base_snapshot_id), BackupStrategy (含 Differential)
│   │   ├── config.rs        # BackupConfig (含 S3 config), StorageConfig
│   │   └── error.rs         # VaultError (含 UnsupportedBackend, NoFullBackupFound)
│   ├── openvault-storage/   # 存储实现
│   │   ├── local.rs         # LocalVaultStorage (含链式恢复)
│   │   └── s3.rs            # S3VaultStorage (stub, 接口就绪)
│   └── openvault-cli/       # CLI入口: vault backup/restore/snapshots
├── config/example.yaml      # 示例配置 (含 incremental/differential/S3)
└── justfile                 # 构建任务
```

**关键设计决策**:
1. **链式增量**: 增量备份沿 parent_id 链构建完整文件视图，避免增量→增量时的误判
2. **核心零业务**: BackupEngine 不知道"本地备份"是什么，新策略=注册 trait 实现
3. **VaultStorage 对齐 open-storage**: 预留接口兼容性，未来可直接对接
4. **哈希优先于时间**: Phase 2 改进 — mtime+size 快速跳过，SHA-256 精确判定
5. **差异 vs 增量**: 差异备份以完整快照为基准，恢复更简单；增量以最近快照为基准，体积更小

### 运营卖点（运营关注）

- **核心痛点**：重要文件害怕丢失，多地备份靠人记不住也管不过来
- **目标用户**：独立开发者 / 知识工作者 / 创作者 / 小团队
- **一句话定位**：你的文件保险箱——狡兔三窟，AI守护，永不丢失
- **核心类比**：不是网盘，是保险箱。网盘存一份，保险箱存三份还能自愈
- **与OpenLink配合**：OpenLink管"到得了"，OpenVault管"丢不了"

### 内容素材（内容关注）

- **教程方向**：备份入门 → 3-2-1规则 → 自愈原理 → AI智能管理 → 跨设备协作
- **核心场景**：手机照片自动备份 / DAW工程容灾 / 代码仓库异地备份
- **与OpenLink的组合故事**：随时随地、任何设备、任何网络环境，都能拿到最新版本，而且永远丢不了

## 项目状态

| 阶段 | 状态 | 说明 |
|------|------|------|
| Phase 1：核心备份 | ✅ 已完成 | BackupPolicy/FileInventory/CLI |
| Phase 2：增量+差异+多后端 | ✅ 已完成 | 哈希增量+差异备份+多后端 |
| Phase 3-4：校验自愈+版本管理 | ✅ 已完成 | SHA256校验+自愈+多版本+快照 |
| Phase 5：S3/R2+3-2-1+CLI | ✅ 已完成 | 云存储后端+3-2-1策略+自愈+CLI |
| Phase 6：加密+压缩+增量+管道 | ✅ 已完成 | AES-GCM+zstd+块级增量+管道 |
| Phase 7：AI智能层+语义搜索 | ✅ 已完成 | FileClassifier+AnomalyPredictor+NL查询 |
| Phase 8：企业级+合规+多租户 | ✅ 已完成 | audit+compliance+RBAC+通知 |
| Phase 9：物理智能体+Web面板+多设备 | ✅ 已完成 | 机器人API+Dashboard+DeviceManager |
| Phase 10：Docker+CI/CD+基准+文档+v1.0.0 | ✅ 已完成 | 生产部署+14基准+4篇文档+CI |

- GitHub仓库：https://github.com/youbanzhishi/OpenVault
- 当前版本：**v1.0.0** | ~20552行Rust | 6 crates
- CI：已上线 | Docker：生产级配置就绪

| 项目 | 关系 | 详见 |
|------|------|------|
| OpenLink | 运输层，OpenVault调用它做文件传输 | [../OpenLink/INDEX.md](../OpenLink/INDEX.md) |
| open-dev-tools | 共享构建工具链 | [../open-dev-tools/README.md](../open-dev-tools/README.md) |

| 2026-05-15 | 内嵌Web管理面板：Dashboard+Devices+Policies+Snapshots+API五页面，HTMX+Alpine.js暗色主题，根路径不再404 |

## 最近变更（2026-05-11）

- **v1.0.1** README+部署文档更新(非Docker部署) | 2026-05-11
- ✅ **Phase 5-10 全部完成**: 从云存储后端到v1.0.0发布
- **测试修复全绿** 4+3个失败全修(crypto/notification/restore/intel), 259测试全绿, commit 4550459
- **第三步门通过** Linux x86_64 release构建+二进制上传Release
- Phase 5: S3/R2+3-2-1+自愈+CLI, commit acf7082
- Phase 6: 加密+压缩+增量+管道, commit 6e390a3
- Phase 7: AI智能层+语义搜索, commit a459cfc
- Phase 8: 企业级+合规+RBAC+通知, commit 0c4633f
- Phase 9: 物理智能体API+Web面板+多设备, commit 6d13b6d
- Phase 10: Docker+CI/CD+14基准+4篇文档+v1.0.0, commit 716b6e3

→ 详细开发日志: [docs/dev-log/2026-05-09-phase2.md](docs/dev-log/2026-05-09-phase2.md)


## 开发技能拆解补充（2026-05-10）

> 以下内容原属 `技能/openvault-dev/`，现已拆解回项目INDEX。

### AI增强能力（Phase 4+）

- **智能文件识别**：AI自动识别重要度，推荐策略
- **语义级增量**：理解内容变化，只传差异（非块级去重）
- **AI恢复**：自然语言意图→定位恢复
- **异常预测**：健康趋势分析+风险预警
- **智能调度**：根据网络/设备状态优化备份时间
- **文件索引扩展（ext-indexer）**：全文/图片AI描述/音频转文字/PDF提取+向量化
- **搜索API**：语义+关键词双路召回，跨项目搜索，自然语言查询
- **知识整理智能体**：自动归类+知识卡片+自然语言指令
- **个性化学习**：搜索偏好/自动标注优先级/摘要推送/风格适配

### 开发铁律（完整7条）

1. **永不丢失** — 底线，任何决策优先保证数据安全
2. **自愈优先于告警** — 能自动修复不通知人
3. **端到端加密** — 可选但默认开启
4. **最少依赖** — 核心不依赖OpenLink，OpenLink是增强
5. **配置驱动** — 策略/后端/调度全部可配置
6. **渐进式** — 初期只做本地+云，不急着接AI
7. **安全合规** — 内容扫描，合规优先
## ⛔ 禁止项

- **禁止直接操作ECS服务器**：所有服务器操作（SSH/Remote Gateway/Docker管理）只能由ECS运维角色执行
- 需要部署/运维时：通过主对话转派给ECS运维角色，不要自己动手

## 部署信息
| 项目 | 部署文档 | 部署脚本 | 部署方式 | 服务器 |
|------|----------|----------|----------|--------|
| OpenVault | 待补充 | 待补充 | Docker(ECS)/二进制(云电脑) | ECS+云电脑 |

**部署文档**：`角色/ECS运维/knowledge/快速部署指南.md`（Docker/二进制/源码编译三种方式）

**实际部署状态（2026-05-11）**：
- **ECS（Docker）**：未部署（端口8090）
- **云电脑（二进制直跑）**：Nginx反代 `/vault/` → 占位页（等待 openvault-server 二进制发布）
- ✅ openvault-server已运行(8090端口)，内嵌Web管理面板
- 根路径返回Dashboard(设备/策略/快照/状态概览)


## 凭据

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | `github.pat` | 仓库 push/pull/CI |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。

## 关联角色

- 系统开发者（主）：Rust开发、加密存储架构设计

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
| 仓库 | https://github.com/youbanzhishi/openvault |
| Actions | https://github.com/youbanzhishi/openvault/actions |
