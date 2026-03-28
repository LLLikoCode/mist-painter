#!/usr/bin/env python3
"""
迷雾绘者 (Mist Painter) - 角色Sprite生成器
使用纯Python创建PNG像素艺术资源
"""

import struct
import zlib
import os

# 颜色定义 - 根据美术风格指南
COLORS = {
    'transparent': (0, 0, 0, 0),
    'cloak': (45, 45, 45, 255),        # #2d2d2d - 斗篷深灰
    'cloak_dark': (26, 26, 26, 255),   # #1a1a1a - 斗篷墨黑
    'hood_inner': (20, 20, 20, 255),   # 兜帽内部更黑
    'eye': (201, 162, 39, 255),        # #c9a227 - 金色眼睛
    'backpack': (90, 74, 58, 255),     # #5a4a3a - 皮革背包
    'boots': (61, 40, 23, 255),        # #3d2817 - 深褐色靴子
    'skin': (200, 180, 160, 255),      # 肤色
    'highlight': (60, 60, 60, 255),    # 高光
}

# Sprite规格
SPRITE_WIDTH = 32
SPRITE_HEIGHT = 48


def create_png_rgba(width, height, pixel_data):
    """手动创建PNG文件 (RGBA格式)"""
    
    # PNG文件头
    png_header = b'\x89PNG\r\n\x1a\n'
    
    # IHDR块
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    ihdr_chunk = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # IDAT块 (图像数据)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # 每行以过滤类型0开始
        for x in range(width):
            r, g, b, a = pixel_data[y * width + x]
            raw_data += bytes([r, g, b, a])
    
    compressed_data = zlib.compress(raw_data)
    idat_crc = zlib.crc32(b'IDAT' + compressed_data) & 0xffffffff
    idat_chunk = struct.pack('>I', len(compressed_data)) + b'IDAT' + compressed_data + struct.pack('>I', idat_crc)
    
    # IEND块
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    return png_header + ihdr_chunk + idat_chunk + iend_chunk


def create_base_character():
    """创建基础角色模板 (32x48像素)"""
    width, height = SPRITE_WIDTH, SPRITE_HEIGHT
    pixels = [COLORS['transparent']] * (width * height)
    c = COLORS
    
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = color
    
    def fill_rect(x1, y1, x2, y2, color):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                set_pixel(x, y, color)
    
    # 头部/兜帽 (y: 0-11)
    fill_rect(8, 0, 23, 11, c['cloak'])
    fill_rect(10, 2, 21, 9, c['hood_inner'])
    
    # 眼睛 (金色微光)
    fill_rect(12, 5, 13, 7, c['eye'])
    fill_rect(18, 5, 19, 7, c['eye'])
    
    # 身体/斗篷主体 (y: 12-31)
    fill_rect(6, 12, 25, 31, c['cloak'])
    fill_rect(8, 14, 23, 29, c['cloak_dark'])
    
    # 斗篷边缘高光
    fill_rect(6, 12, 7, 31, c['highlight'])
    fill_rect(24, 12, 25, 31, c['highlight'])
    
    # 背包 (y: 16-27)
    fill_rect(4, 16, 7, 27, c['backpack'])
    fill_rect(24, 16, 27, 27, c['backpack'])
    
    # 腿部/靴子 (y: 32-47)
    fill_rect(8, 32, 14, 47, c['boots'])
    fill_rect(17, 32, 23, 47, c['boots'])
    
    # 靴子高光
    fill_rect(8, 44, 9, 47, c['highlight'])
    fill_rect(17, 44, 18, 47, c['highlight'])
    
    return pixels


def create_idle_frame(frame_num):
    """创建待机动画帧 (4帧)"""
    pixels = create_base_character()
    c = COLORS
    width = SPRITE_WIDTH
    
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < SPRITE_HEIGHT:
            pixels[y * width + x] = color
    
    def fill_rect(x1, y1, x2, y2, color):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                set_pixel(x, y, color)
    
    # 待机动画：轻微呼吸起伏效果
    if frame_num in [2, 4]:
        # 轻微下沉 (斗篷底部稍微扩展)
        fill_rect(6, 31, 25, 33, c['cloak'])
    
    return pixels


def create_walk_frame(frame_num):
    """创建行走动画帧 (8帧)"""
    width, height = SPRITE_WIDTH, SPRITE_HEIGHT
    pixels = [COLORS['transparent']] * (width * height)
    c = COLORS
    
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = color
    
    def fill_rect(x1, y1, x2, y2, color):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                set_pixel(x, y, color)
    
    # 基础身体（所有帧通用）
    # 头部/兜帽
    fill_rect(8, 0, 23, 11, c['cloak'])
    fill_rect(10, 2, 21, 9, c['hood_inner'])
    fill_rect(12, 5, 13, 7, c['eye'])
    fill_rect(18, 5, 19, 7, c['eye'])
    
    # 身体/斗篷
    fill_rect(6, 12, 25, 31, c['cloak'])
    fill_rect(8, 14, 23, 29, c['cloak_dark'])
    
    # 根据帧数调整腿部位置
    if frame_num in [1, 2]:  # 左腿前
        # 斗篷飘动
        fill_rect(4, 14, 6, 27, c['backpack'])
        # 左腿向前
        fill_rect(6, 32, 12, 47, c['boots'])
        fill_rect(6, 44, 7, 47, c['highlight'])
        # 右腿向后
        fill_rect(19, 34, 25, 47, c['boots'])
        fill_rect(19, 44, 20, 47, c['highlight'])
        
    elif frame_num in [3, 4]:  # 中间
        fill_rect(4, 16, 7, 27, c['backpack'])
        fill_rect(24, 16, 27, 27, c['backpack'])
        fill_rect(8, 32, 14, 47, c['boots'])
        fill_rect(17, 32, 23, 47, c['boots'])
        fill_rect(8, 44, 9, 47, c['highlight'])
        fill_rect(17, 44, 18, 47, c['highlight'])
        
    elif frame_num in [5, 6]:  # 右腿前
        # 斗篷飘动
        fill_rect(26, 14, 28, 27, c['backpack'])
        # 右腿向前
        fill_rect(19, 32, 25, 47, c['boots'])
        fill_rect(19, 44, 20, 47, c['highlight'])
        # 左腿向后
        fill_rect(6, 34, 12, 47, c['boots'])
        fill_rect(6, 44, 7, 47, c['highlight'])
        
    else:  # 中间
        fill_rect(4, 16, 7, 27, c['backpack'])
        fill_rect(24, 16, 27, 27, c['backpack'])
        fill_rect(8, 32, 14, 47, c['boots'])
        fill_rect(17, 32, 23, 47, c['boots'])
        fill_rect(8, 44, 9, 47, c['highlight'])
        fill_rect(17, 44, 18, 47, c['highlight'])
    
    return pixels


def create_interact_frame(frame_num):
    """创建交互动画帧 (4帧)"""
    width, height = SPRITE_WIDTH, SPRITE_HEIGHT
    pixels = [COLORS['transparent']] * (width * height)
    c = COLORS
    
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = color
    
    def fill_rect(x1, y1, x2, y2, color):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                set_pixel(x, y, color)
    
    # 基础身体
    # 头部/兜帽
    fill_rect(8, 0, 23, 11, c['cloak'])
    fill_rect(10, 2, 21, 9, c['hood_inner'])
    fill_rect(12, 5, 13, 7, c['eye'])
    fill_rect(18, 5, 19, 7, c['eye'])
    
    # 身体/斗篷
    fill_rect(6, 12, 25, 31, c['cloak'])
    fill_rect(8, 14, 23, 29, c['cloak_dark'])
    
    # 背包
    fill_rect(4, 16, 7, 27, c['backpack'])
    fill_rect(24, 16, 27, 27, c['backpack'])
    
    # 腿部
    fill_rect(8, 32, 14, 47, c['boots'])
    fill_rect(17, 32, 23, 47, c['boots'])
    fill_rect(8, 44, 9, 47, c['highlight'])
    fill_rect(17, 44, 18, 47, c['highlight'])
    
    # 交互动作：伸手
    if frame_num == 2:  # 伸手
        fill_rect(26, 17, 29, 25, c['cloak'])
    elif frame_num == 3:  # 接触
        fill_rect(26, 17, 31, 25, c['cloak'])
    elif frame_num == 4:  # 收回
        fill_rect(26, 17, 29, 25, c['cloak'])
    
    return pixels


def create_sprite_sheet(frames, horizontal=True):
    """创建sprite sheet"""
    if horizontal:
        width = SPRITE_WIDTH * len(frames)
        height = SPRITE_HEIGHT
        sheet_pixels = [COLORS['transparent']] * (width * height)
        
        for i, frame in enumerate(frames):
            for y in range(SPRITE_HEIGHT):
                for x in range(SPRITE_WIDTH):
                    sheet_pixels[y * width + (i * SPRITE_WIDTH + x)] = frame[y * SPRITE_WIDTH + x]
    else:
        width = SPRITE_WIDTH
        height = SPRITE_HEIGHT * len(frames)
        sheet_pixels = [COLORS['transparent']] * (width * height)
        
        for i, frame in enumerate(frames):
            for y in range(SPRITE_HEIGHT):
                for x in range(SPRITE_WIDTH):
                    sheet_pixels[(i * SPRITE_HEIGHT + y) * width + x] = frame[y * SPRITE_WIDTH + x]
    
    return sheet_pixels, width, height


def save_png(filename, width, height, pixel_data):
    """保存PNG文件"""
    png_data = create_png_rgba(width, height, pixel_data)
    with open(filename, 'wb') as f:
        f.write(png_data)


def generate_all_sprites():
    """生成所有sprite资源"""
    output_dir = "/home/admin/.openclaw/workspace/assets/sprites/character"
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成待机动画帧 (4帧)
    idle_frames = []
    for i in range(1, 5):
        frame = create_idle_frame(i)
        idle_frames.append(frame)
        save_png(f"{output_dir}/character_idle_{i:02d}.png", SPRITE_WIDTH, SPRITE_HEIGHT, frame)
    
    # 合并待机动画
    idle_pixels, idle_width, idle_height = create_sprite_sheet(idle_frames, horizontal=True)
    save_png(f"{output_dir}/character_idle.png", idle_width, idle_height, idle_pixels)
    
    # 生成行走动画帧 (8帧)
    walk_frames = []
    for i in range(1, 9):
        frame = create_walk_frame(i)
        walk_frames.append(frame)
        save_png(f"{output_dir}/character_walk_{i:02d}.png", SPRITE_WIDTH, SPRITE_HEIGHT, frame)
    
    # 合并行走动画
    walk_pixels, walk_width, walk_height = create_sprite_sheet(walk_frames, horizontal=True)
    save_png(f"{output_dir}/character_walk.png", walk_width, walk_height, walk_pixels)
    
    # 生成交互动画帧 (4帧)
    interact_frames = []
    for i in range(1, 5):
        frame = create_interact_frame(i)
        interact_frames.append(frame)
        save_png(f"{output_dir}/character_interact_{i:02d}.png", SPRITE_WIDTH, SPRITE_HEIGHT, frame)
    
    # 合并交互动画
    interact_pixels, interact_width, interact_height = create_sprite_sheet(interact_frames, horizontal=True)
    save_png(f"{output_dir}/character_interact.png", interact_width, interact_height, interact_pixels)
    
    # 创建整合的sprite sheet
    all_frames = idle_frames + walk_frames + interact_frames
    all_pixels, all_width, all_height = create_sprite_sheet(all_frames, horizontal=True)
    save_png(f"{output_dir}/character_sprite_sheet.png", all_width, all_height, all_pixels)
    
    print(f"✅ 已生成 {len(all_frames)} 帧sprite资源")
    print(f"📁 输出目录: {output_dir}")
    
    return {
        'idle': idle_frames,
        'walk': walk_frames,
        'interact': interact_frames,
        'all': all_frames
    }


if __name__ == "__main__":
    generate_all_sprites()