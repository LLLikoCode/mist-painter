#!/usr/bin/env python3
"""
装饰元素 Tileset 生成器
使用纯 Python 实现 PNG 编码，无需外部依赖
"""

import struct
import zlib

# 色彩 Palette (与基础地形保持一致)
COLORS = {
    # 羊皮纸色系
    'paper_light': (245, 240, 225),
    'paper_medium': (232, 220, 196),
    'paper_dark': (212, 196, 168),
    'paper_aged': (201, 184, 150),

    # 环境色
    'water': (74, 111, 165),
    'water_dark': (45, 70, 110),
    'moss': (74, 124, 89),
    'moss_dark': (55, 95, 68),
    'stone': (120, 115, 105),
    'stone_dark': (90, 87, 80),
    'shadow_deep': (10, 10, 10),
    'fog': (42, 37, 32),

    # 植被色
    'grass_light': (140, 180, 100),
    'grass_medium': (100, 150, 70),
    'grass_dark': (70, 110, 50),
    'flower_red': (200, 80, 80),
    'flower_pink': (220, 150, 160),
    'flower_yellow': (230, 200, 80),
    'flower_white': (250, 250, 240),
    'bush_green': (85, 130, 65),
    'tree_trunk': (100, 80, 60),
    'tree_leaves': (60, 100, 50),

    # 水晶/魔法色
    'crystal_blue': (150, 200, 255),
    'crystal_purple': (180, 140, 220),
    'crystal_glow': (200, 230, 255),

    # 人造物
    'wood': (140, 110, 80),
    'wood_dark': (100, 75, 55),
    'metal': (160, 160, 170),
    'metal_dark': (100, 100, 110),
    'lamp_glow': (255, 220, 150),
    'sign_text': (60, 50, 40),

    # 水面装饰
    'lily_green': (100, 160, 90),
    'lily_pink': (230, 160, 180),
    'reed': (160, 140, 90),
}


class SimplePNG:
    """简单的 PNG 编码器"""

    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.pixels = [[(0, 0, 0, 0) for _ in range(width)] for _ in range(height)]

    def set_pixel(self, x, y, color):
        """设置单个像素"""
        if 0 <= x < self.width and 0 <= y < self.height:
            if len(color) == 3:
                color = (*color, 255)
            self.pixels[y][x] = color

    def fill_rect(self, x, y, w, h, color):
        """填充矩形"""
        for dy in range(h):
            for dx in range(w):
                self.set_pixel(x + dx, y + dy, color)

    def save(self, filename):
        """保存为 PNG 文件"""
        # PNG 签名
        signature = b'\x89PNG\r\n\x1a\n'

        # IHDR chunk
        ihdr_data = struct.pack('>IIBBBBB', self.width, self.height, 8, 6, 0, 0, 0)
        ihdr = self._make_chunk(b'IHDR', ihdr_data)

        # IDAT chunk (压缩图像数据)
        raw_data = b''
        for row in self.pixels:
            raw_data += b'\x00'  # 滤波器类型
            for pixel in row:
                raw_data += bytes(pixel)

        compressed = zlib.compress(raw_data)
        idat = self._make_chunk(b'IDAT', compressed)

        # IEND chunk
        iend = self._make_chunk(b'IEND', b'')

        with open(filename, 'wb') as f:
            f.write(signature)
            f.write(ihdr)
            f.write(idat)
            f.write(iend)

    def _make_chunk(self, chunk_type, data):
        """创建 PNG chunk"""
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)


# 创建装饰元素 tileset: 8 tiles/行 × 4 行 = 32 tiles
tile_size = 32
tiles_per_row = 8
num_rows = 4
width = tile_size * tiles_per_row
height = tile_size * num_rows

img = SimplePNG(width, height)

def get_tile_xy(tile_index):
    """获取 tile 的左上角坐标"""
    row = tile_index // tiles_per_row
    col = tile_index % tiles_per_row
    return (col * tile_size, row * tile_size)


# ========== 植被装饰 ==========

# Tile 0: 小草丛
tx, ty = get_tile_xy(0)
img.fill_rect(tx+12, ty+20, 8, 12, COLORS['grass_dark'])
img.fill_rect(tx+10, ty+18, 4, 8, COLORS['grass_medium'])
img.fill_rect(tx+18, ty+16, 4, 10, COLORS['grass_light'])
img.fill_rect(tx+14, ty+14, 4, 8, COLORS['grass_medium'])

# Tile 1: 草丛变体1
tx, ty = get_tile_xy(1)
img.fill_rect(tx+8, ty+22, 6, 10, COLORS['grass_dark'])
img.fill_rect(tx+16, ty+20, 8, 12, COLORS['grass_medium'])
img.fill_rect(tx+20, ty+16, 6, 10, COLORS['grass_light'])
img.fill_rect(tx+12, ty+18, 6, 8, COLORS['grass_medium'])

# Tile 2: 红色小花
tx, ty = get_tile_xy(2)
img.fill_rect(tx+15, ty+20, 2, 12, COLORS['grass_dark'])
img.fill_rect(tx+12, ty+22, 3, 2, COLORS['grass_medium'])
img.fill_rect(tx+17, ty+24, 3, 2, COLORS['grass_medium'])
img.fill_rect(tx+13, ty+14, 6, 6, COLORS['flower_red'])
img.fill_rect(tx+15, ty+16, 2, 2, COLORS['flower_yellow'])

# Tile 3: 粉色花朵
tx, ty = get_tile_xy(3)
img.fill_rect(tx+15, ty+18, 2, 14, COLORS['grass_dark'])
img.fill_rect(tx+11, ty+24, 4, 2, COLORS['grass_medium'])
img.fill_rect(tx+17, ty+22, 4, 2, COLORS['grass_medium'])
img.fill_rect(tx+12, ty+12, 8, 6, COLORS['flower_pink'])
img.fill_rect(tx+14, ty+10, 4, 2, COLORS['flower_pink'])
img.fill_rect(tx+15, ty+14, 2, 2, COLORS['flower_white'])

# Tile 4: 白色雏菊
tx, ty = get_tile_xy(4)
img.fill_rect(tx+15, ty+20, 2, 12, COLORS['grass_dark'])
img.fill_rect(tx+12, ty+24, 3, 2, COLORS['grass_medium'])
img.fill_rect(tx+17, ty+22, 3, 2, COLORS['grass_medium'])
img.fill_rect(tx+13, ty+12, 2, 6, COLORS['flower_white'])
img.fill_rect(tx+17, ty+12, 2, 6, COLORS['flower_white'])
img.fill_rect(tx+11, ty+14, 6, 2, COLORS['flower_white'])
img.fill_rect(tx+15, ty+14, 2, 2, COLORS['flower_yellow'])

# Tile 5: 黄色小花丛
tx, ty = get_tile_xy(5)
img.fill_rect(tx+8, ty+24, 4, 8, COLORS['grass_dark'])
img.fill_rect(tx+18, ty+22, 4, 10, COLORS['grass_dark'])
img.fill_rect(tx+12, ty+20, 8, 4, COLORS['flower_yellow'])
img.fill_rect(tx+10, ty+18, 4, 4, COLORS['flower_yellow'])
img.fill_rect(tx+20, ty+16, 4, 4, COLORS['flower_yellow'])

# Tile 6: 小灌木
tx, ty = get_tile_xy(6)
img.fill_rect(tx+12, ty+24, 8, 8, COLORS['bush_green'])
img.fill_rect(tx+8, ty+20, 6, 8, COLORS['bush_green'])
img.fill_rect(tx+18, ty+22, 6, 6, COLORS['bush_green'])
img.fill_rect(tx+10, ty+16, 12, 6, COLORS['bush_green'])
img.fill_rect(tx+14, ty+12, 4, 6, COLORS['bush_green'])

# Tile 7: 苔藓石上的草
tx, ty = get_tile_xy(7)
img.fill_rect(tx+8, ty+20, 16, 12, COLORS['stone'])
img.fill_rect(tx+6, ty+22, 4, 8, COLORS['stone_dark'])
img.fill_rect(tx+22, ty+24, 4, 6, COLORS['stone_dark'])
img.fill_rect(tx+10, ty+20, 8, 4, COLORS['moss'])
img.fill_rect(tx+16, ty+22, 6, 4, COLORS['moss_dark'])
img.fill_rect(tx+12, ty+14, 4, 6, COLORS['grass_medium'])
img.fill_rect(tx+18, ty+16, 4, 6, COLORS['grass_light'])

# ========== 环境装饰 ==========

# Tile 8: 小石头
tx, ty = get_tile_xy(8)
img.fill_rect(tx+12, ty+24, 8, 8, COLORS['stone'])
img.fill_rect(tx+10, ty+26, 4, 6, COLORS['stone_dark'])
img.fill_rect(tx+18, ty+26, 4, 4, COLORS['stone'])
img.fill_rect(tx+14, ty+22, 4, 4, COLORS['stone_dark'])

# Tile 9: 大石头
tx, ty = get_tile_xy(9)
img.fill_rect(tx+8, ty+18, 16, 14, COLORS['stone'])
img.fill_rect(tx+6, ty+22, 6, 10, COLORS['stone_dark'])
img.fill_rect(tx+20, ty+24, 6, 6, COLORS['stone'])
img.fill_rect(tx+12, ty+16, 8, 6, COLORS['stone_dark'])
img.fill_rect(tx+10, ty+20, 4, 4, COLORS['stone_dark'])

# Tile 10: 苔藓岩石
tx, ty = get_tile_xy(10)
img.fill_rect(tx+6, ty+16, 20, 16, COLORS['stone'])
img.fill_rect(tx+4, ty+20, 6, 10, COLORS['stone_dark'])
img.fill_rect(tx+22, ty+22, 6, 8, COLORS['stone'])
img.fill_rect(tx+8, ty+18, 12, 6, COLORS['moss'])
img.fill_rect(tx+16, ty+20, 8, 6, COLORS['moss_dark'])

# Tile 11: 蓝色水晶
tx, ty = get_tile_xy(11)
img.fill_rect(tx+14, ty+12, 4, 16, COLORS['crystal_blue'])
img.fill_rect(tx+12, ty+14, 2, 12, COLORS['crystal_blue'])
img.fill_rect(tx+18, ty+14, 2, 12, COLORS['crystal_blue'])
img.fill_rect(tx+10, ty+16, 2, 10, COLORS['crystal_glow'])
img.fill_rect(tx+20, ty+16, 2, 10, COLORS['crystal_glow'])
img.fill_rect(tx+12, ty+26, 8, 6, COLORS['stone_dark'])

# Tile 12: 紫色水晶簇
tx, ty = get_tile_xy(12)
img.fill_rect(tx+12, ty+10, 6, 16, COLORS['crystal_purple'])
img.fill_rect(tx+18, ty+16, 4, 10, COLORS['crystal_blue'])
img.fill_rect(tx+8, ty+18, 4, 8, COLORS['crystal_purple'])
img.fill_rect(tx+10, ty+24, 12, 8, COLORS['stone_dark'])

# Tile 13: 遗迹