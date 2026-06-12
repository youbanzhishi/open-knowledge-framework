# 打包备份技能

## 目标
将云端文件打包为ZIP，发送到主人邮箱 18630620063@163.com

## 步骤（严格按顺序执行，不得跳过不得自作主张）

### 步骤1：运行备份脚本
必须完整运行以下代码，不允许省略：
```python
import sys
sys.path.insert(0, './自定义技能/备份打包技能/scripts')
from backup_sender import BackupSender, load_config
config = load_config()
default_config = config.get('default_config', {})
sender = BackupSender(
    backup_dir=default_config.get('backup_dir', './备份'),
    exclude_dirs=set(default_config.get('exclude_dirs', [])),
    exclude_ext=set(default_config.get('exclude_extensions', [])),
    exclude_dir_names=set(default_config.get('exclude_dir_names', [])),
    separate_backup_dirs=set(default_config.get('separate_backup_dirs', [])),
    max_file_size=default_config.get('max_file_size_mb', 100) * 1024 * 1024,
    keep_days=3
)
backup_file, analysis = sender.create_backup()
separate_backups = sender.create_separate_backups()
sender.cleanup_old_backups()
info = sender.get_backup_info(backup_file, analysis)
comparison = sender.compare_with_last(info)
info['comparison'] = comparison
info['separate_backups'] = separate_backups
sender.save_history(info)
import json
print('\n=== 对比结果 ===')
print(json.dumps(comparison, ensure_ascii=False, indent=2))
```

### 步骤2：发送邮件
- 只发送主备份zip到 18630620063@163.com
- 专辑封面独立备份不发送邮件

### 步骤3：更新执行记录
更新 ./定时任务/执行记录.md 中"打包文件和记忆发送邮件"一行的：
- 最后执行时间：当前时间
- 状态：根据邮件发送结果填 ✅ 或 ❌
- 问题分析：记录备份大小/文件数和邮件发送结果

## 禁止事项
- ❌ 不要扫描全目录
- ❌ 不要自行修复冲突
- ❌ 不要删除任何文件
- ❌ 不要手动挑选文件备份
- ❌ 不要因为"目录太大"等理由跳过或缩减备份范围
- ❌ 不要伪造备份结果
- ❌ 失败不要静默跳过，必须报告

## 如果遇到未列出的情况
→ 停下来，报告给主对话，等指令。不允许自行判断。

## 排除规则说明（只读，不要修改）
- 全局排除扩展名：.pptx, .zip, .7z, .rar, .tar, .tar.gz, .wav, .mp3
- 全局排除目录名：build
- 排除目录：备份/回收站/SKILL/.skills/.tmp/browser/imgs/表情包/模型/测试目录/用户上传
- 独立打包目录：专辑封面
- 服务器运维目录已加入主备份

## 配置文件
./自定义技能/备份打包技能/config.json
