#!/bin/bash
# SSH密钥管理脚本 v2.0
# SSH密钥管理脚本 v2.1 — 移除硬编码GIT_PAT，改为环境变量+decrypt.sh
>>>>>>> origin/master
# 功能：生成/加密/解密/切换SSH模式/配置SSH
# 用法：bash scripts/ssh-init.sh [gen|encrypt|decrypt|switch|check|setup]
# 
# 新增功能：
#   - 支持自定义密钥名称（默认id_rsa_github）
#   - 自动配置SSH config
#   - 支持传入密钥文件路径解密
#   - push.sh自动集成SSH模式

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"
SSH_KEY_DIR="$HOME/.ssh"
SSH_KEY_NAME="${SSH_KEY_NAME:-id_rsa_github}"  # 默认id_rsa_github
SSH_KEY="$SSH_KEY_DIR/$SSH_KEY_NAME"
SSH_KEY_PUB="$SSH_KEY_DIR/${SSH_KEY_NAME}.pub"
SSH_CONFIG="$SSH_KEY_DIR/config"
ENCRYPTED_KEY="共享知识/凭据/github-deploy-key.enc"
ENCRYPTED_PASS="共享知识/凭据/ssh-passphrase.enc"
GIT_PAT="${GIT_PAT:-}"
# GIT_PAT从环境变量读取（init.sh调用时传入），或从decrypt.sh解密获取
# 禁止硬编码token到脚本中
_get_git_pat() {
  if [ -n "$GIT_PAT" ]; then
    echo "$GIT_PAT"
    return
  fi
  # 尝试从decrypt.sh获取（需要MASTER_KEY环境变量）
  if [ -n "$MASTER_KEY" ] && [ -f "$REPO_DIR/共享知识/凭据/decrypt.sh" ]; then
    local pat
    pat=$(bash "$REPO_DIR/共享知识/凭据/decrypt.sh" "$MASTER_KEY" "github.pat" 2>/dev/null || echo "")
    if [ -n "$pat" ]; then
      echo "$pat"
      return
    fi
  fi
  echo ""
}
>>>>>>> origin/master

# ═══ 锁文件处理 ═══
LOCK_FD=9
LOCK_FILE=".git/ops.lock"
exec 9>"$LOCK_FILE"
if ! flock -n $LOCK_FD; then
  echo "⚠️ 前方有git操作进行中，请稍后重试"
  exit 1
fi
echo "ssh-init.sh | PID:$$ | $(date '+%H:%M:%S')" >&9

# ═══ 颜色定义 ═══
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ═══ 检查函数 ═══
check_key() {
  if [ -f "$SSH_KEY" ]; then
    log_info "SSH密钥已存在: $SSH_KEY"
    return 0
  else
    log_warn "SSH密钥不存在: $SSH_KEY"
    return 1
  fi
}

check_repo_key() {
  if [ -f "$ENCRYPTED_KEY" ]; then
    log_info "仓库加密密钥已存在: $ENCRYPTED_KEY"
    return 0
  else
    log_error "仓库加密密钥不存在: $ENCRYPTED_KEY"
    return 1
  fi
}

# ═══ SSH Config配置 ═══
setup_ssh_config() {
  local KEY_NAME="$1"
  local KEY_PATH="$SSH_KEY_DIR/$KEY_NAME"
  
  mkdir -p "$SSH_KEY_DIR"
  
  # 如果没有config则创建
  if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
  fi
  
  # 检查是否已配置GitHub
  if grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    log_info "SSH config已配置GitHub"
  else
    cat >> "$SSH_CONFIG" << EOF

Host github.com
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF
    log_info "SSH config已添加GitHub配置"
  fi
  
  chmod 600 "$SSH_CONFIG"
}

# ═══ 主命令 ═══
CMD="${1:-}"

case "$CMD" in
  check)
    log_info "=== 检查SSH密钥状态 ==="
    check_key
    check_repo_key
    log_info "检查完成"
    ;;

  setup)
    log_info "=== 配置SSH密钥 ==="
    
    # 1. 解密密钥（如果存在加密版本）
    if [ -f "$ENCRYPTED_KEY" ]; then
      log_info "发现加密密钥，尝试解密..."
      
      # 尝试从加密文件解密密码
      if [ -f "$ENCRYPTED_PASS" ]; then
        DECRYPT_PASS=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass pass:$GIT_PAT -base64 -in "$ENCRYPTED_PASS" 2>/dev/null || echo "")
        DECRYPT_PASS=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass pass:$(_get_git_pat) -base64 -in "$ENCRYPTED_PASS" 2>/dev/null || echo "")
>>>>>>> origin/master
        
        if [ -n "$DECRYPT_PASS" ]; then
          log_info "解密密钥密码成功"
          
          # 检查密钥是否已解密
          if ssh-keygen -y -f "$SSH_KEY" >/dev/null 2>&1; then
            log_info "密钥已解密可直接使用"
          else
            # 密钥是加密的，需要解密
            log_info "密钥加密中，尝试解密..."
            openssl rsa -in "$SSH_KEY" -passin pass:"$DECRYPT_PASS" -out "$SSH_KEY" 2>/dev/null && \
              chmod 600 "$SSH_KEY" && log_info "密钥解密成功" || \
              log_warn "密钥解密失败，密码可能不正确"
          fi
        fi
      fi
    fi
    
    # 2. 配置SSH config
    setup_ssh_config "$SSH_KEY_NAME"
    
    # 3. 测试连接
    log_info "测试SSH连接..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully"; then
      log_info "✅ SSH连接成功"
    else
      log_warn "⚠️ SSH连接失败，请检查密钥配置"
    fi
    ;;

  gen)
    log_info "=== 生成SSH密钥 ==="
    if check_key; then
      log_warn "密钥已存在，跳过生成"
      log_info "如需重新生成，请先备份并删除 $SSH_KEY"
      exit 0
    fi
    
    mkdir -p "$SSH_KEY_DIR"
    chmod 700 "$SSH_KEY_DIR"
    ssh-keygen -t ed25519 -C "xiaolong_steward@coze.email" -f "$SSH_KEY" -N ""
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY_PUB"
    
    # 配置SSH config
    setup_ssh_config "$SSH_KEY_NAME"
    
    log_info "SSH密钥已生成:"
    echo "  私钥: $SSH_KEY"
    echo "  公钥: $SSH_KEY_PUB"
    echo ""
    echo "公钥内容（添加到GitHub）："
    cat "$SSH_KEY_PUB"
    echo ""
    log_warn "请把上方公钥添加到GitHub账号（Settings → SSH Keys）"
    ;;

  encrypt)
    log_info "=== 加密本地SSH密钥到仓库 ==="
    if ! check_key; then
      log_error "本地密钥不存在，请先运行: bash scripts/ssh-init.sh gen"
      exit 1
    fi
    
    if [ -z "$ENCRYPT_PASSWORD" ]; then
      log_error "请设置加密密码环境变量: ENCRYPT_PASSWORD=xxx bash scripts/ssh-init.sh encrypt"
      exit 1
    fi
    
    # 加密私钥
    cat "$SSH_KEY" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -pass pass:$ENCRYPT_PASSWORD -base64 -o "$ENCRYPTED_KEY"
    
    # 提交到仓库
    git add "$ENCRYPTED_KEY"
    git commit -m "feat: 添加SSH加密密钥" || log_warn "密钥已存在，无需提交"
    git push origin master
    
    log_info "SSH密钥已加密存入仓库: $ENCRYPTED_KEY"
    ;;

  decrypt)
    log_info "=== 从仓库解密SSH密钥到本地 ==="
    
    # 支持自定义密钥文件和密码
    KEY_FILE="${1:-}"  # 可选：传入密钥文件路径
    DECRYPT_PASS="${2:-}"  # 可选：传入密码
    
    if [ -n "$KEY_FILE" ] && [ -f "$KEY_FILE" ]; then
      # 使用传入的密钥文件
      log_info "使用传入的密钥文件: $KEY_FILE"
      mkdir -p "$SSH_KEY_DIR"
      chmod 700 "$SSH_KEY_DIR"
      
      # 尝试解密
      if [ -n "$DECRYPT_PASS" ]; then
        openssl rsa -in "$KEY_FILE" -passin pass:"$DECRYPT_PASS" -out "$SSH_KEY" && \
          chmod 600 "$SSH_KEY" && log_info "密钥解密成功: $SSH_KEY" || \
          log_error "密钥解密失败"
      else
        log_error "请传入密码: bash scripts/ssh-init.sh decrypt <密钥文件> <密码>"
        exit 1
      fi
    elif check_repo_key; then
      # 使用仓库加密的密钥
      if [ -z "$DECRYPT_PASSWORD" ] && [ -z "$DECRYPT_PASS" ]; then
        log_error "请设置解密密码环境变量: DECRYPT_PASSWORD=xxx bash scripts/ssh-init.sh decrypt"
        exit 1
      fi
      
      PASS="${DECRYPT_PASSWORD:-$DECRYPT_PASS}"
      
      # 检查是否已有密钥
      if check_key; then
        log_warn "本地密钥已存在，解密会覆盖"
        cp "$SSH_KEY" "${SSH_KEY}.bak" 2>/dev/null || true
      fi
      
      # 解密
      mkdir -p "$SSH_KEY_DIR"
      chmod 700 "$SSH_KEY_DIR"
      openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass pass:$PASS -in "$ENCRYPTED_KEY" -base64 -out "$SSH_KEY"
      chmod 600 "$SSH_KEY"
      
      log_info "SSH密钥已解密到本地: $SSH_KEY"
    else
      log_error "仓库加密密钥不存在，且未传入密钥文件"
      exit 1
    fi
    
    # 生成公钥
    if [ ! -f "$SSH_KEY_PUB" ]; then
      ssh-keygen -y -f "$SSH_KEY" > "$SSH_KEY_PUB"
      chmod 644 "$SSH_KEY_PUB"
    fi
    
    # 配置SSH config
    setup_ssh_config "$SSH_KEY_NAME"
    ;;

  switch)
    log_info "=== 切换仓库到SSH模式 ==="
    
    CURRENT_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -z "$CURRENT_URL" ]; then
      log_error "未找到origin remote"
      exit 1
    fi
    
    if echo "$CURRENT_URL" | grep -q "^git@github.com"; then
      log_info "已是SSH模式: $CURRENT_URL"
      exit 0
    fi
    
    if echo "$CURRENT_URL" | grep -q "github.com"; then
      REPO_PATH=$(echo "$CURRENT_URL" | sed -n 's|.*github.com/[^/]*/\([^/]*\.git\)|\1|p')
      USER=$(echo "$CURRENT_URL" | sed -n 's|.*github.com/\([^/]*\)/.*|\1|p')
      
      SSH_URL="git@github.com:${USER}/${REPO_PATH}"
      
      log_info "切换: $CURRENT_URL"
      log_info "  → $SSH_URL"
      
      git remote set-url origin "$SSH_URL"
      log_info "已切换到SSH模式"
      log_warn "请确保GitHub已添加SSH公钥，否则无法推送"
    else
      log_error "无法识别仓库URL格式: $CURRENT_URL"
      exit 1
    fi
    ;;

  status)
    log_info "=== SSH状态 ==="
    echo ""
    echo "当前密钥: $SSH_KEY_NAME"
    echo "本地密钥:"
    if check_key; then
      echo "  ✅ 存在: $SSH_KEY"
      # 检查密钥是否加密
      if ssh-keygen -y -f "$SSH_KEY" >/dev/null 2>&1; then
        echo "  状态: 已解密"
      else
        echo "  状态: 加密（需要解密）"
      fi
    else
      echo "  ❌ 不存在"
    fi
    echo ""
    echo "仓库加密密钥:"
    if check_repo_key; then
      echo "  ✅ 存在: $ENCRYPTED_KEY"
    else
      echo "  ❌ 不存在"
    fi
    echo ""
    echo "Git Remote:"
    git remote -v | sed 's/^/  /'
    ;;

  *)
    echo "SSH密钥管理脚本 v2.0"
    echo ""
    echo "用法: bash scripts/ssh-init.sh <command> [参数...]"
    echo ""
    echo "命令:"
    echo "  check           - 检查密钥状态"
    echo "  setup          - 一键配置SSH（解密+config+测试连接）"
    echo "  gen            - 生成新SSH密钥"
    echo "  encrypt        - 加密本地密钥存仓库（需设置ENCRYPT_PASSWORD）"
    echo "  decrypt [文件] [密码] - 解密仓库密钥到本地"
    echo "  switch         - 把仓库从HTTPS切换到SSH模式"
    echo "  status         - 查看完整状态"
    echo ""
    echo "环境变量:"
    echo "  SSH_KEY_NAME=id_rsa_github  # 指定密钥名称（默认id_rsa_github）"
    echo ""
    echo "示例:"
    echo "  # 一键配置（推荐）"
    echo "  bash scripts/ssh-init.sh setup"
    echo ""
    echo "  # 指定密钥文件解密"
    echo "  bash scripts/ssh-init.sh decrypt /path/to/key songjian"
    echo ""
    echo "  # 查看状态"
    echo "  bash scripts/ssh-init.sh status"
    echo ""
    echo "  # 切换到SSH模式"
    echo "  bash scripts/ssh-init.sh switch"
    ;;
esac
