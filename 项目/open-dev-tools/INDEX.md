# open-dev-tools 项目知识索引

> 最后更新：2026-07-10 | 更新人：子任务(5项目入体系)
> 用途：任何智能体接手open-dev-tools相关任务时，先读本文件了解项目全貌

## 共享规范
→ ./共享知识/项目规范/（宪法层，改一次全局生效）
- 目录结构规范：最后同步 2026-07-10
- 协作规范：最后同步 2026-07-10
- 热规则规范：最后同步 2026-07-10
本项目已对齐：新建，按规范骨架建立

## 热规则
→ 规划/hot-rules.md（派发任务时必须注入，防重复踩坑）

## 本地偏差
| 规范 | 偏差 | 原因 |
|------|------|------|
| 目录结构 | 保留git仓库原有结构（templates/docker/github/scripts/config/） | 工具链项目特有，不迁入规范目录 |
| 目录结构 | 根目录散落justfile+README.md | 工具链项目入口文件，保持根目录可访问 |

## 目录自愈

此项目按开发类目录结构规范，执行任何操作前运行：
```bash
mkdir -p ./回收站 && mkdir -p ./项目/open-dev-tools/规划 ./项目/open-dev-tools/src ./项目/open-dev-tools/tests/integration ./项目/open-dev-tools/tests/fixtures ./项目/open-dev-tools/docs/dev-log ./项目/open-dev-tools/docs/knowledge ./项目/open-dev-tools/assets/images ./项目/open-dev-tools/assets/templates ./项目/open-dev-tools/assets/data ./项目/open-dev-tools/output ./项目/open-dev-tools/config ./项目/open-dev-tools/scripts ./项目/open-dev-tools/feedback
```

⚠️ 文件安全铁律：删除→mv到./回收站/open-dev-tools-$(date +%m%d)/，禁止rm

## 项目定位

**open-dev-tools是跨语言共享构建工具链——一套标准化的开发环境+CI模板+踩坑知识，让所有项目不再重复造轮子。**

- 当下：Rust/Python/C++ justfile模板 + CI工作流 + 构建脚本 + Docker镜像
- 近未来：统一CI Dashboard，一键部署新项目开发环境
- 远期：所有项目的DevOps中枢

一句话：**一个项目踩过的坑，其他项目绝对不能再踩。**

→ README：[README.md](README.md)

## 核心知识

### 产品特性（开发关注）

| 特性 | 说明 | 详见 |
|------|------|------|
| justfile模板 | Rust/Python/C++三套，统一命令入口 | templates/ |
| CI工作流 | ci.yml + release.yml，开箱即用 | github/workflows/ |
| 构建脚本 | setup-rust.sh / build.sh / docker-build.sh | scripts/ |
| Docker镜像 | RustBase + CI镜像，预编译依赖缓存 | docker/ |
| 配置文件 | cargo镜像+编译优化+代码格式统一 | config/ |
| 共享知识库 | CI模式库/踩坑记录/设计模式 | ../../共享知识/ |

### 技术架构（开发关注）

| 维度 | 选择 | 详见 |
|------|------|------|
| 语言 | Shell + Justfile + YAML | 脚本工具链 |
| CI平台 | GitHub Actions | github/workflows/ |
| 缓存策略 | Swatinem/rust-cache + 增量编译 | ci.yml |
| 镜像构建 | Docker多阶段构建 | docker/ |
| open-storage | Rust共享crate（存储后端抽象） | open-storage/ |

## 项目状态

| 阶段 | 状态 | 说明 |
|------|------|------|
| Phase 1：Rust工具链+CI | ✅ 已完成 | justfile+CI+构建脚本 |
| Phase 2：跨语言模板 | ✅ 已完成 | Python/C++ justfile模板 |
| Phase 3：Docker缓存优化 | ✅ 已完成 | RustBase+CI镜像 |
| Phase 4：open-storage共享crate | ✅ 已完成 | 存储后端抽象 |
| Phase 5：CI Dashboard | 📋 规划中 | 统一监控所有项目CI状态 |

## 联盟项目
| 项目 | 路径 | 关系 | 共享知识 |
|------|------|------|----------|
| OpenDAW | ./项目/OpenDAW/ | DAW核心+插件宿主 | 音频引擎/信号链/扩展注册 |
| AudioFX | ./项目/AudioFX/ | VC插件基础(C++/JUCE) | DSP/插件设计/混音经验 |
| OpenLink | ./项目/OpenLink/ | 同架构不同领域 | Extension Registry/架构模式 |
| OpenVault | ./项目/OpenVault/ | 保险层 | 存储引擎/备份策略 |
| open-dev-tools | ./项目/open-dev-tools/ | 共享构建工具链 | CI模板/构建脚本 |

| 项目 | 关系 | 详见 |
|------|------|------|
| OpenLink | 主要用户，Rust项目已接入 | [../OpenLink/INDEX.md](../OpenLink/INDEX.md) |
| OpenVault | 主要用户，Rust项目已接入 | [../OpenVault/INDEX.md](../OpenVault/INDEX.md) |
| AudioFX | C++/JUCE模板用户 | [../AudioFX/INDEX.md](../AudioFX/INDEX.md) |
| OpenDAW | Python模板用户 | [../OpenDAW/INDEX.md](../OpenDAW/INDEX.md) |
| 共享知识库 | CI模式库+踩坑记录 | [../../共享知识/README.md](../../共享知识/README.md) |

## 关联技能
- DevOps/CI-CD
- Docker镜像构建
- 跨语言构建系统
- Rust/Python/C++工具链

## 最近变更

| 日期 | 变更 | 详见 |
|------|------|------|
| 2026-07-10 | 项目入知识体系，建骨架+INDEX.md | 本文件 |
## ⛔ 禁止项

- **禁止直接操作ECS服务器**：所有服务器操作（SSH/Remote Gateway/Docker管理）只能由ECS运维角色执行
- 需要部署/运维时：通过主对话转派给ECS运维角色，不要自己动手


## 部署信息

无部署需求

## 凭据

| 用途 | 字段路径 | 说明 |
|------|----------|------|
| GitHub 读写 | `github.pat` | 仓库 push/pull/CI |

> 凭据加密存储在 `共享知识/凭据/secrets.enc`，主密钥在平台 SECRET.md。

## 关联角色

- 系统开发者（主）：Rust/Python/C++工具链开发

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
