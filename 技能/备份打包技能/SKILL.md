# 备份打包技能

## 功能描述
将云端文件和记忆打包成 ZIP 格式，并发送到指定邮箱。支持排除特定目录和文件类型，自动清理旧备份。

## 适用场景
- 定时备份云端文件和记忆
- 手动触发备份发送
- 数据迁移和归档

## 核心能力
1. **智能打包**：使用 Python zipfile 模块，解决中文文件名乱码问题
2. **符号链接支持**：正确跟随符号链接目录（如基础设定目录）
3. **灵活排除**：可配置排除的目录和文件类型
4. **自动清理**：保留指定天数的备份文件
5. **邮件发送**：支持发送到指定邮箱
6. **空间分析**：备份超过 30MB 时自动分析各目录和文件类型的占用空间
7. **优化建议**：自动识别可压缩/可打包的大目录，给出优化建议
8. **历史对比**：对比上次备份，计算大小变化，通知用户变化来源

## 使用方式

### 方式一：通过日程自动执行
在日程描述中引用本技能，执行 session 会自动加载并执行。

### 方式二：手动调用脚本
```bash
python3 ./自定义技能/备份打包技能/scripts/backup_sender.py
```

### 方式三：自定义参数执行
```python
from scripts.backup_sender import BackupSender

sender = BackupSender(
    backup_dir='./备份',
    exclude_dirs={'./备份', './SKILL', './browser', './mobile_use'},
    exclude_ext={'.pptx', '.zip'},
    keep_days=3
)
backup_file, analysis = sender.create_backup()

# 如果 analysis 不为 None，说明备份过大，需要通知用户
if analysis:
    print("备份过大，空间分析：")
    for dir_name, info in analysis["by_directory"][:5]:
        print(f"  {dir_name}: {info['size'] / 1024 / 1024:.2f} MB")
sender.send_email('recipient@example.com', backup_file)
```

## 返回值说明
**create_backup() 返回 (backup_file, analysis) 元组**
- `backup_file`: 备份文件路径
- `analysis`: 如果备份超过 30MB，返回空间分析结果；否则为 None

**get_backup_info() 返回 info 字典，包含：**
- 基本信息：date、filename、size、file_count、path
- 目录大小：dir_sizes（用于历史对比）
- 对比结果：comparison（与上次备份的变化）

**comparison 结构**：
```json
{
  "is_first_backup": false,
  "last_date": "2026-04-27",
  "size_change": 2500000,
  "size_change_text": "+2.38 MB",
  "changed_dirs": [
    {"dir": "根目录", "change": 1500000, "change_text": "+1.43 MB", "current": "19.84 MB"},
    {"dir": "元宝收藏导出", "change": 800000, "change_text": "+781.25 KB", "current": "8.09 MB"}
  ]
}
```

**空间分析结果结构**：
```json
{
  "by_directory": [("目录名", {"size": 字节数, "count": 文件数}), ...],
  "by_extension": [("扩展名", {"size": 字节数, "count": 文件数}), ...],
  "total_size": 总字节数,
  "total_files": 总文件数
}
```

## 配置说明
详见 `config.json` 和 `references/usage.md`

## 注意事项
- 基础设定目录是符号链接，必须使用 `followlinks=True` 参数
- 使用 ZIP 格式避免 Windows 解压中文乱码
- 备份文件大小约 30MB（已排除大目录），适合邮箱附件
- **重要**：如果 analysis 不为 None，执行 Agent 需通知用户空间占用情况
- **排除目录**：备份、SKILL、.skills、.tmp、browser、browser_screenshots、mobile_use、screenshots、imgs、表情包、模型、测试目录、服务器运维、回收站
- **单独备份**：
  - 表情包：`./表情包.zip`（约 67MB）
  - 模型：`./模型.zip`（约 192MB）
  - 服务器运维：单独管理（约 765MB）
