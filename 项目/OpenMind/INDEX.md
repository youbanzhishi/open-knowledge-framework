# OpenMind 项目知识索引

> 最后同步：2026-05-16 (Web UI部署+服务启动)

## 项目定位
AI原生的个人知识引擎，Agent生态中的知识节点

## 项目类型
🔨开发

## 技术栈
Rust (Axum) + Qdrant(向量) + SQLite/PostgreSQL(元数据) + 可插拔嵌入模型

## 当前进度
| Phase | 状态 | 说明 |
|-------|------|------|
| Phase 1 | ✅完成 | 项目骨架+数据模型+Connector trait+SQLite存储+CLI命令 |
| Phase 2 | ✅完成 | 文本摄入+关键词搜索+嵌入模型集成 |
| Phase 3 | ✅完成 | 语义搜索+RAG查询+知识图谱基础 |
| Phase 4 | ✅完成 | Connector实现（Blog/Vault/Bookmark/Note） |
| Phase 5 | ✅完成 | Agent Action Protocol + /.well-known/agent.json |
| Phase 6 | ✅完成 | Web管理界面(HTMX+Alpine.js)+API指标+配置热重载+监控面板 |
| Phase 7 | ✅完成 | 增量同步+变更检测+删除处理 |

## 关联角色
- 系统开发者（主）：架构设计、核心开发、Rust实现
- ECS运维（辅）：部署、Docker编排、Qdrant运维

## 可用工具
| 工具 | 路径 | 用途 |
|------|------|------|
| Rust工具链 | cargo/rustc | 项目编译与开发 |
| Qdrant | Docker镜像 | 向量存储与检索 |
| 嵌入模型API | OpenAI/本地 | 文本嵌入生成 |

## 关联项目
| 项目 | 关系 | 路径 |
|------|------|------|
| OpenVault | 数据源（Vault文件） | ./项目/OpenVault/ |
| OpenLink | 协议协同（互联网协议） | ./项目/OpenLink/ |
| OpenDAW | 协议协同（音频知识检索） | ./项目/OpenDAW/ |

## 凭据（需要时从加密文件获取）

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | github.pat | 仓库 push/pull |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。
> 解密：`bash 共享知识/凭据/decrypt.sh $MASTER_KEY <字段路径>`
> **新建仓库前先查现有凭据**，不要重复申请密钥。如需新增凭据，按「共享知识/凭据/README.md」更新流程操作。

## 部署信息（可选·有部署需求时填写）
| 项目 | 部署文档 | 部署脚本 | 部署方式 | 服务器 |
|------|----------|----------|----------|--------|
| OpenMind | docs/knowledge/deploy.md | scripts/deploy.sh | Docker(含Qdrant)+二进制+源码编译 | 39.103.203.162 |

## 反哺检查门（不过不算任务完成）

> 铁律4：产出结果≠任务完成。以下每项必须过，sub-agent返回时必须汇报反哺情况。
1. 更新本INDEX.md的"最近变更"
2. 项目特有事实 → 本项目 docs/knowledge/
3. 通用经验 → ./角色/{关联角色名}/knowledge/
4. 踩坑2次 → 本项目 规划/hot-rules.md
5. 发现跨角色通用模式 → ./共享知识/

## 最近变更
| 日期 | 做了什么 |
|------|---------|
| 2026-05-11 | 项目创建：知识体系注册+GitHub仓库+Rust项目骨架 |
| 2026-05-11 | Phase 1+2完成：SQLite存储+CLI+解析器+分块+FTS5搜索+嵌入模型+摄入管道 |

## 目录自愈
```bash
mkdir -p ./{规划,src,docs/{dev-log,knowledge},assets,config,scripts,output,feedback}
```

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|

## 按需加载
- 规划/roadmap.md — 项目路线图
- 规划/decisions.md — 架构决策记录
- docs/knowledge/ — 项目特有知识

## 已同步版本: 2026-05-11-v13

## 部署信息
| 项 | 值 |
|------|------|
| 二进制路径 | /opt/openmind/openmind |
| 数据目录 | /opt/openmind/data/ |
| 监听端口 | 9090 |
| systemd服务 | openmind.service |
| 数据库 | SQLite (/opt/openmind/data/openmind.db) |

## 最近变更
- 2026-05-16: 部署OpenMind服务到ECS，Web管理面板上线(6页面)，systemd服务配置

## CI/CD

| 项目 | 地址 |
|------|------|
| 仓库 | https://github.com/youbanzhishi/openmind |
| Actions | https://github.com/youbanzhishi/openmind/actions |
