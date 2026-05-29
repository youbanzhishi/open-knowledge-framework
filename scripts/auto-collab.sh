#!/bin/bash
# auto-collab.sh v4.0 — 自动化协作引擎辅助脚本
# 功能：封装协作引擎的机械操作，减少主agent的token消耗
# 用法：bash scripts/auto-collab.sh <命令> [参数]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HANDOVER_DIR="$REPO_DIR/交接台"
WO_DIR="$HANDOVER_DIR/工单"
BUG_DIR="$HANDOVER_DIR/bug单"
README="$HANDOVER_DIR/README.md"

# SSH密钥设置
SSH_KEY="${SSH_KEY:-/.ssh/id_rsa_github}"
if [ -f "$SSH_KEY" ]; then
    export GIT_SSH_COMMAND="ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
fi

case "${1:-help}" in

    pull)
        # Merge方式拉取最新代码（与push.sh一致，禁止rebase）
        echo "📦 拉取最新仓库..."
        cd "$REPO_DIR"
        
        # 解密SSH密钥
        if [ ! -f "$SSH_KEY" ]; then
            MASTER_KEY="${2:-}"
            if [ -z "$MASTER_KEY" ]; then
                # 尝试从环境变量获取
                MASTER_KEY="${MASTER_KEY_ENV:-}"
            fi
            if [ -n "$MASTER_KEY" ] && [ -f "$REPO_DIR/共享知识/凭据/decrypt.sh" ]; then
                GIT_PAT=$(bash "$REPO_DIR/共享知识/凭据/decrypt.sh" "$MASTER_KEY" github.pat 2>/dev/null || true)
                if [ -n "$GIT_PAT" ] && [ -f "$REPO_DIR/共享知识/凭据/ssh-key.enc" ]; then
                    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:${GIT_PAT}" \
                        -in "$REPO_DIR/共享知识/凭据/ssh-key.enc" -base64 2>/dev/null > /tmp/id_rsa_github
                    mkdir -p "$(dirname "$SSH_KEY")"
                    cp /tmp/id_rsa_github "$SSH_KEY" 2>/dev/null && chmod 600 "$SSH_KEY"
                    export GIT_SSH_COMMAND="ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
                fi
            fi
        fi
        
        git fetch origin 2>/dev/null || true
        LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        REMOTE=$(git rev-parse origin/master 2>/dev/null || echo "unknown")
        
        if [ "$LOCAL" = "$REMOTE" ]; then
            echo "✅ 已是最新: $LOCAL"
            exit 0
        fi
        
        # 使用merge方式，禁止rebase（与push.sh保持一致，防止多平台推拉内容丢失）
        if git pull --no-rebase origin master 2>&1; then
            echo "✅ 拉取成功: $LOCAL → $REMOTE"
        else
            # 检查是否有冲突
            if git diff --name-only --diff-filter=U 2>/dev/null | head -1 >/dev/null 2>&1; then
                echo "⛔ 合并冲突，需要人工处理"
                git merge --abort 2>/dev/null || true
                exit 1
            fi
            echo "❌ 拉取失败"
            exit 1
        fi
        ;;

    scan)
        # 扫描待领工单，输出精简队列
        echo "📋 扫描待领工单..."
        cd "$REPO_DIR"
        
        FOUND=0
        for f in "$WO_DIR"/WO-*.md; do
            [ -f "$f" ] || continue
            # 提取关键信息：编号、接收角色、优先级、状态
            WO_ID=$(basename "$f" .md | sed 's/WO-//' | cut -d'-' -f1)
            ROLE=$(grep -oP '接收角色[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "未知")
            PRIORITY=$(grep -oP '优先级[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "P2")
            STATUS=$(grep -oP '状态[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "未知")
            TITLE=$(head -1 "$f" | sed 's/^# //' | head -c 60)
            
            if echo "$STATUS" | grep -q "待领取"; then
                echo "WO-${WO_ID}|${PRIORITY}|${ROLE}|${TITLE}"
                FOUND=$((FOUND + 1))
            fi
        done
        
        if [ $FOUND -eq 0 ]; then
            echo "NO_WORKORDERS"
        else
            echo "TOTAL:${FOUND}"
        fi
        ;;

    status)
        # 更新工单状态：auto-collab.sh status WO-029 "🔧处理中"
        WO_NUM="${2:-}"
        NEW_STATUS="${3:-}"
        if [ -z "$WO_NUM" ] || [ -z "$NEW_STATUS" ]; then
            echo "用法: auto-collab.sh status <WO编号> <新状态>"
            echo "示例: auto-collab.sh status WO-029 '🔧处理中'"
            exit 1
        fi
        
        # 找到对应工单文件
        WO_FILE=$(ls "$WO_DIR"/${WO_NUM}-*.md 2>/dev/null | head -1)
        if [ -z "$WO_FILE" ]; then
            echo "❌ 工单不存在: $WO_NUM"
            exit 1
        fi
        
        # 替换状态
        OLD_STATUS=$(grep -oP '状态[：:]\s*\K.*' "$WO_FILE" | head -1 | xargs)
        if [ -n "$OLD_STATUS" ]; then
            sed -i "s/状态[：:]*.*$/状态：${NEW_STATUS}/" "$WO_FILE"
            echo "✅ $WO_NUM: $OLD_STATUS → $NEW_STATUS"
        else
            echo "⚠️ 未找到状态字段，手动检查: $WO_FILE"
        fi
        ;;

    bug)
        # 生成bug单：auto-collab.sh bug "系统开发者" "执行WO-029失败：cargo build OOM"
        ROLE="${2:-}"
        REASON="${3:-}"
        if [ -z "$ROLE" ] || [ -z "$REASON" ]; then
            echo "用法: auto-collab.sh bug <角色> <原因>"
            exit 1
        fi
        
        # 获取下一个bug编号
        LAST_NUM=$(ls "$BUG_DIR"/BUG-*.md 2>/dev/null | sed 's/.*BUG-//' | sed 's/-.*//' | sort -n | tail -1 || echo "0")
        NEXT_NUM=$((LAST_NUM + 1))
        BUG_FILE="$BUG_DIR/BUG-$(printf '%03d' $NEXT_NUM)-自动化协作-${ROLE}执行失败.md"
        
        cat > "$BUG_FILE" << EOF
# BUG-$(printf '%03d' $NEXT_NUM): ${ROLE}执行工单失败

| 字段 | 内容 |
|------|------|
| 提交者 | 自动化协作引擎 |
| 角色 | ${ROLE} |
| 状态 | ⏳待处理 |

## 失败原因
${REASON}

## 产生时间
$(date '+%Y-%m-%d %H:%M:%S')
EOF
        
        echo "✅ Bug单已创建: $(basename $BUG_FILE)"
        ;;

    push)
        # 推送变更：auto-collab.sh push "描述"
        MSG="${2:-auto-collab: 协作循环变更}"
        cd "$REPO_DIR"
        
        if [ -n "$(git status --porcelain)" ]; then
            # 只add交接台和项目相关文件，不add全局
            git add 交接台/ 项目/ 技能/ 2>/dev/null || true
            git commit -m "$MSG" 2>/dev/null || true
        fi
        
        # 使用push.sh推送（确保双平台+反哺检查）
        if [ -f "$SCRIPT_DIR/push.sh" ]; then
            SSH_KEY="$SSH_KEY" bash "$SCRIPT_DIR/push.sh" "$MSG" -y 2>/dev/null || {
                # push.sh失败时直接推
                git push origin master 2>/dev/null || true
                git push gitee master 2>/dev/null || true
            }
        else
            git push origin master 2>/dev/null || true
            git push gitee master 2>/dev/null || true
        fi
        echo "✅ 推送完成"
        ;;

    pm-check)
        # PM检查预处理：输出各项目进度概览
        cd "$REPO_DIR"
        echo "📊 项目进度扫描..."
        
        for idx in 项目/*/INDEX.md; do
            [ -f "$idx" ] || continue
            PROJ=$(dirname "$idx" | xargs basename)
            LAST_CHANGE=$(grep '2026-' "$idx" | head -1 | grep -oP '\d{4}-\d{2}-\d{2}' || echo "未知")
            PHASE=$(grep -oP 'Phase \d+|🔧.*?开发中' "$idx" | head -1 || echo "未知")
            STALLED=""
            
            # 检查是否停滞（>3天没动）
            if [ "$LAST_CHANGE" != "未知" ]; then
                DAYS_SINCE=$(( ($(date +%s) - $(date -d "$LAST_CHANGE" +%s 2>/dev/null || echo 0)) / 86400 ))
                if [ $DAYS_SINCE -gt 3 ]; then
                    STALLED="⚠️${DAYS_SINCE}天未动"
                fi
            fi
            
            echo "${PROJ}|${PHASE}|${LAST_CHANGE}|${STALLED:-🟢}"
        done
        
        # 检查体系优化追踪
        if [ -f "$REPO_DIR/共享知识/体系优化追踪.md" ]; then
            PENDING=$(grep -c '⏳\|🔄' "$REPO_DIR/共享知识/体系优化追踪.md" 2>/dev/null || echo "0")
            echo "OPT-TRACK|${PENDING}项待推进||"
        fi
        ;;

    group)
        # 按项目分组待领工单：auto-collab.sh group
        echo "📦 按项目分组工单..."
        cd "$REPO_DIR"
        
        # 已知项目列表（从项目目录获取）
        declare -A PROJECT_GROUPS
        SYSTEM_WOS=""
        
        for f in "$WO_DIR"/WO-*.md "$BUG_DIR"/BUG-*.md; do
            [ -f "$f" ] || continue
            
            BASENAME=$(basename "$f")
            STATUS=$(grep -oP '状态[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "未知")
            
            # 只处理待领取/待处理的工单
            if ! echo "$STATUS" | grep -q "待领取\|待处理"; then
                continue
            fi
            
            # 判断项目归属
            PROJ="体系维护"  # 默认
            
            # 方法1：从文件名提取项目名
            for p in $(ls -d 项目/*/ 2>/dev/null | xargs -I{} basename {}); do
                if echo "$BASENAME" | grep -qi "$p"; then
                    PROJ="$p"
                    break
                fi
            done
            
            # 方法2：从文件内容grep项目名
            if [ "$PROJ" = "体系维护" ]; then
                for p in $(ls -d 项目/*/ 2>/dev/null | xargs -I{} basename {}); do
                    if grep -q "$p" "$f" 2>/dev/null; then
                        PROJ="$p"
                        break
                    fi
                done
            fi
            
            # 提取角色和优先级
            ROLE=$(grep -oP '接收角色[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "未知")
            PRIORITY=$(grep -oP '优先级[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "P2")
            WO_ID=$(echo "$BASENAME" | sed 's/\.md$//' | sed 's/-.*//')
            
            if [ "$PROJ" = "体系维护" ]; then
                SYSTEM_WOS="${SYSTEM_WOS}${WO_ID}|${PRIORITY}|${ROLE}|${BASENAME}"$'\n'
            else
                PROJECT_GROUPS["$PROJ"]="${PROJECT_GROUPS[$PROJ]}${WO_ID}|${PRIORITY}|${ROLE}|${BASENAME}"$'\n'
            fi
        done
        
        # 输出分组结果
        for proj in $(echo "${!PROJECT_GROUPS[@]}" | tr ' ' '\n' | sort); do
            echo "GROUP:${proj}"
            echo "${PROJECT_GROUPS[$proj]}" | sort -t'|' -k2 -r | while IFS='|' read -r wo_id pri role fname; do
                [ -z "$wo_id" ] && continue
                echo "  ${wo_id}|${pri}|${role}|${fname}"
            done
        done
        
        if [ -n "$SYSTEM_WOS" ]; then
            echo "GROUP:体系维护"
            echo "$SYSTEM_WOS" | sort -t'|' -k2 -r | while IFS='|' read -r wo_id pri role fname; do
                [ -z "$wo_id" ] && continue
                echo "  ${wo_id}|${pri}|${role}|${fname}"
            done
        fi
        ;;

    plan)
        # 基于分组结果生成并行执行计划：auto-collab.sh plan
        echo "📋 生成并行执行计划..."
        cd "$REPO_DIR"
        
        # 先分组
        GROUP_OUTPUT=$(bash "$0" group 2>/dev/null)
        
        # 分析角色冲突：同一角色出现在多个组 → 需要串行
        declare -A ROLE_GROUPS
        CURRENT_GROUP=""
        
        while IFS= read -r line; do
            if echo "$line" | grep -q "^GROUP:"; then
                CURRENT_GROUP=$(echo "$line" | sed 's/^GROUP://')
            elif [ -n "$CURRENT_GROUP" ] && echo "$line" | grep -q '|'; then
                ROLE=$(echo "$line" | cut -d'|' -f3)
                ROLE_GROUPS["$ROLE"]="${ROLE_GROUPS[$ROLE]} ${CURRENT_GROUP}"
            fi
        done <<< "$GROUP_OUTPUT"
        
        # 找出角色冲突
        echo "⚡ 可并行的项目组："
        for proj in $(echo "${!ROLE_GROUPS[@]}" | tr ' ' '\n' | sort -u); do
            GROUPS_FOR_ROLE=$(echo "${ROLE_GROUPS[$proj]}" | tr ' ' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
            GROUP_COUNT=$(echo "${ROLE_GROUPS[$proj]}" | tr ' ' '\n' | sort -u | wc -l)
            if [ "$GROUP_COUNT" -gt 1 ]; then
                echo "  ⚠️ 角色[${proj}]跨${GROUP_COUNT}组: ${GROUPS_FOR_ROLE} → 需串行排队"
            fi
        done
        
        # 生成波次
        echo ""
        echo "📊 建议执行波次："
        ALL_GROUPS=$(echo "$GROUP_OUTPUT" | grep "^GROUP:" | sed 's/^GROUP://' | tr '\n' ' ')
        echo "  波次1: $ALL_GROUPS (不同项目可并行，同角色串行)"
        ;;

    lock)
        # 获取push锁
        LOCK_FILE="/tmp/auto-collab-push.lock"
        if [ -f "$LOCK_FILE" ]; then
            LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
            echo "⛔ Push锁已被PID ${LOCK_PID}持有"
            exit 1
        fi
        echo $$ > "$LOCK_FILE"
        echo "✅ Push锁已获取: PID $$"
        ;;

    unlock)
        # 释放push锁
        LOCK_FILE="/tmp/auto-collab-push.lock"
        if [ -f "$LOCK_FILE" ]; then
            rm -f "$LOCK_FILE"
            echo "✅ Push锁已释放"
        else
            echo "⚠️ Push锁不存在"
        fi
        ;;

    focus)
        # 设置聚焦白名单：auto-collab.sh focus "网文创作,OpenForge"
        PROJECTS="${2:-}"
        if [ -z "$PROJECTS" ]; then
            echo "用法: auto-collab.sh focus <项目1,项目2,...>"
            echo "示例: auto-collab.sh focus '网文创作'"
            echo "      auto-collab.sh focus '网文创作,OpenForge'"
            exit 1
        fi
        
        FOCUS_FILE="$REPO_DIR/.focus-projects"
        echo "$PROJECTS" > "$FOCUS_FILE"
        
        # 冻结非白名单工单
        cd "$REPO_DIR"
        IFS=',' read -ra PROJ_ARRAY <<< "$PROJECTS"
        FROZEN=0
        
        for f in "$WO_DIR"/WO-*.md; do
            [ -f "$f" ] || continue
            STATUS=$(grep -oP '状态[：:]\s*\K.*' "$f" 2>/dev/null | head -1 | xargs || echo "未知")
            
            if ! echo "$STATUS" | grep -q "待领取"; then
                continue
            fi
            
            # 检查是否属于白名单项目
            IN_FOCUS=false
            BASENAME=$(basename "$f")
            for p in "${PROJ_ARRAY[@]}"; do
                if echo "$BASENAME" | grep -qi "$p" || grep -q "$p" "$f" 2>/dev/null; then
                    IN_FOCUS=true
                    break
                fi
            done
            
            # 体系维护工单不冻结
            if echo "$BASENAME" | grep -qi "BUG\|体系\|优化"; then
                IN_FOCUS=true
            fi
            
            if [ "$IN_FOCUS" = false ]; then
                sed -i "s/状态[：:]*.*⏳待领取.*/状态：⏸️聚焦暂停/" "$f"
                FROZEN=$((FROZEN + 1))
            fi
        done
        
        echo "✅ 聚焦已设置: $PROJECTS"
        echo "   冻结工单: ${FROZEN}个"
        ;;

    unfocus)
        # 解除聚焦，恢复所有⏸️工单
        cd "$REPO_DIR"
        FOCUS_FILE="$REPO_DIR/.focus-projects"
        THAWED=0
        
        for f in "$WO_DIR"/WO-*.md "$BUG_DIR"/BUG-*.md; do
            [ -f "$f" ] || continue
            if grep -q "⏸️聚焦暂停" "$f" 2>/dev/null; then
                sed -i 's/⏸️聚焦暂停/⏳待领取/' "$f"
                THAWED=$((THAWED + 1))
            fi
        done
        
        rm -f "$FOCUS_FILE"
        echo "✅ 聚焦已解除，恢复工单: ${THAWED}个"
        ;;

    focus-status)
        # 查看当前聚焦状态
        FOCUS_FILE="$REPO_DIR/.focus-projects"
        if [ -f "$FOCUS_FILE" ]; then
            PROJECTS=$(cat "$FOCUS_FILE")
            echo "🎯 当前聚焦: $PROJECTS"
            
            # 统计冻结工单数
            cd "$REPO_DIR"
            FROZEN=0
            for f in "$WO_DIR"/WO-*.md; do
                [ -f "$f" ] || continue
                grep -q "⏸️聚焦暂停" "$f" 2>/dev/null && FROZEN=$((FROZEN + 1))
            done
            echo "   冻结工单: ${FROZEN}个"
        else
            echo "📋 无聚焦设置（所有项目正常推进）"
        fi
        ;;

    help|*)
        echo "auto-collab.sh v4.0 — 自动化协作引擎辅助脚本"
        echo ""
        echo "命令："
        echo "  pull                    Merge方式拉取最新仓库（禁止rebase）"
        echo "  scan                    扫描待领工单，输出精简队列"
        echo "  group                   按项目分组待领工单（并行模式用）"
        echo "  plan                    生成并行执行计划（并行模式用）"
        echo "  status <WO编号> <状态>  更新工单状态"
        echo "  bug <角色> <原因>       生成bug单"
        echo "  push <描述>             推送变更（双平台）"
        echo "  pm-check                PM检查预处理，输出项目进度"
        echo "  lock                    获取push锁（并行模式用）"
        echo "  unlock                  释放push锁（并行模式用）"
        echo "  focus <项目列表>        设置聚焦白名单，冻结非白名单工单"
        echo "  unfocus                 解除聚焦，恢复所有冻结工单"
        echo "  focus-status            查看当前聚焦状态"
        echo ""
        echo "示例："
        echo "  bash scripts/auto-collab.sh pull"
        echo "  bash scripts/auto-collab.sh scan"
        echo "  bash scripts/auto-collab.sh group"
        echo "  bash scripts/auto-collab.sh plan"
        echo "  bash scripts/auto-collab.sh status WO-029 '🔧处理中'"
        echo "  bash scripts/auto-collab.sh push 'auto-collab: 第1轮完成'"
        echo "  bash scripts/auto-collab.sh focus '网文创作'"
        echo "  bash scripts/auto-collab.sh focus '网文创作,OpenForge'"
        echo "  bash scripts/auto-collab.sh unfocus"
        ;;
esac
