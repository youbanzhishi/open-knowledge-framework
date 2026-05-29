#!/bin/bash
# 搜索索引重建脚本 v1.0
# 用法：bash scripts/rebuild-index.sh
# 功能：扫描仓库所有md文件，提取元数据，生成index/db.json
# 性能：897文件遍历一次，5秒内完成

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# 确保index目录存在
mkdir -p index

echo "🔧 正在重建搜索索引..."

# 用Python生成索引
python3 << 'PYTHON_SCRIPT'
import os, json, re, glob
from datetime import datetime

REPO_DIR = os.getcwd()

# 停用词
STOP_WORDS = set([
    "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很",
    "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好", "自己", "这", "那", "他", "她", "它",
    "们", "这个", "那个", "什么", "怎么", "如何", "为什么", "因为", "所以", "但是", "如果", "虽然",
    "而", "且", "并", "或", "与", "和", "对", "从", "向", "往", "跟", "比", "被", "让", "给", "把",
    "请", "一下", "一下", "需要", "应该", "可以", "能", "会", "可能", "还", "又", "也", "都", "只",
    "更", "最", "已", "已经", "正在", "将", "将要", "曾", "曾经", "刚", "刚刚", "才", "刚才",
    "已", "一个", "一种", "一样", "一些", "一样", "一直", "一切", "一般", "一起", "一同", "仍然",
    "仍然", "依然", "仍然", "还是", "仍旧", "果然", "居然", "竟然", "难道", "究竟", "到底",
    "等等", "之类", "什么的", "等等", "总之", "总而言之", "简而言之", "也就是说", "即", "即",
    "也就是说", "换句话说", "反过来说", "相反", "不过", "然而", "但是", "可是", "然而", "然后",
    "于是", "接着", "最后", "终于", "总之", "总的说来", "一方面", "另一方面", "同时", "并且",
])

def extract_title(content, filename):
    """提取标题：第一个#后面的内容"""
    match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    # 没有#标题就用文件名去掉.md
    return re.sub(r"\.md$", "", filename)

def strip_markdown(content):
    """去掉Markdown标记"""
    # 去掉标题标记
    content = re.sub(r"^#{1,6}\s+", "", content, flags=re.MULTILINE)
    # 去掉粗体斜体
    content = re.sub(r"\*\*([^*]+)\*\*", r"\1", content)
    content = re.sub(r"\*([^*]+)\*", r"\1", content)
    content = re.sub(r"__([^_]+)__", r"\1", content)
    content = re.sub(r"_([^_]+)_", r"\1", content)
    # 去掉代码块
    content = re.sub(r"```[\s\S]*?```", "", content)
    content = re.sub(r"`([^`]+)`", r"\1", content)
    # 去掉链接
    content = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", content)
    # 去掉图片
    content = re.sub(r"!\[([^\]]*)\]\([^)]+\)", "", content)
    # 去掉水平线
    content = re.sub(r"^[-*_]{3,}$", "", content, flags=re.MULTILINE)
    # 去掉表格分隔线
    content = re.sub(r"^\|?[-:\s|]+\|?$", "", content, flags=re.MULTILINE)
    # 去掉列表标记
    content = re.sub(r"^[\s]*[-*+]\s+", "", content, flags=re.MULTILINE)
    content = re.sub(r"^[\s]*\d+\.\s+", "", content, flags=re.MULTILINE)
    # 去掉引用标记
    content = re.sub(r"^>\s*", "", content, flags=re.MULTILINE)
    return content

def extract_keywords(title, summary):
    """从标题和摘要中提取关键词"""
    text = title + " " + summary
    keywords = set()
    
    # 英文单词（2个字符以上）
    en_words = re.findall(r"[a-zA-Z]{2,}", text)
    for w in en_words:
        w_lower = w.lower()
        if w_lower not in STOP_WORDS:
            keywords.add(w_lower)
    
    # 中文词（2-4字）
    cn_chars = re.findall(r"[\u4e00-\u9fff]", text)
    cn_text = "".join(cn_chars)
    cn_words = re.findall(r"[\u4e00-\u9fff]{2,4}", cn_text)
    for w in cn_words:
        if w not in STOP_WORDS:
            keywords.add(w)
    
    return list(keywords)[:20]  # 最多20个

def extract_summary(content):
    """提取摘要：前200字符，去掉markdown标记"""
    stripped = strip_markdown(content)
    # 去掉空行
    lines = [l.strip() for l in stripped.split("\n") if l.strip()]
    summary = " ".join(lines)
    return summary[:200] if len(summary) > 200 else summary

def scan_files():
    """扫描所有md文件"""
    files = []
    count = 0
    
    for filepath in glob.glob("**/*.md", recursive=True):
        # 排除回收站
        if "回收站" in filepath:
            continue
        
        try:
            stat = os.stat(filepath)
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            
            filename = os.path.basename(filepath)
            title = extract_title(content, filename)
            summary = extract_summary(content)
            keywords = extract_keywords(title, summary)
            
            # 提取修改日期
            modified = datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d")
            
            # 相对路径
            rel_path = filepath
            
            files.append({
                "path": rel_path,
                "title": title,
                "keywords": keywords,
                "summary": summary,
                "size": stat.st_size,
                "modified": modified
            })
            
            count += 1
            if count % 200 == 0:
                print(f"  已扫描 {count} 个文件...")
                
        except Exception as e:
            continue
    
    return files, count

# 主流程
print(f"📂 扫描目录：{REPO_DIR}")
files, count = scan_files()

# 构建索引
index = {
    "version": 1,
    "build_time": datetime.now().strftime("%Y-%m-%dT%H:%M:%S+08:00"),
    "file_count": count,
    "files": files
}

# 写入文件
output_path = os.path.join(REPO_DIR, "index", "db.json")
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(index, f, ensure_ascii=False, indent=2)

print(f"✅ 索引生成完成：{count} 个文件")
print(f"📄 索引文件：index/db.json")
print(f"⏱️ 生成时间：{index['build_time']}")

PYTHON_SCRIPT

echo "💡 索引已更新，搜索将自动使用新索引"
