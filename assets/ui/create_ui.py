#!/usr/bin/env python3
"""
迷雾绘者 - UI元素生成器
32x32像素按钮，多种状态
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

def create_img(w, h, draw_func):
    pixels = [(0, 0, 0, 0)] * (w * h)
    def sp(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            pixels[y * w + x] = c
    def rect(x1, y1, x2, y2, c):
        for y in range(y1, y2):
            for x in range(x1, x2):
                sp(x, y, c)
    def border(x1, y1, x2, y2, c, t=1):
        for y in range(y1, y2):
            for x in range(x1, x2):
                if x < x1+t or x >= x2-t or y < y1+t or y >= y2-t:
                    sp(x, y, c)
    draw_func(sp, rect, border)
    return create_png_rgba(w, h, pixels)

# 颜色定义
C = {
    'paper': (232, 220, 200, 255), 'paper_dark': (200, 185, 165, 255),
    'paper_light': (245, 235, 220, 255), 'ink': (61, 40, 23, 255),
    'ink_light': (100, 80, 60, 255), 'red': (180, 80, 70, 255),
    'red_dark': (140, 60, 50, 255), 'green': (80, 130, 80, 255),
    'gold': (200, 170, 90, 255), 'shadow': (30, 30, 30, 80),
    'white': (255, 255, 255, 200), 'black': (40, 40, 45, 255),
    'transparent': (0, 0, 0, 0),
}

# ============ 按钮 ============
def btn_normal(sp, rect, border):
    rect(0, 0, 32, 32, C['paper'])
    border(0, 0, 32, 32, C['ink'], 2)
    # 文字区域示意
    rect(8, 12, 24, 20, C['ink_light'])

def btn_hover(sp, rect, border):
    rect(0, 0, 32, 32, C['paper_light'])
    border(0, 0, 32, 32, C['gold'], 2)
    rect(8, 12, 24, 20, C['ink'])

def btn_pressed(sp, rect, border):
    rect(0, 0, 32, 32, C['paper_dark'])
    border(2, 2, 30, 30, C['ink'], 2)
    rect(10, 14, 26, 22, C['ink_light'])

def btn_disabled(sp, rect, border):
    rect(0, 0, 32, 32, C['paper_dark'])
    border(0, 0, 32, 32, C['ink_light'], 1)
    rect(8, 12, 24, 20, C['ink_light'])

# ============ 面板 ============
def panel_frame(sp, rect, border):
    rect(0, 0, 32, 32, C['paper'])
    border(0, 0, 32, 32, C['ink'], 3)
    border(3, 3, 29, 29, C['paper_light'], 1)

def panel_dark(sp, rect, border):
    rect(0, 0, 32, 32, C['paper_dark'])
    border(0, 0, 32, 32, C['ink'], 2)

# ============ 进度条 ============
def bar_empty(sp, rect, border):
    rect(0, 10, 32, 22, C['paper_dark'])
    border(0, 10, 32, 22, C['ink'], 1)

def bar_full(sp, rect, border):
    rect(0, 10, 32, 22, C['paper_dark'])
    rect(2, 12, 30, 20, C['green'])
    border(0, 10, 32, 22, C['ink'], 1)

def bar_mist(sp, rect, border):
    rect(0, 10, 32, 22, C['paper_dark'])
    rect(2, 12, 20, 20, C['gold'])
    border(0, 10, 32, 22, C['ink'], 1)

# ============ 图标 ============
def icon_settings(sp, rect, border):
    # 齿轮形状
    for y in range(8, 24):
        for x in range(8, 24):
            if ((x-16)**2 + (y-16)**2) < 36:
                sp(x, y, C['ink'])
    rect(14, 14, 18, 18, C['paper'])

def icon_back(sp, rect, border):
    # 左箭头
    for i in range(8):
        sp(8+i, 16-i, C['ink'])
        sp(8+i, 16+i, C['ink'])
    rect(8, 14, 20, 18, C['ink'])

def icon_close(sp, rect, border):
    # X形状
    for i in range(12):
        sp(8+i, 8+i, C['red'])
        sp(19-i, 8+i, C['red'])

def icon_menu(sp, rect, border):
    # 三条横线
    for y in [10, 16, 22]:
        rect(6, y, 26, y+3, C['ink'])

# ============ 复选框 ============
def checkbox_empty(sp, rect, border):
    rect(8, 8, 24, 24, C['paper'])
    border(8, 8, 24, 24, C['ink'], 2)

def checkbox_checked(sp, rect, border):
    rect(8, 8, 24, 24, C['paper'])
    border(8, 8, 24, 24, C['ink'], 2)
    # 对勾
    for i in range(6):
        sp(12+i, 18-i, C['green'])
    for i in range(4):
        sp(17+i, 12+i, C['green'])

# ============ 滑块 ============
def slider_track(sp, rect, border):
    rect(4, 14, 28, 18, C['paper_dark'])
    border(4, 14, 28, 18, C['ink'], 1)

def slider_handle(sp, rect, border):
    rect(12, 10, 20, 22, C['paper'])
    border(12, 10, 20, 22, C['ink'], 2)

# 生成所有UI元素
elements_32 = [
    ('button_normal', btn_normal, 32), ('button_hover', btn_hover, 32),
    ('button_pressed', btn_pressed, 32), ('button_disabled', btn_disabled, 32),
    ('panel_frame', panel_frame, 32), ('panel_dark', panel_dark, 32),
    ('bar_empty', bar_empty, 32), ('bar_full', bar_full, 32),
    ('bar_mist', bar_mist, 32), ('icon_settings', icon_settings, 32),
    ('icon_back', icon_back, 32), ('icon_close', icon_close, 32),
    ('icon_menu', icon_menu, 32), ('checkbox_empty', checkbox_empty, 32),
    ('checkbox_checked', checkbox_checked, 32), ('slider_track', slider_track, 32),
    ('slider_handle', slider_handle, 32),
]

output_dir = '/home/admin/.openclaw/workspace/assets/ui'
os.makedirs(output_dir, exist_ok=True)

for name, func, size in elements_32:
    png_data = create_img(size, size, func)
    with open(f'{output_dir}/ui_{name}.png', 'wb') as f:
        f.write(png_data)
    print(f'Generated: ui_{name}.png ({size}x{size})')

print(f'\nTotal: {len(elements_32)} UI elements generated.')
