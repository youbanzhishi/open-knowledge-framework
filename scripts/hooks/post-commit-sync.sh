#!/bin/bash
# post-commit-sync.sh - 私有仓库commit后自动触发框架同步
# 安装：cp scripts/hooks/post-commit-sync.sh .git/hooks/post-commit
# 触发条件：白名单文件有变更

WHITELIST_PATTERNS=(
  "共享知识/"
  "角色/"
  "templates/"
  "入口.md"
  "知识体系使用指南.md"
  "README.md"
  "START.md"
  "scripts/"
  ".well-known/"
  "docs/"
)

# 检查最近一次commit涉及的文件
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null)

SHOULD_SYNC=0
for pattern in "${WHITELIST_PATTERNS[@]}"; do
  if echo "$CHANGED_FILES" | grep -q "^$pattern"; then
    SHOULD_SYNC=1
    echo "📦 检测到框架文件变更: $pattern"
    break
  fi
done

if [ "$SHOULD_SYNC" = "1" ]; then
  echo "🔄 框架文件有变更，触发同步到公开仓库..."
  SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
  if [ -f "$SCRIPT_DIR/scripts/sync-public.sh" ]; then
    bash "$SCRIPT_DIR/scripts/sync-public.sh" 2>&1 | tail -5
  else
    echo "⚠️ sync-public.sh 未找到，跳过自动同步"
  fi
else
  echo "ℹ️ 本次提交不涉及框架文件，跳过同步"
fi
