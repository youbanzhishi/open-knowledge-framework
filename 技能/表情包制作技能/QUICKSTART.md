# 快速开始指南

## 环境准备

### 1. 安装依赖
```bash
cd .skills/skill-sticker-pack
pip install Pillow PyYAML
```

### 2. （可选）透明背景处理
```bash
# 本地处理
pip install rembg
rembg install  # 安装模型

# 或使用 remove.bg API
export REMOVE_BG_API_KEY="your_api_key"
```

## 模式 A: 新角色创建

### Step 1: 定义角色设定
编辑 `templates/characters/新角色/character.md`

### Step 2: 生成标准形象
```bash
python scripts/generate_character.py \
  --character "新角色" \
  --ref-image "用户上传/头像.jpg" \
  --output "templates/characters/新角色/reference.png"
```

### Step 3: 批量生成表情
```bash
python scripts/generate_expressions.py \
  --character "新角色" \
  --ref-image "templates/characters/新角色/reference.png" \
  --scene "基础场景" \
  --output "output/新角色/基础表情套包"
```

### Step 4: 处理透明背景
```bash
python scripts/process_transparency.py \
  --input-dir "output/新角色/基础表情套包/原图" \
  --output-dir "output/新角色/基础表情套包/透明背景"
```

### Step 5: 生成衍生素材
```bash
python scripts/generate_derivatives.py \
  --character "新角色" \
  --ref-image "templates/characters/新角色/reference.png" \
  --transparent-dir "output/新角色/基础表情套包/透明背景" \
  --output "output/新角色/基础表情套包/衍生素材"
```

## 模式 B: 衍生套包创建

基于已有角色创建新场景的套包：

```bash
python scripts/generate_expressions.py \
  --character "傲娇小汤圆" \
  --ref-image "templates/characters/傲娇小汤圆/reference.png" \
  --scene "过年场景" \
  --output "output/傲娇小汤圆/拜年表情套包"

python scripts/process_transparency.py \
  --input-dir "output/傲娇小汤圆/拜年表情套包/原图" \
  --output-dir "output/傲娇小汤圆/拜年表情套包/透明背景"

python scripts/generate_derivatives.py \
  --character "傲娇小汤圆" \
  --ref-image "templates/characters/傲娇小汤圆/reference.png" \
  --transparent-dir "output/傲娇小汤圆/拜年表情套包/透明背景" \
  --output "output/傲娇小汤圆/拜年表情套包/衍生素材"
```

## 目录结构

```
output/
└── {角色名}/
    └── {场景名}套包/
        ├── 不带文字版/
        │   ├── 原图/
        │   ├── 透明背景/
        │   └── 衍生素材/
        │       ├── 主图/
        │       ├── 缩略图/
        │       ├── 聊天面板图标/
        │       ├── 表情封面图/
        │       └── 详情页横幅/
        └── 带文字版/
            └── ...
```

## 提示词模板

### 基础角色描述
```
白色圆润的可爱汤圆卡通形象，圆滚滚的身体，大眼睛，黑豆般的瞳孔，粉嫩的小嘴微张，头顶有一个小揪揪，坐在蒸笼里，周围有蒸汽缭绕
```

### 表情描述模板
```
{基础描述}，表情{情绪}，{动作细节}
```

### 示例
```
傲娇小汤圆卡通形象，圆滚滚的身体，表情傲娇，头微微扬起，眼睛看向上方，嘴角上扬，小揪揪翘起，可爱卡通插画，纯白底背景
```
