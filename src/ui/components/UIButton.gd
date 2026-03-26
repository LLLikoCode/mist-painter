## UIButton
## 羊皮纸风格按钮组件
## 支持悬停效果、点击动画、焦点样式
## 基于美术风格指南设计

class_name UIButton
extends Button

# ============================================
# 枚举定义
# ============================================

## 按钮类型
enum ButtonType {
    PRIMARY,    ## 主要按钮 - 金色强调
    SECONDARY,  ## 次要按钮 - 羊皮纸风格
    ACCENT,     ## 强调按钮 - 绿色
    DANGER,     ## 危险按钮 - 红色
    GHOST       ## 幽灵按钮 - 透明背景
}

## 按钮尺寸
enum ButtonSize {
    SMALL,      ## 小尺寸 - 80x32
    MEDIUM,     ## 中尺寸 - 120x44 (默认)
    LARGE       ## 大尺寸 - 160x56
}

# ============================================
# 导出变量
# ============================================

@export_group("Button Configuration")
@export var button_type: ButtonType = ButtonType.PRIMARY:
    set = set_button_type

@export var button_size: ButtonSize = ButtonSize.MEDIUM:
    set = set_button_size

@export_group("Animation Settings")
@export var animate_scale: bool = true
@export var animate_color: bool = true
@export var play_sound: bool = true

@export_group("Style Overrides")
@export var custom_text_color: Color = Color.TRANSPARENT
@export var custom_bg_color: Color = Color.TRANSPARENT
@export var custom_border_color: Color = Color.TRANSPARENT

# ============================================
# 内部变量
# ============================================

var _original_scale: Vector2 = Vector2.ONE
var _is_hovered: bool = false
var _is_pressed: bool = false
var _is_focused: bool = false

# 样式缓存
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _disabled_style: StyleBoxFlat
var _focus_style: StyleBoxFlat

# ============================================
# 生命周期
# ============================================

func _ready():
    # 设置焦点模式
    focus_mode = Control.FOCUS_ALL
    
    # 保存原始缩放
    _original_scale = scale
    
    # 应用初始样式
    _build_styles()
    _apply_styles()
    _apply_size()
    
    # 连接信号
    _connect_signals()
    
    # 应用自定义颜色（如果有）
    _apply_custom_colors()

func _connect_signals() -> void:
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    button_down.connect(_on_button_down)
    button_up.connect(_on_button_up)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)
    pressed.connect(_on_pressed)

func _apply_custom_colors() -> void:
    if custom_text_color != Color.TRANSPARENT:
        add_theme_color_override("font_color", custom_text_color)
        add_theme_color_override("font_hover_color", custom_text_color)
        add_theme_color_override("font_pressed_color", custom_text_color)

# ============================================
# 样式构建
# ============================================

func _build_styles() -> void:
    var border_radius := UITheme.RADIUS_MEDIUM
    
    # 根据按钮类型构建不同样式
    match button_type:
        ButtonType.PRIMARY:
            _build_primary_styles(border_radius)
        ButtonType.SECONDARY:
            _build_secondary_styles(border_radius)
        ButtonType.ACCENT:
            _build_accent_styles(border_radius)
        ButtonType.DANGER:
            _build_danger_styles(border_radius)
        ButtonType.GHOST:
            _build_ghost_styles(border_radius)

func _build_primary_styles(border_radius: int) -> void:
    # 主要按钮 - 金色风格
    var bg_normal := UITheme.ACCENT_GOLD
    var bg_hover := UITheme.lighten(UITheme.ACCENT_GOLD, 0.15)
    var bg_pressed := UITheme.darken(UITheme.ACCENT_GOLD, 0.1)
    var bg_disabled := UITheme.PAPER_DARK
    
    var border_color := UITheme.INK_BROWN
    
    _normal_style = UITheme.create_style_box_flat(bg_normal, border_color, 2, border_radius)
    _hover_style = UITheme.create_style_box_flat(bg_hover, UITheme.ACCENT_GOLD, 2, border_radius)
    _pressed_style = UITheme.create_style_box_flat(bg_pressed, border_color, 2, border_radius)
    _disabled_style = UITheme.create_style_box_flat(bg_disabled, UITheme.INK_FADED, 2, border_radius)
    _focus_style = UITheme.create_style_box_flat(bg_normal, UITheme.ACCENT_GOLD, 3, border_radius)
    
    # 设置文字颜色
    add_theme_color_override("font_color", UITheme.INK_BLACK)
    add_theme_color_override("font_hover_color", UITheme.INK_BLACK)
    add_theme_color_override("font_pressed_color", UITheme.INK_BLACK)
    add_theme_color_override("font_disabled_color", UITheme.INK_FADED)

func _build_secondary_styles(border_radius: int) -> void:
    # 次要按钮 - 羊皮纸风格
    var bg_normal := UITheme.PAPER_MEDIUM
    var bg_hover := UITheme.PAPER_LIGHT
    var bg_pressed := UITheme.PAPER_DARK
    var bg_disabled := UITheme.PAPER_DARK
    
    var border_color := UITheme.INK_BROWN
    var border_focus := UITheme.ACCENT_GOLD
    
    _normal_style = UITheme.create_style_box_flat(bg_normal, border_color, 2, border_radius)
    _hover_style = UITheme.create_style_box_flat(bg_hover, border_color, 2, border_radius)
    _pressed_style = UITheme.create_style_box_flat(bg_pressed, border_color, 3, border_radius)
    _disabled_style = UITheme.create_style_box_flat(bg_disabled, UITheme.INK_FADED, 2, border_radius)
    _focus_style = UITheme.create_style_box_flat(bg_normal, border_focus, 3, border_radius)
    
    add_theme_color_override("font_color", UITheme.INK_BLACK)
    add_theme_color_override("font_hover_color", UITheme.INK_BLACK)
    add_theme_color_override("font_pressed_color", UITheme.INK_BLACK)
    add_theme_color_override("font_disabled_color", UITheme.INK_FADED)

func _build_accent_styles(border_radius: int) -> void:
    # 强调按钮 - 绿色风格
    var bg_normal := UITheme.ACCENT_GREEN
    var bg_hover := UITheme.lighten(UITheme.ACCENT_GREEN, 0.1)
    var bg_pressed := UITheme.darken(UITheme.ACCENT_GREEN, 0.1)
    var bg_disabled := UITheme.PAPER_DARK
    
    var border_color := UITheme.INK_BROWN
    
    _normal_style = UITheme.create_style_box_flat(bg_normal, border_color, 2, border_radius)
    _hover_style = UITheme.create_style_box_flat(bg_hover, border_color, 2, border_radius)
    _pressed_style = UITheme.create_style_box_flat(bg_pressed, border_color, 2, border_radius)
    _disabled_style = UITheme.create_style_box_flat(bg_disabled, UITheme.INK_FADED, 2, border_radius)
    _focus_style = UITheme.create_style_box_flat(bg_normal, UITheme.ACCENT_GOLD, 3, border_radius)
    
    add_theme_color_override("font_color", UITheme.INK_BLACK)
    add_theme_color_override("font_hover_color", UITheme.INK_BLACK)
    add_theme_color_override("font_pressed_color", UITheme.INK_BLACK)
    add_theme_color_override("font_disabled_color", UITheme.INK_FADED)

func _build_danger_styles(border_radius: int) -> void:
    # 危险按钮 - 红色风格
    var bg_normal := UITheme.ACCENT_RED
    var bg_hover := UITheme.lighten(UITheme.ACCENT_RED, 0.1)
    var bg_pressed := UITheme.darken(UITheme.ACCENT_RED, 0.1)
    var bg_disabled := UITheme.PAPER_DARK
    
    var border_color := UITheme.INK_BROWN
    
    _normal_style = UITheme.create_style_box_flat(bg_normal, border_color, 2, border_radius)
    _hover_style = UITheme.create_style_box_flat(bg_hover, border_color, 2, border_radius)
    _pressed_style = UITheme.create_style_box_flat(bg_pressed, border_color, 2, border_radius)
    _disabled_style = UITheme.create_style_box_flat(bg_disabled, UITheme.INK_FADED, 2, border_radius)
    _focus_style = UITheme.create_style_box_flat(bg_normal, UITheme.ACCENT_GOLD, 3, border_radius)
    
    add_theme_color_override("font_color", Color.WHITE)
    add_theme_color_override("font_hover_color", Color.WHITE)
    add_theme_color_override("font_pressed_color", Color.WHITE)
    add_theme_color_override("font_disabled_color", UITheme.INK_FADED)

func _build_ghost_styles(border_radius: int) -> void:
    # 幽灵按钮 - 透明背景
    var bg_normal := Color.TRANSPARENT
    var bg_hover := UITheme.PAPER_MEDIUM
    var bg_pressed := UITheme.PAPER_DARK
    var bg_disabled := Color.TRANSPARENT
    
    var border_color := UITheme.INK_FADED
    
    _normal_style = UITheme.create_style_box_flat(bg_normal, border_color, 1, border_radius)
    _hover_style = UITheme.create_style_box_flat(bg_hover, UITheme.INK_BROWN, 1, border_radius)
    _pressed_style = UITheme.create_style_box_flat(bg_pressed, UITheme.INK_BROWN, 2, border_radius)
    _disabled_style = UITheme.create_style_box_flat(bg_disabled, UITheme.INK_FADED, 1, border_radius)
    _focus_style = UITheme.create_style_box_flat(bg_hover, UITheme.ACCENT_GOLD, 2, border_radius)
    
    add_theme_color_override("font_color", UITheme.INK_BLACK)
    add_theme_color_override("font_hover_color", UITheme.INK_BLACK)
    add_theme_color_override("font_pressed_color", UITheme.INK_BLACK)
    add_theme_color_override("font_disabled_color", UITheme.INK_FADED)

# ============================================
# 样式应用
# ============================================

func _apply_styles() -> void:
    add_theme_stylebox_override("normal", _normal_style)
    add_theme_stylebox_override("hover", _hover_style)
    add_theme_stylebox_override("pressed", _pressed_style)
    add_theme_stylebox_override("disabled", _disabled_style)
    add_theme_stylebox_override("focus", _focus_style)

func _apply_size() -> void:
    match button_size:
        ButtonSize.SMALL:
            custom_minimum_size = Vector2(80, UITheme.BUTTON_HEIGHT_SMALL)
            add_theme_font_size_override("font_size", 14)
        ButtonSize.MEDIUM:
            custom_minimum_size = Vector2(120, UITheme.BUTTON_HEIGHT_MEDIUM)
            add_theme_font_size_override("font_size", 18)
        ButtonSize.LARGE:
            custom_minimum_size = Vector2(160, UITheme.BUTTON_HEIGHT_LARGE)
            add_theme_font_size_override("font_size", 22)

# ============================================
# 动画效果
# ============================================

func _animate_hover(hovered: bool) -> void:
    if not animate_scale:
        return
    
    var target_scale := Vector2(1.05, 1.05) if hovered else _original_scale
    UIAnimation.button_hover(self, hovered, 1.05)

func _animate_press(pressed: bool) -> void:
    if not animate_scale:
        return
    
    if pressed:
        UIAnimation.button_click(self, 0.95, 1.05 if _is_hovered else 1.0)

func _play_click_sound() -> void:
    if play_sound:
        # TODO: 集成音频管理器
        # AudioManager.play_sfx("button_click")
        pass

# ============================================
# 信号处理
# ============================================

func _on_mouse_entered() -> void:
    _is_hovered = true
    if not disabled:
        _animate_hover(true)

func _on_mouse_exited() -> void:
    _is_hovered = false
    _animate_hover(false)

func _on_button_down() -> void:
    _is_pressed = true
    _animate_press(true)

func _on_button_up() -> void:
    _is_pressed = false
    _animate_press(false)

func _on_focus_entered() -> void:
    _is_focused = true
    if animate_scale:
        _animate_hover(true)

func _on_focus_exited() -> void:
    _is_focused = false
    _animate_hover(false)

func _on_pressed() -> void:
    _play_click_sound()

# ============================================
# 公共方法
# ============================================

## 设置按钮类型
func set_button_type(type: ButtonType) -> void:
    button_type = type
    if is_node_ready():
        _build_styles()
        _apply_styles()

## 设置按钮尺寸
func set_button_size(size: ButtonSize) -> void:
    button_size = size
    if is_node_ready():
        _apply_size()

## 设置自定义颜色
func set_custom_colors(text: Color = Color.TRANSPARENT, bg: Color = Color.TRANSPARENT, border: Color = Color.TRANSPARENT) -> void:
    custom_text_color = text
    custom_bg_color = bg
    custom_border_color = border
    
    if is_node_ready():
        _apply_custom_colors()
        _build_styles()
        _apply_styles()

## 播放强调动画（用于重要提示）
func play_emphasis() -> void:
    UIAnimation.pulse(self, 1.1, 0.5)

## 播放成功动画
func play_success() -> void:
    UIAnimation.highlight(self, 0.3)

## 播放错误动画
func play_error() -> void:
    UIAnimation.shake(self, 5.0, 0.3)