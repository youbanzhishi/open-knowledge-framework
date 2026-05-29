#!/bin/bash
# 意图检索脚本 v3.4
# 用法：bash scripts/act.sh "意图" [搜索范围] [角色路径]
#   搜索范围：.(默认,整个体系)/shared/role/all/具体路径
#   角色路径：可选，如"角色/AI调教师"，前科必显拉角色+关联项目的踩坑
# 示例：
#   bash scripts/act.sh "push代码" . "角色/AI调教师"     ← 知识搜全体系，前科拉调教师+关联项目
#   bash scripts/act.sh "push代码"                       ← 知识搜全体系，无前科
#   bash scripts/act.sh "部署服务" shared "角色/ECS运维"  ← 知识只搜共享，前科拉运维+关联项目
#
# 设计理念：
#   - 知识搜整个体系，前科搜角色+关联项目：两个维度分开
#   - 前科跟执行者走，不跟搜索范围走：搜共享知识时也该看到自己的前科
#   - 关联项目自动发现：解析角色INDEX.md中的关联项目链接，项目里的坑也拉出来
#   - 前科必显：hot-rules和踩坑无条件置顶，不靠搜到，强制展示
#   - 宁多勿漏：搜到多余的比搜不到要好
#   - 智能拆词：长意图自动拆成短关键词，提高命中率
#   - 索引加速：用db.json索引过滤候选文件，grep只搜top 30文件而非全897文件

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# ── 启动必检：冲突标记 ──
# 如果上次同步有未处理冲突，直接拒绝执行，只有主人能解锁
PLATFORM_DIR=""
search_dir="$REPO_DIR/.."
while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/.sync-paths.conf" ] || [ -d "$search_dir/基础设定" ]; then
        PLATFORM_DIR="$(cd "$search_dir" && pwd)"
        break
    fi
    search_dir="$(cd "$search_dir/.." && pwd)"
done

if [ -n "$PLATFORM_DIR" ] && [ -f "$PLATFORM_DIR/.sync-conflict" ]; then
    echo "⛔ 存在未处理的设定同步冲突，所有角色暂停执行！"
    echo ""
    cat "$PLATFORM_DIR/.sync-conflict"
    echo ""
    echo "只有主人可以处理："
    echo "  1. 查看回收站中的差异文件和双方备份"
    echo "  2. 确认用仓库版 → 手动 cp 仓库版到平台路径"
    echo "  3. 确认用平台版 → bash scripts/sync-settings.sh push"
    echo "  4. 处理完后 → 删除 .sync-conflict 文件解锁"
    echo ""
    echo "角色无权跳过此检查。"
    exit 1
fi


# ── 环境配置 ──
# 每次角色切换时自动配置安全环境
if [ -f "$REPO_DIR/scripts/config-env.sh" ]; then
    bash "$REPO_DIR/scripts/config-env.sh"
fi


# ── 启动必检：设定同步 ──
# 仓库是真相源，每次启动角色时自动同步最新设定到平台
# 首次运行会自动生成 .sync-paths.conf（路径映射）
# 有冲突则写入冲突标记文件并退出，角色无法绕过
if [ -f "$REPO_DIR/scripts/sync-settings.sh" ]; then
    SYNC_OUTPUT=$(bash "$REPO_DIR/scripts/sync-settings.sh" 2>&1) || {
        # 同步失败 → 写冲突标记文件
        if [ -n "$PLATFORM_DIR" ]; then
            cat > "$PLATFORM_DIR/.sync-conflict" << CONFLICT_EOF
⚠️ 设定同步冲突 - $(date '+%Y-%m-%d %H:%M')
$(echo "$SYNC_OUTPUT" | grep -E "⚠️|冲突|备份|差异" )
CONFLICT_EOF
        fi
        echo "⛔ 设定同步冲突！已写入 .sync-conflict 锁定平台"
        echo "所有角色将无法执行，直到主人手动处理冲突并删除 .sync-conflict"
        exit 1
    }
    # 显示同步摘要
    echo "$SYNC_OUTPUT" | grep -E "✅|⚠️|首次" || true
fi

# ── 迁移检测：检查热更新.md中是否有未完成的迁移项 ──
if [ -n "${3:-}" ] && [ -f "$REPO_DIR/热更新.md" ] && [ -f "$REPO_DIR/入口.md" ]; then
    ROLE_NAME=$(basename "${3:-}")
    # 解析入口.md中的迁移清单：提取"谁需要动"列含该角色的行，且"完成角色"列不含该角色名
    MIGRATE_WARNINGS=$(python3 -c "
import re, sys
role = '$ROLE_NAME'
with open('$REPO_DIR/入口.md', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()
# 找迁移清单表格
in_table = False
warnings = []
for line in content.split('\n'):
    if '版本迁移清单' in line:
        in_table = True
        continue
    if in_table and line.startswith('>') and 'v20及更早' in line:
        break
    if in_table and line.startswith('|') and not line.startswith('|--') and not line.startswith('| 版本'):
        cells = [c.strip() for c in line.split('|') if c.strip()]
        if len(cells) >= 5:
            who = cells[1]
            completed = cells[4]
            # 检查该角色是否需要迁移但未完成
            if '所有角色' in who or role in who:
                if role not in completed:
                    warnings.append(f'  {cells[0]} | {cells[2][:40]}')
if warnings:
    print('⚠️⚠️⚠️ 版本迁移未完成！以下迁移项尚未执行：')
    for w in warnings:
        print(w)
    print('→ 请先完成迁移再继续任务（入口.md → 版本迁移清单）')
    print('')
" 2>/dev/null || true)
    if [ -n "$MIGRATE_WARNINGS" ]; then
        echo "$MIGRATE_WARNINGS"
    fi
fi

QUERY="${1:?用法: $0 \"意图描述\" [搜索范围] [角色路径]}"
SCOPE="${2:-.}"
ROLE_PATH="${3:-}"

echo "=== 知识检索 ==="
echo "🔍 意图：$QUERY"
echo "📂 知识范围：$SCOPE"
[ -n "$ROLE_PATH" ] && echo "👤 前科角色：$ROLE_PATH"
echo ""

case "$SCOPE" in
  shared) SEARCH_DIR="共享知识" ;;
  role)   SEARCH_DIR="角色" ;;
  all|.)  SEARCH_DIR="." ;;
  *)      SEARCH_DIR="$SCOPE" ;;
esac

# ── 用Python做拆词+前科解析+格式化输出 ──
QUERY="$QUERY" SEARCH_DIR="$SEARCH_DIR" ROLE_PATH="$ROLE_PATH" REPO_DIR="$REPO_DIR" python3 -c '
import re, os, sys, glob, subprocess
from collections import defaultdict
from datetime import datetime

query = os.environ["QUERY"]
search_dir = os.environ["SEARCH_DIR"]
role_path = os.environ.get("ROLE_PATH", "")
repo_dir = os.environ["REPO_DIR"]
os.chdir(repo_dir)

# ── 角色核心信息展示（仅当ROLE_PATH非空时） ──
if role_path:
    role_info_shown = False
    # 1. 角色定位：从RULES.md读取"## 角色定位"段的前5行
    rules_file = os.path.join(role_path, "RULES.md")
    if os.path.isfile(rules_file):
        with open(rules_file, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
        in_section = False
        section_lines = []
        for line in lines:
            if re.search(r"^##\s+角色定位", line):
                in_section = True
                continue
            if in_section:
                if re.match(r"^##\s", line):
                    break
                section_lines.append(line.rstrip())
        if section_lines:
            role_info_shown = True
            print("👤 角色核心信息")
            print("═══════════════════════════════════════")
            print("  📌 角色定位：")
            for sl in section_lines[:5]:
                if sl.strip():
                    print(f"     {sl.strip()[:120]}")
            print("")

    # 2. hot-rules：强制展示全文
    hr_candidates = []
    for hr in glob.glob(os.path.join(role_path, "**/hot-rules.md"), recursive=True):
        if "回收站" not in hr:
            hr_candidates.append(hr)
    # 也检查项目级规划下的hot-rules（通过INDEX关联）
    if os.path.isfile(os.path.join(role_path, "INDEX.md")):
        with open(os.path.join(role_path, "INDEX.md"), "r", encoding="utf-8", errors="ignore") as f:
            idx_content = f.read()
        for m in re.finditer(r"\[([^\]]+)\]\(([^)]+)\)", idx_content):
            link = m.group(2)
            resolved = os.path.normpath(os.path.join(role_path, link))
            for hr in glob.glob(os.path.join(resolved, "规划/hot-rules.md")):
                if "回收站" not in hr and hr not in hr_candidates:
                    hr_candidates.append(hr)

    if hr_candidates:
        if not role_info_shown:
            print("👤 角色核心信息")
            print("═══════════════════════════════════════")
            role_info_shown = True
        print("  🔥 hot-rules（必读）：")
        for hr in hr_candidates:
            rel = os.path.relpath(hr, repo_dir)
            with open(hr, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            for line in content.split("\n"):
                if line.strip():
                    print(f"     {line.strip()[:120]}")
            print(f"     ← {rel}")
        print("")

    if role_info_shown:
        print("───────────────────────────────────────")
        print("")

# 停用词拆关键词
stop_pattern = r"我要|帮我|请|一下|怎么|如何|什么|的|了|吗|呢|吧|到|在|是|和|与|或|不|也|还|又|把|被|让|给|对|从|向|往|跟|比|有|个|这|那|就|都|会|能|可以|需要|应该"
stripped = re.sub(f"({stop_pattern})", "", query).strip()
en_words = re.findall(r"[a-zA-Z]{2,}", stripped)
cn_raw = re.findall(r"[\u4e00-\u9fff]{2,}", stripped)
cn_words = []
for w in cn_raw:
    if len(w) == 2:
        cn_words.append(w)
    else:
        for i in range(len(w) - 1):
            cn_words.append(w[i:i+2])
all_keywords = list(dict.fromkeys(en_words + cn_words))
if not all_keywords:
    all_keywords = [c for c in stripped if c.strip()]

# 保存关键词到临时文件供shell grep用
kw_file = "/tmp/act_keywords.txt"
with open(kw_file, "w") as f:
    f.write("\n".join(all_keywords))

# ── 前科必显区 ──
prior_dirs = []

def parse_associated_projects(index_path):
    projects = []
    try:
        with open(index_path, "r", encoding="utf-8", errors="ignore") as f:
            in_section = False
            for line in f:
                if re.search(r"关联项目", line):
                    in_section = True
                    continue
                if in_section and line.strip().startswith("#"):
                    break
                if in_section:
                    m = re.search(r"\[([^\]]+)\]\(([^)]+)\)", line)
                    if m:
                        link = m.group(2)
                        resolved = os.path.normpath(os.path.join(os.path.dirname(index_path), link))
                        if os.path.isdir(resolved):
                            projects.append(resolved)
    except:
        pass
    return projects

if role_path:
    prior_dirs.append(role_path)
    index_file = os.path.join(role_path, "INDEX.md")
    if os.path.isfile(index_file):
        assoc = parse_associated_projects(index_file)
        for p in assoc:
            prior_dirs.append(p)
else:
    prior_dirs.append(search_dir)

# 展示前科搜索范围
if prior_dirs:
    prior_display = [os.path.relpath(d, repo_dir) if d != "." else "." for d in prior_dirs]
    print(f"🔎 前科范围：{prior_display}")
    print("")

# ── 前科搜索（用grep，快） ──
has_priors = False

for prior_dir in prior_dirs:
    # hot-rules搜索
    hr_files = []
    for hr in glob.glob(os.path.join(prior_dir, "**/hot-rules.md"), recursive=True):
        if "回收站" not in hr:
            hr_files.append(hr)

    if hr_files:
        # 构造grep模式：所有关键词用\|连接
        kw_pattern = "\\|".join(re.escape(kw) for kw in all_keywords)
        for hr in hr_files:
            try:
                result = subprocess.run(
                    ["grep", "-c", "-i", "-E", kw_pattern, hr],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    match_count = int(result.stdout.strip())
                    if match_count >= 2:
                        with open(hr, "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read()
                        lines = [l.strip() for l in content.split("\n") if l.strip() and not l.strip().startswith("#")][:5]
                        rel = os.path.relpath(hr, repo_dir)
                        if not has_priors:
                            has_priors = True
                            print("⚠️ 前科必显（历史踩坑，必读再操作）")
                            print("═══════════════════════════════════════")
                        print(f"  🔥 {rel} （命中{match_count}行）")
                        for l in lines:
                            print(f"     {l[:100]}")
                        print("")
            except:
                continue

    # knowledge搜索
    kn_files = []
    for kn_dir in glob.glob(os.path.join(prior_dir, "**/knowledge/"), recursive=True):
        if "回收站" not in kn_dir:
            for kn_file in glob.glob(os.path.join(kn_dir, "*.md")):
                kn_files.append(kn_file)

    if kn_files:
        kw_pattern = "\\|".join(re.escape(kw) for kw in all_keywords)
        for kn in kn_files:
            try:
                result = subprocess.run(
                    ["grep", "-c", "-i", "-E", kw_pattern, kn],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    match_count = int(result.stdout.strip())
                    if match_count >= 2:
                        with open(kn, "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read(2000)
                        lines = [l.strip() for l in content.split("\n") if l.strip() and not l.strip().startswith("#")][:3]
                        rel = os.path.relpath(kn, repo_dir)
                        # 提取踩坑count字段
                        pitfall_count = ""
                        count_match = re.search(r"\*\*count\*\*\s*:\s*(\d+)", content)
                        if count_match:
                            pitfall_count = f" [踩{count_match.group(1)}次]"
                        if not has_priors:
                            has_priors = True
                            print("⚠️ 前科必显（历史踩坑，必读再操作）")
                            print("═══════════════════════════════════════")
                        print(f"  📝 {rel}{pitfall_count} （命中{match_count}行）")
                        for l in lines:
                            print(f"     {l[:100]}")
                        print("")
            except:
                continue

if has_priors:
    print("───────────────────────────────────────")
    print("")

# ── 意图搜索区（索引加速：先查db.json再grep候选文件） ──
kw_display = " ".join(all_keywords)
scope_display = os.path.relpath(search_dir, repo_dir) if search_dir != "." else "整个体系"
print(f"🔑 关键词：{kw_display}")
print(f"📂 知识搜索范围：{scope_display}")
print("")

# 检查索引是否存在，不存在则自动重建
index_file = os.path.join(repo_dir, "index", "db.json")
if not os.path.exists(index_file):
    print("📦 索引不存在，正在生成...")
    import subprocess
    subprocess.run(["bash", os.path.join(repo_dir, "scripts", "rebuild-index.sh")])

# 加载索引
import json
try:
    with open(index_file, "r", encoding="utf-8") as f:
        index_data = json.load(f)
    index_load_time = datetime.now().strftime("%H:%M:%S")
    idx_file_count = index_data["file_count"]
    print(f"📊 索引已加载：{idx_file_count} 个文件 ({index_load_time})")
except Exception as e:
    print(f"⚠️ 索引加载失败，回退到全量grep: {e}")
    index_data = None

# ── 索引匹配：计算每个文件的命中数 ──
candidate_files = []
if index_data:
    # 过滤到搜索范围内
    idx_files = index_data["files"]
    if search_dir != ".":
        valid_files = [f for f in idx_files if f["path"].startswith(search_dir) or search_dir.startswith(f["path"].rsplit("/", 1)[0] + "/")]
    else:
        valid_files = idx_files
    
    # 计算每个文件的关键词命中数
    file_scores = []
    for f in valid_files:
        score = 0
        f_title = f["title"]
        f_path = f["path"]
        f_summary = f["summary"]
        f_keywords = f["keywords"]
        title_lower = f_title.lower()
        summary_lower = f_summary.lower()
        keywords_str = " ".join(f_keywords).lower()
        searchable = title_lower + " " + summary_lower + " " + keywords_str
        
        for kw in all_keywords:
            kw_lower = kw.lower()
            # 标题命中权重3，关键词命中权重2，摘要命中权重1
            if kw_lower in title_lower:
                score += 3
            if kw_lower in keywords_str:
                score += 2
            if kw_lower in summary_lower:
                score += 1
        
        if score > 0:
            file_scores.append((f["path"], score))
    
    # 按命中数排序，取top 30
    file_scores.sort(key=lambda x: x[1], reverse=True)
    candidate_files = [fp for fp, _ in file_scores[:30]]
    
    print(f"🎯 索引命中：{len(candidate_files)} 个候选文件")

# 用grep在候选文件中搜索
kw_pattern = "|".join(re.escape(kw) for kw in all_keywords)

def run_grep(pattern, *files, timeout=15, max_lines=100):
    """在指定文件中grep搜索，只取前max_lines行"""
    if not files:
        return ""
    cmd = ["grep", "-rn", "-i", "-E", "--include=*.md", pattern]
    cmd.extend(f for f in files if os.path.isfile(f))
    if not any(os.path.isfile(f) for f in files):
        return ""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        lines = result.stdout.split("\n")
        if len(lines) > max_lines:
            return "\n".join(lines[:max_lines]) + "\n"
        return result.stdout
    except subprocess.TimeoutExpired:
        return ""

grep_output = ""
if candidate_files:
    # 只搜候选文件
    grep_output = run_grep(kw_pattern, *candidate_files, timeout=15)
else:
    # 索引失效，回退到全量grep
    print("⚠️ 索引未命中，回退到全量搜索...")
    if search_dir == ".":
        grep_output = run_grep(kw_pattern, ".", timeout=30)
    else:
        grep_output = run_grep(kw_pattern, search_dir, timeout=30)

if not grep_output.strip():
    if not has_priors:
        print("📭 未找到相关内容")
        print("💡 提示：")
        print("   1. 缩短关键词：bash scripts/act.sh \"核心词\"")
        print("   2. 指定角色搜前科：bash scripts/act.sh \"意图\" . \"角色/xxx\"")
        print("   3. 缩小范围：bash scripts/act.sh \"意图\" shared")
    else:
        print("📭 意图搜索无结果，但前科必显区有内容，请先阅读上方⚠️区域")
    sys.exit(0)

# 解析grep输出，统计每个文件的命中数
file_hits = defaultdict(int)
file_lines = defaultdict(list)

for line in grep_output.split("\n"):
    if not line.strip():
        continue
    # 格式：./path/file.md:行号:内容
    # 找第一个冒号分割文件路径
    parts = line.split(":", 2)
    if len(parts) < 3:
        continue
    fp = parts[0]
    line_num = parts[1]
    content = parts[2].strip()[:120]
    rel = os.path.relpath(fp, repo_dir)
    file_hits[fp] += 1
    file_lines[fp].append(f"{rel}:{line_num}: {content}")

sorted_files = sorted(file_hits.items(), key=lambda x: x[1], reverse=True)

print("📖 搜索结果（按相关度排序）：")
print("═══════════════════════════════════════")
for fp, count in sorted_files[:10]:
    rel = os.path.relpath(fp, repo_dir)
    print(f"  📄 {rel} （命中{count}行）")

print("")
print("── 匹配行 ──")
shown = 0
for fp, _ in sorted_files[:10]:
    for line in file_lines[fp]:
        print(line)
        shown += 1
        if shown >= 30:
            break
    if shown >= 30:
        break

print("")
print("💡 前科必显+搜索结果，先读⚠️区再读📖区")

# ── 交接台检查：只显示与当前角色相关的待领条目 ──
role_path = os.environ.get("ROLE_PATH", "")
if role_path:
    role_name = os.path.basename(role_path)
    handover_file = os.path.join(repo_dir, "交接台", "README.md")
    if os.path.exists(handover_file):
        with open(handover_file, "r", encoding="utf-8") as hf:
            handover = hf.read()

        # 检查物料交接区（表格行）和bug单区（表格行）
        material_items = []
        bug_items = []
        in_material = False
        in_bug = False
        for line in handover.split("\\n"):
            if "物料交接" in line and "##" in line:
                in_material = True
                in_bug = False
                continue
            if "体系bug单" in line and "##" in line:
                in_material = False
                in_bug = True
                continue
            if line.startswith("## ") and "bug" not in line and "物料交接" not in line:
                in_material = False
                in_bug = False
                continue
            # 物料交接：表格行匹配角色名+待状态
            if in_material and "|" in line and not line.strip().startswith("|-") and not line.strip().startswith("| 编号"):
                if role_name in line and "待" in line:
                    material_items.append(line.strip())
            # bug单：表格行匹配⏳待处理（只有调教师需要看到）
            if in_bug and "|" in line and not line.strip().startswith("|-") and not line.strip().startswith("| 编号"):
                if ("⏳" in line or "待处理" in line) and "调教师" in role_name:
                    cells = [c.strip() for c in line.split("|") if c.strip()]
                    if len(cells) >= 3:
                        bug_items.append(cells[0] + " | " + cells[2])

        all_items = material_items + bug_items
        if all_items:
            print("")
            parts = []
            if material_items:
                parts.append(str(len(material_items)) + "条物料待领")
            if bug_items:
                parts.append(str(len(bug_items)) + "条bug单待处理")
            print("📦 交接台：" + "，".join(parts))
            for item in material_items:
                cells = [c.strip() for c in item.split("|") if c.strip()]
                if len(cells) >= 4:
                    print("  " + cells[0] + " | " + cells[1] + "→" + cells[2] + " | " + cells[3] + " | " + cells[-1])
            for item in bug_items:
                print("  🐛 " + item)
            print("  → 详见 交接台/")
'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  