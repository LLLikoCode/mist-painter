#!/bin/bash
# 迷雾绘者 (Mist Painter) - 角色Sprite生成脚本
# 使用ImageMagick创建像素艺术sprite

set -e

OUTPUT_DIR="/home/admin/.openclaw/workspace/assets/sprites/character"
mkdir -p "$OUTPUT_DIR"

# 颜色定义 (根据美术风格指南)
TRANSPARENT="none"
CLOAK="#2d2d2d"        # 斗篷深灰
CLOAK_DARK="#1a1a1a"   # 斗篷墨黑
HOOD_INNER="#141414"   # 兜帽内部
EYE="#c9a227"          # 金色眼睛
BACKPACK="#5a4a3a"     # 皮革背包
BOOTS="#3d2817"        # 深褐色靴子
HIGHLIGHT="#3c3c3c"    # 高光

echo "🎨 生成迷雾绘者主角Sprite资源..."

# 函数：创建基础角色
create_base_character() {
    local output="$1"
    
    convert -size 32x48 xc:"$TRANSPARENT" \
        `# 头部/兜帽 (y: 0-12)` \
        -fill "$CLOAK" -draw "rectangle 8,0 23,11" \
        -fill "$HOOD_INNER" -draw "rectangle 10,2 21,9" \
        `# 眼睛 (金色微光)` \
        -fill "$EYE" -draw "rectangle 12,5 13,7" \
        -fill "$EYE" -draw "rectangle 18,5 19,7" \
        `# 身体/斗篷主体 (y: 12-32)` \
        -fill "$CLOAK" -draw "rectangle 6,12 25,31" \
        -fill "$CLOAK_DARK" -draw "rectangle 8,14 23,29" \
        `# 斗篷边缘高光` \
        -fill "$HIGHLIGHT" -draw "rectangle 6,12 7,31" \
        -fill "$HIGHLIGHT" -draw "rectangle 24,12 25,31" \
        `# 背包` \
        -fill "$BACKPACK" -draw "rectangle 4,16 7,27" \
        -fill "$BACKPACK" -draw "rectangle 24,16 27,27" \
        `# 腿部/靴子` \
        -fill "$BOOTS" -draw "rectangle 8,32 14,47" \
        -fill "$BOOTS" -draw "rectangle 17,32 23,47" \
        `# 靴子高光` \
        -fill "$HIGHLIGHT" -draw "rectangle 8,44 9,47" \
        -fill "$HIGHLIGHT" -draw "rectangle 17,44 18,47" \
        "$output"
}

# 函数：创建待机动画帧
create_idle_frame() {
    local frame_num="$1"
    local output="$2"
    
    # 复制基础角色
    create_base_character "$output"
    
    # 根据帧号添加呼吸效果
    if [ "$frame_num" -eq 2 ] || [ "$frame_num" -eq 4 ]; then
        # 轻微下沉
        convert "$output" \
            -fill "$CLOAK" -draw "rectangle 6,31 25,33" \
            "$output"
    fi
}

# 函数：创建行走动画帧
create_walk_frame() {
    local frame_num="$1"
    local output="$2"
    
    # 创建基础
    convert -size 32x48 xc:"$TRANSPARENT" \
        `# 头部/兜帽` \
        -fill "$CLOAK" -draw "rectangle 8,0 23,11" \
        -fill "$HOOD_INNER" -draw "rectangle 10,2 21,9" \
        -fill "$EYE" -draw "rectangle 12,5 13,7" \
        -fill "$EYE" -draw "rectangle 18,5 19,7" \
        `# 身体/斗篷` \
        -fill "$CLOAK" -draw "rectangle 6,12 25,31" \
        -fill "$CLOAK_DARK" -draw "rectangle 8,14 23,29" \
        "$output"
    
    # 根据帧数添加腿部
    if [ "$frame_num" -eq 1 ] || [ "$frame_num" -eq 2 ]; then
        # 左腿前，右腿后
        convert "$output" \
            -fill "$BACKPACK" -draw "rectangle 4,14 6,27" \
            -fill "$BOOTS" -draw "rectangle 6,32 12,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 6,44 7,47" \
            -fill "$BOOTS" -draw "rectangle 19,34 25,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 19,44 20,47" \
            "$output"
    elif [ "$frame_num" -eq 3 ] || [ "$frame_num" -eq 4 ]; then
        # 双腿并拢
        convert "$output" \
            -fill "$BACKPACK" -draw "rectangle 4,16 7,27" \
            -fill "$BACKPACK" -draw "rectangle 24,16 27,27" \
            -fill "$BOOTS" -draw "rectangle 8,32 14,47" \
            -fill "$BOOTS" -draw "rectangle 17,32 23,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 8,44 9,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 17,44 18,47" \
            "$output"
    elif [ "$frame_num" -eq 5 ] || [ "$frame_num" -eq 6 ]; then
        # 右腿前，左腿后
        convert "$output" \
            -fill "$BACKPACK" -draw "rectangle 26,14 28,27" \
            -fill "$BOOTS" -draw "rectangle 19,32 25,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 19,44 20,47" \
            -fill "$BOOTS" -draw "rectangle 6,34 12,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 6,44 7,47" \
            "$output"
    else
        # 双腿并拢
        convert "$output" \
            -fill "$BACKPACK" -draw "rectangle 4,16 7,27" \
            -fill "$BACKPACK" -draw "rectangle 24,16 27,27" \
            -fill "$BOOTS" -draw "rectangle 8,32 14,47" \
            -fill "$BOOTS" -draw "rectangle 17,32 23,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 8,44 9,47" \
            -fill "$HIGHLIGHT" -draw "rectangle 17,44 18,47" \
            "$output"
    fi
}

# 函数：创建交互动画帧
create_interact_frame() {
    local frame_num="$1"
    local output="$2"
    
    # 创建基础
    convert -size 32x48 xc:"$TRANSPARENT" \
        `# 头部/兜帽` \
        -fill "$CLOAK" -draw "rectangle 8,0 23,11" \
        -fill "$HOOD_INNER" -draw "rectangle 10,2 21,9" \
        -fill "$EYE" -draw "rectangle 12,5 13,7" \
        -fill "$EYE" -draw "rectangle 18,5 19,7" \
        `# 身体/斗篷` \
        -fill "$CLOAK" -draw "rectangle 6,12 25,31" \
        -fill "$CLOAK_DARK" -draw "rectangle 8,14 23,29" \
        `# 背包` \
        -fill "$BACKPACK" -draw "rectangle 4,16 7,27" \
        -fill "$BACKPACK" -draw "rectangle 24,16 27,27" \
        `# 腿部` \
        -fill "$BOOTS" -draw "rectangle 8,32 14,47" \
        -fill "$BOOTS" -draw "rectangle 17,32 23,47" \
        -fill "$HIGHLIGHT" -draw "rectangle 8,44 9,47" \
        -fill "$HIGHLIGHT" -draw "rectangle 17,44 18,47" \
        "$output"
    
    # 添加手臂动作
    if [ "$frame_num" -eq 2 ]; then
        convert "$output" \
            -fill "$CLOAK" -draw "rectangle 26,17 29,25" \
            "$output"
    elif [ "$frame_num" -eq 3 ]; then
        convert "$output" \
            -fill "$CLOAK" -draw "rectangle 26,17 31,25" \
            "$output"
    elif [ "$frame_num" -eq 4 ]; then
        convert "$output" \
            -fill "$CLOAK" -draw "rectangle 26,17 29,25" \
            "$output"
    fi
}

echo "📦 生成待机动画帧 (4帧)..."
for i in 1 2 3 4; do
    create_idle_frame $i "$OUTPUT_DIR/character_idle_$(printf "%02d" $i).png"
done

# 合并待机动画帧
convert +append \
    "$OUTPUT_DIR/character_idle_01.png" \
    "$OUTPUT_DIR/character_idle_02.png" \
    "$OUTPUT_DIR/character_idle_03.png" \
    "$OUTPUT_DIR/character_idle_04.png" \
    "$OUTPUT_DIR/character_idle.png"

echo "📦 生成行走动画帧 (8帧)..."
for i in 1 2 3 4 5 6 7 8; do
    create_walk_frame $i "$OUTPUT_DIR/character_walk_$(printf "%02d" $i).png"
done

# 合并行走动画帧
convert +append \
    "$OUTPUT_DIR/character_walk_01.png" \
    "$OUTPUT_DIR/character_walk_02.png" \
    "$OUTPUT_DIR/character_walk_03.png" \
    "$OUTPUT_DIR/character_walk_04.png" \
    "$OUTPUT_DIR/character_walk_05.png" \
    "$OUTPUT_DIR/character_walk_06.png" \
    "$OUTPUT_DIR/character_walk_07.png" \
    "$OUTPUT_DIR/character_walk_08.png" \
    "$OUTPUT_DIR/character_walk.png"

echo "📦 生成交互动画帧 (4帧)..."
for i in 1 2 3 4; do
    create_interact_frame $i "$OUTPUT_DIR/character_interact_$(printf "%02d" $i).png"
done

# 合并交互动画帧
convert +append \
    "$OUTPUT_DIR/character_interact_01.png" \
    "$OUTPUT_DIR/character_interact_02.png" \
    "$OUTPUT_DIR/character_interact_03.png" \
    "$OUTPUT_DIR/character_interact_04.png" \
    "$OUTPUT_DIR/character_interact.png"

echo "📦 生成整合Sprite Sheet..."
# 创建完整的sprite sheet (所有动画)
convert +append \
    "$OUTPUT_DIR/character_idle.png" \
    "$OUTPUT_DIR/character_walk.png" \
    "$OUTPUT_DIR/character_interact.png" \
    "$OUTPUT_DIR/character_sprite_sheet.png"

echo "✅ Sprite资源生成完成!"
echo "📁 输出目录: $OUTPUT_DIR"
echo ""
echo "生成的文件:"
ls -la "$OUTPUT_DIR"/*.png | grep -v "_0" | awk '{print "  - " $9