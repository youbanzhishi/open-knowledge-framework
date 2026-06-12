# OpenForge 项目知识索引

> 最后同步：2026-05-18

## 项目定位
AI-First游戏创作平台——AI Agent在服务器上写游戏，人类通过Web在任何设备上查看和参与开发，从小游戏到3A都能覆盖

## 领域术语

| 术语 | 本项目含义 | 别义/易混 | 备注 |
|------|-----------|----------|------|
| Forge Core | Rust游戏引擎核心 | OpenDAW的core crate | 负责游戏循环/实体/组件/系统 |
| Script Forge | 游戏逻辑脚本引擎 | JSFX脚本引擎 | YAML/JSON描述→Rust执行 |
| Extension Registry | 功能扩展注册中心 | OpenDAW同名的Extension Registry | 同架构理念：新功能=注册扩展 |
| Web Studio | 浏览器端游戏开发IDE | DAW前端 | TypeScript+Canvas/WebGL |
| Light Runtime | 轻量游戏运行时 | DAW播放引擎 | 嵌入式游戏执行，无编辑功能 |
| Asset Forge | 游戏资产管理模块 | — | 图片/音频/3D模型统一管理 |
| Build Pipeline | 游戏构建打包管线 | CI Pipeline | 将游戏源码→可分发产物 |
| 3D桥接 | Godot/Unreal的集成层 | — | Phase 2 Godot headless，Phase 3 Unreal PIC |

## 项目类型
开发（Rust核心+TypeScript前端）

## 技术栈
- **核心**：Rust（Forge Core / Script Forge / Extension Registry）
- **前端**：TypeScript + Canvas API / WebGL（Web Studio + Light Runtime）
- **3D桥接**：Godot headless（Phase 2）→ Unreal PIC（Phase 3）
- **AI接口**：RESTful + WebSocket
- **游戏逻辑描述**：YAML/JSON

## 当前进度
| Phase | 状态 | 说明 |
|-------|------|------|
| Phase 1: AI-First 2D创作平台 | 🔧 开发中 | PRD+技术方案已完成，workspace骨架已搭建（7 crate / 35 源文件） |
| Phase 2: Godot桥接+中型3D | ⬜ 未启动 | — |
| Phase 3: 3A能力+生态 | ⬜ 未启动 | — |

## 关联角色
- 产品经理（主）：需求定义/验收标准/蓝图维护
- 系统开发者（主）：Forge Core/Script Forge Rust核心开发
- 前端开发（主）：Web Studio + Light Runtime
- 游戏开发工程师（辅）：Godot Bridge对接+游戏逻辑规范（Phase 2）
- 游戏美术设计师（辅）：Asset Forge资产标准（Phase 1+）
- 本地运维（辅）：部署Forge服务+云渲染环境
- AI调教师（辅）：AI Agent创作流程优化

## 五步门（每次任务必走，跳过=不合格）

> 知识不等于行为，行为不能靠自觉，要靠机制。五步门就是项目的机制。

### ① 查后定方案
1. 执行 `bash scripts/act.sh "你要做的事" . "角色/系统开发者"` 搜项目内现有方案+角色前科
2. 搜到了 → 复用，搜不到 → 新建，记录原因
3. 方案写清：要改什么、为什么改、预期效果

### ② 执行方案
- 严格按方案执行，方案外发现先记后处理
- 改文件前先备份

### ③ 测试验证
- Rust核心：cargo test + cargo clippy + 功能冒烟
- 前端：TypeScript编译+浏览器运行验证+响应式验证
- 集成：API端到端测试

### ④ 反哺沉淀
1. 更新本INDEX.md的"最近变更"
2. 项目特有知识 → docs/knowledge/
3. 通用经验 → 角色 knowledge/
4. 踩坑升级：1次→knowledge，2次→hot-rules，系统性风险→脚本/铁律
5. 可封装检查 → 同一操作做了2次+？写成脚本/skill
6. 经验归属判断：换项目还能用→角色knowledge，只本项目的→项目docs/knowledge
7. 决策记录(DR)：重要技术选型/架构决策→docs/adr/

### ⑤ 交付闭环
- 执行 `bash scripts/push.sh "简要描述变更"`
- 代码项目推GitHub+Gitee双平台

## 可用工具
| 工具 | 路径 | 用途 |
|------|------|------|
| act.sh | scripts/act.sh | 意图检索+前科必显 |
| push.sh | scripts/push.sh | 一体化推送 |
| create-repo.sh | scripts/create-repo.sh | 创建GitHub+Gitee双仓库 |

## 代码仓库
- **GitHub**：https://github.com/youbanzhishi/open-forge（公开）
- **Gitee**：https://gitee.com/hutio/open-forge（私有，容灾备份）
- **本地路径**：/tmp/open-forge

## 关联项目
| 项目 | 关系 | 路径 |
|------|------|------|
| OpenDAW | 架构理念复用（Extension Registry/YAML→渲染） | ./项目/OpenDAW/ |
| 游戏开发项目 | 上游经验输入 | ./项目/游戏开发项目/ |
| OpenLink | 下游部署依赖 | ./项目/OpenLink/ |

## 凭据（需要时从加密文件获取）

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | `github.pat` | 仓库 push/pull/CI |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。
> 解密：`bash 共享知识/凭据/decrypt.sh $MASTER_KEY <字段路径>`

## 最近变更
| 日期 | 做了什么 |
|------|---------|
| 2026-05-18 | 项目立项，PRD完成，INDEX+目录结构创建 |
| 2026-05-20 | 技术架构方案v1完成（产品经理初稿），待系统开发者评审 |
| 2026-05-20 | 产品经理vs系统开发者对比评审完成 |
| 2026-05-21 | 技术架构方案v2定稿：合并PM+Dev方案，四层八模块 |
| 2026-05-18 | Phase 1 开发启动：workspace骨架搭建（forge-core/script-forge/extension-registry/runtime-abstraction/runtime-light/asset-forge/build-pipeline），REST API routes，deploy.md |
| 2026-05-18 | 技术方案完成：tech-architecture.md + api-design.md + ADR 002-006 |
| 2026-05-23 | Sprint 1启动：提WO-029(系统开发者Rust核心)+WO-030(前端Web Studio)，WO-025/026合并入WO-030，WO-028关闭(自动化协作技能替代) |

## CI/CD

| 项目 | 地址 |
|------|------|
| 仓库 | https://github.com/youbanzhishi/open-forge |
| Actions | https://github.com/youbanzhishi/open-forge/actions |
