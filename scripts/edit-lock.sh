#!/bin/bash
# 文件编辑锁 v1.0
# 用法：
#   bash scripts/edit-lock.sh lock <文件路径> <角色名> [session_id]  — 加锁
#   bash scripts/edit-lock.sh unlock <文件路径> [角色名]             — 解锁
#   bash scripts/edit-lock.sh check <文件路径>                       — 检查锁状态
#   bash scripts/edit-lock.sh list                                   — 列出所有活跃锁
#   bash scripts/edit-lock.sh clean                                  — 清理过期锁（>30min）
#   bash scripts/edit-lock.sh verify <文件路径> <hash>               — 验证文件是否被改过
#
# 功能：防止多智能体同时编辑同一文件导致内容丢失
# 锁文件存 .git/edit-locks/ 目录，超时30分钟自动失效

LOCK_DIR=".git/edit-locks"
LOCK_TIMEOUT=1800
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"
mkdir -p "$LOCK_DIR"

ACTION="${1:?用法: $0 lock|unlock|check|list|clean|verify <文件路径> [角色名] [session_id]}"
FILE_PATH="${2:-}"
ROLE="${3:-}"
SESSION="${4:-}"

lock_name() {
    local p="$1"; p="${p#./}"; p="${p//\//__}"; echo "$p"
}

file_hash() {
    if [ -f "$1" ]; then md5sum "$1" 2>/dev/null | cut -d' ' -f1; else echo "FILE_NOT_EXIST"; fi
}

is_expired() {
    local lock_file="$1"
    local lock_time=$(cut -d'|' -f3 "$lock_file" 2>/dev/null)
    [ -z "$lock_time" ] && return 0
    local lock_epoch=$(date -d "$lock_time" +%s 2>/dev/null || echo 0)
    local diff=$(( $(date +%s) - lock_epoch ))
    [ "$diff" -gt "$LOCK_TIMEOUT" ]
}

case "$ACTION" in
    lock)
        [ -z "$FILE_PATH" ] || [ -z "$ROLE" ] && { echo "❌ 用法: $0 lock <文件路径> <角色名> [session_id]"; exit 1; }
        LOCK_FILE="$LOCK_DIR/$(lock_name "$FILE_PATH")"
        if [ -f "$LOCK_FILE" ]; then
            if is_expired "$LOCK_FILE"; then
                echo "🧹 锁已过期（持有者: $(cut -d'|' -f1 "$LOCK_FILE")），自动释放"
                rm -f "$LOCK_FILE"
            else
                HOLDER=$(cut -d'|' -f1 "$LOCK_FILE")
                if [ "$HOLDER" = "$ROLE" ]; then
                    HASH=$(file_hash "$FILE_PATH")
                    echo "$ROLE|${SESSION:-$(cut -d'|' -f2 "$LOCK_FILE")}|$(date '+%Y-%m-%d %H:%M:%S')|$HASH" > "$LOCK_FILE"
                    echo "🔄 续锁成功: $FILE_PATH (角色: $ROLE)"; exit 0
                fi
                echo "🚧 文件被锁: $FILE_PATH"
                echo "   持有者: $HOLDER | 时间: $(cut -d'|' -f3 "$LOCK_FILE")"
                echo "   处理: 等待释放 / 等30分钟自动释放 / 紧急: $0 unlock $FILE_PATH $HOLDER"
                exit 1
            fi
        fi
        HASH=$(file_hash "$FILE_PATH")
        echo "$ROLE|${SESSION:-unknown}|$(date '+%Y-%m-%d %H:%M:%S')|$HASH" > "$LOCK_FILE"
        echo "✅ 加锁成功: $FILE_PATH (角色: $ROLE, hash: ${HASH:0:8}...)"
        ;;
    unlock)
        [ -z "$FILE_PATH" ] && { echo "❌ 用法: $0 unlock <文件路径> [角色名]"; exit 1; }
        LOCK_FILE="$LOCK_DIR/$(lock_name "$FILE_PATH")"
        [ ! -f "$LOCK_FILE" ] && { echo "⚠️ 文件未加锁: $FILE_PATH"; exit 0; }
        HOLDER=$(cut -d'|' -f1 "$LOCK_FILE")
        if [ -n "$ROLE" ] && [ "$HOLDER" != "$ROLE" ]; then
            echo "⚠️ 锁持有者是 $HOLDER，不是 $ROLE。强制释放: $0 unlock $FILE_PATH $HOLDER"; exit 1
        fi
        rm -f "$LOCK_FILE"
        echo "🔓 解锁成功: $FILE_PATH (原持有者: $HOLDER)"
        ;;
    check)
        [ -z "$FILE_PATH" ] && { echo "❌ 用法: $0 check <文件路径>"; exit 1; }
        LOCK_FILE="$LOCK_DIR/$(lock_name "$FILE_PATH")"
        [ ! -f "$LOCK_FILE" ] && { echo "🟢 文件未加锁: $FILE_PATH"; exit 0; }
        if is_expired "$LOCK_FILE"; then
            echo "🟡 锁已过期: $FILE_PATH (持有者: $(cut -d'|' -f1 "$LOCK_FILE"))"; exit 0
        fi
        HOLDER=$(cut -d'|' -f1 "$LOCK_FILE"); HOLDER_TIME=$(cut -d'|' -f3 "$LOCK_FILE")
        LOCKED_HASH=$(cut -d'|' -f4 "$LOCK_FILE"); CURRENT_HASH=$(file_hash "$FILE_PATH")
        echo "🔴 文件已锁定: $FILE_PATH"
        echo "   持有者: $HOLDER | 时间: $HOLDER_TIME"
        [ "$LOCKED_HASH" != "$CURRENT_HASH" ] && echo "   ⚠️ 文件已被修改! 锁时hash: ${LOCKED_HASH:0:8}... 当前: ${CURRENT_HASH:0:8}..."
        exit 1
        ;;
    list)
        echo "📋 当前编辑锁:"; COUNT=0
        for lf in "$LOCK_DIR"/*; do
            [ -f "$lf" ] || continue; COUNT=$((COUNT+1))
            H=$(cut -d'|' -f1 "$lf"); T=$(cut -d'|' -f3 "$lf"); N=$(basename "$lf"); P="${N//__/\/}"
            EX=""; is_expired "$lf" && EX=" (已过期)"
            echo "   - $P → $H @ $T$EX"
        done
        [ "$COUNT" -eq 0 ] && echo "   (无活跃锁)"; echo "   共 $COUNT 个锁"
        ;;
    clean)
        echo "🧹 清理过期锁:"; COUNT=0
        for lf in "$LOCK_DIR"/*; do
            [ -f "$lf" ] || continue
            if is_expired "$lf"; then
                echo "   🗑️ 释放: ${lf##*/} (持有者: $(cut -d'|' -f1 "$lf"))"; rm -f "$lf"; COUNT=$((COUNT+1))
            fi
        done
        echo "   清理了 $COUNT 个过期锁"
        ;;
    verify)
        [ -z "$FILE_PATH" ] || [ -z "$ROLE" ] && { echo "❌ 用法: $0 verify <文件路径> <hash>"; exit 1; }
        LOCK_FILE="$LOCK_DIR/$(lock_name "$FILE_PATH")"; HASH_ARG="$ROLE"
        [ ! -f "$LOCK_FILE" ] && { echo "⚠️ 文件未加锁，无法验证"; exit 0; }
        LOCKED_HASH=$(cut -d'|' -f4 "$LOCK_FILE"); CURRENT_HASH=$(file_hash "$FILE_PATH")
        if [ "$LOCKED_HASH" = "$CURRENT_HASH" ]; then echo "✅ 文件未被修改: $FILE_PATH"; exit 0
        else echo "❌ 文件已被修改! 锁时: ${LOCKED_HASH:0:8}... 当前: ${CURRENT_HASH:0:8}..."; exit 1; fi
        ;;
    *) echo "❌ 未知操作: $ACTION"; echo "用法: $0 lock|unlock|check|list|clean|verify <文件路径> [角色名] [session_id]"; exit 1 ;;
esac
