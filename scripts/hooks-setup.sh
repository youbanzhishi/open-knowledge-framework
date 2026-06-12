#!/bin/bash
# Git hooks一键安装脚本
# 用法：bash scripts/setup-hooks.sh
# 功能：配置git使用本地hooks目录

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "🔧 安装Git hooks..."

# 配置git使用本地hooks目录
git config core.hooksPath .githooks

# 确保所有hook可执行
chmod +x .githooks/pre-commit
chmod +x .githooks/commit-msg 2>/dev/null
chmod +x .githooks/pre-push 2>/dev/null

echo "✅ Git hooks已安装"
echo "   hooks目录: $(pwd)/.githooks/"
echo "   当前active hook: $(git config core.hooksPath)"
echo "   已安装: $(ls .githooks/ | grep -v README)"
