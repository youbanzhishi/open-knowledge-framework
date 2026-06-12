#!/bin/bash
# 媒体预览服务停止

echo "🛑 停止媒体预览服务..."

# 停止 HTTP 服务器
if [ -f /tmp/media-preview.pid ]; then
  PID=$(cat /tmp/media-preview.pid)
  if kill -0 $PID 2>/dev/null; then
    kill $PID && echo "✅ HTTP 服务器已停止 (PID: $PID)"
  else
    echo "   HTTP 服务器进程已不存在"
  fi
  rm -f /tmp/media-preview.pid
fi

# 停止 cloudflared tunnel
bash "$(dirname "$0")/scripts/cloudflared-tunnel.sh" stop

echo "✅ 预览服务已完全停止"
echo "   预览目录文件保留，下次启动自动恢复"
