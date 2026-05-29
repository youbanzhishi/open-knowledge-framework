#!/bin/bash
# 安全拉取脚本 v1.0
# 用法：bash scripts/safe-pull.sh [remote] [branch]
# 铁律：pull前必须先commit本地变更，否则拒绝pull
# 原因：未commit就pull会触发merge/overwrite，可能丢失本地改动

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

REMOTE="${1:-origin}"
BRANCH="${2:-master}"

# ═══ 全局锁（与push.sh共用，防止同时push和pull） ═══
LOCK_FD=9
LOCK_FILE=".git/ops.lock"
LOCK_TIMEOUT=120
MY_NAME="safe-pull.sh"
exec 9>"$LOCK_FILE"
if ! flock -n $LOCK_FD; then
  HOLDER_INFO=$(cat "$LOCK_FILE" 2>/dev/null || echo "未知")
  HOLDER_NAME=$(echo "$HOLDER_INFO" | cut -d'|' -f1 | xargs)
  echo "🚧 $HOLDER_NAME 正在操作中，等待..."
  if ! flock -w $LOCK_TIMEOUT $LOCK_FD; then
    echo "⚠️ 等了${LOCK_TIMEOUT}秒还没轮到，可能卡住了"
    exit 1
  fi
fi
echo "$MY_NAME | PID:$$ | $(date '+%H:%M:%S')" >&9

cleanup() { rm -f .git/ops.lock 2>/dev/null; }
trap cleanup EXIT

# ═══ 核心检查：本地变更必须先commit ═══

echo "🔍 检查本地变更状态..."

# 检查未暂存变更
UNSTAGED=$(git diff --name-only 2>/dev/null | grep -v '^$' || true)
# 检查已暂存未提交变更
STAGED=$(git diff --cached --name-only 2>/dev/null | grep -v '^$' || true)
# 检查未追踪文件
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -v '^$' || true)

HAS_CHANGES=0

if [ -n "$UNSTAGED" ]; then
    echo ""
    echo "⚠️ 发现未暂存的变更："
    echo "$UNSTAGED" | head -10 | while read -r f; do echo "   - $f"; done
    UNSTAGED_COUNT=$(echo "$UNSTAGED" | wc -l | tr -d ' ')
    [ "$UNSTAGED_COUNT" -gt 10 ] && echo "   ... 共${UNSTAGED_COUNT}个文件"
    HAS_CHANGES=1
fi

if [ -n "$STAGED" ]; then
    echo ""
    echo "⚠️ 发现已暂存但未提交的变更："
    echo "$STAGED" | head -10 | while read -r f; do echo "   - $f"; done
    STAGED_COUNT=$(echo "$STAGED" | wc -l | tr -d ' ')
    [ "$STAGED_COUNT" -gt 10 ] && echo "   ... 共${STAGED_COUNT}个文件"
    HAS_CHANGES=1
fi

if [ "$HAS_CHANGES" -eq 1 ]; then
    echo ""
    echo "═══════════════════════════════════════"
    echo "❌ 拒绝pull！本地有未提交的变更"
    echo "═══════════════════════════════════════"
    echo ""
    echo "   原因：pull会触发merge，可能覆盖或丢失你的本地改动"
    echo "   教训：改了没推=没改！pull覆盖本地改动=白干"
    echo ""
    echo "   正确做法："
    echo "     1. 先提交本地变更："
    echo "        git add <改动的文件>"
    echo "        git commit -m '描述你的改动'"
    echo "     2. 再拉取："
    echo "        bash scripts/safe-pull.sh"
    echo "     3. 如有冲突，解决后推送："
    echo "        bash scripts/push.sh 'merge: 解决冲突'"
    echo ""
    exit 1
fi

# ═══ 检查是否有本地commit未推送 ═══
LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
REMOTE_SHA=$(git rev-parse "$REMOTE/$BRANCH" 2>/dev/null || echo "unknown")

if [ "$LOCAL" != "$REMOTE_SHA" ]; then
    # 本地有未推送的commit，需要先fetch看远程是否有更新
    echo "📡 本地有未推送的commit，检查远程是否也有更新..."
    git fetch "$REMOTE" 2>/dev/null || true
    NEW_REMOTE=$(git rev-parse "$REMOTE/$BRANCH" 2>/dev/null || echo "$REMOTE_SHA")
    
    if [ "$NEW_REMOTE" != "$REMOTE_SHA" ] && [ "$LOCAL" != "$NEW_REMOTE" ]; then
        echo ""
        echo "⚠️ 本地和远程都有新commit，pull会产生merge"
        echo "   本地: $LOCAL"
        echo "   远程: $NEW_REMOTE"
        echo ""
        echo "   建议先推送本地commit再pull："
        echo "     bash scripts/push.sh '你的改动描述'"
        echo "     bash scripts/safe-pull.sh"
        echo ""
        # 仍然允许pull，但给出警告
    fi
fi

# ═══ 执行pull ═══
echo "📥 拉取最新仓库..."
git pull "$REMOTE" "$BRANCH" --no-rebase 2>&1

# ═══ pull后检查：是否有冲突标记 ═══
CONFLICT_FOUND=0
while IFS= read -r f; do
    [ -z "$f" ] && continue
    if grep -q "^[[:space:]]*<<<<<<< " "$f" 2>/dev/null; then
        echo "🚨 冲突标记残留: $f"
        CONFLICT_FOUND=1
    fi
done < <(git diff --name-only HEAD~1..HEAD 2>/dev/null | head -50)

if [ "$CONFLICT_FOUND" -eq 1 ]; then
    echo ""
    echo "❌ pull后检测到冲突标记！请先解决再继续工作"
    echo "   解决后运行: bash scripts/push.sh 'merge: 解决冲突'"
fi

echo "✅ 拉取完成"
