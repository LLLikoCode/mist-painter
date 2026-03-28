#!/usr/bin/env python3
"""
迷雾绘者 (Mist Painter) - 特殊装饰元素 Tileset 生成器
包含：神秘/魔法元素、互动元素、氛围元素
"""

import os
import struct
import zlib
import random
import math

def create_png_chunk(chunk_type, data):
    chunk = chunk_type + data
    crc = zlib.crc32(chunk) & 0xffffffff
    return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)

def create_png_rgba(width, height, pixels):
    signature = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr = create_png_chunk(b'IHDR', ihdr_data)
    raw_data = b''
    for row in range(height):
        raw_data += b'\x00'
        for col in range(width):
            r, g, b, a = pixels[row * width + col]
            raw_data += bytes([r, g, b, a])
    compressed = zlib.compress(raw_data)
    idat = create_png_chunk(b'IDAT', compressed)
    iend = create_png_chunk(b'IEND', b'')
    return signature + ihdr + idat + iend

def create_single_png(width, height, draw_func, seed=42):
    pixels = [(0, 0, 0, 0)] * (width * height)
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = color
    def fill_rect(ox, oy, w, h, color):
        for y in range(oy, min(oy + h, height)):
            for x in range(ox, min(ox + w, width)):
                set_pixel(x, y, color)
    def draw_circle(cx, cy, r, color, filled=False):
        if filled:
            for y in range(-r, r + 1):
                for x in range(-r, r + 1):
                    if x * x + y * y <= r * r:
                        set_pixel(cx + x, cy + y, color)
    def draw_line(x1, y1, x2, y2, color):
        dx, dy = abs(x2 - x1), abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1
        err = dx - dy
        while True:
            set_pixel(x1, y1, color)
            if x1 == x2 and y1 == y2:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x1 += sx
            if e2 < dx:
                err += dx
                y1 += sy
    def draw_rect(ox, oy, w, h, color, filled=True):
        if filled:
            fill_rect(ox, oy, w, h, color)
        else:
            for x in range(ox, ox + w):
                set_pixel(x, oy, color)
                set_pixel(x, oy + h - 1, color)
            for y in range(oy, oy + h):
                set_pixel(ox, y, color)
                set_pixel(ox + w - 1, y, color)
    draw_func(set_pixel, fill_rect, draw_circle, draw_line, draw_rect, seed)
    return create_png_rgba(width, height, pixels)

# 颜色定义 - 魔法/神秘风格
colors = {
    # 水晶系列
    'crystal_core': (180, 220, 255, 255),
    'crystal_light': (140, 190, 240, 255),
    'crystal_medium': (100, 150, 220, 255),
    'crystal_dark': (60, 100, 180, 255),
    'crystal_glow': (200, 230, 255, 180),
    
    # 符文系列
    'rune_gold': (220, 180, 80, 255),
    'rune_gold_light': (255, 220, 120, 255),
    'rune_stone': (80, 75, 70, 255),
    'rune_stone_light': (120, 115, 110, 255),
    
    # 魔法阵
    'magic_purple': (160, 80, 200, 255),
    'magic_purple_light': (200, 120, 240, 255),
    'magic_purple_glow': (180, 100, 220, 150),
    
    # 开关/机关
    'metal_dark': (60, 65, 75, 255),
    'metal_medium': (90, 95, 105, 255),
    'metal_light': (130, 135, 145, 255),
    'switch_red': (200, 60, 60, 255),
    'switch_green': (60, 180, 80, 255),
    'switch_blue': (60, 100, 200, 255),
    
    # 门
    'wood_dark': (100, 75, 55, 255),
    'wood_medium': (140, 105, 75, 255),
    'iron_rust': (100, 85, 75, 255),
    'iron_dark': (70, 75, 85, 255),
    
    # 雾气/氛围
    'mist_white': (220, 225, 230, 200),
    'mist_blue': (180, 190, 210, 180),
    'glow_green': (120, 220, 120, 200),
    'glow_cyan': (100, 220, 200, 200),
    'plant_glow': (150, 255, 150, 220),
    
    # 通用
    'shadow': (30, 30, 35, 120),
    'black': (20, 20, 25, 255),
}

# ==================== 神秘/魔法元素 ====================

def draw_crystal_small(sp, fr, dc, dl, dr, seed):
    """小水晶簇"""
    random.seed(seed)
    base_points = [(14, 28), (16, 28), (18, 28)]
    for bx, by in base_points:
        for x in range(bx-1, bx+2):
            sp(x, by, colors['crystal_dark'])
    # 主水晶
    for y in range(12, 28):
        width = 1 + (28 - y) // 6
        for x in range(16 - width, 16 + width + 1):
            c = colors['crystal_core'] if x == 16 and y < 18 else \
                colors['crystal_light'] if abs(x-16) <= 1 else colors['crystal_medium']
            sp(x, y, c)
    # 侧水晶
    for y in range(16, 26):
        sp(12, y, colors['crystal_medium'])
        sp(20, y, colors['crystal_medium'])
    # 顶部
    sp(16, 11, colors['crystal_core'])
    sp(15, 12, colors['crystal_light'])
    sp(17, 12, colors['crystal_light'])

def draw_crystal_large(sp, fr, dc, dl, dr, seed):
    """大水晶柱"""
    random.seed(seed)
    # 基座
    for x in range(10, 22):
        for y in range(24, 28):
            sp(x, y, colors['crystal_dark'])
    # 主柱体
    for y in range(6, 24):
        width = 2 if y > 15 else 3 if y > 10 else 2
        for x in range(16 - width, 16 + width):
            if y < 10:
                c = colors['crystal_core']
            elif y < 16:
                c = colors['crystal_light'] if (x+y)%2==0 else colors['crystal_medium']
            else:
                c = colors['crystal_medium'] if (x+y)%3!=0 else colors['crystal_dark']
            sp(x, y, c)
    # 顶部尖晶
    for y in range(4, 6):
        for x in range(15, 17):
            sp(x, y, colors['crystal_core'])
    sp(16, 3, colors['crystal_core'])
    # 光晕效果
    sp(10, 15, colors['crystal_glow'])
    sp(22, 15, colors['crystal_glow'])

def draw_rune_stone(sp, fr, dc, dl, dr, seed):
    """符文石"""
    random.seed(seed)
    # 石碑主体
    for y in range(8, 28):
        for x in range(10, 22):
            if (x-16)**2/25 + (y-18)**2/100 <= 1:
                c = colors['rune_stone_light'] if (x+y)%5==0 else colors['rune_stone']
                sp(x, y, c)
    # 符文图案
    rune_y = 14
    # 主符文线
    dl(13, rune_y, 19, rune_y, colors['rune_gold'])
    dl(16, rune_y-3, 16, rune_y+3, colors['rune_gold'])
    dl(14, rune_y-2, 14, rune_y+2, colors['rune_gold_light'])
    dl(18, rune_y-2, 18, rune_y+2, colors['rune_gold_light'])
    # 装饰点
    dc(16, rune_y, 1, colors['rune_gold_light'], True)
    sp(12, rune_y+4, colors['rune_gold'])
    sp(20, rune_y+4, colors['rune_gold'])

def draw_magic_circle_fragment(sp, fr, dc, dl, dr, seed):
    """魔法阵残片"""
    random.seed(seed)
    cx, cy = 16, 20
    # 残破的圆环
    for angle in range(0, 360, 5):
        rad = angle * 3.14159 / 180
        r = 10
        if 60 < angle < 120:  # 缺口
            continue
        x, y = int(cx + r * math.cos(rad)), int(cy + r * math.sin(rad))
        c = colors['magic_purple_light'] if angle % 20 < 10 else colors['magic_purple']
        sp(x, y, c)
    # 内部符文
    dl(12, 18, 20, 18, colors['magic_purple_light'])
    dl(16, 14, 16, 22, colors['magic_purple_light'])
    dl(13, 15, 19, 21, colors['magic_purple'])
    dl(19, 15, 13, 21, colors['magic_purple'])
    # 中心
    dc(cx, cy, 2, colors['magic_purple_glow'], True)
    # 散落的光点
    sp(10, 12, colors['magic_purple_light'])
    sp(22, 14, colors['magic_purple'])
    sp(8, 22, colors['magic_purple_glow'])

# ==================== 互动元素 ====================

def draw_button_off(sp, fr, dc, dl, dr, seed):
    """按钮 - 关闭状态"""
    # 底座
    fr(10, 22, 12, 6, colors['metal_dark'])
    fr(11, 21, 10, 1, colors['metal_medium'])
    # 按钮主体（凹陷）
    fr(12, 23, 8, 4, colors['metal_dark'])
    # 红色指示灯
    dc(16, 25, 2, colors['switch_red'], True)

def draw_button_on(sp, fr, dc, dl, dr, seed):
    """按钮 - 开启状态"""
    # 底座
    fr(10, 22, 12, 6, colors['metal_dark'])
    fr(11, 20, 10, 2, colors['metal_medium'])
    #