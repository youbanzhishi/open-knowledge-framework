#!/bin/bash
# 放入预览文件并输出可访问的 URL
# 用法:
#   bash serve-file.sh /path/to/audio.mp3
#   bash serve-file.sh /path/to/audio.mp3 "我的曲子预览"
#   PREVIEW_DIR=/opt/opendaw bash serve-file.sh build/index.html

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

PREVIEW_PORT=${PREVIEW_PORT:-8787}
PREVIEW_DIR=${PREVIEW_DIR:-/tmp/media-preview}

FILE_PATH=${1:-}
TITLE=${2:-}

if [ -z "$FILE_PATH" ]; then
  echo "用法: $0 <文件路径> [标题]"
  echo ""
  echo "示例:"
  echo "  bash $0 /tmp/audio.mp3           # 音频预览"
  echo "  bash $0 /tmp/video.mp4           # 视频预览"
  echo "  bash $0 /tmp/demo.webm \"演示\"   # 带标题"
  echo ""
  echo "环境变量:"
  echo "  PREVIEW_PORT  端口（默认 8787）"
  echo "  PREVIEW_DIR   服务目录（默认 /tmp/media-preview）"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "❌ 文件不存在: $FILE_PATH"
  exit 1
fi

# ── 确定文件类型图标 ────────────────────────────────────────
EXT="${FILE_PATH##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

case $EXT_LOWER in
  mp3|wav|ogg|flac|aac|m4a|mid|midi) ICON="🎵" ;;
  mp4|webm|mov|avi|mkv|m4v)          ICON="🎬" ;;
  png|jpg|jpeg|gif|webp|svg)         ICON="🖼️" ;;
  pdf)                                ICON="📄" ;;
  html|htm)                           ICON="🌐" ;;
  *)                                  ICON="📎" ;;
esac

# ── 复制到预览目录 ──────────────────────────────────────────
if [ -n "$TITLE" ]; then
  MONTH_DIR="$PREVIEW_DIR/$(date +%Y-%m)__${TITLE}"
else
  MONTH_DIR="$PREVIEW_DIR/$(date +%Y-%m)"
fi
mkdir -p "$MONTH_DIR"

FILENAME=$(basename "$FILE_PATH")
DEST="$MONTH_DIR/$FILENAME"
cp "$FILE_PATH" "$DEST"

# ── 确保 HTTP 服务器在运行 ─────────────────────────────────
RUNNING=""
for pidfile in /tmp/http-server-nodejs.pid /tmp/http-server-python.pid; do
  [ -f "$pidfile" ] && kill -0 $(cat "$pidfile") 2>/dev/null && RUNNING="yes" && break
done

if [ -z "$RUNNING" ]; then
  echo "⚠️  HTTP 服务器未运行，先启动..."
  bash "$SCRIPT_DIR/start-server.sh" > /dev/null 2>&1
  sleep 3
fi

# ── 获取公网 URL ───────────────────────────────────────────
TUNNEL_URL=""
for urlfile in /tmp/tunnel-cloudflare.url /tmp/tunnel-lts.url /tmp/tunnel-frp.url; do
  if [ -f "$urlfile" ] && [ -s "$urlfile" ]; then
    TUNNEL_URL=$(cat "$urlfile")
    break
  fi
done

# ── 输出 ───────────────────────────────────────────────────
LOCAL_PATH="/$(basename "$MONTH_DIR")/$FILENAME"
LOCAL_URL="http://localhost:$PREVIEW_PORT$LOCAL_PATH"

echo ""
echo "═══════════════════════════════════════"
echo "$ICON 文件已放入预览"
echo "   文件名: $FILENAME"
echo "   大小:   $(du -h "$DEST" | cut -f1)"
echo "   存放:   $DEST"
echo ""
echo "🎧 本地播放:"
echo "   $LOCAL_URL"
if [ -n "$TUNNEL_URL" ]; then
  REL_URL="${TUNNEL_URL}${LOCAL_PATH}"
  echo ""
  echo "🌐 公网播放:"
  echo "   $REL_URL"
fi
echo "═══════════════════════════════════════"

# 如果公网 URL 存在，也输出纯 URL 便于分享
if [ -n "$TUNNEL_URL" ]; then
  echo ""
  echo "📋 分享链接（复制使用）:"
  echo "   ${TUNNEL_URL}${LOCAL_PATH}"
fi
