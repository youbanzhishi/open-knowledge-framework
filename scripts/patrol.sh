#!/bin/bash
# 体系健康巡检脚本 v1.0
# 用法：bash scripts/patrol.sh [输出目录]
# 五维度巡检 + 闭环复查，产物存 交接台/测试报告/

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

TODAY=$(date '+%Y%m%d')
REPORT_DIR="${1:-交接台/测试报告}"
REPORT_FILE="$REPORT_DIR/体系巡检报告-${TODAY}.md"
mkdir -p "$REPORT_DIR"

LAST_REPORT=$(ls -t "$REPORT_DIR"/体系巡检报告-*.md 2>/dev/null | head -1)

echo "🔍 开始体系健康巡检..."; echo "   报告输出: $REPORT_FILE"

ISSUE_COUNT=0
add_issue() { local s="$1" c="$2" d="$3"; ISSUE_COUNT=$((ISSUE_COUNT+1)); echo "- [${s}] ${d}" >> "$REPORT_FILE.tmp_issues_${c}"; }

# ═══ 1. 健康度 ═══
echo "📌 1/6 健康度检查..."; > "$REPORT_FILE.tmp_issues_health"

# 1.1 冲突标记
CONFLICT_FILES=""
while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -q "^[[:space:]]*<<<<<<< " "$f" 2>/dev/null && CONFLICT_FILES="${CONFLICT_FILES}${f}"$'\n'
done < <(find 角色 共享知识 交接台 项目 技能 -name "*.md" -type f 2>/dev/null | head -300)
for f in 体系优化追踪.md 热更新.md 入口.md 知识体系使用指南.md 蓝图.md MEMORY.md; do
    [ -f "$f" ] && grep -q "^[[:space:]]*<<<<<<< " "$f" 2>/dev/null && CONFLICT_FILES="${CONFLICT_FILES}${f}"$'\n'
done
CONFLICT_FILES=$(echo "$CONFLICT_FILES" | grep -v "^$" | sort -u)
if [ -n "$CONFLICT_FILES" ]; then
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        CONFLICT_COUNT=$(grep -c "^[[:space:]]*<<<<<<< " "$f" 2>/dev/null || echo 0)
        add_issue "🔴严重" "health" "merge冲突残留: $f ($CONFLICT_COUNT处)"
    done <<< "$CONFLICT_FILES"
fi

# 1.2 index.lock
[ -f ".git/index.lock" ] && { LOCK_AGE=$(($(date +%s) - $(stat -c %Y ".git/index.lock" 2>/dev/null || echo 0))); [ "$LOCK_AGE" -gt 300 ] && add_issue "🔴严重" "health" "index.lock残留超过5分钟（${LOCK_AGE}秒）"; }

# 1.3 ops.lock
if [ -f ".git/ops.lock" ]; then
    OPS_PID=$(fuser ".git/ops.lock" 2>/dev/null | tr -d ' ')
    [ -z "$OPS_PID" ] && add_issue "🟡中等" "health" "ops.lock残留但持有进程已终止，可清理"
fi

# 1.4 编辑锁过期
ORPHAN_LOCKS=0; mkdir -p .git/edit-locks
for lf in .git/edit-locks/*; do
    [ -f "$lf" ] || continue
    LOCK_TIME=$(cut -d'|' -f3 "$lf" 2>/dev/null)
    [ -n "$LOCK_TIME" ] || continue
    LOCK_EPOCH=$(date -d "$LOCK_TIME" +%s 2>/dev/null || echo 0)
    DIFF=$(( $(date +%s) - LOCK_EPOCH ))
    if [ "$DIFF" -gt 1800 ]; then
        HOLDER=$(cut -d'|' -f1 "$lf"); N=$(basename "$lf"); P="${N//__/\/}"
        add_issue "🟡中等" "health" "编辑锁过期: $P (持有者: $HOLDER, 已${DIFF}秒)"
        ORPHAN_LOCKS=$((ORPHAN_LOCKS+1))
    fi
done

# 1.5 死链（基于链接文件目录解析相对路径）
DEAD_LINKS=""
while IFS= read -r f; do
    [ -z "$f" ] && continue
    FILE_DIR=$(dirname "$f")
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        path=$(echo "$link" | sed 's/\[.*\](\(.*\))/\1/')
        [[ "$path" == /* ]] || [[ "$path" == http* ]] && continue
        # 基于链接文件所在目录解析
        RESOLVED="$FILE_DIR/$path"
        RESOLVED=$(realpath --relative-to=. "$RESOLVED" 2>/dev/null || echo "$RESOLVED")
        [ ! -f "$RESOLVED" ] && DEAD_LINKS="${DEAD_LINKS}${f}: ${link} → ${RESOLVED}"$'\n'
    done < <(grep -oh '\[.*\](\./[^)]*\.md)' "$f" 2>/dev/null)
done < <(find 角色 共享知识 交接台 -name "*.md" -type f 2>/dev/null | head -200)
if [ -n "$DEAD_LINKS" ]; then
    while IFS= read -r dl; do [ -z "$dl" ] || add_issue "🟡中等" "health" "死链: $dl"; done <<< "$DEAD_LINKS"
fi

HEALTH_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_health" 2>/dev/null | tr -d ' ')
echo "   发现 $HEALTH_ISSUES 个健康度问题"

# ═══ 2. 规范性 ═══
echo "📌 2/6 规范性检查..."; > "$REPORT_FILE.tmp_issues_norm"

for rules_file in 角色/*/RULES.md; do
    [ -f "$rules_file" ] || continue
    ROLE_NAME=$(basename "$(dirname "$rules_file")")
    grep -qP '已同步版本' "$rules_file" 2>/dev/null || add_issue "🟡中等" "norm" "$ROLE_NAME RULES缺少版本号"
done

# bug单超时
if [ -d "交接台/bug单" ]; then
    for bug_file in 交接台/bug单/BUG-*.md; do
        [ -f "$bug_file" ] || continue
        if grep -q "⏳" "$bug_file" 2>/dev/null; then
            BUG_DATE=$(grep -oP '发现时间\s*\|\s*\K.*' "$bug_file" 2>/dev/null | tr -d ' ')
            [ -n "$BUG_DATE" ] || continue
            BUG_EPOCH=$(date -d "$BUG_DATE" +%s 2>/dev/null || echo 0)
            DAYS=$(( ($(date +%s) - BUG_EPOCH) / 86400 ))
            [ "$DAYS" -gt 7 ] && add_issue "🟡中等" "norm" "Bug单超过7天: $(basename "$bug_file") (${DAYS}天)"
        fi
    done
fi

NORM_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_norm" 2>/dev/null | tr -d ' ')
echo "   发现 $NORM_ISSUES 个规范性问题"

# ═══ 3. 自动化 ═══
echo "📌 3/6 自动化机会..."; > "$REPORT_FILE.tmp_issues_auto"

for knowledge_dir in 角色/*/knowledge; do
    [ -d "$knowledge_dir" ] || continue
    FILE_COUNT=$(find "$knowledge_dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    [ "$FILE_COUNT" -gt 5 ] && add_issue "🟢建议" "auto" "$(basename "$(dirname "$knowledge_dir")") knowledge有${FILE_COUNT}篇，考虑提炼脚本/模板"
done

AUTO_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_auto" 2>/dev/null | tr -d ' ')
echo "   发现 $AUTO_ISSUES 个自动化机会"

# ═══ 4. 阻塞性 ═══
echo "📌 4/6 阻塞性检查..."; > "$REPORT_FILE.tmp_issues_block"

PENDING_BUG=0
if [ -d "交接台/bug单" ]; then
    for bug_file in 交接台/bug单/BUG-*.md; do
        [ -f "$bug_file" ] && grep -q "⏳" "$bug_file" 2>/dev/null && PENDING_BUG=$((PENDING_BUG+1))
    done
    [ "$PENDING_BUG" -gt 3 ] && add_issue "🟡中等" "block" "交接台有${PENDING_BUG}个待处理bug单"
fi

UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
UNCOMMITTED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
[ "$UNSTAGED" -gt 5 ] || [ "$UNCOMMITTED" -gt 5 ] && add_issue "🟡中等" "block" "大量未提交变更: 未暂存${UNSTAGED}个, 已暂存${UNCOMMITTED}个"

BLOCK_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_block" 2>/dev/null | tr -d ' ')
echo "   发现 $BLOCK_ISSUES 个阻塞性问题"

# ═══ 5. 经济性 ═══
echo "📌 5/6 经济性检查..."; > "$REPORT_FILE.tmp_issues_cost"

for dir in 角色 共享知识 交接台; do
    [ -d "$dir" ] || continue
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        SIZE=$(wc -c < "$f" 2>/dev/null || echo 0)
        [ "$SIZE" -gt 50000 ] && add_issue "🟢建议" "cost" "大文件: $f ($((SIZE/1024))KB)，考虑拆分"
    done < <(find "$dir" -name "*.md" -type f -size +50k 2>/dev/null | head -20)
done

for rules_file in 角色/*/RULES.md; do
    [ -f "$rules_file" ] || continue
    LINES=$(wc -l < "$rules_file" 2>/dev/null | tr -d ' ')
    ROLE_NAME=$(basename "$(dirname "$rules_file")")
    [ "$LINES" -gt 300 ] && add_issue "🟢建议" "cost" "$ROLE_NAME RULES有${LINES}行(>300)，考虑精简"
done

COST_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_cost" 2>/dev/null | tr -d ' ')
echo "   发现 $COST_ISSUES 个经济性问题"

# ═══ 6. 角色成熟度 ═══
echo "📌 6/7 角色成熟度评估..."; > "$REPORT_FILE.tmp_issues_maturity"
MATURITY_REPORT=""
LOW_ROLES=0
STALE_ROLES=0
for mat_file in 角色/*/maturity.md; do
    [ -f "$mat_file" ] || continue
    ROLE_NAME=$(basename "$(dirname "$mat_file")")
    # 提取均分
    AVG_SCORE=$(grep -oP '均分[：:]\s*\K[0-9.]+' "$mat_file" 2>/dev/null || echo "0")
    # 提取等级
    LEVEL=$(grep -oP '等级[：:]\s*\K\S+' "$mat_file" 2>/dev/null || echo "未知")
    # 提取最后评估日期
    LAST_EVAL=$(grep -oP '最后评估[：:]\s*\K[0-9-]+' "$mat_file" 2>/dev/null || echo "未知")
    
    # 检查是否长期未评估（>30天）
    if [ "$LAST_EVAL" != "未知" ]; then
        EVAL_EPOCH=$(date -d "$LAST_EVAL" +%s 2>/dev/null || echo 0)
        DAYS_SINCE=$(( ($(date +%s) - EVAL_EPOCH) / 86400 ))
        if [ "$DAYS_SINCE" -gt 30 ]; then
            add_issue "🟡中等" "maturity" "$ROLE_NAME 成熟度超过30天未评估（${DAYS_SINCE}天），建议重新评估"
            STALE_ROLES=$((STALE_ROLES+1))
        fi
    fi
    
    # 检查低分角色（均分<3）
    IS_LOW=$(echo "$AVG_SCORE < 3" | bc 2>/dev/null || echo 0)
    if [ "$IS_LOW" = "1" ]; then
        add_issue "🟡中等" "maturity" "$ROLE_NAME 成熟度偏低（${AVG_SCORE}，${LEVEL}），建议关注能力短板"
        LOW_ROLES=$((LOW_ROLES+1))
    fi
    
    # 收集评分摘要
    MATURITY_REPORT="${MATURITY_REPORT}| ${ROLE_NAME} | ${AVG_SCORE} | ${LEVEL} | ${LAST_EVAL} |"$'\n'
done

MATURITY_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_maturity" 2>/dev/null | tr -d ' ')
echo "   发现 $MATURITY_ISSUES 个成熟度问题 (低分${LOW_ROLES}个, 过期${STALE_ROLES}个)"

# ═══ 7. 闭环复查 ═══
echo "📌 7/7 闭环复查..."; > "$REPORT_FILE.tmp_issues_regress"
REGRESS_NOTE="首次巡检，无历史对比"
if [ -n "$LAST_REPORT" ] && [ -f "$LAST_REPORT" ]; then
    LAST_DATE=$(basename "$LAST_REPORT" | grep -oP '\d{8}')
    LAST_ISSUES=$(grep -P '^\- \[' "$LAST_REPORT" 2>/dev/null | sed 's/.*\] //' | sort -u)
    if [ -n "$LAST_ISSUES" ]; then
        while IFS= read -r li; do
            [ -z "$li" ] && continue
            KEYWORD=$(echo "$li" | cut -c1-20)
            cat "$REPORT_FILE.tmp_issues_"* 2>/dev/null | grep -qF "$KEYWORD" && add_issue "🔴严重" "regress" "复发: $li"
        done <<< "$LAST_ISSUES"
    fi
    REGRESS_NOTE="对比上次巡检($LAST_DATE)"
fi

REGRESS_ISSUES=$(wc -l < "$REPORT_FILE.tmp_issues_regress" 2>/dev/null | tr -d ' ')
echo "   发现 $REGRESS_ISSUES 个复发问题"

# ═══ 生成报告 ═══
TOTAL_ISSUES=$((HEALTH_ISSUES + NORM_ISSUES + AUTO_ISSUES + BLOCK_ISSUES + COST_ISSUES + MATURITY_ISSUES + REGRESS_ISSUES))

cat > "$REPORT_FILE" << EOF
# 体系巡检报告 - $(date '+%Y-%m-%d %H:%M')

> 巡检脚本: scripts/patrol.sh
> $REGRESS_NOTE

## 总览

| 维度 | 问题数 | 状态 |
|------|--------|------|
| 健康度 | $HEALTH_ISSUES | $([ "$HEALTH_ISSUES" -eq 0 ] && echo '🟢正常' || echo '🔴需处理') |
| 规范性 | $NORM_ISSUES | $([ "$NORM_ISSUES" -eq 0 ] && echo '🟢正常' || echo '🟡需关注') |
| 自动化 | $AUTO_ISSUES | $([ "$AUTO_ISSUES" -eq 0 ] && echo '🟢正常' || echo '🟢优化建议') |
| 阻塞性 | $BLOCK_ISSUES | $([ "$BLOCK_ISSUES" -eq 0 ] && echo '🟢正常' || echo '🟡需关注') |
| 经济性 | $COST_ISSUES | $([ "$COST_ISSUES" -eq 0 ] && echo '🟢正常' || echo '🟢优化建议') |
| 成熟度 | $MATURITY_ISSUES | $([ "$MATURITY_ISSUES" -eq 0 ] && echo '🟢正常' || echo '🟡需关注') |
| 闭环复查 | $REGRESS_ISSUES | $([ "$REGRESS_ISSUES" -eq 0 ] && echo '🟢无复发' || echo '🔴有复发!') |
| **合计** | **$TOTAL_ISSUES** | |

## 角色成熟度总览

| 角色 | 均分 | 等级 | 最后评估 |
|------|------|------|----------|
$(echo "$MATURITY_REPORT" | sort -t'|' -k2 -rn)

## 🔴 严重问题（必须立即处理）

$(grep '🔴' "$REPORT_FILE.tmp_issues_"* 2>/dev/null | sed 's/.*tmp_issues_[^:]*://' || echo '(无)')

## 🟡 中等问题（本周处理）

$(grep '🟡' "$REPORT_FILE.tmp_issues_"* 2>/dev/null | sed 's/.*tmp_issues_[^:]*://' || echo '(无)')

## 🟢 优化建议（择机处理）

$(grep '🟢' "$REPORT_FILE.tmp_issues_"* 2>/dev/null | sed 's/.*tmp_issues_[^:]*://' || echo '(无)')

## 闭环跟踪

| 问题 | 修复状态 | 根因分析 | 规则升级 | 验证 |
|------|----------|----------|----------|------|
| (待填写) | | | | |

---
*下次巡检将复查本表所有问题*
EOF

rm -f "$REPORT_FILE.tmp_issues_"*
echo ""
echo "══════════════════════════════════════"
echo "✅ 巡检完成! 总问题数: $TOTAL_ISSUES"
echo "   报告: $REPORT_FILE"
[ "$REGRESS_ISSUES" -gt 0 ] && echo "🚨 有 $REGRESS_ISSUES 个问题复发！"
[ "$HEALTH_ISSUES" -gt 0 ] && echo "🔴 有 $HEALTH_ISSUES 个健康度问题"
echo "══════════════════════════════════════"
exit $TOTAL_ISSUES
