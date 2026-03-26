## UISlider
## 羊皮纸风格滑块组件
## 支持数值显示、步进调节、羊皮纸风格样式

class_name UISlider
extends HSlider

# ============================================
# 枚举定义
# ============================================

## 数值显示模式
enum DisplayMode {
    NONE,       ## 不显示数值
    PERCENTAGE, ## 显示百分比 (0% - 100%)
    VALUE,      ## 显示数值 (min - max)
    CUSTOM      ## 自定义格式
}

# ============================================
# 导出变量
# ============================================

@export_group("Display Settings")
@export var display_mode: DisplayMode = DisplayMode.PERCENTAGE:
    set = set_display_mode

@export var show_value_label: bool = true:
    set = set_show_value_label

@export var value_label_format: String = "%d"
@export var value_suffix: String = ""

@export_group("Value Settings")
@export var display_min_value: float = 0.0
@export var display_max_value: float = 100.0

@export_group("Style Settings")
@export var track_height: int = 8
@export var grabber_size: int = 20
@export var show_tick_marks: bool = false
@export var tick_count: int = 5

# ============================================
# 内部变量
# ============================================

var _value_label: Label
var _container: HBoxContainer
var _is_hovered: bool = false
var _is_dragging: bool = false

# 样式缓存
var _slider_style: StyleBoxFlat
var _grabber_style: StyleBoxFlat
var _grabber_highlight_style: StyleBoxFlat

# ============================================
# 生命周期
# ============================================

func _ready():
    # 设置焦点模式
    focus_mode = Control.FOCUS_ALL
    
    # 构建UI
    _build_ui()
    
    # 应用样式
    _build_styles()
    _apply_styles()
    
    # 连接信号
    _connect_signals()
    
    # 更新显示
    _update_value_display()

func _build_ui() -> void:
    # 创建容器布局
    _container = HBoxContainer.new()
    _container.name = "SliderContainer"
    
    # 创建数值标签
    _value_label = Label.new()
    _value_label.name = "ValueLabel"
    _value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _value_label.custom_minimum_size = Vector2(60, 0)
    
    # 设置标签样式
    _value_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
    _value_label.add_theme_color_override("font_color", UITheme.INK_BLACK)
    
    # 注意：由于Slider是Range的子类，我们不能直接添加子节点
    # 数值标签需要在外部使用此组件时手动添加
    # 这里我们保存引用供外部使用

func _connect_signals() -> void:
    value_changed.connect(_on_value_changed)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)

# ============================================
# 样式构建
# ============================================

func _build_styles() -> void:
    # 滑块轨道样式
    _slider_style = StyleBoxFlat.new()
    _slider_style.bg_color = UITheme.PAPER_DARK
    _slider_style.corner_radius_top_left = track_height / 2
    _slider_style.corner_radius_top_right = track_height / 2
    _slider_style.corner_radius_bottom_left = track_height / 2
    _slider_style.corner_radius_bottom_right = track_height / 2
    
    # 滑块手柄样式（正常）
    _grabber_style = StyleBoxFlat.new()
    _grabber_style.bg_color = UITheme.ACCENT_GOLD
    _grabber_style.border_color = UITheme.INK_BROWN
    _grabber_style.border_width_left = 2
    _grabber_style.border_width_right = 2
    _grabber_style.border_width_top = 2
    _grabber_style.border_width_bottom = 2
    _grabber_style.corner_radius_top_left = grabber_size / 2
    _grabber_style.corner_radius_top_right = grabber_size / 2
    _grabber_style.corner_radius_bottom_left = grabber_size / 2
    _grabber_style.corner_radius_bottom_right = grabber_size / 2
    _grabber_style.shadow_color = UITheme.SHADOW
    _grabber_style.shadow_size = 4
    _grabber_style.shadow_offset = Vector2(2, 2)
    
    # 滑块手柄样式（高亮）
    _grabber_highlight_style = StyleBoxFlat.new()
    _grabber_highlight_style.bg_color = UITheme.lighten(UITheme.ACCENT_GOLD, 0.15)
    _grabber_highlight_style.border_color = UITheme.ACCENT_GOLD
    _grabber_highlight_style.border_width_left = 3
    _grabber_highlight_style.border_width_right = 3
    _grabber_highlight_style.border_width_top = 3
    _grabber_highlight_style.border_width_bottom = 3
    _grabber_highlight_style.corner_radius_top_left = grabber_size / 2
    _grabber_highlight_style.corner_radius_top_right = grabber_size / 2
    _grabber_highlight_style.corner_radius_bottom_left = grabber_size / 2
    _grabber_highlight_style.corner_radius_bottom_right = grabber_size / 2
    _grabber_highlight_style.shadow_color = UITheme.SHADOW_DARK
    _grabber_highlight_style.shadow_size = 6
    _grabber_highlight_style.shadow_offset = Vector2(3, 3)

func _apply_styles() -> void:
    # 应用滑块样式
    add_theme_stylebox_override("slider", _slider_style)
    add_theme_stylebox_override("grabber_area", _grabber_style)
    add_theme_stylebox_override("grabber_area_highlight", _grabber_highlight_style)
    
    # 设置滑块大小
    add_theme_constant_override("slider_height", track_height)
    add_theme_constant_override("grabber_offset", grabber_size / 2)

# ============================================
# 数值显示
# ============================================

func _update_value_display() -> void:
    if _value_label == null:
        return
    
    if not show_value_label:
        _value_label.visible = false
        return
    
    _value_label.visible = true
    
    var display_text := ""
    
    match display_mode:
        DisplayMode.NONE:
            _value_label.visible = false
            return
        
        DisplayMode.PERCENTAGE:
            var percentage := int((value - min_value) / (max_value - min_value) * 100)
            display_text = "%d%%" % percentage
        
        DisplayMode.VALUE:
            # 映射到显示范围
            var display_val := display_min_value + (value - min_value) / (max_value - min_value) * (display_max_value - display_min_value)
            display_text = value_label_format % display_val
        
        DisplayMode.CUSTOM:
            display_text = value_label_format % value
    
    if not value_suffix.is_empty():
        display_text += value_suffix
    
    _value_label.text = display_text

## 获取当前显示值文本
func get_display_text() -> String:
    var display_text := ""
    
    match display_mode:
        DisplayMode.PERCENTAGE:
            var percentage := int((value - min_value) / (max_value - min_value) * 100)
            display_text = "%d%%" % percentage
        
        DisplayMode.VALUE:
            var display_val := display_min_value + (value - min_value) / (max_value - min_value) * (display_max_value - display_min_value)
            display_text = value_label_format % display_val
        
        DisplayMode.CUSTOM:
            display_text = value_label_format % value
        
        _:
            display_text = str(value)
    
    if not value_suffix.is_empty():
        display_text += value_suffix
    
    return display_text

# ============================================
# 信号处理
# ============================================

func _on_value_changed(new_value: float) -> void:
    _update_value_display()
    
    # 播放数值变化音效（可选）
    # if AudioManager:
    #     AudioManager.play_sfx("slider_tick")

func _on_mouse_entered() -> void:
    _is_hovered = true
    _animate_grabber(true)

func _on_mouse_exited() -> void:
    _is_hovered = false
    if not _is_dragging:
        _animate_grabber(false)

func _on_focus_entered() -> void:
    _animate_grabber(true)

func _on_focus_exited() -> void:
    if not _is_hovered:
        _animate_grabber(false)

# ============================================
# 动画效果
# ============================================

func _animate_grabber(highlight: bool) -> void:
    # 手柄高亮动画效果通过样式切换实现
    # 这里可以添加额外的视觉效果
    pass

# ============================================
# 公共方法
# ============================================

## 设置显示模式
func set_display_mode(mode: DisplayMode) -> void:
    display_mode = mode
    if is_node_ready():
        _update_value_display()

## 设置是否显示数值标签
func set_show_value_label(show: bool) -> void:
    show_value_label = show
    if is_node_ready() and _value_label != null:
        _value_label.visible = show
        _update_value_display()

## 获取数值标签（供外部布局使用）
func get_value_label() -> Label:
    return _value_label

## 设置显示范围（用于将内部值映射到显示值）
func set_display_range(min_val: float, max_val: float) -> void:
    display_min_value = min_val
    display_max_value = max_val
    if is_node_ready():
        _update_value_display()

## 设置自定义格式字符串
func set_custom_format(format: String, suffix: String = "") -> void:
    value_label_format = format
    value_suffix = suffix
    if is_node_ready():
        _update_value_display()

## 动画设置值（带过渡效果）
func animate_to_value(target_value: float, duration: float = 0.3) -> void:
    var tween := create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "value", target_value, duration)

## 步进增加
func step_up() -> void:
    value = min(value + step, max_value)

## 步进减少
func step_down() -> void:
    value = max(value - step, min_value)

## 设置步进值
func set_step_size(new_step: float) -> void:
    step = new_step

## 重置为默认值
func reset_to_default() -> void:
    if has_meta("default_value"):
        animate_to_value(get_meta("default_value"))

## 保存当前值为默认值
func save_as_default() -> void:
    set_meta("default_value", value)

## 设置滑块为音量模式（0-100%，带%显示）
func set_volume_mode() -> void:
    min_value = 0
    max_value = 100
    step = 1
    display_mode = DisplayMode.PERCENTAGE
    if is_node_ready():
        _update_value_display()

## 设置滑块为进度模式（显示当前/最大值）
func set_progress_mode() -> void:
    display_mode = DisplayMode.VALUE
    value_label_format = "%d"
    if is_node_ready():
        _update_value_display()

## 播放高亮动画（用于引导用户注意）
func play_highlight() -> void:
    var original_color := _slider_style.bg_color
    var highlight_color := UITheme.lighten(UITheme.PAPER_DARK, 0.2)
    
    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    
    # 高亮
    tween.tween_method(func(c): _slider_style.bg_color = c, original_color, highlight_color, 0.3)
    # 恢复
    tween.tween_method(func(c): _slider_style.bg_color = c, highlight_color, original_color, 0.3)

## 获取当前百分比（0-1）
func get_percentage() -> float:
    if max_value == min_value:
        return 0.0
    return (value - min_value) / (max_value - min_value)

## 设置百分比（0-1）
func set_percentage(percentage: float) -> void:
    value = min_value + percentage * (max_value - min_value)