#!/usr/bin/env bash
# ==============================================================================
# 同步脚本：直接用 Git 同步知识体系
# ==============================================================================
# 用途：
#   将工作目录的知识体系文件同步到 Git 仓库并推送到 GitHub。
#   工作目录直接操作仓库文件，改完即 commit+push，无需中转。
#
# 用法：
#   ./sync.sh push    # 拉取+提交+推送
#   ./sync.sh pull    # 仅拉取远程更新
#
# 设计原则：
#   - 编辑即同步：工作目录下的 共享知识/ 角色/ 知识导航.md 等是软链接到仓库
#   - 直接 git 操作，不用 rsync 中转
#   - 频繁小推：改一点推一点
# ==============================================================================

set -euo pipefail

REPO_DIR="/app/data/所有对话/主对话/知识体系同步"
SSH_KEY="/root/.ssh/id_ed25519_openks"
GIT_SSH_CMD="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no"

MODE="${1:-push}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
err() { log "ERROR: $*" >&2; exit 1; }

# ── 需要同步的相对路径（仓库内的路径）──────────────────────────────────────────
SYNC_PATHS=(
  "共享知识"
  "角色"
  "技能"
  "知识导航.md"
  "知识体系使用指南.md"
  "项目文档"
  "基础设定"
  "USER.md"
  "MEMORY.md"
  "知识沉淀"
)

# ── PUSH 模式：从工作目录复制到仓库 → commit → push ─────────────────────────
do_push() {
  log "=== PUSH 模式 ==="

  cd "$REPO_DIR"

  # 先拉远程最新
  log "  拉取远程最新..."
  GIT_SSH_COMMAND="$GIT_SSH_CMD" git pull --rebase 2>&1 || {
    log "  ⚠️ pull 有冲突，尝试处理..."
    git rebase --abort 2>/dev/null
    log "  ⚠️ 放弃本次 rebase，保留本地状态，下次再试"
    return 1
  }

  # 从工作目录复制最新文件到仓库（只覆盖已存在的，不删除仓库独有文件）
  WORK_DIR="/app/data/所有对话/主对话"
  for rel_path in "${SYNC_PATHS[@]}"; do
    src="${WORK_DIR}/${rel_path}"
    dst="${REPO_DIR}/${rel_path}"

    if [[ ! -e "$src" ]]; then
      continue
    fi

    # 用 cp -r 而非 rsync，避免 --delete 风险
    if [[ -d "$src" ]]; then
      # 目录：用 rsync --update 只覆盖更新的文件，不删除仓库多出的文件
      rsync -a --update --exclude='.git' --exclude='target' --exclude='__pycache__' "$src/" "$dst/" 2>&1
    else
      # 文件：直接覆盖
      cp -f "$src" "$dst"
    fi
  done

  # Git 提交推送
  if git diff --quiet && git diff --cached --quiet; then
    log "  无变更"
  else
    git add -A
    git commit -m "sync: $(date '+%Y-%m-%d %H:%M:%S')"
    log "  已提交"

    GIT_SSH_COMMAND="$GIT_SSH_CMD" git push 2>&1
    log "  已推送"
  fi

  log "完成！"
}

# ── PULL 模式：拉取远程 → 复制到工作目录 ──────────────────────────────────────
do_pull() {
  log "=== PULL 模式 ==="

  cd "$REPO_DIR"
  GIT_SSH_COMMAND="$GIT_SSH_CMD" git pull --rebase 2>&1 || err "pull 失败"

  # 从仓库复制到工作目录
  WORK_DIR="/app/data/所有对话/主对话"
  for rel_path in "${SYNC_PATHS[@]}"; do
    src="${REPO_DIR}/${rel_path}"
    dst="${WORK_DIR}/${rel_path}"

    if [[ ! -e "$src" ]]; then
      continue
    fi

    if [[ -d "$src" ]]; then
      rsync -a --update --exclude='.git' "$src/" "$dst/" 2>&1
    else
      cp -f "$src" "$dst"
    fi
  done

  log "完成！"
}

# ── 主流程 ─────────────────────────────────────────────────────────────────────
log "模式：${MODE}"

case "$MODE" in
  push) do_push ;;
  pull) do_pull ;;
  *)    err "未知模式：${MODE}" ;;
esac
