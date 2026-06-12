#!/bin/bash
# Git hooks一键安装脚本 v2.0
# 用法：bash scripts/setup-hooks.sh
# 功能：配置git使用本地hooks目录 + 确保所有hook可执行
# v2.0: 新增commit-msg v2角色标识强制校验

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "🔧 安装Git hooks..."

# 配置git使用本地hooks目录
git config core.hooksPath .githooks

# 确保所有hook可执行
for hook in .githooks/pre-commit .githooks/commit-msg .githooks/pre-push; do
  if [ -f "$hook" ]; then
    chmod +x "$hook"
    echo "  ✅ $hook"
  else
    echo "  ⚠️ $hook 不存在"
  fi
done

# 写入当前角色标识（从git user.name提取，供commit-msg hook读取）
CURRENT_USER=$(git config user.name 2>/dev/null || echo "")
if [ -n "$CURRENT_USER" ]; then
  ROLE_NAME=$(echo "$CURRENT_USER" | sed 's/(.*)//' | tr -d '[:space:]')
  echo "$ROLE_NAME" > .git/current-role
  echo "  ✅ 当前角色: $ROLE_NAME (写入.git/current-role)"
fi

echo ""
echo "✅ Git hooks已安装"
echo "   hooks目录: $(pwd)/.githooks/"
echo "   当前active hook: $(git config core.hooksPath)"
echo ""
echo "   📋 已安装hook功能："
echo "   - pre-commit: 敏感文件检测 + token泄露检测 + OPT格式检查"
echo "   - commit-msg: 🔴强制[角色名]前缀 + OPT关联提醒"
echo "   - pre-push: 禁止强推 + 删除分支拦截 + 文件数骤降保护"
echo ""
echo "   💡 设置角色标识方式："
echo "     export GIT_ROLE=角色名       # 环境变量（推荐）"
echo "     echo '角色名' > .git/current-role  # 持久化文件"
