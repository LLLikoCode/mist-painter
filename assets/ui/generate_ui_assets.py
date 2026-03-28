#!/usr/bin/env python3
"""
迷雾绘者 UI元素资源生成器
生成像素风格的UI元素，使用复古纸张色调
"""

from PIL import Image, ImageDraw
import os

# 色彩调色板 - 羊皮纸风格
COLORS = {
    'paper_light': (245, 240, 225),    # #f5f0e1 - 羊皮纸浅
    'paper_medium': (232, 220, 196),   # #e8dcc4 - 羊皮纸中
    'paper_dark': (212, 196, 168),     # #d4c4a8 - 羊皮纸深
    'paper_aged': (201, 184, 150),     # #c9b896 - 羊皮纸旧
    'ink_black': (26, 26, 26),         # #1a1a1a - 墨黑
    'ink_dark': (45, 45, 45),          # #2d2d2d - 墨深
    'ink_faded': (90, 90, 90),         # #5a5a5a - 墨淡
    'ink_brown': (61, 40, 23),         # #3d2817 - 墨褐
    'accent_gold': (201, 162, 39),     # #c9a227 - 金色
    'accent_red': (139, 58, 58),       # #8b3a3a - 红色
    'accent_green': (74, 124, 89),     # #4a7c59 - 绿色
    'accent_blue': (74, 111, 165),     # #4a6fa5 - 蓝色
    'transparent': (0, 0, 0, 0),
}

def create_image(width, height, transparent=True):
    """创建新图像"""
    if transparent:
        return Image.new('RGBA', (width, height), COLORS['transparent'])
    return Image.new('RGBA', (width, height), COLORS['paper_light'])

def generate_button_normal():
    """生成普通状态按钮 - 96x32像素"""
    img = create_image(96, 32)
    draw = ImageDraw.Draw(img)
    
    # 羊皮纸背景
    draw.rectangle([2, 2, 93, 29], fill=COLORS['paper_medium'])
    
    # 像素风格边框
    draw.rectangle([0, 0, 95, 31], outline=COLORS['ink_brown'], width=2)
    
    # 内部装饰线
    draw.rectangle([4, 4, 91, 27], outline=COLORS['paper_aged'], width=1)
    
    return img

def generate_button_hover():
    """生成悬停状态按钮"""
    img = create_image(96, 32)
    draw = ImageDraw.Draw(img)
    
    # 高亮背景
    draw.rectangle([2, 2, 93, 29], fill=COLORS['paper_light'])
    
    # 金色边框
    draw.rectangle([0, 0, 95, 31], outline=COLORS['accent_gold'], width=2)
    
    # 内部装饰线
    draw.rectangle([4, 4, 91, 27], outline=COLORS['accent_gold'], width=1)
    
    # 角落装饰
    draw.rectangle([2, 2, 5, 5], fill=COLORS['accent_gold'])
    draw.rectangle([90, 2, 93, 5], fill=COLORS['accent_gold'])
    draw.rectangle([2, 26, 5, 29], fill=COLORS['accent_gold'])
    draw.rectangle([90, 26, 93, 29], fill=COLORS['accent_gold'])
    
    return img

def generate_button_pressed():
    """生成按下状态按钮"""
    img = create_image(96, 32)
    draw = ImageDraw.Draw(img)
    
    # 暗色背景（按下效果）
    draw.rectangle([2, 2, 93, 29], fill=COLORS['paper_dark'])
    
    # 深色边框
    draw.rectangle([0, 0, 95, 31], outline=COLORS['ink_dark'], width=2)
    
    # 内阴影效果
    draw.rectangle([4, 4, 91, 27], outline=COLORS['paper_aged'], width=1)
    
    return img

def generate_button_disabled():
    """生成禁用状态按钮"""
    img = create_image(96, 32)
    draw = ImageDraw.Draw(img)
    
    # 灰度背景
    draw.rectangle([2, 2, 93, 29], fill=COLORS['paper_aged'])
    
    # 淡色边框
    draw.rectangle([0, 0, 95, 31], outline=COLORS['ink_faded'], width=2)
    
    return img

def generate_panel():
    """生成面板/窗口框架 - 256x192像素"""
    img = create_image(256, 192)
    draw = ImageDraw.Draw(img)
    
    # 主背景
    draw.rectangle([8, 8, 247, 183], fill=COLORS['paper_medium'])
    
    # 外边框
    draw.rectangle([0, 0, 255, 191], outline=COLORS['ink_brown'], width=2)
    
    # 内边框
    draw.rectangle([6, 6, 249, 185], outline=COLORS['paper_aged'], width=2)
    
    # 装饰角
    corners = [(4, 4), (248, 4), (4, 184), (248, 184)]
    for cx, cy in corners:
        draw.rectangle([cx-2, cy-2, cx+2, cy+2], fill=COLORS['accent_gold'])
    
    return img

def generate_progress_bar_bg():
    """生成进度条背景"""
    img = create_image(128, 16)
    draw = ImageDraw.Draw(img)
    
    # 背景
    draw.rectangle([0, 0, 127, 15], fill=COLORS['paper_dark'])
    
    # 边框
    draw.rectangle([0, 0, 127, 15], outline=COLORS['ink_brown'], width=1)
    
    return img

def generate_progress_bar_fill():
    """生成进度条填充（生命值）"""
    img = create_image(128, 16)
    draw = ImageDraw.Draw(img)
    
    # 渐变填充效果（使用条纹模拟）
    for x in range(0, 128, 2):
        if x < 43:
            color = COLORS['accent_green']
        elif x < 86:
            color = (120, 140, 60)  # 黄绿过渡
        else:
            color = COLORS['accent_gold']
        draw.line([(x, 2), (x, 13)], fill=color, width=1)
    
    # 高光
    draw.line([(0, 2), (127, 2)], fill=COLORS['paper_light'], width=1)
    
    return img

def generate_progress_bar_mist():
    """生成迷雾值进度条"""
    img = create_image(128, 16)
    draw = ImageDraw.Draw(img)
    
    # 迷雾色调填充
    for x in range(0, 128, 2):
        if x < 43:
            color = COLORS['accent_blue']
        elif x < 86:
            color = (100, 80, 120)  # 蓝紫过渡
        else:
            color = (120, 60, 100)  # 紫色
        draw.line([(x, 2), (x, 13)], fill=color, width=1)
    
    # 高光
    draw.line([(0, 2), (127, 2)], fill=COLORS['paper_light'], width=1)
    
    return img

def generate_slider_bg():
    """生成滑块背景"""
    img = create_image(160, 12)
    draw = ImageDraw.Draw(img)
    
    # 轨道背景
    draw.rectangle([0, 4, 159, 7], fill=COLORS['paper_dark'])
    
    # 轨道边框
    draw.rectangle([0, 3, 159, 8], outline=COLORS['ink_brown'], width=1)
    
    return img

def generate_slider_handle():
    """生成滑块手柄"""
    img = create_image(16, 24)
    draw = ImageDraw.Draw(img)
    
    # 手柄主体
    draw.rectangle([4, 0, 11, 23], fill=COLORS['paper_medium'])
    
    # 边框
    draw.rectangle([4, 0, 11, 23], outline=COLORS['ink_brown'], width=1)
    
    # 中心标记
    draw.rectangle([6, 8, 9, 15], fill=COLORS['accent_gold'])
    
    # 底部尖角
    draw.polygon([(4, 23), (8, 18), (11, 23)], fill=COLORS['paper_medium'])
    draw.line([(4, 23), (8, 18)], fill=COLORS['ink_brown'], width=1)
    draw.line([(8, 18), (11, 23)], fill=COLORS['ink_brown'], width=1)
    
    return img

def generate_checkbox_unchecked():
    """生成未选中复选框"""
    img = create_image(24, 24)
    draw = ImageDraw.Draw(img)
    
    # 背景
    draw.rectangle([2, 2, 21, 21], fill=COLORS['paper_light'])
    
    # 边框
    draw.rectangle([0, 0, 23, 23], outline=COLORS['ink_brown'], width=2)
    
    return img

def generate_checkbox_checked():
    """生成已选中复选框"""
    img = create_image(24, 24)
    draw = ImageDraw.Draw(img)
    
    # 背景
    draw.rectangle([2, 2, 21, 21], fill=COLORS['paper_light'])
    
    # 边框
    draw.rectangle([0, 0, 23, 23], outline=COLORS['ink_brown'], width=2)
    
    # 对勾标记
    draw.line([(5, 12), (10, 17), (18, 7)], fill=COLORS['accent_green'], width=3)
    
    return img

def generate_radio_unchecked():
    """生成未选中单选按钮"""
    img = create_image(24, 24)
    draw = ImageDraw.Draw(img)
    
    # 圆形外框
    draw.ellipse([2, 2, 21, 21], outline=COLORS['ink_brown'], width=2)
    
    # 背景
    draw.ellipse([4, 4, 19, 19], fill=COLORS['paper_light'])
    
    return img

def generate_radio_checked():
    """生成已选中单选按钮"""
    img = create_image(24, 24)
    draw = ImageDraw.Draw(img)
    
    # 圆形外框
    draw.ellipse([2, 2, 21, 21], outline=COLORS['ink_brown'], width=2)
    
    # 背景
    draw.ellipse([4, 4, 19, 19], fill=COLORS['paper_light'])
    
    # 中心点
    draw.ellipse([8, 8, 15, 15], fill=COLORS['accent_gold'])
    
    return img

def generate_icon_settings():
    """生成设置图标"""
    img = create_image(24, 24)
    draw = ImageDraw.Draw(img)
    
    # 简化的齿轮 - 像素风格
    color = COLORS['ink_brown']
    # 中心圆
    draw.ellipse([8, 8, 15, 15], fill=color)
    # 外齿
    draw.rectangle([10, 2, 13, 6], fill=color)
    draw.rectangle([10, 17, 13, 21], fill=color)
    draw.rectangle([2, 10, 6, 13], fill=color)
    draw.rectangle([17, 10, 21, 13], fill=color)
    
    return img

def generate_icon_back():
    """生成返回图标"""
    img = create_image(24, 24)
    draw = ImageDraw.Draw(img)
    
    color = COLORS['ink_brown']
    # 箭头形状
    draw.polygon([(18, 4), (6, 12), (18, 20)],