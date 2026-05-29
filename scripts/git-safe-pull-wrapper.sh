#!/bin/bash
# git-safe-pull wrapper v1.0
# 功能：拦截 git pull，未commit的变更必须先提交才能pull
# 安装：放入PATH，设置环境变量 GIT_SAFE_PULL=1 启用
# 原理：通过shell alias或PATH优先级，让git pull实际走本脚本

set -euo pipefail

# ═══ 环境变量检查 ═══
if [ "${GIT_SAFE_PULL:-0}" != "1" ]; then
    # 未启用安全模式，直接透传给原生git
    exec git "$@"
fi

# ═══ 拦截git pull ═══
if [ "${1:-}" = "pull" ]; then
    REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    cd "$REPO_DIR" 2>/dev/null || true
    
    # 检查未暂存变更
    UNSTAGED=$(git diff --name-only 2>/dev/null | grep -v '^$' || true)
    # 检查已暂存未提交变更
    STAGED=$(git diff --cached --name-only 2>/dev/null | grep -v '^$' || true)
    
    if [ -n "$UNSTAGED" ] || [ -n "$STAGED" ]; then
        echo ""
        echo "═══════════════════════════════════════════"
        echo "🚫 安全拦截：本地有未提交的变更，禁止pull！"
        echo "═══════════════════════════════════════════"
        echo ""
        
        [ -n "$STAGED" ] && echo "  已暂存未提交：" && echo "$STAGED" | head -5 | while read -r f; do echo "    - $f"; done
        [ -n "$UNSTAGED" ] && echo "  未暂存变更：" && echo "$UNSTAGED" | head -5 | while read -r f; do echo "    - $f"; done
        
        echo ""
        echo "  正确流程："
        echo "    1. git add <文件>"
        echo "    2. git commit -m '描述'"
        echo "    3. bash scripts/safe-pull.sh    # 或 git pull"
        echo ""
        exit 1
    fi
    
    # 本地干净，允许pull
    echo "✅ 本地无未提交变更，允许pull"
fi

# 透传给原生git
exec git "$@"
