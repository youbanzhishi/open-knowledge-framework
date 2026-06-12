#!/usr/bin/env python3
"""
文件清理脚本
支持回收站机制、白名单保护、清理报告生成
"""

import os
import json
import shutil
import hashlib
from datetime import datetime, timedelta
from pathlib import Path

class FileCleaner:
    def __init__(self, config_path=os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")):
        self.config = self._load_config(config_path)
        self.recycle_bin = Path(self.config["recycle_bin"]["path"])
        self.report_path = Path(self.config["report"]["path"])
        self.retention_days = self.config["recycle_bin"]["retention_days"]
        self.whitelist = self.config["whitelist"]
        self.today = datetime.now()
        
    def _load_config(self, config_path):
        """加载配置文件"""
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def _is_protected(self, file_path):
        """检查文件是否在白名单中"""
        file_path = str(Path(file_path).resolve())
        
        # 检查目录白名单
        for dir_path in self.whitelist["directories"]:
            if file_path.startswith(str(Path(dir_path).resolve())):
                return True
        
        # 检查文件白名单
        for protected_file in self.whitelist["files"]:
            if file_path == str(Path(protected_file).resolve()):
                return True
        
        # 检查保护模式
        import fnmatch
        for pattern in self.config["protected_patterns"]:
            if fnmatch.fnmatch(file_path, pattern):
                return True
        
        return False
    
    def _get_file_hash(self, file_path):
        """计算文件hash值"""
        hasher = hashlib.md5()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                hasher.update(chunk)
        return hasher.hexdigest()
    
    def clean_expired_recycle_bin(self):
        """清理回收站中过期的文件"""
        expired_date = (self.today - timedelta(days=self.retention_days)).strftime("%Y%m%d")
        deleted_files = []
        deleted_size = 0
        
        for date_dir in self.recycle_bin.iterdir():
            if date_dir.name <= expired_date:
                for file in date_dir.rglob("*"):
                    if file.is_file():
                        deleted_size += file.stat().st_size
                        deleted_files.append(str(file))
                shutil.rmtree(date_dir)
        
        return deleted_files, deleted_size
    
    def scan_garbage_files(self, root_dir="."):
        """扫描垃圾文件"""
        garbage_files = []
        root_path = Path(root_dir)
        
        # 扫描临时文件
        for pattern in self.config["clean_rules"]["temp_files"]:
            for file in root_path.rglob(pattern):
                if file.is_file() and not self._is_protected(file):
                    garbage_files.append(file)
        
        # 扫描空文件夹
        if self.config["clean_rules"]["empty_folders"]:
            for folder in root_path.rglob("*"):
                if folder.is_dir() and not any(folder.iterdir()):
                    if not self._is_protected(folder):
                        garbage_files.append(folder)
        
        return garbage_files
    
    def move_to_recycle_bin(self, files):
        """将文件移入回收站"""
        today_dir = self.recycle_bin / self.today.strftime("%Y%m%d")
        today_dir.mkdir(parents=True, exist_ok=True)
        
        moved_files = []
        moved_size = 0
        
        for file in files:
            if file.is_file():
                moved_size += file.stat().st_size
            dest = today_dir / file.name
            # 处理重名
            counter = 1
            while dest.exists():
                dest = today_dir / f"{file.stem}_{counter}{file.suffix}"
                counter += 1
            shutil.move(str(file), str(dest))
            moved_files.append((str(file), str(dest)))
        
        return moved_files, moved_size
    
    def generate_report(self, deleted_files, deleted_size, moved_files, moved_size):
        """生成清理报告"""
        report_filename = f"清理报告_{self.today.strftime('%Y%m%d')}.md"
        report_file = self.report_path / report_filename
        self.report_path.mkdir(parents=True, exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(f"# 清理报告 - {self.today.strftime('%Y年%m月%d日')}\n\n")
            f.write("## 执行时间\n")
            f.write(f"执行时间：{self.today.strftime('%H:%M:%S')}\n\n")
            
            f.write("## 回收站清理\n")
            f.write(f"永久删除文件数：{len(deleted_files)}\n")
            f.write(f"释放空间：{deleted_size / 1024 / 1024:.2f} MB\n\n")
            if deleted_files:
                f.write("永久删除列表：\n")
                for file in deleted_files:
                    f.write(f"- {file}\n")
            
            f.write("\n## 本次清理\n")
            f.write(f"移入回收站文件数：{len(moved_files)}\n")
            f.write(f"文件大小总计：{moved_size / 1024 / 1024:.2f} MB\n\n")
            if moved_files:
                f.write("移入回收站列表：\n")
                for orig, dest in moved_files:
                    f.write(f"- 原路径：{orig} → 回收站：{dest}\n")
            
            f.write("\n---\n")
            f.write("*本报告由 file-cleaner 技能自动生成*\n")
        
        return str(report_file)
    
    def run(self, root_dir="."):
        """执行完整清理流程"""
        print("开始清理...")
        
        # 1. 清理过期回收站
        print("清理过期回收站...")
        deleted_files, deleted_size = self.clean_expired_recycle_bin()
        
        # 2. 扫描垃圾文件
        print("扫描垃圾文件...")
        garbage_files = self.scan_garbage_files(root_dir)
        
        # 3. 移入回收站
        print("移入回收站...")
        moved_files, moved_size = self.move_to_recycle_bin(garbage_files)
        
        # 4. 生成报告
        print("生成清理报告...")
        report_file = self.generate_report(deleted_files, deleted_size, moved_files, moved_size)
        
        print(f"清理完成！报告已保存到：{report_file}")
        return report_file


if __name__ == "__main__":
    cleaner = FileCleaner()
    cleaner.run()
