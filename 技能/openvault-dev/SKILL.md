# OpenVault 开发技能

## 技能信息
- 技能名称：openvault-dev
- 技能类型：项目级开发技能
- 适用项目：OpenVault（智能文件备份容灾系统）
- 加载模式：progressive
- 触发关键词：[OpenVault, 开放金库, openvault-dev, 文件备份]
- 摘要：OpenVault项目完整上下文+开发规范，接手开发/迭代时加载

## 功能描述
为智能体提供 OpenVault 项目的完整上下文，使其能0成本接手开发和迭代。包含：项目定位、架构设计、与OpenLink的关系、代码结构、开发铁律、部署规范、当前进度。

## 使用场景
- 接手或继续开发 OpenVault 项目
- 为 OpenVault 添加新的备份策略/存储后端/扩展
- 修复 OpenVault 的 bug
- 部署或运维 OpenVault
- 理解 OpenVault 与 OpenLink 的关系

## 加载方式
skill_load: openvault-dev

## 技能文件
- `skill/SKILL.md` — 项目完整上下文 + 开发规范

## 项目资料目录
所有项目相关资料集中存放，方便迁移和打包：
```
./项目文档/OpenVault/
├── README.md              # 项目总览 + 目录导航
├── 项目规划.md            # 架构设计、技术选型、路线图
├── 开发日志/              # 按日期的开发记录
├── 知识沉淀/              # 项目相关的技术知识
├── docs/                  # 其他文档
└── openvault/             # 代码（Rust workspace）
```

**重要：** 所有项目产出物必须放到上述目录下，不要散落在其他位置。

## 关联项目
- **OpenLink**：运输层，OpenVault调用其API做文件传输
- **open-storage**：共享存储抽象crate
