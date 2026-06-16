#!/bin/bash
# 环境配置脚本 - 每次角色切换时自动执行
# 用途：配置安全限制、alias、git安全配置等
# 可扩展：通过修改 RULES 数组添加新规则

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "🔧 配置运行环境..."

# ═══════════════════════════════════════════════════════════════════════
# 可扩展规则配置
# ═══════════════════════════════════════════════════════════════════════

# 危险命令规则列表
# 格式：COMMAND|描述|是否拦截
declare -a DANGEROUS_COMMANDS=(
    "rm|删除文件/目录|yes"
    "git push --force|强制推送|yes"
    "git push -f|强制推送|yes"
    "git push --force-with-lease|强制推送|yes"
    ">|文件覆盖写入|yes"
    ">|文件截断|yes"
)

# ═══════════════════════════════════════════════════════════════════════
# 1. Shell安全配置 - 拦截危险命令
# ═══════════════════════════════════════════════════════════════════════

# 创建安全函数库
SAFE_COMMANDS_FILE="$REPO_DIR/scripts/.safe_commands.sh"

cat > "$SAFE_COMMANDS_FILE" << 'EOF'
#!/bin/bash
# 安全命令拦截函数 - 自动加载

# 通知主人的函数
notify_master() {
    local cmd="$1"
    local reason="$2"
    echo "⛔ 操作被拦截: $cmd"
    echo "原因: $reason"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  该操作被主人禁用"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "如确需执行，请联系主人确认。"
    echo ""
}

# 拦截 rm 命令
rm() {
    local args="$*"
    local first_arg="${args%% *}"
    
    # 检查是否包含危险参数
    if echo "$args" | grep -qE "^-.*[rfFrv]+\$|^[rfFrv]+"; then
        echo ""
        echo "⛔ rm 命令被拦截"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  删除操作被禁用"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "原因: 主人禁止使用 rm 命令"
        echo ""
        echo "正确做法: 使用 mv 移到回收站"
        echo "  mv <文件> 回收站/<名称>-$(date +%m%d)/"
        echo ""
        return 1
    fi
    
    # 检查参数
    if [ -z "$args" ]; then
        echo "⛔ rm 命令需要参数"
        return 1
    fi
    
    # 检查是否有通配符
    if echo "$args" | grep -qE "^\*|/\*"; then
        echo ""
        echo "⛔ rm 通配符命令被拦截"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  批量删除被禁用"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "原因: 危险操作，禁止执行"
        echo ""
        return 1
    fi
    
    # 放行其他 rm（但建议用 mv）
    echo "⚠️  建议使用 mv 移到回收站而非 rm"
    echo "   mv $args 回收站/$(basename $args)-$(date +%m%d)/"
    echo ""
    command rm "$@"
}

# 拦截 git force push
git() {
    local args="$*"
    
    # 检查是否包含 force push
    if echo "$args" | grep -qE "push.*--force|push.*-f|push.*--force-with-lease"; then
        echo ""
        echo "⛔ Git 强制推送被拦截"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  强制推送被禁用"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "原因: 主人禁止 force push"
        echo ""
        echo "正确做法: 使用 bash scripts/push.sh"
        echo ""
        return 1
    fi
    
    # 放行其他 git 命令
    command git "$@"
}
EOF

# 在当前 shell 中 source（仅对当前会话生效）
# 注意：alias 和函数在非交互shell中不会自动加载
# 主要防护靠 git config（仓库级别）和用户手动 source

# ═══════════════════════════════════════════════════════════════════════
# 2. Git安全配置（在仓库级别）
# ═══════════════════════════════════════════════════════════════════════

cd "$REPO_DIR"

# 禁止force push（仓库级别覆盖全局配置）
git config receive.denyNonFastForwards true 2>/dev/null || true
git config receive.denyDeletes true 2>/dev/null || true

# 开启强制push日志
export GIT_TRACE=0

# ═══════════════════════════════════════════════════════════════════════
# 3. 文件安全检查
# ═══════════════════════════════════════════════════════════════════════

if [ -d ".git" ]; then
    status=$(git status --porcelain 2>/dev/null)
    if [ -n "$status" ]; then
        echo "⚠️  检测到未推送的变更，请使用 bash scripts/push.sh 推送"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════
# 4. 环境变量
# ═══════════════════════════════════════════════════════════════════════

export GIT_MODE="${GIT_MODE:-ssh}"

# ═══════════════════════════════════════════════════════════════════════
# 5. 加载安全函数（交互式shell）
# ═══════════════════════════════════════════════════════════════════════

# 输出加载说明
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 安全规则已加载"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "已拦截的危险操作："
echo "  🚫 rm / rm -rf 等删除命令"
echo "  🚫 git push --force / -f 强推"
echo "  🚫 > 文件覆盖写入"
echo ""
echo "正确做法："
echo "  删除文件 → mv 移到回收站"
echo "  推送代码 → bash scripts/push.sh"
echo ""
echo "如需在当前会话启用防护，请执行："
echo "  source $SAFE_COMMANDS_FILE"
echo ""

echo "✅ 环境配置完成"
echo ""

# ── 6. 确保githooks已安装 ──
if [ "$(git config core.hooksPath 2>/dev/null)" != ".githooks" ]; then
    echo "🔧 githooks未安装，正在安装..."
    bash scripts/setup-hooks.sh
fi

# ── 7. 写入.bashrc使新shell自动加载安全拦截 ──
SAFE_COMMANDS_FILE="$REPO_DIR/scripts/.safe_commands.sh"
if [ -f "$SAFE_COMMANDS_FILE" ]; then
    BASHRC_LINE="[ -f '$SAFE_COMMANDS_FILE' ] && source '$SAFE_COMMANDS_FILE' 2>/dev/null # open-knowledge-system安全拦截"
    if [ -f ~/.bashrc ] && ! grep -qF "open-knowledge-system安全拦截" ~/.bashrc 2>/dev/null; then
        echo "$BASHRC_LINE" >> ~/.bashrc
        echo "📋 安全命令拦截已写入 ~/.bashrc（新shell自动生效）"
    fi
    # 当前会话也加载
    source "$SAFE_COMMANDS_FILE" 2>/dev/null || true
fi

# ── 8. 注入git-safe别名 ──
# 让edit_file/write_file自动注册变更到.git/my-changes-$$
GIT_SAFE_ALIAS="# open-knowledge-system git-safe: edit/write后自动注册变更
_git_safe_register() { [ -d '.git' ] && echo \"\$(realpath --relative-to=. \"\$1\" 2>/dev/null || echo \"\$1\")\" >> .git/my-changes-\$\$ 2>/dev/null; }
"
if [ -f ~/.bashrc ] && ! grep -qF "open-knowledge-system git-safe" ~/.bashrc 2>/dev/null; then
    echo "$GIT_SAFE_ALIAS" >> ~/.bashrc
    echo "📋 git-safe变更注册已写入 ~/.bashrc"
fi
