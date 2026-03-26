## StyledButton
## 样式化按钮组件
## 支持悬停效果、点击动画、焦点样式

class_name StyledButton
extends Button

# 按钮类型
enum ButtonType {
    PRIMARY,    # 主要按钮
    SECONDARY,  # 次要按钮
    ACCENT,     # 强调按钮
    DANGER,     # 危险按钮
    GHOST       # 幽灵按钮
}

# 按钮尺寸
enum ButtonSize {
    SMALL,
    MEDIUM,
    LARGE
}

# 配置
@export var button_type: ButtonType = ButtonType.PRIMARY
@export var button_size: ButtonSize = ButtonSize.MEDIUM
@export var animate_scale: bool = true
@export var play_sound: bool = true

# 原始缩放
var original_scale: Vector2 = Vector2.ONE

func _ready():
    # 设置焦点模式
    focus_mode = Control.FOCUS_ALL
    
    # 应用样式
    _apply_style()
    
    # 连接信号
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    button_down.connect(_on_button_down)
    button_up.connect(_on_button_up)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)
    
    original_scale = scale

func _apply_style() -> void:
    # 应用尺寸
    match button_size:
        ButtonSize.SMALL:
            custom_minimum_size = Vector2(80, 32)
            add_theme_font_size_override("font_size", 14)
        ButtonSize.MEDIUM:
            custom_minimum_size = Vector2(120, 44)
            add_theme_font_size_override("font_size", 18)
        ButtonSize.LARGE:
            custom_minimum_size = Vector2(160, 56)
            add_theme_font_size_override("font_size", 22)
    
    # 应用类型样式
    _apply_type_style()

func _apply_type_style() -> void:
    var theme_manager = UIManager.instance.theme_manager if UIManager.instance else null
    if theme_manager == null:
        return
    
    var normal_style = StyleBoxFlat.new()
    var hover_style = StyleBoxFlat.new()
    var pressed_style = StyleBoxFlat.new()
    var disabled_style = StyleBoxFlat.new()
    var focus_style = StyleBoxFlat.new()
    
    var border_radius = theme_manager.get_size("border_radius_medium", 8)
    
    match button_type:
        ButtonType.PRIMARY:
            normal_style.bg_color = theme_manager.get_color("primary")
            hover_style.bg_color = theme_manager.get_color("primary").lightened(0.1)
            pressed_style.bg_color = theme_manager.get_color("primary").darkened(0.1)
            disabled_style.bg_color = theme_manager.get_color("surface_variant")
            focus_style.bg_color = theme_manager.get_color("primary")
            
            add_theme_color_override("font_color", theme_manager.get_color("text"))
            add_theme_color_override("font_hover_color", theme_manager.get_color("text"))
            add_theme_color_override("font_pressed_color", theme_manager.get_color("text"))
            
        ButtonType.SECONDARY:
            normal_style.bg_color = theme_manager.get_color("surface")
            hover_style.bg_color = theme_manager.get_color("surface_variant")
            pressed_style.bg_color = theme_manager.get_color("secondary")
            disabled_style.bg_color = theme_manager.get_color("surface_variant")
            focus_style.bg_color = theme_manager.get_color("surface_variant")
            
            normal_style.border_color = theme_manager.get_color("border")
            normal_style.border_width_left = 2
            normal_style.border_width_right = 2
            normal_style.border_width_top = 2
            normal_style.border_width_bottom = 2
            
            add_theme_color_override("font_color", theme_manager.get_color("text"))
            add_theme_color_override("font_hover_color", theme_manager.get_color("text"))
            
        ButtonType.ACCENT:
            normal_style.bg_color = theme_manager.get_color("accent")
            hover_style.bg_color = theme_manager.get_color("accent").lightened(0.1)
            pressed_style.bg_color = theme_manager.get_color("accent").darkened(0.1)
            disabled_style.bg_color = theme_manager.get_color("surface_variant")
            focus_style.bg_color = theme_manager.get_color("accent")
            
            add_theme_color_override("font_color", theme_manager.get_color("text"))
            
        ButtonType.DANGER:
            normal_style.bg_color = theme_manager.get_color("error")
            hover_style.bg_color = theme_manager.get_color("error").lightened(0.1)
            pressed_style.bg_color = theme_manager.get_color("error").darkened(0.1)
            disabled_style.bg_color = theme_manager.get_color("surface_variant")
            focus_style.bg_color = theme_manager.get_color("error")
            
            add_theme_color_override("font_color", theme_manager.get_color("text"))
            
        ButtonType.GHOST:
            normal_style.bg_color = Color.TRANSPARENT
            hover_style.bg_color = theme_manager.get_color("surface")
            pressed_style.bg_color = theme_manager.get_color("surface_variant")
            disabled_style.bg_color = Color.TRANSPARENT
            focus_style.bg_color = theme_manager.get_color("surface")
            
            add_theme_color_override("font_color", theme_manager.get_color("text"))
    
    # 设置圆角
    for style in [normal_style, hover_style, pressed_style, disabled_style, focus_style]:
        style.corner_radius_top_left = border_radius
        style.corner_radius_top_right = border_radius
        style.corner_radius_bottom_left = border_radius
        style.corner_radius_bottom_right = border_radius
    
    # 应用样式
    add_theme_stylebox_override("normal", normal_style)
    add_theme_stylebox_override("hover", hover_style)
    add_theme_stylebox_override("pressed", pressed_style)
    add_theme_stylebox_override("disabled", disabled_style)
    add_theme_stylebox_override("focus", focus_style)

func _on_mouse_entered() -> void:
    if animate_scale and not disabled:
        _animate_scale(Vector2(1.05, 1.05))

func _on_mouse_exited() -> void:
    if animate_scale:
        _animate_scale(original_scale)

func _on_button_down() -> void:
    if animate_scale:
        _animate_scale(Vector2(0.95, 0.95))
    
    if play_sound:
        _play_click_sound()

func _on_button_up() -> void:
    if animate_scale:
        _animate_scale(Vector2(1.05, 1.05))

func _on_focus_entered() -> void:
    if animate_scale:
        _animate_scale(Vector2(1.05, 1.05))

func _on_focus_exited() -> void:
    if animate_scale:
        _animate_scale(original_scale)

func _animate_scale(target_scale: Vector2) -> void:
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "scale", target_scale, 0.15)

func _play_click_sound() -> void:
    # TODO: 播放点击音效
    # if AutoLoad.audio_manager:
    #     AutoLoad.audio_manager.play_sfx("button_click")
    pass

## 设置按钮类型
func set_button_type(type: ButtonType) -> void:
    button_type = type
    _apply_type_style()

## 设置按钮尺寸
func set_button_size(size: ButtonSize) -> void:
    button_size = size
    _apply_style()
