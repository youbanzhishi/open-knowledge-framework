#!/bin/bash
# 新平台一键初始化脚本 v2.1
# 用法：cd open-knowledge-framework && bash scripts/init.sh [平台名]
#   平台名：扣子/元宝/云电脑/本地 （必填，用于git提交身份识别）
# 功能：配置git用户/token/remote/双推 + SSH密钥配置
# 幂等：已配置过会自动跳过，重复执行无副作用

# v2.2: SSH配置成功后自动switch+GIT_PAT从环境变量传入


set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# ═══ 全局锁（防止多智能体git操作并发竞争index.lock） ═══
LOCK_FD=9
LOCK_FILE=".git/ops.lock"
LOCK_TIMEOUT=120
MY_NAME="init.sh"
exec 9>"$LOCK_FILE"
if ! flock -n $LOCK_FD; then
  HOLDER_INFO=$(cat "$LOCK_FILE" 2>/dev/null || echo "未知")
  HOLDER_NAME=$(echo "$HOLDER_INFO" | cut -d'|' -f1 | xargs)
  HOLDER_TIME=$(echo "$HOLDER_INFO" | cut -d'|' -f3 | xargs)
  echo ""
  echo "🚧 前方有车！$HOLDER_NAME 正在操作中（开始于 $HOLDER_TIME），请耐心排队，很快就好~"
  echo ""
  if ! flock -w $LOCK_TIMEOUT $LOCK_FD; then
    echo "⚠️ 等了${LOCK_TIMEOUT}秒还没轮到我，可能前面卡住了"
    echo "   前面是谁：$HOLDER_INFO"
    echo "   排查：ps aux | grep git → 只杀自己的卡死进程 → rm .git/ops.lock"
    exit 1
  fi
  echo "✅ 轮到我了！init.sh 开始操作"
fi
echo "init.sh | PID:$$ | $(date '+%H:%M:%S')" >&9

GITHUB_USER="youbanzhishi"
GITEE_USER="hutio"
REPO_NAME="open-knowledge-framework"

# ── 平台身份映射 ──
PLATFORM="${1:-}"
if [ -z "$PLATFORM" ]; then
  echo "❌ 必须指定平台名"
  echo "用法：bash scripts/init.sh 扣子|元宝|云电脑|本地"
  echo ""
  echo "平台列表："
  echo "  扣子    → 小龙(扣子) <xiaolong_steward@coze.email>"
  echo "  元宝    → 小龙(元宝) <xiaolong_steward@coze.email>"
  echo "  云电脑  → 小龙(云电脑) <xiaolong_steward@coze.email>"
  echo "  本地    → 小龙(本地) <xiaolong_steward@coze.email>"
  exit 1
fi

case "$PLATFORM" in
  扣子)   GIT_NAME="小龙(扣子)";   GIT_EMAIL="xiaolong_steward@coze.email" ;;
  元宝)   GIT_NAME="小龙(元宝)";   GIT_EMAIL="xiaolong_steward@coze.email" ;;
  云电脑) GIT_NAME="小龙(云电脑)"; GIT_EMAIL="xiaolong_steward@coze.email" ;;
  本地)   GIT_NAME="小龙(本地)";   GIT_EMAIL="xiaolong_steward@coze.email" ;;
  *)      echo "❌ 未知平台：$PLATFORM"; echo "支持：扣子/元宝/云电脑/本地"; exit 1 ;;
esac

echo "=== 知识体系新平台初始化 ==="
echo "📱 平台：$PLATFORM"

# ── 1. Git用户配置 ──
echo "🔧 配置git用户（$PLATFORM）..."
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

# ── 2. GitHub remote + pushurl ──
if [ -z "$GITHUB_PAT" ]; then
  echo "📝 请输入GitHub PAT令牌（从平台SECRET.md获取）："
  read -s GITHUB_PAT
fi

echo "🔧 配置GitHub remote（拉取+推送）..."
REPO_URL="https://${GITHUB_PAT}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
git remote set-url origin "$REPO_URL"

# 配置GitHub pushurl（双推基础：必须显式添加，否则--add --push会替换默认行为）
# 先清除旧的pushurl配置
git remote set-url --delete --push origin "https://${GITHUB_PAT}@github.com/${GITHUB_USER}/${REPO_NAME}.git" 2>/dev/null || true
# 添加GitHub pushurl
git remote set-url --add --push origin "https://${GITHUB_PAT}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

# ── 3. Gitee双推配置（可选）──
# 🔴 铁律：Gitee所有仓库必须私有！
if [ -n "$GITEE_PAT" ]; then
  echo "🔧 配置Gitee双推..."
  git remote set-url --add --push origin "https://${GITEE_USER}:${GITEE_PAT}@gitee.com/${GITEE_USER}/${REPO_NAME}.git"
  echo "✅ Gitee双推已配置"
elif [ -f ".gitee-configured" ]; then
  echo "ℹ️  Gitee双推已配置过（标记文件存在）"
else
  echo ""
  echo "💡 是否配置Gitee双推？（y/n，默认n）"
  echo "   双推=一条push同时推GitHub和Gitee，拉取只走GitHub"
  echo "   🔴 铁律：Gitee所有仓库必须私有！"
  read -r SETUP_GITEE
  if [ "$SETUP_GITEE" = "y" ] || [ "$SETUP_GITEE" = "Y" ]; then
    echo "📝 请输入Gitee PAT令牌："
    read -s GITEE_PAT_INPUT
    if [ -n "$GITEE_PAT_INPUT" ]; then
      git remote set-url --add --push origin "https://${GITEE_USER}:${GITEE_PAT_INPUT}@gitee.com/${GITEE_USER}/${REPO_NAME}.git"
      touch .gitee-configured
      echo "✅ Gitee双推已配置"
    else
      echo "⏭️  跳过Gitee配置（未输入token）"
    fi
  else
    echo "⏭️  跳过Gitee配置（后续可用 GITEE_PAT=xxx bash scripts/init.sh 重新配置）"
  fi
fi

# ── 4. 禁止强推 ──
echo "🔧 配置禁止强推..."
git config receive.denyForceDeletes true
git config push.default current

# ── 5. 验证 ──
echo ""
echo "✅ 初始化完成："
echo "   用户：$(git config user.name) <$(git config user.email)>"
echo "   拉取：$(git remote get-url origin | sed 's/.*@/***@/')"
echo "   推送："
git remote get-url --push origin | while read -r url; do
  echo "     → $(echo "$url" | sed 's/.*@/***@/')"
done
echo ""

# ── 6. SSH密钥配置 ──
echo "🔧 配置SSH密钥..."

if GIT_PAT="$GITHUB_PAT" bash scripts/ssh-init.sh setup; then
  # SSH配置成功，切换remote到SSH模式
  echo "🔧 切换remote到SSH模式..."
  bash scripts/ssh-init.sh switch || echo "⚠️ SSH切换失败，将使用HTTPS模式"
else
  echo "⚠️ SSH配置跳过（密钥可能未加密存库），继续使用HTTPS模式"
fi


# ── 7. 安装git hooks ──
echo "🔧 安装Git hooks..."
bash scripts/setup-hooks.sh

# ── 8. 配置物理层安全拦截 ──
echo "🔧 配置物理层安全拦截（未commit禁止pull）..."

# 方法1：git alias（最可靠，git pull → 自动走safe-pull）
git config alias.pull "!bash scripts/safe-pull.sh"

# 方法2：环境变量（用于shell级别的git覆盖）
# 在 .bashrc 或当前shell中加入：export GIT_SAFE_PULL=1
# 并将 scripts/ 加入PATH 或创建 alias

# 方法3：将安全拦截写入 .bashrc（跨会话持久化）
BASHRC_LINE='export GIT_SAFE_PULL=1'
PROFILE_FILE="$HOME/.bashrc"
if [ -f "$PROFILE_FILE" ]; then
    if ! grep -q "GIT_SAFE_PULL" "$PROFILE_FILE" 2>/dev/null; then
        echo "" >> "$PROFILE_FILE"
        echo "# 知识体系安全拦截：未commit禁止pull" >> "$PROFILE_FILE"
        echo "$BASHRC_LINE" >> "$PROFILE_FILE"
        echo "✅ 环境变量已写入 $PROFILE_FILE"
    else
        echo "ℹ️  环境变量已存在"
    fi
fi

# shell function覆盖（优先级最高，连 git pull 也会被拦截）
GIT_FUNC='git() { if [ "$1" = "pull" ] && [ "${GIT_SAFE_PULL:-0}" = "1" ]; then bash "$(git rev-parse --show-toplevel 2>/dev/null)/scripts/safe-pull.sh" "${@:2}"; else command git "$@"; fi; }'
if [ -f "$PROFILE_FILE" ]; then
    if ! grep -q "GIT_SAFE_PULL.*git()" "$PROFILE_FILE" 2>/dev/null && ! grep -q 'git().*GIT_SAFE_PULL' "$PROFILE_FILE" 2>/dev/null; then
        echo "" >> "$PROFILE_FILE"
        echo "# 知识体系安全拦截：覆盖git pull命令" >> "$PROFILE_FILE"
        echo "$GIT_FUNC" >> "$PROFILE_FILE"
        echo "✅ git function覆盖已写入 $PROFILE_FILE"
    else
        echo "ℹ️  git function覆盖已存在"
    fi
fi

export GIT_SAFE_PULL=1

echo "✅ 物理层安全拦截已配置："
echo "   - git alias.pull → safe-pull.sh（git pull 自动走安全检查）"
echo "   - 环境变量 GIT_SAFE_PULL=1（shell function级别拦截）"
echo "   - shell function覆盖 git()（最高优先级，连 git pull 也拦截）"

# ── 9. 重建搜索索引 ──
echo "🔧 重建搜索索引..."
bash scripts/rebuild-index.sh

echo ""
echo "🎉 初始化完成！现在可以使用 bash scripts/push.sh \"描述\" 推送代码"
echo "⚠️ 安全拦截已启用：git pull 前必须先 commit，否则会被拒绝"
