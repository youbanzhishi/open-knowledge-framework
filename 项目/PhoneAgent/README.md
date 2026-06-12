# PhoneAgent - 自建手机远程控制工具

源码仓库：https://github.com/youbanzhishi/phone-agent （私有）

## 架构
- **服务端**: Flask API + ADB设备管理 + 视觉识别 + 任务调度
- **客户端**: ADB代理 + 自动重连 + 设备配置
- **部署**: Docker + systemd

## 关联
- 体系仓库：open-knowledge-system/项目/PhoneAgent/
- 角色：任务助手、ECS运维
