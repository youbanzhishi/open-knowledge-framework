# 无人直播推流技能

> 本技能封装了无人直播推流的完整知识体系，可复用、可迁移、可升级

---

## 一、技能概述

### 适用场景
- 24小时无人值守直播推流
- RTMP 流转发与转码
- 自建流媒体服务器（SRS）
- 带宽受限环境下的低码率推流

### 核心能力
1. **推流脚本管理**：自动重连、日志记录、码率控制
2. **流媒体服务器搭建**：SRS Docker 部署
3. **带宽计算与优化**：根据带宽选择合适码率
4. **故障排查**：推流中断、卡顿、无法播放等问题诊断

---

## 技能信息
- 加载模式：progressive
- 触发关键词：[直播, 推流, 无人]
- 摘要：无人直播推流配置与管理

## 二、快速开始

### 1. 部署 SRS 流媒体服务器

```bash
docker run -d --name srs \
  -p 1935:1935 \
  -p 1985:1985 \
  -p 8080:8080 \
  registry.cn-hangzhou.aliyuncs.com/ossrs/srs:5
```

**端口说明：**
| 端口 | 用途 |
|------|------|
| 1935 | RTMP 推流/拉流 |
| 1985 | HTTP API 管理 |
| 8080 | HTTP-FLV / HLS 播放 |

### 2. 启动推流脚本

**低码率模式（适配 1Mbps 带宽）：**
```bash
# 下载脚本
mkdir -p /root/stream_relay
cat > /root/stream_relay/stream_relay.sh << 'EOF'
#!/bin/bash
LOG_FILE="/root/stream_relay/stream_relay.log"
SOURCE="[源流地址]"
TARGET="rtmp://[服务器IP]:1935/live/[流名称]"

echo "$(date '+%Y-%m-%d %H:%M:%S') 推流脚本启动" >> "$LOG_FILE"

while true; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') 开始推流..." >> "$LOG_FILE"
    
    ffmpeg -re -i "$SOURCE" \
        -c:v libx264 -preset ultrafast -g 60 -keyint_min 60 \
        -b:v 600k -maxrate 800k -bufsize 1200k \
        -c:a aac -b:a 64k \
        -f flv -flvflags no_duration_filesize \
        "$TARGET" 2>> "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') ffmpeg 退出，退出码: $?" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') 3秒后重连..." >> "$LOG_FILE"
    sleep 3
done
EOF

chmod +x /root/stream_relay/stream_relay.sh

# 后台启动
cd /root/stream_relay && nohup bash stream_relay.sh > /dev/null 2>&1 &
```

### 3. 播放地址

```
HLS:     http://[服务器IP]:8080/live/[流名称].m3u8
RTMP:    rtmp://[服务器IP]:1935/live/[流名称]
HTTP-FLV: http://[服务器IP]:8080/live/[流名称].flv
```

---

## 三、推流命令速查

### 按带宽选择命令

| 带宽 | 推荐命令 |
|------|----------|
| **1 Mbps** | 低码率命令（见下文） |
| **5 Mbps+** | 标准码率命令 |
| **10 Mbps+** | 可用 `-c copy` 直接转发 |

### 低码率推流（1Mbps 带宽）
```bash
ffmpeg -re -i [源流地址] \
  -c:v libx264 -preset ultrafast -g 60 -keyint_min 60 \
  -b:v 600k -maxrate 800k -bufsize 1200k \
  -c:a aac -b:a 64k \
  -f flv rtmp://[服务器IP]:1935/live/[流名称]
```

### 标准码率推流（5Mbps+ 带宽）
```bash
ffmpeg -re -i [源流地址] \
  -c:v libx264 -preset ultrafast -g 60 -keyint_min 60 \
  -b:v 2500k -maxrate 3000k -bufsize 5000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://[服务器IP]:1935/live/[流名称]
```

### 直接转发（不转码，需要充足带宽）
```bash
ffmpeg -re -i [源流地址] \
  -c copy -f flv \
  -flvflags no_duration_filesize \
  rtmp://[服务器IP]:1935/live/[流名称]
```
- 优点：CPU 占用极低（约 5%）
- 缺点：码率由源流决定，无法控制

---

## 四、参数详解

### FFmpeg 关键参数

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `-re` | 按原始帧率推流 | 必须加 |
| `-c:v libx264` | 视频编码器 | libx264 |
| `-preset` | 编码速度 | ultrafast（快速）|
| `-g` | GOP 间隔（帧数）| 60（约2秒@30fps）|
| `-keyint_min` | 最小关键帧间隔 | 与 -g 相同 |
| `-b:v` | 视频码率 | 根据带宽调整 |
| `-maxrate` | 最大码率 | 比目标码率高 20% |
| `-bufsize` | 缓冲区大小 | 目标码率的 2 倍 |
| `-b:a` | 音频码率 | 64k-128k |
| `-flvflags no_duration_filesize` | 不写入时长信息 | 直播流必须加 |

### 带宽计算公式

```
所需带宽 = 推流码率 + (观众数 × 推流码率)

例如：
- 推流 800 kbps
- 1 个观众
- 所需带宽 = 800 + 800 = 1600 kbps ≈ 2 Mbps
```

### 带宽与码率对照表

| 带宽 | 推荐码率 | 分辨率 | 支持观众数 |
|------|---------|--------|-----------|
| 1 Mbps | 600-800 kbps | 480p | 1 人 |
| 5 Mbps | 2500 kbps | 720p | 1-2 人 |
| 10 Mbps | 2500 kbps | 720p | 3-4 人 |
| 20+ Mbps | 4000+ kbps | 1080p | 5+ 人 |

---

## 五、故障排查

### 排查优先级

1. **带宽上限** ← 最优先！
2. CPU 使用率
3. 内存使用率
4. 磁盘 IO
5. 网络连接状态

### 常见问题

#### 1. 播放卡顿
- **检查带宽**：`speedtest-cli --simple`
- **检查码率**：推流码率是否超过带宽上限
- **解决方案**：降低码率或升级带宽

**关键排查点**：
1. 先确认是**推流端**还是**目标服务器**的带宽瓶颈
2. 推流端上传带宽测试：`speedtest-cli --simple`（看 Upload 值）
3. 目标服务器带宽测试：在目标服务器上测试下载速度
4. 案例：推流端 250Mbps 上传充足，但目标服务器只有 1Mbps 带宽，导致卡顿

**带宽独立性说明**：
- 上下行带宽通常是独立的通道（企业级宽带）
- 但如果是共享带宽池，下载大文件可能挤占上行带宽
- 建议：排查卡顿时，先暂停服务器上的大文件下载任务测试

#### 2. 推流中断
- **检查日志**：`tail -50 /root/stream_relay/stream_relay.log`
- **检查源流**：`ffmpeg -i [源流] -t 5 -f null -`
- **检查目标服务器**：`nc -zv [IP] 1935`

**常见根因排序**：
1. **服务器重启导致 nohup 进程丢失**（最常见！）
   - nohup 只能扛终端关闭，不扛系统重启
   - 排查方法：`uptime` 看运行时间，`ps aux | grep stream_relay` 看进程是否存在
   - 解决方案：改用 systemd service 或 crontab `@reboot`
2. **源流不稳定导致 Broken pipe**
   - 日志中反复出现 `Broken pipe` = 源流断开
   - 推流脚本有 while 循环自动重连，但如果源流长时间不可用，会持续报错
   - 解决方案：换更稳定的直播源
3. **OOM killer 杀进程**
   - 排查方法：`dmesg | grep -i oom` 或 `dmesg | grep -i kill`
   - FFmpeg 转码模式内存占用较高，低配服务器需注意

#### 3. 无法播放
- **检查 SRS 状态**：`docker ps | grep srs`
- **检查流是否存在**：`curl http://localhost:8080/api/v1/streams/`
- **检查安全组**：确保 1935、8080 端口开放

#### 4. 脚本卡住不重连
- **原因**：脚本文件可能存储在云存储，I/O 错误导致无法执行
- **解决方案**：脚本必须放在本地磁盘（如 `/root/`）

### 排查命令

```bash
# 检查推流进程
ps aux | grep ffmpeg

# 检查网络连通性
ping -c 3 [目标IP]
nc -zv [目标IP] 1935

# 检查带宽
speedtest-cli --simple

# 检查 SRS 流状态
curl http://localhost:8080/api/v1/streams/

# 检查进程卡住位置
cat /proc/[PID]/stack
cat /proc/[PID]/wchan

# 检查文件是否可读
dd if=[文件路径] bs=512 count=1
```

---

## 六、测试用直播源

### 腾讯云测试流
```
rtmp://liteavapp.qcloud.com/live/liteavdemoplayerstreamid
```
- 来源：腾讯云官方
- 用途：播放器功能测试
- 注意：不建议用于公开直播

### 无版权直播源（YouTube）
| 名称 | 类型 | 说明 |
|------|------|------|
| Lofi Girl | 音乐 | 24小时 lofi hip hop |
| NASA TV | 科技 | NASA 官方直播 |
| EarthCam | 风景 | 各地城市实时摄像头 |

---

## 七、运维规范

### 脚本存放位置
- ✅ 本地磁盘：`/root/stream_relay/`
- ❌ 云存储：`/app/data/xxx/`（可能导致 I/O 错误）

### 操作命令
```bash
# 启动推流（nohup方式，不扛重启）
cd /root/stream_relay && nohup bash stream_relay.sh > /dev/null 2>&1 &

# 启动推流（systemd方式，推荐！扛重启）
# 先创建 service 文件（见下方），然后：
systemctl start stream-relay
systemctl enable stream-relay   # 开机自启
systemctl status stream-relay   # 查看状态

# 停止推流
pkill -f stream_relay
pkill -f ffmpeg
# 或 systemd 方式：
systemctl stop stream-relay

# 查看状态
ps aux | grep -E "stream_relay|ffmpeg"

# 查看日志
tail -f /root/stream_relay/stream_relay.log
# systemd 方式：
journalctl -u stream-relay -f
```

### systemd service 配置（推荐）

创建文件 `/etc/systemd/system/stream-relay.service`：
```ini
[Unit]
Description=Stream Relay Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/bin/bash /root/stream_relay/stream_relay.sh
Restart=always
RestartSec=5
WorkingDirectory=/root/stream_relay

[Install]
WantedBy=multi-user.target
```

**优势**：
- 系统重启后自动恢复推流
- 进程崩溃后 5 秒自动重启
- 可通过 systemctl 统一管理
- 日志可通过 journalctl 查看

### 进程存活监控

**方案1：心跳检查（轻量）**
在心跳检查项中加入：
```
- 检查推流进程是否存活：ssh到云电脑执行 ps aux | grep ffmpeg，无结果则通知用户
```

**方案2：cron 定时脚本（更及时）**
```bash
# 创建 /root/stream_relay/check_alive.sh
#!/bin/bash
if ! pgrep -f "stream_relay" > /dev/null; then
    echo "$(date) 推流进程不存在，尝试重启..." >> /root/stream_relay/stream_relay.log
    cd /root/stream_relay && nohup bash stream_relay.sh > /dev/null 2>&1 &
fi

# 加入 crontab（每5分钟检查一次）
# crontab -e
# */5 * * * * /bin/bash /root/stream_relay/check_alive.sh
```

---

## 八、参考文档

- `references/直播源与推流技术.md`：直播源汇总、推流工具对比
- `references/服务器运维知识.md`：带宽计算、故障排查、Docker 运维
- `scripts/stream_relay.sh`：推流脚本模板

---

## 九、版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| 1.2 | 2026-04-30 | 补充推流中断根因排序（重启丢进程、Broken pipe、OOM killer）；新增 systemd service 配置（推荐替代 nohup）；新增进程存活监控方案 |
| 1.1 | 2026-04-27 | 补充卡顿排查经验、带宽独立性说明 |
| 1.0 | 2026-04-27 | 初始版本，封装完整推流知识体系 |

---

*技能创建者：小龙*
*最后更新：2026-04-30*
