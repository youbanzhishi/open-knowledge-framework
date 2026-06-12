#!/usr/bin/env python3
"""
体系提交深度诊断脚本 v3.0 - 极致优化版
核心优化：最少git调用（~5次），其余全在Python内存中分析
深度检查：逐文件对比blob大小，检测清空/缩减/删除/Merge丢失
"""
import subprocess, sys, os, json, datetime
from pathlib import Path
from collections import defaultdict

REPO_DIR = Path(__file__).resolve().parent.parent
LOG_DIR = REPO_DIR / "交接台" / "诊断日志"
os.chdir(REPO_DIR)

# 全局缓存
BLOB_SIZE_CACHE = {}

def git_once(*args, timeout=300):
    """执行一次git命令，长超时"""
    r = subprocess.run(['git'] + list(args), capture_output=True, text=True, timeout=timeout)
    return r.stdout

def get_blob_size(hash_str):
    """缓存blob大小查询"""
    if hash_str in BLOB_SIZE_CACHE:
        return BLOB_SIZE_CACHE[hash_str]
    try:
        size = int(git_once('cat-file', '-s', hash_str, timeout=60).strip())
        BLOB_SIZE_CACHE[hash_str] = size
        return size
    except:
        BLOB_SIZE_CACHE[hash_str] = -1
        return -1

def batch_blob_sizes(hash_list):
    """批量获取blob大小（用git cat-file --batch-check）"""
    if not hash_list:
        return {}
    # 用git cat-file --batch-check一次查询多个
    input_data = '\n'.join(hash_list) + '\n'
    try:
        r = subprocess.run(
            ['git', 'cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)'],
            input=input_data, capture_output=True, text=True, timeout=300
        )
        result = {}
        for line in r.stdout.strip().split('\n'):
            if not line.strip(): continue
            parts = line.split()
            if len(parts) >= 3:
                result[parts[0]] = int(parts[2])
        return result
    except:
        return {}

def main():
    import argparse
    parser = argparse.ArgumentParser(description='体系提交深度诊断 v3.0')
    parser.add_argument('--last', type=int, default=50)
    args = parser.parse_args()
    
    print(f'🔍 体系提交深度诊断 v3.0（极简git调用版）')
    print(f'   仓库: {REPO_DIR}')
    print(f'   策略: 最少git调用 + 全内存分析')
    
    # ===== 第1次git调用：获取commit列表 + parent信息 =====
    print(f'\n📡 获取commit列表...')
    log_output = git_once('log', '--format=%H|%P|%s', f'-{args.last}')
    
    commits = []
    for line in log_output.strip().split('\n'):
        if not line.strip(): continue
        parts = line.split('|', 2)
        if len(parts) >= 3:
            sha = parts[0].strip()
            parents = parts[1].strip().split() if parts[1].strip() else []
            msg = parts[2].strip()
            commits.append({'sha': sha, 'parents': parents, 'msg': msg})
    
    print(f'   获取到{len(commits)}个commit')
    
    # ===== 第2次git调用：获取所有commit的diff-tree（一次全部） =====
    print(f'\n📡 批量获取所有commit的文件变更...')
    
    all_diff_data = {}  # sha -> {added: [], deleted: [], modified: []}
    all_blob_hashes = set()  # 需要查询大小的blob
    
    for i, c in enumerate(commits):
        sha = c['sha']
        print(f"  [{i+1}/{len(commits)}] 获取diff: {sha[:8]} {c['msg'][:40]}...", flush=True)
        
        diff_info = {'added': [], 'deleted': [], 'modified': [], 'renamed': []}
        
        # 获取完整diff-tree（包含old/new blob hash）
        diff_output = git_once('diff-tree', '-r', '--no-commit-id', sha)
        
        for line in diff_output.strip().split('\n'):
            if not line.strip(): continue
            parts = line.split()
            if len(parts) < 6: continue
            
            old_mode, new_mode, old_hash, new_hash, status = parts[0], parts[1], parts[2], parts[3], parts[4]
            fname = parts[5].strip('"')
            
            # 跳过临时文件
            if fname.endswith('.目录锁') or '.backups/' in fname or '回收站/' in fname:
                continue
            
            if status == 'D':
                diff_info['deleted'].append({'name': fname, 'old_hash': old_hash})
                all_blob_hashes.add(old_hash)
            elif status == 'M':
                diff_info['modified'].append({'name': fname, 'old_hash': old_hash, 'new_hash': new_hash})
                all_blob_hashes.add(old_hash)
                all_blob_hashes.add(new_hash)
            elif status == 'A':
                diff_info['added'].append({'name': fname, 'new_hash': new_hash})
                all_blob_hashes.add(new_hash)
            elif status.startswith('R'):
                old_name = fname
                new_name = parts[6].strip('"') if len(parts) > 6 else fname
                diff_info['renamed'].append({'old': old_name, 'new': new_name, 'old_hash': old_hash, 'new_hash': new_hash})
                all_blob_hashes.add(old_hash)
                all_blob_hashes.add(new_hash)
        
        all_diff_data[sha] = diff_info
    
    # ===== 第3次git调用：批量获取所有blob大小 =====
    print(f'\n📡 批量查询{len(all_blob_hashes)}个blob大小...')
    blob_sizes = batch_blob_sizes(list(all_blob_hashes))
    BLOB_SIZE_CACHE.update(blob_sizes)
    print(f'   获取到{len(blob_sizes)}个blob大小')
    
    # ===== 第4次git调用：获取每个commit的文件树（用于Merge检查和文件数） =====
    print(f'\n📡 获取commit文件树数量...')
    file_counts = {}
    # 对所有commit + 它们的parent获取文件数
    shas_to_count = set()
    for c in commits:
        shas_to_count.add(c['sha'])
        for p in c['parents']:
            shas_to_count.add(p)
    
    for sha in shas_to_count:
        output = git_once('ls-tree', '-r', '--name-only', sha)
        file_counts[sha] = len([l for l in output.strip().split('\n') if l.strip()])
    
    # ===== 纯内存分析 =====
    print(f'\n🔬 深度分析中...')
    
    results = []
    for i, c in enumerate(commits):
        sha = c['sha']
        msg = c['msg']
        parents = c['parents']
        prev_sha = parents[0] if parents else None
        is_merge = len(parents) >= 2
        
        issues = []
        detail = {
            'sha': sha, 'msg': msg, 'status': '✅',
            'is_merge': is_merge,
            'prev_count': file_counts.get(prev_sha, 0),
            'curr_count': file_counts.get(sha, 0),
            'issues': [],
            'deleted_files': [],
            'cleared_files': [],
            'shrunk_files': [],
            'bloated_files': [],
            'merge_lost': [],
        }
        
        if not prev_sha:
            results.append(detail)
            continue
        
        # 文件数变化
        prev_count = detail['prev_count']
        curr_count = detail['curr_count']
        if prev_count > 0:
            pct = ((curr_count - prev_count) / prev_count) * 100
            if pct < -20:
                issues.append(('🚨', f'文件数骤降: {prev_count}→{curr_count} (减少{abs(pct):.0f}%)'))
            elif pct < -5:
                issues.append(('⚠️', f'文件数下降: {prev_count}→{curr_count} (减少{abs(pct):.0f}%)'))
        
        diff = all_diff_data.get(sha, {'added': [], 'deleted': [], 'modified': [], 'renamed': []})
        
        # 检查删除的文件
        for f in diff['deleted']:
            old_size = blob_sizes.get(f['old_hash'], -1)
            detail['deleted_files'].append({'name': f['name'], 'old_size': old_size})
        
        if detail['deleted_files']:
            count = len(detail['deleted_files'])
            severity = '🚨' if count > 5 else '⚠️'
            names = [d['name'] for d in detail['deleted_files'][:5]]
            issues.append((severity, f'删除{count}个文件: {", ".join(names)}{"..." if count>5 else ""}'))
            for d in detail['deleted_files']:
                issues.append(('  ↳', f"删除: {d['name']} (原{d['old_size']}字节)"))
                issues.append(('  ↳', f"恢复: git show {prev_sha[:8]}:\"{d['name']}\" > \"{d['name']}\""))
        
        # 检查修改的文件 - 深度内容对比
        for f in diff['modified']:
            fname = f['name']
            # 跳过二进制/加密
            if fname.endswith(('.enc', '.pack', '.zip', '.png', '.jpg', '.ico', '.gif', '.wav', '.mp3', '.db')):
                continue
            
            old_size = blob_sizes.get(f['old_hash'], -1)
            new_size = blob_sizes.get(f['new_hash'], -1)
            
            if old_size < 0 or new_size < 0:
                continue
            
            # 文件被清空
            if old_size > 100 and new_size == 0:
                issues.append(('🚨', f'文件被清空: {fname} ({old_size}→0字节)'))
                issues.append(('  ↳', f"恢复: git show {prev_sha[:8]}:\"{fname}\" > \"{fname}\""))
                detail['cleared_files'].append({'name': fname, 'old_size': old_size})
            
            # 内容大幅缩减 (>80%)
            elif old_size > 200 and 0 < new_size < old_size * 0.2:
                pct = int((1 - new_size/old_size) * 100)
                issues.append(('🚨', f'内容缩减{pct}%: {fname} ({old_size}→{new_size}字节)'))
                issues.append(('  ↳', f"恢复: git show {prev_sha[:8]}:\"{fname}\" > \"{fname}\""))
                detail['shrunk_files'].append({'name': fname, 'old_size': old_size, 'new_size': new_size, 'pct': pct})
            
            # 内容缩减过半 (50%-80%)
            elif old_size > 100 and 0 < new_size < old_size * 0.5:
                pct = int((1 - new_size/old_size) * 100)
                issues.append(('⚠️', f'内容缩减{pct}%: {fname} ({old_size}→{new_size}字节)'))
                issues.append(('  ↳', f"恢复: git show {prev_sha[:8]}:\"{fname}\" > \"{fname}\""))
                detail['shrunk_files'].append({'name': fname, 'old_size': old_size, 'new_size': new_size, 'pct': pct})
            
            # 内容暴增 (>3倍)
            elif old_size > 500 and new_size > old_size * 3:
                pct = int((new_size/old_size - 1) * 100)
                issues.append(('⚠️', f'内容暴增{pct}%: {fname} ({old_size}→{new_size}字节)，检查重复'))
                detail['bloated_files'].append({'name': fname, 'old_size': old_size, 'new_size': new_size, 'pct': pct})
            
            # 近乎空白
            elif 0 <= new_size < 10 and not fname.endswith(('.enc', '.pack', '.gitignore')):
                issues.append(('🚨', f'文件近乎空白: {fname} ({new_size}字节)'))
                detail['cleared_files'].append({'name': fname, 'new_size': new_size})
        
        # Merge检查
        if is_merge and prev_sha:
            # 获取两个parent的文件列表
            all_parent_files = set()
            for p in parents:
                p_output = git_once('ls-tree', '-r', '--name-only', p)
                all_parent_files.update(f for f in p_output.strip().split('\n') if f.strip())
            
            c_output = git_once('ls-tree', '-r', '--name-only', sha)
            curr_files = set(f for f in c_output.strip().split('\n') if f.strip())
            
            missing = all_parent_files - curr_files
            missing = {f for f in missing if not f.endswith('.目录锁') and '.backups/' not in f and '回收站/' not in f}
            
            if missing:
                severity = '🚨' if len(missing) > 10 else '⚠️'
                sample = list(missing)[:5]
                issues.append((severity, f'Merge丢失{len(missing)}个文件: {", ".join(sample)}{"..." if len(missing)>5 else ""}'))
                detail['merge_lost'] = sorted(missing)
                for f in sorted(missing)[:10]:
                    issues.append(('  ↳', f'丢失: {f}'))
        
        # 状态判定
        if any(s == '🚨' for s, _ in issues):
            detail['status'] = '🚨'
        elif any(s == '⚠️' for s, _ in issues):
            detail['status'] = '⚠️'
        
        detail['issues'] = issues
        results.append(detail)
        print(f"  [{i+1}/{len(commits)}] {detail['status']} {sha[:8]} | {len(issues)}个发现", flush=True)
    
    # ===== 生成报告 =====
    print(f'\n📝 生成报告...')
    
    head_count = file_counts.get(commits[0]['sha'], 0) if commits else 0
    baseline_sha = max(file_counts.keys(), key=lambda s: file_counts[s]) if file_counts else 'HEAD'
    baseline_count = file_counts.get(baseline_sha, 0)
    
    today = datetime.datetime.now().strftime('%Y%m%d')
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    report_file = LOG_DIR / f'commit-diagnose-{today}-50.md'
    
    lines = [
        f'# 体系提交深度诊断报告（50 commit）',
        f'',
        f'> 生成时间: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}',
        f'> 诊断范围: 最近{len(results)}个commit',
        f'> HEAD文件数: {head_count}',
        f'> 完整性基线: {baseline_sha[:8]} ({baseline_count}个文件)',
        f'> 检查维度: 文件删除/清空/内容缩减/暴增/Merge丢失/空白文件',
        f'',
        f'## 摘要',
        f'',
    ]
    
    critical = [r for r in results if r['status'] == '🚨']
    warning = [r for r in results if r['status'] == '⚠️']
    healthy = [r for r in results if r['status'] == '✅']
    
    lines += [
        f'| 级别 | 数量 |',
        f'|------|------|',
        f'| 🚨 严重 | {len(critical)} |',
        f'| ⚠️ 警告 | {len(warning)} |',
        f'| ✅ 正常 | {len(healthy)} |',
        f'',
    ]
    
    # 问题汇总
    all_problems = []
    for r in results:
        for s, d in r['issues']:
            if s in ('🚨', '⚠️'):
                all_problems.append((r['sha'], s, d))
    
    if all_problems:
        lines.append(f'## 问题汇总（共{len(all_problems)}项）')
        lines.append(f'')
        lines.append(f'| # | 严重度 | Commit | 问题描述 |')
        lines.append(f'|---|--------|--------|----------|')
        for i, (sha, sev, desc) in enumerate(all_problems, 1):
            lines.append(f'| {i} | {sev} | {sha[:8]} | {desc[:80]} |')
        lines.append('')
    
    # HEAD完整性
    lines += [
        f'## 当前HEAD完整性',
        f'',
        f'- HEAD文件数: {head_count}',
        f'- 基线文件数: {baseline_count} (commit {baseline_sha[:8]})',
    ]
    if head_count >= baseline_count:
        lines.append(f'- 结论: ✅ HEAD比基线多{head_count-baseline_count}个文件')
    else:
        lines.append(f'- 结论: 🚨 HEAD比基线少{baseline_count-head_count}个文件')
    lines.append('')
    
    # 逐commit详细
    lines.append(f'## 逐commit深度诊断')
    lines.append('')
    
    for r in results:
        lines.append(f'### {r["status"]} {r["sha"][:8]} | {r["msg"]}')
        lines.append(f'')
        lines.append(f'- 文件数: {r["prev_count"]}→{r["curr_count"]}')
        if r['is_merge']:
            lines.append(f'- 类型: Merge commit')
        
        if r['deleted_files']:
            lines.append(f'- **🗑️ 删除{len(r["deleted_files"])}个文件**:')
            for d in r['deleted_files']:
                lines.append(f'  - {d["name"]} (原{d["old_size"]}字节)')
        
        if r['cleared_files']:
            lines.append(f'- **🚨 清空{len(r["cleared_files"])}个文件**:')
            for d in r['cleared_files']:
                if 'old_size' in d:
                    lines.append(f'  - {d["name"]} ({d["old_size"]}→0字节)')
                else:
                    lines.append(f'  - {d["name"]} (近空白{d.get("new_size",0)}字节)')
        
        if r['shrunk_files']:
            lines.append(f'- **📉 内容缩减{len(r["shrunk_files"])}个文件**:')
            for d in r['shrunk_files']:
                lines.append(f'  - {d["name"]} ({d["old_size"]}→{d["new_size"]}字节, 缩减{d["pct"]}%)')
        
        if r['bloated_files']:
            lines.append(f'- **📈 内容暴增{len(r["bloated_files"])}个文件**:')
            for d in r['bloated_files']:
                lines.append(f'  - {d["name"]} ({d["old_size"]}→{d["new_size"]}字节, 增{d["pct"]}%)')
        
        if r['merge_lost']:
            lines.append(f'- **❌ Merge丢失{len(r["merge_lost"])}个文件**:')
            for f in r['merge_lost'][:15]:
                lines.append(f'  - {f}')
            if len(r['merge_lost']) > 15:
                lines.append(f'  - ...还有{len(r["merge_lost"])-15}个')
        
        if r['issues']:
            main_issues = [(s, d) for s, d in r['issues'] if s != '  ↳']
            if main_issues:
                lines.append(f'- 问题:')
                for s, d in r['issues']:
                    lines.append(f'  - {s} {d}')
        else:
            lines.append(f'- 无异常')
        lines.append('')
    
    # 修复命令汇总
    all_recovery = []
    for r in results:
        if r['status'] in ('🚨', '⚠️'):
            prev_sha = None
            for c in commits:
                if c['sha'] == r['sha']:
                    prev_sha = c['parents'][0] if c['parents'] else None
                    break
            
            for d in r.get('deleted_files', []):
                cmd = f'git show {prev_sha[:8]}:"{d["name"]}" > "{d["name"]}"' if prev_sha else f'# 无法确定parent'
                all_recovery.append((d['name'], '删除', cmd))
            for d in r.get('cleared_files', []):
                cmd = f'git show {prev_sha[:8]}:"{d["name"]}" > "{d["name"]}"' if prev_sha else f'# 无法确定parent'
                all_recovery.append((d['name'], '清空', cmd))
            for d in r.get('shrunk_files', []):
                cmd = f'git show {prev_sha[:8]}:"{d["name"]}" > "{d["name"]}"' if prev_sha else f'# 无法确定parent'
                all_recovery.append((d['name'], f'缩减{d["pct"]}%', cmd))
    
    if all_recovery:
        lines += [
            f'## 修复命令汇总',
            f'',
            f'```bash',
            f'# 恢复被误删/清空/缩减的文件',
            f'# ⚠️ 执行前先确认目标文件当前状态',
            f'',
        ]
        seen = set()
        for fname, issue_type, cmd in all_recovery:
            if fname not in seen:
                seen.add(fname)
                lines.append(f'# {issue_type}: {fname}')
                lines.append(cmd)
                lines.append('')
        lines += [f'```', f'']
    
    report = '\n'.join(lines)
    report_file.write_text(report, encoding='utf-8')
    print(f'\n📄 深度诊断报告: {report_file}')
    
    # 最终摘要
    if critical:
        print(f'🚨 发现{len(critical)}个严重commit！详见报告')
    elif warning:
        print(f'⚠️ 发现{len(warning)}个警告，建议检查')
    else:
        print(f'✅ 深度诊断完成，50个commit均无严重问题')

if __name__ == '__main__':
    main()
