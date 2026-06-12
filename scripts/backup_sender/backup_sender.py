#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
备份打包发送脚本
用于将云端文件和记忆打包成 ZIP 格式并发送到指定邮箱
"""

import zipfile
import os
import json
import sys
from datetime import datetime
from typing import Set, Optional, List, Dict
from collections import defaultdict

# 获取技能目录路径
SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 自动检测主对话工作目录
# 脚本位于: 主对话/自定义技能/备份打包技能/scripts/backup_sender.py
# 向上逐级查找包含 MEMORY.md 的目录
def _find_work_dir():
    """从脚本位置向上查找主对话目录（包含 MEMORY.md 的目录）"""
    current = os.path.dirname(os.path.abspath(__file__))
    for _ in range(10):  # 最多向上10级
        if os.path.exists(os.path.join(current, 'MEMORY.md')):
            return current
        parent = os.path.dirname(current)
        if parent == current:
            break
        current = parent
    return os.getcwd()  # 兜底

_WORK_DIR = _find_work_dir()
os.chdir(_WORK_DIR)

# 备份大小阈值（超过此值需分析空间）
SIZE_WARNING_THRESHOLD = 30 * 1024 * 1024  # 30MB


class BackupSender:
    """备份打包发送器"""
    
    def __init__(
        self,
        backup_dir: str = "./备份",
        exclude_dirs: Set[str] = None,
        exclude_ext: Set[str] = None,
        exclude_dir_names: Set[str] = None,
        separate_backup_dirs: Set[str] = None,
        max_file_size: int = 100 * 1024 * 1024,
        keep_days: int = 3,
        size_threshold: int = SIZE_WARNING_THRESHOLD
    ):
        """
        初始化备份发送器
        
        Args:
            backup_dir: 备份文件存放目录
            exclude_dirs: 要排除的目录集合（按完整路径）
            exclude_ext: 要排除的文件扩展名集合
            exclude_dir_names: 要排除的目录名集合（任何层级的同名目录都排除）
            separate_backup_dirs: 需要独立打包的目录集合（从主备份中排除，单独生成zip）
            max_file_size: 单文件大小上限（字节），超过此大小的文件不打包，默认100MB
            keep_days: 保留最近几天的备份
            size_threshold: 大小警告阈值（字节）
        """
        self.backup_dir = backup_dir
        self.work_dir = _WORK_DIR  # 锁定工作目录
        self.exclude_dirs = exclude_dirs or {
            './备份', './回收站', './SKILL', './.skills', './.tmp',
            './browser', './browser_screenshots', './mobile_use', './screenshots', './imgs',
            './表情包', './模型', './测试目录', './用户上传'
        }
        self.exclude_ext = exclude_ext or {'.pptx', '.zip', '.7z', '.rar', '.tar', '.tar.gz', '.wav', '.mp3'}
        self.exclude_dir_names = exclude_dir_names or {'build'}
        self.separate_backup_dirs = separate_backup_dirs or {'./专辑封面'}
        self.max_file_size = max_file_size
        self.keep_days = keep_days
        self.size_threshold = size_threshold
        self.separate_backup_files = []
        
        # 将相对路径转为绝对路径，确保任何工作目录下排除规则都能匹配
        def to_abs(p):
            if p.startswith('./'):
                return os.path.normpath(os.path.join(self.work_dir, p))
            return os.path.normpath(p)
        
        self.abs_exclude_dirs = {to_abs(d) for d in self.exclude_dirs}
        self.abs_separate_backup_dirs = {to_abs(d) for d in self.separate_backup_dirs}
        
        # 确保备份目录存在
        os.makedirs(self.backup_dir, exist_ok=True)
    
    def analyze_space(self, work_dir: str = None) -> Dict:
        """
        分析各目录占用空间
        
        Args:
            work_dir: 要分析的工作目录，默认自动检测
            
        Returns:
            包含空间分析结果的字典
        """
        if work_dir is None:
            work_dir = self.work_dir
        dir_sizes = defaultdict(lambda: {"size": 0, "count": 0, "files": []})
        ext_sizes = defaultdict(lambda: {"size": 0, "count": 0})
        
        for root, dirs, files in os.walk(work_dir, followlinks=True):
            # 过滤目录（使用绝对路径匹配）
            new_dirs = []
            for d in dirs:
                abs_dir_path = os.path.join(root, d)
                if not self._should_exclude_dir(abs_dir_path, d):
                    new_dirs.append(d)
            dirs[:] = new_dirs
            
            # 统计文件
            for f in files:
                if any(f.endswith(ext) for ext in self.exclude_ext):
                    continue
                
                fp = os.path.join(root, f)
                try:
                    size = os.path.getsize(fp)
                    
                    # 按一级目录统计（基于work_dir的相对路径）
                    rel_root = os.path.relpath(root, work_dir)
                    top_dir = rel_root.split('/')[0] if '/' in rel_root else rel_root
                    if top_dir == '.':
                        top_dir = '根目录'
                    dir_sizes[top_dir]["size"] += size
                    dir_sizes[top_dir]["count"] += 1
                    
                    # 记录大文件（>1MB）
                    if size > 1024 * 1024:
                        dir_sizes[top_dir]["files"].append({
                            "name": f,
                            "size": size,
                            "path": fp
                        })
                    
                    # 按扩展名统计
                    ext = os.path.splitext(f)[1].lower() or "无扩展名"
                    ext_sizes[ext]["size"] += size
                    ext_sizes[ext]["count"] += 1
                    
                except Exception:
                    pass
        
        # 排序
        sorted_dirs = sorted(dir_sizes.items(), key=lambda x: x[1]["size"], reverse=True)
        sorted_exts = sorted(ext_sizes.items(), key=lambda x: x[1]["size"], reverse=True)
        
        return {
            "by_directory": sorted_dirs,
            "by_extension": sorted_exts,
            "total_size": sum(d["size"] for d in dir_sizes.values()),
            "total_files": sum(d["count"] for d in dir_sizes.values())
        }
    
    def format_size(self, size_bytes: int) -> str:
        """格式化文件大小"""
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        elif size_bytes < 1024 * 1024 * 1024:
            return f"{size_bytes / 1024 / 1024:.2f} MB"
        else:
            return f"{size_bytes / 1024 / 1024 / 1024:.2f} GB"
    
    def estimate_compression(self, dir_path: str) -> Dict:
        """
        估算目录压缩效果
        
        Args:
            dir_path: 目录路径
            
        Returns:
            包含压缩估算结果的字典
        """
        import tempfile
        import io
        
        # 统计原始大小
        original_size = 0
        file_count = 0
        
        for root, dirs, files in os.walk(dir_path, followlinks=True):
            for f in files:
                fp = os.path.join(root, f)
                try:
                    original_size += os.path.getsize(fp)
                    file_count += 1
                except:
                    pass
        
        if original_size == 0 or file_count == 0:
            return {"error": "目录为空或无法访问"}
        
        # 采样压缩测试（最多取前 50 个文件，避免耗时过长）
        sample_files = []
        for root, dirs, files in os.walk(dir_path, followlinks=True):
            for f in files[:50]:
                fp = os.path.join(root, f)
                sample_files.append(fp)
            if len(sample_files) >= 50:
                break
        
        # 压缩测试
        compressed_size = 0
        try:
            with io.BytesIO() as buffer:
                with zipfile.ZipFile(buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
                    for fp in sample_files:
                        try:
                            zf.write(fp, os.path.relpath(fp, dir_path))
                        except:
                            pass
                compressed_size = buffer.tell()
        except:
            pass
        
        # 计算压缩率
        sample_original = sum(os.path.getsize(fp) for fp in sample_files if os.path.exists(fp))
        compression_ratio = compressed_size / sample_original if sample_original > 0 else 1.0
        
        # 估算压缩后大小
        estimated_compressed = int(original_size * compression_ratio)
        savings = original_size - estimated_compressed
        savings_percent = (1 - compression_ratio) * 100
        
        return {
            "original_size": original_size,
            "estimated_compressed": estimated_compressed,
            "compression_ratio": compression_ratio,
            "savings": savings,
            "savings_percent": savings_percent,
            "file_count": file_count,
            "worth_compressing": savings_percent > 20 and savings > 1024 * 1024,  # 节省超过20%且大于1MB
            "worth_bundling": original_size > 10 * 1024 * 1024 and file_count > 10  # 大于10MB且超过10个文件，建议打包
        }
    
    def print_space_analysis(self, analysis: Dict):
        """打印空间分析结果"""
        print("\n" + "="*60)
        print("📊 空间占用分析")
        print("="*60)
        
        print(f"\n总大小: {self.format_size(analysis['total_size'])} ({analysis['total_files']} 个文件)")
        
        print("\n📁 按目录统计（Top 10）:")
        print("-"*60)
        compress_suggestions = []
        
        for dir_name, info in analysis["by_directory"][:10]:
            print(f"  {dir_name:30s} {self.format_size(info['size']):>10s}  ({info['count']} 文件)")
            # 显示大文件
            if info["files"]:
                for f in info["files"][:3]:
                    print(f"    └─ {f['name']}: {self.format_size(f['size'])}")
            
            # 分析大目录的压缩效果（>5MB）
            if info["size"] > 5 * 1024 * 1024:
                dir_path = f"./{dir_name}" if dir_name != "根目录" else "."
                if os.path.exists(dir_path) and dir_path != ".":
                    comp = self.estimate_compression(dir_path)
                    # 压缩效果明显（>20%节省）
                    if comp.get("worth_compressing"):
                        compress_suggestions.append({
                            "dir": dir_name,
                            "original": info["size"],
                            "estimated": comp["estimated_compressed"],
                            "savings": comp["savings"],
                            "savings_percent": comp["savings_percent"],
                            "reason": "compress"
                        })
                    # 大目录建议打包（即使压缩效果不明显，打包也能减少文件数量）
                    elif comp.get("worth_bundling"):
                        compress_suggestions.append({
                            "dir": dir_name,
                            "original": info["size"],
                            "estimated": comp["estimated_compressed"],
                            "savings": comp["savings"],
                            "savings_percent": comp["savings_percent"],
                            "file_count": comp["file_count"],
                            "reason": "bundle"
                        })
        
        print("\n📄 按文件类型统计（Top 10）:")
        print("-"*60)
        for ext, info in analysis["by_extension"][:10]:
            print(f"  {ext:15s} {self.format_size(info['size']):>10s}  ({info['count']} 文件)")
        
        # 显示压缩建议
        if compress_suggestions:
            print("\n💾 优化建议:")
            print("-"*60)
            for s in compress_suggestions:
                if s["reason"] == "compress":
                    print(f"  📦 {s['dir']} (建议压缩)")
                    print(f"     原始大小: {self.format_size(s['original'])}")
                    print(f"     压缩后约: {self.format_size(s['estimated'])} (节省 {s['savings_percent']:.1f}%)")
                    print(f"     可节省: {self.format_size(s['savings'])}")
                else:  # bundle
                    print(f"  📦 {s['dir']} (建议打包)")
                    print(f"     大小: {self.format_size(s['original'])} ({s['file_count']} 个文件)")
                    print(f"     说明: 该目录文件较多，打包成单个 zip 可减少备份文件数量")
                    if s["savings_percent"] > 5:
                        print(f"     压缩后约: {self.format_size(s['estimated'])} (节省 {s['savings_percent']:.1f}%)")
            
            # 添加到分析结果
            analysis["compress_suggestions"] = compress_suggestions
        
        print("="*60)
    
    def _should_exclude_dir(self, abs_dir_path: str, dir_name: str) -> bool:
        """
        判断目录是否应该被排除（使用绝对路径匹配）
        
        Args:
            abs_dir_path: 目录的绝对路径
            dir_name: 目录名（如 表情包）
        
        Returns:
            是否排除
        """
        # 隐藏目录
        if dir_name.startswith('.'):
            return True
        # 按目录名排除（build等，任何层级）
        if dir_name in self.exclude_dir_names:
            return True
        # 按绝对路径排除
        norm_path = os.path.normpath(abs_dir_path)
        if norm_path in self.abs_exclude_dirs:
            return True
        # 按目录名兜底匹配
        exclude_dir_names_set = {os.path.basename(d) for d in self.abs_exclude_dirs}
        if dir_name in exclude_dir_names_set:
            return True
        # 独立打包目录也排除
        if norm_path in self.abs_separate_backup_dirs:
            return True
        separate_dir_names = {os.path.basename(d) for d in self.abs_separate_backup_dirs}
        if dir_name in separate_dir_names:
            return True
        return False
    
    def create_backup(self, work_dir: str = None) -> str:
        """
        创建备份文件
        
        Args:
            work_dir: 要备份的工作目录，默认自动检测
            
        Returns:
            备份文件路径
        """
        if work_dir is None:
            work_dir = detect_work_dir()
        # 确保在正确目录
        original_dir = os.getcwd()
        os.chdir(work_dir)
        backup_name = os.path.join(
            self.backup_dir,
            f"backup_{datetime.now().strftime('%Y%m%d_%H%M')}.zip"
        )
        
        file_count = 0
        total_size = 0
        
        with zipfile.ZipFile(backup_name, 'w', zipfile.ZIP_DEFLATED) as zf:
            # 关键：followlinks=True 跟随符号链接
            for root, dirs, files in os.walk(work_dir, followlinks=True):
                # 过滤目录（使用绝对路径匹配）
                new_dirs = []
                for d in dirs:
                    abs_dir_path = os.path.join(root, d)
                    if not self._should_exclude_dir(abs_dir_path, d):
                        new_dirs.append(d)
                dirs[:] = new_dirs
                
                # 添加文件
                for f in files:
                    # 排除特定扩展名
                    if any(f.endswith(ext) for ext in self.exclude_ext):
                        continue
                    # 排除超大文件
                    fp = os.path.join(root, f)
                    try:
                        fsize = os.path.getsize(fp)
                        if fsize > self.max_file_size:
                            print(f"Skipped large file: {fp} ({fsize/1024/1024:.1f} MB)")
                            continue
                    except:
                        continue
                    # 使用相对路径作为 zip 内的文件名
                    arcname = os.path.relpath(fp, work_dir)
                    
                    try:
                        zf.write(fp, arcname)
                        file_count += 1
                        total_size += os.path.getsize(fp)
                    except Exception as e:
                        print(f"Warning: Failed to add {fp}: {e}")
        
        # 打印统计信息
        backup_size = os.path.getsize(backup_name)
        print(f"Backup created: {backup_name}")
        print(f"Total files: {file_count}")
        print(f"Backup size: {backup_size / 1024 / 1024:.2f} MB")
        
        # 如果备份过大，分析空间占用
        if backup_size > self.size_threshold:
            print(f"\n⚠️  备份文件超过 {self.size_threshold / 1024 / 1024:.0f}MB，正在分析空间占用...")
            analysis = self.analyze_space(work_dir)
            self.print_space_analysis(analysis)
            
            # 返回额外的分析信息
            os.chdir(original_dir)
            return backup_name, analysis
        
        os.chdir(original_dir)
        return backup_name, None
    
    def create_separate_backups(self, work_dir: str = None) -> List[Dict]:
        """
        为独立打包目录创建单独的备份文件
        
        Args:
            work_dir: 工作目录，默认自动检测
            
        Returns:
            独立备份文件信息列表
        """
        separate_files = []
        
        if work_dir is None:
            work_dir = detect_work_dir()
        original_dir = os.getcwd()
        os.chdir(work_dir)
        for sep_dir in self.separate_backup_dirs:
            full_path = os.path.join(work_dir, sep_dir.lstrip('./'))
            if not os.path.exists(full_path):
                print(f"Separate backup dir not found: {sep_dir}, skipping")
                continue
            
            dir_name = os.path.basename(sep_dir)
            backup_name = os.path.join(
                self.backup_dir,
                f"backup_{dir_name}_{datetime.now().strftime('%Y%m%d_%H%M')}.zip"
            )
            
            file_count = 0
            
            with zipfile.ZipFile(backup_name, 'w', zipfile.ZIP_DEFLATED) as zf:
                for root, dirs, files in os.walk(full_path, followlinks=True):
                    # 过滤目录（使用绝对路径匹配）
                    new_dirs = []
                    for d in dirs:
                        abs_dir_path = os.path.join(root, d)
                        if not self._should_exclude_dir(abs_dir_path, d):
                            new_dirs.append(d)
                    dirs[:] = new_dirs
                    
                    for f in files:
                        if any(f.endswith(ext) for ext in self.exclude_ext):
                            continue
                        
                        fp = os.path.join(root, f)
                        # 排除超大文件
                        try:
                            fsize = os.path.getsize(fp)
                            if fsize > self.max_file_size:
                                print(f"Skipped large file: {fp} ({fsize/1024/1024:.1f} MB)")
                                continue
                        except:
                            continue
                        
                        arcname = os.path.relpath(fp, work_dir)
                        
                        try:
                            zf.write(fp, arcname)
                            file_count += 1
                        except Exception as e:
                            print(f"Warning: Failed to add {fp}: {e}")
            
            backup_size = os.path.getsize(backup_name)
            print(f"Separate backup created: {backup_name}")
            print(f"  Files: {file_count}, Size: {backup_size / 1024 / 1024:.2f} MB")
            
            separate_files.append({
                "dir": sep_dir,
                "path": backup_name,
                "size": backup_size,
                "file_count": file_count
            })
        
        self.separate_backup_files = separate_files
        return separate_files
    
    def cleanup_old_backups(self):
        """清理旧备份文件，保留最近 keep_days 天的备份"""
        import time
        
        cutoff_time = time.time() - (self.keep_days * 24 * 60 * 60)
        count = 0
        
        for filename in os.listdir(self.backup_dir):
            if filename.startswith('backup_') and (filename.endswith('.zip') or filename.endswith('.tar.gz')):
                filepath = os.path.join(self.backup_dir, filename)
                if os.path.getmtime(filepath) < cutoff_time:
                    os.remove(filepath)
                    count += 1
        
        if count > 0:
            print(f"Cleaned up {count} old backup(s)")
    
    def get_backup_info(self, backup_file: str, analysis: dict = None) -> dict:
        """
        获取备份文件信息
        
        Args:
            backup_file: 备份文件路径
            analysis: 空间分析结果
            
        Returns:
            包含备份信息的字典
        """
        with zipfile.ZipFile(backup_file, 'r') as zf:
            files = zf.namelist()
        
        backup_size = os.path.getsize(backup_file)
        info = {
            "date": datetime.now().strftime('%Y-%m-%d'),
            "filename": os.path.basename(backup_file),
            "size": f"{backup_size / 1024 / 1024:.2f} MB",
            "size_bytes": backup_size,
            "file_count": len(files),
            "path": backup_file
        }
        
        # 添加目录大小信息（用于历史对比）
        if analysis:
            dir_sizes = {}
            for dir_name, dir_info in analysis.get("by_directory", []):
                dir_sizes[dir_name] = dir_info["size"]
            info["dir_sizes"] = dir_sizes
        
        return info
    
    def save_history(self, info: dict):
        """保存备份历史记录"""
        history_file = os.path.join(self.backup_dir, "backup_history.json")
        
        history = []
        if os.path.exists(history_file):
            try:
                with open(history_file, 'r', encoding='utf-8') as f:
                    history = json.load(f)
            except:
                history = []
        
        # 添加新记录
        history.append(info)
        
        # 只保留最近7条记录
        if len(history) > 7:
            history = history[-7:]
        
        with open(history_file, 'w', encoding='utf-8') as f:
            json.dump(history, f, ensure_ascii=False, indent=2)
    
    def get_last_backup(self) -> dict:
        """获取上一次备份记录"""
        history_file = os.path.join(self.backup_dir, "backup_history.json")
        
        if not os.path.exists(history_file):
            return None
        
        try:
            with open(history_file, 'r', encoding='utf-8') as f:
                history = json.load(f)
            if len(history) >= 1:
                return history[-1]
        except:
            pass
        
        return None
    
    def compare_with_last(self, current_info: dict) -> dict:
        """对比上次备份，计算变化"""
        last = self.get_last_backup()
        
        if not last:
            return {"is_first_backup": True}
        
        result = {
            "is_first_backup": False,
            "last_date": last.get("date", "未知"),
            "size_change": 0,
            "size_change_text": "",
            "changed_dirs": []
        }
        
        # 计算总大小变化
        current_size = current_info.get("size_bytes", 0)
        last_size = last.get("size_bytes", 0)
        size_diff = current_size - last_size
        
        if size_diff > 0:
            result["size_change"] = size_diff
            result["size_change_text"] = f"+{self.format_size(size_diff)}"
        elif size_diff < 0:
            result["size_change"] = size_diff
            result["size_change_text"] = f"{self.format_size(size_diff)}"
        else:
            result["size_change_text"] = "无变化"
        
        # 计算各目录变化
        current_dirs = current_info.get("dir_sizes", {})
        last_dirs = last.get("dir_sizes", {})
        
        dir_changes = []
        all_dirs = set(current_dirs.keys()) | set(last_dirs.keys())
        
        for dir_name in all_dirs:
            curr_size = current_dirs.get(dir_name, 0)
            last_size_dir = last_dirs.get(dir_name, 0)
            diff = curr_size - last_size_dir
            
            if abs(diff) > 100 * 1024:  # 变化超过100KB才记录
                dir_changes.append({
                    "dir": dir_name,
                    "change": diff,
                    "change_text": f"+{self.format_size(diff)}" if diff > 0 else self.format_size(diff),
                    "current": self.format_size(curr_size)
                })
        
        # 按变化量排序，取最大的
        dir_changes.sort(key=lambda x: abs(x["change"]), reverse=True)
        result["changed_dirs"] = dir_changes[:5]  # 最多显示5个
        
        return result


def detect_work_dir() -> str:
    """
    自动检测主对话工作目录
    脚本位于 /app/data/所有对话/主对话/自定义技能/备份打包技能/scripts/
    工作目录应该是脚本往上3级
    """
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # scripts/ → 备份打包技能/ → 自定义技能/ → 主对话/
    work_dir = os.path.dirname(os.path.dirname(os.path.dirname(script_dir)))
    if os.path.exists(os.path.join(work_dir, 'MEMORY.md')):
        return work_dir
    # 兜底：当前目录
    return os.getcwd()


def load_config() -> dict:
    """加载配置文件"""
    config_path = os.path.join(SKILL_DIR, 'config.json')
    if os.path.exists(config_path):
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def main():
    """主函数 - 用于命令行调用或被其他脚本调用"""
    # 自动检测并切换到主对话工作目录
    work_dir = detect_work_dir()
    os.chdir(work_dir)
    print(f"Working directory: {os.getcwd()}")
    
    # 加载配置
    config = load_config()
    default_config = config.get('default_config', {})
    email_config = config.get('email_config', {})
    
    # 解析命令行参数
    recipient = None
    keep_days = default_config.get('keep_days', 3)
    
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == '--recipient' and i + 1 < len(args):
            recipient = args[i + 1]
            i += 2
        elif args[i] == '--keep-days' and i + 1 < len(args):
            keep_days = int(args[i + 1])
            i += 2
        else:
            i += 1
    
    # 使用默认收件人
    if not recipient:
        recipient = email_config.get('default_recipient')
    
    if not recipient:
        print("Error: No recipient email specified")
        print("Usage: python backup_sender.py --recipient email@example.com [--keep-days 3]")
        sys.exit(1)
    
    # 创建备份发送器
    sender = BackupSender(
        backup_dir=default_config.get('backup_dir', './备份'),
        exclude_dirs=set(default_config.get('exclude_dirs', [])),
        exclude_ext=set(default_config.get('exclude_extensions', [])),
        exclude_dir_names=set(default_config.get('exclude_dir_names', [])),
        separate_backup_dirs=set(default_config.get('separate_backup_dirs', [])),
        max_file_size=default_config.get('max_file_size_mb', 100) * 1024 * 1024,
        keep_days=keep_days
    )
    
    # 创建备份
    print("Creating backup...")
    backup_file, analysis = sender.create_backup()
    
    # 创建独立目录备份
    print("\nCreating separate backups...")
    separate_backups = sender.create_separate_backups()
    
    # 清理旧备份
    sender.cleanup_old_backups()
    
    # 获取备份信息（包含目录大小）
    info = sender.get_backup_info(backup_file, analysis)
    
    # 对比上次备份
    comparison = sender.compare_with_last(info)
    info["comparison"] = comparison
    
    # 保存本次备份记录
    sender.save_history(info)
    
    # 如果有空间分析结果，添加到 info 中
    if analysis:
        info["space_analysis"] = {
            "warning": f"备份文件超过 {sender.size_threshold / 1024 / 1024:.0f}MB",
            "top_directories": [
                {"name": d[0], "size": sender.format_size(d[1]["size"]), "count": d[1]["count"]}
                for d in analysis["by_directory"][:5]
            ],
            "top_extensions": [
                {"ext": e[0], "size": sender.format_size(e[1]["size"]), "count": e[1]["count"]}
                for e in analysis["by_extension"][:5]
            ]
        }
    
    print(f"\nBackup info: {json.dumps(info, ensure_ascii=False, indent=2)}")
    
    # 返回备份文件路径，供邮件发送使用
    return backup_file, recipient, info


if __name__ == "__main__":
    main()
