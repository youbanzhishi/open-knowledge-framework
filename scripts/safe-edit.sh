#!/bin/bash
# 安全编辑包装器 v1.0
# 用法：bash scripts/safe-edit.sh <文件路径> <角色名> [session_id]
#
# 功能：检查锁→加锁→记录hash→输出编辑指引→编辑完需手动unlock

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

FILE_PATH="${1:?用法: $0 <文件路径> <角色名> [session_id]}"
ROLE="${2:?请指定角色名}"
SESSION="${3:-unknown}"

SHARED_FILES=("体系优化追踪.md" "热更新.md" "MEMORY.md" "入口.md" "入口-快速启动.md" "知识体系使用指南.md" "蓝图.md")

is_shared_file() {
    local f="$1"
    for sf in "${SHARED_FILES[@]}"; do [ "$(basename "$f")" = "$sf" ] && return 0; done
    [[ "$f" == 共享知识/* ]] || [[ "$f" == ./共享知识/* ]] && return 0
    [[ "$f" == 交接台/* ]] || [[ "$f" == ./交接台/* ]] && return 0
    return 1
}

echo "════════════════════════════════════"
echo "🔐 安全编辑检查"
echo "════════════════════════════════════"
echo "文件: $FILE_PATH | 角色: $ROLE"

# Step 1: 检查锁
LOCK_STATUS=0; bash scripts/edit-lock.sh check "$FILE_PATH" 2>/dev/null || LOCK_STATUS=$?
if [ "$LOCK_STATUS" -ne 0 ]; then
    echo "❌ 文件已被锁定，无法编辑！"; exit 1
fi

# Step 2: 加锁
bash scripts/edit-lock.sh lock "$FILE_PATH" "$ROLE" "$SESSION" || { echo "❌ 加锁失败"; exit 1; }

# Step 3: 快照
if [ -f "$FILE_PATH" ]; then
    BEFORE_HASH=$(md5sum "$FILE_PATH" 2>/dev/null | cut -d' ' -f1)
    BEFORE_LINES=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
    echo "✅ 快照: hash=${BEFORE_HASH:0:12}... 行数=$BEFORE_LINES"
else
    echo "⚠️ 新文件"
fi

# Step 4: 编辑指引
echo "════════════════════════════════════"
if is_shared_file "$FILE_PATH"; then
    echo "🔴 高频共享文件 — 必须用 edit_file 增量修改，编辑完必须解锁:"
else
    echo "🟢 角色私有文件 — 编辑完解锁:"
fi
echo "   bash scripts/edit-lock.sh unlock $FILE_PATH $ROLE"
echo "════════════════════════════════════"
echo "✅ 可以开始编辑"
