# ============================================================================
# RustBase.Dockerfile - Rust 基础镜像（预装依赖缓存）
#
# 用途：预编译常用 crate 依赖，项目构建时只需编译业务代码，
#       大幅减少 CI/CD 构建时间。
#
# 构建命令：
#   docker build -f docker/RustBase.Dockerfile -t rust-base:1.82 .
#
# 使用方式：
#   在项目 Dockerfile 中使用：FROM rust-base:1.82 AS builder
#
# 预装依赖：
#   tokio, axum, serde, sqlx, chrono, thiserror, tracing, clap
#   （通过空项目触发编译，缓存到镜像层）
# ============================================================================

FROM rust:1.82-slim AS base

# 构建参数：镜像源配置
ARG CARGO_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git
ARG RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup

# 安装系统依赖（构建 openssl, postgresql 等原生 crate 需要）
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# 配置 cargo 镜像源
RUN mkdir -p /usr/local/cargo \
    && cat > /usr/local/cargo/config.toml << EOF
[source.tuna]
registry = "${CARGO_MIRROR}"

[source.crates-io]
replace-with = "tuna"

[build]
jobs = 2

[profile.release]
codegen-units = 1
lto = "thin"
EOF

# ============================================================
# 预编译常用依赖（空项目触发编译，结果缓存到镜像层）
# ============================================================
WORKDIR /tmp/deps-cache

# 第1步：创建空项目
RUN cargo init --name deps-cache

# 第2步：写入常用依赖到 Cargo.toml
RUN cat > Cargo.toml << 'EOF'
[package]
name = "deps-cache"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["full"] }
axum = "0.7"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres", "chrono"] }
chrono = { version = "0.4", features = ["serde"] }
thiserror = "2"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
clap = { version = "4", features = ["derive"] }
anyhow = "1"
uuid = { version = "1", features = ["v4", "serde"] }
reqwest = { version = "0.12", features = ["json"] }
dotenvy = "0.15"
EOF

# 第3步：创建 dummy main.rs 触发依赖编译
RUN cat > src/main.rs << 'EOF'
fn main() {
    println!("deps-cache: dependencies compiled and cached");
}
EOF

# 第4步：编译依赖（debug 模式缓存，release 可另加一层）
RUN CARGO_BUILD_JOBS=2 cargo build 2>&1 || true

# 第5步：也编译 release 模式依赖
RUN CARGO_BUILD_JOBS=2 cargo build --release 2>&1 || true

# 清理编译产物但保留依赖缓存
RUN rm -rf /tmp/deps-cache/target/debug/deps_cache* \
    && rm -rf /tmp/deps-cache/target/release/deps_cache* \
    && rm -rf /tmp/deps-cache/target/debug/.fingerprint/deps-cache* \
    && rm -rf /tmp/deps-cache/target/release/.fingerprint/deps-cache* \
    && rm -rf /tmp/deps-cache/target/debug/incremental \
    && rm -rf /tmp/deps-cache/target/release/incremental

# ============================================================
# 最终镜像
# ============================================================
FROM base AS final

# 复制依赖缓存
COPY --from=base /tmp/deps-cache/target /tmp/deps-cache/target

# 工作目录
WORKDIR /app

# 默认命令
CMD ["bash"]
