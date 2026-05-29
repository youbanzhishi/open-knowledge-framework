#!/bin/bash
# 知识体系归档脚本
# 用法：bash archive.sh [主题关键词]
# 示例：bash archive.sh 混音    → 归档所有混音相关文件
#       bash archive.sh         → 归档全部知识

BASE="./open-knowledge-system"
OUT="./归档/知识归档-$(date +%Y%m%d)"

mkdir -p "$OUT"

if [ -z "$1" ]; then
  # 全量归档：按项目+角色+共享知识组织
  echo "📦 全量归档..."
  
  # 项目文档
  for proj in "$BASE/项目文档"/*/; do
    name=$(basename "$proj")
    [ "$name" = "*" ] && continue
    mkdir -p "$OUT/项目/$name"
    # 只归档 docs/knowledge/ 和 规划/
    [ -d "$proj/docs/knowledge" ] && cp -r "$proj/docs/knowledge/"*.md "$OUT/项目/$name/" 2>/dev/null || true
    [ -d "$proj/规划" ] && cp -r "$proj/规划/"*.md "$OUT/项目/$name/" 2>/dev/null || true
  done
  
  # 角色knowledge
  for role in "$BASE/角色"/*/; do
    name=$(basename "$role")
    [ "$name" = "*" ] && continue
    [ -d "$role/knowledge" ] || continue
    mkdir -p "$OUT/角色/$name"
    cp -r "$role/knowledge/"*.md "$OUT/角色/$name/" 2>/dev/null || true
    for sub in "$role/knowledge"/*/; do
      [ -d "$sub" ] || continue
      subname=$(basename "$sub")
      mkdir -p "$OUT/角色/$name/$subname"
      cp "$sub"*.md "$OUT/角色/$name/$subname/" 2>/dev/null || true
    done
  done
  
  # 共享知识
  cp -r "$BASE/共享知识/"* "$OUT/共享知识/" 2>/dev/null || true
  
  echo "✅ 全量归档完成 → $OUT"

else
  # 按关键词归档：扫所有knowledge目录，文件名含关键词的复制出来
  KEYWORD="$1"
  echo "📦 按关键词归档：$KEYWORD"
  
  mkdir -p "$OUT/$KEYWORD"
  
  # 扫项目
  for proj in "$BASE/项目文档"/*/docs/knowledge/; do
    for f in "$proj"*"$KEYWORD"*; do
      [ -f "$f" ] && cp "$f" "$OUT/$KEYWORD/" 2>/dev/null && echo "  📄 $(basename $f)"
    done
  done
  
  # 扫角色
  for role in "$BASE/角色"/*/knowledge/; do
    for f in $(find "$role" -name "*$KEYWORD*" -type f 2>/dev/null); do
      cp "$f" "$OUT/$KEYWORD/" 2>/dev/null && echo "  📄 $(basename $f)"
    done
  done
  
  # 扫共享知识
  for f in $(find "$BASE/共享知识" -name "*$KEYWORD*" -type f 2>/dev/null); do
    cp "$f" "$OUT/$KEYWORD/" 2>/dev/null && echo "  📄 $(basename $f)"
  done
  
  count=$(ls "$OUT/$KEYWORD/" 2>/dev/null | wc -l)
  echo "✅ 归档 $count 个文件 → $OUT/$KEYWORD/"
fi
