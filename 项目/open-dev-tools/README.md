# Open Dev Tools - 跨语言共享构建工具链

> 一套标准化的开发工具+CI模板+项目知识，为 OpenLink / OpenVault / OpenDAW / AudioFX 等项目提供统一的开发环境、构建流程、CI/CD 和经验沉淀。

## 为什么需要这个工具？

- **重复造轮子**：AudioFX写了Docker缓存，OpenLink又从头写——不同项目重复解决相同问题
- **经验不流通**：这个项目踩的坑，那个项目再踩一次
- **协作断裂**：不同智能体/会话之间知识不共享
- **效率低下**：没有统一的命令入口，每次手动敲命令

## 快速开始

### 3 步开始开发

```bash
# 1️⃣ 安装 Rust 环境（含镜像配置）
./scripts/setup-rust.sh

# 2️⃣ 复制 justfile 到项目目录，修改项目变量
cp justfile ./项目/OpenLink/openlink/justfile
# 编辑 justfile 中的 project-dir 和 project-name

# 3️⃣ 构建项目
just build
```

### 直接使用构建脚本（不需要 just）

```bash
# 开发构建
./scripts/build.sh ./项目/OpenLink/openlink

# Release 构建
./scripts/build.sh ./项目/OpenLink/openlink --release

# 指定 crate
./scripts/build.sh ./项目/OpenLink/openlink --package openlink-core --release
```

## GitHub Actions CI 集成

### 为什么用 GitHub Actions？

| 维度 | ECS本地编译 | GitHub Actions |
|------|-----------|---------------|
| CPU | 共享 | 2核专用 |
| 内存 | 1.8G（OOM风险） | 7G |
| 出站带宽 | 1Mbps | 无限制 |
| 费用 | ECS运行时间 | 公开仓库免费 |
| 缓存 | 无 | rust-cache自动缓存 |
| 速度 | 慢（受限于硬件） | 快3-5倍 |

### 工作流说明

open-dev-tools提供标准CI工作流模板：

1. **ci.yml** — PR/push自动检查：check + clippy + test + fmt
2. **release.yml** — tag触发自动构建release二进制 + Docker镜像

### 使用方式

```bash
# 复制工作流到项目
cp -r github/workflows/ <项目根目录>/.github/workflows/

# 修改工作流中的项目特定变量（crate名、二进制名等）
```

### CI流程

```
push/PR → check(快速编译检查) → clippy(lint) → test(测试) → fmt(格式)
tag v*  → 构建 release 二进制 → 构建多平台 → 创建 GitHub Release
```

### 关键优化

- **Swatinem/rust-cache**：缓存 ~/.cargo/registry + target/，后续构建秒级
- **CARGO_INCREMENTAL=1**：增量编译，改一个文件不是全量重编
- **cargo nextest**：测试并行执行，比cargo test快2-3倍
- **分步缓存**：先check再test，check的缓存给test用

## 目录结构

```
open-dev-tools/
├── README.md                    # 本文档
├── justfile                     # Rust Justfile（兼容旧版）
├── templates/                   # 跨语言项目模板
│   ├── rust/justfile            # Rust项目命令模板
│   ├── python/justfile          # Python项目命令模板
│   └── cpp/justfile             # C++/JUCE项目命令模板
├── scripts/
│   ├── setup-rust.sh            # Rust环境一键安装（含镜像配置）
│   ├── cargo-mirror.sh          # cargo镜像配置
│   ├── build.sh                 # 通用构建脚本
│   └── docker-build.sh          # Docker多阶段构建脚本
├── docker/
│   ├── RustBase.Dockerfile      # Rust基础镜像
│   └── ci.Dockerfile            # CI用镜像
├── github/
│   └── workflows/
│       ├── ci.yml               # PR/push自动CI
│       └── release.yml          # tag触发release构建
└── config/
    ├── cargo-config.toml        # 镜像+编译优化配置
    └── rustfmt.toml             # 代码格式统一
```

## 配套：共享知识库

```
./共享知识/
├── CI模式库/          # 跨项目CI最佳实践
│   ├── rust-ci.md    # Rust CI标准模式
│   ├── cpp-juce-ci.md # C++ JUCE CI模式
│   └── python-ci.md  # Python CI模式
├── 踩坑记录/          # 所有项目的坑汇总
│   ├── rust-oom.md   # Rust编译OOM
│   └── cargo-mirror.md # 国内镜像配置
└── 设计模式/          # 可复用架构模式
    └── extension-registry.md  # 注册表模式
```

**原则：一个项目踩过的坑，其他项目绝对不能再踩。**

## 各项目如何接入

### OpenLink / OpenVault（Rust）

已接入。justfile + CI workflows + 构建脚本全到位。

### AudioFX（C++/JUCE）

1. 复制 `templates/cpp/justfile` 到项目根目录
2. CI workflows 已有且成熟，不需要替换，但可参考 `共享知识/CI模式库/` 优化
3. 主要受益点：统一命令入口 + 踩坑记录不重复

### OpenDAW（Python）

1. 复制 `templates/python/justfile` 到项目根目录
2. CI workflows 已有且成熟，不需要替换
3. 主要受益点：Docker多Profile模板 + PyPI发布模板

## 脚本详解

### 1. setup-rust.sh — Rust 环境一键安装

```bash
./scripts/setup-rust.sh
```

功能：
- 检测当前 Rust 版本，≥1.82 则跳过
- 需要安装时使用清华镜像加速（`RUSTUP_DIST_SERVER`）
- 安装 stable 工具链
- 自动配置 cargo 镜像（调用 `cargo-mirror.sh`）
- 安装 just 命令运行器
- 输出完整环境信息

特性：
- **幂等**：重复运行不出错，已安装则跳过
- **安全**：限制 `CARGO_BUILD_JOBS=2` 防止 OOM

### 2. cargo-mirror.sh — Cargo 镜像配置

```bash
./scripts/cargo-mirror.sh
```

功能：
- 写入 `~/.cargo/config.toml`
- 主源：清华镜像 `https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git`
- 备源：rsproxy `https://rsproxy.cn/crates.io-index`
- 已有配置不覆盖（幂等）

### 3. build.sh — 通用构建脚本

```bash
./scripts/build.sh <项目目录> [--release] [--package <crate名>]
```

| 参数 | 说明 | 示例 |
|------|------|------|
| `<项目目录>` | 必填，Cargo.toml 所在目录 | `./OpenLink/openlink` |
| `--release` | 可选，release 模式构建 | |
| `--package` | 可选，指定 workspace 中的 crate | `--package openlink-core` |

流程：
1. 校验项目目录和 Cargo.toml
2. `cargo check` — 快速验证编译（秒级反馈）
3. `cargo build` — 实际编译
4. 输出构建报告（耗时、产物路径、大小）

环境变量：
- `CARGO_BUILD_JOBS`：并行编译数，默认 **2**（1.8G 内存安全值）

### 4. docker-build.sh — Docker 构建

```bash
./scripts/docker-build.sh <项目目录> [镜像名]
```

| 参数 | 说明 | 示例 |
|------|------|------|
| `<项目目录>` | 必填，包含 Dockerfile 的目录 | `./OpenLink/openlink` |
| `[镜像名]` | 可选，默认用目录名+时间戳 | `openlink:latest` |

自动传递构建参数：
- `CARGO_MIRROR`：清华镜像 URL
- `RUSTUP_DIST_SERVER`：rustup 镜像

## Docker 镜像

### RustBase.Dockerfile — 基础镜像

```bash
# 构建
docker build -f docker/RustBase.Dockerfile -t rust-base:1.82 .

# 在项目 Dockerfile 中使用
FROM rust-base:1.82 AS builder
# 只需编译业务代码，依赖已缓存
```

预装依赖（编译缓存层）：
- tokio (full), axum, serde, serde_json
- sqlx (postgres), chrono, thiserror
- tracing, tracing-subscriber
- clap, anyhow, uuid, reqwest, dotenvy

原理：通过一个空项目触发依赖编译，结果缓存到镜像层。项目构建时只需编译业务代码。

### ci.Dockerfile — CI 镜像

```bash
# 构建（需要先构建 RustBase）
docker build -f docker/ci.Dockerfile -t rust-ci:1.82 .

# 本地测试 CI 流程
docker run --rm -v $(pwd):/app rust-ci:1.82 just ci
```

预装 CI 工具：
- just, cargo-nextest, cargo-audit

## 配置文件

### cargo-config.toml

复制到 `~/.cargo/config.toml`（全局）或项目 `.cargo/config.toml`：

```bash
cp config/cargo-config.toml ~/.cargo/config.toml
```

配置内容：
- 清华镜像（主）+ rsproxy（备）
- `codegen-units = 1`：release 最优代码生成
- `lto = "thin"`：轻量级链接时优化
- `strip = true`：移除调试符号
- `jobs = 2`：并行编译限制

### rustfmt.toml

复制到项目根目录：

```bash
cp config/rustfmt.toml ./OpenLink/openlink/rustfmt.toml
```

## Justfile 命令速查

| 命令 | 说明 |
|------|------|
| `just setup` | 安装 Rust 环境 |
| `just build` | 开发构建 |
| `just build-release` | Release 构建 |
| `just check` | 快速编译检查 |
| `just fmt` | 代码格式化 |
| `just lint` | Clippy 严格检查 |
| `just test` | 运行测试 |
| `just dev` | 开发模式运行 |
| `just docker` | Docker 构建 |
| `just audit` | 安全审计 |
| `just clean` | 清理构建缓存 |
| `just ci` | CI 全流程 |
| `just info` | 查看项目信息 |

## 如何给新项目使用这套工具

以新项目 OpenDAW 为例：

### 步骤1：配置环境

```bash
cd open-dev-tools
./scripts/setup-rust.sh
```

### 步骤2：复制配置文件

```bash
# justfile
cp justfile /path/to/OpenDAW/justfile
# 修改 justfile 中的变量：
#   project-dir := "/path/to/OpenDAW"
#   project-name := "opendaw"

# rustfmt
cp config/rustfmt.toml /path/to/OpenDAW/rustfmt.toml

# cargo 配置（项目级）
mkdir -p /path/to/OpenDAW/.cargo
cp config/cargo-config.toml /path/to/OpenDAW/.cargo/config.toml
```

### 步骤3：创建符号链接（可选，让脚本全局可用）

```bash
# 在项目目录下链接脚本
ln -s /path/to/open-dev-tools/scripts scripts
```

### 步骤4：开始开发

```bash
cd /path/to/OpenDAW
just build        # 开发构建
just check        # 快速检查
just test         # 运行测试
just build-release # 发布构建
```

## 适配环境

| 项目 | 当前值 | 说明 |
|------|--------|------|
| OS | Debian | 云电脑 |
| 内存 | 1.8G | CARGO_BUILD_JOBS=2 |
| Rust | ≥1.75（可升级） | setup-rust.sh 自动升级到 ≥1.82 |
| 网络 | 国内 | 清华镜像加速 |

## 故障排查

### 编译 OOM

```bash
# 减少并行数
export CARGO_BUILD_JOBS=1
./scripts/build.sh ./项目目录
```

### 镜像源不通

```bash
# 手动切换到 rsproxy
# 编辑 ~/.cargo/config.toml，将 replace-with = "tuna" 改为 replace-with = "rsproxy"
```

### 依赖下载超时

```bash
# 清除缓存重新下载
cargo clean
./scripts/build.sh ./项目目录
```

### just 未安装

```bash
CARGO_BUILD_JOBS=2 cargo install just
```
