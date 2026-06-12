# 备份打包技能知识提炼

> 来源：./自定义技能/备份打包技能/SKILL.md + references/
> 提炼时间：2026-05-09

## 踩坑经验

| 坑 | 症状 | 解法 | 严重度 |
|----|------|------|--------|
| 中文文件名乱码 | Windows解压后中文变乱码 | 使用ZIP格式而非tar.gz | 🔴兼容性 |
| 符号链接目录被忽略 | 备份缺失./基础设定/内容 | 使用`followlinks=True`参数 | 🔴数据丢失 |
| 备份文件过大 | 超过邮箱附件限制 | 排除大目录（表情包、模型等） | 🟠通知用户 |

## 最佳实践

### 智能打包策略
1. **使用Python zipfile模块**：解决中文乱码
2. **符号链接跟随**：使用`followlinks=True`参数
3. **灵活排除机制**：可配置排除目录和文件类型
4. **自动清理旧备份**：保留指定天数

### 空间管理
- 备份超过30MB时自动分析各目录和文件类型占用
- 自动识别可压缩/可打包的大目录
- 大体积资源单独备份（表情包~67MB、模型~192MB、服务器运维~765MB）

### 历史对比
- 对比上次备份，计算大小变化
- 通知用户变化来源（哪些目录增加了/减少了）

## 平台规则/限制

### 排除规则
- **排除目录**：备份、SKILL、.skills、.tmp、browser、browser_screenshots、mobile_use、screenshots、imgs、表情包、模型、测试目录、服务器运维、回收站
- **排除扩展名**：.pptx、.zip

### 备份包含内容
- 核心记忆：MEMORY.md、USER.md、SECRET.md
- 基础设定：SOUL.md、TOOLS.md、EMAIL_RULES.md
- 项目文件：网盘变现项目、元宝收藏导出等
- 技能配置：自定义技能、file-cleaner等

### 邮件发送
- 附件大小限制约30MB（已排除大目录）
- 超出30MB需通知用户空间占用情况

## 设计决策

| 决策 | 选项 | 最终选择 | 理由 |
|------|------|----------|------|
| 压缩格式 | tar.gz | ZIP | Windows兼容性好，中文不乱码 |
| 符号链接处理 | 跳过/报错 | followlinks=True | 确保符号链接目录内容被备份 |
| 清理策略 | 手动/自动 | 自动保留N天 | 避免手动操作遗忘 |
| 备份验证 | 仅大小 | 历史对比+来源追踪 | 便于用户了解变化 |

## 返回值规范

### create_backup() 返回
```python
(backup_file, analysis)
# analysis: 超过30MB时返回空间分析，否则None
```

### get_backup_info() 返回
```python
{
  "date": str,           # 日期
  "filename": str,       # 文件名
  "size": int,          # 字节数
  "file_count": int,    # 文件数
  "path": str,          # 路径
  "dir_sizes": dict,    # 目录大小
  "comparison": dict    # 与上次对比
}
```

### comparison 结构
```python
{
  "is_first_backup": bool,
  "last_date": str,
  "size_change": int,
  "size_change_text": str,
  "changed_dirs": [{"dir": str, "change": int, ...}]
}
```

## 可升级为热规则的警告

- ⚠️ **符号链接目录必须用followlinks=True**：否则备份缺失关键内容
- ⚠️ **使用ZIP格式而非tar.gz**：避免Windows解压中文乱码
- ⚠️ **备份超30MB必须通知用户**：让用户决定是否调整排除规则
