#!/bin/bash
# 目录锁 v1.0
# 用法：
#   bash scripts/dir-lock.sh lock <目录路径> <角色名> [session_id] [修改文件列表]  — 加锁
#   bash scripts/dir-lock.sh unlock <目录路径> [角色名]                             — 解锁
#   bash scripts/dir-lock.sh check <目录路径>                                       — 检查锁状态
#   bash scripts/dir-lock.sh list                                                   — 列出所有目录锁
#   bash scripts/dir-lock.sh clean                                                  — 清理过期锁(>30min)
#   bash scripts/dir-lock.sh add-file <目录路径> <文件路径>                          — 添加修改中文件
#
# 功能：多智能体并发操作时保护目录，防止同时修改同一目录下的文件
# 锁文件格式：目录下 .目录锁 文件，含角色名+sessionID+时间+修改文件列表

LOCK_FILE=".目录锁"
LOCK_TIMEOUT=1800
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

ACTION="${1:?用法: $0 lock|unlock|check|list|clean|add-file <目录路径> [角色名] [session_id] [文件列表]}"
DIR_PATH="${2:-}"
ROLE="${3:-}"
SESSION="${4:-}"
FILE_LIST="${5:-}"

# 确保路径不以/结尾
DIR_PATH="${DIR_PATH%/}"

is_expired() {
    local lock_path="$1"
    [ ! -f "$lock_path" ] && return 0
    local lock_time=$(grep "^TIME:" "$lock_path" | cut -d: -f2-)
    [ -z "$lock_time" ] && return 0
    local lock_epoch=$(date -d "$lock_time" +%s 2>/dev/null || echo 0)
    local diff=$(( $(date +%s) - lock_epoch ))
    [ "$diff" -gt "$LOCK_TIMEOUT" ]
}

case "$ACTION" in
    lock)
        [ -z "$DIR_PATH" ] && echo "错误: 缺少目录路径" && exit 1
        [ -z "$ROLE" ] && echo "错误: 缺少角色名" && exit 1
        local_lock="$DIR_PATH/$LOCK_FILE"
        
        # 检查是否已过期
        if [ -f "$local_lock" ] && is_expired "$local_lock"; then
            rm -f "$local_lock"
        fi
        
        # 检查是否已被锁
        if [ -f "$local_lock" ]; then
            existing_role=$(grep "^ROLE:" "$local_lock" | cut -d: -f2)
            existing_session=$(grep "^SESSION:" "$local_lock" | cut -d: -f2)
            if [ "$existing_session" = "$SESSION" ]; then
                # 同一session，刷新锁
                :
            else
                echo "⚠️ 目录 $DIR_PATH 已被 $existing_role 锁定"
                echo "锁定时间: $(grep '^TIME:' "$local_lock" | cut -d: -f2-)"
                echo "修改中文件: $(grep '^FILES:' "$local_lock" | cut -d: -f2-)"
                exit 1
            fi
        fi
        
        # 加锁
        cat > "$local_lock" << EOF
ROLE:${ROLE}
SESSION:${SESSION:-unknown}
TIME:$(date '+%Y-%m-%d %H:%M:%S')
FILES:${FILE_LIST:-none}
EOF
        echo "✅ 已锁定 $DIR_PATH (角色: $ROLE)"
        ;;
    
    unlock)
        [ -z "$DIR_PATH" ] && echo "错误: 缺少目录路径" && exit 1
        local_lock="$DIR_PATH/$LOCK_FILE"
        if [ -f "$local_lock" ]; then
            existing_role=$(grep "^ROLE:" "$local_lock" | cut -d: -f2)
            if [ -z "$ROLE" ] || [ "$existing_role" = "$ROLE" ]; then
                rm -f "$local_lock"
                echo "✅ 已解锁 $DIR_PATH"
            else
                echo "⚠️ 只能由 $existing_role 解锁，当前: $ROLE"
                exit 1
            fi
        else
            echo "ℹ️ $DIR_PATH 无锁"
        fi
        ;;
    
    check)
        [ -z "$DIR_PATH" ] && echo "错误: 缺少目录路径" && exit 1
        local_lock="$DIR_PATH/$LOCK_FILE"
        if [ -f "$local_lock" ] && ! is_expired "$local_lock"; then
            echo "🔒 $DIR_PATH 已被 $(grep '^ROLE:' "$local_lock" | cut -d: -f2) 锁定"
            echo "   时间: $(grep '^TIME:' "$local_lock" | cut -d: -f2-)"
            echo "   修改中: $(grep '^FILES:' "$local_lock" | cut -d: -f2-)"
            exit 0
        else
            echo "🔓 $DIR_PATH 未锁定"
            rm -f "$local_lock"  # 清理过期锁
            exit 1
        fi
        ;;
    
    list)
        echo "=== 活跃目录锁 ==="
        found=0
        for dir in 角色 技能 共享知识; do
            local_lock="$dir/$LOCK_FILE"
            if [ -f "$local_lock" ] && ! is_expired "$local_lock"; then
                role=$(grep '^ROLE:' "$local_lock" | cut -d: -f2)
                time=$(grep '^TIME:' "$local_lock" | cut -d: -f2-)
                files=$(grep '^FILES:' "$local_lock" | cut -d: -f2-)
                echo "  🔒 $dir → $role ($time) 修改中: $files"
                found=1
            fi
        done
        # 也检查项目目录
        for dir in 项目/*/; do
            local_lock="$dir/$LOCK_FILE"
            if [ -f "$local_lock" ] && ! is_expired "$local_lock"; then
                role=$(grep '^ROLE:' "$local_lock" | cut -d: -f2)
                time=$(grep '^TIME:' "$local_lock" | cut -d: -f2-)
                echo "  🔒 $dir → $role ($time)"
                found=1
            fi
        done
        [ "$found" -eq 0 ] && echo "  (无活跃锁)"
        ;;
    
    clean)
        cleaned=0
        for dir in 角色 技能 共享知识 项目; do
            if [ -d "$dir" ]; then
                find "$dir" -name "$LOCK_FILE" | while read local_lock; do
                    if is_expired "$local_lock"; then
                        rm -f "$local_lock"
                        echo "  🧹 已清理过期锁: $local_lock"
                        cleaned=1
                    fi
                done
            fi
        done
        [ "$cleaned" -eq 0 ] && echo "  无过期锁"
        ;;
    
    add-file)
        [ -z "$DIR_PATH" ] && echo "错误: 缺少目录路径" && exit 1
        [ -z "$FILE_LIST" ] && echo "错误: 缺少文件路径" && exit 1
        local_lock="$DIR_PATH/$LOCK_FILE"
        if [ -f "$local_lock" ]; then
            existing_files=$(grep '^FILES:' "$local_lock" | cut -d: -f2-)
            if [ "$existing_files" = "none" ]; then
                new_files="$FILE_LIST"
            else
                new_files="$existing_files,$FILE_LIST"
            fi
            sed -i "s/^FILES:.*/FILES:$new_files/" "$local_lock"
            echo "✅ 已添加修改文件: $FILE_LIST"
        else
            echo "⚠️ 目录未锁定，请先lock"
            exit 1
        fi
        ;;
    
    *)
        echo "未知操作: $ACTION"
        echo "支持: lock|unlock|check|list|clean|add-file"
        exit 1
        ;;
esac
