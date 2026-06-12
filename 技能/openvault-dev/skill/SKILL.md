# OpenVault 开发技能

> 项目代号：OpenVault
> 技能类型：项目级开发技能（项目上下文 + 开发规范 + 迭代指引）
> 目标：任何智能体加载此技能后，能0成本接手OpenVault项目的开发和迭代

---

## 一、项目定位

**OpenVault 不是网盘，不是同步工具，是智能时代的文件保险系统。**

- 网盘 = 存一份，靠服务商不倒
- 同步工具 = 多端一致，但不保证容灾
- OpenVault = 多地多副本 + 完整性校验 + 自愈 + AI智能管理

核心痛点：**重要文件害怕丢失，需要多地备份容灾，靠人记不住也管不过来。**

核心哲学：**狡兔三窟，AI守护，永不丢失。**

---

## 二、与OpenLink的关系

**OpenVault是保险层，OpenLink是运输层。独立项目，分层依赖。**

| 维度 | OpenLink | OpenVault |
|------|---------|-----------|
| 核心动作 | 路由（文件到哪去） | 复制（文件在多处都存在） |
| 问题域 | 怎么最快送到 | 怎么确保不丢 |
| 决策维度 | 网络拓扑、设备类型 | 副本数量、地理分布、版本历史 |

```
OpenVault（保险层）→ 策略/版本/校验/恢复
       │ 调用
OpenLink（运输层）→ 存储路由/传输路由/存储后端
       │ 依赖
open-storage（共享）→ StorageBackend trait + 实现
```

**关键原则：核心备份能力不依赖OpenLink，OpenLink是增强不是必需。** OpenLink不可用时降级为直接云端传输。

---

## 三、核心概念

### 3.1 备份策略（BackupPolicy）

```rust
BackupPolicy {
    name, replicas, locations, schedule, retention, versioning, priority
}
```

- replicas: 副本数（至少3）
- locations: 存储位置要求（后端类型/地域/加密）
- schedule: Realtime / Interval / OnChange
- retention: KeepAll / KeepVersions(N) / KeepDuration / Custom
- versioning: Full / Incremental / Semantic

### 3.2 3-2-1黄金规则（默认策略）

3份副本 / 2种介质 / 1份异地

### 3.3 文件清单（FileInventory）

记录每个文件存在哪里、什么版本、完整性状态。核心字段：file_id/path/checksum/replicas/last_verified/policy

### 3.4 完整性校验与自愈

- 定时SHA256校验 → 比对清单
- Healthy → 记录
- Degraded → 从健康副本自动修复（自愈）
- Corrupted → 告警人工介入
- Missing → 从其他副本重建

**自愈优先于告警：能自动修复的不通知人。**

---

## 四、AI增强能力（Phase 4+）

- 智能文件识别：AI自动识别重要度，推荐策略
- 语义级增量：理解内容变化，只传差异（非块级去重）
- AI恢复：自然语言意图→定位恢复
- 异常预测：健康趋势分析+风险预警
- 智能调度：根据网络/设备状态优化备份时间

---

## 五、项目结构

```
openvault/
├── Cargo.toml
├── crates/
│   ├── openvault-core/       # Policy/Inventory/Verification
│   ├── openvault-intel/      # AI智能层（Phase 4+）
│   ├── openvault-cli/        # 命令行工具
│   ├── openvault-server/     # API服务
│   └── openvault-daemon/     # 守护进程
├── extensions/
│   ├── ext-local-backup/
│   ├── ext-cloud-backup/
│   ├── ext-ai-classifier/
│   └── ext-ai-restore/
├── config/default.toml
├── docker/
└── deploy/
```

---

## 六、技术栈

| 组件 | 选择 |
|------|------|
| 语言 | Rust |
| 异步 | Tokio |
| CLI | clap |
| 文件监听 | notify |
| 增量备份 | rolling hash + 块去重 |
| 校验 | sha2 |
| 加密 | ring / aes-gcm |
| 存储 | open-storage crate |
| API | Axum |

---

## 七、开发铁律

1. **永不丢失** — 底线，任何决策优先保证数据安全
2. **自愈优先于告警** — 能自动修复不通知人
3. **端到端加密** — 可选但默认开启
4. **最少依赖** — 核心不依赖OpenLink，OpenLink是增强
5. **配置驱动** — 策略/后端/调度全部可配置
6. **渐进式** — 初期只做本地+云，不急着接AI
7. **安全合规** — 内容扫描，合规优先

---

## 八、路线图

### Phase 1：核心备份（本地优先）
核心概念/文件监听/增量备份/存储后端/CLI

### Phase 2：校验自愈 + 版本管理
SHA256校验/自愈/多版本/快照/恢复

### Phase 3：OpenLink集成 + 远程管理
OpenLink API/远程管理/多设备/通知

### Phase 4：AI智能层 + 语义搜索
- 文件索引扩展（ext-indexer）：全文/图片AI描述/音频转文字/PDF提取+向量化
- 搜索API：语义+关键词双路召回，跨项目搜索，自然语言查询
- 知识整理智能体：自动归类+知识卡片+自然语言指令
- 文件分类/语义增量/AI恢复/异常预测/智能调度
- 个性化学习：搜索偏好/自动标注优先级/摘要推送/风格适配

### Phase 5：企业级 + 安全合规
端到端加密/审计日志/合规/多租户/Web面板

---

## 九、关键决策记录

| 决策 | 选择 | 理由 | 日期 |
|------|------|------|------|
| 独立vs合并 | 独立项目 | 核心动作不同，合并四不像 | 2026-05-09 |
| 默认策略 | 3-2-1规则 | 行业最佳实践 | 2026-05-09 |
| AI接入 | Phase 4渐进式 | 先保证基础可靠性 | 2026-05-09 |
| 加密 | 默认开启 | 信任模型：只信任自己密钥 | 2026-05-09 |
| OpenLink依赖 | 可选增强 | 最后防线不能依赖外部 | 2026-05-09 |

---

*此技能文档随项目进展持续更新*
*最后更新：2026-05-09*
