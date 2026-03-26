## UITheme
## UI主题系统常量
## 定义迷雾绘者游戏的美术风格色彩、尺寸和字体常量
## 基于美术风格指南 (docs/art-style-guide.md)

class_name UITheme
extends RefCounted

# ============================================
# 羊皮纸色系 (Parchment Colors)
# ============================================

## 羊皮纸浅色 - 主背景、地图底色
const PAPER_LIGHT := Color(0.961, 0.941, 0.882, 1.0)   # #f5f0e1

## 羊皮纸中色 - 次级背景、面板
const PAPER_MEDIUM := Color(0.910, 0.863, 0.769, 1.0)  # #e8dcc4

## 羊皮纸深色 - 阴影、通道地板
const PAPER_DARK := Color(0.831, 0.769, 0.659, 1.0)    # #d4c4a8

## 羊皮纸旧色 - 老化效果、边缘
const PAPER_AGED := Color(0.788, 0.722, 0.588, 1.0)    # #c9b896

# ============================================
# 墨水色系 (Ink Colors)
# ============================================

## 墨黑 - 主要文字、线条
const INK_BLACK := Color(0.102, 0.102, 0.102, 1.0)     # #1a1a1a

## 墨深 - 次级线条、边框
const INK_DARK := Color(0.176, 0.176, 0.176, 1.0)      # #2d2d2d

## 墨淡 - 褪色效果、次要文字
const INK_FADED := Color(0.353, 0.353, 0.353, 1.0)     # #5a5a5a

## 墨褐 - 复古墨水、装饰
const INK_BROWN := Color(0.239, 0.157, 0.090, 1.0)     # #3d2817

# ============================================
# 强调色 (Accent Colors)
# ============================================

## 金色 - 宝藏、重要提示、主要按钮
const ACCENT_GOLD := Color(0.788, 0.635, 0.153, 1.0)   # #c9a227

## 红色 - 危险、敌人、警告
const ACCENT_RED := Color(0.545, 0.227, 0.227, 1.0)    # #8b3a3a

## 绿色 - 安全、回复、入口
const ACCENT_GREEN := Color(0.290, 0.486, 0.349, 1.0)  # #4a7c59

## 蓝色 - 魔法、特殊、传送
const ACCENT_BLUE := Color(0.290, 0.435, 0.647, 1.0)   # #4a6fa5

# ============================================
# 环境色 (Environment Colors)
# ============================================

## 阴影深 - 未探索区域
const SHADOW_DEEP := Color(0.039, 0.039, 0.039, 1.0)   # #0a0a0a

## 迷雾色 - 迷雾遮罩
const MIST_COLOR := Color(0.165, 0.145, 0.125, 1.0)    # #2a2520

## 火把暖色
const TORCH_WARM := Color(1.0, 0.667, 0.267, 1.0)      # #ffaa44

## 提灯暖色
const LANTERN_WARM := Color(1.0, 0.8, 0.4, 1.0)        # #ffcc66

# ============================================
# 功能色 (Functional Colors)
# ============================================

## 成功色
const SUCCESS := Color(0.251, 0.8, 0.451, 1.0)

## 警告色
const WARNING := Color(0.949, 0.702, 0.2, 1.0)

## 错误色
const ERROR := Color(0.902, 0.251, 0.251, 1.0)

## 信息色
const INFO := Color(0.251, 0.6, 0.8, 1.0)

## 透明阴影
const SHADOW := Color(0.0, 0.0, 0.0, 0.3)

## 透明阴影（深色）
const SHADOW_DARK := Color(0.0, 0.0, 0.0, 0.5)

# ============================================
# 尺寸常量 (Size Constants)
# ============================================

## 小圆角
const RADIUS_SMALL: int = 4

## 中圆角
const RADIUS_MEDIUM: int = 8

## 大圆角
const RADIUS_LARGE: int = 12

## 小间距
const SPACING_SMALL: int = 8

## 中间距
const SPACING_MEDIUM: int = 16

## 大间距
const SPACING_LARGE: int = 24

## 边框宽度
const BORDER_WIDTH: int = 2

## 按钮高度（小）
const BUTTON_HEIGHT_SMALL: int = 32

## 按钮高度（中）
const BUTTON_HEIGHT_MEDIUM: int = 44

## 按钮高度（大）
const BUTTON_HEIGHT_LARGE: int = 56

## 输入框高度
const INPUT_HEIGHT: int = 40

# ============================================
# 字体大小 (Font Sizes)
# ============================================

## 标题字号
const FONT_HEADING: int = 36

## 面板标题字号
const FONT_TITLE: int = 28

## 正文字号
const FONT_BODY: int = 18

## 注释字号
const FONT_CAPTION: int = 14

## 小字字号
const FONT_SMALL: int = 12

# ============================================
# 动画时长 (Animation Durations)
# ============================================

## 按钮悬停动画时长
const ANIM_BUTTON_HOVER: float = 0.15

## 按钮点击动画时长
const ANIM_BUTTON_CLICK: float = 0.1

## 界面切换动画时长
const ANIM_SCREEN_TRANSITION: float = 0.3

## 数值变化动画时长
const ANIM_VALUE_CHANGE: float = 0.3

## 抖动动画时长
const ANIM_SHAKE: float = 0.5

## 脉冲动画时长
const ANIM_PULSE: float = 1.0

# ============================================
# 缓动函数类型 (Ease Types)
# ============================================

## 线性缓动
const EASE_LINEAR = Tween.TRANS_LINEAR

## 缓入
const EASE_IN = Tween.EASE_IN

## 缓出
const EASE_OUT = Tween.EASE_OUT

## 缓入缓出
const EASE_IN_OUT = Tween.EASE_IN_OUT

## 缓出回弹
const EASE_OUT_BACK = Tween.EASE_OUT
const TRANS_BACK = Tween.TRANS_BACK

## 缓出弹跳
const EASE_OUT_BOUNCE = Tween.EASE_OUT
const TRANS_BOUNCE = Tween.TRANS_BOUNCE

# ============================================
# 主题预设 (Theme Presets)
# ============================================

## 获取羊皮纸主题颜色配置
static func get_parchment_theme_colors() -> Dictionary:
    return {
        "primary": ACCENT_GOLD,
        "secondary": INK_BROWN,
        "accent": ACCENT_GOLD,
        "background": PAPER_LIGHT,
        "surface": PAPER_MEDIUM,
        "surface_variant": PAPER_DARK,
        "text": INK_BLACK,
        "text_secondary": INK_FADED,
        "text_disabled": Color(INK_FADED.r, INK_FADED.g, INK_FADED.b, 0.5),
        "border": INK_BROWN,
        "border_focused": ACCENT_GOLD,
        "shadow": SHADOW,
        "error": ACCENT_RED,
        "warning": TORCH_WARM,
        "success": ACCENT_GREEN,
        "info": ACCENT_BLUE
    }

## 获取羊皮纸主题尺寸配置
static func get_parchment_theme_sizes() -> Dictionary:
    return {
        "border_radius_small": RADIUS_SMALL,
        "border_radius_medium": RADIUS_MEDIUM,
        "border_radius_large": RADIUS_LARGE,
        "border_width": BORDER_WIDTH,
        "button_height_small": BUTTON_HEIGHT_SMALL,
        "button_height_medium": BUTTON_HEIGHT_MEDIUM,
        "button_height_large": BUTTON_HEIGHT_LARGE,
        "input_height": INPUT_HEIGHT,
        "spacing_small": SPACING_SMALL,
        "spacing_medium": SPACING_MEDIUM,
        "spacing_large": SPACING_LARGE
    }

## 获取羊皮纸主题字体配置
static func get_parchment_theme_fonts() -> Dictionary:
    return {
        "heading_size": FONT_HEADING,
        "title_size": FONT_TITLE,
        "body_size": FONT_BODY,
        "caption_size": FONT_CAPTION,
        "small_size": FONT_SMALL
    }

## 获取完整羊皮纸主题配置
static func get_parchment_theme() -> Dictionary:
    return {
        "name": "parchment",
        "colors": get_parchment_theme_colors(),
        "sizes": get_parchment_theme_sizes(),
        "fonts": get_parchment_theme_fonts()
    }

# ============================================
# 工具函数 (Utility Functions)
# ============================================

## 获取颜色的变亮版本
static func lighten(color: Color, amount: float = 0.1) -> Color:
    return color.lightened(amount)

## 获取颜色的变暗版本
static func darken(color: Color, amount: float = 0.1) -> Color:
    return color.darkened(amount)

## 获取颜色的半透明版本
static func with_alpha(color: Color, alpha: float) -> Color:
    return Color(color.r, color.g, color.b, alpha)

## 创建样式框
static func create_style_box_flat(
    bg_color: Color,
    border_color: Color = Color.TRANSPARENT,
    border_width: int = 0,
    corner_radius: int = 0
) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_right = border_width
    style.border_width_top = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = corner_radius
    style.corner_radius_top_right = corner_radius
    style.corner_radius_bottom_left = corner_radius
    style.corner_radius_bottom_right = corner_radius
    return style

## 创建羊皮纸风格样式框
static func create_parchment_style(
    variant: String = "medium",
    has_border: bool = true,
    border_color: Color = INK_BROWN
) -> StyleBoxFlat:
    var bg_color: Color
    match variant:
        "light":
            bg_color = PAPER_LIGHT
        "medium":
            bg_color = PAPER_MEDIUM
        "dark":
            bg_color = PAPER_DARK
        "aged":
            bg_color = PAPER_AGED
        _:
            bg_color = PAPER_MEDIUM
    
    var border_width := BORDER_WIDTH if has_border else 0
    
    return create_style_box_flat(bg_color, border_color, border_width, RADIUS_MEDIUM)