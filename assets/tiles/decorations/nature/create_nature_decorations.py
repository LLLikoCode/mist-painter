#!/usr/bin/env python3
"""
迷雾绘者 (Mist Painter) - 自然装饰元素 Tileset 生成器
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
    draw_func(set_pixel, fill_rect, draw_circle, seed)
    return create_png_rgba(width, height, pixels)

colors = {
    'grass_light': (140, 170, 100, 255), 'grass_medium': (100, 140, 80, 255),
    'grass_dark': (70, 100, 55, 255), 'flower_red': (180, 90, 90, 255),
    'flower_yellow': (200, 170, 80, 255), 'flower_blue': (100, 130, 170, 255),
    'flower_white': (235, 230, 220, 255), 'stone_light': (170, 165, 155, 255),
    'stone_medium': (130, 125, 115, 255), 'stone_dark': (90, 85, 80, 255),
    'stone_shadow': (60, 58, 55, 180), 'trunk': (110, 90, 70, 255),
    'trunk_dark': (80, 65, 50, 255), 'leaves_light': (120, 160, 90, 255),
    'leaves_medium': (85, 130, 70, 255), 'leaves_dark': (55, 90, 50, 255),
    'leaves_brown': (140, 120, 80, 255), 'shadow': (30, 30, 30, 120),
}

def draw_grass_1(sp, fr, dc, seed):
    random.seed(seed)
    for i in range(6):
        x, h = 8 + i*4, 8 + random.randint(0,5)
        c = colors['grass_medium'] if i%2==0 else colors['grass_light']
        for y in range(28-h, 28):
            sp(x, y, c); sp(x+1, y, c)

def draw_grass_2(sp, fr, dc, seed):
    random.seed(seed)
    for i in range(9):
        x, h = 6 + i*3, 6 + random.randint(0,6)
        c = colors['grass_dark'] if random.random()>0.5 else colors['grass_medium']
        for j in range(h):
            y, off = 27-j, j//3 if i%2==0 else -(j//3)
            sp(x+off, y, c)

def draw_grass_3(sp, fr, dc, seed):
    random.seed(seed)
    for x, y in [(10,26),(16,24),(22,27),(8,28),(24,25),(14,28)]:
        h = 5 + random.randint(0,4)
        for j in range(h):
            sp(x, y-j, colors['grass_light'])

def draw_grass_4(sp, fr, dc, seed):
    random.seed(seed)
    for i in range(4):
        x, h = 10 + i*5, 12 + random.randint(0,6)
        for y in range(28-h, 28): sp(x, y, colors['grass_dark'])

def draw_flower_red(sp, fr, dc, seed):
    cx, cy = 16, 18
    for y in range(21, 30): sp(cx, y, colors['grass_dark'])
    for px, py in [(cx,14),(cx+4,17),(cx+3,21),(cx-3,21),(cx-4,17)]:
        dc(px, py, 2, colors['flower_red'], True)
    dc(cx, cy, 2, colors['flower_yellow'], True)

def draw_flower_yellow(sp, fr, dc, seed):
    cx, cy = 16, 20
    for y in range(22, 30): sp(cx, y, colors['grass_dark'])
    for i in range(8):
        a = i*45*3.14159/180
        dc(int(cx+4*math.cos(a)), int(cy+4*math.sin(a)), 2, colors['flower_yellow'], True)
    dc(cx, cy, 2, colors['flower_white'], True)

def draw_flower_blue(sp, fr, dc, seed):
    cx, cy = 16, 19
    for y in range(22, 30): sp(cx, y, colors['grass_dark'])
    for i in range(6):
        a = i*60*3.14159/180
        dc(int(cx+5*math.cos(a)), int(cy+5*math.sin(a)), 3, colors['flower_blue'], True)
    dc(cx, cy, 2, colors['flower_white'], True)

def draw_stone_small(sp, fr, dc, seed):
    for y in range(23, 29):
        for x in range(12, 20):
            if (x-16)**2/16 + (y-26)**2/9 <= 1:
                c = colors['stone_light'] if (x+y)%3==0 else colors['stone_medium']
                sp(x, y, c)

def draw_stone_medium(sp, fr, dc, seed):
    for y in range(20, 30):
        for x in range(10, 22):
            if (x-16)**2/36 + (y-25)**2/25 <= 1:
                c = colors['stone_medium'] if (x+y)%4<2 else colors['stone_dark']
                sp(x, y, c)

def draw_stone_large(sp, fr, dc, seed):
    for y in range(16, 30):
        for x in range(8, 24):
            if (x-16)**2/64 + (y-23)**2/49 <= 1:
                c = colors['stone_light'] if (x+y)%5==0 else (colors['stone_medium'] if (x+y)%3==0 else colors['stone_dark'])
                sp(x, y, c)

def draw_tree_small(sp, fr, dc, seed):
    for y in range(20, 30):
        for x in range(14, 18):
            sp(x, y, colors['trunk'])
    for y in range(8, 22):
        for x in range(8, 24):
            if (x-16)**2/36 + (y-15)**2/25 <= 1:
                c = colors['leaves_light'] if (x+y)%4==0 else (colors['leaves_medium'] if (x+y)%3==0 else colors['leaves_dark'])
                sp(x, y, c)

def draw_tree_bush(sp, fr, dc, seed):
    for y in range(22, 30):
        for x in range(13, 19):
            sp(x, y, colors['trunk_dark'])
    for y in range(12, 24):
        for x in range(8, 24):
            if (x-16)**2/49 + (y-18)**2/25 <= 1:
                c = colors['leaves_medium'] if (x+y)%3==0 else colors['leaves_dark']
                sp(x, y, c)

def draw_tree_dead(sp, fr, dc, seed):
    for y in range(18, 30):
        for x in range(14, 18):
            sp(x, y, colors['trunk_dark'])
    for y in range(6, 20):
        for x in range(10, 22):
            if abs(x-16) + abs(y-14) < 6:
                sp(x, y, colors['leaves_brown'])

# Main
elements = [
    ('grass_1', draw_grass_1), ('grass_2', draw_grass_2), ('grass_3', draw_grass_3), ('grass_4', draw_grass_4),
    ('flower_red', draw_flower_red), ('flower_yellow', draw_flower_yellow), ('flower_blue', draw_flower_blue),
    ('stone_small', draw_stone_small), ('stone_medium', draw_stone_medium), ('stone_large', draw_stone_large),
    ('tree_small', draw_tree_small), ('tree_bush', draw_tree_bush), ('tree_dead', draw_tree_dead),
]

output_dir = '/home/admin/.openclaw/workspace/assets/tiles/decorations/nature'
os.makedirs(output_dir, exist_ok=True)

for name, func in elements:
    png_data = create_single_png(32, 32, func, seed=42)
    with open(f'{output_dir}/nature_{name}.png', 'wb') as f:
        f.write(png_data)
    print(f'Generated: nature_{name}.png')

print(f'\nTotal: {len(elements)} nature decoration elements generated.')
