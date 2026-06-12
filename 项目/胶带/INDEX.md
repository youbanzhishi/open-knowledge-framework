# 胶带 项目知识索引

> 最后同步：2026-05-16 (Web UI内嵌)

## 项目定位
现在写，条件到了才开——时间封存平台。封存物+解封条件+查看人三要素覆盖遗嘱、暗恋表白、时间胶囊、毕业寄语等全部场景。

## 项目类型
🔨开发

## 技术栈
Rust (Axum) + Ethereum L2 + SQLite + 微信小程序/H5

## 当前进度
| Phase | 状态 | 说明 |
|-------|------|------|
| Phase 1 | ✅完成 | 项目骨架+数据模型+核心trait |
| Phase 2 | ✅完成 | 账号体系（注册/登录/手机号绑定/换号找回/实名认证兜底） |
| Phase 3 | ✅完成 | 封存核心（内容加密存储+hash上链+封存凭证生成） |
| Phase 4 | ✅完成 | 解封引擎（心跳失联/双向匹配/指定日期/多人确认） |
| Phase 5 | ✅完成 | 暗恋表白场景 |
| Phase 6 | ✅完成 | 遗嘱交代场景 |
| Phase 7 | ✅完成 | 时间胶囊场景 |
| Phase 8 | ✅完成 | 区块链时间戳集成（Merkle批量上链+MockChain+验证API） |
| Phase 9 | ✅完成 | OpenLink集成（Identity Card+短链分享+凭证验证） |
| Phase 10 | ✅完成 | OpenVault集成（Shamir SSS完整M-of-N+VaultConnector trait） |
| Phase 11 | ✅完成 | Web前端API准备（CORS+JWT中间件+WebSocket+OpenAPI spec） |
| Phase 12 | ✅完成 | Agent Action Protocol（agent.json+Action中间件+OpenMind占位） |

## 关联角色
- 系统开发者（主）：架构设计、核心开发、Rust实现、加密方案
- ECS运维（辅）：部署、Docker编排、区块链节点运维

## 可用工具
| 工具 | 路径 | 用途 |
|------|------|------|
| Rust工具链 | cargo/rustc | 项目编译与开发 |
| ethers-rs | crates.io | Ethereum L2交互 |
| AES-256-GCM | RustCrypto | 端到端内容加密 |
| Shamir SSS | GF(256) | 密钥分片M-of-N |
| 微信开发者工具 | 本地 | 小程序开发调试 |

## 关联项目
| 项目 | 关系 | 路径 |
|------|------|------|
| OpenLink | 封存凭证=Identity Card+短链分享 | ./项目/OpenLink/ |
| OpenVault | 大文件加密存储引用 | ./项目/OpenVault/ |
| OpenMind | 知识检索（封存内容语义索引） | ./项目/OpenMind/ |

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
| 胶带 | docs/knowledge/deploy.md | scripts/deploy.sh | Docker+二进制+源码编译 | 39.103.203.162 |

## 反哺检查门（不过不算任务完成）

> 铁律4：产出结果≠任务完成。以下每项必须过，sub-agent返回时必须汇报反哺情况。
1. 更新本INDEX.md的"最近变更"
2. 项目特有事实 → 本项目 docs/knowledge/
3. 通用经验 → ./角色/系统开发者/knowledge/
4. 踩坑2次 → 本项目 规划/hot-rules.md
5. 发现跨角色通用模式 → ./共享知识/

## 最近变更
| 日期 | 做了什么 |
|------|---------|
| 2026-05-11 | Phase 8-12 全部完成：9 crate Rust workspace + 区块链时间戳+OpenLink+OpenVault+前端API+Agent Protocol，177 tests全绿，~9400行Rust |
| 2026-05-11 | Phase 1-7 完成：7→9 crate Rust workspace（+auth+scene） + 核心场景 + 22→177测试全绿 |
| 2026-05-11 | 项目创建：知识体系注册+核心文件编写（INDEX/roadmap/decisions/蓝图） |

## 目录自愈
```bash
mkdir -p ./{规划,src,tests/{integration,fixtures},docs/{dev-log,knowledge},assets/{images,templates,data},output,config,scripts,feedback,.github/workflows}
```

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|

## 按需加载
- 规划/roadmap.md — 项目路线图（12个Phase）
- 规划/decisions.md — 架构决策记录（ADR-001~ADR-008）
- docs/蓝图与设计文档.md — 完整蓝图（架构/数据模型/API/加密方案）
- docs/knowledge/ — 项目特有知识
- docs/dev-log/ — 开发日志

## 已同步版本: 2026-05-11-v15

## 部署信息
| 项 | 值 |
|------|------|
| 二进制路径 | /opt/jiaodai/jiaodai |
| 数据目录 | /opt/jiaodai/data/ |
| 监听端口 | 3000 |
| systemd服务 | jiaodai.service |

## 最近变更
- 2026-05-16: 新增Web管理面板(web_ui.rs, 6页面: Dashboard/Seals/Unseal/Capsule/Chain/Account)，HTMX+Alpine.js内嵌方案，服务部署上线

## CI/CD

| 项目 | 地址 |
|------|------|
| 仓库 | https://github.com/youbanzhishi/jiaodai |
| Actions | https://github.com/youbanzhishi/jiaodai/actions |
| CI | https://github.com/youbanzhishi/jiaodai/actions/workflows/CI/ |
| Auto Format Fix | https://github.com/youbanzhishi/jiaodai/actions/workflows/Auto%20Format%20Fix/ |
