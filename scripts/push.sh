#!/bin/bash
# 体系推送脚本 v4.1
# 用法：cd open-knowledge-framework && bash scripts/push.sh "简要描述变更"
# 功能：先commit再pull再push + 冲突处理 + 双平台推送 + 禁止强推
# 流程顺序：commit → pull(merge from origin) → push(推所有pushurl)
# 双推机制：
#   - GitHub: SSH模式（默认）
#   - Gitee: HTTPS模式
# v4.1变更：默认SSH模式，兼容HTTPS降级

# 解析 -y 参数（跳过反哺检查确认，仅用于已确认反哺完整但脚本检测不到的场景）
AUTO_CONFIRM=0
if [ "${1:-}" = "-y" ]; then
  AUTO_CONFIRM=1
  shift
fi
MSG="${1:?用法: $0 [-y] \"简要描述变更\"}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# ═══ SSH/HTTPS模式切换（默认SSH） ═══
GIT_MODE="${GIT_MODE:-ssh}"  # 默认SSH
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa_github}"

if [ "$GIT_MODE" = "ssh" ]; then
  echo "🔐 使用SSH模式"
  # 检查SSH密钥
  if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH密钥不存在: $SSH_KEY"
    echo "   使用自定义密钥: SSH_KEY=/path/to/key bash scripts/push.sh"
    exit 1
  fi
  # 配置SSH config
  mkdir -p ~/.ssh
  if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
    echo -e "Host github.com\n    HostName github.com\n    User git\n    IdentityFile $SSH_KEY\n    IdentitiesOnly yes" > ~/.ssh/config
    chmod 600 ~/.ssh/config
  fi
  # 切换到SSH
  git remote set-url origin git@github.com:youbanzhishi/open-knowledge-framework.git 2>/dev/null || true
else
  echo "🔗 使用HTTPS模式"
  # 切换到HTTPS
  git remote set-url origin https://youbanzhishi:${GIT_PAT:-}@github.com/youbanzhishi/open-knowledge-framework.git 2>/dev/null || true
fi

# ═══ 全局锁（防止多智能体git操作并发竞争index.lock） ═══
LOCK_FD=9
LOCK_FILE=".git/ops.lock"
LOCK_TIMEOUT=120  # 最长等120秒，超时退出
MY_NAME=$(git config user.name 2>/dev/null || echo '未知')

# 锁文件健康检查：如果锁文件存在但持有进程已死，自动清理
if [ -f "$LOCK_FILE" ]; then
  LOCK_HOLDER_PID=$(fuser "$LOCK_FILE" 2>/dev/null | tr -d ' ')
  if [ -z "$LOCK_HOLDER_PID" ]; then
    echo "🧹 检测到残留锁文件（持有进程已终止），自动清理"
    rm -f "$LOCK_FILE" 2>/dev/null || true
  fi
fi

exec 9>"$LOCK_FILE"
if ! flock -n $LOCK_FD; then
  # 读持锁者信息
  HOLDER_INFO=$(cat "$LOCK_FILE" 2>/dev/null || echo "未知")
  HOLDER_NAME=$(echo "$HOLDER_INFO" | cut -d'|' -f1 | xargs)
  HOLDER_TIME=$(echo "$HOLDER_INFO" | cut -d'|' -f3 | xargs)
  echo ""
  echo "🚧 前方有车！$HOLDER_NAME 正在推送中（开始于 $HOLDER_TIME），请耐心排队，很快就好~"
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
  echo "✅ 轮到我了！$MY_NAME 开始推送"
fi
# 写入自己的身份信息，让后面排队的人知道是谁
echo "$MY_NAME | PID:$$ | $(date '+%H:%M:%S')" >&9

# ═══ 前置检查（必须全部通过才能继续） ═══

# 0. 禁止强推：检测任何--force变体
if echo "$*" | grep -qE '\-\-force|\-f '; then
  echo "❌ 禁止强推（--force / -f）！强推会覆盖其他平台的提交历史"
  echo "   如果真的需要，请主人手动执行 git push --force"
  exit 1
fi

# 0.1 身份检查：git用户名必须包含平台标识
CURRENT_USER=$(git config user.name 2>/dev/null || echo "")
if [ -z "$CURRENT_USER" ]; then
  echo "❌ git未配置用户名，先运行 bash scripts/init.sh 扣子|元宝|云电脑|本地"
  exit 1
fi
if ! echo "$CURRENT_USER" | grep -qE "\(扣子\)|\(元宝\)|\(云电脑\)|\(本地\)"; then
  echo "❌ git用户名缺少平台标识：$CURRENT_USER"
  echo "   必须运行 bash scripts/init.sh 扣子|元宝|云电脑|本地"
  echo "   正确格式：小龙(扣子)、小龙(元宝) 等"
  echo "   没有平台标识=commit不可追踪=不知道谁改的"
  exit 1
fi

# 0.2 remote检查：origin fetch URL必须带token（拉取鉴权）
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if ! echo "$CURRENT_REMOTE" | grep -q "@"; then
  echo "❌ origin未配token，push/pull会失败，先运行 bash scripts/init.sh"
  exit 1
fi

# 0.3 pushurl检查：至少有一个pushurl配置（双推的基础）
PUSH_URLS=$(git remote get-url --push origin 2>/dev/null || echo "")
if [ -z "$PUSH_URLS" ]; then
  echo "⚠️  未检测到pushurl配置，将使用fetch URL推送（单平台模式）"
  echo "   如需双推，运行 bash scripts/init.sh 配置多平台推送"
fi

# 0.4 冲突标记扫描：待提交文件中不能包含 <<<<<<< 冲突标记
if [ -n "$(git diff --cached --name-only 2>/dev/null)" ] || [ -n "$(git diff --name-only 2>/dev/null)" ]; then
  CONFLICT_MARKER_FILES=""
  for f in $(git diff --cached --name-only 2>/dev/null) $(git diff --name-only 2>/dev/null); do
    [ -f "$f" ] || continue
    if grep -q "<<<<<<" "$f" 2>/dev/null; then
      CONFLICT_MARKER_FILES="$CONFLICT_MARKER_FILES\n  $f"
    fi
  done
  if [ -n "$CONFLICT_MARKER_FILES" ]; then
    echo ""
    echo "❌ 检测到未解决的merge冲突标记！以下文件包含 <<<<<<< ："
    echo -e "$CONFLICT_MARKER_FILES"
    echo ""
    echo "   冲突残留推入远程=灾难。请先解决冲突后再推送。"
    if [ "$AUTO_CONFIRM" = "1" ]; then
      echo "   ⚠️ -y 模式跳过冲突扫描（危险！）"
    else
      exit 1
    fi
  fi
fi

# ─── 冲突自动处理 ───
resolve_merge_conflicts() {
  local CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)
  [ -z "$CONFLICT_FILES" ] && CONFLICT_FILES=$(git status --porcelain | grep '^UU\|^AA' | awk '{print $2}')

  if [ -z "$CONFLICT_FILES" ]; then
    echo "⚠️ 无法定位冲突文件"
    git merge --abort 2>/dev/null
    return 1
  fi

  echo ""
  echo "═══════════════════════════════════════════"
  echo "⚠️  冲突文件（$(echo "$CONFLICT_FILES" | wc -l)个）："
  echo "$CONFLICT_FILES"
  echo "───────────────────────────────────────────"

  local AUTO=0 MANUAL=0

  for FILE in $CONFLICT_FILES; do
    RESULT=$(python3 -c "
import re, sys
try:
    with open('$FILE', 'r') as f:
        content = f.read()
    if '<<<<<<<' not in content:
        print('SKIP'); sys.exit(0)

    conflicts = list(re.finditer(
        r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>>[^\n]*\n',
        content, re.DOTALL
    ))

    if not conflicts:
        print('SKIP'); sys.exit(0)

    all_append = True
    for m in conflicts:
        ours, theirs = m.group(1).strip(), m.group(2).strip()
        if not ours or not theirs:
            all_append = False
            break

    if all_append:
        resolved = content
        for m in reversed(conflicts):
            ours_text = m.group(1).rstrip()
            theirs_text = m.group(2).strip()
            block = ours_text + '\n' + theirs_text + '\n'
            resolved = resolved[:m.start()] + block + resolved[m.end():]
        with open('$FILE', 'w') as f:
            f.write(resolved)
        print('AUTO')
    else:
        lines = []
        for i, line in enumerate(content.split('\n'), 1):
            if line.startswith('<<<<<<<') or line.startswith('=======') or line.startswith('>>>>>>>'):
                lines.append(f'  行{i}: {line}')
        print('MANUAL|' + '\\n'.join(lines[:20]))
except Exception as e:
    print(f'ERROR|{e}')
" 2>/dev/null)

    case "$RESULT" in
      AUTO)
        echo "  ✅ $FILE → 追加类冲突，已自动合并双方内容"
        # 校验：我的新增行是否还在（防止自动合并丢内容）
        if [ -f .git/our-lines-$$.tmp ]; then
          MISSING=0
          while IFS= read -r line; do
            if [ -n "$line" ] && ! grep -qF "$line" "$FILE" 2>/dev/null; then
              MISSING=$((MISSING + 1))
            fi
          done < .git/our-lines-$$.tmp
          if [ $MISSING -gt 0 ]; then
            echo "  🚨 $FILE 自动合并后有 $MISSING 行内容丢失！中断推送，需人工处理"
            git merge --abort 2>/dev/null
            MANUAL=$((MANUAL + 1))
            continue 2
          fi
        fi
        git add "$FILE"
        AUTO=$((AUTO + 1))
        ;;
      MANUAL\|*)
        echo "  ❌ $FILE → 修改类冲突，需人工决定"
        echo "${RESULT#MANUAL|}" | while IFS= read -r line; do echo "     $line"; done
        MANUAL=$((MANUAL + 1))
        ;;
      SKIP|ERROR\|*)
        if [[ "$RESULT" == ERROR* ]]; then
          echo "  ⚠️ $FILE → 处理出错：${RESULT#ERROR|}"
          MANUAL=$((MANUAL + 1))
        fi
        ;;
    esac
  done

  echo ""
  echo "📊 结果：自动合并 ${AUTO} 个 | 需人工处理 ${MANUAL} 个"

  if [ "$MANUAL" -gt 0 ]; then
    echo ""
    echo "🔧 手动处理步骤："
    echo "  1. 编辑冲突文件，删除 <<<<<< / ====== / >>>>>> 标记，保留正确内容"
    echo "  2. git add <冲突文件>"
    echo "  3. git add <冲突文件>"
    echo "  4. git commit（完成合并）
  5. 重新运行 bash scripts/push.sh"
    echo "  放弃合并：git merge --abort（回到合并前状态，不丢内容）"
    return 1
  fi

  # 全部自动解决，完成merge commit
  git commit --no-edit 2>/dev/null || true
  return 0
}

# ═══ 主流程 ═══

# 0. 推送前目录锁检查（WO-038/039：多智能体并发保护）
echo "🔍 检查目录锁..."
DIR_LOCK_CONFLICTS=0
if [ -f "scripts/dir-lock.sh" ]; then
  for dir in 角色 技能 共享知识; do
    if [ -d "$dir" ]; then
      LOCK_INFO=$(bash scripts/dir-lock.sh check "$dir" 2>/dev/null)
      if [ $? -eq 0 ]; then
        # 检查是否自己的session锁的
        LOCK_ROLE=$(grep "^ROLE:" "$dir/.目录锁" 2>/dev/null | cut -d: -f2)
        LOCK_SESSION=$(grep "^SESSION:" "$dir/.目录锁" 2>/dev/null | cut -d: -f2)
        if [ "$LOCK_SESSION" != "${SESSION_ID:-unknown}" ]; then
          echo "⚠️ $dir 被 $LOCK_ROLE 锁定，修改中文件: $(grep '^FILES:' "$dir/.目录锁" | cut -d: -f2-)"
          DIR_LOCK_CONFLICTS=1
        fi
      fi
    fi
  done
  if [ "$DIR_LOCK_CONFLICTS" -eq 1 ]; then
    echo "⚠️ 存在目录锁冲突！其他session正在修改这些目录"
    echo "   建议：等待锁释放或与对方协调后再推送"
    echo "   继续推送可能导致对方修改丢失（5秒后继续，Ctrl+C取消）"
    sleep 5
  fi
fi

# 1. 先提交本地变更（先保住工作，不丢）
echo "📦 暂存变更..."

# ═══ 多Agent安全：只add自己改的文件 ═══
# 通过.git/changed-files-$$记录本agent要提交的文件清单
# 避免把其他agent的未完成改动带入自己的commit
CHANGED_FILES_LIST=""
if [ -f ".git/my-changes-$$" ]; then
  # 从预注册文件列表中读取（由edit_file/write_file自动写入）
  CHANGED_FILES_LIST=$(cat .git/my-changes-$$ 2>/dev/null | sort -u)
  rm -f .git/my-changes-$$
fi

if [ -n "$CHANGED_FILES_LIST" ]; then
  echo "📋 只提交本agent改动的文件（${#CHANGED_FILES_LIST[@]}个）:"
  echo "$CHANGED_FILES_LIST" | while read -r f; do echo "   + $f"; done
  echo "$CHANGED_FILES_LIST" | xargs git add --
else
  # 没有预注册清单时，回退到git add -A但给出警告
  echo "⚠️ 未检测到预注册文件清单，回退到 git add -A（可能包含其他agent的变更）"
  echo "   建议：在bash中编辑文件前，先注册: echo 文件路径 >> .git/my-changes-\$\$"
  git add -A
fi

# 记录本agent文件在commit前的content hash（用于merge后验证）
PRE_MERGE_HASHES=""
for f in $(git diff --cached --name-only 2>/dev/null); do
  if [ -f "$f" ]; then
    HASH=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
    PRE_MERGE_HASHES="${PRE_MERGE_HASHES}${f}|${HASH}"$'\n'
  fi
done
echo "$PRE_MERGE_HASHES" > .git/pre-merge-hashes-$$

if git diff --cached --quiet; then
  # 没有新变更，跳过commit，但还是要pull+push确保同步
  echo "ℹ️ 没有新变更需要提交，直接同步远程"
else
  # 自动从git用户名提取平台标识
  PLATFORM_TAG=$(echo "$CURRENT_USER" | grep -oE '\([^)]+\)' | tr -d '()' || echo "未知")
  COMMIT_MSG="sync: ${PLATFORM_TAG} ${MSG}"
  echo "💾 提交：$COMMIT_MSG"
  git commit -m "$COMMIT_MSG"
fi

# 2. 拉取远程最新（merge远程到本地，多智能体仓库不改写历史）
echo "📥 拉取最新..."
if ! git pull --no-rebase origin master 2>&1; then
  echo "⚠️ pull遇到冲突，尝试自动处理..."
  if resolve_merge_conflicts; then
    echo "✅ 冲突已自动解决"
  else
    echo "❌ 存在无法自动处理的冲突"
    echo "💡 本地commit已保存，不会丢失。解决冲突后重跑 push.sh 即可"
    echo "   放弃合并：git merge --abort（回到合并前状态）"
    exit 1
  fi
fi

# 3. 推送（含冲突重试，最多3次）
echo "📤 推送..."
ATTEMPT=1
MAX_ATTEMPTS=3

# ── 推送前反哺检查（机制代替自觉） ──
# 检查本地领先远程的所有commit中，是否有反哺遗漏
echo "🔍 推送前反哺检查..."
MERGE_BASE=$(git merge-base HEAD origin/master 2>/dev/null || echo "HEAD~1")
PENDING_FILES=$(git log --name-only --pretty=format: "$MERGE_BASE..HEAD" | sort -u | grep -v '^$')

WARN_COUNT=0

# ⓪ 部署交接检查：改了部署相关文件，是否需要通知运维？
# 注意：此检查只覆盖体系仓库内的部署文件变更。项目代码仓库的部署交接由开发者手动创建。
DEPLOY_PATTERNS="deploy\.md\|deploy-.*\.sh\|docker-compose.*\.yml\|Dockerfile\|\.env\.example\|nginx.*\.conf"
CHANGED_DEPLOY=$(echo "$PENDING_FILES" | grep -E "$DEPLOY_PATTERNS" || true)
if [ -n "$CHANGED_DEPLOY" ]; then
  # 找到涉及的项目
  DEPLOY_PROJECTS=$(echo "$CHANGED_DEPLOY" | grep -oP '(?<=项目/)[^/]+' | sort -u || true)
  for proj in $DEPLOY_PROJECTS; do
    HANDOVER_FILE="项目/$proj/deploy-handover.md"
    # 已有交接单则跳过（开发者可能已手动创建更详细的）
    if [ ! -f "$HANDOVER_FILE" ]; then
      cat > "$HANDOVER_FILE" << EOF
# 部署交接单（自动生成，开发者请补充详情）

> ⚠️ 有部署变更待运维处理，运维接手时必读本文件
> 生成时间：$(date '+%Y-%m-%d %H:%M')
> 推送者：$CURRENT_USER

## 待部署变更

$(echo "$CHANGED_DEPLOY" | grep "^项目/$proj/" | while read f; do echo "- $f"; done)

## 部署注意事项

（开发者请补充：新环境变量/端口变更/依赖变更等）

## 运维必读

1. 读项目INDEX.md的「部署信息」段，找到部署文档和脚本
2. 读部署文档，确认部署步骤
3. 部署完成后，在本文档底部标记「已部署」并写明结果
EOF
      git add "$HANDOVER_FILE"
      echo "📋 已生成 项目/$proj/deploy-handover.md（部署交接单），请补充部署注意事项后推送"
    fi
  done
fi

# ① 改了体系文件，体系优化追踪也改了吗？
if echo "$PENDING_FILES" | grep -qE "^scripts/|^共享知识/|^templates/|^入口\.md"; then
  if ! echo "$PENDING_FILES" | grep -q "体系优化追踪"; then
    echo "⚠️ ① 改了体系文件（scripts/共享知识/templates/入口），但本次推送没更新体系优化追踪.md！"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
fi

# ①.1 改了体系优化追踪，新条目格式校验
if echo "$PENDING_FILES" | grep -q "体系优化追踪"; then
  OPT_FILE="体系优化追踪.md"
  # 找出新增的OPT条目（本次commit中新增的## OPT-行）
  NEW_OPTS=$(git diff "$MERGE_BASE" HEAD -- "$OPT_FILE" | grep "^+## OPT-" | sed 's/^+//' || true)
  if [ -n "$NEW_OPTS" ]; then
    # 必填字段清单
    REQUIRED_SECTIONS="问题\|讨论过程\|最终方案\|决策原因\|状态"
    for opt_line in $NEW_OPTS; do
      OPT_ID=$(echo "$opt_line" | grep -oP 'OPT-\d+')
      # 提取该条目内容（从## OPT-xxx 到下一个## OPT- 或 --- 之间）
      OPT_START=$(grep -n "^## ${OPT_ID}：" "$OPT_FILE" | head -1 | cut -d: -f1)
      if [ -n "$OPT_START" ]; then
        NEXT_OPT=$(awk "NR>$OPT_START && /^## OPT-/{print NR; exit}" "$OPT_FILE")
        NEXT_SEP=$(awk "NR>$OPT_START && /^---$/{print NR; exit}" "$OPT_FILE")
        OPT_END=$NEXT_SEP
        [ -z "$OPT_END" ] && OPT_END=$(wc -l < "$OPT_FILE")
        [ -n "$NEXT_OPT" ] && [ -n "$OPT_END" ] && [ "$NEXT_OPT" -lt "$OPT_END" ] && OPT_END=$NEXT_OPT
        OPT_CONTENT=$(sed -n "${OPT_START},${OPT_END}p" "$OPT_FILE")
        # 检查每个必填字段
        for field in "问题" "讨论过程" "最终方案" "决策原因" "状态"; do
          if ! echo "$OPT_CONTENT" | grep -q "### $field"; then
            echo "⚠️ ① ${OPT_ID} 缺少必填字段「${field}」！请对照 templates/OPT-TRACK.template.md 补全"
            WARN_COUNT=$((WARN_COUNT + 1))
          fi
        done
      fi
    done
  fi
fi

# ② 改了角色文件，角色INDEX也改了吗？
CHANGED_ROLES=$(echo "$PENDING_FILES" | grep -oP '(?<=角色/)[^/]+' | sort -u)
if [ -n "$CHANGED_ROLES" ]; then
  for role in $CHANGED_ROLES; do
    if ! echo "$PENDING_FILES" | grep -q "角色/$role/INDEX.md"; then
      echo "⚠️ ② 改了角色/$role/ 的文件，但没更新角色/$role/INDEX.md！"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  done
fi

# ③ 改了项目文件，项目INDEX也改了吗？
CHANGED_PROJECTS=$(echo "$PENDING_FILES" | grep -oP '(?<=项目/)[^/]+' | sort -u)
if [ -n "$CHANGED_PROJECTS" ]; then
  for proj in $CHANGED_PROJECTS; do
    if ! echo "$PENDING_FILES" | grep -q "项目/$proj/INDEX.md"; then
      echo "⚠️ ③ 改了项目/$proj/ 的文件，但没更新项目/$proj/INDEX.md！"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  done
fi

if [ $WARN_COUNT -gt 0 ]; then
  echo ""
  echo "🚨 推送前检查发现 ${WARN_COUNT} 项反哺遗漏！"
  echo "   请补全后再推送——推送≠任务完成，反哺没做等于白干"
  echo ""
  echo "   💡 快速补全："
  echo "      改了角色 → 更新 角色/<角色名>/INDEX.md"
  echo "      改了项目 → 更新 项目/<项目名>/INDEX.md"
  echo "      改了体系 → 更新 体系优化追踪.md"
  echo ""
  if [ "$AUTO_CONFIRM" = "1" ]; then
    echo "   ⚡ -y 模式：跳过确认继续推送（仅用于已确认反哺完整但脚本检测不到的场景）"
  else
    read -p "   强制推送？[y/N] " FORCE_PUSH
    [ "$FORCE_PUSH" != "y" ] && exit 1
    echo "   ⚡ 强制推送中..."
  fi
fi

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  if git push origin master 2>&1; then
    echo "✅ 推送成功"

    # ── 推送后校验：content hash对比（比行级grep更精准） ──
    HASH_MISMATCH=0
    HASH_MISSING=0
    if [ -f ".git/pre-merge-hashes-$$" ]; then
      echo "🔍 merge后内容校验（content hash对比）..."
      while IFS='|' read -r f hash; do
        [ -z "$f" ] && continue
        if [ -f "$f" ]; then
          NOW_HASH=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
          if [ "$hash" != "$NOW_HASH" ]; then
            echo "   🔄 $f merge后内容变化（其他agent可能也改了同文件，正常）"
          fi
        else
          echo "   🚨 $f 在merge后消失！"
          HASH_MISSING=$((HASH_MISSING+1))
        fi
      done < .git/pre-merge-hashes-$$
      rm -f .git/pre-merge-hashes-$$
      if [ "$HASH_MISSING" -gt 0 ]; then
        echo ""
        echo "🚨 merge导致 ${HASH_MISSING} 个文件丢失！"
        echo "   排查：git log --oneline -5"
        echo "   恢复：git reflog 找回原commit → 对比 diff → cherry-pick"
      else
        echo "✅ merge后校验通过，无文件丢失"
      fi
    else
      # 回退到旧的行级校验
      if [ -f .git/our-lines-$$.tmp ]; then
        echo "🔍 merge后内容校验（行级）..."
        MISSING=0
        while IFS= read -r line; do
          if [ -n "$line" ]; then
            FOUND=0
            for f in $PENDING_FILES; do
              if [ -f "$f" ] && grep -qF "$line" "$f" 2>/dev/null; then
                FOUND=1
                break
              fi
            done
            if [ $FOUND -eq 0 ]; then
              MISSING=$((MISSING + 1))
              [ "$MISSING" -le 3 ] && echo "   ❌ 丢失行：$line"
            fi
          fi
        done < .git/our-lines-$$.tmp
        rm -f .git/our-lines-$$.tmp
        if [ "$MISSING" -gt 0 ]; then
          echo "🚨 merge导致 ${MISSING} 行内容丢失！"
          echo "   恢复：git reflog 找回原commit → cherry-pick"
        else
          echo "✅ merge后内容校验通过"
        fi
      fi
    fi

    # 推送成功后重建搜索索引
    echo "🔧 重建搜索索引..."
    bash scripts/rebuild-index.sh
    
    # ═══ 推送后验证：对比本地和远程内容是否一致 ═══
    echo "🔍 推送后内容验证..."
    VERIFY_FAIL=0
    for f in $PENDING_FILES; do
      [ -f "$f" ] || continue
      # 跳过二进制和超大文件
      SIZE=$(wc -c < "$f" 2>/dev/null || echo 0)
      [ "$SIZE" -gt 500000 ] && continue
      # 对比本地文件与远程HEAD中的文件
      REMOTE_CONTENT=$(git show "origin/master:$f" 2>/dev/null || echo "__MISSING__")
      if [ "$REMOTE_CONTENT" = "__MISSING__" ]; then
        echo "   ⚠️ $f 在远程不存在（可能是新文件，验证跳过）"
        continue
      fi
      LOCAL_CONTENT=$(cat "$f" 2>/dev/null || echo "")
      if [ "$LOCAL_CONTENT" != "$REMOTE_CONTENT" ]; then
        # 内容不一致——可能被另一个agent的push覆盖了
        LOCAL_LINES=$(echo "$LOCAL_CONTENT" | wc -l | tr -d ' ')
        REMOTE_LINES=$(echo "$REMOTE_CONTENT" | wc -l | tr -d ' ')
        echo "   🚨 $f 内容不一致! 本地${LOCAL_LINES}行 vs 远程${REMOTE_LINES}行"
        VERIFY_FAIL=$((VERIFY_FAIL+1))
      fi
    done
    if [ "$VERIFY_FAIL" -gt 0 ]; then
      echo ""
      echo "═══════════════════════════════════════"
      echo "🚨 推送后验证失败！${VERIFY_FAIL}个文件内容不一致"
      echo "═══════════════════════════════════════"
      echo ""
      echo "   可能原因：另一个agent在你push的同时也push了，merge后覆盖了你的内容"
      echo "   排查："
      echo "     git log --oneline -5   # 看最近几次commit"
      echo "     git reflog             # 找回你的commit"
      echo "     git diff HEAD~1..HEAD  # 看最后一次merge改了什么"
      echo ""
      echo "   恢复：找回原commit → 重新应用变更 → 再push"
    else
      echo "✅ 推送后验证通过，远程内容与本地一致"
    fi
    
    exit 0
  fi

  echo "⚠️ 推送失败（第${ATTEMPT}次），拉取后重试..."
  if git pull --no-rebase origin master 2>&1; then
    # 记录本次commit新增的行（用于校验merge是否丢内容）
    > .git/our-lines-$$.tmp
    for f in $PENDING_FILES; do
      if [ -f "$f" ]; then
        git diff "$MERGE_BASE" HEAD -- "$f" 2>/dev/null | grep "^+" | grep -v "^+++" | sed 's/^+//' >> .git/our-lines-$$.tmp
      fi
    done
    ATTEMPT=$((ATTEMPT + 1))
    continue
  fi

  echo "⚠️ pull遇到冲突，尝试自动处理..."
  if resolve_merge_conflicts; then
    ATTEMPT=$((ATTEMPT + 1))
    continue
  else
    echo "❌ 冲突需人工处理，推送中止"
    echo "💡 本地commit已保存，不会丢失"
    exit 1
  fi
done

echo "❌ 重试${MAX_ATTEMPTS}次仍失败，请手动处理"
exit 1
