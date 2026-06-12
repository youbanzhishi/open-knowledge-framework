#!/bin/bash
# 自动化协作循环引擎 v4.0
# 扫描工单 → 直接处理 → 工单流转
#
# 使用方式：
#   bash scripts/auto-collab-loop.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

QUEUE_FILE="/tmp/任务队列.md"
LOG_FILE="/tmp/auto-collab-loop.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ── 第1步：拉取最新 ──
log "📥 拉取最新仓库..."
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master)
if [ "$LOCAL" != "$REMOTE" ]; then
    git pull origin master --no-rebase
    log "✅ 已更新到最新"
else
    log "✅ 已是最新"
fi

# ── 第2步：扫描工单 ──
log "📋 扫描待处理工单..."

WO_DIR="$REPO_DIR/交接台/工单"
declare -a PENDING_WOS=()

for wo_file in "$WO_DIR"/WO-*.md; do
    [ -f "$wo_file" ] || continue
    
    # 检查状态
    status_line=$(grep "^## 状态" -A1 "$wo_file" 2>/dev/null | tail -1 || grep "状态" "$wo_file" | head -1)
    if echo "$status_line" | grep -qE "已完成|✅"; then
        continue
    fi
    
    role=$(grep "接收角色" "$wo_file" | grep -oP '(?<=[|：])\s*[^\s|]+(?=\s*[|：])' | head -1)
    priority=$(grep "优先级" "$wo_file" | grep -oP 'P\d' | head -1 || echo "P3")
    
    [ -z "$role" ] && continue
    
    PENDING_WOS+=("$priority|$role|$(basename "$wo_file")")
done

# 按优先级排序
IFS=$'\n' sorted=($(sort <<<"${PENDING_WOS[*]}")); unset IFS

if [ ${#sorted[@]} -eq 0 ]; then
    log "✅ 无待处理工单"
    rm -f "$QUEUE_FILE"
    exit 0
fi

log "📊 发现 ${#sorted[@]} 个待处理工单"

# ── 第3步：写入任务队列 ──
# 工单状态改为处理中
for item in "${sorted[@]}"; do
    wo_file=$(echo "$item" | cut -d'|' -f3)
    wo_path="$WO_DIR/$wo_file"
    if [ -f "$wo_path" ]; then
        sed -i 's/状态.*⏳待领取/状态 🔧处理中/' "$wo_path" 2>/dev/null || true
        sed -i 's/状态.*🟡 待领单/状态 🔧处理中/' "$wo_path" 2>/dev/null || true
    fi
done

# 写入队列文件（供主动检查）
cat > "$QUEUE_FILE" << EOF
## 待处理任务队列

### 发现时间
$(date '+%Y-%m-%d %H:%M:%S')

### 工单列表
EOF

for item in "${sorted[@]}"; do
    priority=$(echo "$item" | cut -d'|' -f1)
    role=$(echo "$item" | cut -d'|' -f2)
    wo_file=$(echo "$item" | cut -d'|' -f3)
    
    echo "- **[$role]** $wo_file (优先级: $priority)" >> "$QUEUE_FILE"
    log "   - [$role] $wo_file"
done

log ""
log "✅ 扫描完成，${#sorted[@]} 个工单已标记处理中"
log "📝 任务队列: $QUEUE_FILE"
log ""
log "👉 下一步：执行任务后更新状态"
