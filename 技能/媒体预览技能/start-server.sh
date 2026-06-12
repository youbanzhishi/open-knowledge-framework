#!/bin/bash
# 媒体预览服务一键启动（支持音频/视频预览 + 项目部署访问）
# 用法:
#   bash start-server.sh                # 启动预览服务
#   bash start-server.sh --serve       # 仅启动HTTP服务器（不穿透）
#   bash start-server.sh --port 3001   # 指定端口（如 OpenLink 3001）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$(dirname "$SKILL_DIR")"

PREVIEW_PORT=${PREVIEW_PORT:-${1:-8787}}

# 解析参数
MODE="full"  # full | http-only
if [ "$1" = "--serve" ]; then MODE="http-only"; fi
if [ "$1" = "--help" ]; then
  echo "用法:"
  echo "  bash $0                    # 完整模式（HTTP+穿透）"
  echo "  bash $0 --serve            # 仅HTTP服务器（无穿透）"
  echo "  bash $0 --port 3001        # 指定端口"
  echo "  export PREVIEW_DIR=/opt/opendaw  # 指定服务目录"
  exit 0
fi

# 端口解析（支持 bash start-server.sh --port 3001）
for i in $(seq 1 $#); do
  eval "arg=\${$i}"
  if [ "$arg" = "--port" ]; then
    next=$((i+1))
    eval "PREVIEW_PORT=\${$next}"
  fi
done

echo "═══════════════════════════════════════"
echo "🌐 媒体预览 / 项目部署服务"
echo "═══════════════════════════════════════"

# 0. 初始化目录
PREVIEW_DIR=${PREVIEW_DIR:-/tmp/media-preview}
mkdir -p "$PREVIEW_DIR"

# 1. 检查 HTTP 服务器
echo ""
echo "① 检查 HTTP 文件服务器..."
RUNNING_PID=""
for pidfile in /tmp/http-server-nodejs.pid /tmp/http-server-python.pid; do
  if [ -f "$pidfile" ] && kill -0 $(cat "$pidfile") 2>/dev/null; then
    RUNNING_PID=$(cat "$pidfile")
    break
  fi
done

if [ -n "$RUNNING_PID" ]; then
  echo "✅ HTTP 服务器已在运行 (PID: $RUNNING_PID)"
  echo "   本地: http://localhost:$PREVIEW_PORT"
else
  echo "   启动 HTTP 服务器..."
  bash "$SCRIPT_DIR/scripts/http-server.sh" "$PREVIEW_PORT" "$PREVIEW_DIR"
fi

# 2. 穿透服务（完整模式才启动）
echo ""
echo "② 穿透服务..."
if [ "$MODE" = "http-only" ]; then
  echo "⏭️  已跳过（http-only 模式）"
else
  bash "$SCRIPT_DIR/scripts/cloudflared-tunnel.sh" status 2>/dev/null || true
  bash "$SCRIPT_DIR/scripts/cloudflared-tunnel.sh" start
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ 服务已就绪"
echo ""
echo "   📂 目录: $PREVIEW_DIR"
echo "   🌐 本地: http://localhost:$PREVIEW_PORT"
if [ "$MODE" != "http-only" ]; then
  TUNNEL_URL=$(bash "$SCRIPT_DIR/scripts/cloudflared-tunnel.sh" url 2>/dev/null || echo "")
  if [ -n "$TUNNEL_URL" ]; then
    echo "   🌍 公网: $TUNNEL_URL"
  fi
fi
echo ""
echo "📌 快速用法:"
echo "   # 放入音频/视频，获取预览链接"
echo "   bash $SCRIPT_DIR/serve-file.sh /path/to/audio.mp3 \"我的曲子\""
echo ""
echo "   # 部署项目目录（OpenLink 等）"
echo "   PREVIEW_DIR=/opt/opendaw bash $SCRIPT_DIR/start-server.sh --port 3001"
echo ""
echo "   # 仅HTTP服务器（内网使用，无需穿透）"
echo "   bash $SCRIPT_DIR/start-server.sh --serve"
echo "═══════════════════════════════════════"
