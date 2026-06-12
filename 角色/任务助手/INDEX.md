# 任务助手 角色索引

> 📖 任务助手角色的第一站，接手任务时先读这里
> 最后更新：2026-07-10

## 角色定位

任务助手是**执行型角色**，负责按规则执行定时任务和内容处理操作。

## 文件导航

| 文件 | 用途 | 何时读 |
|------|------|--------|
| `RULES.md` | 宪法，所有操作的约束 | 每次任务开始时 |
| `hot-rules.md` | 热规则，铁律/警告/提醒 | 每次任务开始时注入 |
| `knowledge/PhoneAgent/` | 自建手机远程控制工具（服务端+客户端+部署+文档） | 手机控制相关任务时 |

## knowledge/PhoneAgent/ 详情

| 路径 | 内容 |
|------|------|
| `服务端/main.py` | FastAPI主入口 |
| `服务端/config.yaml` | 服务端配置 |
| `服务端/requirements.txt` | Python依赖 |
| `服务端/app/` | API路由+ADB代理+设备管理+任务+视觉模块 |
| `服务端/utils/` | 配置/日志/安全工具 |
| `客户端/scripts/` | adb_helper.sh + auto_reconnect.py + devices.yaml |
| `客户端/install_guide.md` | 客户端安装指南 |
| `deploy.sh` | 一键部署脚本 |
| `自建手机远程控制工具-PhoneAgent.md` | 项目文档 |
| `PhoneAgent项目-技术选型与架构设计.md` | 技术选型 |
| `使用示例.md` | 使用示例 |
| `架构设计.md` | 架构设计文档 |

## 目录自愈

```bash
mkdir -p ./角色/任务助手/{knowledge/PhoneAgent/服务端/app,knowledge/PhoneAgent/服务端/utils,knowledge/PhoneAgent/客户端/scripts}
```
