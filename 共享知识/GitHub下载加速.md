# GitHub下载加速

> 最后更新：2026-05-15
> 适用于：云电脑、ECS等直连GitHub网络慢的场景

## 问题

云电脑/ECS直连GitHub下载大文件（release）超时或极慢，但GitHub API正常。

## 可用镜像站

| 镜像站 | 状态 | 用法 |
|--------|------|------|
| ghfast.top | ✅ 可用（推荐） | `https://ghfast.top/https://github.com/...` |
| gh-proxy.com | ✅ 可用 | `https://gh-proxy.com/https://github.com/...` |
| mirror.ghproxy.com | ✅ 可用 | `https://mirror.ghproxy.com/https://github.com/...` |
| ghproxy.cc | ❌ 不可用 | 连接超时 |

## 用法

```bash
# 原始URL
https://github.com/youbanzhishi/OpenLink/releases/download/v1.0.1/openlink-linux-amd64.tar.gz

# 加速URL（前面加镜像站地址）
https://ghfast.top/https://github.com/youbanzhishi/OpenLink/releases/download/v1.0.1/openlink-linux-amd64.tar.gz
```

## 注意

- GitHub API（api.github.com）正常，不需要加速
- 只有大文件下载（release/tarball）需要加速
- 镜像站可能不稳定，备选多个
