# 角色模板：傲娇小汤圆

## 参考图
请将标准形象参考图放置于此目录下，命名为 `reference.png`

## 角色设定
详见 `character.md`

## 表情词库
详见 `expression_words.json`

## 使用说明

1. **生成标准形象**
   ```bash
   python scripts/generate_character.py \
     --character "傲娇小汤圆" \
     --template "templates/characters/傲娇小汤圆/character.md" \
     --ref-image "用户上传/头像.jpg" \
     --output "templates/characters/傲娇小汤圆/reference.png"
   ```

2. **生成表情包**
   ```bash
   python scripts/generate_expressions.py \
     --character "傲娇小汤圆" \
     --ref-image "templates/characters/傲娇小汤圆/reference.png" \
     --scene "基础场景" \
     --output "output/傲娇小汤圆/基础表情套包"
   ```

3. **处理透明背景**
   ```bash
   python scripts/process_transparency.py \
     --input-dir "output/傲娇小汤圆/基础表情套包/原图" \
     --output-dir "output/傲娇小汤圆/基础表情套包/透明背景"
   ```

4. **生成衍生素材**
   ```bash
   python scripts/generate_derivatives.py \
     --character "傲娇小汤圆" \
     --ref-image "templates/characters/傲娇小汤圆/reference.png" \
     --transparent-dir "output/傲娇小汤圆/基础表情套包/透明背景" \
     --output "output/傲娇小汤圆/基础表情套包/衍生素材"
   ```
