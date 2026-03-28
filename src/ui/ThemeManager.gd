## ThemeManager
## 主题管理器
## 负责管理UI主题、样式和颜色方案

class_name ThemeManager
extends Node

# 主题数据
var current_theme: Dictionary = {}
var themes: Dictionary = {}

# 信号
signal theme_changed(theme_name: String)
signal theme_loaded(theme_name: String)

# 默认主题
const DEFAULT_THEME = {
    "name": "default",
    "colors": {
        "primary": Color(0.2, 0.5, 0.9),
        "secondary": Color(0.3, 0.35, 0.45),
        "accent": Color(0.95, 0.65, 0.25),
        "background": Color(0.08, 0.08, 0.12),
        "surface": Color(0.12, 0.12, 0.18),
        "surface_variant": Color(0.18, 0.18, 0.25),
        "text": Color(0.95, 0.95, 0.95),
        "text_secondary": Color(0.65, 0.65, 0.7),
        "text_disabled": Color(0.4, 0.4, 0.45),
        "error": Color(0.9, 0.25, 0.25),
        "warning": Color(0.95, 0.7, 0.2),
        "success": Color(0.25, 0.8, 0.45),
        "border": Color(0.25, 0.25, 0.35),
        "border_focused": Color(0.4, 0.6, 0.95),
        "shadow": Color(0, 0, 0, 0.5)
    },
    "sizes": {
        "border_radius_small": 4,
        "border_radius_medium": 8,
        "border_radius_large": 12,
        "border_width": 2,
        "button_height": 50,
        "input_height": 40,
        "spacing_small": 8,
        "spacing_medium": 16,
        "spacing_large": 24
    },
    "fonts": {
        "heading_size": 48,
        "title_size": 32,
        "body_size": 18,
        "caption_size": 14
    }
}

# 浅色主题
const LIGHT_THEME = {
    "name": "light",
    "colors": {
        "primary": Color(0.15, 0.4, 0.85),
        "secondary": Color(0.5, 0.55, 0.65),
        "accent": Color(0.9, 0.55, 0.15),
        "background": Color(0.95, 0.95, 0.97),
        "surface": Color(1, 1, 1),
        "surface_variant": Color(0.9, 0.9, 0.93),
        "text": Color(0.15, 0.15, 0.2),
        "text_secondary": Color(0.45, 0.45, 0.5),
        "text_disabled": Color(0.6, 0.6, 0.65),
        "error": Color(0.85, 0.2, 0.2),
        "warning": Color(0.9, 0.65, 0.15),
        "success": Color(0.2, 0.75, 0.4),
        "border": Color(0.8, 0.8, 0.85),
        "border_focused": Color(0.35, 0.55, 0.9),
        "shadow": Color(0, 0, 0, 0.15)
    },
    "sizes": DEFAULT_THEME["sizes"],
    "fonts": DEFAULT_THEME["fonts"]
}

func _ready():
    # 注册内置主题
    register_theme("default", DEFAULT_THEME)
    register_theme("light", LIGHT_THEME)
    
    # 加载默认主题
    load_theme("default")
    
    print("ThemeManager initialized")

## 注册主题
func register_theme(theme_name: String, theme_data: Dictionary) -> void:
    themes[theme_name] = theme_data.duplicate(true)
    print("Theme registered: %s" % theme_name)

## 加载主题
func load_theme(theme_name: String) -> bool:
    if not themes.has(theme_name):
        push_error("Theme not found: %s" % theme_name)
        return false
    
    current_theme = themes[theme_name].duplicate(true)
    theme_loaded.emit(theme_name)
    theme_changed.emit(theme_name)
    
    print("Theme loaded: %s" % theme_name)
    return true

## 获取当前主题
func get_current_theme() -> Dictionary:
    return current_theme.duplicate(true)

## 获取主题名称
func get_current_theme_name() -> String:
    return current_theme.get("name", "default")

## 获取颜色
func get_color(color_name: String, default_color: Color = Color.WHITE) -> Color:
    if current_theme.has("colors") and current_theme["colors"].has(color_name):
        return current_theme["colors"][color_name]
    return default_color

## 获取尺寸
func get_size(size_name: String, default_size: int = 0) -> int:
    if current_theme.has("sizes") and current_theme["sizes"].has(size_name):
        return current_theme["sizes"][size_name]
    return default_size

## 获取字体大小
func get_font_size(font_name: String, default_size: int = 16) -> int:
    if current_theme.has("fonts") and current_theme["fonts"].has(font_name):
        return current_theme["fonts"][font_name]
    return default_size

## 应用主题到控件
func apply_theme(control: Control) -> void:
    if control == null or not is_instance_valid(control):
        return
    
    # 创建并应用主题资源
    var theme_resource = _create_theme_resource()
    control.theme = theme_resource
    
    # 递归应用到子控件
    for child in control.get_children():
        if child is Control:
            apply_theme(child)

## 创建主题资源
func _create_theme_resource() -> Theme:
    var theme = Theme.new()
    
    # 设置默认字体大小
    theme.set_font_size("font_size", "Label", get_font_size("body_size"))
    theme.set_font_size("font_size", "Button", get_font_size("body_size"))
    
    # 设置按钮样式
    var button_normal = _create_button_stylebox("surface", "border")
    var button_hover = _create_button_stylebox("surface_variant", "border_focused")
    var button_pressed = _create_button_stylebox("primary", "primary")
    var button_disabled = _create_button_stylebox("surface", "text_disabled")
    var button_focused = _create_button_stylebox("surface_variant", "border_focused")
    
    theme.set_stylebox("normal", "Button", button_normal)
    theme.set_stylebox("hover", "Button", button_hover)
    theme.set_stylebox("pressed", "Button", button_pressed)
    theme.set_stylebox("disabled", "Button", button_disabled)
    theme.set_stylebox("focus", "Button", button_focused)
    
    # 设置按钮颜色
    theme.set_color("font_color", "Button", get_color("text"))
    theme.set_color("font_hover_color", "Button", get_color("text"))
    theme.set_color("font_pressed_color", "Button", get_color("text"))
    theme.set_color("font_disabled_color", "Button", get_color("text_disabled"))
    
    # 设置面板样式
    var panel_style = _create_panel_stylebox()
    theme.set_stylebox("panel", "Panel", panel_style)
    theme.set_stylebox("panel", "PanelContainer", panel_style)
    
    # 设置标签颜色
    theme.set_color("font_color", "Label", get_color("text"))
    theme.set_color("font_color", "RichTextLabel", get_color("text"))
    
    # 设置进度条样式
    var progress_bg = _create_progress_bg_stylebox()
    var progress_fill = _create_progress_fill_stylebox()
    theme.set_stylebox("background", "ProgressBar", progress_bg)
    theme.set_stylebox("fill", "ProgressBar", progress_fill)
    
    # 设置滑块样式
    var slider_grabber = _create_slider_grabber_stylebox()
    var slider_bg = _create_slider_bg_stylebox()
    theme.set_stylebox("grabber_area", "HSlider", slider_grabber)
    theme.set_stylebox("slider", "HSlider", slider_bg)
    
    # 设置LineEdit样式
    var line_edit_normal = _create_line_edit_stylebox()
    var line_edit_focused = _create_line_edit_focused_stylebox()
    theme.set_stylebox("normal", "LineEdit", line_edit_normal)
    theme.set_stylebox("focus", "LineEdit", line_edit_focused)
    theme.set_color("font_color", "LineEdit", get_color("text"))
    theme.set_color("font_placeholder_color", "LineEdit", get_color("text_secondary"))
    
    return theme

## 创建按钮样式框
func _create_button_stylebox(bg_color_name: String, border_color_name: String) -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color(bg_color_name)
    stylebox.border_color = get_color(border_color_name)
    stylebox.border_width_left = get_size("border_width")
    stylebox.border_width_right = get_size("border_width")
    stylebox.border_width_top = get_size("border_width")
    stylebox.border_width_bottom = get_size("border_width")
    stylebox.corner_radius_top_left = get_size("border_radius_medium")
    stylebox.corner_radius_top_right = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_left = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_right = get_size("border_radius_medium")

    return stylebox

## 创建面板样式框
func _create_panel_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("surface")
    stylebox.border_color = get_color("border")
    stylebox.border_width_left = 1
    stylebox.border_width_right = 1
    stylebox.border_width_top = 1
    stylebox.border_width_bottom = 1
    stylebox.corner_radius_top_left = get_size("border_radius_medium")
    stylebox.corner_radius_top_right = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_left = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_right = get_size("border_radius_medium")

    return stylebox

## 创建进度条背景样式框
func _create_progress_bg_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("surface_variant")
    stylebox.corner_radius_top_left = get_size("border_radius_medium")
    stylebox.corner_radius_top_right = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_left = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_right = get_size("border_radius_medium")

    return stylebox

## 创建进度条填充样式框
func _create_progress_fill_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("primary")
    stylebox.corner_radius_top_left = get_size("border_radius_medium")
    stylebox.corner_radius_top_right = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_left = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_right = get_size("border_radius_medium")

    return stylebox

## 创建滑块抓取器样式框
func _create_slider_grabber_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("primary")
    stylebox.corner_radius_top_left = 8
    stylebox.corner_radius_top_right = 8
    stylebox.corner_radius_bottom_left = 8
    stylebox.corner_radius_bottom_right = 8

    return stylebox

## 创建滑块背景样式框
func _create_slider_bg_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("surface_variant")
    stylebox.corner_radius_top_left = 4
    stylebox.corner_radius_top_right = 4
    stylebox.corner_radius_bottom_left = 4
    stylebox.corner_radius_bottom_right = 4

    return stylebox

## 创建 LineEdit 样式框
func _create_line_edit_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("surface")
    stylebox.border_color = get_color("border")
    stylebox.border_width_left = 1
    stylebox.border_width_right = 1
    stylebox.border_width_top = 1
    stylebox.border_width_bottom = 1
    stylebox.corner_radius_top_left = get_size("border_radius_medium")
    stylebox.corner_radius_top_right = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_left = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_right = get_size("border_radius_medium")

    return stylebox

## 创建 LineEdit 聚焦样式框
func _create_line_edit_focused_stylebox() -> StyleBoxFlat:
    var stylebox = StyleBoxFlat.new()
    stylebox.bg_color = get_color("surface")
    stylebox.border_color = get_color("border_focused")
    stylebox.border_width_left = 2
    stylebox.border_width_right = 2
    stylebox.border_width_top = 2
    stylebox.border_width_bottom = 2
    stylebox.corner_radius_top_left = get_size("border_radius_medium")
    stylebox.corner_radius_top_right = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_left = get_size("border_radius_medium")
    stylebox.corner_radius_bottom_right = get_size("border_radius_medium")

    return stylebox