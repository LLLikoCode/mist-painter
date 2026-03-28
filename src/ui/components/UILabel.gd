## UILabel
## 羊皮纸风格标签组件
## 支持多种文本样式、自动换行、阴影效果

class_name UILabel
extends Label

# ============================================
# 枚举定义
# ============================================

## 文本样式类型
enum TextStyle {
    HEADING,    ## 标题 - 大号字体
    TITLE,      ## 面板标题 - 中大号字体
    BODY,       ## 正文 - 标准字体
    CAPTION,    ## 注释 - 小号字体
    SMALL       ## 小字 - 最小字体
}

## 文本对齐方式（垂直）
enum VerticalAlign {
    TOP,
    CENTER,
    BOTTOM
}

# ============================================
# 导出变量
# ============================================

@export_group("Text Style")
@export var text_style: TextStyle = TextStyle.BODY:
    set = set_text_style

@export var use_custom_color: bool = false
@export var custom_text_color: Color = UITheme.INK_BLACK

@export_group("Effects")
@export var enable_shadow: bool = false
@export var shadow_color: Color = UITheme.SHADOW
@export var shadow_offset: Vector2 = Vector2(2, 2)

@export var enable_outline: bool = false
@export var outline_color: Color = UITheme.INK_BROWN
@export var outline_size: int = 1

@export_group("Animation")
@export var enable_typewriter: bool = false
@export var typewriter_speed: float = 0.05

# ============================================
# 内部变量
# ============================================

var _full_text: String = ""
var _typewriter_tween: Tween
var _is_typing: bool = false
var max_lines: int = -1

# ============================================
# 生命周期
# ============================================

func _ready():
    # 应用样式
    _apply_text_style()
    _apply_effects()
    
    # 保存完整文本
    _full_text = text
    
    # 如果启用了打字机效果，开始打字
    if enable_typewriter and not _full_text.is_empty():
        start_typewriter()

# ============================================
# 样式应用
# ============================================

func _apply_text_style() -> void:
    # 应用字体大小
    var font_size: int
    var text_color: Color
    
    match text_style:
        TextStyle.HEADING:
            font_size = UITheme.FONT_HEADING
            text_color = UITheme.INK_BLACK
            horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        
        TextStyle.TITLE:
            font_size = UITheme.FONT_TITLE
            text_color = UITheme.INK_BLACK
            horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        
        TextStyle.BODY:
            font_size = UITheme.FONT_BODY
            text_color = UITheme.INK_BLACK
            horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        
        TextStyle.CAPTION:
            font_size = UITheme.FONT_CAPTION
            text_color = UITheme.INK_FADED
            horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        
        TextStyle.SMALL:
            font_size = UITheme.FONT_SMALL
            text_color = UITheme.INK_FADED
            horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    
    # 应用字体大小覆盖
    add_theme_font_size_override("font_size", font_size)
    
    # 应用颜色
    if use_custom_color:
        add_theme_color_override("font_color", custom_text_color)
    else:
        add_theme_color_override("font_color", text_color)

func _apply_effects() -> void:
    # 应用阴影效果
    if enable_shadow:
        add_theme_color_override("font_shadow_color", shadow_color)
        add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
        add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
    
    # 应用描边效果（Godot 4.x Label不支持直接描边，需要使用自定义绘制或RichTextLabel）
    # 这里预留接口，实际实现可能需要自定义绘制

# ============================================
# 打字机效果
# ============================================

## 开始打字机效果
func start_typewriter() -> void:
    if _full_text.is_empty():
        _full_text = text
    
    if _full_text.is_empty():
        return
    
    # 停止之前的打字机动画
    stop_typewriter()
    
    text = ""
    _is_typing = true
    visible_characters = 0
    
    _typewriter_tween = create_tween()
    _typewriter_tween.set_ease(Tween.EASE_IN_OUT)
    _typewriter_tween.set_trans(Tween.TRANS_LINEAR)
    
    # 逐字显示
    for i in range(_full_text.length()):
        _typewriter_tween.tween_callback(func():
            visible_characters = i + 1
        )
        _typewriter_tween.tween_interval(typewriter_speed)
    
    _typewriter_tween.finished.connect(func():
        _is_typing = false
        visible_characters = -1  # 显示所有字符
    )

## 停止打字机效果
func stop_typewriter() -> void:
    if _typewriter_tween != null and _typewriter_tween.is_valid():
        _typewriter_tween.kill()
    
    _is_typing = false
    visible_characters = -1
    text = _full_text

## 立即完成打字机效果
func finish_typewriter() -> void:
    stop_typewriter()

## 检查是否正在打字
func is_typing() -> bool:
    return _is_typing

# ============================================
# 公共方法
# ============================================

## 设置文本样式
func set_text_style(style: TextStyle) -> void:
    text_style = style
    if is_node_ready():
        _apply_text_style()

## 设置文本（支持打字机效果）
func set_text_with_effect(new_text: String, play_typewriter: bool = false) -> void:
    _full_text = new_text
    
    if play_typewriter and enable_typewriter:
        start_typewriter()
    else:
        text = new_text

## 设置自定义颜色
func set_custom_text_color(color: Color) -> void:
    custom_text_color = color
    use_custom_color = true
    if is_node_ready():
        add_theme_color_override("font_color", color)

## 清除自定义颜色
func clear_custom_color() -> void:
    use_custom_color = false
    if is_node_ready():
        _apply_text_style()

## 启用阴影
func enable_text_shadow(color: Color = UITheme.SHADOW, offset: Vector2 = Vector2(2, 2)) -> void:
    enable_shadow = true
    shadow_color = color
    shadow_offset = offset
    if is_node_ready():
        _apply_effects()

## 禁用阴影
func disable_text_shadow() -> void:
    enable_shadow = false
    if is_node_ready():
        remove_theme_color_override("font_shadow_color")

## 渐变显示（淡入效果）
func fade_in(duration: float = 0.3) -> Tween:
    modulate.a = 0.0
    var tween := create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "modulate:a", 1.0, duration)
    return tween

## 渐变消失（淡出效果）
func fade_out(duration: float = 0.2) -> Tween:
    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "modulate:a", 0.0, duration)
    return tween

## 闪烁效果（用于警告/提示）
func blink(times: int = 3, duration: float = 0.5) -> Tween:
    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    
    for i in times:
        tween.tween_property(self, "modulate:a", 0.3, duration / 2)
        tween.tween_property(self, "modulate:a", 1.0, duration / 2)
    
    return tween

## 脉冲缩放效果
func pulse_scale(times: int = 2, scale_amount: float = 1.1, duration: float = 0.3) -> Tween:
    var original_scale := scale
    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    
    for i in times:
        tween.tween_property(self, "scale", Vector2(scale_amount, scale_amount), duration / 2)
        tween.tween_property(self, "scale", original_scale, duration / 2)
    
    return tween

## 设置文本并播放打字机效果
func type_text(new_text: String, speed: float = -1) -> void:
    if speed > 0:
        typewriter_speed = speed
    set_text_with_effect(new_text, true)

## 追加文本
func append_text(append_str: String) -> void:
    _full_text += append_str
    text = _full_text

## 清除文本
func clear() -> void:
    _full_text = ""
    text = ""
    visible_characters = -1

## 获取原始完整文本（打字机效果期间）
func get_full_text() -> String:
    return _full_text

## 设置垂直对齐
func set_vertical_align(align: VerticalAlign) -> void:
    match align:
        VerticalAlign.TOP:
            vertical_alignment = VERTICAL_ALIGNMENT_TOP
        VerticalAlign.CENTER:
            vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        VerticalAlign.BOTTOM:
            vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

## 设置水平对齐
func set_horizontal_align(align: HorizontalAlignment) -> void:
    horizontal_alignment = align

## 设置自动换行
func set_autowrap(enable: bool) -> void:
    autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if enable else TextServer.AUTOWRAP_OFF

## 设置最大行数
func set_max_lines(lines: int) -> void:
    max_lines = lines

## 设置文本溢出处理
func set_text_overflow(overflow: TextServer.OverrunBehavior) -> void:
    text_overrun_behavior = overflow

## 截断文本并添加省略号
func truncate_with_ellipsis(max_length: int) -> void:
    if _full_text.length() > max_length:
        _full_text = _full_text.substr(0, max_length - 3) + "..."
        text = _full_text

## 创建标题标签（静态工厂方法）
static func create_heading(text: String, parent: Node = null) -> UILabel:
    var label := UILabel.new()
    label.text_style = TextStyle.HEADING
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if parent:
        parent.add_child(label)
    return label

## 创建正文标签（静态工厂方法）
static func create_body(text: String, parent: Node = null) -> UILabel:
    var label := UILabel.new()
    label.text_style = TextStyle.BODY
    label.text = text
    if parent:
        parent.add_child(label)
    return label

## 创建注释标签（静态工厂方法）
static func create_caption(text: String, parent: Node = null) -> UILabel:
    var label := UILabel.new()
    label.text_style = TextStyle.CAPTION
    label.text = text
    if parent:
        parent.add_child(label)
    return label