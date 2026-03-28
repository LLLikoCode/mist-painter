#!/usr/bin/env python3
"""
迷雾绘者 - Tileset 整合与导出工具
整合所有场景 tileset 资源并生成统一映射文件
"""

import struct
import zlib
import json
import os
from pathlib import Path

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
    'flower_blue': (100, 150, 220),
    'bush_green': (85, 130, 65),
    'tree_trunk': (100, 80, 60),
    'tree_leaves': (60, 100, 50),

    # 水晶/魔法色
    'crystal_blue': (150, 200, 255),
    'crystal_purple': (180, 140, 220),
    'crystal_pink': (255, 180, 200),
    'crystal_glow': (200, 230, 255),
    'magic_green': (150, 255, 180),

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

    def draw_tile_from_data(self, tx, ty, pixel_data):
        """从像素数据绘制 tile"""
        for y, row in enumerate(pixel_data):
            for x, color in enumerate(row):
                if color:
                    self.set_pixel(tx + x, ty + y, color)

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


def create_basic_terrain_tileset():
    """创建基础地形 tileset (24 tiles)"""
    tile_size = 32
    tiles_per_row = 8
    num_rows = 3
    width = tile_size * tiles_per_row
    height = tile_size * num_rows

    img = SimplePNG(width, height)

    def get_tile_xy(tile_index):
        row = tile_index // tiles_per_row
        col = tile_index % tiles_per_row
        return (col * tile_size, row * tile_size)

    # Tile 0-1: 草地基础/变体
    for i in range(2):
        tx, ty = get_tile_xy(i)
        color = COLORS['paper_light'] if i == 0 else COLORS['paper_medium']
        img.fill_rect(tx, ty, 32, 32, color)
        # 添加一些纹理
        for y in range(4, 28, 8):
            for x in range(4, 28, 8):
                if (x + y) % 16 == 0:
                    img.fill_rect(tx + x, ty + y, 2, 2, COLORS['paper_aged'])

    # Tile 2: 泥土基础
    tx, ty = get_tile_xy(2)
    img.fill_rect(tx, ty, 32, 32, COLORS['paper_dark'])

    # Tile 3: 水面基础
    tx, ty = get_tile_xy(3)
    img.fill_rect(tx, ty, 32, 32, COLORS['water'])
    # 水波纹
    for x in range(4, 28, 12):
        img.fill_rect(tx + x, ty + 8, 8, 2, COLORS['water_dark'])
        img.fill_rect(tx + x + 4, ty + 20, 6, 2, COLORS['water_dark'])

    # Tile 4-7: 草地-泥土边缘
    edges = [
        (4, [(0, 0, 32, 16, COLORS['paper_light']), (0, 16, 32, 16, COLORS['paper_dark'])]),
        (5, [(0, 0, 32, 16, COLORS['paper_dark']), (0, 16, 32, 16, COLORS['paper_light'])]),
        (6, [(0, 0, 16, 32, COLORS['paper_light']), (16, 0, 16, 32, COLORS['paper_dark'])]),
        (7, [(0, 0, 16, 32, COLORS['paper_dark']), (16, 0, 16, 32, COLORS['paper_light'])]),
    ]
    for tile_idx, rects in edges:
        tx, ty = get_tile_xy(tile_idx)
        for x, y, w, h, color in rects:
            img.fill_rect(tx + x, ty + y, w, h, color)

    # Tile 8-11: 草地-水面边缘
    water_edges = [
        (8, [(0, 0, 32, 16, COLORS['paper_light']), (0, 16, 32, 16, COLORS['water'])]),
        (9, [(0, 0, 32, 16, COLORS['water']), (0, 16, 32, 16, COLORS['paper_light'])]),
        (10, [(0, 0, 16, 32, COLORS['paper_light']), (16, 0, 16, 32, COLORS['water'])]),
        (11, [(0, 0, 16, 32, COLORS['water']), (16, 0, 16, 32, COLORS['paper_light'])]),
    ]
    for tile_idx, rects in water_edges:
        tx, ty = get_tile_xy(tile_idx)
        for x, y, w, h, color in rects:
            img.fill_rect(tx + x, ty + y, w, h, color)

    # Tile 12-15: 内角
    inner_corners = [
        (12, [(0, 0, 32, 32, COLORS['paper_dark']), (16, 16, 16, 16, COLORS['paper_light'])]),
        (13, [(0, 0, 32, 32, COLORS['paper_dark']), (0, 16, 16, 16, COLORS['paper_light'])]),
        (14, [(0, 0, 32, 32, COLORS['paper_dark']), (16, 0, 16, 16, COLORS['paper_light'])]),
        (15, [(0, 0, 32, 32, COLORS['paper_dark']), (0, 0, 16, 16, COLORS['paper_light'])]),
    ]
    for tile_idx, rects in inner_corners:
        tx, ty = get_tile_xy(tile_idx)
        for x, y, w, h, color in rects:
            img.fill_rect(tx + x, ty + y, w, h, color)

    # Tile 16-19: 外角
    outer_corners = [
        (16, [(0, 0, 16, 16, COLORS['paper_light']), (16, 0, 16, 32, COLORS['paper_dark']), (0, 16, 16, 16, COLORS['paper_dark'])]),
        (17, [(16, 0, 16, 16, COLORS['paper_light']), (0, 0, 16, 32, COLORS['paper_dark']), (16, 16, 16, 16, COLORS['paper_dark'])]),
        (18, [(0, 16, 16, 16, COLORS['paper_light']), (16, 0, 16, 32, COLORS['paper_dark']), (0, 0, 16, 16, COLORS['paper_dark'])]),
        (19, [(16, 16, 16, 16, COLORS['paper_light']), (0, 0, 16, 32, COLORS['paper_dark']), (16, 0, 16, 16, COLORS['paper_dark'])]),
    ]
    for tile_idx, rects in outer_corners:
        tx, ty = get_tile_xy(tile_idx)
        for x, y, w, h, color in rects:
            img.fill_rect(tx + x, ty + y, w, h, color)

    # Tile 20: 石墙
    tx, ty = get_tile_xy(20)
    img.fill_rect(tx, ty, 32, 32, COLORS['stone'])
    # 砖块纹理
    for y in range(0, 32, 8):
        img.fill_rect(tx, ty + y, 32, 1, COLORS['stone_dark'])
    for x in range(0, 32, 16):
        img.fill_rect(tx + x, ty, 1, 32, COLORS['stone_dark'])

    # Tile 21: 苔藓地面
    tx, ty = get_tile_xy(21)
    img.fill_rect(tx, ty, 32, 32, COLORS['paper_dark'])
    img.fill_rect(tx + 4, ty + 4, 24, 24, COLORS['moss'])
    img.fill_rect(tx + 8, ty + 8, 4, 4, COLORS['moss_dark'])
    img.fill_rect(tx + 20, ty + 16, 6, 6, COLORS['moss_dark'])

    # Tile 22: 阴影/未探索
    tx, ty =