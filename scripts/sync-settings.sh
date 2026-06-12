#!/bin/bash
# 核心设定同步脚本 v4.1
# 用途：仓库(真相源)与平台之间的核心设定同步
#
# 核心理念：仓库是唯一真相源，不存在自动合并
#   - pull：仓库→平台（日常用，git pull后执行）
#   - push：平台→仓库（改了平台设定后推回仓库）
#   - 冲突 = 流程问题，必须人工决定
#
# 用法：
#   bash scripts/sync-settings.sh          ← 智能模式（默认pull，有冲突则报错）
#   bash scripts/sync-settings.sh pull     ← 仓库→平台
#   bash scripts/sync-settings.sh push     ← 平台→仓库（推完后建议 git push）
#
# 路径配置：
#   首次在新平台运行时，自动引导创建 .sync-paths.conf
#   不同平台目录结构不同，映射关系存在该配置文件中
#
# 安全：
#   - 两边都有变更→报错+生成diff，绝不自动覆盖或合并
#   - 覆盖前自动备份到 回收站/设定同步-<日期>/
#   - SECRET.md永远不碰
#   - 只add自己改的文件，禁止git add -A

set -e

# ═══ 全局锁（防止多智能体git操作并发竞争index.lock） ═══
REPO_DIR_LOCK="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_FD=9
LOCK_FILE="$REPO_DIR_LOCK/.git/ops.lock"
LOCK_TIMEOUT=120
MY_NAME=$(git config user.name 2>/dev/null || echo '未知')
exec 9>"$LOCK_FILE"
if ! flock -n $LOCK_FD; then
  HOLDER_INFO=$(cat "$LOCK_FILE" 2>/dev/null || echo "未知")
  HOLDER_NAME=$(echo "$HOLDER_INFO" | cut -d'|' -f1 | xargs)
  HOLDER_TIME=$(echo "$HOLDER_INFO" | cut -d'|' -f3 | xargs)
  echo ""
  echo "🚧 前方有车！$HOLDER_NAME 正在操作中（开始于 $HOLDER_TIME），请耐心排队，很快就好~"
  echo "   我是 $MY_NAME，排队等候中..."
  echo ""
  if ! flock -w $LOCK_TIMEOUT $LOCK_FD; then
    echo ""
    echo "⚠️ 等了${LOCK_TIMEOUT}秒还没轮到我，可能前面卡住了"
    echo "   前面是谁：$HOLDER_INFO"
    echo "   排查步骤："
    echo "     1. 先 ps aux | grep git 看看进程是不是还活着、是谁的"
    echo "     2. 是自己之前的卡死进程 → kill -9 <pid> && rm .git/ops.lock"
    echo "     3. 不是自己的 → 别动，等对方处理"
    echo ""
    exit 1
  fi
  echo "✅ 轮到我了！$MY_NAME 开始操作"
fi
echo "$MY_NAME | PID:$$ | $(date '+%H:%M:%S')" >&9

# ── 自动检测平台根目录 ──
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLATFORM_DIR=""

# 搜索策略：从仓库往上找含 .sync-paths.conf 的目录
# 然后找含 基础设定/ 的目录（兼容旧平台）
# 然后找含 MEMORY.md 的目录（最低兼容）
search_dir="$REPO_DIR/.."
while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/.sync-paths.conf" ]; then
        PLATFORM_DIR="$(cd "$search_dir" && pwd)"
        break
    fi
    search_dir="$(cd "$search_dir/.." && pwd)"
done

# 没找到配置文件，尝试兼容检测
if [ -z "$PLATFORM_DIR" ]; then
    search_dir="$REPO_DIR/.."
    while [ "$search_dir" != "/" ]; do
        if [ -d "$search_dir/基础设定" ] || [ -f "$search_dir/MEMORY.md" ]; then
            PLATFORM_DIR="$(cd "$search_dir" && pwd)"
            break
        fi
        search_dir="$(cd "$search_dir/.." && pwd)"
    done
fi

if [ -z "$PLATFORM_DIR" ]; then
    echo "⚠️ 未找到平台根目录"
    echo "请在平台根目录创建 .sync-paths.conf，或设置 PLATFORM_DIR=/your/path"
    exit 1
fi

# 支持外部指定平台路径
[ -n "$PLATFORM_DIR_OVERRIDE" ] && PLATFORM_DIR="$PLATFORM_DIR_OVERRIDE"

# ── 首次配置引导 ──
if [ ! -f "$PLATFORM_DIR/.sync-paths.conf" ]; then
    echo "🔧 首次运行：未找到 .sync-paths.conf，自动生成默认配置"
    echo "   平台根目录：$PLATFORM_DIR"
    echo ""
    
    # 自动检测平台目录结构，生成映射
    cat > "$PLATFORM_DIR/.sync-paths.conf" << CONFEOF
# 核心设定同步路径映射 - 自动生成 $(date +%Y-%m-%d)
# 格式：名称|仓库相对路径|平台相对路径
# 如需调整请手动编辑此文件
CONFEOF
    
    # SOUL: 仓库在基础设定/，平台检测
    if [ -f "$PLATFORM_DIR/基础设定/SOUL.md" ]; then
        echo "SOUL|基础设定/SOUL.md|基础设定/SOUL.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    elif [ -f "$PLATFORM_DIR/SOUL.md" ]; then
        echo "SOUL|基础设定/SOUL.md|SOUL.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    else
        echo "SOUL|基础设定/SOUL.md|基础设定/SOUL.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    fi
    
    # TOOLS
    if [ -f "$PLATFORM_DIR/基础设定/TOOLS.md" ]; then
        echo "TOOLS|基础设定/TOOLS.md|基础设定/TOOLS.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    elif [ -f "$PLATFORM_DIR/TOOLS.md" ]; then
        echo "TOOLS|基础设定/TOOLS.md|TOOLS.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    else
        echo "TOOLS|基础设定/TOOLS.md|基础设定/TOOLS.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    fi
    
    # USER: 仓库根目录
    if [ -f "$PLATFORM_DIR/USER.md" ]; then
        echo "USER|USER.md|USER.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    else
        echo "USER|USER.md|USER.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    fi
    
    # MEMORY: 仓库在基础设定/，平台可能不同
    if [ -f "$PLATFORM_DIR/基础设定/MEMORY.md" ]; then
        echo "MEMORY|基础设定/MEMORY.md|基础设定/MEMORY.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    elif [ -f "$PLATFORM_DIR/MEMORY.md" ]; then
        echo "MEMORY|基础设定/MEMORY.md|MEMORY.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    else
        echo "MEMORY|基础设定/MEMORY.md|MEMORY.md" >> "$PLATFORM_DIR/.sync-paths.conf"
    fi
    
    echo "✅ 已生成 $PLATFORM_DIR/.sync-paths.conf"
    echo "   内容："
    cat "$PLATFORM_DIR/.sync-paths.conf"
    echo ""
fi

# ── 方向判断 ──
DIRECTION="pull"
if [ "$1" = "push" ]; then DIRECTION="push"
elif [ "$1" = "pull" ]; then DIRECTION="pull"
fi

BACKUP_DIR="$PLATFORM_DIR/回收站/设定同步-$(date +%Y%m%d-%H%M)"
CONFLICT_FOUND=0

echo "=== 核心设定同步 v4.1 ==="
echo "📦 仓库：$REPO_DIR"
echo "🖥️ 平台：$PLATFORM_DIR"
echo "➡️ 方向：$([ "$DIRECTION" = "pull" ] && echo '仓库→平台' || echo '平台→仓库')"
echo ""

# ── 读取路径映射 ──
declare -a FILES
while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    FILES+=("$line")
done < "$PLATFORM_DIR/.sync-paths.conf"
echo "📋 路径映射：$PLATFORM_DIR/.sync-paths.conf"
echo ""

# ── 工具函数 ──

backup_file() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$filepath" "$BACKUP_DIR/"
    fi
}

# ── 同步单个文件 ──
sync_file() {
    local name="$1" repo_path="$2" plat_path="$3"
    
    local repo_exists="no" plat_exists="no"
    [ -f "$repo_path" ] && repo_exists="yes"
    [ -f "$plat_path" ] && plat_exists="yes"
    
    # 双方都不存在
    if [ "$repo_exists" = "no" ] && [ "$plat_exists" = "no" ]; then
        echo "  ⏭️ $name：双方都不存在"
        return
    fi
    
    # 内容一致
    if [ "$repo_exists" = "yes" ] && [ "$plat_exists" = "yes" ]; then
        if diff -q "$repo_path" "$plat_path" > /dev/null 2>&1; then
            echo "  ⏭️ $name：一致，无需同步"
            return
        fi
    fi
    
    if [ "$DIRECTION" = "pull" ]; then
        # ── 仓库→平台 ──
        if [ "$repo_exists" = "no" ]; then
            echo "  ⏭️ $name：仓库不存在，跳过"
            return
        fi
        if [ "$plat_exists" = "no" ]; then
            mkdir -p "$(dirname "$plat_path")"
            cp "$repo_path" "$plat_path"
            echo "  ✅ $name：仓库→平台（新建）"
            return
        fi
        # 两边都有且不同→冲突
        echo "  ⚠️ $name：冲突！两边内容不同"
        echo "     仓库：$(wc -l < "$repo_path") 行 | 平台：$(wc -l < "$plat_path") 行"
        mkdir -p "$BACKUP_DIR"
        diff -u "$repo_path" "$plat_path" > "$BACKUP_DIR/${name}.diff" 2>/dev/null || true
        cp "$plat_path" "$BACKUP_DIR/${name}-平台版.md"
        cp "$repo_path" "$BACKUP_DIR/${name}-仓库版.md"
        echo "     平台版已备份：${name}-平台版.md"
        echo "     仓库版已备份：${name}-仓库版.md"
        echo "     差异：${name}.diff"
        echo "     → 用仓库版：手动 cp ${name}-仓库版.md 到平台路径"
        echo "     → 用平台版：先 bash scripts/sync-settings.sh push 推回仓库"
        CONFLICT_FOUND=1
        
    elif [ "$DIRECTION" = "push" ]; then
        # ── 平台→仓库 ──
        if [ "$plat_exists" = "no" ]; then
            echo "  ⏭️ $name：平台不存在，跳过"
            return
        fi
        if [ "$repo_exists" = "no" ]; then
            mkdir -p "$(dirname "$repo_path")"
            cp "$plat_path" "$repo_path"
            echo "  ✅ $name：平台→仓库（新建）"
            return
        fi
        # push=主动确认用平台版，直接覆盖仓库
        backup_file "$repo_path"
        cp "$plat_path" "$repo_path"
        echo "  ✅ $name：平台→仓库（已备份仓库原版）"
    fi
}

# ── 执行同步 ──
for entry in "${FILES[@]}"; do
    IFS='|' read -r name repo_rel plat_rel <<< "$entry"
    echo "── $name ──"
    sync_file "$name" "$REPO_DIR/$repo_rel" "$PLATFORM_DIR/$plat_rel"
    echo ""
done

echo "🔒 SECRET.md 永远不同步（平台凭据不同）"
echo ""

if [ "$CONFLICT_FOUND" = "1" ]; then
    # 写冲突标记文件（act.sh会检查此文件，锁定平台）
    cat > "$PLATFORM_DIR/.sync-conflict" << CONFLICT_EOF
⚠️ 设定同步冲突 - $(date '+%Y-%m-%d %H:%M')
冲突文件在：$BACKUP_DIR/
$(ls "$BACKUP_DIR/" 2>/dev/null | grep -E "\.diff|平台版|仓库版" | while read f; do echo "  - $f"; done)

处理方法：
  1. 查看差异：cat 回收站/设定同步-*/MEMORY.diff
  2. 用仓库版：cp 回收站/设定同步-*/MEMORY-仓库版.md 到平台MEMORY路径
  3. 用平台版：bash scripts/sync-settings.sh push
  4. 处理完后删除此文件：rm .sync-conflict
CONFLICT_EOF
    echo "❌ 存在冲突！已写入 .sync-conflict 锁定平台"
    echo "   所有角色将无法执行，直到主人处理冲突并删除 .sync-conflict"
    echo "   冲突文件在：$BACKUP_DIR/"
    exit 1
else
    # 同步成功 → 清除冲突标记（如果有的话）
    [ -f "$PLATFORM_DIR/.sync-conflict" ] && rm "$PLATFORM_DIR/.sync-conflict" && echo "🔓 已清除冲突标记"
    echo "✅ 同步完成"
    if [ "$DIRECTION" = "push" ]; then
        echo ""
        echo "💡 推回仓库后，记得推到GitHub："
        echo "   cd open-knowledge-system && bash scripts/push.sh \"sync: 设定同步 $(date '+%Y-%m-%d %H:%M')\""
    fi
fi
