# media-preview · 媒体预览与项目部署技能

> 内网穿透音频/视频预览 + 项目部署访问：生成文件直接网页播放，定稿后再下载
> 适用场景：音频生成、视频预览、编曲确认、混音版本对比、项目部署演示
> 跨角色通用：编曲工程师、混音母带工程师、动画导演、游戏开发工程师、本地运维、系统开发者

## 能力

1. **本地预览服务器** — HTTP 文件服务器（Node.js 主方案 / Python 备选），支持：
   - 中文路径（UTF-8 编码，无乱码）
   - Range 请求（视频/音频拖动播放）
   - 目录索引（直接浏览器访问文件列表）
   - 多格式支持：audio / video / image / PDF / 任意文件

2. **多穿透方案（自动回退链）** — 按优先级自动尝试：
   - `frps`（ecs_frps凭据）→ 最稳定
   - `cloudflared quick tunnel` → 零配置快速穿透（**国内首选**）
   - `localtunnel`（lt）→ ⚠️ 国内被ICP备案拦截，仅海外可用
   - `ssh -R` → 自有VPS

3. **项目部署访问** — OpenDAW/OpenLink/OpenVault 等项目启动后，直接穿透访问 Web UI

4. **统一目录管理** — `/tmp/media-preview/` 按月分目录，7天前自动清理

## 架构

```
┌─────────────────────────────────────────────────┐
│  HTTP 服务器 (Node.js, 端口可配)                 │
│  支持: 中文路径 / Range请求(视频拖动) / UTF-8     │
└──────────────────────┬──────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
    cloudflared    localtunnel       frps
   (trycloudflare)  (lts.dev)     (ecs_frps)
        └──────────────┴──────────────┘
                       ↓
               公网 URL → 主人浏览器
```

## 使用方式

### 场景一：音频/视频预览（推荐）

```bash
# 1. 启动服务（一键，自动穿透）
bash 技能/媒体预览技能/start-server.sh

# 2. 放入文件，获取可分享链接
bash 技能/媒体预览技能/serve-file.sh /path/to/audio.mp3 "编曲V1"

# 输出:
# 🎵 文件已放入预览
# 🌐 公网播放: https://xxxx.lts.dev/2026-06__编曲V1/audio.mp3
# → 直接浏览器打开播放，定稿满意后再下载
```

### 场景二：视频预览（支持拖动）

```bash
bash 技能/媒体预览技能/serve-file.sh /tmp/demo.mp4 "混音V2对比"
```

### 场景三：部署项目 Web UI（OpenLink 等）

```bash
# 启动 OpenLink 后（端口3001），穿透访问
PREVIEW_DIR=/opt/opendaw PREVIEW_PORT=3001 \
  bash 技能/媒体预览技能/start-server.sh

# 公网访问 OpenLink Web UI
```

### 场景四：内网仅访问（不需要穿透）

```bash
bash 技能/媒体预览技能/start-server.sh --serve
# → http://localhost:8787（无公网地址）
```

### 停止服务

```bash
bash 技能/媒体预览技能/stop-server.sh
```

## 穿透凭据配置

### frps（ecs_frps）— 最稳定，推荐优先配置

在 `共享知识/凭据/secrets.enc` 中配置：
```json
{
  "ecs_frps": {
    "server": "your-vps.example.com",
    "token": "your-frps-token",
    "bind_port": 7000
  }
}
```
→ 使用 `bash 共享知识/凭据/decrypt.sh $MASTER_KEY ecs_frps.token` 解密

### localtunnel（零配置备选）

```bash
npm install -g localtunnel
# 自动使用，无需额外配置
```

### cloudflared（有 Cloudflare 账号）

```bash
# 安装
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# 授权
cloudflared tunnel login

# 创建 tunnel
cloudflared tunnel create media-preview
cloudflared tunnel route dns media-preview your-subdomain.cloudflare.com

# 配置 ~/.cloudflared/config.yml
tunnel: <tunnel-uuid>
credentials-file: /root/.cloudflared/credentials.json
ingress:
  - service: http://localhost:8787
    originRequest:
      noTLSVerify: true

# 启动
cloudflared tunnel run media-preview
```

### SSH 反向隧道（自有 VPS）

```bash
export SSH_TUNNEL_USER=root
export SSH_TUNNEL_HOST=your-vps.example.com
export SSH_TUNNEL_PORT=22
bash 技能/媒体预览技能/start-server.sh
# → 在 VPS 上 curl http://localhost:8787 访问
```

## 内网穿透历史经验（持续更新）

| 问题 | 原因 | 解决 |
|------|------|------|
| Python http.server 中文乱码 | 未设置 charset=utf-8 | 改用 Node.js HTTP 服务器 |
| 中文目录 URL 404 | URL 未解码（%XX） | Node.js 中使用 decodeURIComponent |
| cloudflared SIGSEGV | bin 与内核不兼容 | 自动回退到 localtunnel |
| localtunnel 国内无法访问 | lts.dev 域名被ICP备案拦截 | **改用 cloudflared quick tunnel** |
| Vite dev server "Blocked request" | Vite 8 检查 Host header | `server: { allowedHosts: true }` |
| cloudflared `allowedHosts: 'all'` 报错 | Vite 8 不支持字符串 'all' | 用 `allowedHosts: true`（布尔值） |
| 多端口需多隧道 | 每个隧道只绑一个端口 | 启动多个 cloudflared 实例 |

### cloudflared quick tunnel 快速用法（无需 Cloudflare 账号）

**最简一行穿透**，不需要 login / tunnel create / config.yml：

```bash
# 一键穿透本地端口（自动生成 trycloudflare.com 临时链接）
nohup cloudflared tunnel --url http://localhost:5173 > /tmp/cf-box.log 2>&1 &

# 等5秒提取公网URL
sleep 5 && grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf-box.log | tail -1
# → https://xxx-yyy-zzz.trycloudflare.com
```

**多端口多站点并行穿透**：
```bash
# 同时穿透3个Vite dev server
nohup cloudflared tunnel --url http://localhost:5173 > /tmp/cf-box.log 2>&1 &
nohup cloudflared tunnel --url http://localhost:5174 > /tmp/cf-ma.log 2>&1 &
nohup cloudflared tunnel --url http://localhost:5175 > /tmp/cf-mi.log 2>&1 &
```

**Vite 项目穿透必配**（Vite 8+）：
```js
// vite.config.js
export default defineConfig({
  server: {
    host: '0.0.0.0',  // 允许外部访问
    allowedHosts: true  // Vite 8 语法，允许 cloudflared 域名访问
  }
})
```

**注意事项**：
- trycloudflare.com 链接是临时的，每次重启 cloudflared 会生成新链接
- 链接无密码保护，任何人可访问，不用于敏感内容
- `pkill -f cloudflared` 一键停止所有隧道

## 文件结构

```
技能/媒体预览技能/
├── SKILL.md                    # 本文件
├── start-server.sh             # 一键启动（HTTP+穿透）
├── stop-server.sh              # 停止服务
├── serve-file.sh               # 放入文件并输出 URL
├── scripts/
│   ├── http-server.sh          # Node.js 主服务器（中文友好）/ Python 备选
│   ├── cloudflared-tunnel.sh # 多穿透管理器（frps→cloudflared→lt→ssh-R）
│   └── cleanup.sh             # 清理7天前文件
└── config/
    └── server.env             # 端口/目录配置
```

## 配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| PREVIEW_PORT | 8787 | HTTP 服务器端口 |
| PREVIEW_DIR | /tmp/media-preview/ | 预览文件根目录 |
| CLEANUP_DAYS | 7 | 自动清理天数 |
| MASTER_KEY | （从平台获取） | 解密 secrets.enc 凭据 |

## 安全注意

- 预览目录 `/tmp/media-preview/` 仅用于临时预览，文件7天后自动清理
- 穿透 URL 随机生成，有一定隐私保护，不用于传输高度敏感内容
- 如需密码保护，可用 HTTP Basic Auth（cloudflared Access）

## 更新记录

- **2026-06-03 v2**: 融合4个穿透方案（frps/cloudflared/lt/ssh-R）+ Node.js 中文路径支持 + 项目部署模式
- 2026-06-03 v1: 初版（Python HTTP + localtunnel 单方案）
