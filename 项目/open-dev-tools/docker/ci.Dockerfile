# ============================================================================
# ci.Dockerfile - CI 用 Rust 镜像
#
# 用途：基于 RustBase 预装 CI 工具，用于 GitHub Actions 等持续集成环境。
#
# 构建命令：
#   docker build -f docker/ci.Dockerfile -t rust-ci:1.82 .
#
# 使用方式：
#   GitHub Actions: uses: docker://rust-ci:1.82
#   本地测试:      docker run --rm -v $(pwd):/app rust-ci:1.82 just ci
#
# 预装工具：
#   just, cargo-nextest, cargo-audit, cargo-clippy, cargo-fmt
# ============================================================================

# 基于 RustBase 镜像（已预装依赖缓存）
# 如果未构建 RustBase，取消注释下行使用官方镜像
# FROM rust:1.82-slim
ARG RUST_BASE=rust-base:1.82
FROM ${RUST_BASE} AS ci

# 构建参数：镜像源配置
ARG CARGO_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git

# 确保镜像配置（RustBase 已配置，此处为独立使用时的兜底）
RUN mkdir -p /usr/local/cargo \
    && if [ ! -f /usr/local/cargo/config.toml ] || ! grep -q "tuna" /usr/local/cargo/config.toml; then \
        cat > /usr/local/cargo/config.toml << EOF
[source.tuna]
registry = "${CARGO_MIRROR}"

[source.crates-io]
replace-with = "tuna"

[build]
jobs = 2
EOF
    fi

# 安装 CI 工具（利用镜像加速）
RUN CARGO_BUILD_JOBS=2 cargo install just cargo-nextest cargo-audit 2>&1 \
    || echo "WARN: 部分 CI 工具安装失败，请检查网络"

# 安装额外系统依赖
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 验证工具安装
RUN just --version && cargo nextest --version && cargo audit --version

# 工作目录
WORKDIR /app

# 默认运行 CI 全流程
CMD ["just", "ci"]
