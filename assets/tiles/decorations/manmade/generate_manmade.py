#!/usr/bin/env python3
"""
生成人造装饰元素tileset
迷雾绘者项目 - 32x32像素风格
复古纸张色调palette
"""

from PIL import Image

# 复古纸张色调palette
COLORS = {
    'transparent': (0, 0, 0, 0),
    'paper_light': (245, 235, 220, 255),
    'paper': (232, 220, 200, 255),
    'paper_dark': (200, 185, 165, 255),
    'wood_light': (194, 162, 128, 255),
    'wood': (160, 120, 90, 255),
    'wood_dark': (120, 85, 60, 255),
    'metal_light': (180, 180, 190, 255),
    'metal': (140, 140, 150, 255),
    'metal_dark': (100, 100, 110, 255),
    'iron': (80, 80, 90, 255),
    'iron_dark': (50, 50, 60, 255),
    'gold': (200, 170, 90, 255),
    'gold_dark': (160, 130, 60, 255),
    'stone': (160, 155, 145, 255),
    'stone_dark': (120, 115, 105, 255),
    'red': (180, 80, 70, 255),
    'blue': (70, 100, 150, 255),
    'green': (80, 130, 80, 255),
    'black': (40, 40, 45, 255),
    'yellow': (220, 200, 100, 255),
    'yellow_dark': (180, 160, 60, 255),
}

def create_image():
    return Image.new('RGBA', (32, 32), COLORS['transparent'])

def put_pixel(img, x, y, color):
    if 0 <= x < 32 and 0 <= y < 32:
        img.putpixel((x, y), color)

def draw_rect(img, x1, y1, x2, y2, color):
    for y in range(y1, y2):
        for x in range(x1, x2):
            put_pixel(img, x, y, color)

def draw_line(img, x1, y1, x2, y2, color):
    dx = abs(x2 - x1)
    dy = abs(y2 - y1)
    sx = 1 if x1 < x2 else -1
    sy = 1 if y1 < y2 else -1
    err = dx - dy
    while True:
        put_pixel(img, x1, y1, color)
        if x1 == x2 and y1 == y2:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x1 += sx
        if e2 < dx:
            err += dx
            y1 += sy

# ============ 路灯/街灯 ============

def create_lamp_classical():
    img = create_image()
    # 灯柱
    draw_rect(img, 15, 12, 17, 30, COLORS['iron'])
    draw_rect(img, 14, 14, 15, 16, COLORS['iron_dark'])
    draw_rect(img, 17, 14, 18, 16, COLORS['iron_dark'])
    # 底座
    draw_rect(img, 13, 28, 19, 31, COLORS['iron_dark'])
    draw_rect(img, 14, 27, 18, 28, COLORS['iron'])
    # 灯罩框架
    draw_rect(img, 12, 8, 20, 12, COLORS['iron'])
    draw_rect(img, 11, 7, 21, 8, COLORS['iron_dark'])
    # 灯罩玻璃
    draw_rect(img, 13, 9, 19, 11, (255, 220, 150, 200))
    # 顶部装饰
    draw_line(img, 15, 7, 16, 4, COLORS['iron'])
    put_pixel(img, 16, 4, COLORS['gold'])
    put_pixel(img, 12, 12, COLORS['gold'])
    put_pixel(img, 19, 12, COLORS['gold'])
    return img

def create_lamp_modern():
    img = create_image()
    # 灯柱
    draw_rect(img, 15, 10, 17, 30, COLORS['metal'])
    put_pixel(img, 16, 15, COLORS['metal_light'])
    put_pixel(img, 16, 20, COLORS['metal_light'])
    put_pixel(img, 16, 25, COLORS['metal_light'])
    # 底座
    draw_rect(img, 14, 28, 18, 31, COLORS['metal_dark'])
    # 灯头
    draw_rect(img, 11, 6, 21, 10, COLORS['metal_dark'])
    draw_rect(img, 12, 7, 20, 9, COLORS['metal'])
    # LED光源
    draw_rect(img, 13, 8, 19, 9, (240, 250, 255, 220))
    # 太阳能板
    draw_rect(img, 12, 4, 20, 6, COLORS['iron_dark'])
    put_pixel(img, 14, 5, COLORS['metal_dark'])
    put_pixel(img, 17, 5, COLORS['metal_dark'])
    return img

# ============ 长椅 ============

def create_bench_horizontal():
    img = create_image()
    # 椅腿
    draw_rect(img, 4, 24, 6, 30, COLORS['iron_dark'])
    draw_rect(img, 26, 24, 28, 30, COLORS['iron_dark'])
    draw_rect(img, 4, 20, 5, 24, COLORS['iron'])
    draw_rect(img, 27, 20, 28, 24, COLORS['iron'])
    # 座椅板
    draw_rect(img, 3, 22, 29, 24, COLORS['wood'])
    draw_rect(img, 3, 20, 29, 22, COLORS['wood_light'])
    for x in range(5, 28, 4):
        put_pixel(img, x, 21, COLORS['wood_dark'])
        put_pixel(img, x, 23, COLORS['wood_dark'])
    # 靠背支架
    draw_rect(img, 4, 12, 5, 20, COLORS['iron'])
    draw_rect(img, 27, 12, 28, 20, COLORS['iron'])
    # 靠背板
    draw_rect(img, 3, 14, 29, 16, COLORS['wood'])
    draw_rect(img, 3, 11, 29, 14, COLORS['wood_light'])
    for x in range(5, 28, 4):
        put_pixel(img, x, 12, COLORS['wood_dark'])
        put_pixel(img, x, 15, COLORS['wood_dark'])
    return img

def create_bench_vertical():
    img = create_image()
    # 椅腿
    draw_rect(img, 8, 24, 10, 30, COLORS['iron_dark'])
    draw_rect(img, 22, 24, 24, 30, COLORS['iron_dark'])
    # 座椅板
    draw_rect(img, 6, 22, 26, 24, COLORS['wood'])
    draw_rect(img, 6, 20, 26, 22, COLORS['wood_light'])
    put_pixel(img, 7, 21, COLORS['wood_dark'])
    put_pixel(img, 25, 21, COLORS['wood_dark'])
    # 靠背支架
    draw_rect(img, 8, 12, 10, 20, COLORS['iron'])
    draw_rect(img, 22, 12, 24, 20, COLORS['iron'])
    # 靠背板
    draw_rect(img, 6, 14, 26, 16, COLORS['wood'])
    draw_rect(img, 6, 11, 26, 14, COLORS['wood_light'])
    draw_rect(img, 7, 9, 25, 11, COLORS['wood'])
    return img

# ============ 标牌/指示牌 ============

def create_sign_wooden():
    img = create_image()
    # 立柱
    draw_rect(img, 15, 18, 17, 31, COLORS['wood_dark'])
    # 标牌板
    draw_rect(img, 4, 8, 28, 18, COLORS['wood'])
    draw_rect(img, 5, 9, 27, 17, COLORS['wood_light'])
    # 边框
    draw_rect(img, 4, 8, 28, 9, COLORS['wood_dark'])
    draw_rect(img, 4, 17, 28, 18, COLORS['wood_dark'])
    draw_rect(img, 4, 8, 5, 18, COLORS['wood_dark'])
    draw_rect(img, 27, 8, 28, 18, COLORS['wood_dark'])
    # 木纹
    for x in range(7, 26, 3):
        put_pixel(img, x, 11, COLORS['wood_dark'])
        put_pixel(img, x + 1, 14, COLORS['wood_dark'])
    # 箭头
    draw_line(img, 10, 13, 18, 13, COLORS['wood_dark'])
    put_pixel(img, 17, 12, COLORS['wood_dark'])
    put_pixel(img, 17, 14, COLORS['wood_dark'])
    put_pixel(img, 18, 11, COLORS['wood_dark'])
    put_pixel(img, 18, 15, COLORS['wood_dark'])
    return img

def create_sign_metal():
    img = create_image()
    # 立柱
    draw_rect(img, 15, 16, 17, 31, COLORS['metal_dark'])
    put_pixel(img, 16, 20, COLORS['metal_light'])
    put_pixel(img, 16, 26, COLORS['metal_light'])
    # 标牌板
    draw_rect(img, 6, 6, 26, 16, COLORS['metal'])
    draw_rect(img, 7, 7, 25, 15, COLORS['metal_light'])
    # 边框
    draw_rect(img, 6, 6, 26, 7, COLORS['metal_dark'])
    draw_rect(img, 6, 15, 26, 16, COLORS['metal_dark'])
    draw_rect(img, 6, 6, 7, 16, COLORS['metal_dark'])
    draw_rect(img, 25, 6, 26, 16, COLORS['metal_dark'])
    # 文字区域
    draw_rect(img, 10, 9, 14, 13, COLORS['metal_dark'])
    draw_line(img, 16, 9, 22, 9, COLORS['metal_dark'])
    draw_line(img, 16, 11, 21, 11, COLORS['metal_dark'])
    draw_line(img, 16, 13, 20, 13, COLORS['metal_dark'])
    return img

def create_sign_warning():
    img = create_image()
    # 立柱
    draw_rect(img, 15, 18, 17, 31, COLORS['wood_dark'])
    # 三角形标牌 - 黄色警告色
    for y in range(4, 20):
        width = (y - 4) // 2
        for x in range(16 - width, 16 + width + 1):
            if y == 4 or y == 19 or x == 16 - width or x == 16 + width:
                put_pixel(img, x, y, COLORS['yellow_dark'])
            else:
                put_pixel(img, x, y, COLORS['yellow'])
    # 感叹号
    draw_rect(img, 15, 8, 17, 13, COLORS['black'])
    draw_rect(img, 15, 15, 17, 17, COLORS['black'])
    return img

# ============ 栅栏/围栏 ============

def create_fence_wooden():
    img = create_image()
    # 木栅栏 - 垂直木板风格
    for x in [4, 12, 20, 28]:
        # 立柱
        draw_rect(img, x - 1, 8, x + 2, 28, COLORS['wood'])
        draw_rect(img, x, 8, x + 1, 28, COLORS['wood_light'])
        # 顶部尖角
        put_pixel(img, x, 7, COLORS['wood'])
        put_pixel(img, x + 1, 7, COLORS['wood'])
        put_pixel(img, x, 6, COLORS['wood_dark'])
    # 横栏
    draw_rect(img, 2, 14, 30, 17, COLORS['wood_dark'])
    draw_rect(img, 2, 22, 30, 25, COLORS['wood_dark'])
    # 横栏高光
    draw_rect(img, 3, 15, 29, 16, COLORS['wood'])
    draw_rect(img, 3, 23, 29, 24, COLORS['wood'])
    return img

def create_fence_iron():
    img = create_image()
    # 铁艺栅栏 - 装饰性花纹
    for x in [6, 16, 26]:
        # 立柱
        draw_rect(img, x - 1, 10, x + 2, 30, COLORS['iron_dark'])
        put_pixel(img, x, 15, COLORS['metal_light'])
        put_pixel(img, x, 22, COLORS['metal_light'])
        # 顶部装饰球
        draw_rect(img, x - 1, 6, x + 2, 10, COLORS['iron'])
        put_pixel(img, x, 5, COLORS['gold'])
    # 横栏
    draw_rect(img, 2, 16, 30, 18, COLORS['iron'])
    draw_rect(img, 2, 24, 30, 26, COLORS['iron'])
    # 装饰花纹 - 弧线
    for i, x in enumerate([6, 16, 26]):
        if i < 2:
            next_x = [6, 16, 26][i + 1]
            mid_x = (x + next_x) // 2
            # 弧形装饰
            put_pixel(img, mid_x, 12, COLORS['iron'])
            put_pixel(img, mid_x - 1, 13, COLORS['iron'])
            put_pixel(img, mid_x + 1, 13, COLORS['iron'])
            put_pixel(img, mid_x - 2, 14, COLORS['iron'])
            put_pixel(img, mid_x + 2, 14, COLORS['iron'])
    return img

# ============ 井/水桶 ============

def create_well():
    img = create_image()
    # 井台（圆形石制）
    for y in range(20, 30):
        for x in range(6, 26):
            dist = ((x - 16) ** 2 + (y - 25) ** 2) ** 0.5
            if 7 <= dist <= 9:
                put_pixel(img, x, y, COLORS['stone_dark'])
            elif dist < 7:
                put_pixel(img, x, y, COLORS['stone'])
    # 井口（黑色空洞）
    for y in range(22, 28):
        for x in range(12, 20):
            dist = ((x - 16) ** 2 + (y - 25) ** 2) ** 0.5
            if dist < 4:
                put_pixel(img, x, y, COLORS['black'])
    # 井架支柱
    draw_rect(img, 8, 8, 10, 22, COLORS['wood_dark'])
    draw_rect(img, 22, 8, 24, 22, COLORS['wood_dark'])
    # 横梁
    draw_rect(img, 6, 8, 26, 11, COLORS['wood'])
    draw_rect(img, 7, 9, 25, 10, COLORS['wood_light'])
    # 绞盘
    draw_rect(img, 14, 10, 18, 14, COLORS['wood_dark'])
    put_pixel(img, 16, 12, COLORS['wood_light'])
    # 绳索
    draw_line(img, 16, 14, 16, 22, COLORS['wood_dark'])
    # 水桶（悬挂）
    draw_rect(img, 14, 22, 18, 26, COLORS['wood'])
    draw_rect(img, 15, 23, 17, 25, COLORS['wood_light'])
    return img

def create_bucket():
    img = create_image()
    # 水桶主体
    draw_rect(img, 10, 14, 22, 26, COLORS['wood'])
    draw_rect(img, 11, 15, 21, 25, COLORS['wood_light'])
    # 水桶边框
    draw_rect(img, 10, 14, 22, 16, COLORS['wood_dark'])
    draw_rect(img, 10, 24, 22, 26, COLORS['wood_dark'])
    # 提手（金属）
    draw_line(img, 10, 14, 8, 8, COLORS['metal_dark'])
    draw_line(img, 22, 14, 24, 8, COLORS['metal_dark'])
    draw_line(img, 8, 8, 24, 8, COLORS['metal_dark'])
    put_pixel(img, 16, 8, COLORS['metal'])
    # 水（蓝色）
    draw_rect(img, 12, 17, 20, 20, COLORS['blue'])
    put_pixel(img, 13, 18, (100, 140, 200, 255))
    put_pixel(img, 18, 19, (100, 140, 200, 255))
    return img

# ============ 主程序 ============

def main():
    assets = [
        ('manmade_lamp_classical.png', create_lamp_classical),
        ('manmade_lamp_modern.png', create_lamp_modern),
        ('manmade_bench_horizontal.png', create_bench_horizontal),
        ('manmade_bench_vertical.png', create_bench_vertical),
        ('manmade_sign_wooden.png', create_sign_wooden),
        ('manmade_sign_metal.png', create_sign_metal),
        ('manmade_sign_warning.png', create_sign_warning),
        ('manmade_fence_wooden.png', create_fence_wooden),
        ('manmade_fence_iron.png', create_fence_iron),
        ('manmade_well.png', create_well),
        ('manmade_bucket.png', create_bucket),
    ]
    
    for filename, func in assets:
        img = func()
        img.save(filename)
        print(f"Generated: {filename}")

if __name__ == '__main__':
    main()
