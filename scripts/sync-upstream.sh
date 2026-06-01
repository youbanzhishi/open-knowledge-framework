#!/bin/bash
# sync-upstream.sh - 从上游框架仓库同步更新
# 用法：cd open-knowledge-framework && bash scripts/sync-upstream.sh
# 前提：通过fork模式安装，已配置upstream remote

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# 检查upstream remote
if ! git remote get-url upstream &>/dev/null; then
  echo "❌ 未找到 upstream remote"
  echo "💡 请先执行: git remote add upstream https://github.com/youbanzhishi/open-knowledge-framework.git"
  exit 1
fi

echo "🔍 检查上游更新..."
git fetch upstream

# 比较差异
LOCAL_HEAD=$(git rev-parse HEAD)
UPSTREAM_HEAD=$(git rev-parse upstream/main)

if [ "$LOCAL_HEAD" = "$UPSTREAM_HEAD" ]; then
  echo "✅ 已是最新，无需同步"
  exit 0
fi

echo "📋 上游变更："
git log --oneline HEAD..upstream/main | head -20

echo ""
echo "🔄 合并上游更新..."
echo "   策略：优先保留你的定制（yours），冲突文件会逐个提示"
echo ""

# 使用merge，冲突时默认保留用户版本
if git merge upstream/main --no-edit 2>/dev/null; then
  echo "✅ 同步成功，无冲突！"
else
  echo "⚠️ 有冲突需要解决："
  CONFLICTS=$(git diff --name-only --diff-filter=U)
  for file in $CONFLICTS; do
    echo ""
    echo "📄 冲突文件: $file"
    echo "   y = 保留你的版本"
    echo "   u = 使用框架版本"  
    echo "   m = 手动解决(暂停)"
    read -p "   选择 [y/u/m]: " choice
    case "$choice" in
      y) git checkout --ours "$file" && git add "$file" && echo "   ✅ 保留你的版本" ;;
      u) git checkout --theirs "$file" && git add "$file" && echo "   ✅ 使用框架版本" ;;
      m) echo "   ⏸️ 请手动解决后: git add $file && git commit" ; exit 0 ;;
      *) git checkout --ours "$file" && git add "$file" && echo "   ✅ 默认保留你的版本" ;;
    esac
  done
  git commit --no-edit 2>/dev/null || true
  echo "✅ 冲突已解决，同步完成！"
fi

echo ""
echo "📊 同步摘要："
echo "   上游版本: $(git log --oneline -1 upstream/main)"
echo "   当前版本: $(git log --oneline -1 HEAD)"
echo ""
echo "💡 别忘了: git push origin main"
