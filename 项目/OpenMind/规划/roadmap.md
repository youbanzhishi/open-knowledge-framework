# OpenMind 路线图

## Phase 1: 项目骨架+数据模型+Connector trait
- [x] 创建项目目录与知识体系注册
- [x] GitHub仓库初始化
- [x] Rust workspace骨架（6个crate）
- [x] 核心trait定义（Connector/Storage/Embedding/KnowledgeStore/IngestionPipeline）
- [x] 数据模型定义（KnowledgeEntry/FileReference/KnowledgeRelation/SyncState/SearchResult）
- [x] API路由骨架（Axum）
- [x] Agent发现协议（/.well-known/agent.json）
- [x] SQLite元数据存储实现
- [x] 基础CLI命令

## Phase 2: 文本摄入+关键词搜索+嵌入模型集成
- [x] 文本解析器（Markdown/纯文本/HTML）
- [x] 分块策略（按段落/固定长度/语义边界）
- [x] SQLite全文搜索（FTS5）
- [x] 嵌入模型接口实现（OpenAI/本地模型）
- [x] 摄入管道串联

## Phase 3: 语义搜索+RAG查询+知识图谱基础
- [ ] Qdrant向量存储集成
- [ ] 语义搜索实现
- [ ] 混合搜索（关键词+语义融合）
- [ ] RAG查询管道
- [ ] 基础知识图谱（实体提取+关系构建）

## Phase 4: Connector实现（Blog/Vault/Bookmark/Note）
- [ ] OpenVault Connector（Vault文件同步）
- [ ] Blog Connector（博客文章摄入）
- [ ] Bookmark Connector（书签导入）
- [ ] Note Connector（备忘录同步）
- [ ] Connector注册与发现机制

## Phase 5: Agent Action Protocol + /.well-known/agent.json
- [ ] Action Protocol完整实现
- [ ] 输入输出契约校验
- [ ] Agent间调用示例
- [ ] 工作流编排（search_and_mix）

## Phase 6: Web管理界面+同步调度
- [x] Web UI骨架（管理界面）
- [x] 多页面UI: Dashboard/Search/Config/Ingest/Status/Sync
- [x] HTMX+Alpine.js轻量前端（无构建链）
- [x] API指标追踪（请求计数/响应时间/错误率）
- [x] 监控面板（API统计/存储占用/同步健康）
- [x] 配置管理（TOML配置+热重载API+功能开关页）
- [x] 摄入页（手动触发摄入+同步触发）
- [x] 同步调度器（定时/增量）

## Phase 7: 增量同步+变更检测+删除处理
- [ ] 内容哈希变更检测
- [ ] 增量同步机制
- [ ] 删除处理与级联清理
- [ ] 冲突解决策略
- [ ] 同步状态持久化
