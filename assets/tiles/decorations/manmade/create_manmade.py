#!/usr/bin/env python3
"""
迷雾绘者 - 人造装饰元素生成器
32x32像素，纯Python实现
"""

import os
import struct
import zlib

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

def create_img(draw_func):
    pixels = [(0, 0, 0, 0)] * (32 * 32)
    def sp(x, y, c):
        if 0 <= x < 32 and 0 <= y < 32:
            pixels[y * 32 + x] = c
    def rect(x1, y1, x2, y2, c):
        for y in range(y1, y2):
            for x in range(x1, x2):
                sp(x, y, c)
    draw_func(sp, rect)
    return create_png_rgba(32, 32, pixels)

# 颜色定义
C = {
    'wood': (160, 120, 90, 255), 'wood_dark': (120, 85, 60, 255),
    'wood_light': (194, 162, 128, 255), 'iron': (80, 80, 90, 255),
    'iron_dark': (50, 50, 60, 255), 'metal': (140, 140, 150, 255),
    'metal_dark': (100, 100, 110, 255), 'gold': (200, 170, 90, 255),
    'stone': (160, 155, 145, 255), 'stone_dark': (120, 115, 105, 255),
    'red': (180, 80, 70, 255), 'blue': (70, 100, 150, 255),
    'yellow': (255, 220, 150, 200), 'black': (40, 40, 45, 255),
    'white': (240, 240, 240, 255), 'shadow': (30, 30, 30, 100),
}

# ============ 路灯 ============
def lamp_classical(sp, rect):
    rect(15, 12, 17, 30, C['iron'])  # 灯柱
    rect(13, 28, 19, 31, C['iron_dark'])  # 底座
    rect(12, 8, 20, 12, C['iron'])  # 灯罩框架
    rect(13, 9, 19, 11, C['yellow'])  # 灯光
    sp(16, 4, C['gold'])  # 顶部装饰

def lamp_modern(sp, rect):
    rect(15, 10, 17, 30, C['metal'])  # 灯柱
    rect(14, 28, 18, 31, C['metal_dark'])  # 底座
    rect(11, 6, 21, 10, C['metal_dark'])  # 灯头
    rect(13, 7, 19, 9, C['yellow'])  # 灯光

# ============ 长椅 ============
def bench_horizontal(sp, rect):
    rect(4, 20, 28, 24, C['wood_dark'])  # 座椅
    rect(4, 16, 28, 19, C['wood'])  # 靠背
    rect(6, 24, 8, 30, C['iron'])  # 左腿
    rect(24, 24, 26, 30, C['iron'])  # 右腿

def bench_vertical(sp, rect):
    rect(10, 6, 14, 26, C['wood_dark'])  # 座椅
    rect(14, 6, 17, 26, C['wood'])  # 靠背
    rect(10, 8, 14, 10, C['iron'])  # 上支撑
    rect(10, 22, 14, 24, C['iron'])  # 下支撑

# ============ 标牌 ============
def sign_arrow(sp, rect):
    rect(8, 14, 20, 18, C['wood'])  # 牌身
    rect(20, 12, 26, 20, C['wood'])  # 箭头
    rect(14, 18, 16, 28, C['wood_dark'])  # 支柱

def sign_blank(sp, rect):
    rect(6, 10, 26, 18, C['wood'])  # 牌身
    rect(14, 18, 18, 28, C['wood_dark'])  # 支柱
    rect(8, 12, 24, 16, C['white'])  # 空白区域

def sign_warning(sp, rect):
    rect(6, 10, 26, 18, C['wood'])
    rect(14, 18, 18, 28, C['wood_dark'])
    rect(8, 12, 24, 16, C['yellow'])
    sp(16, 13, C['black'])  # 警告符号

# ============ 栅栏 ============
def fence_wood(sp, rect):
    for x in [4, 14, 24]:
        rect(x, 10, x+3, 28, C['wood'])  # 竖条
    rect(2, 14, 30, 16, C['wood_dark'])  # 横条上
    rect(2, 22, 30, 24, C['wood_dark'])  # 横条下

def fence_iron(sp, rect):
    for x in [6, 16, 26]:
        rect(x, 8, x+2, 28, C['iron'])  # 竖条
    rect(4, 12, 30, 14, C['iron_dark'])  # 横条上
    rect(4, 24, 30, 26, C['iron_dark'])  # 横条下

# ============ 井/水桶 ============
def well(sp, rect):
    rect(8, 16, 24, 26, C['stone'])  # 井身
    rect(6, 12, 26, 16, C['stone_dark'])  # 井沿
    rect(14, 6, 18, 12, C['wood'])  # 支架
    rect(10, 8, 22, 10, C['wood_dark'])  # 横梁

def bucket(sp, rect):
    rect(12, 18, 20, 26, C['wood'])  # 桶身
    rect(12, 16, 20, 18, C['wood_dark'])  # 桶沿
    rect(10, 10, 12, 18, C['iron'])  # 提手左
    rect(20, 10, 22, 18, C['iron'])  # 提手右
    rect(10, 8, 22, 10, C['iron'])  # 提手顶

# 生成所有元素
elements = [
    ('lamp_classical', lamp_classical), ('lamp_modern', lamp_modern),
    ('bench_horizontal', bench_horizontal), ('bench_vertical', bench_vertical),
    ('sign_arrow', sign_arrow), ('sign_blank', sign_blank), ('sign_warning', sign_warning),
    ('fence_wood', fence_wood), ('fence_iron', fence_iron),
    ('well', well), ('bucket', bucket),
]

output_dir = '/home/admin/.openclaw/workspace/assets/tiles/decorations/manmade'
os.makedirs(output_dir, exist_ok=True)

for name, func in elements:
    png_data = create_img(func)
    with open(f'{output_dir}/manmade_{name}.png', 'wb') as f:
        f.write(png_data)
    print(f'Generated: manmade_{name}.png')

print(f'\nTotal: {len(elements)} manmade decoration elements generated.')
