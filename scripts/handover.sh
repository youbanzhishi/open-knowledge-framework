#!/bin/bash
# 交接台管理脚本 v1.0
# 用法：
#   bash scripts/handover.sh bug "标题" "提交者"           → 提交bug单
#   bash scripts/handover.sh work "标题" "提交者" "接收角色" → 提交工单
#   bash scripts/handover.sh material "编号" "交付者" "接收者" "内容" "文件路径" → 提交物料交接单
#   bash scripts/handover.sh hotupdate "OPT编号" "摘要" "影响角色" "改了什么" → 写热更新
#   bash scripts/handover.sh archive-bug "BUG-编号"        → 归档bug单
#   bash scripts/handover.sh archive-material "H-编号"     → 归档物料
#   bash scripts/handover.sh resolve-bug "BUG-编号" "OPT编号" → 解决bug单
#   bash scripts/handover.sh resolve-work "WO-编号"        → 完成工单

set -e
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

HANDOVER_DIR="交接台"
README="$HANDOVER_DIR/README.md"
BUG_DIR="$HANDOVER_DIR/bug单"
WORK_DIR="$HANDOVER_DIR/工单"
MATERIAL_DIR="$HANDOVER_DIR/物料"
ARCHIVE_DIR="$HANDOVER_DIR/归档"

# 获取下一个编号
next_bug_num() {
    local max=0
    for f in "$BUG_DIR"/BUG-*.md; do
        [ -f "$f" ] || continue
        local num=$(basename "$f" | grep -oP 'BUG-\K\d+')
        num=$((10#$num))  # 强制十进制
        [ "$num" -gt "$max" ] && max=$num
    done
    grep -oP 'BUG-\K\d+' "$README" 2>/dev/null | while read num; do
        num=$((10#$num))
        [ "$num" -gt "$max" ] && max=$num
    done
    echo $((max + 1))
}

next_work_num() {
    local max=0
    for f in "$WORK_DIR"/WO-*.md; do
        [ -f "$f" ] || continue
        local num=$(basename "$f" | grep -oP 'WO-\K\d+')
        num=$((10#$num))
        [ "$num" -gt "$max" ] && max=$num
    done
    echo $((max + 1))
}

next_material_num() {
    local max=0
    for f in "$MATERIAL_DIR"/H*.md; do
        [ -f "$f" ] || continue
        local num=$(basename "$f" | grep -oP 'H\K\d+')
        num=$((10#$num))
        [ "$num" -gt "$max" ] && max=$num
    done
    echo $((max + 1))
}

today() { date +%Y-%m-%d; }

# 提交bug单
cmd_bug() {
    local title="$1"
    local submitter="$2"
    local num=$(next_bug_num)
    local padded=$(printf "%03d" $num)
    local file="$BUG_DIR/BUG-${padded}-${title}.md"
    local date=$(today)
    
    cat > "$file" << BOGEOF
# BUG-${padded}：${title}

| 字段 | 内容 |
|------|------|
| 编号 | BUG-${padded} |
| 提交者 | ${submitter} |
| 发现时间 | ${date} |
| 问题类型 | （填写：流程断链/规范缺失/体系架构优化） |
| 影响范围 | （填写：哪些角色受影响） |
| 状态 | ⏳待处理 |

## 用户想法

（用户视角：想要什么效果？）

## 智能体视角的问题

（根因分析：为什么会出这个问题？）

## 建议

（修复方案）
BOGEOF
    
    # 更新README - 用python精确追加到对应表格末尾
    python3 -c "
with open('${README}', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 找bug单表格区，在最后一行数据后追加
in_bug_table = False
last_data_line = -1
for i, line in enumerate(lines):
    if '体系bug单' in line and '##' in line:
        in_bug_table = True
        continue
    if in_bug_table and line.startswith('## '):
        break
    if in_bug_table and line.startswith('|') and not line.startswith('|-') and not line.startswith('| 编号'):
        last_data_line = i

if last_data_line >= 0:
    new_row = '| BUG-${padded} | ${submitter} | ${title} | ⏳待处理 |\n'
    lines.insert(last_data_line + 1, new_row)
    with open('${README}', 'w', encoding='utf-8') as f:
        f.writelines(lines)
"
    
    echo "✅ Bug单已创建: BUG-${padded}"
    echo "   文件: $file"
    echo "   请补充问题类型、影响范围、根因分析和修复方案"
}

# 提交工单
cmd_work() {
    local title="$1"
    local submitter="$2"
    local receiver="$3"
    local num=$(next_work_num)
    local padded=$(printf "%03d" $num)
    local file="$WORK_DIR/WO-${padded}-${title}.md"
    local date=$(today)
    
    cat > "$file" << WORKEOF
# WO-${padded}：${title}

| 字段 | 内容 |
|------|------|
| 编号 | WO-${padded} |
| 提交者 | ${submitter} |
| 接收角色 | ${receiver} |
| 优先级 | P2 |
| 状态 | ⏳待领取 |

## 任务描述

（详细描述任务内容、产出要求、关联bug单）

## 关联文件

（列出相关文件路径）
WORKEOF
    
    # 更新README
    python3 -c "
with open('${README}', 'r', encoding='utf-8') as f:
    lines = f.readlines()
in_work_table = False
last_data_line = -1
for i, line in enumerate(lines):
    if '工单' in line and '##' in line and '活跃' in line:
        in_work_table = True
        continue
    if in_work_table and line.startswith('## '):
        break
    if in_work_table and line.startswith('|') and not line.startswith('|-') and not line.startswith('| 编号'):
        last_data_line = i
if last_data_line >= 0:
    new_row = '| WO-${padded} | ${submitter} | ${receiver} | ${title} | ⏳待领取 |\n'
    lines.insert(last_data_line + 1, new_row)
    with open('${README}', 'w', encoding='utf-8') as f:
        f.writelines(lines)
"
    
    echo "✅ 工单已创建: WO-${padded}"
    echo "   文件: $file"
    echo "   请补充任务描述和关联文件"
}

# 提交物料交接单
cmd_material() {
    local num="$1"
    local from="$2"
    local to="$3"
    local content="$4"
    local path="$5"
    local date=$(today)
    local file="$MATERIAL_DIR/H${num}-${content}.md"
    
    cat > "$file" << MATEOF
# H${num}：${content}

| 字段 | 内容 |
|------|------|
| 编号 | H${num} |
| 交付者 | ${from} |
| 接收者 | ${to} |
| 交付时间 | ${date} |
| 状态 | 待领取 |

## 内容

${content}

## 物料位置

${path}

## 备注

（补充说明）
MATEOF
    
    # 更新README
    python3 -c "
with open('${README}', 'r', encoding='utf-8') as f:
    lines = f.readlines()
in_mat_table = False
last_data_line = -1
for i, line in enumerate(lines):
    if '物料交接' in line and '##' in line:
        in_mat_table = True
        continue
    if in_mat_table and line.startswith('## '):
        break
    if in_mat_table and line.startswith('|') and not line.startswith('|-') and not line.startswith('| 编号'):
        last_data_line = i
if last_data_line >= 0:
    new_row = '| H${num} | ${from} | ${to} | ${content} | 待领取 |\n'
    lines.insert(last_data_line + 1, new_row)
    with open('${README}', 'w', encoding='utf-8') as f:
        f.writelines(lines)
"
    
    echo "✅ 物料交接单已创建: H${num}"
    echo "   文件: $file"
}

# 写热更新
cmd_hotupdate() {
    local opt_num="$1"
    local summary="$2"
    local affected="$3"
    local changed="$4"
    local time=$(date +%H:%M)
    local hotfile="热更新.md"
    local today_str=$(date +%Y-%m-%d)
    
    python3 -c "
import os
hotfile = '${hotfile}'
today = '${today_str}'
time_str = '${time}'
opt = '${opt_num}'
summary = '${summary}'
affected = '${affected}'
changed = '${changed}'

with open(hotfile, 'r', encoding='utf-8') as f:
    lines = f.readlines()

entry = f'''
### {time_str} — {opt}：{summary}
- 影响：{affected}
- 改了：{changed}
'''

# 找到今天的日期段
insert_pos = -1
for i, line in enumerate(lines):
    if f'## {today}' in line:
        insert_pos = i + 1
        break

if insert_pos >= 0:
    lines.insert(insert_pos, entry)
else:
    # 新建日期段，插入在第一个##之前
    header_end = 0
    for i, line in enumerate(lines):
        if line.startswith('## '):
            header_end = i
            break
    lines.insert(header_end, f'\n## {today}\n{entry}')

with open(hotfile, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('✅ 热更新已写入: ' + opt)
"
}

# 解决bug单
cmd_resolve_bug() {
    local bug_id="$1"
    local opt_id="$2"
    local file=$(ls "$BUG_DIR"/${bug_id}-*.md 2>/dev/null | head -1)
    
    if [ -z "$file" ]; then
        echo "❌ 找不到: $BUG_DIR/${bug_id}-*.md"
        exit 1
    fi
    
    # 改状态
    sed -i "s/| ⏳待处理 |/| ✅已解决（${opt_id}） |/" "$file"
    sed -i "s/| 🔧处理中 |/| ✅已解决（${opt_id}） |/" "$file"
    
    # 更新README
    python3 -c "
with open('${README}', 'r', encoding='utf-8') as f:
    content = f.read()
import re
content = re.sub(r'${bug_id} \| (.*) \| (.*) \| ⏳待处理 \|', r'${bug_id} | \1 | \2 | ✅已解决 |', content)
content = re.sub(r'${bug_id} \| (.*) \| (.*) \| 🔧处理中 \|', r'${bug_id} | \1 | \2 | ✅已解决 |', content)
with open('${README}', 'w', encoding='utf-8') as f:
    f.write(content)
"
    
    echo "✅ Bug单已解决: ${bug_id} (${opt_id})"
}

# 归档bug单
cmd_archive_bug() {
    local bug_id="$1"
    local file=$(ls "$BUG_DIR"/${bug_id}-*.md 2>/dev/null | head -1)
    
    if [ -z "$file" ]; then
        echo "❌ 找不到: $BUG_DIR/${bug_id}-*.md"
        exit 1
    fi
    
    local month=$(date +%Y-%m)
    mkdir -p "$ARCHIVE_DIR"
    
    # 追加到归档文件
    local archive_file="$ARCHIVE_DIR/${month}.md"
    if [ ! -f "$archive_file" ]; then
        echo "# 交接台归档 — $(date +%Y年%m月)" > "$archive_file"
    fi
    echo "" >> "$archive_file"
    cat "$file" >> "$archive_file"
    
    # 从README删除该行
    sed -i "/${bug_id}/d" "$README"
    
    # 删除原文件
    rm "$file"
    
    echo "✅ 已归档: ${bug_id} → $ARCHIVE_DIR/${month}.md"
}

# 归档物料
cmd_archive_material() {
    local h_id="$1"
    local file=$(ls "$MATERIAL_DIR"/${h_id}-*.md 2>/dev/null | head -1)
    
    if [ -z "$file" ]; then
        echo "❌ 找不到: $MATERIAL_DIR/${h_id}-*.md"
        exit 1
    fi
    
    local month=$(date +%Y-%m)
    mkdir -p "$ARCHIVE_DIR"
    
    local archive_file="$ARCHIVE_DIR/${month}.md"
    if [ ! -f "$archive_file" ]; then
        echo "# 交接台归档 — $(date +%Y年%m月)" > "$archive_file"
    fi
    echo "" >> "$archive_file"
    cat "$file" >> "$archive_file"
    
    sed -i "/${h_id}/d" "$README"
    rm "$file"
    
    echo "✅ 已归档: ${h_id} → $ARCHIVE_DIR/${month}.md"
}

# 完成工单
cmd_resolve_work() {
    local wo_id="$1"
    
    # 更新README
    sed -i "s/${wo_id} | \(.*\) | \(.*\) | \(.*\) | ⏳待领取 |/${wo_id} | \1 | \2 | \3 | ✅已完成 |/" "$README"
    sed -i "s/${wo_id} | \(.*\) | \(.*\) | \(.*\) | 🔧处理中 |/${wo_id} | \1 | \2 | \3 | ✅已完成 |/" "$README"
    
    echo "✅ 工单已完成: ${wo_id}"
}

# 更新工单/bug单状态
cmd_status() {
    local type="$1"    # work 或 bug
    local id="$2"      # WO-XXX 或 BUG-XXX
    local status="$3"  # 新状态
    
    if [ -z "$type" ] || [ -z "$id" ] || [ -z "$status" ]; then
        echo "用法: bash scripts/handover.sh status {work|bug} {WO-XXX|BUG-XXX} {新状态}"
        echo "状态示例：⏳待领取 🔧处理中 ✅已完成 ❌已关闭"
        exit 1
    fi
    
    # 验证编号存在
    if ! grep -q "$id" "$README"; then
        echo "❌ 未找到: $id"
        exit 1
    fi
    
    # 更新README中的状态（匹配任意旧状态）
    sed -i "s/${id} | \(.*\) | \(.*\) | \(.*\) | [^|]* |/${id} | \1 | \2 | \3 | ${status} |/" "$README"
    
    # 如果是工单，也更新工单文件内的状态
    if [ "$type" = "work" ]; then
        local file=$(ls ${WORK_DIR}/${id}-*.md 2>/dev/null | head -1)
        if [ -n "$file" ]; then
            sed -i "s/^> 状态：.*/> 状态：${status}/" "$file"
        fi
    elif [ "$type" = "bug" ]; then
        local file=$(ls ${BUG_DIR}/${id}-*.md 2>/dev/null | head -1)
        if [ -n "$file" ]; then
            sed -i "s/^> 状态：.*/> 状态：${status}/" "$file"
        fi
    fi
    
    echo "✅ 状态已更新: $id → $status"
}

# 主入口
case "${1}" in
    bug)        cmd_bug "$2" "$3" ;;
    work)       cmd_work "$2" "$3" "$4" ;;
    material)   cmd_material "$2" "$3" "$4" "$5" "$6" ;;
    hotupdate)  cmd_hotupdate "$2" "$3" "$4" "$5" ;;
    resolve-bug)  cmd_resolve_bug "$2" "$3" ;;
    resolve-work) cmd_resolve_work "$2" ;;
    status)     cmd_status "$2" "$3" "$4" ;;
    archive-bug)     cmd_archive_bug "$2" ;;
    archive-material) cmd_archive_material "$2" ;;
    *) echo "用法: bash scripts/handover.sh {bug|work|material|hotupdate|resolve-bug|resolve-work|status|archive-bug|archive-material} [参数...]"; exit 1 ;;
esac
