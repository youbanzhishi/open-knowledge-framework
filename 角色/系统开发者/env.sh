#!/bin/bash
# 系统开发者 - 角色专属环境配置

# Rust 编译优化
export CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS:-2}
export CARGO_TARGET_DIR=${CARGO_TARGET_DIR:-/tmp/cargo-target}

# OpenDAW 路径
export OPENDAW_DIR=${OPENDAW_DIR:-/opt/opendaw}
export OPENFORGE_DIR=${OPENFORGE_DIR:-/opt/open-forge}

# 常用路径
export PROJECTS_DIR="$REPO_DIR/项目"

echo "  🔧 CARGO_BUILD_JOBS=$CARGO_BUILD_JOBS"
echo "  🔧 OPENDAW_DIR=$OPENDAW_DIR"
echo "  🔧 OPENFORGE_DIR=$OPENFORGE_DIR"
