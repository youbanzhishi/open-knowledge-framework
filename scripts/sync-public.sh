#!/bin/bash
#===============================================
# 知识体系框架同步脚本 - sync-public.sh
# 功能：从私有仓库选择性同步框架文件到公开仓库
# 安全铁律：必须使用 --update，绝不用 --delete
# 黑名单：凭据/踩坑记录/SECRET/hot-rules/角色knowledge子目录不同步
# 自动化：公开仓库不存在时自动clone；支持被push.sh自动调用
#===============================================

set -e

# ═══ 工作目录 ═══
PRIVATE_DIR="/app/data/所有对话/主对话/open-knowledge-system"
PUBLIC_DIR="/app/data/所有对话/主对话/open-knowledge-framework"
PUBLIC_REPO="https://github.com/youbanzhishi/open-knowledge-framework.git"
PUBLIC_BRANCH="master"

# ═══ 日志函数 ═══
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [sync-public] $1"
}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ═══ 1. 前置检查：私有仓库必须存在 ═══
if [ ! -d "$PRIVATE_DIR/.git" ]; then
    log "${RED}错误：私有仓库目录不存在: $PRIVATE_DIR${NC}"
    exit 1
fi

# ═══ 2. 自动克隆：公开仓库不存在时自动从GitHub clone ═══
if [ ! -d "$PUBLIC_DIR/.git" ]; then
    log "${YELLOW}公开仓库目录不存在，开始自动克隆...${NC}"

    # 确保父目录存在
    PARENT_DIR="$(dirname "$PUBLIC_DIR")"
    mkdir -p "$PARENT_DIR"

    # 尝试克隆
    if git clone --branch "$PUBLIC_BRANCH" --single-branch \
         "$PUBLIC_REPO" "$PUBLIC_DIR" 2>&1; then
        log "${GREEN}✅ 公开仓库克隆成功${NC}"
    else
        log "${RED}❌ 公开仓库克隆失败，可能原因：${NC}"
        log "  1. 仓库不存在（需要先在GitHub上创建 open-knowledge-framework 仓库）"
        log "  2. 网络不通（检查代理或 ghfast.top 可用性）"
        log "  3. 认证问题（公开仓库clone不需要token，但网络可能受限）"
        log ""
        log "手动恢复：git clone $PUBLIC_REPO $PUBLIC_DIR"
        exit 1
    fi

    # 配置git用户
    cd "$PUBLIC_DIR"
    git config user.email "youbanzhishi@users.noreply.github.com" 2>/dev/null || true
    git config user.name "youbanzhishi" 2>/dev/null || true
fi

# ═══ 3. 全局锁（防止多智能体git操作并发竞争index.lock） ═══
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
cd "$PUBLIC_DIR"
git config user.email "youbanzhishi@users.noreply.github.com" 2>/dev/null || true
git config user.name "youbanzhishi" 2>/dev/null || true

# 先pull远程最新（防止本地落后）
log "拉取公开仓库最新代码..."
git pull origin "$PUBLIC_BRANCH" 2>/dev/null || log "⚠️ pull失败（可能网络问题，继续本地同步）"

# ═══ 4. 同步策略 ═══
cd "$PRIVATE_DIR"

log "${GREEN}开始同步框架文件到公开仓库...${NC}"
log "${YELLOW}同步规则：--update（只更新不删）+ 黑名单排除${NC}"

SYNC_STATS=0

# ─── 4.1 共享知识（排除凭据和踩坑记录） ───
log "同步 共享知识/（排除凭据/踩坑记录）..."
OUT=$(rsync -av --update \
  --exclude='凭据/' \
  --exclude='踩坑记录*/' \
  共享知识/ \
  "$PUBLIC_DIR/共享知识/" 2>&1) || true
echo "$OUT" | grep -c "^deleting\|^f\|^d" >/dev/null 2>&1 && SYNC_STATS=$((SYNC_STATS+1)) || true

# ─── 4.2 角色目录（排除hot-rules/knowledge子目录/output/SKILL） ───
log "同步 角色/（排除hot-rules/knowledge/output/SKILL）..."
rsync -av --update \
  --exclude='*/hot-rules*' \
  --exclude='*/hot-rules/' \
  --exclude='*/knowledge/' \
  --exclude='*/output/' \
  --exclude='*/SKILL.md' \
  角色/ \
  "$PUBLIC_DIR/角色/" 2>&1 | tail -1

# ─── 4.3 项目目录 ───
log "同步 项目/..."
rsync -av --update \
  --exclude='*/docs/' \
  --exclude='*/src/' \
  --exclude='*/references/' \
  --exclude='*/scripts/' \
  项目/ \
  "$PUBLIC_DIR/项目/" 2>&1 | tail -1

# ─── 4.4 技能目录 ───
log "同步 技能/..."
rsync -av --update \
  --exclude='*/scripts/' \
  --exclude='*/references/' \
  技能/ \
  "$PUBLIC_DIR/技能/" 2>&1 | tail -1

# ─── 4.5 模板 ───
log "同步 templates/..."
rsync -av --update \
  templates/ \
  "$PUBLIC_DIR/templates/" 2>&1 | tail -1

# ─── 4.6 基础设定（排除SECRET，只同步模板和TOOLS） ───
log "同步 基础设定/（只同步模板，排除实际设定）..."
rsync -av --update \
  --include='*-TEMPLATE*' \
  --include='TOOLS.md' \
  --exclude='*' \
  基础设定/ \
  "$PUBLIC_DIR/基础设定/" 2>&1 | tail -1

# ─── 4.7 根目录文件 ───
log "同步根目录文件..."
for f in README.md START.md 入口.md 知识体系使用指南.md .gitignore; do
  if [ -f "$PRIVATE_DIR/$f" ]; then
    cp --update "$PRIVATE_DIR/$f" "$PUBLIC_DIR/$f" 2>/dev/null || true
  fi
done

# ─── 4.8 scripts目录（排除敏感脚本） ───
log "同步 scripts/（排除敏感脚本）..."
rsync -av --update \
  --exclude='gateway-proxy/' \
  --exclude='safe-edit.sh' \
  --exclude='ssh-init.sh' \
  --exclude='edit-lock.sh' \
  --exclude='dir-lock.sh' \
  --exclude='push.sh' \
  --exclude='worktree-manager.sh' \
  --exclude='create-repo.sh' \
  --exclude='multi-remote-setup.sh' \
  --exclude='auto-collub-loop.sh' \
  --exclude='auto-collab.sh' \
  --exclude='git-recovery.sh' \
  --exclude='git-safe.sh' \
  --exclude='pre-tool-check.sh' \
  --exclude='switch-role.sh' \
  --exclude='.push-remotes.conf' \
  --exclude='.role-git-config' \
  --exclude='.safe_commands.sh' \
  scripts/ \
  "$PUBLIC_DIR/scripts/" 2>&1 | tail -1

# ─── 4.9 docs目录 ───
if [ -d "$PRIVATE_DIR/docs" ]; then
  log "同步 docs/..."
  rsync -av --update \
    docs/ \
    "$PUBLIC_DIR/docs/" 2>&1 | tail -1
fi

# ═══ 5. 黑名单二次清理 ═══
log "${YELLOW}清理公开仓库中的黑名单文件...${NC}"
cd "$PUBLIC_DIR"
find . -name "SECRET.md" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "hot-rules.md" -not -path "./.git/*" -delete 2>/dev/null || true
find . -path "*/凭据/*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -path "*/踩坑记录*" -not -path "./.git/*" -delete 2>/dev/null || true

# ═══ 6. Git提交与推送 ═══
log "检查变更..."

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
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

# Git推送
log "推送到GitHub $PUBLIC_BRANCH..."
if git push origin "$PUBLIC_BRANCH"; then
    log "${GREEN}✅ 公开仓库同步成功！${NC}"
else
    log "${RED}❌ 推送失败${NC}"
    log "  可能原因：1.网络问题 2.Push Protection拦截敏感信息"
    log "  排查：cd $PUBLIC_DIR && git push origin $PUBLIC_BRANCH"
    exit 1
fi

# 简要统计
CHANGED=$(git diff --stat HEAD~1 HEAD 2>/dev/null | tail -1 | xargs || echo "未知")
log "本次同步：$CHANGED"
