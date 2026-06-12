# ECS运维 角色索引

> 📖 这是ECS运维角色的第一站，任何session接手运维任务时先读这里
> 最后更新：2026-05-09

## 角色定位

ECS运维是**服务角色**，不是项目。它运行代码，不开发代码。

## 文件导航

| 文件 | 用途 | 何时读 |
|------|------|--------|
| `RULES.md` | 宪法，所有运维操作的约束 | 每次运维任务开始时 |
| `hot-rules.md` | 热规则，铁律/警告/提醒 | 每次运维任务开始时注入 |
| `knowledge/服务清单.md` | 服务器信息+运行服务+VCMix详情 | 部署新服务前/排查问题时 |
| `knowledge/部署流程.md` | 通用部署脚本体系和流程 | 部署新项目时 |
| `knowledge/容器映射.md` | 所有容器的宿主机↔容器路径映射 | 迁移服务器时 |
| `knowledge/端口分配.md` | 端口占用+SRS地址+分配原则 | 部署前查端口冲突 |
| `knowledge/目录结构.md` | 服务器文件目录树 | 需要找服务器上的文件时 |
| `knowledge/镜像清单.md` | Docker镜像精确版本+查询指令 | 升级/迁移镜像时 |
| `knowledge/常用命令.md` | 服务管理/资源查看/Gateway/传输 | 速查命令时 |
| `knowledge/排坑经验.md` | 9条踩坑经验（必读） | 第一次接手时通读，遇问题时翻阅 |
| `knowledge/紧急处理.md` | 服务异常/磁盘满/内存不足排查 | 紧急故障时 |
| `knowledge/大文件传输.md` | file_to_url+wget方案 | 需要传大文件到ECS时 |
| `knowledge/云电脑与ECS互补架构.md` | frp隧道打通/端口映射/带宽互补策略/7个应用场景 | 部署云电脑服务/新增端口映射/排查隧道问题时 |
| `scripts/init-server.sh` | 一键初始化脚本（Docker安装+镜像源+Compose部署+Gateway启动+Swap+防火墙） | 新服务器初始化时 |
| `scripts/gateway/` | Gateway服务（gateway.py+config.yaml+gateway.service） | 部署/排查Gateway时 |
| `log/` | 运维操作记录 | 操作完成后写入 |
| `config/` | 运维配置（镜像源等） | 需要时查阅 |

## 服务器速查

| 项目 | ECS | 云电脑 |
|------|-----|--------|
| IP | 39.103.203.162 | 115.190.127.67 |
| 内存 | 1.8G（已用约1.3G） | 3.8G |
| Swap | 2G | - |
| 磁盘余量 | ~8G | 40G |
| 出站带宽 | 1Mbps | 不限速 |
| 入站带宽 | 不限 | 被封（无开放端口） |
| Gateway Proxy v2 | 1806端口，角色Token认证（ops/admin/dev/readonly） | 连接服务器操作 |
| frp | frps服务端(7000) | frpc客户端 |
| 特殊能力 | Docker/Nginx/反代 | VNC桌面/浏览器自动化 |

## 目录自愈

```bash
mkdir -p ./角色/ECS运维/{log,knowledge,config,scripts/gateway}
```

## 待办

- [ ] 配置 Hermes API Key（等待获取）
- [ ] 监控 Hermes 官方镜像更新
- [ ] 考虑自建 Hermes Python 3.11 镜像
- [ ] VCMix core-latest 缺 Web UI 依赖，等待完整版镜像
- [ ] ~~Remote Gateway 端口7772~~ 已被 Gateway Proxy v2(1806端口) 替代

## 共享规范同步

| 规范 | 同步日期 | 本地偏差 |
|------|----------|----------|
| 目录结构规范 | 2026-05-09 | 角色类型：无src/tests/output，核心是RULES+knowledge+log |
| 热规则规范 | 2026-05-09 | 无偏差 |
| 协作规范 | 2026-05-09 | 角色不产出代码，协作方式是"被项目调用" |

## 已同步版本: 2026-05-11-v10
