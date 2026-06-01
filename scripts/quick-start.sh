#!/bin/bash
# OpenClaw Framework 一键安装脚本（无交互版，适合智能体调用）
# 用法：
#   直接模式：bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh) [平台名] [智能体名] [角色定位]
#   最简用法：bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh)
#   Fork模式：bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh) fork <你的GitHub用户名> [智能体名] [角色定位]
#
# 智能体调用示例（curl一条命令接入）：
#   bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh) 扣子 我的助手 管家
#   bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/refs/heads/main/scripts/quick-start.sh) fork zhangsan 我的助手 管家

set -euo pipefail

UPSTREAM_REPO="youbanzhishi/open-knowledge-framework"
REPO_URL="https://github.com/$UPSTREAM_REPO.git"

# ═══ Fork 模式 ═══
if [ "$1" = "fork" ]; then
  GITHUB_USER="${2:-}"
  AGENT_NAME="${3:-我的智能体}"
  AGENT_ROLE="${4:-助手}"
  DIR_NAME="open-knowledge-framework"

  if [ -z "$GITHUB_USER" ]; then
    echo "❌ fork模式需要指定GitHub用户名"
    echo "用法：bash quick-start.sh fork <你的GitHub用户名> [智能体名] [角色定位]"
    exit 1
  fi

  FORK_REPO="$GITHUB_USER/open-knowledge-framework"
  
  echo "🍴 Fork模式安装"
  echo "   上游仓库: https://github.com/$UPSTREAM_REPO"
  echo "   目标仓库: https://github.com/$FORK_REPO"
  echo ""

  # 1. Fork仓库（如果还没fork，API会自动处理）
  echo "📡 检查Fork状态..."
  GITHUB_TOKEN="${GITHUB_TOKEN:-}"
  if [ -n "$GITHUB_TOKEN" ]; then
    FORK_CHECK=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$FORK_REPO" 2>/dev/null || echo "")
    if echo "$FORK_CHECK" | grep -q '"full_name"'; then
      echo "✅ Fork已存在"
    else
      echo "🍴 正在创建Fork..."
      curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$UPSTREAM_REPO/forks" | grep -q '"full_name"' || true
      echo "✅ Fork请求已发送（GitHub后台处理中）"
    fi
  else
    echo "⚠️ 未设置 GITHUB_TOKEN，跳过API检查"
    echo "💡 如需自动Fork，请设置环境变量: export GITHUB_TOKEN=你的token"
  fi

  # 2. Clone用户的fork
  echo ""
  echo "📥 Clone你的Fork仓库..."
  if [ -d "$DIR_NAME" ]; then
    cd "$DIR_NAME"
    echo "   目录已存在，切换到现有目录"
  else
    if git clone "https://github.com/$FORK_REPO.git" "$DIR_NAME" 2>/dev/null; then
      cd "$DIR_NAME"
    else
      echo "❌ Clone失败，请检查："
      echo "   1. 你是否已在GitHub上Fork了仓库"
      echo "   2. GitHub用户名是否正确: $GITHUB_USER"
      echo "   3. 仓库是否公开"
      exit 1
    fi
  fi

  # 3. 添加upstream remote
  echo ""
  echo "🔗 配置上游仓库..."
  if git remote get-url upstream &>/dev/null; then
    echo "✅ upstream remote 已存在"
  else
    git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
    git remote set-url --push upstream DISABLE
    echo "✅ upstream remote 已添加（禁止push到上游）"
  fi

  # 4. 模板替换
  echo ""
  echo "🎨 定制智能体身份..."
  if [ ! -f "基础设定/SOUL.md" ]; then
    cp "基础设定/SOUL-TEMPLATE.md" "基础设定/SOUL.md"
    sed -i "s/\[你的智能体名称\]/$AGENT_NAME/g" "基础设定/SOUL.md"
    sed -i "s/\[角色定位\]/$AGENT_ROLE/g" "基础设定/SOUL.md"
    sed -i "s/\[主人的称呼\]/主人/g" "基础设定/SOUL.md"
    sed -i "s/\[一句话描述核心价值\]/让主人的生活和工作更顺畅，少操心琐事，多专注重要的事/g" "基础设定/SOUL.md"
    echo "   ✅ SOUL.md 已定制"
  else
    echo "   ⏭️ SOUL.md 已存在，跳过"
  fi

  if [ ! -f "基础设定/USER.md" ]; then
    cp "基础设定/USER-TEMPLATE.md" "基础设定/USER.md"
    echo "   ✅ USER.md 已创建"
  else
    echo "   ⏭️ USER.md 已存在，跳过"
  fi

  if [ ! -f "基础设定/MEMORY.md" ]; then
    cp "基础设定/MEMORY-TEMPLATE.md" "基础设定/MEMORY.md"
    echo "   ✅ MEMORY.md 已创建"
  else
    echo "   ⏭️ MEMORY.md 已存在，跳过"
  fi

  echo ""
  echo "✅ Fork安装完成！"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 你的仓库: https://github.com/$FORK_REPO"
  echo "📖 入门指引: cat 入口.md"
  echo ""
  echo "🔄 获取框架更新（定期执行）:"
  echo "   bash scripts/sync-upstream.sh"
  echo ""
  echo "💡 下一步:"
  echo "   1. git add . && git commit -m '初始化我的智能体'"
  echo "   2. git push origin main"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# ═══ 直接Clone模式（原逻辑） ═══
PLATFORM="${1:-本地}"
AGENT_NAME="${2:-我的智能体}"
AGENT_ROLE="${3:-助手}"
DIR_NAME="open-knowledge-framework"

# 克隆
if [ -d "$DIR_NAME" ]; then
    cd "$DIR_NAME"
    echo "📦 目录已存在，拉取最新..."
    git pull --no-rebase origin master 2>/dev/null || git pull --no-rebase origin main 2>/dev/null || true
else
    git clone "$REPO_URL" "$DIR_NAME"
    cd "$DIR_NAME"
fi

# 身份定制
if [ ! -f "基础设定/SOUL.md" ]; then
    cp "基础设定/SOUL-TEMPLATE.md" "基础设定/SOUL.md"
    sed -i "s/\[你的智能体名称\]/$AGENT_NAME/g" "基础设定/SOUL.md"
    sed -i "s/\[角色定位\]/$AGENT_ROLE/g" "基础设定/SOUL.md"
    sed -i "s/\[主人的称呼\]/主人/g" "基础设定/SOUL.md"
    sed -i "s/\[一句话描述核心价值\]/让主人的生活和工作更顺畅，少操心琐事，多专注重要的事/g" "基础设定/SOUL.md"
fi

[ ! -f "基础设定/USER.md" ] && cp "基础设定/USER-TEMPLATE.md" "基础设定/USER.md"
[ ! -f "基础设定/MEMORY.md" ] && cp "基础设定/MEMORY-TEMPLATE.md" "基础设定/MEMORY.md"

# 初始化
[ -f "scripts/init.sh" ] && bash scripts/init.sh "$PLATFORM" 2>&1 || true

echo ""
echo "✅ OpenClaw Framework 安装完成！"
echo "📖 第一步：cat 入口.md"
echo "⚡ 五步门：读 → 做 → 验 → 反哺 → 汇报"
