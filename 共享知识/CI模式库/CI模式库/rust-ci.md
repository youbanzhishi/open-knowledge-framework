# Rust 项目 CI 标准模式

> 从 AudioFX/OpenDAW/OpenLink/OpenVault 四个项目提炼的 Rust CI 最佳实践
> 最后更新：2026-05-11

## 🔴 核心原则：本地优先，CI兜底

**能本地测的必须本地测，实在不行再上CI。** CI分钟要钱，CI日志读起来要token。能用本地解决的绝不上CI。

**本地测试优先级高于CI的原因**：
1. **速度**：本地秒级复现，CI要排队等容器启动（1-3分钟）
2. **成本**：本地测试0成本，CI读日志一次消耗数百token
3. **迭代**：本地改完立刻重测，CI每轮push等结果（5-10分钟一轮）
4. **诊断**：本地RUST_BACKTRACE=1完整堆栈，CI日志被截断混噪音

**反面教训**：OpenLink的Kahn算法bug，本地`cargo test`秒复现秒修复。如果靠CI试错，每轮push→等5分钟→读几百行日志→修→再push，至少3-5轮=半小时+数千token。

| 步骤 | 本地 | CI | 理由 |
|------|:---:|:---:|------|
| cargo check | ✅ | ✅ | push前守门 |
| cargo test | ✅ | ✅ | 守门员 |
| cargo fmt --check | ✅ | ✅ | 轻量，CI带上不亏 |
| clippy -D warnings | ✅ | ❌ | 太严格，18个小问题就让CI红，本地跑就行 |
| smoke test | ✅ | ❌ | 本地`./binary --help`秒完，CI排号等容器浪费 |
| 多平台构建 | ❌ | ✅ | 本地只有Linux，macOS/Windows必须CI |
| 打包上传Release | ❌ | ✅ | 需要GHCR/GitHub权限 |
| Docker推GHCR | ❌ | ✅ | 需要registry权限 |
| Tauri桌面应用构建 | ❌ | ✅ | 需要各平台native依赖，必须CI |

**省钱逻辑**：
- clippy本地跑不卡CI → CI红了要读日志修 → 日志几百行 → 消耗token
- smoke test本地秒完 → CI排号等容器启动 → Docker构建3分钟 → 跑smoke又要等 → 浪费分钟
- 用 `workflow_dispatch` 手动触发release/docker，不打tag → tag多了容易乱

## 标准 CI 流程（精简3步）

```yaml
jobs:
  check → test → fmt
```

| Job | 作用 | 必要性 |
|-----|------|--------|
| check | 快速编译检查，最先跑 | 必须 |
| test | 运行测试 | 必须 |
| fmt | 格式检查，最轻量 | 必须 |

~~clippy~~：从CI移除。本地跑 `cargo clippy -- -D warnings` 即可，CI太严格反而浪费时间修小问题。

**关键设计**：check先跑，test/fmt 依赖check的缓存，这样check编译的缓存直接给后续job用。

## 必用的 GitHub Actions

| Action | 用途 | 配置要点 |
|--------|------|---------|
| `dtolnay/rust-toolchain@stable` | Rust工具链 | 指定components: clippy, rustfmt |
| `Swatinem/rust-cache@v2` | 缓存依赖+编译产物 | `cache-on-failure: true` |
| `softprops/action-gh-release@v2` | 创建Release | `generate_release_notes: true` |

## Release 流程

```
workflow_dispatch 手动触发 → 4平台构建(Linux/macOS-amd64/macOS-arm64/Windows) → GitHub Release
```

**不用打tag触发**：所有workflow都配了 `workflow_dispatch`，直接 `gh workflow run release.yml` 触发。tag打多了容易乱。

Docker缓存用GitHub Actions原生缓存：
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

## 从 AudioFX 借鉴的高级模式

1. **变更检测**：不是每次全量构建，只构建有改动的模块（适用于workspace项目）
2. **分层验证**：快速验证先行(g++ standalone) → 完整构建后置(JUCE)
3. **三层CLI测试**：可运行性 → 功能性 → 效果性

Rust项目可借鉴：`cargo check`(快速) → `cargo test`(完整) → `cargo clippy`(严格)

## 从 OpenDAW 借鉴的 Docker 模式

1. **纯Rust多阶段构建**：`rust:1.86-slim` 编译 → `debian:bookworm-slim` 运行，镜像精简
2. **GHCR推流**：`ghcr.io/owner/repo:latest` + semver版本标签
3. ~~Smoke Test~~：从Docker CI移除，放本地第③步做

### 🔴 Rust版本选择（踩坑：1.82→1.85→1.86）

| 依赖 | 最低Rust版本 | 原因 |
|------|-------------|------|
| clap ≥4.6 | 1.85+ | edition2024特性 |
| icu_collections ≥2.2 | 1.86+ | 依赖Rust 1.86 |
| getrandom ≥0.4 / base64ct ≥1.7 / indexmap ≥2.7 | 1.85+ | edition2024 |

**结论**：新项目Dockerfile统一用 `rust:1.86-slim`，避免逐级升版本。

### 🔴 Dockerfile slim镜像踩坑

slim镜像缺少编译依赖，builder阶段必须apt安装：
```dockerfile
FROM rust:1.86-slim AS builder
WORKDIR /app
# 🔴 slim镜像必须装这两个，否则openssl-sys编译失败
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY . .
RUN cargo build --release -p your-crate

FROM debian:bookworm-slim
# 运行时也需libssl
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/your-binary /usr/local/bin/
```

### 🔴 Release workflow踩坑

`softprops/action-gh-release@v2` 需要tag才能创建release。workflow_dispatch触发时没有tag会失败：
```bash
# 正确流程：先打tag再触发release
gh api repos/owner/repo/git/refs -f ref=refs/tags/v1.0.1 -f sha=$MAIN_SHA
gh workflow run release.yml --repo owner/repo --ref v1.0.1
```

## Tauri v2 桌面应用构建模式（通用复用）

从OpenDAW提炼，适用于任何Rust+Tauri项目。

### workflow关键结构（desktop.yml）

```yaml
name: Desktop Build
on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:

jobs:
  check:     # cargo check快速验证（fast fail）
  build:     # 三平台构建（linux/macos/windows）
```

### 三平台构建矩阵

| 平台 | runner | 产出 |
|------|--------|------|
| Linux | ubuntu-latest | .AppImage + .deb |
| macOS | macos-latest | .dmg + .app.tar.gz |
| Windows | windows-latest | .exe (NSIS) + .msi |

### Linux系统依赖（必须）

```bash
sudo apt-get install -y libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev \
  patchelf libssl-dev libasound2-dev libgtk-3-dev libglib2.0-dev
```

### 核心步骤

1. **Cargo check**（fast fail）— 先验证编译，避免三平台同时编译失败浪费资源
2. **Prepare frontend** — 将前端静态文件复制到 `src-tauri/frontend/`
3. **npm install** — 安装Tauri CLI
4. **tauri-action** — `tauri-apps/tauri-action@v0` 一键构建+打包+上传artifact
5. **Upload artifact** — 按平台上传安装包

### 🔴 workspace踩坑

Tauri子项目在workspace中必须加入members，不能用exclude：
```toml
# ❌ 错误：exclude会导致cargo check报"believes it's in a workspace when it's not"
exclude = ["desktop/src-tauri"]

# ✅ 正确：加入members
members = ["desktop/src-tauri", ...]
```

### 缓存策略

```yaml
- uses: Swatinem/rust-cache@v2
  with:
    workspaces: desktop/src-tauri -> target
    prefix-key: v0-rust-${{ matrix.platform }}-${{ matrix.target }}
    cache-on-failure: true
```

### 产品名/版本号统一

Tauri项目需同步更新以下文件的产品名和版本号：
1. `desktop/src-tauri/tauri.conf.json` — productName, version, identifier
2. `desktop/src-tauri/Cargo.toml` — name, description
3. `desktop/package.json` — name, version, description

## 开发交付七步门

| 步 | 门 | 做什么 | 在哪做 | 谁管 |
|---|---|---|---|---|
| ① | cargo check 0错误 | 编译通过 | 本地+CI | 开发 |
| ② | cargo test 0失败 | 功能正确 | 本地+CI | 开发 |
| ③ | 本地构建验证 | `cargo build --release` + smoke test（`./binary --help`） | 本地 | 开发 |
| ④ | CI全平台构建 | GitHub Actions 4平台构建+打包+推Release | CI | 开发 |
| ⑤ | 桌面应用构建 | Tauri v2三平台构建+打包AppImage/dmg/exe/msi | CI | 开发 |
| ⑥ | 文档同步更新 | 项目README/CHANGELOG/运维文档/知识体系同步更新 | 本地 | 开发 |

**六步全过才算开发完成。** ⑤仅适用于有桌面GUI的项目。smoke test在第③步本地做，不在CI。

**⑥详解**：代码变了文档必须跟着变，否则下一个接手的人看到过期文档=白写。必须同步更新：
- 项目README.md（新功能/新命令/新配置项）
- CHANGELOG.md（本次变更摘要）
- 知识体系：项目INDEX.md + roadmap.md打勾 + 相关角色knowledge
- 运维文档（如有部署变更：新端口/新环境变量/新依赖）

**🔴 开发只管七步门，不碰生产服务器。部署是运维的事。**
