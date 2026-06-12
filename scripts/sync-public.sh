#!/bin/bash
#===============================================
# 知识体系框架同步脚本 - sync-public.sh
# 功能：从私有仓库选择性同步框架文件到公开仓库
# 安全铁律：必须使用 --update，绝不用 --delete
# 黑名单：凭据/踩坑记录/SECRET/hot-rules/角色knowledge子目录不同步
#===============================================

set -e

# ═══ 工作目录（实际路径） ═══
PRIVATE_DIR="/app/data/所有对话/主对话/open-knowledge-system"
PUBLIC_DIR="/app/data/所有对话/主对话/open-knowledge-framework"

# ═══ 全局锁（防止多智能体git操作并发竞争index.lock） ═══
LOCK_FD=9
LOCK_FILE="$PUBLIC_DIR/.git/ops.lock"
LOCK_TIMEOUT=120
exec 9>"$LOCK_FILE" 2>/dev/null || exec 9>/dev/null
if ! flock -n $LOCK_FD 2>/dev/null; then
  HOLDER_INFO=$(cat "$LOCK_FILE" 2>/dev/null || echo "未知")
  HOLDER_NAME=$(echo "$HOLDER_INFO" | cut -d'|' -f1 | xargs)
  echo ""
  echo "🚧 前方有车！$HOLDER_NAME 正在操作中，请耐心排队，很快就好~"
  echo ""
  if ! flock -w $LOCK_TIMEOUT $LOCK_FD 2>/dev/null; then
    echo "⚠️ 等了${LOCK_TIMEOUT}秒还没轮到我，可能前面卡住了"
    echo "   前面是谁：$HOLDER_INFO"
    exit 1
  fi
  echo "✅ 轮到我了！sync-public.sh 开始操作"
fi
echo "sync-public.sh | PID:$$ | $(date '+%H:%M:%S')" >&9 2>/dev/null || true

# Git配置
git config user.email "youbanzhishi@users.noreply.github.com" 2>/dev/null || true
git config user.name "youbanzhishi" 2>/dev/null || true

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查目录
if [ ! -d "$PRIVATE_DIR" ]; then
    log "错误：私有仓库目录不存在: $PRIVATE_DIR"
    exit 1
fi
if [ ! -d "$PUBLIC_DIR" ]; then
    log "错误：公开仓库目录不存在: $PUBLIC_DIR"
    exit 1
fi

cd "$PRIVATE_DIR"

# ═══ 同步策略 ═══
# 白名单目录/文件：只同步这些
# 黑名单排除：凭据/踩坑/SECRET/hot-rules/角色knowledge子目录/交接台/回收站
# 规则：rsync --update（只更新不删）+ --exclude 排除敏感内容

log "${GREEN}开始同步框架文件到公开仓库...${NC}"
log "${YELLOW}同步规则：--update（只更新不删）+ 黑名单排除${NC}"

# ─── 1. 共享知识（排除凭据和踩坑记录） ───
log "同步 共享知识/（排除凭据/踩坑记录）..."
rsync -av --update \
  --exclude='凭据/' \
  --exclude='踩坑记录*/' \
  共享知识/ \
  "$PUBLIC_DIR/共享知识/"

# ─── 2. 角色目录（排除hot-rules/knowledge子目录/敏感角色） ───
# 同步：INDEX.md、RULES.md、maturity.md、templates/
# 排除：hot-rules.md、knowledge/子目录、output/
log "同步 角色/（排除hot-rules/knowledge/output）..."
rsync -av --update \
  --exclude='*/hot-rules*' \
  --exclude='*/hot-rules/' \
  --exclude='*/knowledge/' \
  --exclude='*/output/' \
  --exclude='*/SKILL.md' \
  角色/ \
  "$PUBLIC_DIR/角色/"

# ─── 3. 项目目录（排除具体项目子内容，只保留INDEX和模板） ───
log "同步 项目/（只保留INDEX和模板）..."
rsync -av --update \
  --exclude='*/docs/' \
  --exclude='*/src/' \
  --exclude='*/references/' \
  --exclude='*/scripts/' \
  项目/ \
  "$PUBLIC_DIR/项目/"

# ─── 4. 技能目录 ───
log "同步 技能/..."
rsync -av --update \
  --exclude='*/scripts/' \
  --exclude='*/references/' \
  技能/ \
  "$PUBLIC_DIR/技能/"

# ─── 5. 模板 ───
log "同步 templates/..."
rsync -av --update \
  templates/ \
  "$PUBLIC_DIR/templates/"

# ─── 6. 基础设定（排除SECRET，只同步模板） ───
log "同步 基础设定/（只同步模板，排除实际设定）..."
rsync -av --update \
  --include='*-TEMPLATE*' \
  --include='TOOLS.md' \
  --exclude='*' \
  基础设定/ \
  "$PUBLIC_DIR/基础设定/"

# ─── 7. 根目录文件 ───
log "同步根目录文件..."
for f in README.md START.md 入口.md 知识体系使用指南.md .gitignore; do
  if [ -f "$PRIVATE_DIR/$f" ]; then
    cp --update "$PRIVATE_DIR/$f" "$PUBLIC_DIR/$f" 2>/dev/null || true
  fi
done

# ─── 8. scripts目录（排除敏感脚本） ───
log "同步 scripts/（排除敏感脚本）..."
rsync -av --update \
  --exclude='gateway-proxy/' \
  --exclude='safe-edit.sh' \
  --exclude='ssh-init.sh' \
  --exclude='edit-lock.sh' \
  --exclude='dir-lock.sh' \
  scripts/ \
  "$PUBLIC_DIR/scripts/"

# ─── 9. docs目录 ───
if [ -d "$PRIVATE_DIR/docs" ]; then
  log "同步 docs/..."
  rsync -av --update \
    docs/ \
    "$PUBLIC_DIR/docs/"
fi

# ═══ 绝不同步的黑名单文件（二次确认） ═══
log "${YELLOW}清理公开仓库中的黑名单文件（如误同步则删除）...${NC}"
# 删除公开仓库中不应存在的敏感文件
cd "$PUBLIC_DIR"
find . -name "SECRET.md" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "hot-rules.md" -not -path "./.git/*" -delete 2>/dev/null || true
find . -path "*/凭据/*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -path "*/踩坑记录*" -not -path "./.git/*" -delete 2>/dev/null || true

# ═══ Git提交与推送 ═══
log "${GREEN}同步完成，检查变更...${NC}"

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    log "没有新变更需要提交"
    exit 0
fi

# Git提交
log "提交变更..."
git add -A

COMMIT_MSG="sync framework from private repo $(date '+%Y%m%d-%H%M%S')"
if git commit -m "$COMMIT_MSG" 2>/dev/null; then
    log "${GREEN}提交成功${NC}"
else
    log "没有变更需要提交"
    exit 0
fi

# Git推送（master分支）
log "推送到GitHub master..."
if git push origin master; then
    log "${GREEN}✅ 同步成功！${NC}"
else
    log "${RED}❌ 推送失败，请检查网络或认证信息${NC}"
    exit 1
fi

# 显示同步后的文件结构
log "公开仓库当前文件结构："
find . -type f -name "*.md" -not -path "./.git/*" 2>/dev/null | sort | head -40
