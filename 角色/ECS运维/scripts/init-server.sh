#!/bin/bash
# ==============================================================================
# 服务器初始化脚本
# 用途：新服务器迁移后一键初始化，包括Docker安装、镜像源配置、
#       Remote Gateway启动、所有Compose服务部署
# 使用：chmod +x init-server.sh && ./init-server.sh 2>&1 | tee /root/init-server.log
# 作者：小龙 🦎
# 更新：2026-05-08
# ==============================================================================

set -u  # 未定义变量报错（不用set -e，避免某服务失败导致整个脚本中断）

# ======================== 配置区 ========================

# 项目根目录
SONGJIAN_DIR="/root/songjian"

# Remote Gateway 配置
GATEWAY_DIR="${SONGJIAN_DIR}/remote-gateway"
GATEWAY_SERVICE="/etc/systemd/system/remote-gateway.service"

# Compose 部署目录
COMPOSE_DIR="${SONGJIAN_DIR}/docker-compose"

# 主 compose 文件（WordPress/Nginx/MySQL/FRP 等）
MAIN_COMPOSE="${COMPOSE_DIR}/docker-compose.yml"

# 日志文件
LOG_FILE="/root/init-server.log"

# 部署结果统计
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FAILED_LIST=""
SKIPPED_LIST=""

# ======================== 工具函数 ========================

# 带时间戳的日志输出
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${msg}" | tee -a "${LOG_FILE}"
}

log_info()  { log "INFO "  "$@"; }
log_ok()    { log "  OK "  "$@"; }
log_warn()  { log "WARN "  "$@"; }
log_fail()  { log "FAIL "  "$@"; }
log_step()  { log "STEP "  "$@"; }

# 记录成功/失败
record_ok()   { ((SUCCESS_COUNT++)); log_ok "$1"; }
record_fail() { ((FAIL_COUNT++)); FAILED_LIST="${FAILED_LIST}\n  - $1"; log_fail "$1"; }
record_skip() { ((SKIP_COUNT++)); SKIPPED_LIST="${SKIPPED_LIST}\n  - $1"; log_warn "跳过: $1"; }

# ======================== 第一步：系统基础配置 ========================

log_step "========== 第1步：系统基础配置 =========="

# 1.1 设置时区
log_info "设置时区为 Asia/Shanghai"
timedatectl set-timezone Asia/Shanghai 2>/dev/null && record_ok "时区设置" || record_fail "时区设置"

# 1.2 更新系统（可选，首次建议执行）
log_info "更新系统软件包（跳过，迁移服务器不需要）"
# apt-get update && apt-get upgrade -y

# ======================== 第二步：安装 Docker ========================

log_step "========== 第2步：安装 Docker =========="

if command -v docker &>/dev/null; then
    log_info "Docker 已安装: $(docker --version)"
    record_skip "Docker 安装（已存在）"
else
    log_info "开始安装 Docker..."

    # 2.1 卸载旧版本
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null

    # 2.2 安装依赖
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 2.3 添加 Docker 官方 GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # 2.4 添加 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 2.5 安装 Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 2.6 启动并设置开机自启
    systemctl start docker
    systemctl enable docker

    if command -v docker &>/dev/null; then
        record_ok "Docker 安装 ($(docker --version))"
    else
        record_fail "Docker 安装"
    fi
fi

# ======================== 第三步：配置 Docker 国内镜像源 ========================

log_step "========== 第3步：配置 Docker 国内镜像源 =========="

DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

# 国内镜像源列表（从原服务器拷贝，已验证可用）
cat > "${DOCKER_DAEMON_JSON}" << 'DAEMONJSON'
{
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
DAEMONJSON

log_info "已写入 Docker 镜像源配置: ${DOCKER_DAEMON_JSON}"
cat "${DOCKER_DAEMON_JSON}" | tee -a "${LOG_FILE}"

# 重载 Docker 配置
systemctl daemon-reload
systemctl restart docker

if systemctl is-active docker &>/dev/null; then
    record_ok "Docker 镜像源配置并重启"
else
    record_fail "Docker 镜像源配置（Docker 重启失败）"
fi

# 验证镜像源
log_info "验证 Docker 镜像源..."
docker info 2>/dev/null | grep -A5 "Registry Mirrors" | tee -a "${LOG_FILE}"

# ======================== 第四步：创建 Docker 网络 ========================

log_step "========== 第4步：创建 Docker 网络 =========="

if docker network inspect c_bridge &>/dev/null; then
    log_info "c_bridge 网络已存在"
    record_skip "c_bridge 网络创建（已存在）"
else
    docker network create c_bridge
    if docker network inspect c_bridge &>/dev/null; then
        record_ok "c_bridge 网络创建"
    else
        record_fail "c_bridge 网络创建"
    fi
fi

# ======================== 第五步：加载自定义镜像 ========================

log_step "========== 第5步：加载自定义镜像（如有导出文件） =========="

# 自定义镜像列表（这些无法从公共仓库 pull，需要提前导出/导入）
# 如果有 .tar 导出文件，放在 /root/songjian/docker-images/ 目录下
CUSTOM_IMAGE_DIR="${SONGJIAN_DIR}/docker-images"

if [[ -d "${CUSTOM_IMAGE_DIR}" ]]; then
    for tar_file in "${CUSTOM_IMAGE_DIR}"/*.tar; do
        if [[ -f "${tar_file}" ]]; then
            log_info "加载镜像: ${tar_file}"
            docker load -i "${tar_file}" && record_ok "加载镜像 $(basename "${tar_file}")" || record_fail "加载镜像 $(basename "${tar_file}")"
        fi
    done
else
    log_info "未找到自定义镜像目录 ${CUSTOM_IMAGE_DIR}，跳过"
    record_skip "自定义镜像加载（目录不存在）"
fi

# ======================== 第六步：部署主 Compose 服务 ========================

log_step "========== 第6步：部署主 Compose 服务（WordPress/Nginx/MySQL/FRP等） =========="

if [[ -f "${MAIN_COMPOSE}" ]]; then
    log_info "启动主 Compose 服务: ${MAIN_COMPOSE}"
    cd "$(dirname "${MAIN_COMPOSE}")"

    # 先 pull 公共镜像（MySQL/Nginx/WordPress等）
    log_info "拉取公共镜像（可能较慢，取决于带宽）..."
    docker compose pull 2>&1 | tee -a "${LOG_FILE}" || true

    # 启动服务
    docker compose up -d 2>&1 | tee -a "${LOG_FILE}"
    if [[ $? -eq 0 ]]; then
        record_ok "主 Compose 服务启动"
    else
        record_fail "主 Compose 服务启动"
    fi
else
    record_fail "主 Compose 文件不存在: ${MAIN_COMPOSE}"
fi

# ======================== 第七步：部署各子项目（deploy-*.sh） ========================

log_step "========== 第7步：部署各子项目 =========="

# 子项目部署顺序（按依赖关系排序）
# MySQL 需要先启动，WordPress 依赖它
DEPLOY_ORDER=(
    "srs"       # SRS 流媒体，无依赖
    "vcmix"     # VCMix 混音宿主，无依赖
    "openclaw"  # OpenClaw，无依赖（需要自定义镜像）
    "hermes"    # Hermes，暂不可用（Python 3.13 bug）
)

for project in "${DEPLOY_ORDER[@]}"; do
    project_dir="${COMPOSE_DIR}/${project}"
    deploy_script="${project_dir}/deploy-${project}.sh"
    compose_file="${project_dir}/docker-compose.yml"

    log_info "---- 部署项目: ${project} ----"

    # 检查项目目录是否存在
    if [[ ! -d "${project_dir}" ]]; then
        record_skip "${project}（目录不存在）"
        continue
    fi

    # 优先使用 deploy 脚本
    if [[ -f "${deploy_script}" ]]; then
        log_info "执行部署脚本: ${deploy_script}"
        chmod +x "${deploy_script}"
        cd "${project_dir}"
        bash "${deploy_script}" 2>&1 | tee -a "${LOG_FILE}"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            record_ok "${project} 部署脚本执行"
        else
            record_fail "${project} 部署脚本执行"
        fi
    elif [[ -f "${compose_file}" ]]; then
        # 没有 deploy 脚本则直接 docker compose up
        log_info "无 deploy 脚本，直接启动: ${compose_file}"
        cd "${project_dir}"
        docker compose up -d 2>&1 | tee -a "${LOG_FILE}"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            record_ok "${project} docker compose up"
        else
            record_fail "${project} docker compose up"
        fi
    else
        record_skip "${project}（无部署脚本也无 compose 文件）"
    fi
done

# ======================== 第八步：安装 PyYAML ========================

log_step "========== 第8步：安装 Python 依赖（PyYAML） =========="

if python3 -c "import yaml" 2>/dev/null; then
    log_info "PyYAML 已安装"
    record_skip "PyYAML 安装（已存在）"
else
    pip3 install pyyaml -q 2>&1 | tee -a "${LOG_FILE}"
    if python3 -c "import yaml" 2>/dev/null; then
        record_ok "PyYAML 安装"
    else
        record_fail "PyYAML 安装"
    fi
fi

# ======================== 第九步：启动 Remote Gateway ========================

log_step "========== 第9步：启动 Remote Gateway HTTP 命令网关 =========="

# 9.1 检查配置文件
if [[ ! -f "${GATEWAY_DIR}/config.yaml" ]]; then
    record_fail "Remote Gateway 配置文件不存在: ${GATEWAY_DIR}/config.yaml"
else
    log_info "配置文件: ${GATEWAY_DIR}/config.yaml"
fi

if [[ ! -f "${GATEWAY_DIR}/gateway.py" ]]; then
    record_fail "Remote Gateway 主程序不存在: ${GATEWAY_DIR}/gateway.py"
else
    log_info "主程序: ${GATEWAY_DIR}/gateway.py"
fi

# 9.2 安装 systemd 服务
if [[ -f "${GATEWAY_DIR}/../gateway/gateway.service" ]]; then
    # 从本地 skill 目录复制
    cp "${GATEWAY_DIR}/../gateway/gateway.service" "${GATEWAY_SERVICE}"
fi

# 如果 service 文件不存在，直接创建
if [[ ! -f "${GATEWAY_SERVICE}" ]]; then
    cat > "${GATEWAY_SERVICE}" << 'SERVICEEOF'
[Unit]
Description=Remote Command Gateway
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/songjian/remote-gateway
ExecStart=/usr/bin/python3 /root/songjian/remote-gateway/gateway.py
Restart=always
RestartSec=5
Environment=GATEWAY_CONFIG=/root/songjian/remote-gateway/config.yaml

[Install]
WantedBy=multi-user.target
SERVICEEOF
    log_info "已创建 systemd 服务文件: ${GATEWAY_SERVICE}"
fi

# 9.3 启动服务
systemctl daemon-reload
systemctl enable remote-gateway
systemctl start remote-gateway

sleep 2

if systemctl is-active remote-gateway &>/dev/null; then
    record_ok "Remote Gateway 启动（端口 $(grep 'port' ${GATEWAY_DIR}/config.yaml | awk '{print $2}' | tr -d '"')）"
else
    record_fail "Remote Gateway 启动"
    log_info "查看错误: journalctl -u remote-gateway --since '1 minute ago'"
fi

# ======================== 第十步：配置 Swap（如未配置） ========================

log_step "========== 第10步：检查 Swap 配置 =========="

SWAP_SIZE=$(swapon --show=SIZE --noheadings 2>/dev/null | head -1)
if [[ -n "${SWAP_SIZE}" ]]; then
    log_info "Swap 已配置: ${SWAP_SIZE}"
    record_skip "Swap 配置（已存在）"
else
    log_info "配置 2G Swap..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # 持久化
    if ! grep -q swapfile /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    if swapon --show | grep -q swapfile; then
        record_ok "Swap 2G 配置"
    else
        record_fail "Swap 配置"
    fi
fi

# ======================== 第十一步：配置防火墙白名单 ========================

log_step "========== 第11步：配置 iptables 白名单（Agent 访问） =========="

# Agent 出口 IP 网段（云电脑出口IP可能在这些网段间切换）
AGENT_CIDRS=("115.190.0.0/16" "101.126.0.0/16")

for cidr in "${AGENT_CIDRS[@]}"; do
    if ! iptables -C INPUT -s "${cidr}" -j ACCEPT &>/dev/null; then
        iptables -I INPUT -s "${cidr}" -j ACCEPT
        log_info "已添加 iptables 白名单: ${cidr}"
    else
        log_info "iptables 白名单已存在: ${cidr}"
    fi
done

record_ok "iptables 白名单配置"

# ======================== 部署结果汇总 ========================

log_step "========== 部署结果汇总 =========="

echo "" | tee -a "${LOG_FILE}"
echo "======================================" | tee -a "${LOG_FILE}"
echo "  服务器初始化完成" | tee -a "${LOG_FILE}"
echo "======================================" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"
echo "  ✅ 成功: ${SUCCESS_COUNT}" | tee -a "${LOG_FILE}"
echo "  ❌ 失败: ${FAIL_COUNT}" | tee -a "${LOG_FILE}"
echo "  ⏭️  跳过: ${SKIP_COUNT}" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

if [[ -n "${FAILED_LIST}" ]]; then
    echo "  失败项目:${FAILED_LIST}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
fi

if [[ -n "${SKIPPED_LIST}" ]]; then
    echo "  跳过项目:${SKIPPED_LIST}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
fi

echo "  日志文件: ${LOG_FILE}" | tee -a "${LOG_FILE}"
echo "======================================" | tee -a "${LOG_FILE}"

# 显示容器状态总览
echo "" | tee -a "${LOG_FILE}"
echo "========== 容器状态总览 ==========" | tee -a "${LOG_FILE}"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

# 显示 Gateway 状态
echo "========== Remote Gateway 状态 ==========" | tee -a "${LOG_FILE}"
systemctl status remote-gateway --no-pager | head -10 | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

# 退出码：有失败则返回1
if [[ ${FAIL_COUNT} -gt 0 ]]; then
    exit 1
fi
exit 0
