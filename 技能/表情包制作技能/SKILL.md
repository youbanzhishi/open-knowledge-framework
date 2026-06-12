# 表情包生成技能 (Sticker Pack Generator)

## 1. 技能概述

这是一套可复用的表情包批量生成技能，基于 AI 生图技术实现角色形象的多种表情场景化应用。

### ⚠️ 强制前置步骤（跨会话形象一致性保障）

**为什么必须有这一步**：用户可能换话题、换会话来生成新场景的表情图（如从运动版切到新年版）。新会话没有任何历史上下文，如果不读取形象档案，就会凭空想象角色外貌，导致形象丢失（已有惨痛教训：v7自作主张发明新造型被否、v8纯文生图形象不一致）。

**执行规则**：
1. 生成任何角色表情图之前，**必须先读取该角色的形象档案**
2. 形象档案路径：`技能/表情包制作技能/templates/characters/[角色名]/形象档案/`
3. 必读文件：
   - `形象档案/形象规范.md` — 跨会话唯一形象标准（外貌、头顶分性别、参考图源、提示词模板、禁忌、生图策略）
   - `形象档案/提示词记录.md` — 历史版本的提示词和评价
4. 形象规范.md中的「生图策略原则」和「提示词禁忌」必须严格遵守
5. **铁律27**：形象定稿后必须使用图生图，不能用文生图

**不读取形象档案就生成表情图，视为违反铁律！**

### 核心能力
- **角色生成**：从参考图生成统一风格的角色标准形象
- **表情批量生成**：基于角色模板批量生成多种表情
- **透明背景处理**：一键去除背景，生成透明 PNG
- **衍生素材生成**：自动生成主图、缩略图、图标、封面、横幅等

### 适用场景
| 场景 | 说明 |
|------|------|
| 原创 IP 孵化 | 从零打造专属表情包角色 |
| 主题套包扩展 | 基于已有角色开发节日/职业主题套包 |
| 素材库建设 | 批量产出可复用的表情素材 |
| 自媒体运营 | 微信/小红书/微博配图素材 |

---

## 技能信息
- 加载模式：progressive
- 触发关键词：[表情包, emoji, 贴图]
- 摘要：表情包设计与批量生成

## 2. 两种工作模式

### 模式 A：新角色创建
从一张参考图开始，生成完整的角色模板和基础表情套包。

**适用场景**：全新角色 IP 开发

**流程**：
```
参考图 → 角色设定 → 标准形象生成 → 基础表情词库 → 批量生成表情 → 透明化处理 → 衍生素材
```

### 模式 B：衍生套包创建
基于已有角色模板，快速生成主题场景的表情套包。

**适用场景**：节日/职业/场景主题表情包

**流程**：
```
选择角色模板 → 选择/自定义场景词库 → 批量生成表情 → 透明化处理 → 衍生素材
```

---

## 3. 完整工作流步骤

### Phase 1: 角色标准化 (模式 A)

#### Step 1.1 定义角色设定
创建 `templates/characters/{角色名}/character.md`：
```markdown
# 角色名称：傲娇小汤圆

## 角色描述
一个圆滚滚、软糯糯的小汤圆，有着傲娇的小表情

## 外形特征
- 主体：白色圆润的汤圆形态
- 表情：灵动的大眼睛、微张的小嘴
- 特点：头顶有小揪揪，周围有蒸笼元素

## 性格标签
傲娇、嘴硬、可爱、软萌
```

#### Step 1.2 生成标准形象参考图
```bash
python scripts/generate_character.py \
    --character "傲娇小汤圆" \
    --template "templates/characters/傲娇小汤圆/character.md" \
    --ref-image "用户上传/参考图.jpg" \
    --output "templates/characters/傲娇小汤圆/reference.png"
```

**核心提示词模板**：
```
白色圆润的可爱汤圆卡通形象，圆滚滚的身体，大眼睛，黑豆般的瞳孔，粉嫩的小嘴微张，头顶有一个小揪揪，坐在蒸笼里，周围有蒸汽缭绕，干净的白底，简洁插画风格，正面视角，高清质感
```

### Phase 2: 表情批量生成

#### Step 2.1 配置表情词库
编辑 `templates/characters/{角色名}/expression_words.json`：
```json
{
  "基础表情": ["平静", "开心", "生气", "难过", "无语", "崩溃", "感动"],
  "傲娇系列": ["傲娇脸", "哼", "不理你", "才没有", "嘴硬", "真香"],
  "回应系列": ["OK", "嗯嗯", "好的", "收到", "没问题", "谢谢"]
}
```

#### Step 2.2 批量生成表情
```bash
# 生成不带文字版
python scripts/generate_expressions.py \
    --character "傲娇小汤圆" \
    --ref-image "templates/characters/傲娇小汤圆/reference.png" \
    --scene "基础场景" \
    --output "output/傲娇小汤圆/基础表情套包/不带文字版" \
    --with-text false

# 生成带文字版
python scripts/generate_expressions.py \
    --character "傲娇小汤圆" \
    --ref-image "templates/characters/傲娇小汤圆/reference.png" \
    --scene "基础场景" \
    --output "output/傲娇小汤圆/基础表情套包/带文字版" \
    --with-text true
```

**生成提示词模板**：
```
[基础描述], [表情状态], [动作细节], 白底背景
```

### Phase 3: 透明背景处理

**⚠️ 透明背景PNG标准输出尺寸：500x500**（节省资源，原图保持原始尺寸不改动。衍生图从500x500缩放生成）

**方案汇总（按优先级）**：

| 优先级 | 方案 | 适用场景 | 备注 |
|--------|------|---------|------|
| 1 | 外部洪水灌水法（含方向变体） | ⭐优先使用 白底/黑底图通用 | 四边灌水/上方灌水/左上角/右上角/灌黑水等方向变体，详见9.6节 |
| 2 | 三模型对比法 | 单一模型效果不理想 | u2net/isnet-anime/isnet-general-use对比选最佳，可取alpha并集融合（⭐17_累了定稿方案） |
| 3 | 混合方案v3 | 白底原图通用 | 绿色背景+rembg(主体) OR 洪水填充(文字)，取并集 |
| 4 | 坐标掩码涂抹法 | 特定区域需要补充 | ⚠️必须基于已有方案的结果进行补充，不能单独使用 |
| 5 | 内部填充法v3 | 底部无闭合线+主体内部有空隙 | 从内部洪水填充+闭运算+彩色像素保护+封闭内部区域检测 |
| 6 | 内部洪水填充法 | 细小白色缺失修复（头顶毛等） | 闭运算封缺口→内部种子点洪水填充→不越界，比矩形涂抹法安全 |
| 7 | 轮廓线围栏法 | 白色主体+白底+底部有开口 | 黑线本身当围栏+底部封闭线，贴合主体无多余白色（⭐推荐） |
| 8 | 颜色灌水法 | 白色背景+非白色主体轮廓 | 按颜色判断水流，白色区域才让水通过，非白色天然挡水，无需修补断裂 |
| 9 | 外部灌水法+L形封闭线 | 底部+侧面都有开口 | 竖线封侧+底线封底=L形围栏，配合外部灌水（⭐09_甲方爸爸定稿方案） |

**特殊情况**：
| 方案 | 适用场景 | 备注 |
|------|---------|------|
| u2net处理绿幕图 | 绿幕背景原图 | 无蓝色光晕 |
| 黑底→白底→isnet-anime | 黑底原图+无特效 | 图生图转白底再抠图 |
| 黑底→绿幕→u2net | 黑底原图+彩色特效 | strength=0.5保表情 |

#### Step 3.1 首选方案：rembg 本地处理（推荐）
**优势**：完全免费、无次数限制、本地运行、图片不外传

```bash
# 安装依赖
pip install rembg scipy

# 使用处理脚本
python scripts/process_transparency_rembg.py \
    --input-dir "output/傲娇小汤圆/基础表情套包/不带文字版/原图" \
    --output-dir "output/傲娇小汤圆/基础表情套包/不带文字版/透明背景" \
    --target-size 500
```

**处理逻辑**：
- 使用 rembg 的 `remove()` 函数自动识别主体
- 保持原图 RGB 颜色不变，只用 rembg 生成的 alpha 通道
- 对 alpha 做轻微膨胀（iterations=5）和高斯平滑（sigma=2.0）
- **文字保护**：检测并保护图片下方的彩色文字区域
- 支持自定义输出尺寸

**文字保护逻辑**（带文字版必须）：
```python
# 全图检测文字区域（不限制位置）
colorfulness = np.std([r, g, b], axis=0)  # 颜色丰富度

# 与背景色的差异
corners = [orig_array[0, 0], orig_array[0, w-1], orig_array[h-1, 0], orig_array[h-1, w-1]]
bg_color = np.median(corners, axis=0)
bg_distance = np.sqrt((r - bg_color[0])**2 + (g - bg_color[1])**2 + (b - bg_color[2])**2)

# 文字区域：颜色丰富 OR 与背景差异大
text_by_color = (colorfulness > 12) | (bg_distance > 30)

# 形态学处理
text_region = ndimage.binary_dilation(text_by_color, iterations=8)
text_region = ndimage.binary_closing(text_region, iterations=5)

# 主体区域膨胀
dilated_subject = ndimage.binary_dilation(subject_region, iterations=8)

# 合并主体和文字区域
combined = dilated_subject | text_region
combined = ndimage.binary_dilation(combined, iterations=3)
```

**关键参数**：
- 颜色丰富度阈值：`colorfulness > 12`
- 背景差异阈值：`bg_distance > 30`
- 主体膨胀次数：`iterations=8`（如身体有缺失可增加到10-12）
- 文字膨胀次数：`iterations=8`
- 高斯平滑：`sigma=2.0`

**注意**：不带文字版不需要文字保护逻辑，可减少膨胀次数

**彩色特效保护逻辑**（带特效的表情必须）：

当表情包包含彩色特效（如金黄色月亮、太阳、星星、黑色线条等）时，需要额外保护：

```python
# 颜色丰富度检测（识别彩色区域）
colorfulness = np.std([r, g, b], axis=0)
colored_area = colorfulness > 15  # 有明显颜色的区域

# 与背景色差异检测
corners = [orig_array[0, 0], orig_array[0, w-1], orig_array[h-1, 0], orig_array[h-1, w-1]]
bg_color = np.median(corners, axis=0)
bg_distance = np.sqrt((r - bg_color[0])**2 + (g - bg_color[1])**2 + (b - bg_color[2])**2)
diff_from_bg = bg_distance > 30

# 膨胀彩色区域
colored_expanded = ndimage.binary_dilation(colored_area | diff_from_bg, iterations=8)

# 合并主体和彩色区域
combined = dilated_subject | colored_expanded
```

**彩色特效保护参数**：
| 参数 | 推荐值 | 说明 |
|------|--------|------|
| 颜色丰富度阈值 | `> 15` | 识别非灰度彩色区域 |
| 背景差异阈值 | `> 30` | 识别与背景不同的区域 |
| 彩色区域膨胀 | `iterations=8` | 确保彩色特效完整 |
| 主体膨胀 | `iterations=12` | 确保主体完整 |

**适用场景**：
- 金色/黄色特效（月亮、太阳、星星等）
- 黑色线条特效
- 任何非白色的彩色装饰元素

**可用模型**：
| 模型 | 适用场景 |
|------|---------|
| isnet-anime | **动漫/卡通专用（推荐）**，mIoU 0.94 |
| u2net | 通用模型，效果好（默认） |
| u2netp | 轻量版，速度快 |
| isnet-general-use | 复杂背景效果更好 |
| silueta | 人像专用 |

**模型配置（重要）**：
```python
# 避免rembg自动下载模型，需在导入前设置环境变量
import os
os.environ['U2NET_HOME'] = '模型/rembg'
from rembg import new_session
```

**模型下载**：
```bash
# 镜像下载（推荐，速度快）
curl -L -o 模型/rembg/isnet-anime.onnx "https://gh-proxy.com/https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-anime.onnx"

# 或设置环境变量后rembg会自动从本地目录读取
export U2NET_HOME="/app/data/所有对话/主对话/模型/rembg"
```

**模型大小**：isnet-anime 212MB, isnet-general-use 171MB, u2net 168MB, silueta 43MB

#### Step 3.1.1 带文字版特殊处理（文字提取融合）

**问题**：所有模型都会把文字当背景去掉，需要从原图提取文字并叠加回去。

**解决方案**：

```python
from rembg import new_session, remove
from PIL import Image
import numpy as np
from scipy import ndimage

# 1. 读取原图（jpg格式）
original = Image.open('原图/10_不理你.jpg').convert('RGBA')
original_arr = np.array(original)

# 2. 用 isnet-anime 处理
session = new_session('isnet-anime')
anime_result = remove(original, session=session)
anime_arr = np.array(anime_result)

# 3. 检测文字区域
gray = original_arr[:,:,:3].mean(axis=2)
anime_alpha = anime_arr[:,:,3]

# 文字检测条件：
is_background = anime_alpha < 80       # isnet-anime 认为是背景
is_dark = gray < 252                   # 深色像素
subject_expanded = ndimage.binary_dilation(anime_alpha > 128, iterations=20)
text_mask = is_dark & is_background & (~subject_expanded)

# 4. 叠加文字到结果
result = anime_arr.copy()
result[text_mask, 3] = 255                    # 文字区域设为不透明
result[text_mask, :3] = original_arr[text_mask, :3]  # 复制文字颜色

# 5. 保存
Image.fromarray(result).save('透明背景/10_不理你.png')
```

**关键参数**：
| 参数 | 推荐值 | 说明 |
|------|--------|------|
| 文字亮度阈值 | `< 252` | 排除主体边缘的半白色像素 |
| 背景判断阈值 | `alpha < 80` | isnet-anime 判断为背景的区域 |
| 主体膨胀次数 | `iterations=20` | 防止主体边缘被误判为文字 |

**适用场景**：
- 带文字的表情包（文字在主体外部）
- 文字颜色较深（灰色/黑色/彩色）
- 白色主体的卡通形象

**效果**：
- 主体完整保留（isnet-anime 的优势）
- 文字从原图提取并叠加
- 透明背景干净

#### Step 3.1.2 绿幕背景处理（推荐方案）

**背景选择**：强烈推荐使用绿色背景（chroma key green #00FF00）生成原图

**优势**：
- 与白色主体对比度高
- 与黑色线条不冲突
- 边缘干净，无需复杂模型

**⭐ 最佳处理方案：用 u2net 模型直接处理绿幕图（2026-04-27 验证）**

**核心经验**：自定义绿幕检测算法会导致蓝色光晕和噪点问题，**用 rembg 的 u2net 模型直接处理绿幕图效果最好**！

```python
import os
os.environ['U2NET_HOME'] = '模型/rembg'  # 必须在导入rembg前设置
from rembg import new_session, remove
from PIL import Image
import numpy as np
from scipy import ndimage

# 用 u2net 处理绿幕图
session = new_session('u2net')
result = remove(green_screen_image, session=session)

# 仅做轻微平滑（可选）
arr = np.array(result)
alpha_smooth = ndimage.gaussian_filter(arr[:,:,3].astype(float), sigma=1.5)
arr[:,:,3] = np.clip(alpha_smooth, 0, 255).astype(np.uint8)
```

**优势**：
- ✅ **无蓝色光晕**（这是最关键的改进！）
- ✅ 边缘干净，无噪点
- ✅ 主体完整保留
- ✅ 处理速度快

**不推荐方案**：
- ❌ 自定义绿幕检测算法 → 会导致蓝色光晕
- ❌ 边缘颜色修正 → 会导致颜色异常

---

**旧方案：自定义绿幕检测算法（已废弃，仅供了解）**

以下方法会导致蓝色光晕，不再推荐使用：

```python
# ❌ 不推荐：会导致蓝色光晕
def process_green_screen(input_path, output_path):
    original = Image.open(input_path).convert('RGBA')
    arr = np.array(original)
    
    r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]
    
    # 绿幕检测：G-R > 30 且 G-B > 100
    green_diff_rb = g.astype(int) - r.astype(int)
    green_diff_gb = g.astype(int) - b.astype(int)
    green_mask = (green_diff_rb > 30) & (green_diff_gb > 100)
    
    # 主体 = 非绿色区域
    subject_mask = ~green_mask
    
    # 去除边缘绿色光晕：先腐蚀再膨胀
    subject_eroded = ndimage.binary_erosion(subject_mask, iterations=2)
    subject_final = ndimage.binary_dilation(subject_eroded, iterations=1)
    
    # 平滑边缘
    from scipy.ndimage import gaussian_filter
    alpha_smooth = gaussian_filter(subject_final.astype(float), sigma=1.0)
    alpha = (alpha_smooth * 255).astype(np.uint8)
    
    # 边缘颜色修正：消除绿色残留
    result = arr.copy()
    result[:,:,3] = alpha
    
    edge_mask = (alpha > 50) & (alpha < 200)
    edge_green = edge_mask & (g > r) & (g > b)
    avg_rgb = ((r.astype(int) + g.astype(int) + b.astype(int)) // 3).astype(np.uint8)
    result[edge_green, 0] = avg_rgb[edge_green]
    result[edge_green, 1] = avg_rgb[edge_green]
    result[edge_green, 2] = avg_rgb[edge_green]
    
    Image.fromarray(result).save(output_path)
```

**关键参数**：
| 参数 | 推荐值 | 说明 |
|------|--------|------|
| 绿幕检测条件 | G-R>30 且 G-B>100 | 区分绿色背景与主体 |
| 腐蚀次数 | iterations=2 | 去除边缘绿色光晕 |
| 膨胀次数 | iterations=1 | 恢复主体形状 |
| 高斯平滑 | sigma=1.0 | 边缘平滑 |

**适用场景**：
- 白色主体 + 黑色线条的卡通形象
- 绿幕背景的原图
- 需要快速批量处理

**效果**：
- 主体完整保留
- 黑色线条不受影响
- 边缘无绿色残留
- 处理速度快

#### Step 3.2 备选方案：remove.bg API
**适用场景**：rembg 效果不佳时，或需要更精细的处理

```bash
python scripts/process_transparency.py \
    --input-dir "output/傲娇小汤圆/基础表情套包/不带文字版/原图" \
    --output-dir "output/傲娇小汤圆/基础表情套包/不带文字版/透明背景" \
    --method "remove.bg" \
    --api-key "YOUR_REMOVE_BG_API_KEY"
```

**注意**：免费版每月限制 50 次 API 调用

#### Step 3.3 最后备选：颜色阈值算法
**适用场景**：背景颜色单一、主体与背景对比明显的图片

```bash
python scripts/process_transparency_v2.py \
    --input-dir "output/傲娇小汤圆/基础表情套包/不带文字版/原图" \
    --output-dir "output/傲娇小汤圆/基础表情套包/不带文字版/透明背景"
```

**注意**：此方法对白色主体效果较差，仅作最后备选

#### Step 3.4 黑底原图处理方案（特殊情况）

**问题背景**：
- 黑色背景的原图，黑色线条会被当作背景一起透明化
- 直接用 rembg 抠图，眼睛和轮廓线条会消失

**失败方案记录**：
1. **亮度阈值法**：白色主体的高亮区域也被识别为背景
2. **纯黑像素检测法**：半透明过渡区域无法处理，边缘毛刺严重
3. **白色膨胀法**：文字和噪点都被保留，不干净
4. **isnet-anime 直接抠图**：黑色线条被透明化，眼睛和轮廓消失

**推荐方案：图生图黑底转白底**

**步骤**：
1. 使用图生图将黑底转为白底
2. 使用 isnet-anime 进行透明化处理

```python
# 1. 图生图转换背景
response = client.images.generate(
    model="flux-kontext-pro",  # 或其他支持图生图的模型
    prompt="保持完全相同的角色形象、姿势、表情和场景元素，保留所有彩色特效（如星星、光效等），只将纯黑色背景替换为纯白色背景，其他一切保持不变",
    image=original_image_path,
    strength=0.7,  # 0.6-0.7 之间，太高会改变主体
    size="1024x1024"
)

# 2. 保存白底图
white_bg_image.save(white_bg_path)

# 3. 使用 isnet-anime 透明化
python scripts/process_transparency_rembg.py \
    --input-dir "白底图目录" \
    --output-dir "透明背景目录" \
    --model isnet-anime \
    --target-size 500
```

**关键参数**：
| 参数 | 推荐值 | 说明 |
|------|--------|------|
| 图生图强度 | `0.6-0.7` | 太高会改变主体，太低无法改变背景 |
| 提示词要点 | "保持完全相同"+"保留所有彩色特效" | 防止特效丢失 |
| 抠图模型 | `isnet-anime` | 白底+白色主体效果最好 |

**已知问题**：
- ⚠️ 彩色特效（如星星✨）可能在图生图时丢失，需在提示词中明确强调保留
- 解决：在提示词中添加"保留所有彩色特效（如星星、光效、光芒等）"

**已验证成功案例**：
- 打工人版 08_不想上班、22_摸鱼、23_社畜

**已验证结论：图生图直接黑底→透明背景不可行**
- 图生图模型输出 RGB 格式（JPG），不支持 alpha 通道
- 即使提示词要求"透明背景"，只生成棋盘格视觉效果，并非真正透明
- 必须两步走：图生图黑底→白底 → isnet-anime 抠图

**优化提示词（解决特效丢失问题）**：
```
保持完全相同的角色形象、姿势、表情和场景元素，
**必须保留所有彩色特效元素（包括但不限于：金色星星✨、光芒、光晕、闪光等装饰效果，
保持原有的颜色、大小、位置和发光效果）**，
只将纯黑色背景替换为纯白色背景，角色和特效完全不变，画质高清
```

**已验证成功案例**：
- 打工人版 08_工资发了：黑底→绿幕→透明背景，两个金黄色星星✨完整保留

**推荐方案对比**：
| 方案 | 特效保留 | 边缘质量 | 适用场景 |
|------|---------|---------|---------|
| 黑底→白底→isnet-anime | ❌ 金黄色特效丢失 | 好 | 无特效的白色主体 |
| 黑底→绿幕→绿幕抠图 | ✅ 金黄色特效保留 | 好 | 有彩色特效的表情包（推荐）|

**绿幕抠图算法（适配浅绿色背景）**：
```python
import numpy as np
from PIL import Image
from scipy import ndimage

def light_green_screen_removal(input_path, output_path):
    img = Image.open(input_path).convert('RGBA')
    arr = np.array(img)
    r, g, b = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int)
    
    # 浅绿色检测（生成模型背景约RGB(128, 190, 120)）
    green_mask = (g > r) & (g > b) & (g > 150) & (abs(r - b) < 30) & (g > r + 40) & (g > b + 40)
    
    # 主体 = 非绿色区域，腐蚀+膨胀去光晕，高斯平滑
    subject_mask = ~green_mask
    subject_eroded = ndimage.binary_erosion(subject_mask, iterations=2)
    subject_final = ndimage.binary_dilation(subject_eroded, iterations=3)
    alpha_smooth = ndimage.gaussian_filter(subject_final.astype(float), sigma=1.5)
    alpha = (alpha_smooth * 255).astype(np.uint8)
    
    # 边缘绿色修正为灰度
    result = arr.copy()
    result[:,:,3] = alpha
    edge_mask = (alpha > 50) & (alpha < 200) & (g > r) & (g > b)
    avg_rgb = ((r + g + b) // 3).astype(np.uint8)
    result[edge_mask, :3] = np.stack([avg_rgb[edge_mask]]*3, axis=1)
    
    Image.fromarray(result).save(output_path)
```

#### Step 3.5 三模型对比法（备选方案）

**适用场景**：
- 单一模型效果不理想时
- 不确定哪个模型更适合当前图片
- 复杂边缘或特殊颜色主体

**核心思路**：同时用多个rembg模型处理同一张图，对比选择最佳结果；或取多个模型alpha并集融合

**操作流程**：
1. 用3个模型分别处理原图（u2net、isnet-anime、isnet-general-use）
2. 生成横向对比图（原图+三个模型结果）
3. 用户选择最佳效果的模型
4. **融合方案**：如果不同模型各有所长（如u2net主体完整但文字缺失，isnet-general-use文字完整但主体缺失），取两者alpha并集融合

**代码实现**：
```python
import os
os.environ['U2NET_HOME'] = '模型/rembg'
from rembg import new_session, remove
from PIL import Image
import numpy as np

# 读取原图
original = Image.open('原图.jpg').convert('RGBA')
arr = np.array(original)

# 检测文字区域保护
colorfulness = np.std([arr[:,:,0], arr[:,:,1], arr[:,:,2]], axis=0)
text_region = colorfulness > 12

# 三个模型
models = ['u2net', 'isnet-anime', 'isnet-general-use']

for model_name in models:
    session = new_session(model_name)
    result = remove(original, session=session)
    result_arr = np.array(result)
    
    # 保护文字区域
    result_arr[text_region, 3] = 255
    result_arr[text_region, :3] = arr[text_region, :3]
    
    output_path = f'透明背景/文件名_{model_name}.png'
    Image.fromarray(result_arr).save(output_path)

# 生成对比图供用户选择
```

**模型特点对比**：
| 模型 | 特点 | 适用场景 |
|------|------|---------|
| u2net | 通用模型，效果稳定 | 一般场景 |
| isnet-anime | 动漫/卡通专用，mIoU最高 | 卡通表情包（推荐） |
| isnet-general-use | 复杂背景效果更好 | 复杂背景图片 |
| silueta | 人像专用 | 人物照片 |

**实战案例**：
- 图片：21_老板_备选2.jpg
- 问题：混合方案v3主体左侧白色缺失，绿幕+u2net产生绿色噪点
- 结果：isnet-anime效果最好，主体完整、边缘干净

- 图片：17_累了_备选1.jpg
- 问题：u2net主体完整但文字缺失，isnet-general-use文字完整但主体阴影缺失
- 结果：双模型融合（u2net+isnet-general-use取alpha并集），主体完整+文字完整 ✅

#### Step 3.6 底部闭合法（特殊场景）

**适用场景**：
- 主体下方没有闭合线条（如身体和文字相连）
- 主体内部有需要保留透明的空隙（如双手举起，手臂和头部之间的空隙）
- 所有其他方案（混合方案v3、三模型对比法）均失败

**核心思路**：
检测左右两侧黑色轮廓线，在指定y轴位置画水平封闭线，与黑色轮廓形成完整封闭区域，然后洪水填充封闭区域外的白色背景为透明。

**处理步骤**：
1. 检测左右两侧黑色轮廓线位置（灰度值<50）
2. 在指定y轴位置画水平封闭线，连接左右轮廓
3. 封闭线与黑色轮廓形成完整封闭区域
4. 洪水填充封闭区域外的白色背景为透明
5. 主体内部的空隙如果从外部进入，会自然保留为透明

**核心思路**：从封闭区域**内部**出发洪水填充，而非从外部填充。黑色轮廓线虽然不连续，但闭运算可以封住小缺口（嘴巴、眼睛），大空隙（手臂间楔形空隙）因为从内部出发不需要穿过黑色线条，自然保留。

**代码实现**：
```python
from PIL import Image
import numpy as np
from scipy import ndimage

# 读取原图
img = Image.open('原图.jpg').convert('RGBA')
img_array = np.array(img)
gray = np.array(img.convert('L'))
height, width = gray.shape

# 1. 检测黑色轮廓线（灰度值<50）
black_mask = gray < 50

# 2. 闭运算修补小缺口（嘴巴、眼睛等），iterations=8约封16px宽的缺口
black_closed = ndimage.binary_closing(black_mask, iterations=8)

# 3. 添加底部封闭线（如y=1900，需根据图片调整）
y_line = 1900
black_at_y = np.where(black_mask[y_line, :])[0]
x_min, x_max = black_at_y[0], black_at_y[-1]
black_closed[y_line, x_min:x_max+1] = True

# 4. 从主体内部出发洪水填充（遇到闭运算后的线条就停）
def flood_fill_internal(start_y, start_x, barrier, h, w):
    filled = np.zeros_like(barrier)
    visited = np.zeros_like(barrier)
    if barrier[start_y, start_x]: return filled
    stack = [(start_y, start_x)]
    while stack:
        y, x = stack.pop()
        if y < 0 or y >= h or x < 0 or x >= w: continue
        if visited[y, x] or barrier[y, x]: continue
        visited[y, x] = True
        filled[y, x] = True
        stack.extend([(y-1, x), (y+1, x), (y, x-1), (y, x+1)])
    return filled

# 从图片中心找内部起点
internal_mask = flood_fill_internal(height//2, width//2, black_closed, height, width)

# 5. 保护彩色像素（文字填充等）
r, g, b = img_array[:,:,0].astype(int), img_array[:,:,1].astype(int), img_array[:,:,2].astype(int)
color_diff = np.maximum(r, np.maximum(g, b)) - np.minimum(r, np.minimum(g, b))
colored_mask = color_diff > 15

# 6. 合并：内部填充 + 原始黑色轮廓线 + 彩色像素
final_subject = internal_mask | black_mask | colored_mask

# 7. 连通区域去噪
labeled, num = ndimage.label(final_subject)
sizes = ndimage.sum(final_subject, labeled, range(1, num+1))
clean_mask = np.zeros_like(final_subject)
for i in range(1, num+1):
    if sizes[i-1] > 500:
        clean_mask |= (labeled == i)

# ===== v3关键补充：封闭内部区域检测（补上眼睛等被闭运算封住的区域）=====

# 8. 反转黑色轮廓线，找被轮廓线围住的封闭内部区域
white_area = ~black_mask  # 非黑色像素区域
labeled_interior, num_interior = ndimage.label(white_area)

# 找与图像边缘相连的区域 = 外部背景
edge_labels = set()
for x in range(width):
    if labeled_interior[0,x] > 0: edge_labels.add(labeled_interior[0,x])
    if labeled_interior[height-1,x] > 0: edge_labels.add(labeled_interior[height-1,x])
for y in range(height):
    if labeled_interior[y,0] > 0: edge_labels.add(labeled_interior[y,0])
    if labeled_interior[y,width-1] > 0: edge_labels.add(labeled_interior[y,width-1])

# 不与边缘相连的区域 = 被轮廓线围住的封闭内部（眼睛、嘴巴内部等）
interior_mask = np.zeros((height, width), dtype=bool)
for i in range(1, num_interior+1):
    if i not in edge_labels:
        region = labeled_interior == i
        if np.sum(region) > 10:  # 忽略极小噪点
            interior_mask |= region

# 9. 融合：D版掩码 OR 封闭内部区域
fused_mask = clean_mask | interior_mask

# 10. 从原图取像素
result = img_array.copy()
result[~fused_mask, 3] = 0
Image.fromarray(result).save('透明背景/输出.png')
```

**关键参数**：
| 参数 | 说明 |
|------|------|
| 黑色轮廓线检测阈值 | 灰度值<50 |
| 底部封闭线位置 | 根据图片实际情况指定（如y=1900） |
| 闭运算iterations | 8（约封16px宽缺口，如嘴巴/眼睛） |
| 彩色像素阈值 | RGB通道差>15 |

**🔥 内部填充法版本迭代记录（重点！后续继续研究v4/v5的基础）**：

> **核心突破**：传统思路是从外部洪水填充把背景变透明，但黑色轮廓线不连续（嘴巴371px缺口、眼睛等），水必然漏入主体。**反过来想**——从主体内部出发洪水填充，遇到黑色线条就停，小缺口用闭运算封住，大空隙（手臂间楔形）自然不会误填。

---

**v1（步骤A）：内部填充，无闭运算**
- 思路：检测黑色轮廓线 → 添加底部封闭线 → 从中心内部洪水填充
- 结果：❌ 水从嘴巴、眼睛等小缺口漏出头部，流入手臂间空隙
- 原因：黑色轮廓线本身有大量缺口（嘴巴371px、眼睛60px等），不是封闭曲线

**v2（步骤B→D）：内部填充 + 闭运算修补小缺口**
- 思路：v1基础上，对黑色轮廓线做闭运算（iterations=8）封住小缺口
- B版：闭运算封住了嘴巴/眼睛，内部填充主体完整 ✅，但文字丢了 ❌
  - 原因：文字在主体外部独立区域，内部洪水填不到
- C版：B + 下方文字(gray<250) → 文字回来了 ✅，但手臂空隙也被填满 ❌
  - 原因：gray<250太宽松，空隙中gray=248,249的像素也被保留
- D版：B + 彩色像素(color_diff>15) → 文字颜色保留 ✅，空隙大部分被填但仍优于C版
  - **D版定稿**：主体完整、文字彩色保留、空隙保留不完美但整体可接受

**v3（融合版 = D版 + 封闭内部区域检测）🔥**
- 关键发现：D版"少了眼睛"——闭运算把眼睛的开口封上了，水没流进去
- **封闭内部区域检测法**：
  1. 反转黑色轮廓线 → 白色区域
  2. 用ndimage.label做连通区域分析
  3. 与图像边缘相连的区域 = 外部背景
  4. **不与边缘相连的区域 = 被黑色轮廓线围住的封闭内部区域**（眼睛、嘴巴内部等）
  5. 实测：区域87(2626px)和88(2463px)就是眼睛，D版中不透明率0%
- 融合：D版掩码 OR 封闭内部区域掩码 → 眼睛补上 ✅
- **v3定稿**：主体完整 + 眼睛白色高光 + 文字彩色，06_周末万岁_备选1最终版

**⚠️ v3已知遗留问题（v4/v5优化方向）**：
1. 闭运算导致黑色轮廓线变粗糙（描边颗粒感）→ 需要更精细的缺口修补方式
2. 手臂间楔形空隙仍被部分填充 → 需要精确识别"应保留透明的空隙"
3. 底部封闭线y=1900需要手动指定 → 可尝试自动检测主体底部位置

**v4/v5研究思路**：
- v4方向：解决闭运算导致描边粗糙 → 只在缺口处做局部修补，不对整张图做全局闭运算
- v4方向：用"封闭内部区域检测"替代闭运算 → 找到眼睛等封闭区域后直接标记，不需要封住开口
- v5方向：解决空隙保留 → 结合isnet-anime掩码，找出"主体内但与外部连通"的区域做精确挖掘
- v5方向：用连通区域分析+区域大小+位置特征，自动区分"眼睛(应不透明)"和"空隙(应透明)"

---

**逐步方案对比与经验（06_周末万岁_备选1实测）**：

| 步骤 | 方案 | 结果 | 问题 |
|------|------|------|------|
| A | 内部填充（无闭运算） | 水从嘴巴/眼睛漏出 | 小缺口未封，洪水逃逸 |
| B | 内部填充（闭运算8） | 主体完整，文字丢失 | 文字在主体外部独立区域 |
| C | B + 下方文字(gray<250) | 文字保留，空隙被填 | gray<250太宽松 |
| D | B + 彩色像素(color_diff>15) | 空隙改善，文字有颜色 | 空隙仍被部分填充 |
| E | isnet-anime + 文字保护 | 有灰色色调偏移 | rembg会改变像素颜色 |
| F | anime掩码 + 闭运算外部填充 | 水漏入主体 | 外部洪水填充固有问题 |
| G | anime边缘空隙挖掘 | 身体也被挖掉 | isnet-anime主体大部分从边缘可达 |
| v3 | D + 封闭内部区域检测 | ✅ 主体完整+眼睛补上 | 描边粗糙+空隙仍被填 |

**核心经验**：
- ❌ **不要从外部洪水填充**：黑色线条之间有大量白色缝隙（嘴巴371px、眼睛等），水会从缝隙漏入主体内部
- ✅ **从内部出发洪水填充**：闭运算封住小缺口后，从主体内部填充，大空隙（手臂间楔形）自然保留
- ✅ 闭运算iterations=8可封住约16px的缺口（嘴巴、眼睛），但不会封住50px+的大空隙
- ✅ 彩色像素保护（color_diff>15）确保文字填充色不丢失
- ❌ gray<250阈值太宽松：空隙中接近白色的像素（gray=248,249）也被保留，导致空隙被填满
- ⚠️ isnet-anime会改变像素颜色（最大色差25），不适合直接取其输出像素，只适合用其掩码
- ⚠️ isnet-anime无法区分空隙和主体（空隙alpha反而更高242 vs 身体231）
- 🔥 **封闭内部区域检测法**：反转黑色轮廓线→连通区域分析→找不与边缘相连的区域=被轮廓线围住的封闭内部（眼睛等），这是v3的关键突破

**可视化调试经验**：
- 在大尺寸图片（2048x2048）上绘制线条，线宽需设置为5-10像素才能清晰可见
- 1-2像素的线在大图上几乎不可见
- 颜色选择：黑色线在白色背景上对比度最高，红色等彩色线对比度较低

**实战案例**：
- 图片：06_周末万岁_备选1.jpg
- 问题：双手举起，手臂和头部之间有楔形空隙需要保留透明；下方身体和文字相连，没有闭合线条
- 方案探索：A→B→C→D→E→F→G→v3逐步迭代
- 最终定稿：v3（内部填充+闭运算+彩色像素保护+封闭内部区域检测）

### Phase 4: 衍生素材生成

#### Step 4.1 生成全套衍生素材
```bash
python scripts/generate_derivatives.py \
    --character "傲娇小汤圆" \
    --ref-image "templates/characters/傲娇小汤圆/reference.png" \
    --transparent-dir "output/傲娇小汤圆/基础表情套包/不带文字版/透明背景" \
    --output "output/傲娇小汤圆/基础表情套包/带文字版" \
    --scene "基础场景"
```

**衍生素材规格（微信表情包规范）**：
| 素材类型 | 尺寸 | 格式 | 大小限制 | 用途 |
|---------|------|------|---------|------|
| 主图 | 240×240 | PNG | ≤500KB | 详情页展示，必须透明背景 |
| 缩略图 | 120×120 | PNG | ≤50KB | 套包缩略预览，必须透明背景 |
| 聊天面板图标 | 50×50 | PNG | ≤100KB | 微信聊天面板，必须透明背景 |
| 表情封面图 | 240×240 | PNG | ≤500KB | 套包封面，必须透明背景 |
| 详情页横幅 | 750×400 | JPG/PNG | ≤500KB | 详情页大图，禁止透明底 |

---

## 4. 参数配置说明

### 配置文件: `config.yaml`
```yaml
# 通用配置
output_base: "./output"
template_base: "./templates"

# 角色配置
characters:
  - name: "傲娇小汤圆"
    description: "圆滚滚、软糯糯的傲娇小汤圆"
    base_prompt: "白色圆润的可爱汤圆卡通形象，圆滚滚的身体，大眼睛"

# 场景词库配置
scenes:
  基础场景:
    expression_count: 24
    words:
      - "平静"
      - "开心"
      - "生气"
      - "难过"
      - "无语"
      - "崩溃"
      - "感动"
      - "傲娇脸"
      - "哼"
      - "不理你"
      - "才没有"
      - "嘴硬"
      - "真香"
      - "OK"
      - "嗯嗯"
      - "好的"
      - "收到"
      - "没问题"
      - "谢谢"
      - "困了"
      - "饿了"
      - "无语子"
      - "哈哈"
      - "加油"

  过年场景:
    expression_count: 20
    prefix: "过年"
    words:
      - "恭喜发财"
      - "红包拿来"
      - "年年有余"
      - "心想事成"
      - "福气满满"
      - "万事如意"
      - "大吉大利"
      - "身体健康"
      - "阖家欢乐"
      - "新年快乐"

  打工场景:
    expression_count: 20
    prefix: "打工"
    words:
      - "上班"
      - "加班"
      - "摸鱼"
      - "下班"
      - "周一综合症"
      - "周末万岁"
      - "不想上班"
      - "工资发了"
      - "甲方爸爸"
      - "方案改了"

  旅游场景:
    expression_count: 20
    prefix: "旅游"
    words:
      - "出发"
      - "到达"
      - "拍照"
      - "美食"
      - "累并快乐"
      - "想回家"
      - "风景好美"
      - "打卡"
      - "想你了"
      - "回家了"

# 图片生成配置
image_generation:
  style: "可爱卡通插画"
  background: "纯白底"
  quality: "高清"
  seed: null  # 随机种子

# 透明化处理配置
transparency:
  method: "remove.bg"  # 或 "rembg"
  remove_bg_api_key: "${REMOVE_BG_API_KEY}"
```

---

## 5. 示例调用方式

### 完整流程示例

```bash
# 1. 设置环境变量
export REMOVE_BG_API_KEY="your_api_key_here"

# 2. 模式 A: 创建新角色 + 基础套包
python scripts/generate_character.py \
    --character "傲娇小汤圆" \
    --ref-image "用户上传/头像.jpg" \
    --output "templates/characters/傲娇小汤圆/reference.png"

python scripts/generate_expressions.py \
    --character "傲娇小汤圆" \
    --ref-image "templates/characters/傲娇小汤圆/reference.png" \
    --scene "基础场景" \
    --output "output/傲娇小汤圆/基础表情套包"

python scripts/process_transparency.py \
    --input-dir "output/傲娇小汤圆/基础表情套包/原图" \
    --output-dir "output/傲娇小汤圆/基础表情套包/透明背景"

python scripts/generate_derivatives.py \
    --character "傲娇小汤圆" \
    --ref-image "templates/characters/傲娇小汤圆/reference.png" \
    --transparent-dir "output/傲娇小汤圆/基础表情套包/透明背景" \
    --output "output/傲娇小汤圆/基础表情套包/衍生素材"

# 3. 模式 B: 基于已有角色创建衍生套包
python scripts/generate_expressions.py \
    --character "傲娇小汤圆" \
    --ref-image "templates/characters/傲娇小汤圆/reference.png" \
    --scene "过年场景" \
    --output "output/傲娇小汤圆/拜年表情套包"
```

### 批量处理示例

```bash
# 批量生成多个场景
for scene in 基础场景 过年场景 打工场景 旅游场景; do
    python scripts/generate_expressions.py \
        --character "傲娇小汤圆" \
        --ref-image "templates/characters/傲娇小汤圆/reference.png" \
        --scene "$scene" \
        --output "output/傲娇小汤圆/${scene}套包"
done
```

---

## 6. 目录结构

```
skill-sticker-pack/
├── SKILL.md                      # 本文档
├── config.yaml                   # 配置文件
├── scripts/
│   ├── generate_character.py     # 角色标准形象生成
│   ├── generate_expressions.py   # 表情批量生成
│   ├── process_transparency.py   # 透明背景处理
│   └── generate_derivatives.py    # 衍生素材生成
├── templates/
│   ├── characters/               # 角色模板库
│   │   └── 傲娇小汤圆/
│   │       ├── character.md      # 角色设定文档
│   │       ├── reference.png     # 标准形象参考图
│   │       └── expression_words.json
│   └── scenes/                   # 场景词库
│       ├── 基础场景.json
│       ├── 过年场景.json
│       ├── 打工场景.json
│       └── 旅游场景.json
└── output_template/              # 输出目录结构模板
    └── {角色名}/
        └── {场景名}套包/
            ├── 不带文字版/
            │   ├── 原图/
            │   ├── 透明背景/
            │   └── 衍生素材/
            └── 带文字版/
                ├── 原图/
                ├── 透明背景/
                └── 衍生素材/
```

---

## 7. 注意事项

### 提示词优化建议
1. **风格一致性**：保持基础描述不变，只改变表情/动作相关词汇
2. **白底优先**：生成时使用白底，便于后续透明化处理
3. **控制数量**：单次生成建议不超过 20 张，避免质量下降

### API 配额管理
- remove.bg 免费额度：每月 50 张
- 批量处理时注意控制调用频率

### 质量检查清单
- [ ] 角色风格一致性
- [ ] 表情辨识度
- [ ] 透明背景干净度
- [ ] 衍生素材尺寸合规
- [ ] 文字排版美观度

---

## 8. 错误处理

| 错误类型 | 处理方式 |
|---------|---------|
| API 调用失败 | 自动重试 3 次，间隔 5 秒 |
| 图片生成质量差 | 调整提示词，更换 seed |
| 透明化不干净 | 手动微调或使用 PS 辅助 |
| 批量中断 | 支持断点续传，从已完成处继续 |


---

## 9. 实践经验总结（傲娇小汤圆项目）

### 9.1 模型管理规范

**模型目录结构**：
```
模型/rembg/
├── u2net.onnx              # 通用模型，效果好（168MB）
├── u2netp.onnx             # 轻量版，速度快
├── isnet-general-use.onnx  # 复杂背景效果更好（179MB）
└── silueta.onnx            # 人像专用
```

**环境变量配置**：
```bash
export U2NET_HOME=$(pwd)/模型/rembg
```

**模型下载地址**：
- u2net: https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2net.onnx
- isnet-general-use: https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-general-use.onnx

### 9.2 测试目录管理规范

**新项目测试图片统一放入测试目录**：
```
测试目录/
├── {项目名}/
│   ├── 测试图片1.jpg
│   └── 测试图片2.jpg
```

**原因**：历史对话中的图片引用无法修改，移动文件后会导致对话中图片无法显示。

### 9.3 图片发送规范

**显示名称禁用方括号**：
- ❌ 错误：`10_不理你对比图` → 与 Markdown 链接语法冲突
- ✅ 正确：`10-不理你-对比图` → 使用短横线替代

### 9.4 高膨胀版本处理

**需求**：某些表情需要"高膨胀"版本（如"好的"表情）

**处理方式**：
1. 原图单独处理，膨胀次数增加到 20-25 次
2. 使用彩色特效保护逻辑，确保特效完整显示
3. 文件命名：`{序号}_{表情词}_高膨胀`

### 9.5 透明背景处理完整流程

**带文字版**：
```
原图 → rembg去背景 → 文字区域检测（全图） → 主体膨胀(8次) → 文字膨胀(8次) → 合并 → 高斯平滑 → 输出
```

**不带文字版（无特效）**：
```
原图 → rembg去背景 → 主体膨胀(5次) → 高斯平滑 → 输出
```

**不带文字版（有特效）**：
```
原图 → rembg去背景 → 彩色区域检测 → 主体膨胀(12次) → 彩色膨胀(8次) → 合并 → 高斯平滑 → 输出
```

**⭐ 黑底原图（推荐流程，2026-04-27 最终版）**：
```
黑底原图 → 低重绘图生图转绿幕(strength=0.5) → 保存绿幕过渡图 → u2net抠图 → 黑色线条保护 → 高斯平滑 → 输出透明背景
```

**关键要点**：
1. **strength=0.5**：低重绘强度保持表情不变（越高变化越大）
2. 用 **u2net 模型**处理绿幕图，避免蓝色光晕
3. **黑色线条保护**：检测深色区域合并到主体，防止呆毛/眼睛/轮廓被透明化
4. 保存绿幕过渡图方便后续重新处理

**黑色线条保护代码**：
```python
# 检测黑色呆毛/线条区域
r, g, b = orig_arr[:,:,0], orig_arr[:,:,1], orig_arr[:,:,2]
dark_areas = (r < 80) & (g < 80) & (b < 80) & ((r + g + b) > 15)

# 合并主体和黑色区域
combined = (alpha > 10) | dark_areas
```

### 9.6 常见问题解决

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 文字缺失 | 文字在图片上方/侧边 | 使用全图文字检测，不限制位置 |
| 彩色特效缺失 | 特效被当作背景透明化 | 使用彩色特效保护逻辑 |
| 身体部分缺失 | 主体膨胀不够 | 增加膨胀次数到 10-12 次 |
| 边缘毛刺 | alpha 通道处理不当 | 高斯平滑 sigma=2.0 |
| 高光被透明化 | rembg 误识别 | 使用 isnet-general-use 模型 |
| **蓝色光晕** | 自定义绿幕检测算法残留 | **用 u2net 模型处理绿幕图** |
| 绿色噪点 | 绿幕检测阈值过低 | 用 u2net 模型处理绿幕图 |
| 主体透明化 | isnet-general-use 对白色主体效果差 | 使用 u2net 或检查膨胀参数 |
| 模型反复下载 | U2NET_HOME 未设置 | 设置环境变量指向本地模型目录 |
| **黑底图表情变化** | 图生图重绘强度过高 | **strength=0.5 低重绘保表情** |
| **黑色线条/呆毛缺失** | 黑色区域被误判为背景 | **检测深色区域合并到主体** |

### 9.7 输出目录结构（完整版）

```
表情包/{角色名}/{套包名}/
├── 带文字版/
│   ├── 原图/              25张 JPG
│   ├── 透明背景/          25张 PNG (500×500)
│   ├── 主图/              25张 PNG (240×240)
│   ├── 缩略图/            25张 PNG (120×120)
│   ├── 聊天面板图标/      25张 PNG (50×50)
│   ├── 表情封面图/        1张 PNG (240×240)
│   └── 详情页横幅/        1张 JPG (750×400)
└── 不带文字版/
    ├── 原图/              25张 JPG
    ├── 绿幕过渡图/        25张 JPG（黑底原图转绿幕后的中间产物，保留以备重新处理）
    ├── 透明背景/          26张 PNG (500×500) 含高膨胀版
    ├── 主图/              26张 PNG (240×240)
    ├── 缩略图/            26张 PNG (120×120)
    ├── 聊天面板图标/      26张 PNG (50×50)
    ├── 表情封面图/        1张 PNG (240×240)
    └── 详情页横幅/        1张 JPG (750×400)
```

**注意**：
- 不带文字版通常比带文字版多一张高膨胀版本
- **绿幕过渡图**用于保存黑底转绿幕的中间产物，方便后续重新处理或调整，避免重复调用图生图API


---

## 10. 表情包生成最佳实践（2026-04-26 更新）

### 10.1 分阶段生成流程（重要！）

**错误做法**：一次性生成所有素材（原图+透明背景+衍生素材），用户发现问题后需要大量返工

**正确做法**：分阶段生成，每步确认后再继续

```
阶段1：生成原图 + 透明背景
    ↓
阶段2：发送所有对比图给用户检验（原图 vs 透明背景）
    ↓
阶段3：用户确认无误后，再生成衍生素材（主图/缩略图/图标/封面/横幅）
    ↓
阶段4：打包交付
```

**优势**：
- 用户可以及时发现问题，避免返工浪费
- 节省计算资源和时间
- 提高交付质量和用户满意度

### 10.2 生成备用图供选择

**改进点**：每个表情生成多个版本（主图+备选1-4），让用户选择最满意的

**命名规范**：
- 主图：`{序号}_{表情词}.png`
- 备选：`{序号}_{表情词}_备选1.png`、`{序号}_{表情词}_备选2.png`

**优势**：
- 用户可以选择最满意的效果
- 减少重新生成的次数
- 提高创作效率

### 10.3 对比图发送规范

**要求**：
1. **必须包含所有图片的对比图**，不要遗漏
2. **格式**：左侧原图，右侧透明背景图，横向拼接
3. **命名**：`{序号}_{表情词}_对比.png`
4. **编号**：对比图上标注序号，方便用户定位问题

**示例**：
```
发送：[01] 01_上班_对比.png
      [02] 02_加班_对比.png
      ...
      [25] 25_搬砖_对比.png
```

### 10.4 用户反馈记录

**收到用户反馈**：
- ✅ 生成备用图供选择是好的进步
- ✅ 分阶段生成流程更高效
- ⚠️ 先不要着急生成衍生素材，等用户确认原图和透明背景没问题后再生成

### 10.5 质量检查清单

**阶段1检查（原图+透明背景）**：
- [ ] 角色形象统一性
- [ ] 表情辨识度
- [ ] 文字完整显示（带文字版）
- [ ] 特效完整显示（有特效版）
- [ ] 身体部分完整无缺失
- [ ] 背景透明干净

**阶段2检查（衍生素材）**：
- [ ] 尺寸符合微信规范
- [ ] 文件大小符合限制
- [ ] 封面图美观
- [ ] 横幅图无透明底


---

## 11. 问题图片自检修复流程（2026-04-26 更新）

### 11.1 场景说明

当用户指出某些序号的图片有问题需要调整时，执行以下自检修复流程。

### 11.2 自检修复流程

```
用户反馈：第X、Y、Z张有问题
    ↓
Step 1: 生成问题图片的详细对比图（原图 vs 当前结果）
    ↓
Step 2: 使用 read_image 工具自检对比图，描述具体问题
    ↓
Step 3: 分析问题原因（文字缺失/身体缺失/边缘噪点/透明区域等）
    ↓
Step 4: 选择合适的修复方案：
    - 文字缺失 → 调整文字检测阈值，增加膨胀次数
    - 身体缺失 → 增加主体膨胀次数，或使用 isnet 模型
    - 边缘噪点 → 形态学开运算 + 高斯平滑
    - 透明区域 → 降低透明阈值，补充缺失像素
    ↓
Step 5: 修复后再次自检，确认问题已解决
    ↓
Step 6: 生成修复后的对比图发送给用户确认
```

### 11.3 自检要点

**必须自检的项目**：
- [ ] 左右尺寸是否一致（对比图中原图和结果图）
- [ ] 文字是否完整（对比原图文字）
- [ ] 身体是否完整（无缺失部分）
- [ ] 边缘是否干净（无多余白色噪点）
- [ ] 背景是否透明（无不该透明的区域）
- [ ] 主体范围是否合理（不能太大或太小）

### 11.4 常见问题诊断

| 现象 | 可能原因 | 诊断方法 | 解决方案 |
|------|---------|---------|---------|
| 文字缺失 | 颜色检测阈值过高 | 检查文字区域的 colorfulness 值 | 降低阈值如 >10 |
| 身体缺失 | 膨胀次数不足 | 对比原图看缺失部分颜色 | 增加膨胀次数或换模型 |
| 边缘白色噪点 | 透明阈值过低 | 检查边缘 alpha 值分布 | 提高阈值 + 形态学开运算 |
| 背部透明 | 主体与背景颜色接近 | 检查背部与背景的颜色差异 | 使用 isnet 模型 |
| 主体过大 | 膨胀过度 | 计算主体占比是否合理 | 减少膨胀次数 |
| 左右尺寸不一致 | resize 处理错误 | 检查输入输出尺寸 | 统一到同一尺寸处理 |

### 11.5 自检报告格式

每次修复前，输出自检报告：

```
## 自检报告

**问题图片**：第X张 - 10_不理你

**当前问题**：
- [ ] 文字缺失（具体：缺失"你"字）
- [ ] 身体缺失（具体：右手臂透明）
- [ ] 边缘噪点（具体：主图边缘有白色残留）
- [ ] 其他：____________

**问题原因分析**：
- 文字检测阈值过高，"你"字颜色较浅未被识别
- 右手臂颜色接近背景白，被误判为透明

**修复方案**：
1. 降低文字检测阈值至 10
2. 使用 isnet 模型重新处理
3. 形态学开运算去除边缘噪点

**修复结果**：
- 修复后主体占比：XX%
- 文字完整：是/否
- 身体完整：是/否
- 边缘干净：是/否
```

### 11.6 注意事项

1. **不要急于发送结果**：修复后必须自检通过再发送
2. **多次迭代优化**：一次修复可能不完全，需要多次调整
3. **记录成功方案**：将成功的修复方案记录到技能文档
4. **对比原图**：始终以原图为基准，不要凭空想象


---

## 12. 自动掩码生成方案（2026-04-26 更新）

### 12.1 核心理念

**不需要用户手动涂抹掩码**，系统可以自动生成掩码来处理复杂情况。

### 12.2 自动掩码生成方法

| 方法 | 原理 | 适用场景 | 效果 |
|------|------|---------|------|
| AI生图抠图 | 使用AI生图工具自动抠图 | 复杂背景、白色主体 | ⭐⭐⭐⭐⭐ |
| 颜色检测 | 检测非白色/非背景色区域 | 简单背景 | ⭐⭐⭐ |
| 边缘检测 | Canny/Sobel边缘检测 | 清晰边缘 | ⭐⭐ |
| 多模型融合 | 多个模型结果取交集 | 高精度需求 | ⭐⭐⭐⭐ |

### 12.3 推荐方案：AI生图抠图 + 后处理

```python
# 步骤1：使用AI生图工具自动抠图
prompt = "对给定图片进行抠图"
# 得到透明背景图 trans.png

# 步骤2：将AI抠图结果作为掩码基础
trans = Image.open('trans.png')
ai_mask = trans[:,:,3] > 10  # AI识别的主体

# 步骤3：检测文字区域
colorfulness = np.std([r, g, b], axis=0)
text_mask = colorfulness > 15

# 步骤4：合并掩码
final_mask = ai_mask | text_mask
```

### 12.4 模型选择指南

**表情包/卡通形象**：
- 首选：**isnet-anime**（动漫专用，mIoU 0.94）
- 备选：isnet-general-use、birefnet-massive

**人像**：
- 首选：**birefnet-portrait**（mIoU 0.94）
- 备选：u2net_human_seg

**通用物体**：
- 首选：**birefnet-massive**（综合最佳）
- 备选：isnet-general-use

### 12.5 实际操作流程

当遇到难以处理的图片时：

```
1. 分析问题：身体缺失/边缘噪点/文字缺失
    ↓
2. 选择合适的模型：
   - 动漫/卡通 → isnet-anime
   - 人像 → birefnet-portrait
   - 复杂场景 → birefnet-massive
    ↓
3. 使用AI生图抠图生成初始掩码
    ↓
4. 叠加文字检测等后处理
    ↓
5. 自检验证效果
```

### 12.6 模型下载地址

```
# isnet-anime（推荐用于表情包）
https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-anime.onnx

# isnet-general-use
https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-general-use.onnx

# birefnet-massive（综合最佳）
https://github.com/danielgatis/rembg/releases/download/v0.0.0/birefnet-massive.onnx

# birefnet-portrait（人像专用）
https://github.com/danielgatis/rembg/releases/download/v0.0.0/birefnet-portrait.onnx
```

---

## 13. 实践经验与失败教训（2026-04-26 更新）

### 13.1 自动掩码方案实验结果

**实验方案**：使用AI生图工具"对给定图片进行抠图"生成初始掩码，再叠加文字检测

**实验结果**：❌ 效果不佳
- AI生图抠图对白色主体效果不稳定
- 掩码边缘不够精确
- 不如rembg模型稳定

**结论**：自动掩码方案目前不成熟，仍需依赖rembg模型

### 13.2 主体文字分离处理方案实验结果

**实验方案**：
1. 单独用rembg处理主体（膨胀12次）
2. 单独检测文字区域（灰度阈值）
3. 合并两个mask

**实验结果**：❌ 效果一塌糊涂
- 分离处理后合并效果远不如整体处理
- 边缘融合问题难以解决
- 文字和主体衔接处出现断层

**结论**：分离处理方案不可行，应使用完整模型一次性处理

### 13.3 待验证方案：isnet-anime模型

**推荐方案**：使用isnet-anime模型处理表情包
- 动漫/卡通专用模型，mIoU 0.94
- 远超u2net的0.78
- 特别适合白色主体+文字的场景

**模型状态**：
- isnet-anime.onnx：下载中（179MB）
- isnet-general-use.onnx：40MB/179MB（22%）

**下载加速**：
```bash
# GitHub原源（慢）
wget -O isnet-anime.onnx "https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-anime.onnx"

# 国内镜像（快）
wget -O isnet-anime.onnx "https://hf-mirror.com/danielgatis/rembg/resolve/main/isnet-anime.onnx"
```

### 13.4 模型下载最佳实践

**断点续传**：
```bash
wget -c --timeout=120 -t 0 -O model.onnx "URL"
```
- `-c`：断点续传
- `--timeout=120`：超时120秒
- `-t 0`：无限重试

**国内镜像替换**：
- GitHub原源：`https://github.com/...`
- 国内镜像：`https://hf-mirror.com/...` 或 `https://ghproxy.com/...`

**环境变量**：
```bash
export U2NET_HOME=$(pwd)/模型/rembg
```

### 13.5 经验总结

| 方案 | 效果 | 适用场景 | 备注 |
|------|------|---------|------|
| u2net + 膨胀15次 + 文字保护 | ⭐⭐⭐ | 常规表情包 | 部分图片身体缺失 |
| isnet-anime（待验证） | ⭐⭐⭐⭐⭐ | 动漫/卡通表情包 | 预期效果最佳 |
| 自动掩码方案 | ⭐⭐ | 复杂场景 | 效果不稳定 |
| 主体文字分离处理 | ⭐ | 不推荐 | 效果很差 |

### 13.6 下一步计划

1. 等待isnet-anime模型下载完成
2. 用isnet-anime重新处理第10张
3. 验证效果后更新最佳实践
4. 如果效果满意，打包基础表情套包


#### Step 3.1.3 黑色背景处理（不推荐）

**背景**：打工人版部分原图是黑色背景，需要特殊处理

**尝试过的方案**：
| 方案 | 代码 | 结果 |
|------|------|------|
| 亮度阈值 | `gray < 220` | 黑色线条被透明 ❌ |
| 纯黑检测 | `brightness < 30 & rgb_range < 10` | 眼睛被透明 ❌ |
| 白色膨胀 | `dilation(brightness>150, 15次)` | 眼睛被透明，有毛刺 ❌ |

**结论**：
- 黑色背景和黑色线条颜色相近，难以区分
- 眼睛等深色区域会被误判
- **不推荐黑底原图**，生成时应使用绿色背景

**建议**：
对于已有的黑底原图，建议重新生成绿幕版本替代
---

## 透明背景处理方案汇总（2026-04-29 更新）

### 白底原图处理方案

**适用场景**：白色背景 + 白色主体 + 黑色轮廓线 + 彩色文字的卡通表情包

#### ⭐ 方案一：混合方案v3（推荐，已验证成功）

**核心思路**：单一方案都有缺陷，组合方案取长补短

**方案A（绿色背景+rembg）**：
- 把接近白色的背景（RGB>0.95）转成绿色
- 用rembg生成主体掩码
- **优点**：主体完整
- **缺点**：文字可能有问题

**方案B（洪水填充+黑色线条边界）**：
- 检测黑色轮廓线（RGB<0.2），做闭运算填补缺口
- 从四角洪水填充，遇到黑色线条停止
- **优点**：文字完美保留
- **缺点**：主体可能缺失

**最终掩码 = 方案A ∪ 方案B（取并集）**

**已验证成功案例**：
- 打工人版 01_上班.jpg：完美定稿
- 打工人版 10_方案改了_3.jpg：效果很好

#### ⭐ 方案二：坐标掩码涂抹法（特殊情况补充）

**适用场景**：自动方案处理后仍有特定区域缺失

**操作流程**：
1. 生成坐标参考图（网格线+坐标标注）
2. 用户指出需要涂抹/清除的区域坐标
3. 根据坐标生成掩码预览图
4. 用户确认后生成最终透明图

**关键参数**：
| 参数 | 说明 | 示例 |
|------|------|------|
| x_start, x_end | x轴范围 | 570~1650 |
| y_start, y_end | y轴范围 | 1400~1560 |
| angle | 梯形斜边角度（与垂直方向夹角） | 22度 |
| y_clear_start, y_clear_end | 需要清除的区域 | 1560~1600 |

**已验证成功案例**：
- 打工人版 26_收到.jpg：22度梯形涂抹(x=570~1650, y=1400~1560) + y=1560~1600清除白色背景

---

### 黑底原图处理方案

**适用场景**：黑色背景的原图，黑色线条和背景难以区分

#### ⭐ 推荐方案：图生图转绿幕 + u2net抠图

**核心经验**：使用**低重绘强度（strength=0.5）**确保表情不变

**关键参数**：
| 参数 | 推荐值 | 说明 |
|------|--------|------|
| 图生图强度 | **0.5** | 关键参数，太高会改变表情 |
| 抠图模型 | u2net | 处理绿幕效果最好，避免蓝色光晕 |
| 提示词 | "green background, white character" | 明确绿色背景 |

**已验证成功案例**：
- 打工人版 05_周一综合症（黑底图）：
  - ✅ 表情一致：委屈焦虑神态完全保留
  - ✅ 腿部完整：姿势一致
  - ✅ 无蓝色光晕

---

### 处理流程规范（用户要求）

1. 原图定稿后，随机5张自检测试
2. 自检没问题后发用户确认
3. 用户确认后再生成剩余透明图
4. 全部对比图发给用户审核定稿
5. 定稿后才生成衍生图

---

### 方案选择决策树

```
原图类型判断
├── 白底原图 → 混合方案v3
│   ├── 效果OK → 定稿
│   └── 有区域缺失 → 坐标掩码涂抹法
│
└── 黑底原图 → 图生图转绿幕(strength=0.5) + u2net
    ├── 效果OK → 定稿
    └── 表情变了 → 降低strength或接受适度变化
```

---

### 轮廓线围栏法详解（2026-04-30验证，⭐推荐方案）

#### 思路演进过程
这是21_老板_备选2的处理过程中，经过多次迭代最终得出的最优方案：

1. **混合方案v3** → 身体下半部半透明（白色身体+白色背景rembg分不清）
2. **内部洪水填充法** → 身体部分区域灌不到（需要种子点，且身体内部黑线把区域分割了）
3. **外部洪水灌水法** → 半透明率0%，但水从底部开口灌入身体内部（主体两侧黑线没延伸到边缘）
4. **底部封线+外部灌水** → 封线太靠底部，水从两侧绕过
5. **口字形围栏（方形）** → 主体周围多出不必要的白色区域
6. **⭐轮廓线围栏法** → 用黑线本身当围栏，只补底部开口，贴合主体形状，完美！

核心洞察（用户提出）：黑色轮廓线本身就是天然围栏，不需要另建方形围栏，只需要补上底部开口。轮廓线贴合主体形状，不会有方形围栏多余的白色。

#### 详细流程
1. 检测原图黑色轮廓线（亮度<50）
2. 闭运算封住轮廓线断裂（iterations=18）
3. 找底部开口位置（主体两侧黑线到底部边缘之间的间隙）
4. 在底部边缘画横向封闭线（3-5像素宽），连接左右轮廓线/图片边缘
5. 围栏掩码 = 闭运算后黑线 + 底部封闭线
6. 从四周边缘BFS洪水填充，遇到围栏掩码停止
7. BFS到达=外部背景→透明，BFS到不了=主体→全部不透明
8. **不需要rembg**（围栏内的就是主体，围栏外的就是背景）
9. 保护黑色轮廓线
10. 缩放到500x500

#### 关键要点
- 围栏内全部不透明，不需要rembg确认
- rembg只会在围栏逻辑外产生干扰（把白色主体边缘标半透明），所以不用
- 底部封闭线要确保完全封死，不能有缝隙
- 闭运算iterations=18封住黑线细小断裂，比iterations=3更强
- 如果主体两侧轮廓线没延伸到图片边缘，封闭线也要延伸到边缘封死

#### 成功案例
- 21_老板_备选2：半透明率0.00%，主体完整，文字清晰，无多余白色
- 底部封闭线5像素宽，闭运算iterations=18

#### vs 其他方案对比
| 方案 | 半透明率 | 多余白色 | 需要rembg | 适用 |
|------|---------|---------|----------|------|
| 混合方案v3 | 高(白色区域) | 无 | 是 | 通用 |
| 口字形围栏 | 0% | 有(方形区域) | 否 | 底部开口 |
| 轮廓线围栏 | 0% | 无 | 否 | 底部开口+黑线轮廓 |

### 颜色灌水法详解（2026-04-30验证，⭐方案8）

#### 思路来源
02_加班_4的处理过程中，轮廓线围栏法+加强闭运算仍有残留问题（主体轮廓线断裂导致水渗入）。用户提出：**按颜色划分**——水只流过白色区域，非白色区域天然挡水，根本不用操心断裂。

#### 核心逻辑（v8更新：混合封闭+颜色灌水）
1. **自动检测轮廓断点**：逐行扫描暗色像素(RGB<80)，找轮廓线消失的位置和宽度
2. **大缺口(>20px)→自动画封闭线**：根据断点端点坐标，用PIL画线封住（不用OpenCV，避免BGR/RGB混淆）
3. **小缺口(3-20px)→形态学闭运算**：椭圆核7x7修补小断裂
4. **组合围栏**：原始暗色轮廓 + 封闭线 + 闭运算修补 = 完整围栏
5. 从图片四边BFS洪水填充，**颜色+围栏双重判断**：
   - 像素RGB三通道都>240 = 白色 且 不在围栏上 → 水可通过
   - 否则 → 水停止
6. 水到达的像素 → alpha=0（透明），水未到达 → alpha=255（不透明）
7. **铁律：只修改alpha通道**，用np.dstack([原图RGB, alpha])重拼

#### 关键优势
- **小断裂不需要修补**：黑色轮廓线天然挡水
- **大缺口自动封闭**：自动检测断点+计算封闭线坐标，无需用户手动标注
- **非白色元素自动保护**：灰色圈圈、彩色桌子、文字等全部保留
- **无需rembg**：纯PIL/numpy/cv2实现
- **不会泛蓝**：只改alpha不改RGB

#### 适用场景
- 白色背景 + 非白色轮廓线的卡通图
- 主体包含多种颜色（灰色圈圈、彩色文字等），都能自动保护
- 轮廓线有断裂的图片（小断裂不需要修补，大断裂自动画线封住）

#### 局限性
- 如果主体有纯白色区域与背景相连（且没有非白色轮廓线分隔），该区域会被透明化
- 阈值240可能对浅色内容过于严格（如浅灰gray=241会被当成白色让水通过）
- 主体内部悬浮的非白色小圆圈需要先封闭开口，否则水灌入圈圈内部
- 轮廓线有大缺口(>20px)时必须画封闭线，纯闭运算修不了

#### ⚠️ 严禁让用户手动标注坐标
**AI必须自动检测轮廓断点并计算封闭线坐标，不能甩给用户手动标注！**
- AI有像素级数据，比人眼更精确
- 逐行扫描暗色像素找断点，自动计算封闭线起终点
- 只有自动计算确实不准时，才生成坐标图请用户确认

#### ⚠️ RGB/BGR混淆是致命bug（v7踩坑）
- OpenCV用BGR，PIL/numpy用RGB，必须统一
- **推荐全部用PIL操作**，避免OpenCV画线导致BGR/RGB混淆
- v7就是BGR/RGB搞混导致封闭线颜色不对、数据全假（报告100%实际被透明化）
- **每次处理完必须验证RGB偏移=0**，偏移>0说明有bug

#### ⚠️ 缩放半透明bug（2026-05-01踩坑）
- 2048下alpha是0/255二值的，但LANCZOS缩放到500x500时边缘被插值混合，出现0-255之间的半透明值
- 导致文字等边缘细节被切、视觉上"甲字缺了一角"
- **修复**：缩放前后都做alpha二值化
  1. 2048下灌水法完成后：alpha[alpha>=128]=255, alpha[alpha<128]=0
  2. 缩放到500x500
  3. **缩放后再次二值化**：alpha[alpha>=128]=255, alpha[alpha<128]=0
  4. 验证500x500版本alpha只有0和255两个值，0%半透明
- **铁律：所有透明图缩放后必须验证alpha只有0和255！**

#### ⚠️ 封闭线只需封住断点，不需要封整个圈（v11定稿总结）
- 颜色灌水法靠非白色挡水，螺旋圈圈的非白色像素天然挡水
- 小缺口(3-13px)两侧都有非白色像素，水过不去，不需要封
- **只需要封住内部白色↔外部白色连通的断点处**，用线段把两个断点连起来
- 类比：封闭线=在河流上建坝，不需要把整条河围起来

#### 成功案例
- 02_加班_4 v11：0%半透明率，封闭线线1(1590,278)→(1660,330)+线2(1545,335)→(1580,380)，只封断点
- 02_加班_4 v7：❌数据不可信（RGB偏移111，BGR/RGB混淆）

### 外部灌水法+L形封闭线详解（2026-05-01验证，⭐方案8变体）

#### 适用场景
- 主体底部和侧面都有开口，水从底部和侧面都能灌入
- 单条封闭线无法封住所有方向的入口

#### 核心思路
- 竖线封侧边开口 + 底部水平线封底部开口 = L形封闭线
- L形两臂都要朝向主体方向，把水挡在外面
- 配合外部灌水法：从四边BFS洪水填充，遇非白色像素停

#### 关键要点
- L形方向：竖线从主体边缘向下延伸到图片底部，底部线从竖线端点水平延伸到图片边缘
- 竖线和底部线必须**端点相连**，不能有缝隙
- 坐标一律用原图尺寸（2048x2048），范围0-2047

#### 成功案例
- 09_甲方爸爸_备选2 v7修正版：L形封闭线 竖线(300,1946)→(300,2047)+底部线(300,2047)→(2047,2047)，29.2%透明，主体完整
- 迭代过程：v1~v6各种bug（封闭线方向反、太短、缩放坐标偏差、L形画反），v7修正后定稿

#### 踩坑记录
1. 封闭线方向搞反：底部线画向了主体反方向，水直接绕过
2. 缩放坐标偏差：500x500坐标缩放回2048有偏差，封闭线位置偏移
3. L形画反：竖线+底部线组成的L形开口朝外而非朝向主体
4. sub-agent灌水逻辑bug：L形方向搞反导致白色身体被透明化

#### 思路演进
1. **外部洪水灌水法** → 轮廓线断裂，水渗入主体
2. **加强闭运算** → 仍有断裂未封住，水仍渗入
3. **⭐颜色灌水法** → 按颜色判断水流，非白色天然挡水
4. **用户手动标坐标v7** → BGR/RGB搞混，数据全假
5. **⭐v8自动检测断点+混合封闭** → 大缺口画线+小缺口闭运算+颜色灌水，终极方案

---

#### 更新方案决策树
```
原图类型判断
├── 白底原图 → 混合方案v3
│   ├── 效果OK → 定稿
│   ├── 白色主体半透明 → 轮廓线围栏法（⭐优先尝试）
│   │   ├── 底部有开口 → 补底部封闭线+外部灌水
│   │   └── 轮廓不完整 → 口字形围栏 或 其他方案
│   ├── 轮廓线断裂/多种非白色元素 → 颜色灌水法（⭐方案8）
│   │   └── 主体内小圆圈先封闭，防止水灌入圈圈内部
│   ├── 细小缺失(头顶毛等) → 内部洪水填充法
│   └── 大面积缺失 → 坐标掩码涂抹法
│
└── 黑底原图 → 图生图转绿幕(strength=0.5) + u2net
    ├── 效果OK → 定稿
    └── 表情变了 → 降低strength或接受适度变化
```

## ⚠️ 全局铁律汇总（2026-05-01整理，违反即为重大失误）

### 1. 严禁私自修改方案
- 用户说了怎么做就怎么做，不能换成"更好"的方案
- v8椭圆mask、v9矩形封闭：两次犯同一错误，用户明确拒绝仍自作主张
- "自主找坐标"=AI自动算精确坐标，≠AI自主改方案
- 遇到困难先尝试解决，解决不了汇报，由用户决定是否换方案
- AI可以提建议，但绝不擅自执行

### 2. 只改alpha不改RGB（泛蓝铁律）
- 生成透明图时只修改alpha通道，绝不能修改原图RGB
- 正确做法：np.dstack([原图RGB, alpha])
- 泛蓝症状：R降低B升高，说明RGB被篡改
- 每次处理完必须验证RGB偏移=0

### 3. RGB/BGR混淆是致命bug
- OpenCV用BGR，PIL/numpy用RGB，必须统一
- **推荐全部用PIL操作**，避免OpenCV画线
- v7就是BGR/RGB搞混导致封闭线颜色对不上、数据全假

### 4. 严禁让用户手动标注坐标
- AI有像素级数据，必须自动检测轮廓断点并计算封闭线坐标
- 只有自动计算确实不准时，才生成坐标图请用户确认

### 5. 缩放半透明bug + RGB边缘污染bug
- 2048→500缩放时LANCZOS插值会混合alpha边缘，产生半透明值
- **RGB和alpha一起缩放还会导致边缘RGB被插值污染**（不透明区域RGB最大偏移可达89）
- **正确做法：RGB和alpha分别缩放，再合并**
  ```python
  orig_rgb_500 = np.array(orig_rgb_pil.resize((500,500), LANCZOS))
  alpha_500 = np.array(Image.fromarray(fused_alpha).resize((500,500), LANCZOS))
  alpha_500 = (alpha_500 >= 128).astype(np.uint8) * 255
  result = np.dstack([orig_rgb_500, alpha_500])
  ```
- 缩放前后都必须做alpha二值化（>=128→255，<128→0）
- 所有透明图缩放后必须验证：alpha只有0和255，且不透明区域RGB偏移=0

### 6. 坐标标注用原图尺寸
- 给用户看坐标图/坐标值，一律用原图尺寸（2048x2048）
- 不用500x500缩放后的坐标，缩放后坐标有偏差
- 用户基于缩放坐标标注的封闭线位置不准

### 7. 封闭线只需封断点
- 颜色灌水法靠非白色挡水，小缺口不需要封
- 只需封住内部白↔外部白连通的断点处
- 封闭线=在河流上建坝，不需要把整条河围起来

### 8. 透明图未定稿前禁止生成衍生图
- 必须等用户逐张审核确认后才能生成衍生图

### 9. 每次修改透明图必须发可视化调试图
- 水流覆盖图、对比图、棋盘格预览等
- 发图超2张必须标注每张是什么

### 10. 方法保留原则
- 新方法不能覆盖旧方法，每种都有用武之地
- 新方法作为新增方案追加，而非替换现有方案

### 11. 对比图渲染必须用棋盘格
- 对比图右侧必须用棋盘格背景渲染透明区域，不能直接贴透明图RGB
- 正确做法：`Image.alpha_composite(checkerboard, transparent_img)`
- 透明区域显示棋盘格纹理，不透明区域显示原图RGB
- 每次生成对比图必须验证：右侧能明显看到棋盘格，不能和原图一模一样

### 12. L形封闭线方向必须正确（09_甲方爸爸踩坑）
- 竖线+底部水平线组成L形，必须围住主体方向
- 错误示例：底部线(0,2047)→(300,2047) 把主体排除在L形外
- 正确示例：竖线(300,1946)→(300,2047) + 底部线(300,2047)→(2047,2047)
- L形开口朝向主体，封闭线要把水挡在主体外面

### 13. 封闭线必须封住所有水可以进入的方向
- 外部灌水法从四边同时灌水，不是只从一边
- 只封底部不够，如果侧面也有开口，水会从侧面灌入
- 需要逐边检查：上、下、左、右，每个方向的开口都要封

### 14. 2048x2048图片坐标范围是0-2047（不是2048）
- 像素坐标从0开始，2048x2048的图片x/y范围是0-2047
- 超出2047的坐标（如2048、2100）会被截断到图片边界
- 底部线如果y坐标超出2047，画线时会被截断，可能不连续

### 15. sub-agent灌水逻辑可能有bug，需验证
- sub-agent可能实现错误（如L形方向搞反），导致结果不正确
- 验证方法：检查主体中心alpha=255，透明区域alpha=0
- 如果主体大面积透明化，说明灌水逻辑有bug，需手动重跑

### 16. 严禁重复下载模型
- 模型文件已存在于`模型/rembg/`目录（u2net.onnx、isnet-anime.onnx、isnet-general-use.onnx、silueta.onnx）
- 必须在导入rembg前设置`os.environ['U2NET_HOME'] = '模型/rembg'`，rembg会自动从本地读取
- sub-agent任务描述中必须明确写"模型已存在于模型/rembg/目录，不需要下载"
- 发现rembg自行下载说明U2NET_HOME未正确设置

### 17. sub-agent卡住必须及时终止
- 下载超时/卡住会持续消耗token，发现后立即终止
- bash命令必须设置合理timeout，不要无限等待
- 主agent要主动检查sub-agent进度，不要被动等超时

### 18. 处理尺寸必须统一在原图尺寸下操作
- 原图2048x2048，所有处理（文字保护、膨胀、融合等）必须在2048尺寸下完成
- 最后一步才缩放到500x500
- 不能拿已缩放到500x500的图当2048处理，会导致RGB偏移异常
### 19. 透明图必须保存为PNG格式，严禁保存为JPG
- 透明背景图必须保存为**PNG格式**，因为JPG不支持alpha通道，保存为JPG会丢失透明信息
- sub-agent生成透明图时，输出文件名必须是 `.png` 后缀，严禁 `.jpg`
- 覆盖旧文件时也要确保文件名和格式一致，不能旧的是 `.png` 新的存成 `.jpg` 导致旧文件没被替换
- 衍生图生成前必须检查透明背景目录，确保没有多余的 `.jpg` 文件混入

### 20. 生成衍生图前必须验证透明图是最新定稿版
- 衍生图是从透明图缩放生成的，如果透明图没更新，衍生图也是旧的
- 验证方法：检查透明图文件修改时间，确认是最近修改的
### 21. 总览图必须标注序号
- 每张图必须标注序号（如"1"、"2"..."26"），方便用户指定哪张需要修改
- 不带文字版没有文件名直观对应，序号是唯一的沟通方式
- 格式示例："01 出发"、"02 迷路"

### 22. 灌水颜色由用户指定，不要自动判断
- 不要自动识别背景色，避免误判导致透明图错误
- 用户会明确告知背景颜色（白色/黑色/绿色等），按用户指定执行

### 23. 已定稿套图修改必须备份
- 原图备份到原图目录留纪念，透明图备份到回收站（`./回收站/日期/`）
- 修改顺序：备份→改透明图→用户审核→审核通过后才更新衍生图
- 绝不能跳过备份直接修改定稿文件

### 24. 回退恢复时必须确认文件一致性
- 回退恢复时必须做md5校验，确认文件和备份一致
- 不确定时与用户商量，不能自行假设文件正确
- 回退后必须验证恢复结果

### 25. 所有AI生图提示词必须实时记录
- 每次调用image_generate必须立即记录到 `表情包/生图记录/生图日志.md`（或对应版本的生图日志）
- 记录内容：时间、提示词全文、参考图路径、是否图生图模式、输出路径、用途、结果评价
- 禁止事后补记，必须在生图同时记录
- 批量生图时每批记录，不要等全部完成再补

### 26. 生图日志必须记录完整生图参数
- 参考图路径（具体到哪张原图，不能用"旅游版原图"模糊描述）
- 是否图生图模式（ref_images非空即为图生图）
- 模型版本信息（当前扣子平台image_generate无法选择模型版本，需记录"平台默认模型"）
- 这些信息是后期复盘和复现的关键依据

### 27. 形象定稿后必须使用图生图（一致性铁律）
- 文生图仅适用于从0到1的形象定稿阶段（探索造型、试错）
- 形象一旦定稿，后续所有新场景/新主题都必须使用图生图，以已定稿版本的原图为参考
- 文生图无法保证跨版本形象一致（v8纯文生图效果不如v7图生图即为证明）
- 图生图参考图按性别选择：雄性用旅游版**不带文字版**原图（头顶小揪揪正确），雌性用旅游版**带文字版**原图（头顶小爱心正确），不要搞混！
- ⚠️ 头顶造型不对的参考图会传染（v4褶皱发髻、v7丝带辫子做参考图会继承错误头顶），必须用头顶正确的参考图
- 违反此铁律=浪费时间和资源，生成的图无法使用

### 28. 批量生图必须先审后批量（先审铁律）
- 生成新版本/新主题的表情图时，**必须先生成2-4张（雌雄各1-2张）给用户审核**
- 用户确认形象、风格、背景等没问题后，才能继续批量生成剩余图片
- 如果不先审就直接批量生成，一旦风格/形象有问题，所有图片都白费积分
- 先审的内容包括：形象是否正确、头顶造型是否对、背景色是否符合、文字样式是否对、整体氛围是否满意
- 此铁律适用于：新主题版本（新年版/校园版等）、新年龄段（幼年版/少年版等）、参考图/提示词有重大调整时


## 9.6 灌水方向变体（旅游版新增）

灌水法不仅可以从四边灌水，还可以控制灌水方向和起点，适应不同图片：

### 方向变体

| 方案 | 起点 | 适用场景 | 示例 |
|------|------|---------|------|
| 外部洪水灌水法 | 四边同时 | 背景四周都是白色 | 打工人版多数图 |
| 上方灌水法 | 只从上边缘 | 底部白色需要保留 | 旅游版08_睡懒觉 |
| 右上角单点灌水法 | 只从(0,w-1)一个像素 | 只需从一角去除背景 | 旅游版06_累瘫、11_堵车、13_爬山 |
| 左上角单点灌水法 | 只从(0,0)一个像素 | 同上，方向不同 | 旅游版20_酒店躺 |
| 左上角灌黑水法 | 只从(0,0)一个像素，颜色判黑 | **黑底图专用**，遇黑色变透明，遇非黑停 | 旅游版07_晒黑 |
| 灌绿水法 | 从指定点，颜色判绿 | **绿幕图专用**，遇绿色变透明，遇非绿停 | 绿幕原图 |
| 任意方向灌水 | 用户指定边/角 | 灵活适配 | - |

### 关键经验
- **灌水起点越小越自然**：整条边或大片区域做起点会导致方块形透明区
- **单点灌水**：只从一个像素开始，BFS自然扩散，水流沿白色连通区域流动，形状自然
- **方向选择**：看主体在图片哪个位置，从远离主体的角落灌水
- **自动识别背景色（暂关闭）**：由用户指定背景颜色，不要自动判断，避免误判
  - 白底图→灌白水（RGB三通道>240为白色，遇白变透明）
  - 黑底图→灌黑水（RGB三通道<15为黑色，遇黑变透明）
  - 绿幕图→灌绿水（G通道>200且R<100且B<100为绿色，遇绿变透明）

### 右上角单点灌水代码
```python
def top_right_corner_flood_fill(orig_rgb, white_threshold=240):
    h, w = orig_rgb.shape[:2]
    is_white = (orig_rgb[:,:,0] > white_threshold) & \
               (orig_rgb[:,:,1] > white_threshold) & \
               (orig_rgb[:,:,2] > white_threshold)
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()
    # 只从右上角那一个点开始
    if is_white[0, w-1]:
        queue.append((0, w-1))
        visited[0, w-1] = True
    while queue:
        y, x = queue.popleft()
        for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny, nx = y+dy, x+dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_white[ny, nx]:
                visited[ny, nx] = True
                queue.append((ny, nx))
    alpha = np.where(visited, 0, 255).astype(np.uint8)
    return alpha
```

### 上方灌水代码
```python
def top_flood_fill(orig_rgb, white_threshold=240):
    h, w = orig_rgb.shape[:2]
    is_white = (orig_rgb[:,:,0] > white_threshold) & \
               (orig_rgb[:,:,1] > white_threshold) & \
               (orig_rgb[:,:,2] > white_threshold)
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()
    # 只从上边缘开始
    for x in range(w):
        if is_white[0, x]:
            queue.append((0, x))
            visited[0, x] = True
    while queue:
        y, x = queue.popleft()
        for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny, nx = y+dy, x+dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_white[ny, nx]:
                visited[ny, nx] = True
                queue.append((ny, nx))
    alpha = np.where(visited, 0, 255).astype(np.uint8)
    return alpha
```

---

### 9.7 原图当背景方案

当图片背景复杂（如风景、夜景等），透明处理会丢失重要画面元素时，可以直接使用原图作为"透明图"：

```python
from PIL import Image
import numpy as np

orig = Image.open('原图.jpg').convert('RGB')
orig_500 = np.array(orig.resize((500,500), Image.Resampling.LANCZOS))
alpha_500 = np.full((500,500), 255, dtype=np.uint8)  # 全不透明
result = np.dstack([orig_500, alpha_500])
Image.fromarray(result).save('透明背景/xxx.png')
```

适用场景：图片背景本身就是画面的一部分（如看海、看日出等风景场景），抠掉背景反而失去意义。

---

## 10. 打包规则

### 微信表情开放平台打包规范

每套表情包单独一个zip压缩包，压缩包内按类型分文件夹：

```
{套包名}_带文字版.zip
├── 主图/              # 240×240 PNG
├── 缩略图/            # 120×120 PNG
├── 聊天面板图标/       # 50×50 PNG
├── 表情封面图/         # 240×240 PNG（1张）
└── 详情页横幅/         # 750×400 JPG（1张）

{套包名}_不带文字版.zip
├── 主图/
├── 缩略图/
├── 聊天面板图标/
├── 表情封面图/
└── 详情页横幅/
```

### 打包命令
```bash
cd 表情包/{角色名}/{套包名}/{文字版本}/
zip -r ../../{套包名}_{文字版本}.zip 主图/ 缩略图/ 聊天面板图标/ 表情封面图/ 详情页横幅/
```

### 注意事项
- 只打包衍生图目录（主图/缩略图/聊天面板图标/表情封面图/详情页横幅）
- 不打包原图、透明背景、对比图等中间产物
- 打包前确认所有衍生图已定稿
- 打包后验证文件数量和目录结构

---

## 定稿方案记录

> 每套表情包定稿后，记录各图片使用的具体方案，方便复盘参考。

### 旅游版·不带文字版（2026-05-02定稿）

| 序号 | 图片 | 方案 | 备注 |
|------|------|------|------|
| 01 | 出发 | 右上角灌水法 | |
| 02 | 迷路 | 右上角灌水法 | |
| 03 | 拍照 | 右上角灌水法 | |
| 04 | 打卡 | 右上角灌水法 | |
| 05 | 买买买 | 右上+左下双起点灌水 | 单点不够，加左下补充 |
| 06 | 累瘫 | 右上角灌水法 | |
| 07 | 晒黑 | 右上角灌水法 | |
| 08 | 睡懒觉 | anime+灌水法融合 | 封闭缺口后灌水，再与anime alpha取max融合 |
| 09 | 行李超重 | 右上角灌水法 | |
| 10 | 高铁上 | 上下同时灌水法 | 原图非正方形(2304x1728)，先padding再灌水 |
| 11 | 堵车 | 右上角灌水法 | |
| 12 | 看海 | 下方灌水法 | 原图非正方形(2304x1728)，先padding再从下方灌 |
| 13 | 爬山 | 右上角灌水法 | |
| 14 | 看日出 | 右上角灌水法 | |
| 15 | 逛夜市 | 右上角灌水法 | |
| 16 | 干饭 | 右上角灌水法 | |
| 17 | 踩雷 | 右上角灌水法 | |
| 18 | 摆拍 | 右上角灌水法 | |
| 19 | 倒时差 | 右上角灌水法 | |
| 20 | 酒店躺 | 右上+左上双起点灌水 | |
| 21 | 买特产 | 右上角灌水法 | |
| 22 | 人从众 | 右上+左上双起点灌水 | |
| 23 | 返程 | 右上角灌水法 | |
| 24 | 误机 | 右上角灌水法 | |
| 25 | 护照呢 | 右上+左下双起点灌水 | |
| 26 | 旅行结束 | 右上角灌水法 | |

### 旅游版·带文字版（2026-05-02定稿）

| 序号 | 图片 | 方案 | 备注 |
|------|------|------|------|
| 01-06 | 出发~累瘫 | 外部洪水灌水法 | 四边灌水（06），其余四边 |
| 07 | 晒黑 | 灌黑水法 | 黑底图，遇黑变透明 |
| 08 | 睡懒觉 | 上方灌水法 | 只从上边缘灌 |
| 09 | 行李超重 | 混合方案v3 | |
| 10 | 高铁上 | 原图当背景 | alpha全255 |
| 11 | 堵车 | 右上角单点灌水法 | |
| 12 | 看海 | 原图当背景 | alpha全255 |
| 13 | 爬山 | 右上角单点灌水法 | 黑底图 |
| 14 | 看日出 | 原图当背景 | alpha全255 |
| 15-19 | 逛夜市~倒时差 | 外部洪水灌水法 | |
| 20 | 酒店躺 | 左上角灌水法 | 单点灌白色水 |
| 21 | 买特产 | 外部洪水灌水法 | |
| 22 | 人从众 | 外部洪水灌水法 | |
| 23-26 | 返程~旅行结束 | 外部洪水灌水法 | |
### 23. 已定稿套图修改必须备份，先改透明图审核后再更新衍生图
- 对已定稿的套图进行修改时，必须先备份：
  - **原图**：备份到原图目录下，保留旧版作为纪念（如 `07_不想上班_原始.jpg`）
  - **透明图**：备份到回收站（`./回收站/日期/`）
- 修改顺序：备份 → 修改原图 → 修改透明图 → 用户审核透明图 → 审核通过后才更新衍生图
- 严禁跳过审核直接更新衍生图，透明图未确认前衍生图保持不变
- 衍生图更新后需要重新打包发送
### 24. 回退恢复时必须确认文件一致性，不确定时与用户商量
- 回退操作前必须用md5校验确认备份文件和原版一致，不能凭猜测拷贝
- 如果回收站有多个版本的备份，不能自行判断用哪个，必须与用户确认
- 恢复后必须验证：md5对比、图片内容检查、透明图尺寸和alpha分布
- 严禁"差不多就恢复"，宁可多问一句也不能搞错
### 25. 所有AI生图提示词必须记录在案
- 生图日志文件：`表情包/生图记录/生图日志.md`
- 每次调用 image_generate 生图，必须记录：时间、提示词、参考图（如有）、使用模型、输出路径、用途说明、结果评价
- 包括：初始角色设计图、批量表情生成、绿幕重生成、图生图转换、新增表情图等所有场景
- 已有历史提示词需补充完整，确保每张原图的生成提示词都可追溯
- 方便后期复盘：哪类提示词效果好、角色一致性如何、哪些词要避免