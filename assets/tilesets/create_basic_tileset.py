#!/usr/bin/env python3
"""
迷雾绘者 (Mist Painter) - 基础地形 Tileset 生成器
生成32x32像素规格的基础地形tileset
使用纯Python实现，无需外部依赖
"""

import os
import struct
import zlib

def create_png_chunk(chunk_type, data):
    """创建PNG数据块"""
    chunk = chunk_type + data
    crc = zlib.crc32(chunk) & 0xffffffff
    return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)

def create_png_rgba(width, height, pixels):
    """创建PNG格式数据 (RGBA)"""
    # PNG文件签名
    signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR块
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)  # 8-bit RGBA
    ihdr = create_png_chunk(b'IHDR', ihdr_data)
    
    # IDAT块 - 压缩图像数据
    raw_data = b''
    for row in range(height):
        raw_data += b'\x00'  # 过滤类型: None
        for col in range(width):
            r, g, b, a = pixels[row * width + col]
            raw_data += bytes([r, g, b, a])
    
    compressed = zlib.compress(raw_data)
    idat = create_png_chunk(b'IDAT', compressed)
    
    # IEND块
    iend = create_png_chunk(b'IEND', b'')
    
    return signature + ihdr + idat + iend

def create_tileset():
    """创建基础地形tileset"""
    
    # 色彩调色板 - 基于美术风格指南
    colors = {
        # 羊皮纸色系 (地面/草地)
        'paper_light': (245, 240, 225, 255),    # #f5f0e1
        'paper_medium': (232, 220, 196, 255),   # #e8dcc4
        'paper_dark': (212, 196, 168, 255),     # #d4c4a8
        'paper_aged': (201, 184, 150, 255),     # #c9b896
        
        # 墨水色系
        'ink_black': (26, 26, 26, 255),         # #1a1a1a
        'ink_dark': (45, 45, 45, 255),          # #2d2d2d
        'ink_faded': (90, 90, 90, 255),         # #5a5a5a
        'ink_brown': (61, 40, 23, 255),         # #3d2817
        
        # 环境色
        'shadow_deep': (10, 10, 10, 255),       # #0a0a0a
        'fog': (42, 37, 32, 255),               # #2a2520
        
        # 强调色
        'water': (74, 111, 165, 255),           # #4a6fa5
        'water_dark': (45, 70, 110, 255),       # 深水
        'moss': (74, 124, 89, 255),             # #4a7c59
        'stone': (120, 115, 105, 255),          # 石头
    }
    
    TILE_SIZE = 32
    TILES_PER_ROW = 8
    NUM_TILES = 24
    
    width = TILE_SIZE * TILES_PER_ROW
    height = TILE_SIZE * ((NUM_TILES + TILES_PER_ROW - 1) // TILES_PER_ROW)
    
    # 初始化透明像素
    pixels = [(0, 0, 0, 0)] * (width * height)
    
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = color
    
    def fill_rect(ox, oy, w, h, color):
        for y in range(oy, min(oy + h, height)):
            for x in range(ox, min(ox + w, width)):
                set_pixel(x, y, color)
    
    def draw_noise(ox, oy, w, h, color, count):
        import random
        random.seed(42)  # 固定种子以获得可重复结果
        for _ in range(count):
            x = ox + random.randint(0, w - 1)
            y = oy + random.randint(0, h - 1)
            set_pixel(x, y, color)
    
    tile_definitions = []
    
    # Tile 0: 草地基础
    def draw_grass_base(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_light'])
        # 草地纹理
        draw_noise(ox, oy, 32, 32, colors['paper_medium'], 20)
        draw_noise(ox, oy, 32, 32, colors['paper_aged'], 10)
    
    # Tile 1: 草地变体1
    def draw_grass_var1(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_medium'])
        draw_noise(ox, oy, 32, 32, colors['paper_light'], 25)
    
    # Tile 2: 泥土/路径基础
    def draw_dirt_base(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_dark'])
        draw_noise(ox, oy, 32, 32, colors['paper_aged'], 15)
        draw_noise(ox, oy, 32, 32, colors['ink_brown'], 8)
    
    # Tile 3: 水面基础
    def draw_water_base(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['water'])
        # 水波纹
        for i in range(4):
            y = oy + 4 + i * 8
            for x in range(ox + 2, ox + 10):
                set_pixel(x, y, colors['water_dark'])
            for x in range(ox + 18, ox + 28):
                set_pixel(x, y + 4, colors['water_dark'])
    
    # Tile 4: 草地-泥土 上边缘
    def draw_grass_dirt_top(ox, oy):
        fill_rect(ox, oy + 16, 32, 16, colors['paper_dark'])
        fill_rect(ox, oy, 32, 16, colors['paper_light'])
        for x in range(0, 32, 4):
            set_pixel(ox + x, oy + 16, colors['paper_aged'])
    
    # Tile 5: 草地-泥土 下边缘
    def draw_grass_dirt_bottom(ox, oy):
        fill_rect(ox, oy, 32, 16, colors['paper_dark'])
        fill_rect(ox, oy + 16, 32, 16, colors['paper_light'])
        for x in range(0, 32, 4):
            set_pixel(ox + x, oy + 15, colors['paper_aged'])
    
    # Tile 6: 草地-泥土 左边缘
    def draw_grass_dirt_left(ox, oy):
        fill_rect(ox + 16, oy, 16, 32, colors['paper_dark'])
        fill_rect(ox, oy, 16, 32, colors['paper_light'])
        for y in range(0, 32, 4):
            set_pixel(ox + 16, oy + y, colors['paper_aged'])
    
    # Tile 7: 草地-泥土 右边缘
    def draw_grass_dirt_right(ox, oy):
        fill_rect(ox, oy, 16, 32, colors['paper_dark'])
        fill_rect(ox + 16, oy, 16, 32, colors['paper_light'])
        for y in range(0, 32, 4):
            set_pixel(ox + 15, oy + y, colors['paper_aged'])
    
    # Tile 8: 草地-水面 上边缘
    def draw_grass_water_top(ox, oy):
        fill_rect(ox, oy + 16, 32, 16, colors['water'])
        fill_rect(ox, oy, 32, 16, colors['paper_light'])
        for i in range(3):
            set_pixel(ox + 4 + i * 8, oy + 20, colors['water_dark'])
    
    # Tile 9: 草地-水面 下边缘
    def draw_grass_water_bottom(ox, oy):
        fill_rect(ox, oy, 32, 16, colors['water'])
        fill_rect(ox, oy + 16, 32, 16, colors['paper_light'])
    
    # Tile 10: 草地-水面 左边缘
    def draw_grass_water_left(ox, oy):
        fill_rect(ox + 16, oy, 16, 32, colors['water'])
        fill_rect(ox, oy, 16, 32, colors['paper_light'])
    
    # Tile 11: 草地-水面 右边缘
    def draw_grass_water_right(ox, oy):
        fill_rect(ox, oy, 16, 32, colors['water'])
        fill_rect(ox + 16, oy, 16, 32, colors['paper_light'])
    
    # Tile 12: 内角 左上
    def draw_inner_corner_tl(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_dark'])
        fill_rect(ox, oy, 16, 16, colors['paper_light'])
    
    # Tile 13: 内角 右上
    def draw_inner_corner_tr(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_dark'])
        fill_rect(ox + 16, oy, 16, 16, colors['paper_light'])
    
    # Tile 14: 内角 左下
    def draw_inner_corner_bl(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_dark'])
        fill_rect(ox, oy + 16, 16, 16, colors['paper_light'])
    
    # Tile 15: 内角 右下
    def draw_inner_corner_br(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_dark'])
        fill_rect(ox + 16, oy + 16, 16, 16, colors['paper_light'])
    
    # Tile 16: 外角 左上
    def draw_outer_corner_tl(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_light'])
        fill_rect(ox + 16, oy + 16, 16, 16, colors['paper_dark'])
    
    # Tile 17: 外角 右上
    def draw_outer_corner_tr(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_light'])
        fill_rect(ox, oy + 16, 16, 16, colors['paper_dark'])
    
    # Tile 18: 外角 左下
    def draw_outer_corner_bl(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_light'])
        fill_rect(ox + 16, oy, 16, 16, colors['paper_dark'])
    
    # Tile 19: 外角 右下
    def draw_outer_corner_br(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_light'])
        fill_rect(ox, oy, 16, 16, colors['paper_dark'])
    
    # Tile 20: 石墙基础
    def draw_stone_wall(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['stone'])
        # 石块纹理
        fill_rect(ox + 2, oy + 2, 12, 12, colors['paper_aged'])
        fill_rect(ox + 18, oy + 2, 12, 12, colors['paper_aged'])
        fill_rect(ox + 2, oy + 18, 12, 12, colors['paper_aged'])
        fill_rect(ox + 18, oy + 18, 12, 12, colors['paper_aged'])
    
    # Tile 21: 苔藓地面
    def draw_mossy_ground(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['paper_dark'])
        # 苔藓斑块
        import random
        random.seed(42)
        for _ in range(6):
            mx = ox + 4 + random.randint(0, 20)
            my = oy + 4 + random.randint(0, 20)
            fill_rect(mx, my, 6, 4, colors['moss'])
    
    # Tile 22: 阴影/未探索
    def draw_shadow(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['shadow_deep'])
    
    # Tile 23: 迷雾
    def draw_fog(ox, oy):
        fill_rect(ox, oy, 32, 32, colors['fog'])
        draw_noise(ox, oy, 32, 32, colors['shadow_deep'], 8)
    
    # 所有绘制函数
    draw_funcs = [
        ("草地基础", draw_grass_base),
        ("草地变体1", draw_grass_var1),
        ("泥土基础", draw_dirt_base),
        ("水面基础", draw_water_base),
        ("草地-泥土 上边缘", draw_grass_dirt_top),
        ("草地-泥土 下边缘", draw_grass_dirt_bottom),
        ("草地-泥土 左边缘", draw_grass_dirt_left),
        ("草地-泥土 右边缘", draw_grass_dirt_right),
        ("草地-水面 上边缘", draw_grass_water_top),
        ("草地-水面 下边缘", draw_grass_water_bottom),
        ("草地-水面 左边缘", draw_grass_water_left),
        ("草地-水面 右边缘", draw_grass_water_right),
        ("内角 左上", draw_inner_corner_tl),
        ("内角 右上", draw_inner_corner_tr),
        ("内角 左下", draw_inner_corner_bl),
        ("内角 右下", draw_inner_corner_br),
        ("外角 左上", draw_outer_corner_tl),
        ("外角 右上", draw_outer_corner_tr),
        ("外角 左下", draw_outer_corner_bl),
        ("外角 右下", draw_outer_corner_br),
        ("石墙基础", draw_stone_wall),
        ("苔藓地面", draw_mossy_ground),
        ("阴影/未探索", draw_shadow),
        ("迷雾", draw_fog),
    ]
    
    # 绘制所有tiles
    for i, (name, func) in enumerate(draw_funcs):
        x = (i % TILES_PER_ROW) * TILE_SIZE
        y = (i // TILES_PER_ROW) * TILE_SIZE
        func(x, y)
        tile_definitions.append({
            'index': i,
            'name': name,
            'x': x,
            'y': y,
            'coord': f"({i % TILES_PER_ROW}, {i // TILES_PER_ROW})"
        })
    
    return create_png_rgba(width, height, pixels), tile_definitions, (width, height)

def create_tile_layout_doc(tile_definitions):
    """创建tile布局说明文档"""
    doc = """# 迷雾绘者 (Mist Painter) - 基础地形 Tileset 布局说明

> **文件**: basic_terrain_tileset.png  
> **Tile 尺寸**: 32×32 像素  
> **Tile 总数**: 24  
> **布局**: 8 tiles/行 × 3 行  
> **创建时间**: 2026-03-24  

---

## 色彩 Palette

本 tileset 使用以下色彩 palette，与游戏整体美术风格保持一致：

### 羊皮纸色系 (地面)
| 名称 | 色值 | 用途 |
|------|------|------|
| paper_light | #f5f0e1 | 主草地/羊皮纸浅色 |
| paper_medium | #e8dcc4 | 草地变体 |
| paper_dark | #d4c4a8 | 泥土/路径 |
| paper_aged | #c9b896 | 老化效果/边缘 |

### 环境色
| 名称 | 色值 | 用途 |
|------|------|------|
| water | #4a6fa5 | 水面 |
| water_dark | #2d466e | 深水/水波纹 |
| moss | #4a7c59 | 苔藓 |
| stone | #787369 | 石墙 |
| shadow_deep | #0a0a0a | 阴影/未探索区域 |
| fog | #2a2520 | 迷雾 |

---

## Tile 布局图

```
┌────┬────┬────┬────┬────┬────┬────┬────┐
│ 00 │ 01 │ 02 │ 03 │ 04 │ 05 │ 06 │ 07 │  ← 第0行
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 08 │ 09 │ 10 │ 11 │ 12 │ 13 │ 14 │ 15 │  ← 第1行
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 16 │ 17 │ 18 │ 19 │ 20 │ 21 │ 22 │ 23 │  ← 第2行
└────┴────┴────┴────┴────┴────┴────┴────┘
```

---

## Tile 详细说明

"""
    
    categories = {
        (0, 3): "基础地形",
        (4, 11): "边缘过渡",
        (12, 19): "角落连接",
        (20, 23): "特殊地形"
    }
    
    for tile in tile_definitions:
        category = "其他"
        for (start, end), cat in categories.items():
            if start <= tile['index'] <= end:
                category = cat
                break
        
        doc += f"""### Tile {tile['index']:02d}: {tile['name']}
- **坐标**: {tile['coord']} (像素位置: x={tile['x']}, y={tile['y']})
- **分类**: {category}
- **用途**: """
        
        if tile['index'] <= 1:
            doc += "草地基础填充，可交替使用创造自然变化"
        elif tile['index'] == 2:
            doc += "泥土/路径基础填充"
        elif tile['index'] == 3:
            doc += "水面基础填充"
        elif 4 <= tile['index'] <= 7:
            doc += "草地与泥土之间的平滑过渡"
        elif 8 <= tile['index'] <= 11:
            doc += "草地与水面之间的平滑过渡"
        elif 12 <= tile['index'] <= 15:
            doc += "内角连接（草地凹进泥土/水中）"
        elif 16 <= tile['index'] <= 19:
            doc += "外角连接（草地凸出到泥土/水边）"
        elif tile['index'] == 20:
            doc += "石墙/障碍物，不可通行"
        elif tile['index'] == 21:
            doc += "苔藓地面，用于古老/潮湿区域"
        elif tile['index'] == 22:
            doc += "阴影/未探索区域遮罩"
        elif tile['index'] == 23:
            doc += "迷雾效果"
        doc += "\n\n"
    
    doc += """---

## 使用指南

### 基础填充
- 使用 Tile 00 (草地基础) 或 Tile 01 (草地变体1) 填充大面积草地
- 交替使用可创造自然变化效果

### 边缘过渡
- Tile 04-07: 草地与泥土之间的过渡
- Tile 08-11: 草地与水面之间的过渡

### 角落连接
- Tile 12-15: 内角 (草地凹进去)
- Tile 16-19: 外角 (草地凸出来)

### 特殊地形
- Tile 20: 石墙/障碍物
- Tile 21: 苔藓地面 (用于古老区域)
- Tile 22: 阴影/未探索区域
- Tile 23: 迷雾效果

---

## 示例组合

### 简单的草地-泥土过渡
```
[00][00][00]
[04][04][04]
[02][02][02]
```

### 带角落的草地岛
```
[16][06][06][17]
[07][00][00][05]
[07][00][00][05]
[18][04][04][19]
```

### 水边草地
```
[00][00][08][03]
[00][00][08][03]
```

### 复杂地形组合
```
[16][06][17][00][00][16][06][17]
[07][00][05][08][03][07][00][05]
[07][00][05][08][03][07][00][05]
[18][04][19][08][03][18][04][19]
[02][02][02][08][03][03][03][03]
```

---

## 技术规格

- **文件格式**: PNG (RGBA)
- **色彩深度**: 8-bit per channel
- **压缩**: zlib DEFLATE
- **Tile 尺寸**: 32×32 像素
- **总尺寸**: 256×96 像素 (8×3 tiles)

---

*文档生成时间: 2026-03-24*
*符合迷雾绘者美术风格指南 v1.0*
"""
    return doc

def main():
    # 创建输出目录
    output_dir = "/home/admin/.openclaw/workspace/assets/tilesets"
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成 tileset
    png_data, tile_definitions, dimensions = create_tileset()
    
    # 保存 PNG
    png_path = os.path.join(output_dir, "basic_terrain_tileset.png")
    with open(png_path, 'wb') as f:
        f.write(png_data)
    print(f"✓ 已保存: {png_path}")
    
    # 生成布局说明文档
    doc = create_tile_layout_doc(tile_definitions)
    doc_path = os.path.join(output_dir, "tile_layout_guide.md")
    with open(doc_path, 'w', encoding='utf-8') as f:
        f.write(doc)
    print(f"✓ 已保存: {doc_path}")
    
    print(f"\n✓ 完成! 共生成 {len(tile_definitions)} 个 tile")
    print(f"  - Tileset 尺寸: {dimensions[0]}×{dimensions[1]} 像素")
    print(f"  - Tile 尺寸: 32×32 像素")
    print(f"  - 布局: 8 tiles/行 × 3 行")

if __name__ == "__main__":
    main()
