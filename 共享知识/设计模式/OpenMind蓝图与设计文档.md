# OpenMind 蓝图与设计文档

> **版本**: v1.0  
> **状态**: 设计阶段  
> **最后更新**: 2025-06  
> **负责人**: Open-Knowledge-System 团队

---

## 目录

1. [项目概览](#1-项目概览)
2. [问题域分析](#2-问题域分析)
3. [架构设计](#3-架构设计)
4. [核心 Trait 设计（可插拔接口）](#4-核心-trait-设计可插拔接口)
5. [数据模型](#5-数据模型)
6. [摄入管道设计](#6-摄入管道设计)
7. [搜索设计](#7-搜索设计)
8. [降级策略](#8-降级策略)
9. [Connector 实现规划](#9-connector-实现规划)
10. [同步机制详细设计](#10-同步机制详细设计)
11. [大文件处理流程](#11-大文件处理流程)
12. [API 设计](#12-api-设计完整)
13. [服务发现架构（两级发现）](#13-服务发现架构两级发现)
14. [Roadmap](#14-roadmap)
15. [与其他项目的关系](#15-与其他项目的关系)
16. [关键技术选型](#16-关键技术选型)
17. [风险与应对](#17-风险与应对)

---

## 1. 项目概览

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| **名字** | OpenMind |
| **定位** | AI 原生个人知识引擎，Agent 生态知识节点 |
| **核心价值** | 让 AI "懂" 你的知识——不只是存，而是语义理解和关联 |
| **类比** | Google(搜) + Notion(组织) + Obsidian(关联) 的 AI 原生融合体 |
| **技术栈** | Rust + Axum + Qdrant + SQLite/Tantivy |
| **协议** | Agent Action Protocol v2 |

### 1.2 一句话描述

> OpenMind 是 Agent 生态中的**知识节点**——它让散落在博客、备忘录、书签、文件中的知识变得可搜索、可关联、可推理，为 AI Agent 提供语义级的知识服务。

### 1.3 核心设计哲学

1. **节点平等**：OpenMind 不是中枢，是知识节点，和其他项目（OpenVault、OpenDAW 等）架构地位完全平等
2. **协议驱动**：OpenLink 提供发现和路由，不参与业务调度
3. **点对点协作**：Agent 直接调节点，不经中间人
4. **文本存引擎，大文件存引用**：文本直接存 OpenMind，图片/音频/视频只存引用指针，原始文件在 OpenVault/S3
5. **可插拔设计**：Connector 可插拔、嵌入模型可插拔、存储后端可插拔
6. **两级发现**：一级=各节点自带 agent.json（永远可用），二级=Link 聚合发现（方便但不必须）
7. **手动搜索是基础权利**：即使没有任何 AI 能力，用户也能通过关键词、标签、时间范围搜索自己的知识。AI 是增强，不是门槛
8. **优雅降级**：嵌入模型挂了系统不能挂。自动降级到关键词搜索，模型恢复后自动补算

---

## 2. 问题域分析

### 2.1 痛点

| # | 痛点 | 具体表现 |
|---|------|---------|
| 1 | **找不到** | 博客/备忘录/书签越积越多，想用的时候搜不到 |
| 2 | **没关联** | 知识之间是孤岛，A 笔记和 B 博客讲的是同一件事但没人知道 |
| 3 | **搜不到私人内容** | Google 搜全网很强，但搜不到我自己的收藏和笔记 |
| 4 | **AI 没上下文** | 问 AI 一个问题，它不知道我之前写过什么、收藏过什么 |
| 5 | **格式割裂** | 知识散落在 Markdown/HTML/PDF/微信收藏/飞书文档，没有统一入口 |
| 6 | **AI 依赖陷阱** | 很多知识工具把搜索绑定 AI，AI 挂了就啥也搜不了 |

### 2.2 OpenVault 搜索 vs OpenMind 搜索

这是最容易混淆的概念，必须讲清楚：

| 维度 | OpenVault 搜索 | OpenMind 搜索 |
|------|---------------|--------------|
| **搜索级别** | 文件级 | 知识级 |
| **搜什么** | 文件名、路径、元数据、全文内容 | 语义含义、关联关系、上下文推理 |
| **返回什么** | 文件 | 知识条目（可能跨文件） |
| **怎么搜** | 关键词匹配、路径匹配 | 语义搜索、混合搜索、图谱遍历 |
| **典型场景** | "我的混音工程文件在哪" | "我之前写过哪些关于压缩器的心得" |
| **存储本质** | 文件系统（树结构） | 知识图谱（图结构） |

### 2.3 为什么不融入 OpenVault

1. **搜索级别根本不同**：文件级搜索和知识级搜索是两个维度，混在一起会让两边都变得复杂
2. **存储本质不同**：Vault 存的是文件（二进制块），Mind 存的是知识（文本+向量+关联）
3. **独立演化**：知识引擎需要独立的摄入管道、嵌入计算、图谱维护，放在 Vault 里会让 Vault 变成怪物
4. **职责清晰**：Vault 管"文件在哪"，Mind 管"知识是什么"，各司其职

但两者**紧密协作**：OpenMind 通过 VaultConnector 监听 Vault 变化，大文件存在 Vault 里只存引用。

---

## 3. 架构设计

### 3.1 整体架构图

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          Agent 生态                                      │
│                                                                          │
│  ┌─────────┐   ┌───────────┐   ┌──────────┐   ┌──────────┐            │
│  │ OpenDAW │   │ OpenMind  │   │OpenVault │   │OpenLink  │            │
│  │ 音乐节点 │   │ 知识节点   │   │ 存储节点  │   │ 发现节点  │            │
│  └────┬────┘   └─────┬─────┘   └────┬─────┘   └────┬─────┘            │
│       │              │              │              │                    │
│       └──────────────┴──────P2P─────┴──────────────┘                    │
│                     Action Protocol v2                                   │
└──────────────────────────────────────────────────────────────────────────┘
```

### 3.2 OpenMind 内部架构

```
                          ┌─────────────────┐
                          │   Agent API     │ ← REST + Action Protocol
                          │  (Axum Server)  │
                          └────────┬────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
              ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
              │  Search    │ │  Ingest   │ │  Sync     │
              │  Service   │ │  Pipeline │ │  Service  │
              └─────┬─────┘ └─────┬─────┘ └─────┬─────┘
                    │              │              │
         ┌──────────┼──────┐      │       ┌──────┴──────┐
         │          │      │      │       │             │
    ┌────▼───┐ ┌───▼──┐ ┌─▼───┐  │  ┌────▼────┐  ┌────▼────┐
    │Keyword │ │Semantic│ │Graph│  │  │Connector│  │Scheduler│
    │Search  │ │Search  │ │Query│  │  │Registry │  │(Cron)   │
    │(基础)  │ │(增强)  │ │     │  │  └────┬────┘  └─────────┘
    └────┬───┘ └───┬──┘ └─┬───┘  │       │
         │         │       │      │  ┌────▼────────────────────┐
         │    ┌────▼────┐  │      │  │ Connectors               │
         │    │Embedding│  │      │  │ ┌──────┐ ┌──────┐       │
         │    │Service  │  │      │  │ │Blog  │ │Vault │ ...   │
         │    │(可降级) │  │      │  │ └──────┘ └──────┘       │
         │    └────┬────┘  │      │  └─────────────────────────┘
         │         │       │      │
    ┌────▼─────────▼───────▼──────▼──┐
    │        Knowledge Store          │
    │  ┌────────┐ ┌───────┐ ┌─────┐ │
    │  │SQLite  │ │Qdrant │ │Graph│ │
    │  │(Meta+  │ │(Vector│ │(Rel)│ │
    │  │ FTS5)  │ │ Index)│ │     │ │
    │  └────────┘ └───────┘ └─────┘ │
    └────────────────────────────────┘

    ★ Keyword Search 是基础层，永远可用
    ★ Semantic Search 是增强层，依赖 EmbeddingService，可降级
    ★ 降级时：Keyword 正常 + Semantic 返回降级提示 + 新内容暂无向量
```

### 3.3 三层分离

```
┌─────────────────────────────────────────────┐
│  Layer 3: 查询接口 (Agent API)               │
│  - REST API (Axum)                           │
│  - Action Protocol v2 (agent.json)           │
│  - 事件订阅 (未来)                            │
│  - 降级状态透传（响应中标注 degraded）         │
├─────────────────────────────────────────────┤
│  Layer 2: 知识引擎 (OpenMind Core)           │
│  - 文本存储 + 全文索引（基础，永远可用）       │
│  - 向量存储 + 语义搜索（增强，可降级）         │
│  - 知识图谱 + 关联推理                        │
│  - 摄入管道 + 同步引擎（支持降级摄入）         │
│  - 降级管理器 (DegradationManager)            │
├─────────────────────────────────────────────┤
│  Layer 1: 原始文件存储 (Vault / S3)          │
│  - 图片、音频、视频的原始文件                  │
│  - OpenMind 只存引用指针 (URL)               │
│  - StorageBackend trait 抽象                 │
└─────────────────────────────────────────────┘
```

**为什么三层分离？**

1. **关注点分离**：每层独立演化，文件存储格式变化不影响知识引擎，搜索引擎升级不影响 API
2. **存储策略灵活**：大文件不在知识引擎里，引擎保持轻量
3. **可替换性**：Vault 换 S3、SQLite 换 PostgreSQL，都不影响上层
4. **降级隔离**：向量层挂了不影响基础文本层，系统永远不会完全不可用

### 3.4 节点架构：OpenMind 在 Agent 生态中的位置

```
                    ┌──────────────┐
                    │   OpenLink   │ ← 发现节点（二级发现）
                    │ ecosystem.json│
                    └──────┬───────┘
                           │ 聚合（方便但不必须）
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │  OpenMind   │ │  OpenVault  │ │  OpenDAW    │
    │  知识节点    │ │  存储节点    │ │  音乐节点    │
    │ :8080       │ │ :8081       │ │ :8082       │
    │ agent.json  │ │ agent.json  │ │ agent.json  │
    └─────────────┘ └─────────────┘ └─────────────┘

    ★ 所有节点地位平等，直接 P2P 通信
    ★ 每个节点自带 agent.json（一级发现，永远可用）
    ★ Link 挂了 → Agent 退回一级发现，生态不崩溃
```

---

## 4. 核心 Trait 设计（可插拔接口）

OpenMind 的扩展性通过四个核心 trait 实现。每个 trait 定义清晰的边界，实现即可插拔。

### 4.1 Connector Trait（数据源可插拔）

**职责**：从外部数据源拉取内容，统一为 `RawContent` 格式。

```rust
use async_trait::async_trait;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// 数据源类型枚举
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum ConnectorType {
    Blog,      // 博客（RSS/Webhook）
    Vault,     // OpenVault 文件
    Bookmark,  // 浏览器书签
    Note,      // 备忘录（各种格式）
    File,      // 本地目录
    WeChat,    // 微信收藏（未来）
    Feishu,    // 飞书文档（未来）
}

/// Connector 配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectorConfig {
    pub connector_type: ConnectorType,
    pub params: serde_json::Value,  // 类型特定参数，如 RSS URL、Vault 地址等
}

/// 变更条目
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangeEntry {
    pub source_id: String,           // 数据源中的唯一标识
    pub change_type: ChangeType,     // 变更类型
    pub content_hash: String,        // 内容哈希（用于去重）
    pub timestamp: DateTime<Utc>,    // 变更时间
    pub metadata: serde_json::Value, // 源特定元数据
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ChangeType {
    Created,
    Updated,
    Deleted,
}

/// 同步结果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResult {
    pub added: usize,
    pub updated: usize,
    pub deleted: usize,
    pub skipped: usize,       // hash 未变，跳过
    pub errors: Vec<String>,
    pub last_sync_at: DateTime<Utc>,
}

/// 原始内容（Connector 的输出）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawContent {
    pub source_id: String,
    pub source_type: ConnectorType,
    pub title: String,
    pub content: String,             // 纯文本或 Markdown
    pub content_hash: String,        // SHA-256
    pub url: Option<String>,         // 原始链接
    pub media_attachments: Vec<MediaAttachment>, // 附件
    pub metadata: serde_json::Value,
    pub fetched_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaAttachment {
    pub filename: String,
    pub media_type: String,          // MIME type
    pub data: Vec<u8>,               // 原始二进制
    pub url: Option<String>,         // 如果已有远程 URL
}

/// Connector trait —— 数据源可插拔的核心接口
#[async_trait]
pub trait Connector: Send + Sync {
    /// Connector 名称（唯一标识）
    fn name(&self) -> &str;

    /// 数据源类型
    fn connector_type(&self) -> ConnectorType;

    /// 初始化连接（验证配置、建立会话）
    async fn connect(&mut self, config: &ConnectorConfig) -> Result<()>;

    /// 列出指定时间之后的变更
    /// since=None 表示全量同步
    async fn list_changes(&self, since: Option<DateTime<Utc>>) -> Result<Vec<ChangeEntry>>;

    /// 获取单个变更条目的完整内容
    async fn fetch_content(&self, entry: &ChangeEntry) -> Result<RawContent>;

    /// 执行完整同步（list_changes + fetch_content 的封装）
    /// 默认实现：增量 list_changes → 逐条 fetch_content
    async fn sync(&mut self, since: Option<DateTime<Utc>>) -> Result<SyncResult> {
        let changes = self.list_changes(since).await?;
        let mut result = SyncResult {
            added: 0,
            updated: 0,
            deleted: 0,
            skipped: 0,
            errors: Vec::new(),
            last_sync_at: Utc::now(),
        };

        for change in changes {
            match change.change_type {
                ChangeType::Deleted => {
                    result.deleted += 1;
                }
                _ => {
                    match self.fetch_content(&change).await {
                        Ok(_content) => {
                            match change.change_type {
                                ChangeType::Created => result.added += 1,
                                ChangeType::Updated => result.updated += 1,
                                _ => {}
                            }
                        }
                        Err(e) => {
                            result.errors.push(format!(
                                "Failed to fetch {}: {}",
                                change.source_id, e
                            ));
                        }
                    }
                }
            }
        }

        Ok(result)
    }

    /// 断开连接、释放资源
    async fn disconnect(&mut self) -> Result<()> {
        Ok(())
    }
}
```

**为什么 Connector 是 trait 而不是 enum？**

1. **开放封闭**：新增数据源不需要修改核心代码，实现 trait 即可
2. **独立测试**：每个 Connector 独立测试，mock 简单
3. **动态注册**：运行时注册/卸载 Connector，不需要重新编译

### 4.2 StorageBackend Trait（存储后端可插拔）

**职责**：抽象大文件的存储位置，OpenMind 只存引用，原始文件通过此 trait 存取。

```rust
use bytes::Bytes;
use url::Url;

/// 存储后端 trait —— 大文件存储的抽象
#[async_trait]
pub trait StorageBackend: Send + Sync {
    /// 存储数据，返回访问 URL
    async fn put(&self, key: &str, data: Bytes) -> Result<Url>;

    /// 通过 URL 获取数据
    async fn get(&self, url: &Url) -> Result<Bytes>;

    /// 删除数据
    async fn delete(&self, url: &Url) -> Result<()>;

    /// 根据 key 获取 URL（不下载内容）
    async fn get_url(&self, key: &str) -> Result<Url>;

    /// 检查 key 是否存在
    async fn exists(&self, key: &str) -> Result<bool>;

    /// 后端名称
    fn name(&self) -> &str;
}
```

**预期实现**：

| 实现 | 用途 | 说明 |
|------|------|------|
| `VaultStorageBackend` | 对接 OpenVault | 通过 Vault API 上传/下载 |
| `S3StorageBackend` | 对接 S3 兼容存储 | MinIO / AWS S3 / 阿里 OSS |
| `LocalStorageBackend` | 本地目录 | 开发测试用，文件存本地 |

**为什么 StorageBackend 是独立 trait？**

1. **解耦**：知识引擎不需要知道文件存在哪，只需要一个 URL
2. **灵活**：开发用本地，生产用 S3，无缝切换
3. **与 Vault 协作**：Vault 本身就是一个 StorageBackend 实现

### 4.3 EmbeddingModel Trait（嵌入模型可插拔）

**职责**：将文本/图片转为向量，支持不同嵌入模型的切换。**关键：此 trait 的实现可能失败，系统必须能在此 trait 不可用时继续运行。**

```rust
/// 嵌入模型健康状态
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum EmbeddingHealth {
    Healthy,                    // 正常可用
    Degraded(String),           // 降级（原因：限流、延迟高等）
    Unavailable(String),        // 不可用（原因：API 宕机、网络不通等）
}

/// 嵌入模型 trait —— 向量化可插拔
#[async_trait]
pub trait EmbeddingModel: Send + Sync {
    /// 单条文本嵌入
    async fn embed_text(&self, text: &str) -> Result<Vec<f32>>;

    /// 批量文本嵌入（利用模型批处理优化）
    async fn embed_texts(&self, texts: &[&str]) -> Result<Vec<Vec<f32>>>;

    /// 向量维度
    fn dimension(&self) -> usize;

    /// 模型名称
    fn model_name(&self) -> &str;

    /// 最大输入 token 数
    fn max_tokens(&self) -> usize {
        8192 // 默认值
    }

    /// 健康检查 —— 降级判断的核心
    /// 返回当前模型的可用状态
    async fn health_check(&self) -> EmbeddingHealth {
        // 默认实现：尝试嵌入一段测试文本
        match self.embed_text("health check").await {
            Ok(_) => EmbeddingHealth::Healthy,
            Err(e) => EmbeddingHealth::Unavailable(e.to_string()),
        }
    }

    // ---- 未来扩展 ----

    /// 图像嵌入（CLIP 等）
    async fn embed_image(&self, _image_data: &[u8]) -> Result<Vec<f32>> {
        Err(anyhow::anyhow!("Image embedding not supported by {}", self.model_name()))
    }

    /// 多模态嵌入（图文对）
    async fn embed_multimodal(
        &self,
        _text: &str,
        _image_data: &[u8],
    ) -> Result<Vec<f32>> {
        Err(anyhow::anyhow!("Multimodal embedding not supported by {}", self.model_name()))
    }
}
```

**预期实现**：

| 实现 | 模型 | 维度 | 说明 |
|------|------|------|------|
| `OpenAIEmbedding` | text-embedding-3-small | 1536 | API 调用，质量好 |
| `BGEM3Embedding` | BGE-M3 | 1024 | 本地部署，多语言 |
| `LocalEmbedding` | ONNX Runtime | 视模型 | 离线场景 |

**模型切换怎么办？**

如果换了嵌入模型，向量维度可能不同，需要全量重算。设计 `reindex` 命令：

```rust
/// 重索引命令
pub struct ReindexCommand {
    pub model_name: String,        // 新模型名
    pub batch_size: usize,         // 批量大小
    pub dry_run: bool,             // 只看不干
}

impl ReindexCommand {
    /// 后台异步执行：逐批读取 → 重新嵌入 → 写入 Qdrant
    pub async fn execute(&self, store: &dyn KnowledgeStore) -> Result<ReindexReport> {
        // 1. 验证新模型维度与 Qdrant collection 匹配
        // 2. 如不匹配，创建新 collection
        // 3. 分批读取所有 KnowledgeEntry
        // 4. 重新嵌入 → 写入新 collection
        // 5. 原子切换：旧 collection → 新 collection
        // 6. 返回报告
        todo!()
    }
}
```

### 4.4 KnowledgeStore Trait（知识存储）

**职责**：知识条目的 CRUD + 搜索 + 关联，统一访问接口。

```rust
/// 搜索类型
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SearchType {
    Keyword,
    Semantic,
    Hybrid,
}

/// 关联类型
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum RelationType {
    Similar,       // 相似
    DerivedFrom,   // 派生自
    References,    // 引用
    Contradicts,   // 矛盾
    PartOf,        // 部分属于
}

/// 搜索过滤条件
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SearchFilter {
    pub source_types: Option<Vec<ConnectorType>>,
    pub tags: Option<Vec<String>>,
    pub date_range: Option<(DateTime<Utc>, DateTime<Utc>)>,
    pub project: Option<String>,
}

/// 知识存储 trait —— 知识条目的统一访问接口
#[async_trait]
pub trait KnowledgeStore: Send + Sync {
    // ---- CRUD ----

    /// 存储知识条目，返回 ID
    async fn store(&self, entry: KnowledgeEntry) -> Result<String>;

    /// 获取单个知识条目
    async fn get(&self, id: &str) -> Result<Option<KnowledgeEntry>>;

    /// 批量获取
    async fn get_batch(&self, ids: &[String]) -> Result<Vec<Option<KnowledgeEntry>>>;

    /// 标记删除（archived，不真删）
    async fn archive(&self, id: &str) -> Result<()>;

    /// 更新知识条目
    async fn update(&self, id: &str, entry: KnowledgeEntry) -> Result<()>;

    // ---- 搜索 ----

    /// 关键词搜索（基础搜索，永远可用，不依赖任何 AI 模型）
    async fn query_keyword(
        &self,
        query: &str,
        limit: usize,
        filter: Option<SearchFilter>,
    ) -> Result<Vec<SearchResult>>;

    /// 语义搜索（增强搜索，依赖嵌入模型，可降级）
    async fn query_semantic(
        &self,
        query: &str,
        limit: usize,
        filter: Option<SearchFilter>,
    ) -> Result<Vec<SearchResult>>;

    /// 混合搜索（关键词 + 语义）
    async fn query_hybrid(
        &self,
        query: &str,
        limit: usize,
        filter: Option<SearchFilter>,
    ) -> Result<Vec<SearchResult>>;

    // ---- 关联 ----

    /// 创建关联
    async fn relate(
        &self,
        from: &str,
        to: &str,
        relation: RelationType,
        weight: f32,
    ) -> Result<()>;

    /// 删除关联
    async fn unrelate(&self, from: &str, to: &str, relation: &RelationType) -> Result<()>;

    /// 获取关联知识
    async fn get_related(
        &self,
        id: &str,
        depth: usize,
    ) -> Result<Vec<RelatedEntry>>;

    // ---- 统计 ----

    /// 知识库统计
    async fn stats(&self) -> Result<KnowledgeStats>;
}

/// 知识库统计
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KnowledgeStats {
    pub total_entries: usize,
    pub entries_by_type: std::collections::HashMap<String, usize>,
    pub total_relations: usize,
    pub total_file_references: usize,
    pub last_sync_at: Option<DateTime<Utc>>,
    pub index_size_bytes: u64,
    /// 未向量化的条目数（降级指标）
    pub unembedded_count: usize,
}
```

---

## 5. 数据模型

### 5.1 KnowledgeEntry（知识条目）

这是 OpenMind 的核心数据单元，每条知识就是一个 `KnowledgeEntry`。

```rust
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// 知识条目状态
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum EntryStatus {
    Active,     // 正常
    Archived,   // 已归档（源内容已删除，但索引和关联保留）
    Pending,    // 待处理（摄入中）
    Error,      // 处理失败
}

/// 嵌入状态 —— 追踪每条知识的向量化进度
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum EmbeddingStatus {
    Embedded,       // 已向量化
    Pending,        // 待向量化（模型不可用时摄入的内容）
    Failed(String), // 向量化失败
    Skipped,        // 跳过（内容太短或为空）
}

/// 知识条目 —— OpenMind 的核心数据单元
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KnowledgeEntry {
    /// 唯一标识（UUID v7，时间有序）
    pub id: String,

    /// 数据源类型
    pub source_type: ConnectorType,

    /// 数据源中的原始 ID
    pub source_id: String,

    /// 原始 URL（如果有）
    pub source_url: Option<String>,

    /// 标题
    pub title: String,

    /// 文本内容（纯文本或 Markdown）
    pub content: String,

    /// 内容哈希（SHA-256，用于去重和变更检测）
    pub content_hash: String,

    /// Qdrant 中的向量 ID
    pub embedding_id: Option<String>,

    /// 嵌入状态（降级容灾的关键字段）
    pub embedding_status: EmbeddingStatus,

    /// 标签列表
    pub tags: Vec<String>,

    /// 所属项目（可选分组）
    pub project: Option<String>,

    /// 大文件引用列表
    pub file_references: Vec<FileReference>,

    /// 扩展元数据（灵活字段）
    pub metadata: serde_json::Value,

    /// 创建时间
    pub created_at: DateTime<Utc>,

    /// 更新时间
    pub updated_at: DateTime<Utc>,

    /// 条目状态
    pub status: EntryStatus,
}
```

**字段设计说明**：

| 字段 | 为什么需要 |
|------|-----------|
| `id` (UUID v7) | 时间有序，天然按时间排序，不需要额外时间索引 |
| `content_hash` | 去重核心：相同内容不重复索引；变更检测：hash 变了才重新索引 |
| `embedding_id` | 与 Qdrant 向量关联，解耦存储层和向量层 |
| `embedding_status` | **降级容灾关键字段**：标记此条目是否已向量化。模型不可用时摄入的内容标记为 Pending，恢复后据此补算 |
| `source_id` | 回溯原始数据源，用于同步时匹配 |
| `file_references` | 大文件不在 content 里，只存引用 |
| `status.archived` | 源删了不真删，保留关联和索引——知识关联是价值所在 |

### 5.2 FileReference（大文件引用）

```rust
/// 大文件引用 —— 文本存引擎，大文件存引用
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileReference {
    /// 引用 ID
    pub id: String,

    /// 存储后端标识（vault / s3 / local）
    pub storage_backend: String,

    /// 文件访问 URL
    pub url: String,

    /// 文件内容哈希
    pub content_hash: String,

    /// MIME 类型
    pub media_type: String,

    /// 从文件提取的文本（OCR/转录/描述）
    pub extracted_text: Option<String>,

    /// 缩略图 URL
    pub thumbnail_url: Option<String>,

    /// 文件大小（字节）
    pub size_bytes: Option<u64>,

    /// 文件元数据（时长、分辨率等）
    pub metadata: serde_json::Value,
}
```

**为什么 extracted_text 在引用里？**

因为图片 OCR 出来的文字、音频 Whisper 转录出来的文字，需要被搜索和嵌入。但这些文本不属于知识条目的"正文"，而是附件的衍生文本。放引用里语义更清晰。

### 5.3 KnowledgeRelation（知识关联）

```rust
/// 知识关联 —— 连接知识条目的边
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KnowledgeRelation {
    /// 起点 ID
    pub from_id: String,

    /// 终点 ID
    pub to_id: String,

    /// 关联类型
    pub relation_type: RelationType,

    /// 关联权重（0.0 ~ 1.0）
    pub weight: f32,

    /// 关联元数据
    pub metadata: serde_json::Value,

    /// 创建时间
    pub created_at: DateTime<Utc>,
}
```

**关联类型说明**：

| 类型 | 含义 | 典型场景 |
|------|------|---------|
| `Similar` | 内容相似 | 两篇博客讲同一话题 |
| `DerivedFrom` | 派生关系 | 笔记源自某篇博客 |
| `References` | 引用关系 | A 引用了 B 的观点 |
| `Contradicts` | 矛盾关系 | A 和 B 观点相反（特别有价值） |
| `PartOf` | 包含关系 | 笔记是项目文档的一部分 |

**权重的作用**：

- 自动发现的关联（向量相似度）权重 = 相似度分数
- 人工标注的关联权重 = 1.0
- 搜索时可以根据权重排序关联结果

### 5.4 SyncState（同步状态）

```rust
/// 同步状态 —— 追踪每个 Connector 的同步进度
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncState {
    /// Connector 名称
    pub connector_name: String,

    /// 最后同步时间
    pub last_sync_at: DateTime<Utc>,

    /// 最后同步的内容哈希（用于快速变更检测）
    pub content_hash: Option<String>,

    /// 同步状态
    pub status: SyncStatus,

    /// 错误信息（如果失败）
    pub last_error: Option<String>,

    /// 统计信息
    pub stats: SyncStats,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum SyncStatus {
    Idle,        // 空闲
    Syncing,     // 同步中
    Completed,   // 同步完成
    Failed,      // 同步失败
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SyncStats {
    pub total_synced: usize,
    pub total_errors: usize,
    pub last_duration_secs: Option<u64>,
}
```

### 5.5 SearchResult（搜索结果）

```rust
/// 搜索结果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    /// 匹配的知识条目
    pub entry: KnowledgeEntry,

    /// 相关度分数（0.0 ~ 1.0）
    pub relevance: f32,

    /// 高亮片段
    pub highlights: Vec<Highlight>,

    /// 关联条目（简要）
    pub related_entries: Vec<RelatedEntry>,

    /// 搜索来源
    pub search_type: SearchType,

    /// 降级提示（当搜索结果因模型不可用而不完整时）
    pub degradation_notice: Option<DegradationNotice>,
}

/// 降级提示
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DegradationNotice {
    /// 降级原因
    pub reason: String,

    /// 哪些功能受影响
    pub affected_features: Vec<String>,

    /// 降级时间
    pub since: DateTime<Utc>,
}

/// 高亮片段
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Highlight {
    /// 字段名
    pub field: String,

    /// 高亮文本（包含 <em> 标签）
    pub text: String,

    /// 位置偏移
    pub offset: usize,
}

/// 关联条目（简要）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelatedEntry {
    /// 知识条目 ID
    pub id: String,

    /// 标题
    pub title: String,

    /// 关联类型
    pub relation_type: RelationType,

    /// 关联权重
    pub weight: f32,
}
```

### 5.6 ChangeEntry（变更条目）

```rust
/// 变更条目 —— Connector 报告的内容变更
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangeEntry {
    /// 数据源中的唯一标识
    pub source_id: String,

    /// 变更类型
    pub change_type: ChangeType,

    /// 内容哈希（用于去重）
    pub content_hash: String,

    /// 变更时间
    pub timestamp: DateTime<Utc>,

    /// 源特定元数据
    pub metadata: serde_json::Value,
}
```

### 5.7 数据模型关系图

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────────┐
│KnowledgeEntry│───────│KnowledgeRelation │───────│KnowledgeEntry    │
│              │ from  │                  │ to    │                  │
│ id           │       │ from_id          │       │ id               │
│ title        │       │ to_id            │       │ title            │
│ content      │       │ relation_type    │       │ content          │
│ content_hash │       │ weight           │       │ content_hash     │
│ source_type  │       └──────────────────┘       │ source_type      │
│ tags[]       │                                  │ tags[]           │
│ status       │                                  │ status           │
│ embedding_   │                                  │ embedding_       │
│ status ★    │                                  │ status ★        │
└──────┬───────┘                                  └──────────────────┘
       │
       │ 1:N
       │
┌──────▼───────┐       ┌──────────────────┐
│FileReference │       │   SyncState      │
│              │       │                  │
│ id           │       │ connector_name   │
│ url          │       │ last_sync_at     │
│ media_type   │       │ content_hash     │
│ extracted_text│      │ status           │
│ thumbnail_url│       └──────────────────┘
└──────────────┘

★ embedding_status: Embedded / Pending / Failed / Skipped
   这是降级容灾的关键字段——模型不可用时新条目标记 Pending，
   模型恢复后据此批量补算向量

┌──────────────────┐
│   ChangeEntry    │ ← Connector 输出的变更通知
│                  │
│ source_id        │
│ change_type      │
│ content_hash     │
│ timestamp        │
└──────────────────┘
```

---

## 6. 摄入管道设计

摄入管道是 OpenMind 的数据入口，将原始内容转化为可搜索的知识。**管道必须支持降级模式——当嵌入模型不可用时，只做关键词索引，跳过向量化步骤。**

### 6.1 管道流程

```
原始内容 ──→ 解析(Parser) ──→ 分块(Chunker) ──→ 嵌入(Embedder) ──→ 索引(Indexer) ──→ 关联(Relator)
   │             │               │                │                │               │
   │         提取文本         切分为块         生成向量         写入存储        发现关联
   │         检测语言         去重检查         维度校验         更新索引        更新图谱
   │         提取元数据       重叠窗口                          触发事件
   │
   └──→ 大文件？──→ 是 ──→ StorageBackend.put() ──→ 存引用
                  └──→ 否 ──→ 文本直接入管道


降级模式下的管道流程：

原始内容 ──→ 解析(Parser) ──→ 分块(Chunker) ──╳──→ 嵌入(Embedder) ──→ 索引(Indexer) ──→ 关联(Relator)
   │             │               │             │           │                │               │
   │         提取文本         切分为块      跳过！      关键词索引        手动关联       暂停自动
   │         检测语言         去重检查    标记Pending   写入SQLite      (可选)         关联发现
   │         提取元数据       重叠窗口    加入补算队列   （无向量）                    (依赖向量)
   │
   └──→ embedding_status = Pending
        等模型恢复后，BackgroundEmbedder 异步补算
```

### 6.2 解析器 (Parser)

```rust
/// 解析器 —— 从原始内容提取文本和元数据
pub struct Parser {
    /// 已注册的解析器
    parsers: Vec<Box<dyn ContentParser>>,
}

/// 内容解析器 trait
#[async_trait]
pub trait ContentParser: Send + Sync {
    /// 能否处理此 MIME 类型
    fn can_parse(&self, media_type: &str) -> bool;

    /// 解析内容
    async fn parse(&self, raw: &RawContent) -> Result<ParsedContent>;
}

/// 解析结果
#[derive(Debug, Clone)]
pub struct ParsedContent {
    /// 标题
    pub title: String,

    /// 纯文本内容
    pub text: String,

    /// 语言（zh/en/...）
    pub language: Option<String>,

    /// 提取的元数据
    pub metadata: serde_json::Value,

    /// 提取的媒体附件
    pub attachments: Vec<MediaAttachment>,
}
```

**各格式的解析策略**：

| 格式 | 解析方式 | 输出 |
|------|---------|------|
| 纯文本/Markdown | 直接提取 | 原文 |
| HTML | 提取正文（readability 算法） | 纯文本 |
| PDF | pdf-extract / poppler | 纯文本 |
| 图片 | OCR (Tesseract) + CLIP 描述 | 文本 + 图像向量 |
| 音频 | Whisper 转录 | 转录文本 |
| 视频 | 关键帧提取 + Whisper 转录 | 关键帧描述 + 转录文本 |
| 代码 | 语法高亮 + 注释提取 | 源码 + 注释 |

### 6.3 分块器 (Chunker)

**为什么需要分块？**

1. 嵌入模型有 token 限制（通常 512~8192）
2. 搜索时返回小片段比返回整篇文章更精确
3. 语义粒度：一段话通常表达一个完整意思

```rust
/// 分块器
pub struct Chunker {
    /// 最大 token 数
    max_tokens: usize,

    /// 重叠 token 数
    overlap_tokens: usize,
}

/// 文本块
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextChunk {
    /// 块 ID
    pub id: String,

    /// 父条目 ID
    pub parent_id: String,

    /// 块内容
    pub content: String,

    /// 块索引（从 0 开始）
    pub index: usize,

    /// 总块数
    pub total_chunks: usize,

    /// 在原文中的偏移（字符位置）
    pub offset: usize,

    /// 块类型
    pub chunk_type: ChunkType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ChunkType {
    Paragraph,   // 段落
    Heading,     // 标题下的内容
    CodeBlock,   // 代码块
    List,        // 列表
    Media,       // 媒体描述（整体为一块）
}
```

**分块策略详解**：

```
文本分块（最常见）：
┌─────────────────────────────────────────────┐
│ # 标题1                                      │ ← Heading 块
│ 这是一段关于Rust的介绍文字...                   │
│                                              │
│ ## 标题1.1                                   │ ← Heading 块
│ Rust的所有权机制是其最核心的特性...             │
│ 它确保了内存安全而无需垃圾回收...               │
│                                              │← overlap=100字
│ ...Rust的所有权机制确保了... │← 重叠部分       │
│ 生命周期标注帮助编译器理解引用...               │ ← 下一个块
└─────────────────────────────────────────────┘

规则：
- 按 heading / 段落分块
- 相邻块重叠 overlap_tokens 个 token（保证语义连续性）
- 单块不超过 max_tokens（默认 512）
- 超长段落按句子切分

代码分块：
- 按函数/类/结构体分块
- 保留完整的语法单元
- 不做重叠（代码逻辑需要完整性）

图片/音频分块：
- 图片：整体为一块（CLIP 向量 + OCR 文本）
- 音频：转录文本按时间分段（每段 ~30 秒）
```

### 6.4 嵌入器 (Embedder) —— 含降级逻辑

```rust
/// 嵌入器 —— 将文本块转为向量
/// ★ 降级感知：模型不可用时返回降级结果，不阻塞摄入管道
pub struct Embedder {
    model: Box<dyn EmbeddingModel>,
    /// 降级状态
    degradation: Arc<DegradationManager>,
}

/// 嵌入结果
pub enum EmbedResult {
    /// 成功嵌入
    Success(EmbeddedChunk),
    /// 降级：模型不可用，跳过嵌入
    Degraded {
        chunk: TextChunk,
        reason: String,
    },
}

impl Embedder {
    /// 嵌入单个文本块（降级感知）
    pub async fn embed_chunk(&self, chunk: &TextChunk) -> EmbedResult {
        // 检查降级状态
        if self.degradation.is_embedding_degraded().await {
            return EmbedResult::Degraded {
                chunk: chunk.clone(),
                reason: self.degradation.degradation_reason().await
                    .unwrap_or_else(|| "Embedding model unavailable".to_string()),
            };
        }

        match self.model.embed_text(&chunk.content).await {
            Ok(vector) => EmbedResult::Success(EmbeddedChunk {
                chunk: chunk.clone(),
                vector,
                model_name: self.model.model_name().to_string(),
                dimension: self.model.dimension(),
            }),
            Err(e) => {
                // 嵌入失败 → 触发降级
                self.degradation
                    .report_embedding_failure(&e.to_string())
                    .await;
                EmbedResult::Degraded {
                    chunk: chunk.clone(),
                    reason: e.to_string(),
                }
            }
        }
    }

    /// 批量嵌入
    pub async fn embed_batch(&self, chunks: &[TextChunk]) -> Vec<EmbedResult> {
        if self.degradation.is_embedding_degraded().await {
            return chunks
                .iter()
                .map(|chunk| EmbedResult::Degraded {
                    chunk: chunk.clone(),
                    reason: "Embedding model unavailable (batch)".to_string(),
                })
                .collect();
        }

        let texts: Vec<&str> = chunks.iter().map(|c| c.content.as_str()).collect();
        match self.model.embed_texts(&texts).await {
            Ok(vectors) => chunks
                .iter()
                .zip(vectors.into_iter())
                .map(|(chunk, vector)| {
                    EmbedResult::Success(EmbeddedChunk {
                        chunk: chunk.clone(),
                        vector,
                        model_name: self.model.model_name().to_string(),
                        dimension: self.model.dimension(),
                    })
                })
                .collect(),
            Err(e) => {
                self.degradation
                    .report_embedding_failure(&e.to_string())
                    .await;
                chunks
                    .iter()
                    .map(|chunk| EmbedResult::Degraded {
                        chunk: chunk.clone(),
                        reason: e.to_string(),
                    })
                    .collect()
            }
        }
    }
}

#[derive(Debug, Clone)]
pub struct EmbeddedChunk {
    pub chunk: TextChunk,
    pub vector: Vec<f32>,
    pub model_name: String,
    pub dimension: usize,
}
```

### 6.5 索引器 (Indexer)

```rust
/// 索引器 —— 将嵌入后的内容写入存储
/// ★ 降级感知：根据 EmbedResult 决定写入哪些索引
pub struct Indexer {
    /// 知识存储
    store: Box<dyn KnowledgeStore>,

    /// 向量存储（Qdrant）
    vector_store: Box<dyn VectorStore>,
}

/// 向量存储 trait（Qdrant 的抽象）
#[async_trait]
pub trait VectorStore: Send + Sync {
    /// 创建 collection
    async fn create_collection(&self, name: &str, dimension: usize) -> Result<()>;

    /// 插入向量
    async fn upsert(&self, collection: &str, id: &str, vector: Vec<f32>, payload: serde_json::Value) -> Result<()>;

    /// 搜索最相似的向量
    async fn search(
        &self,
        collection: &str,
        vector: &[f32],
        limit: usize,
        filter: Option<serde_json::Value>,
    ) -> Result<Vec<VectorSearchResult>>;

    /// 删除向量
    async fn delete(&self, collection: &str, id: &str) -> Result<()>;
}

#[derive(Debug, Clone)]
pub struct VectorSearchResult {
    pub id: String,
    pub score: f32,
    pub payload: serde_json::Value,
}

impl Indexer {
    /// 索引嵌入结果（处理成功和降级两种情况）
    pub async fn index_embed_result(&self, result: EmbedResult) -> Result<String> {
        match result {
            EmbedResult::Success(embedded) => {
                // 正常模式：写入所有索引
                // 1. 写入向量索引
                self.vector_store
                    .upsert("knowledge", &embedded.chunk.id, embedded.vector, serde_json::json!({
                        "parent_id": embedded.chunk.parent_id,
                    }))
                    .await?;

                // 2. 写入知识存储（embedding_status = Embedded）
                let entry_id = embedded.chunk.parent_id.clone();
                // ... 更新 entry 的 embedding_id 和 embedding_status
                Ok(entry_id)
            }
            EmbedResult::Degraded { chunk, reason } => {
                // 降级模式：只写关键词索引，标记 Pending
                // 1. 不写入向量索引
                // 2. 写入知识存储，embedding_status = Pending
                // 3. 加入补算队列
                tracing::warn!(
                    "Embedding degraded for chunk {}: {}",
                    chunk.id, reason
                );
                Ok(chunk.parent_id.clone())
            }
        }
    }
}
```

### 6.6 关联器 (Relator)

```rust
/// 关联器 —— 自动发现知识之间的关联
/// ★ 降级感知：模型不可用时暂停自动关联发现
pub struct Relator {
    vector_store: Box<dyn VectorStore>,
    knowledge_store: Box<dyn KnowledgeStore>,
    degradation: Arc<DegradationManager>,
}

impl Relator {
    /// 为新条目发现关联
    pub async fn discover_relations(
        &self,
        entry: &KnowledgeEntry,
        embedding: Option<&[f32]>,
    ) -> Result<Vec<KnowledgeRelation>> {
        // 降级模式：无向量则跳过自动关联
        let embedding = match embedding {
            Some(e) => e,
            None => {
                tracing::info!(
                    "Skipping auto-relation for entry {} (no embedding)",
                    entry.id
                );
                return Ok(vec![]);
            }
        };

        let similar = self.vector_store
            .search("knowledge", embedding, 10, None)
            .await?;

        let mut relations = Vec::new();
        for result in similar {
            if result.id == entry.id {
                continue;
            }
            if result.score > 0.7 {
                relations.push(KnowledgeRelation {
                    from_id: entry.id.clone(),
                    to_id: result.id.clone(),
                    relation_type: RelationType::Similar,
                    weight: result.score,
                    metadata: serde_json::json!({
                        "discovered_by": "auto_similarity",
                    }),
                    created_at: Utc::now(),
                });
            }
        }

        for rel in &relations {
            self.knowledge_store
                .relate(&rel.from_id, &rel.to_id, rel.relation_type.clone(), rel.weight)
                .await?;
        }

        Ok(relations)
    }
}
```

### 6.7 去重机制

```
摄入请求 → 计算 content-hash (SHA-256)
              │
              ├─→ hash 已存在？──→ 是 ──→ hash 相同？──→ 是 ──→ 跳过（无变更）
              │                                   │
              │                                   └──→ 否 ──→ 更新（重新索引）
              │
              └──→ hash 不存在 ──→ 新条目 → 摄入管道
```

**为什么用 content-hash 而不是 source_id？**

- 同一内容可能来自多个数据源（博客 + 书签收藏了同一篇文章），source_id 不同但内容相同
- content-hash 是内容级去重，source_id 是数据源级去重
- 两者结合：先查 source_id（快速），再查 content-hash（准确）

---

## 7. 搜索设计

### 7.1 搜索分层：手动搜索是基础权利

**核心原则：手动搜索（关键词、标签、时间范围）是基础权利，不依赖任何 AI 能力。AI 是增强，不是门槛。**

```
┌──────────────────────────────────────────────────────────┐
│                    搜索分层架构                            │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  基础层：手动搜索（永远可用）                      │    │
│  │  ┌─────────────┐  ┌────────────┐  ┌──────────┐ │    │
│  │  │  关键词搜索  │  │  标签浏览   │  │ 时间范围  │ │    │
│  │  │  (FTS5/     │  │  tag:rust   │  │ after:   │ │    │
│  │  │   Tantivy)  │  │  tag:音乐   │  │ 2024-01  │ │    │
│  │  └─────────────┘  └────────────┘  └──────────┘ │    │
│  │                                                  │    │
│  │  ★ 不依赖任何 AI 模型                             │    │
│  │  ★ 不需要嵌入模型                                 │    │
│  │  ★ 不需要向量数据库                               │    │
│  │  ★ 纯 SQLite FTS5 + SQL 查询                     │    │
│  │  ★ 用户基础权利，系统最差情况也能用                │    │
│  └─────────────────────────────────────────────────┘    │
│                           │                              │
│                     AI 可用时增强                         │
│                           │                              │
│  ┌─────────────────────────────────────────────────┐    │
│  │  增强层：AI 搜索（需要嵌入模型）                   │    │
│  │  ┌─────────────┐  ┌─────────────┐               │    │
│  │  │  语义搜索    │  │  混合搜索   │               │    │
│  │  │  (Qdrant    │  │  (RRF 融合  │               │    │
│  │  │   cosine)   │  │  Keyword +  │               │    │
│  │  │             │  │  Semantic)  │               │    │
│  │  └─────────────┘  └─────────────┘               │    │
│  │                                                  │    │
│  │  ★ 依赖 EmbeddingModel 可用                      │    │
│  │  ★ 不可用时自动降级到基础层                       │    │
│  └─────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

**为什么手动搜索是基础权利？**

1. **零依赖**：关键词搜索只需要 SQLite FTS5，不需要网络、不需要 API、不需要 GPU
2. **确定性**：关键词搜到就是搜到，没有模型幻觉和不确定性
3. **可控性**：用户完全知道搜了什么、为什么匹配
4. **可用性**：即使嵌入模型 API 挂了、Qdrant 挂了、网络断了，搜索功能照常工作
5. **渐进增强**：先用关键词搜，AI 是锦上添花，不是必需品

### 7.2 手动搜索详解

手动搜索提供三种方式，全部不依赖 AI：

#### 7.2.1 关键词搜索

```rust
/// 关键词搜索 —— 基础搜索，永远可用
/// 实现：SQLite FTS5 倒排索引
pub struct KeywordSearch {
    pool: sqlx::SqlitePool,
}

impl KeywordSearch {
    /// 基础关键词搜索
    pub async fn search(
        &self,
        query: &str,
        limit: usize,
        filter: Option<&SearchFilter>,
    ) -> Result<Vec<SearchResult>> {
        // FTS5 全文搜索 + 过滤
        let sql = build_keyword_query(filter);
        let rows = sqlx::query_as::<_, EntryRow>(&sql)
            .bind(query)
            .bind(limit)
            .fetch_all(&self.pool)
            .await?;

        Ok(rows.into_iter().map(|r| r.into_search_result()).collect())
    }

    /// 按标签搜索
    pub async fn search_by_tags(
        &self,
        tags: &[String],
        match_mode: TagMatchMode,
        limit: usize,
    ) -> Result<Vec<SearchResult>> {
        // SELECT ... WHERE tags @> '[...]' (JSON 包含)
        // 或 FTS5: tag:rust tag:programming
        todo!()
    }

    /// 按时间范围搜索
    pub async fn search_by_date(
        &self,
        range: (DateTime<Utc>, DateTime<Utc>),
        limit: usize,
    ) -> Result<Vec<SearchResult>> {
        // SELECT ... WHERE created_at BETWEEN ? AND ?
        todo!()
    }

    /// 按来源类型搜索
    pub async fn search_by_source(
        &self,
        source_types: &[ConnectorType],
        limit: usize,
    ) -> Result<Vec<SearchResult>> {
        // SELECT ... WHERE source_type IN (...)
        todo!()
    }

    /// 组合过滤搜索
    pub async fn filtered_search(
        &self,
        query: Option<&str>,           // 可选关键词
        tags: Option<&[String]>,       // 可选标签
        date_range: Option<(DateTime<Utc>, DateTime<Utc>)>, // 可选时间范围
        source_types: Option<&[ConnectorType]>,             // 可选来源
        project: Option<&str>,         // 可选项目
        limit: usize,
    ) -> Result<Vec<SearchResult>> {
        // 所有条件 AND 组合
        // 至少需要一个条件（不允许无条件搜索）
        todo!()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TagMatchMode {
    Any,  // 任一标签匹配（OR）
    All,  // 所有标签匹配（AND）
}
```

#### 7.2.2 标签浏览

```
标签浏览模式（无需输入搜索词）：

1. 获取所有标签及计数
   GET /api/v1/tags
   → { "rust": 42, "音乐": 38, "编程": 25, "混音": 15 }

2. 点击标签 → 获取该标签下的所有条目
   GET /api/v1/entries?tags=rust&limit=20

3. 多标签组合
   GET /api/v1/entries?tags=rust,编程&match=all

4. 标签云（按频率排序，支持搜索过滤）
```

#### 7.2.3 时间线浏览

```
时间线模式（无需输入搜索词）：

1. 获取时间分布
   GET /api/v1/timeline?granularity=month
   → [{ "2024-01": 15 }, { "2024-02": 23 }, ...]

2. 按时间范围浏览
   GET /api/v1/entries?after=2024-01-01&before=2024-03-31

3. 最近更新
   GET /api/v1/entries?sort=updated_at&order=desc&limit=20
```

### 7.3 关键词搜索实现

**实现**：SQLite FTS5 或 Tantivy 倒排索引

```sql
-- SQLite FTS5 建表
CREATE VIRTUAL TABLE knowledge_fts USING fts5(
    id,
    title,
    content,
    tags,
    tokenize='unicode61'  -- 支持中文分词（需 ICU 扩展或 jieba tokenizer）
);

-- 搜索查询
SELECT id, title, rank
FROM knowledge_fts
WHERE knowledge_fts MATCH ?
ORDER BY rank
LIMIT ?;
```

**为什么考虑 Tantivy？**

- Tantivy 是 Rust 原生的全文搜索引擎，性能接近 Lucene
- SQLite FTS5 的中文分词支持较弱，需要额外 jieba 扩展
- 但 SQLite FTS5 开发成本低，Phase 2 先用 FTS5，Phase 3+ 考虑 Tantivy

### 7.4 语义搜索

**实现**：Qdrant 向量相似度搜索

```rust
/// 语义搜索流程
async fn semantic_search(
    query: &str,
    limit: usize,
    filter: Option<SearchFilter>,
    embedding_model: &dyn EmbeddingModel,
    vector_store: &dyn VectorStore,
) -> Result<Vec<SearchResult>> {
    // 1. 将查询文本转为向量
    let query_vector = embedding_model.embed_text(query).await?;

    // 2. 在 Qdrant 中搜索最相似的向量
    let qdrant_filter = filter.map(|f| build_qdrant_filter(&f));
    let results = vector_store
        .search("knowledge", &query_vector, limit, qdrant_filter)
        .await?;

    // 3. 加载完整的知识条目
    let entries = load_entries_from_results(&results).await?;

    // 4. 组装搜索结果
    Ok(entries
        .into_iter()
        .zip(results.into_iter())
        .map(|(entry, vr)| SearchResult {
            entry,
            relevance: vr.score,
            highlights: vec![],  // 语义搜索没有精确高亮
            related_entries: vec![],
            search_type: SearchType::Semantic,
            degradation_notice: None,
        })
        .collect())
}
```

### 7.5 混合搜索（RRF 融合）

**为什么需要混合搜索？**

- 关键词搜索擅长精确匹配（"Rust 所有权"），但不懂语义
- 语义搜索擅长概念匹配（"内存安全机制" ≈ "Rust 所有权"），但可能漏掉精确术语
- 混合搜索取两者之长

**Reciprocal Rank Fusion (RRF) 算法**：

```
RRF 公式：
score(d) = Σ 1 / (k + rank_i(d))

其中：
- d = 文档
- rank_i(d) = 文档 d 在第 i 个排序列表中的排名
- k = 常数（默认 60，源自原始论文）

示例：
关键词搜索排名：[A, B, C, D, E]
语义搜索排名：  [B, C, A, E, D]

RRF score(A) = 1/(60+1) + 1/(60+3) = 0.01639 + 0.01587 = 0.03226
RRF score(B) = 1/(60+2) + 1/(60+1) = 0.01613 + 0.01639 = 0.03252
RRF score(C) = 1/(60+3) + 1/(60+2) = 0.01587 + 0.01613 = 0.03200

最终排名：B > A > C
```

```rust
/// 混合搜索 —— RRF 融合关键词和语义搜索
/// ★ 降级感知：如果语义搜索不可用，退化为纯关键词搜索
pub async fn hybrid_search(
    query: &str,
    limit: usize,
    filter: Option<SearchFilter>,
    keyword_search: &dyn KeywordSearchable,
    semantic_search: &dyn SemanticSearchable,
    degradation: &DegradationManager,
    rrf_k: u32,
) -> Result<Vec<SearchResult>> {
    // 检查降级状态
    if degradation.is_embedding_degraded().await {
        // 降级模式：纯关键词搜索 + 降级提示
        let mut results = keyword_search.search(query, limit, filter.clone()).await?;
        for result in &mut results {
            result.degradation_notice = Some(DegradationNotice {
                reason: "Embedding model unavailable, using keyword search only".to_string(),
                affected_features: vec![
                    "semantic_search".to_string(),
                    "hybrid_search".to_string(),
                    "auto_relations".to_string(),
                ],
                since: degradation.degradation_since().await
                    .unwrap_or_else(|| Utc::now()),
            });
        }
        return Ok(results);
    }

    // 正常模式：并行执行关键词搜索和语义搜索
    let (keyword_results, semantic_results) = tokio::join!(
        keyword_search.search(query, limit * 2, filter.clone()),
        semantic_search.search(query, limit * 2, filter),
    );

    let keyword_results = keyword_results?;
    let semantic_results = match semantic_results {
        Ok(r) => r,
        Err(e) => {
            // 语义搜索失败 → 降级到纯关键词 + 标记
            degradation.report_embedding_failure(&e.to_string()).await;
            let mut results = keyword_results;
            for result in &mut results {
                result.degradation_notice = Some(DegradationNotice {
                    reason: format!("Semantic search failed: {}", e),
                    affected_features: vec!["semantic_search".to_string()],
                    since: Utc::now(),
                });
            }
            return Ok(results);
        }
    };

    // RRF 融合
    let mut rrf_scores: HashMap<String, f32> = HashMap::new();

    for (rank, result) in keyword_results.iter().enumerate() {
        let score = 1.0 / (rrf_k as f32 + rank as f32 + 1.0);
        *rrf_scores.entry(result.entry.id.clone()).or_insert(0.0) += score;
    }

    for (rank, result) in semantic_results.iter().enumerate() {
        let score = 1.0 / (rrf_k as f32 + rank as f32 + 1.0);
        *rrf_scores.entry(result.entry.id.clone()).or_insert(0.0) += score;
    }

    let mut ranked: Vec<_> = rrf_scores.into_iter().collect();
    ranked.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(Ordering::Equal));

    // 加载完整条目并返回
    let ids: Vec<&str> = ranked.iter().take(limit).map(|(id, _)| id.as_str()).collect();
    // ... 加载条目，组装结果
    todo!()
}
```

### 7.6 过滤与排序

```
搜索请求
  │
  ├──→ 过滤（在搜索引擎层面执行）
  │     ├── source_type: [Blog, Note]       ← 只搜博客和笔记
  │     ├── tags: ["rust", "programming"]    ← 标签过滤
  │     ├── date_range: [2024-01-01, ...]    ← 时间范围
  │     └── project: "open-mind"             ← 项目过滤
  │
  ├──→ 召回（搜索引擎返回候选集）
  │
  └──→ 排序（后处理加权排序）
        └──→ final_score = relevance × α + recency × β + importance × γ
              ├── relevance: 搜索引擎原始分
              ├── recency: 时间衰减函数
              └── importance: 手动权重（默认 1.0）或基于关联数
```

### 7.7 手动搜索查询语法

为了支持更灵活的手动搜索，设计统一的查询语法：

```
搜索查询语法：

1. 纯关键词：Rust所有权
   → FTS5 全文搜索

2. 标签过滤：tag:rust tag:编程
   → 只返回同时包含这两个标签的条目

3. 来源过滤：source:blog
   → 只搜索博客来源

4. 时间范围：after:2024-01-01 before:2024-06-30
   → 时间范围过滤

5. 项目过滤：project:open-mind
   → 只搜索特定项目

6. 组合：Rust所有权 tag:编程 source:blog after:2024-01-01
   → 关键词 + 标签 + 来源 + 时间 组合

7. 排序：sort:updated_at order:desc
   → 按更新时间倒序

所有语法都映射到底层 SQL 过滤条件，不依赖 AI。
```

---

## 8. 降级策略

### 8.1 降级管理器

降级管理器是 OpenMind 可靠性的核心组件，负责监控嵌入模型状态、触发降级、管理恢复。

```rust
use std::sync::Arc;
use tokio::sync::RwLock;

/// 降级管理器 —— 监控嵌入模型状态，协调降级和恢复
pub struct DegradationManager {
    /// 当前状态
    state: Arc<RwLock<DegradationState>>,

    /// 健康检查间隔
    check_interval: Duration,

    /// 连续失败阈值（触发降级）
    failure_threshold: u32,

    /// 补算队列（模型恢复后处理）
    catchup_queue: Arc<RwLock<Vec<String>>>,  // Pending 条目 ID 列表
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DegradationState {
    /// 嵌入模型状态
    pub embedding_status: ComponentStatus,

    /// 降级开始时间
    pub degraded_since: Option<DateTime<Utc>>,

    /// 连续失败计数
    pub consecutive_failures: u32,

    /// 最近一次成功嵌入时间
    pub last_success_at: Option<DateTime<Utc>>,

    /// 最近一次失败原因
    pub last_failure_reason: Option<String>,

    /// 下次健康检查时间
    pub next_health_check: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ComponentStatus {
    Healthy,
    Degraded,
    Down,
}

impl DegradationManager {
    /// 嵌入模型是否处于降级状态
    pub async fn is_embedding_degraded(&self) -> bool {
        let state = self.state.read().await;
        matches!(state.embedding_status, ComponentStatus::Degraded | ComponentStatus::Down)
    }

    /// 报告嵌入失败
    pub async fn report_embedding_failure(&self, reason: &str) {
        let mut state = self.state.write().await;
        state.consecutive_failures += 1;
        state.last_failure_reason = Some(reason.to_string());

        if state.consecutive_failures >= self.failure_threshold {
            let was_healthy = state.embedding_status == ComponentStatus::Healthy;
            state.embedding_status = ComponentStatus::Degraded;
            if state.degraded_since.is_none() {
                state.degraded_since = Some(Utc::now());
            }
            if was_healthy {
                tracing::warn!(
                    "Embedding model degraded after {} failures: {}",
                    state.consecutive_failures, reason
                );
            }
        }
    }

    /// 报告嵌入成功
    pub async fn report_embedding_success(&self) {
        let mut state = self.state.write().await;
        state.consecutive_failures = 0;
        state.last_success_at = Some(Utc::now());
        state.last_failure_reason = None;

        if state.embedding_status != ComponentStatus::Healthy {
            let was_degraded = state.embedding_status.clone();
            state.embedding_status = ComponentStatus::Healthy;
            state.degraded_since = None;
            tracing::info!(
                "Embedding model recovered from {:?}",
                was_degraded
            );
            // 触发补算
            self.trigger_catchup().await;
        }
    }

    /// 将条目加入补算队列
    pub async fn enqueue_for_catchup(&self, entry_id: String) {
        let mut queue = self.catchup_queue.write().await;
        if !queue.contains(&entry_id) {
            queue.push(entry_id);
        }
    }

    /// 获取当前降级原因
    pub async fn degradation_reason(&self) -> Option<String> {
        let state = self.state.read().await;
        state.last_failure_reason.clone()
    }

    /// 获取降级开始时间
    pub async fn degradation_since(&self) -> Option<DateTime<Utc>> {
        let state = self.state.read().await;
        state.degraded_since
    }

    /// 触发补算（模型恢复后调用）
    async fn trigger_catchup(&self) {
        let queue = self.catchup_queue.read().await;
        if !queue.is_empty() {
            tracing::info!(
                "Triggering catchup for {} pending entries",
                queue.len()
            );
            // 启动后台任务补算
            // BackgroundEmbedder::start(queue.clone())
        }
    }

    /// 定期健康检查（后台任务）
    pub async fn run_health_check(&self, model: &dyn EmbeddingModel) {
        loop {
            tokio::time::sleep(self.check_interval).await;

            let state = self.state.read().await;
            if state.embedding_status != ComponentStatus::Healthy {
                drop(state); // 释放读锁
                match model.health_check().await {
                    EmbeddingHealth::Healthy => {
                        self.report_embedding_success().await;
                    }
                    EmbeddingHealth::Degraded(reason) => {
                        tracing::warn!("Embedding model still degraded: {}", reason);
                    }
                    EmbeddingHealth::Unavailable(reason) => {
                        self.report_embedding_failure(&reason).await;
                    }
                }
            }
        }
    }

    /// 获取降级状态摘要（用于 API 响应）
    pub async fn status_summary(&self) -> DegradationSummary {
        let state = self.state.read().await;
        let queue_len = self.catchup_queue.read().await.len();
        DegradationSummary {
            embedding_status: state.embedding_status.clone(),
            degraded_since: state.degraded_since,
            consecutive_failures: state.consecutive_failures,
            last_failure_reason: state.last_failure_reason.clone(),
            pending_catchup_count: queue_len,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DegradationSummary {
    pub embedding_status: ComponentStatus,
    pub degraded_since: Option<DateTime<Utc>>,
    pub consecutive_failures: u32,
    pub last_failure_reason: Option<String>,
    pub pending_catchup_count: usize,
}
```

### 8.2 降级矩阵

**系统行为随嵌入模型状态变化的完整矩阵**：

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        降级行为矩阵                                      │
├───────────────────┬─────────────────┬──────────────────┬────────────────┤
│ 功能              │ 模型正常         │ 模型降级          │ 模型不可用     │
├───────────────────┼─────────────────┼──────────────────┼────────────────┤
│ 关键词搜索         │ ✅ 正常          │ ✅ 正常           │ ✅ 正常        │
│ 标签浏览           │ ✅ 正常          │ ✅ 正常           │ ✅ 正常        │
│ 时间线浏览         │ ✅ 正常          │ ✅ 正常           │ ✅ 正常        │
│ 过滤搜索           │ ✅ 正常          │ ✅ 正常           │ ✅ 正常        │
├───────────────────┼─────────────────┼──────────────────┼────────────────┤
│ 语义搜索           │ ✅ 正常          │ ⚠️ 降级提示       │ ❌ 返回降级提示 │
│                   │                 │ 返回部分结果      │ 建议用关键词   │
│ 混合搜索           │ ✅ 正常          │ ⚠️ 退化为关键词   │ ⚠️ 退化为关键词│
│                   │                 │ + 降级提示        │ + 降级提示     │
├───────────────────┼─────────────────┼──────────────────┼────────────────┤
│ 新内容摄入         │ ✅ 全流程        │ ⚠️ 关键词索引     │ ⚠️ 关键词索引  │
│                   │ 文本+向量+关联   │ 向量标记Pending   │ 向量标记Pending│
│ 自动关联发现       │ ✅ 正常          │ ❌ 暂停           │ ❌ 暂停        │
├───────────────────┼─────────────────┼──────────────────┼────────────────┤
│ 已有向量搜索       │ ✅ 正常          │ ✅ 正常           │ ✅ 正常        │
│ 手动关联           │ ✅ 正常          │ ✅ 正常           │ ✅ 正常        │
├───────────────────┼─────────────────┼──────────────────┼────────────────┤
│ API响应            │ 正常             │ degradation_     │ degradation_  │
│                   │                 │ notice 字段      │ notice 字段   │
│ health端点         │ all green       │ embedding:       │ embedding:    │
│                   │                 │ degraded         │ down          │
└───────────────────┴─────────────────┴──────────────────┴────────────────┘

关键原则：
★ 关键词搜索永远不受影响
★ 已有向量数据永远不受影响
★ 新内容在模型恢复后异步补算
★ 降级状态对调用方透明（响应中标注，不需要调用方适配）
```

### 8.3 补算机制（Background Embedder）

```rust
/// 后台嵌入补算器 —— 模型恢复后异步补算 Pending 条目
pub struct BackgroundEmbedder {
    model: Box<dyn EmbeddingModel>,
    store: Box<dyn KnowledgeStore>,
    vector_store: Box<dyn VectorStore>,
    degradation: Arc<DegradationManager>,

    /// 补算批大小
    batch_size: usize,

    /// 补算间隔（避免一次性打满模型 API）
    batch_interval: Duration,
}

impl BackgroundEmbedder {
    /// 启动补算循环（在模型恢复后由 DegradationManager 触发）
    pub async fn run(&self) {
        loop {
            // 1. 查询所有 Pending 条目
            let pending_ids = self.get_pending_entries().await;
            if pending_ids.is_empty() {
                break; // 补算完成
            }

            tracing::info!("Catchup: {} entries pending embedding", pending_ids.len());

            // 2. 分批补算
            for chunk in pending_ids.chunks(self.batch_size) {
                // 再次检查降级状态
                if self.degradation.is_embedding_degraded().await {
                    tracing::warn!("Catchup paused: embedding model degraded again");
                    return;
                }

                // 3. 加载条目内容
                let entries = self.load_entries(chunk).await;

                // 4. 批量嵌入
                let texts: Vec<&str> = entries.iter().map(|e| e.content.as_str()).collect();
                match self.model.embed_texts(&texts).await {
                    Ok(vectors) => {
                        // 5. 写入向量索引
                        for (entry, vector) in entries.iter().zip(vectors.iter()) {
                            self.vector_store
                                .upsert("knowledge", &entry.id, vector.clone(), serde_json::json!({}))
                                .await
                                .ok();

                            // 6. 更新 embedding_status → Embedded
                            self.update_embedding_status(&entry.id, EmbeddingStatus::Embedded).await;
                        }
                        // 7. 报告成功
                        self.degradation.report_embedding_success().await;
                    }
                    Err(e) => {
                        // 嵌入失败，暂停补算
                        self.degradation.report_embedding_failure(&e.to_string()).await;
                        tracing::error!("Catchup failed: {}", e);
                        return;
                    }
                }

                // 8. 批间等待（避免打满 API 限流）
                tokio::time::sleep(self.batch_interval).await;
            }
        }

        tracing::info!("Catchup completed: all pending entries embedded");
    }

    /// 查询 Pending 条目
    async fn get_pending_entries(&self) -> Vec<String> {
        // SELECT id FROM knowledge_entries
        // WHERE embedding_status = 'pending'
        // ORDER BY created_at ASC
        todo!()
    }

    /// 更新嵌入状态
    async fn update_embedding_status(&self, id: &str, status: EmbeddingStatus) {
        // UPDATE knowledge_entries SET embedding_status = ? WHERE id = ?
        todo!()
    }
}
```

### 8.4 降级状态流转

```
┌──────────────────────────────────────────────────────────────┐
│                    降级状态流转图                              │
│                                                              │
│  ┌─────────┐   连续失败 ≥ 3   ┌───────────┐                │
│  │ Healthy │───────────────→ │ Degraded  │                │
│  │         │                  │           │                │
│  │ 全功能   │                  │ 关键词可用  │                │
│  └────┬────┘                  │ 语义降级   │                │
│       │                       │ 新内容Pending│               │
│       │                       └─────┬─────┘                │
│       │                             │                      │
│       │ 健康检查成功                  │ 健康检查成功          │
│       │ (保持Healthy)                │ → 触发补算            │
│       │                             │                      │
│       │                       ┌─────▼─────┐                │
│       │                       │ Recovering │                │
│       │                       │           │                │
│       │                       │ 补算中     │                │
│       │                       │ 全功能恢复  │                │
│       │                       └─────┬─────┘                │
│       │                             │                      │
│       │ 补算完成                     │ 补算完成              │
│       │ (保持Healthy)               │                      │
│       │                             ▼                      │
│       │                       ┌─────────┐                 │
│       └───────────────────────│ Healthy │                 │
│                               └─────────┘                 │
│                                                              │
│  随时可退：任何阶段嵌入失败 → 回到 Degraded                    │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. Connector 实现规划

| Connector | 数据源 | 同步方式 | 优先级 | 说明 |
|-----------|--------|---------|--------|------|
| `BlogConnector` | 博客 (RSS/Webhook) | 定时轮询 + Webhook | **P0** | 个人博客是最核心的知识来源 |
| `VaultConnector` | OpenVault 文件 | 事件监听 + 定时扫描 | **P0** | 与 Vault 深度集成 |
| `BookmarkConnector` | 浏览器书签 | 导入 + 定时同步 | **P1** | 书签是重要知识线索 |
| `NoteConnector` | 备忘录 (各种格式) | 文件监听 | **P1** | 日记、想法、灵感 |
| `FileConnector` | 本地目录 | 文件监听 (notify) | **P2** | 通用文件摄入 |
| `WeChatConnector` | 微信收藏 | 导出解析 | **P3** | 需要手动导出 |
| `FeishuConnector` | 飞书文档 | API 同步 | **P3** | 需要 API 权限 |

### 9.1 BlogConnector 设计

```rust
/// 博客 Connector —— 支持 RSS + Webhook
pub struct BlogConnector {
    /// RSS 源地址
    rss_url: String,

    /// Webhook 密钥（可选）
    webhook_secret: Option<String>,

    /// 上次同步时间
    last_sync: Option<DateTime<Utc>>,

    /// HTTP 客户端
    client: reqwest::Client,
}

#[async_trait]
impl Connector for BlogConnector {
    fn name(&self) -> &str { "blog" }
    fn connector_type(&self) -> ConnectorType { ConnectorType::Blog }

    async fn connect(&mut self, config: &ConnectorConfig) -> Result<()> {
        // 1. 验证 RSS URL 可达
        // 2. 解析 RSS feed 结构
        // 3. 如果有 Webhook，注册回调
        Ok(())
    }

    async fn list_changes(&self, since: Option<DateTime<Utc>>) -> Result<Vec<ChangeEntry>> {
        // 1. 拉取 RSS feed
        // 2. 过滤 since 之后的条目
        // 3. 计算 content_hash
        // 4. 返回变更列表
        todo!()
    }

    async fn fetch_content(&self, entry: &ChangeEntry) -> Result<RawContent> {
        // 1. 根据 source_id 获取文章 URL
        // 2. 下载文章 HTML
        // 3. 提取正文（readability 算法）
        // 4. 处理图片附件
        // 5. 返回 RawContent
        todo!()
    }
}
```

### 9.2 VaultConnector 设计

```rust
/// OpenVault Connector —— 监听 Vault 文件变化
pub struct VaultConnector {
    /// Vault API 地址
    vault_url: String,

    /// Vault API Token
    token: String,

    /// 监听的目录前缀
    watch_prefix: Option<String>,

    /// HTTP 客户端
    client: reqwest::Client,
}

#[async_trait]
impl Connector for VaultConnector {
    fn name(&self) -> &str { "vault" }
    fn connector_type(&self) -> ConnectorType { ConnectorType::Vault }

    async fn connect(&mut self, config: &ConnectorConfig) -> Result<()> {
        // 1. 验证 Vault API 连通性
        // 2. 注册事件监听（如果 Vault 支持）
        // 3. 获取初始文件列表
        Ok(())
    }

    async fn list_changes(&self, since: Option<DateTime<Utc>>) -> Result<Vec<ChangeEntry>> {
        // 1. 调用 Vault API: GET /api/v1/files?since={since}
        // 2. 对比 content-hash
        // 3. 返回变更列表
        todo!()
    }

    async fn fetch_content(&self, entry: &ChangeEntry) -> Result<RawContent> {
        // 1. 根据 source_id 调用 Vault API 下载文件
        // 2. 如果是文本文件 → 直接提取内容
        // 3. 如果是大文件 → 上传到 StorageBackend → 存引用
        // 4. 返回 RawContent
        todo!()
    }
}
```

---

## 10. 同步机制详细设计

### 10.1 同步流程总览

```
┌──────────────────────────────────────────────────────────────┐
│                      同步引擎 (SyncEngine)                    │
│                                                              │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │Scheduler │───→│ SyncRunner   │───→│ IngestPipeline   │  │
│  │(Cron)    │    │              │    │                  │  │
│  │          │    │ 全量/增量    │    │ 解析→分块→嵌入    │  │
│  │ 定时触发  │    │ 变更检测     │    │ →索引→关联       │  │
│  │ 手动触发  │    │ 冲突处理     │    │ (降级感知)       │  │
│  └──────────┘    └──────────────┘    └──────────────────┘  │
│       │                  │                    │              │
│       │            ┌─────▼─────┐        ┌────▼─────┐      │
│       │            │SyncState  │        │EventBus  │      │
│       │            │Store      │        │(通知)    │      │
│       │            └───────────┘        └──────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### 10.2 首次同步（全量导入）

```
首次同步流程：
1. Connector.connect() → 建立连接
2. Connector.list_changes(None) → 获取全部条目
3. 逐条处理：
   a. 计算 content-hash
   b. 检查是否已存在（source_id + content_hash）
   c. 不存在 → fetch_content → 摄入管道
   d. 已存在 → 跳过
4. 更新 SyncState → 记录进度
5. 如果中断 → 断点续传（从 SyncState.last_sync_at 继续）
```

**断点续传设计**：

```rust
/// 同步进度追踪（用于断点续传）
pub struct SyncProgress {
    /// Connector 名称
    pub connector_name: String,

    /// 同步批次 ID
    pub batch_id: String,

    /// 总条目数
    pub total: usize,

    /// 已处理条目数
    pub processed: usize,

    /// 失败条目列表
    pub failed: Vec<(String, String)>,

    /// 当前处理的 source_id（断点）
    pub checkpoint: Option<String>,

    /// 开始时间
    pub started_at: DateTime<Utc>,
}
```

### 10.3 增量同步

```
增量同步流程：
1. 读取 SyncState.last_sync_at
2. Connector.list_changes(since=last_sync_at) → 只获取变更
3. 对每个 ChangeEntry：
   a. 计算 content-hash
   b. hash 相同 → 跳过（skipped++）
   c. hash 不同 → 重新索引
   d. change_type=Deleted → 标记 archived
4. 更新 SyncState
```

### 10.4 变更检测

```
变更检测逻辑：

源内容 → 计算 content_hash
              │
              ├─→ 数据库中无此 source_id ──→ 新增 (Created)
              │
              ├─→ source_id 存在，hash 相同 ──→ 跳过 (Unchanged)
              │
              └─→ source_id 存在，hash 不同 ──→ 更新 (Updated)
                    │
                    └──→ 重新走摄入管道
                         │
                         ├─→ 文本变了 → 重新分块 + 嵌入 + 索引
                         ├─→ 标签变了 → 更新标签索引
                         └─→ 元数据变了 → 只更新 metadata
```

### 10.5 删除处理

**核心原则：知识关联不能丢！**

```
源内容被删除：
  │
  ├─→ 标记 status = Archived（不真删）
  │
  ├─→ 保留所有关联（KnowledgeRelation）
  │     原因：关联本身就是知识，"A 引用了 B"这个事实不会因为 B 被删而失效
  │
  ├─→ 保留 content 和 embedding
  │     原因：搜索时可能还需要匹配到归档内容
  │
  └─→ 从全文索引中移除（可选，节省空间）
        但向量索引保留（语义搜索可能还需要）
```

### 10.6 冲突处理

**场景**：多数据源包含相同内容（博客 + 书签收藏了同一篇文章）

```
冲突检测：content-hash 相同，但 source_id 不同

处理策略：
1. 合并 metadata
   - 保留所有 source_id（作为数组）
   - tags 合并（取并集）
   - 其他 metadata 以最新的为准

2. 保留最新 content
   - 比较 updated_at，保留最新的
   - 如果内容不同但 hash 相同（理论上不可能），以最新的为准

3. 不创建重复条目
   - 一个 content_hash 只对应一个 KnowledgeEntry
   - 但 metadata.sources 记录所有来源
```

### 10.7 博客更新检测

```
博客更新检测的三种机制（按优先级）：

1. Webhook（实时）
   博客发布/更新 → 推送通知到 OpenMind
   优点：实时
   缺点：需要博客支持 Webhook

2. RSS pubDate 变化（准实时）
   定时检查 RSS feed → 对比 pubDate
   优点：通用性强
   缺点：有延迟（取决于轮询频率）

3. 定时全量对比（兜底）
   定时重新拉取所有文章 → 对比 content-hash
   优点：最可靠
   缺点：开销大

推荐配置：
- Webhook 可用 → 使用 Webhook + 每日全量检查（兜底）
- Webhook 不可用 → 每 15 分钟 RSS 检查 + 每日全量检查
```

---

## 11. 大文件处理流程

### 11.1 处理流程图

```
大文件导入流程（图片/音频/视频）：

┌──────────────┐
│ 大文件输入    │
│ (图片/音频/   │
│  视频/PDF)   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐     ┌──────────────────┐
│ 1. 计算 content-  │────→│ 已索引？          │
│    hash (SHA-256) │     │ 比对数据库       │
└──────────────────┘     └──────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │ 已存在                 │ 不存在
                    ▼                       ▼
              ┌──────────┐        ┌──────────────────┐
              │ 跳过/更新 │        │ 2. 上传到         │
              └──────────┘        │ StorageBackend    │
                                  │ (Vault/S3) → URL  │
                                  └────────┬─────────┘
                                           │
                                           ▼
                                  ┌──────────────────┐
                                  │ 3. 提取元数据     │
                                  │ 格式/大小/时长    │
                                  └────────┬─────────┘
                                           │
                                           ▼
                                  ┌──────────────────┐
                                  │ 4. 提取文本内容   │
                                  │ 图片→OCR+CLIP    │
                                  │ 音频→Whisper     │
                                  │ 视频→关键帧+转录  │
                                  └────────┬─────────┘
                                           │
                                           ▼
                                  ┌──────────────────┐
                                  │ 5. 生成嵌入向量   │
                                  │ 文本嵌入 /       │
                                  │ CLIP图像嵌入     │
                                  │ ★可降级→Pending  │
                                  └────────┬─────────┘
                                           │
                                           ▼
                                  ┌──────────────────┐
                                  │ 6. 存储           │
                                  │ KnowledgeEntry    │
                                  │ content=提取文本  │
                                  │ file_ref=URL      │
                                  └────────┬─────────┘
                                           │
                                           ▼
                                  ┌──────────────────┐
                                  │ 7. 入索引         │
                                  │ 文本→FTS5         │
                                  │ 向量→Qdrant(可选) │
                                  │ 原始文件→留在     │
                                  │ StorageBackend    │
                                  └──────────────────┘
```

### 11.2 各文件类型处理详解

| 类型 | 文本提取 | 嵌入方式 | 缩略图 | 降级行为 |
|------|---------|---------|--------|---------|
| 图片 (jpg/png/webp) | OCR (Tesseract) + 视觉描述 (CLIP) | CLIP 图像向量 | 压缩缩略图 | 只做 OCR 文本索引，跳过 CLIP 向量 |
| 音频 (mp3/wav/flac) | Whisper 转录 | 转录文本的文本嵌入 | 无 | 只做转录文本索引，跳过嵌入 |
| 视频 (mp4/mkv) | 关键帧提取 + 每帧描述 + 音轨 Whisper 转录 | 关键帧 CLIP 向量 + 转录文本嵌入 | 首帧缩略图 | 只做转录文本索引 |
| PDF | pdf-extract 文本提取 | 文本嵌入 | 首页渲染图 | 只做文本索引，跳过嵌入 |

### 11.3 文本与引用的关系

```
KnowledgeEntry
├── id: "entry-001"
├── title: "混响参数对比截图"
├── content: "这张图展示了不同混响参数的对比，包括房间大小、衰减时间、预延迟..."
│            ↑ 这是 OCR/CLIP 提取的文本描述，可搜索、可嵌入
├── content_hash: "sha256:abc123..."
├── embedding_id: Some("vec-001")     ← 模型正常时
├── embedding_status: Embedded        ← 或 Pending（模型不可用时）
├── file_references: [
│     {
│       id: "ref-001",
│       storage_backend: "vault",
│       url: "opendaw-vault://files/images/reverb-compare.png",
│       content_hash: "sha256:def456...",
│       media_type: "image/png",
│       extracted_text: "房间大小: 0.8, 衰减时间: 2.5s, ...",
│       thumbnail_url: "opendaw-vault://files/thumbnails/reverb-compare-thumb.jpg",
│       size_bytes: 245760,
│     }
│   ]
└── status: Active

★ 关键：content 字段存的是提取后的文本（可搜索），原始文件通过 file_references 引用
★ 搜索时：搜的是 content + extracted_text，不是图片像素
★ 展示时：用 file_references.url 获取原始文件
★ embedding_status=Pending 时：关键词搜索正常，语义搜索搜不到此条目（直到补算完成）
```

---

## 12. API 设计（完整）

### 12.1 API 路由表

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| `POST` | `/api/v1/search` | 搜索 | `SearchRequest` | `SearchResponse` |
| `POST` | `/api/v1/ingest` | 摄入内容 | `IngestRequest` | `IngestResponse` |
| `GET` | `/api/v1/entry/:id` | 获取知识条目 | - | `KnowledgeEntry` |
| `GET` | `/api/v1/entry/:id/related` | 获取关联知识 | - | `Vec<RelatedEntry>` |
| `POST` | `/api/v1/entry/:id/relate` | 创建关联 | `RelateRequest` | `()` |
| `DELETE` | `/api/v1/entry/:id` | 标记删除(archived) | - | `()` |
| `POST` | `/api/v1/sync/:connector` | 触发同步 | `SyncRequest` | `SyncResult` |
| `GET` | `/api/v1/connectors` | 列出已注册 Connector | - | `Vec<ConnectorInfo>` |
| `GET` | `/api/v1/stats` | 知识库统计 | - | `KnowledgeStats` |
| `GET` | `/api/v1/tags` | 标签列表(含计数) | - | `Vec<TagCount>` |
| `GET` | `/api/v1/timeline` | 时间线分布 | - | `Vec<TimeBucket>` |
| `GET` | `/api/v1/health` | 健康检查 | - | `HealthResponse` |
| `POST` | `/api/v1/admin/reindex` | 触发重索引 | `ReindexRequest` | `ReindexResponse` |
| `GET` | `/.well-known/agent.json` | Agent 发现 | - | `AgentProfile` |

### 12.2 请求/响应结构体

```rust
// ---- 搜索 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct SearchRequest {
    /// 搜索查询
    pub query: String,

    /// 搜索类型
    #[serde(default = "default_search_type")]
    pub search_type: SearchType,

    /// 返回数量限制
    #[serde(default = "default_limit")]
    pub limit: usize,

    /// 过滤条件
    #[serde(default)]
    pub filter: Option<SearchFilter>,
}

fn default_search_type() -> SearchType { SearchType::Hybrid }
fn default_limit() -> usize { 10 }

#[derive(Debug, Serialize, Deserialize)]
pub struct SearchResponse {
    pub results: Vec<SearchResult>,
    pub total: usize,
    pub query: String,
    pub search_type: SearchType,
    pub took_ms: u64,

    /// 降级提示（整个搜索的降级状态）
    pub degradation: Option<DegradationSummary>,
}

// ---- 摄入 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct IngestRequest {
    /// 数据源类型
    pub source_type: ConnectorType,

    /// 原始内容
    pub content: RawContent,

    /// 是否立即处理（否则入队列异步处理）
    #[serde(default)]
    pub immediate: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct IngestResponse {
    pub entry_id: String,
    pub status: IngestStatus,
    pub message: String,

    /// 是否因模型降级跳过了向量化
    pub embedding_skipped: bool,
}

#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
pub enum IngestStatus {
    Accepted,     // 已入队列
    Completed,    // 已完成（含向量化）
    CompletedPartial, // 部分完成（关键词索引完成，向量化跳过/Pending）
    Duplicate,    // 重复内容（已跳过）
    Updated,      // 已更新
    Failed,       // 失败
}

// ---- 关联 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct RelateRequest {
    pub to_id: String,
    pub relation_type: RelationType,
    pub weight: Option<f32>,
}

// ---- 同步 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct SyncRequest {
    /// 全量同步还是增量
    #[serde(default)]
    pub full: bool,
}

// ---- 标签 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct TagCount {
    pub tag: String,
    pub count: usize,
}

// ---- 时间线 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct TimeBucket {
    pub period: String,  // "2024-01"
    pub count: usize,
}

// ---- 健康检查 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,           // "ok" / "degraded" / "error"
    pub version: String,
    pub uptime_secs: u64,
    pub components: ComponentHealth,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ComponentHealth {
    pub database: String,         // "ok" / "error"
    pub vector_store: String,     // "ok" / "error" / "degraded"
    pub embedding_model: String,  // "ok" / "error" / "degraded"
    pub keyword_search: String,   // "ok" (永远 ok，不依赖外部)
}

// ---- 重索引 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct ReindexRequest {
    /// 只重索引未向量化的条目
    #[serde(default)]
    pub pending_only: bool,

    /// 强制全部重索引
    #[serde(default)]
    pub force_all: bool,

    /// 新模型名称（可选，切换模型时用）
    pub model_name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ReindexResponse {
    pub job_id: String,
    pub total_entries: usize,
    pub status: String,
}

// ---- Agent 发现 ----

#[derive(Debug, Serialize, Deserialize)]
pub struct AgentProfile {
    pub name: String,
    pub version: String,
    pub description: String,
    pub url: String,
    pub capabilities: Vec<AgentCapability>,
    pub actions: Vec<AgentAction>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AgentCapability {
    pub name: String,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AgentAction {
    pub name: String,
    pub description: String,
    pub input_schema: serde_json::Value,
    pub output_schema: serde_json::Value,
    pub http_method: String,
    pub path: String,
}
```

### 12.3 Agent.json 示例

```json
{
  "name": "OpenMind",
  "version": "0.1.0",
  "description": "AI-native personal knowledge engine - knowledge node in Agent ecosystem",
  "url": "http://opendaw:8080",
  "capabilities": [
    {
      "name": "search",
      "description": "Search knowledge base with keyword, semantic, or hybrid search. Keyword search always available; semantic search requires embedding model."
    },
    {
      "name": "ingest",
      "description": "Ingest and index new content into knowledge base. Graceful degradation: if embedding model unavailable, keyword indexing still works."
    },
    {
      "name": "relate",
      "description": "Create and traverse knowledge relations"
    },
    {
      "name": "sync",
      "description": "Sync content from external data sources"
    }
  ],
  "actions": [
    {
      "name": "search",
      "description": "Search the knowledge base",
      "input_schema": {
        "type": "object",
        "properties": {
          "query": { "type": "string", "description": "Search query" },
          "search_type": { "type": "string", "enum": ["keyword", "semantic", "hybrid"] },
          "limit": { "type": "integer", "default": 10 }
        },
        "required": ["query"]
      },
      "output_schema": {
        "type": "object",
        "properties": {
          "results": { "type": "array" },
          "total": { "type": "integer" },
          "took_ms": { "type": "integer" },
          "degradation": { "type": "object", "description": "Present if search is degraded" }
        }
      },
      "http_method": "POST",
      "path": "/api/v1/search"
    },
    {
      "name": "ingest",
      "description": "Ingest content into knowledge base",
      "input_schema": {
        "type": "object",
        "properties": {
          "source_type": { "type": "string" },
          "content": { "type": "object" }
        },
        "required": ["source_type", "content"]
      },
      "output_schema": {
        "type": "object",
        "properties": {
          "entry_id": { "type": "string" },
          "status": { "type": "string" },
          "embedding_skipped": { "type": "boolean" }
        }
      },
      "http_method": "POST",
      "path": "/api/v1/ingest"
    },
    {
      "name": "get_related",
      "description": "Get related knowledge entries",
      "input_schema": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "depth": { "type": "integer", "default": 1 }
        },
        "required": ["id"]
      },
      "output_schema": {
        "type": "object",
        "properties": {
          "related_entries": { "type": "array" }
        }
      },
      "http_method": "GET",
      "path": "/api/v1/entry/{id}/related"
    }
  ]
}
```

---

## 13. 服务发现架构（两级发现）

### 13.1 两级发现概览

```
┌─────────────────────────────────────────────────────────────────┐
│                      两级服务发现                                 │
│                                                                 │
│  一级发现（去中心化，永远可用）                                    │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ 每个 Agent 节点自带 /.well-known/agent.json          │       │
│  │ Agent 直接请求节点的 agent.json                      │       │
│  │ 这是权威源，永远可用                                  │       │
│  │ 类比：DNS 根服务器                                    │       │
│  └─────────────────────────────────────────────────────┘       │
│                           │                                     │
│                           │ 聚合                                │
│                           ▼                                     │
│  二级发现（中心化，方便但不必须）                                  │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ OpenLink 聚合所有节点的 agent.json                   │       │
│  │ → /.well-known/ecosystem.json                       │       │
│  │ Agent 一站式发现所有节点                              │       │
│  │ 类比：DNS 递归解析 (8.8.8.8)                        │       │
│  │                                                     │       │
│  │ ★ Link 挂了？退回一级发现，生态不崩溃 ★               │       │
│  └─────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### 13.2 一级发现详解

```rust
/// 一级发现：直接请求节点
async fn discover_node(node_url: &str) -> Result<AgentProfile> {
    let url = format!("{}/.well-known/agent.json", node_url);
    let response = reqwest::get(&url).await?;
    let profile: AgentProfile = response.json().await?;
    Ok(profile)
}

/// Agent 发现流程（一级）
async fn find_capability(capability: &str, known_nodes: &[String]) -> Result<Vec<AgentProfile>> {
    let mut found = Vec::new();
    for node_url in known_nodes {
        if let Ok(profile) = discover_node(node_url).await {
            if profile.capabilities.iter().any(|c| c.name == capability) {
                found.push(profile);
            }
        }
    }
    Ok(found)
}
```

**一级发现的特点**：

- **权威源**：每个节点自己维护自己的 agent.json，最准确
- **永远可用**：不依赖任何第三方服务
- **缺点**：需要知道节点地址（硬编码或配置）

### 13.3 二级发现详解

```json
// OpenLink: /.well-known/ecosystem.json
{
  "name": "OpenDaw Ecosystem",
  "version": "1.0.0",
  "nodes": [
    {
      "name": "OpenMind",
      "url": "http://opendaw:8080",
      "agent_json": "http://opendaw:8080/.well-known/agent.json",
      "last_seen": "2025-06-01T10:00:00Z",
      "status": "healthy"
    },
    {
      "name": "OpenVault",
      "url": "http://opendaw:8081",
      "agent_json": "http://opendaw:8081/.well-known/agent.json",
      "last_seen": "2025-06-01T10:00:00Z",
      "status": "healthy"
    },
    {
      "name": "OpenDAW",
      "url": "http://opendaw:8082",
      "agent_json": "http://opendaw:8082/.well-known/agent.json",
      "last_seen": "2025-06-01T09:55:00Z",
      "status": "healthy"
    }
  ]
}
```

**二级发现的特点**：

- **方便**：一个请求发现所有节点
- **不必须**：Link 挂了不影响系统运行
- **聚合**：Link 定期抓取各节点的 agent.json

### 13.4 为什么不用区块链

| 问题 | 区块链方案 | 我们的方案 | 为什么不选区块链 |
|------|-----------|-----------|----------------|
| 节点发现 | 链上注册 | agent.json + Link | 5 个节点不需要去信任机制 |
| 身份验证 | 链上身份 | TLS + API Token | 都是自己的项目，信任问题不存在 |
| 数据不可篡改 | 链上存储 | SQLite + 备份 | 知识引擎需要随时修改，不可篡改是负担 |
| 共识 | PoS/PoW | 无需共识 | 单人生态，不需要共识 |

**未来扩展方向**（当节点 > 50 时考虑）：

- **DHT（分布式哈希表）**：Kademlia 协议，去中心化的节点发现
- **Gossip 协议**：节点间状态传播，最终一致性
- **但不是现在**：5 个节点用 agent.json + Link 足够了，过早引入复杂度是浪费

### 13.5 Agent 本地缓存策略

```rust
/// Agent 发现缓存
pub struct DiscoveryCache {
    /// 缓存条目
    entries: HashMap<String, CacheEntry>,

    /// TTL（默认 1 小时）
    ttl: Duration,

    /// 已知节点列表（硬编码 + 动态发现）
    known_nodes: Vec<String>,
}

struct CacheEntry {
    profile: AgentProfile,
    cached_at: DateTime<Utc>,
    source: CacheSource,
}

enum CacheSource {
    Primary,   // 从节点直接获取
    Secondary, // 从 Link 获取
    Fallback,  // 从本地缓存获取（发现失败时）
}

impl DiscoveryCache {
    /// 获取节点信息
    async fn get(&mut self, node_name: &str) -> Result<AgentProfile> {
        // 1. 检查缓存是否有效
        if let Some(entry) = self.entries.get(node_name) {
            if entry.cached_at + self.ttl > Utc::now() {
                return Ok(entry.profile.clone());
            }
        }

        // 2. 尝试一级发现
        if let Ok(profile) = self.discover_primary(node_name).await {
            self.entries.insert(
                node_name.to_string(),
                CacheEntry {
                    profile: profile.clone(),
                    cached_at: Utc::now(),
                    source: CacheSource::Primary,
                },
            );
            return Ok(profile);
        }

        // 3. 尝试二级发现（Link）
        if let Ok(profile) = self.discover_secondary(node_name).await {
            self.entries.insert(
                node_name.to_string(),
                CacheEntry {
                    profile: profile.clone(),
                    cached_at: Utc::now(),
                    source: CacheSource::Secondary,
                },
            );
            return Ok(profile);
        }

        // 4. 使用过期缓存（总比没有好）
        if let Some(entry) = self.entries.get(node_name) {
            return Ok(entry.profile.clone());
        }

        Err(anyhow::anyhow!("Node {} not found", node_name))
    }
}
```

---

## 14. Roadmap

> **注意**：本蓝图侧重 **WHY**（为什么这样设计）和 **HOW**（怎么实现）的设计决策。  
> 详细的 Phase 划分、执行计划和任务清单请参考：[`./项目/OpenMind/规划/roadmap.md`](../../项目/OpenMind/规划/roadmap.md)

### 14.1 设计决策与 Roadmap 对应

| Roadmap Phase | 蓝图设计决策 |
|---------------|-------------|
| **Phase 1: 项目骨架+数据模型+Connector trait** | §4 核心 trait 设计、§5 数据模型（含 EmbeddingStatus 字段）、§3 架构三层分离 |
| **Phase 2: 文本摄入+关键词搜索+嵌入模型集成** | §6 摄入管道、§7.2 手动搜索（基础权利）、§7.3 关键词搜索、§8 降级策略基础 |
| **Phase 3: 语义搜索+RAG查询+知识图谱基础** | §7.4 语义搜索、§7.5 混合搜索（RRF 融合）、§8.3 补算机制、§6.6 关联器 |
| **Phase 4: Connector实现** | §9 Connector 规划、§10 同步机制 |
| **Phase 5: Agent Action Protocol** | §12.3 agent.json、§13 服务发现 |
| **Phase 6: Web管理界面+同步调度** | §7.2 标签浏览/时间线、§10.7 博客更新检测、§13 部署架构 |
| **Phase 7: 增量同步+变更检测+删除处理** | §10.3-10.6 增量同步/变更检测/删除/冲突 |

### 14.2 降级策略的实现时机

降级不是一个独立的 Phase，而是贯穿始终的设计约束：

| Phase | 降级相关实现 |
|-------|------------|
| Phase 2 | EmbeddingStatus 字段、DegradationManager 骨架、关键词搜索永远可用 |
| Phase 3 | DegradationManager 完整实现、BackgroundEmbedder 补算、hybrid_search 降级路径 |
| Phase 4+ | 每个新功能都要考虑降级行为 |

---

## 15. 与其他项目的关系

### 15.1 关系总览

```
                    ┌──────────────┐
                    │   OpenLink   │ ← 发现节点
                    └──────┬───────┘
                           │ Agent 发现
                           │ Action Protocol
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │  OpenMind   │◄────────────►│  OpenVault  │ │  OpenDAW    │
    │  知识节点    │   文件引用    │  存储节点    │ │  音乐节点    │
    └──────┬──────┘   大文件存储   └─────────────┘ └─────────────┘
           │                                               │
           │              ┌─────────────────┐             │
           └─────────────►│  其他 Agent 节点  │◄────────────┘
                          │  (未来扩展)       │  混音经验回写
                          └─────────────────┘
```

### 15.2 详细交互

| 交互方向 | 交互内容 | 协议/接口 |
|---------|---------|----------|
| OpenMind → OpenVault | 大文件上传（图片/音频/视频） | StorageBackend trait (VaultStorageBackend) |
| OpenMind → OpenVault | 文件变更监听 | VaultConnector (Vault API) |
| OpenMind → OpenLink | 注册 agent.json | HTTP PUT /api/v1/nodes |
| OpenMind → OpenLink | 心跳/状态上报 | HTTP POST /api/v1/nodes/:id/heartbeat |
| OpenDAW → OpenMind | 搜索混音知识 | POST /api/v1/search |
| OpenMind → OpenDAW | 混音经验知识返回 | SearchResponse |
| OpenDAW → OpenMind | 混音经验回写（新知识） | POST /api/v1/ingest |
| OpenLink → OpenMind | 发布内容入库 | POST /api/v1/ingest |
| OpenMind → OpenMind | 跨节点知识搜索（未来） | P2P gRPC |

### 15.3 典型协作场景

**场景 1：混音时查找知识**

```
1. OpenDAW Agent 在混音过程中需要了解压缩器参数
2. OpenDAW → OpenMind: POST /api/v1/search { query: "压缩器参数设置", type: "hybrid" }
3. OpenMind 返回：之前写的博客"压缩器攻击时间设置心得" + 相关笔记
4. OpenDAW 在侧边栏展示搜索结果
5. 用户点击 → 打开知识条目详情
```

**场景 2：Vault 新文件自动入库**

```
1. 用户在 Vault 上传了一个 PDF 教程
2. OpenMind VaultConnector 检测到新文件（定时扫描或事件通知）
3. OpenMind 下载 PDF → 提取文本 → 分块 → 嵌入 → 索引
4. 下次搜索就能找到这个 PDF 的内容
5. PDF 原文件仍在 Vault，OpenMind 只存引用
```

**场景 3：DAW 经验回写**

```
1. 用户在 OpenDAW 中完成了一次混音，积累了一些经验
2. OpenDAW → OpenMind: POST /api/v1/ingest {
     source_type: "Note",
     content: { title: "2025-06 混音经验", content: "这次混音发现..." }
   }
3. OpenMind 摄入并索引
4. 下次搜索相关话题时能找到这条经验
```

**场景 4：嵌入模型宕机时搜索知识**

```
1. OpenAI API 突然不可用（限流/宕机/网络问题）
2. DegradationManager 检测到连续失败 → 进入 Degraded 状态
3. OpenDAW → OpenMind: POST /api/v1/search { query: "压缩器", type: "hybrid" }
4. OpenMind 自动降级到纯关键词搜索，返回结果 + degradation 提示
5. 关键词搜索结果正常可用，只是少了语义匹配
6. 期间新摄入的内容 embedding_status = Pending
7. OpenAI API 恢复 → DegradationManager 触发补算 → 所有 Pending 条目异步向量化
8. 搜索结果回归完整
```

---

## 16. 关键技术选型

### 16.1 选型总表

| 组件 | 选型 | 备选 | 选择理由 |
|------|------|------|---------|
| **后端语言** | Rust | Go, Python | 与生态其他项目一致；性能；类型安全 |
| **Web 框架** | Axum | Actix-web, Warp | 生态主流；Tower 中间件；与 tokio 深度集成 |
| **向量数据库** | Qdrant | Milvus, Weaviate, Chroma | Rust 原生；性能好；支持过滤；轻量部署 |
| **全文搜索** | SQLite FTS5 (Phase 2) → Tantivy (Phase 3+) | Meilisearch, Elasticsearch | FTS5 起步快；Tantivy 是 Rust 原生 Lucene 替代 |
| **嵌入模型** | OpenAI text-embedding-3-small | BGE-M3, Cohere | 质量好；API 简单；未来可切本地 |
| **知识图谱** | SQLite 关系表 (Phase 3) → Neo4j/AGE (未来) | NetworkX, JanusGraph | 初期简单够用；大了再换 |
| **数据库** | SQLite (单机) | PostgreSQL | 单机够用；零配置；与 Rust 集成好 |
| **异步运行时** | Tokio | async-std | Axum 默认；生态最全 |
| **序列化** | Serde | —— | Rust 标配 |
| **配置** | TOML (config crate) | YAML, JSON | 人类可读；Rust 社区偏好 |
| **错误处理** | anyhow + thiserror | failure | anyhow 用于应用，thiserror 用于库 |

### 16.2 关键依赖

```toml
[dependencies]
# Web 框架
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace"] }

# 数据库
sqlx = { version = "0.7", features = ["runtime-tokio", "sqlite"] }

# 向量存储
qdrant-client = "1.7"

# 序列化
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# 异步 trait
async-trait = "0.1"

# 时间
chrono = { version = "0.4", features = ["serde"] }

# UUID
uuid = { version = "1", features = ["v7", "serde"] }

# HTTP 客户端
reqwest = { version = "0.12", features = ["json"] }

# 配置
config = "0.14"

# 错误处理
anyhow = "1"
thiserror = "1"

# 日志
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# 哈希
sha2 = "0.10"

# RSS 解析
feed-rs = "1"

# HTML 解析
scraper = "0.19"

# 文件监听
notify = "6"
```

---

## 17. 风险与应对

### 17.1 风险清单

| # | 风险 | 影响 | 概率 | 应对策略 |
|---|------|------|------|---------|
| 1 | **嵌入模型不可用** | 中 | **高** | ★ **§8 降级策略全覆盖**：自动降级到关键词搜索；新内容标记 Pending；模型恢复后自动补算 |
| 2 | **嵌入模型切换 → 向量全量重算** | 高 | 中 | 设计 reindex 命令，后台异步重算，支持进度追踪和取消 |
| 3 | **Qdrant 数据丢失** | 高 | 低 | 定期备份 + WAL 日志；与 Vault 联动做 3-2-1 备份；Qdrant 自带快照功能 |
| 4 | **同步延迟 → 数据不一致** | 中 | 高 | 最终一致性模型；同步完成通知；搜索结果标注"索引时间" |
| 5 | **大量导入 → OOM** | 高 | 中 | 流式处理，分批摄入；内存限制（每批 100 条）；背压机制 |
| 6 | **嵌入 API 限流** | 中 | **高** | ★ **§8 降级策略**：限流 → Degraded → 关键词搜索兜底；批间等待；本地缓存；本地模型 fallback |
| 7 | **中文分词质量差** | 中 | 中 | Phase 2 用 FTS5（jieba 扩展）；Phase 3+ 迁移 Tantivy（内置中文分词） |
| 8 | **关联发现噪声大** | 低 | 高 | 相似度阈值可调（默认 0.7）；支持人工审核关联；权重衰减 |
| 9 | **SQLite 并发写入瓶颈** | 中 | 低 | WAL 模式；写入队列；未来迁移 PostgreSQL |
| 10 | **降级补算打满 API** | 中 | 中 | 补算批间等待；限速配置；分优先级补算（最新优先） |

### 17.2 关键应对方案详解

#### 风险 1：嵌入模型不可用（最高频风险）

> 完整方案见 **§8 降级策略**

**核心机制**：

```
1. DegradationManager 监控嵌入模型健康状态
   - 每次嵌入调用失败 → 计数++
   - 连续失败 ≥ 3 → 进入 Degraded 状态
   - 定期健康检查（默认 30 秒）

2. 降级状态下的系统行为
   - 搜索：关键词正常 + 语义降级提示 + 混合退化为关键词
   - 摄入：关键词索引正常 + 向量标记 Pending + 自动关联暂停
   - 已有向量数据：完全不受影响
   - API 响应：degradation_notice 字段透明标注

3. 模型恢复后的行为
   - DegradationManager 检测到模型恢复
   - 自动触发 BackgroundEmbedder 补算
   - 逐批处理 Pending 条目
   - 补算过程中再次失败 → 暂停，等待下次恢复
   - 补算完成 → 回归 Healthy 状态
```

#### 风险 2：嵌入模型切换

```
应对：reindex 命令

流程：
1. 新建 Qdrant collection（新维度）
2. 分批读取所有 KnowledgeEntry
3. 用新模型重新嵌入
4. 写入新 collection
5. 原子切换：旧 collection → 新 collection
6. 删除旧 collection

特性：
- 后台异步执行，不阻塞服务
- 进度追踪（已处理/总数/预计时间）
- 可暂停/恢复
- 失败可回滚（旧 collection 保留直到切换完成）
```

#### 风险 3：Qdrant 数据丢失

```
应对：多级备份

1. Qdrant 内置快照
   - 每日自动快照：POST /collections/{name}/snapshots
   - 快照存储在 Vault（联动备份）

2. WAL 日志
   - Qdrant 默认启用 WAL
   - 崩溃后自动恢复

3. 3-2-1 备份（与 Vault 联动）
   - 3 份数据：本地 + Vault + 远程
   - 2 种介质：SSD + 对象存储
   - 1 份离线

4. 恢复流程
   - 从快照恢复 Qdrant collection
   - 从 SQLite 恢复元数据
   - 重新同步 Connector（增量）
```

#### 风险 5：大量导入 OOM

```
应对：流式处理 + 背压

1. 摄入队列
   - 请求入队列，立即返回 Accepted
   - 后台 Worker 逐批处理
   - 批量大小可配置（默认 100 条）

2. 内存限制
   - 单次最多加载 N 条原始内容到内存
   - 大文件：流式下载，不全部加载到内存
   - 嵌入：批量调用，但控制并发数

3. 背压机制
   - 队列满 → 返回 503 Service Unavailable
   - Worker 慢 → 增加延迟通知

4. 断点续传
   - 每批处理完更新 SyncProgress
   - 中断后从断点继续
```

#### 风险 10：降级补算打满 API

```
应对：限速补算

1. 补算间隔
   - 每批之间等待 batch_interval（默认 5 秒）
   - 可配置：catchup_batch_interval = "5s"

2. 优先级
   - 最新内容优先补算（created_at DESC）
   - 理由：最新内容最可能被搜索

3. 并发控制
   - 补算与正常嵌入共享限流配额
   - 正常嵌入优先，补算用剩余配额

4. 可中断
   - 补算过程中模型再次宕机 → 立即暂停
   - 已补算的部分永久保留
```

---

## 附录 A：术语表

| 术语 | 含义 |
|------|------|
| **KnowledgeEntry** | 知识条目，OpenMind 的核心数据单元 |
| **Connector** | 数据源连接器，从外部拉取内容 |
| **StorageBackend** | 大文件存储后端（Vault/S3/本地） |
| **EmbeddingModel** | 嵌入模型，将文本/图片转为向量 |
| **EmbeddingStatus** | 嵌入状态（Embedded/Pending/Failed/Skipped），降级容灾关键字段 |
| **KnowledgeStore** | 知识存储，统一访问接口 |
| **IngestPipeline** | 摄入管道，原始内容→可搜索知识 |
| **Chunker** | 分块器，将长文本切分为块 |
| **Relator** | 关联器，自动发现知识关联 |
| **RRF** | Reciprocal Rank Fusion，混合搜索融合算法 |
| **Action Protocol** | Agent 动作协议，节点间的输入输出契约 |
| **agent.json** | Agent 发现文件，声明节点的能力和接口 |
| **content-hash** | 内容哈希（SHA-256），用于去重和变更检测 |
| **archived** | 归档状态，源内容已删除但索引和关联保留 |
| **DegradationManager** | 降级管理器，监控嵌入模型状态，协调降级和恢复 |
| **BackgroundEmbedder** | 后台嵌入补算器，模型恢复后异步补算 Pending 条目 |
| **降级 (Degradation)** | 嵌入模型不可用时，系统自动切换到关键词搜索模式 |

## 附录 B：目录结构

```
openmind/
├── Cargo.toml                    # Workspace 根
├── config.toml                   # 运行配置
├── docker-compose.yml            # Docker 部署
├── Dockerfile
├── README.md
│
├── crates/
│   ├── openmind-core/            # 核心库
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── models/           # 数据模型
│   │   │   │   ├── mod.rs
│   │   │   │   ├── entry.rs      # KnowledgeEntry + EmbeddingStatus
│   │   │   │   ├── relation.rs   # KnowledgeRelation
│   │   │   │   ├── reference.rs  # FileReference
│   │   │   │   ├── sync.rs       # SyncState, ChangeEntry
│   │   │   │   └── search.rs     # SearchResult, SearchFilter, DegradationNotice
│   │   │   ├── traits/           # 核心 trait
│   │   │   │   ├── mod.rs
│   │   │   │   ├── connector.rs
│   │   │   │   ├── storage.rs
│   │   │   │   ├── embedding.rs  # 含 EmbeddingHealth, health_check()
│   │   │   │   └── store.rs
│   │   │   ├── pipeline/         # 摄入管道
│   │   │   │   ├── mod.rs
│   │   │   │   ├── parser.rs
│   │   │   │   ├── chunker.rs
│   │   │   │   ├── embedder.rs   # 含 EmbedResult (Success/Degraded)
│   │   │   │   ├── indexer.rs    # 含降级感知索引逻辑
│   │   │   │   └── relator.rs    # 含降级感知关联逻辑
│   │   │   ├── search/           # 搜索引擎
│   │   │   │   ├── mod.rs
│   │   │   │   ├── keyword.rs    # 手动搜索（永远可用）
│   │   │   │   ├── semantic.rs   # 语义搜索（可降级）
│   │   │   │   └── hybrid.rs     # 混合搜索（含降级路径）
│   │   │   ├── degradation/      # 降级管理
│   │   │   │   ├── mod.rs
│   │   │   │   ├── manager.rs    # DegradationManager
│   │   │   │   └── catchup.rs    # BackgroundEmbedder
│   │   │   └── sync/             # 同步引擎
│   │   │       ├── mod.rs
│   │   │       ├── engine.rs
│   │   │       └── scheduler.rs
│   │   └── Cargo.toml
│   │
│   ├── openmind-connectors/      # Connector 实现
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── blog.rs
│   │   │   ├── vault.rs
│   │   │   ├── bookmark.rs
│   │   │   ├── note.rs
│   │   │   └── file.rs
│   │   └── Cargo.toml
│   │
│   ├── openmind-storage/         # StorageBackend 实现
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── vault.rs
│   │   │   ├── s3.rs
│   │   │   └── local.rs
│   │   └── Cargo.toml
│   │
│   ├── openmind-embedding/       # EmbeddingModel 实现
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── openai.rs
│   │   │   ├── bge.rs
│   │   │   └── local.rs
│   │   └── Cargo.toml
│   │
│   └── openmind-server/          # Axum 服务器
│       ├── src/
│       │   ├── main.rs
│       │   ├── routes/
│       │   │   ├── mod.rs
│       │   │   ├── search.rs     # 含降级提示
│       │   │   ├── ingest.rs     # 含 embedding_skipped
│       │   │   ├── entry.rs
│       │   │   ├── sync.rs
│       │   │   ├── connectors.rs
│       │   │   ├── stats.rs
│       │   │   ├── tags.rs       # 标签浏览
│       │   │   ├── timeline.rs   # 时间线
│       │   │   ├── health.rs     # 含降级状态
│       │   │   ├── admin.rs      # reindex 等管理操作
│       │   │   └── agent.rs      # agent.json
│       │   ├── middleware/
│       │   └── config.rs
│       └── Cargo.toml
│
├── migrations/                   # SQLite migrations
│   ├── 001_init.sql
│   ├── 002_fts5.sql
│   └── 003_relations.sql
│
└── tests/                        # 集成测试
    ├── api_tests.rs
    ├── connector_tests.rs
    ├── search_tests.rs
    └── degradation_tests.rs      # 降级场景测试
```

## 附录 C：数据库 Schema

### SQLite 主表

```sql
-- 知识条目表
CREATE TABLE knowledge_entries (
    id TEXT PRIMARY KEY,               -- UUID v7
    source_type TEXT NOT NULL,          -- Blog/Vault/Bookmark/Note/File
    source_id TEXT NOT NULL,            -- 数据源中的 ID
    source_url TEXT,                    -- 原始链接
    title TEXT NOT NULL,
    content TEXT NOT NULL,              -- 纯文本或 Markdown
    content_hash TEXT NOT NULL,         -- SHA-256
    embedding_id TEXT,                  -- Qdrant 中的向量 ID
    embedding_status TEXT NOT NULL DEFAULT 'pending',  -- embedded/pending/failed/skipped
    tags TEXT NOT NULL DEFAULT '[]',    -- JSON 数组
    project TEXT,
    file_references TEXT NOT NULL DEFAULT '[]',  -- JSON 数组
    metadata TEXT NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active',  -- active/archived/pending/error
    created_at TEXT NOT NULL,           -- ISO 8601
    updated_at TEXT NOT NULL
);

-- 索引
CREATE INDEX idx_entries_source ON knowledge_entries(source_type, source_id);
CREATE INDEX idx_entries_hash ON knowledge_entries(content_hash);
CREATE INDEX idx_entries_status ON knowledge_entries(status);
CREATE INDEX idx_entries_updated ON knowledge_entries(updated_at);
CREATE INDEX idx_entries_embedding_status ON knowledge_entries(embedding_status);

-- 唯一约束：同一数据源的同一条目只存一份
CREATE UNIQUE INDEX idx_entries_source_unique ON knowledge_entries(source_type, source_id);

-- 知识关联表
CREATE TABLE knowledge_relations (
    id TEXT PRIMARY KEY,
    from_id TEXT NOT NULL REFERENCES knowledge_entries(id),
    to_id TEXT NOT NULL REFERENCES knowledge_entries(id),
    relation_type TEXT NOT NULL,        -- Similar/DerivedFrom/References/Contradicts/PartOf
    weight REAL NOT NULL DEFAULT 1.0,
    metadata TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL,
    UNIQUE(from_id, to_id, relation_type)
);

CREATE INDEX idx_relations_from ON knowledge_relations(from_id);
CREATE INDEX idx_relations_to ON knowledge_relations(to_id);
CREATE INDEX idx_relations_type ON knowledge_relations(relation_type);

-- 同步状态表
CREATE TABLE sync_states (
    connector_name TEXT PRIMARY KEY,
    last_sync_at TEXT NOT NULL,
    content_hash TEXT,
    status TEXT NOT NULL DEFAULT 'idle',  -- idle/syncing/completed/failed
    last_error TEXT,
    total_synced INTEGER NOT NULL DEFAULT 0,
    total_errors INTEGER NOT NULL DEFAULT 0,
    last_duration_secs INTEGER,
    updated_at TEXT NOT NULL
);

-- 降级状态表
CREATE TABLE degradation_states (
    id INTEGER PRIMARY KEY DEFAULT 1,   -- 单行表
    embedding_status TEXT NOT NULL DEFAULT 'healthy',  -- healthy/degraded/down
    degraded_since TEXT,
    consecutive_failures INTEGER NOT NULL DEFAULT 0,
    last_failure_reason TEXT,
    last_success_at TEXT,
    last_health_check TEXT,
    updated_at TEXT NOT NULL
);

-- 全文索引（FTS5）
CREATE VIRTUAL TABLE knowledge_fts USING fts5(
    id,
    title,
    content,
    tags,
    tokenize='unicode61'
);
```

---

> **文档结束** — 本文档是 OpenMind 的完整蓝图，涵盖架构、数据模型、API、搜索、降级、同步、部署的所有关键设计决策。任何团队接手时应先通读本文档，然后按照 [`roadmap.md`](../../项目/OpenMind/规划/roadmap.md) 的 Phase 划分逐步实施。
