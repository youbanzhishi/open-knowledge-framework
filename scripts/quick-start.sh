#!/bin/bash
# OpenClaw Framework 一键安装脚本（无交互版，适合智能体调用）
# 用法：bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/main/scripts/quick-start.sh) [平台名] [智能体名] [角色定位]
# 最简用法：bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/main/scripts/quick-start.sh)
#
# 智能体调用示例（curl一条命令接入）：
#   bash <(curl -sSL https://raw.githubusercontent.com/youbanzhishi/open-knowledge-framework/main/scripts/quick-start.sh) 扣子 我的助手 管家

set -euo pipefail

REPO_URL="https://github.com/youbanzhishi/open-knowledge-framework.git"
DIR_NAME="open-knowledge-framework"

PLATFORM="${1:-本地}"
AGENT_NAME="${2:-我的智能体}"
AGENT_ROLE="${3:-助手}"

# ═══ 克隆 ═══
if [ -d "$DIR_NAME" ]; then
    cd "$DIR_NAME"
    git pull --no-rebase origin master 2>/dev/null || git pull --no-rebase origin main 2>/dev/null || true
else
    git clone "$REPO_URL" "$DIR_NAME"
    cd "$DIR_NAME"
fi

# ═══ 身份定制 ═══
if [ ! -f "基础设定/SOUL.md" ]; then
    cp "基础设定/SOUL-TEMPLATE.md" "基础设定/SOUL.md"
    sed -i "s/\[你的智能体名称\]/$AGENT_NAME/g" "基础设定/SOUL.md"
    sed -i "s/\[角色定位\]/$AGENT_ROLE/g" "基础设定/SOUL.md"
    sed -i "s/\[主人的称呼\]/主人/g" "基础设定/SOUL.md"
    sed -i "s/\[一句话描述核心价值\]/让主人的生活和工作更顺畅，少操心琐事，多专注重要的事/g" "基础设定/SOUL.md"
fi

[ ! -f "基础设定/USER.md" ] && cp "基础设定/USER-TEMPLATE.md" "基础设定/USER.md"
[ ! -f "基础设定/MEMORY.md" ] && cp "基础设定/MEMORY-TEMPLATE.md" "基础设定/MEMORY.md"

# ═══ 初始化 ═══
[ -f "scripts/init.sh" ] && bash scripts/init.sh "$PLATFORM" 2>&1 || true

echo ""
echo "✅ OpenClaw Framework 安装完成！"
echo "📖 第一步：cat 入口.md"
echo "⚡ 五步门：读 → 做 → 验 → 反哺 → 汇报"
