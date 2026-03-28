## UIAnimation
## UI动画工具类
## 提供常用的UI动画效果，使用Godot Tween系统
## 基于美术风格指南的动画规范

class_name UIAnimation
extends RefCounted

# ============================================
# 内部辅助类
# ============================================

## 数值包装器类（用于 Tween 动画）
class _ValueWrapper extends RefCounted:
    var value: float = 0.0

# ============================================
# 动画类型枚举
# ============================================

enum AnimationType {
    FADE_IN,           # 淡入
    FADE_OUT,          # 淡出
    SLIDE_IN_LEFT,     # 从左滑入
    SLIDE_IN_RIGHT,    # 从右滑入
    SLIDE_IN_UP,       # 从上滑入
    SLIDE_IN_DOWN,     # 从下滑入
    SLIDE_OUT_LEFT,    # 向左滑出
    SLIDE_OUT_RIGHT,   # 向右滑出
    SLIDE_OUT_UP,      # 向上滑出
    SLIDE_OUT_DOWN,    # 向下滑出
    SCALE_IN,          # 缩放入
    SCALE_OUT,         # 缩放出
    BOUNCE_IN,         # 弹入
    BOUNCE_OUT,        # 弹出
    SHAKE,             # 抖动
    PULSE,             # 脉冲
    FLIP_HORIZONTAL,   # 水平翻转
    FLIP_VERTICAL      # 垂直翻转
}

# ============================================
# 缓动类型枚举
# ============================================

enum EaseType {
    LINEAR,         # 线性
    EASE_IN,        # 缓入
    EASE_OUT,       # 缓出
    EASE_IN_OUT,    # 缓入缓出
    BACK_IN,        # 回弹入
    BACK_OUT,       # 回弹出
    BOUNCE_IN,      # 弹跳入
    BOUNCE_OUT,     # 弹跳出
    ELASTIC_IN,     # 弹性入
    ELASTIC_OUT     # 弹性出
}

# ============================================
# 默认时长常量
# ============================================

const DURATION_FAST: float = 0.15      # 快速动画（按钮悬停）
const DURATION_NORMAL: float = 0.3     # 正常动画（界面切换）
const DURATION_SLOW: float = 0.5       # 慢速动画（强调效果）
const DURATION_SHAKE: float = 0.5      # 抖动动画
const DURATION_PULSE: float = 1.0      # 脉冲动画

# ============================================
# 当前运行的动画追踪
# ============================================

static var _active_tweens: Dictionary = {}

# ============================================
# 基础动画方法
# ============================================

## 淡入动画
static func fade_in(
    control: Control,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.EASE_OUT
) -> Tween:
    var tween := _create_tween(control, "fade_in")
    control.modulate.a = 0.0
    control.visible = true
    
    _apply_ease(tween, ease_type)
    tween.tween_property(control, "modulate:a", 1.0, duration)
    
    return tween

## 淡出动画
static func fade_out(
    control: Control,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.EASE_IN,
    hide_on_finish: bool = true
) -> Tween:
    var tween := _create_tween(control, "fade_out")
    
    _apply_ease(tween, ease_type)
    var fade_tween := tween.tween_property(control, "modulate:a", 0.0, duration)
    
    if hide_on_finish:
        fade_tween.finished.connect(func(): control.visible = false)
    
    return tween

## 滑入动画
static func slide_in(
    control: Control,
    direction: Vector2,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.EASE_OUT
) -> Tween:
    var tween := _create_tween(control, "slide_in")
    var viewport_size := _get_viewport_size(control)
    var original_pos := control.position
    
    control.position = original_pos + direction * viewport_size
    control.visible = true
    control.modulate.a = 1.0
    
    _apply_ease(tween, ease_type, Tween.TRANS_QUAD)
    tween.tween_property(control, "position", original_pos, duration)
    
    return tween

## 滑出动画
static func slide_out(
    control: Control,
    direction: Vector2,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.EASE_IN,
    hide_on_finish: bool = true
) -> Tween:
    var tween := _create_tween(control, "slide_out")
    var viewport_size := _get_viewport_size(control)
    var target_pos := control.position + direction * viewport_size
    
    _apply_ease(tween, ease_type, Tween.TRANS_QUAD)
    var slide_tween := tween.tween_property(control, "position", target_pos, duration)
    
    if hide_on_finish:
        slide_tween.finished.connect(func(): control.visible = false)
    
    return tween

## 缩放入动画
static func scale_in(
    control: Control,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.BACK_OUT
) -> Tween:
    var tween := _create_tween(control, "scale_in")
    
    control.scale = Vector2.ZERO
    control.visible = true
    control.modulate.a = 1.0
    
    _apply_ease(tween, ease_type, Tween.TRANS_BACK)
    tween.tween_property(control, "scale", Vector2.ONE, duration)
    
    return tween

## 缩放出动画
static func scale_out(
    control: Control,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.BACK_IN,
    hide_on_finish: bool = true
) -> Tween:
    var tween := _create_tween(control, "scale_out")
    
    _apply_ease(tween, ease_type, Tween.TRANS_BACK)
    var scale_tween := tween.tween_property(control, "scale", Vector2.ZERO, duration)
    
    if hide_on_finish:
        scale_tween.finished.connect(func(): control.visible = false)
    
    return tween

## 弹入动画
static func bounce_in(
    control: Control,
    duration: float = DURATION_NORMAL
) -> Tween:
    var tween := _create_tween(control, "bounce_in")
    
    control.scale = Vector2.ZERO
    control.visible = true
    control.modulate.a = 1.0
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BOUNCE)
    tween.tween_property(control, "scale", Vector2.ONE, duration)
    
    return tween

## 弹出动画
static func bounce_out(
    control: Control,
    duration: float = DURATION_NORMAL,
    hide_on_finish: bool = true
) -> Tween:
    var tween := _create_tween(control, "bounce_out")
    
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_BOUNCE)
    var bounce_tween := tween.tween_property(control, "scale", Vector2.ZERO, duration)
    
    if hide_on_finish:
        bounce_tween.finished.connect(func(): control.visible = false)
    
    return tween

# ============================================
# 特殊效果动画
# ============================================

## 抖动动画
static func shake(
    control: Control,
    intensity: float = 10.0,
    duration: float = DURATION_SHAKE,
    shake_count: int = 10
) -> Tween:
    var tween := _create_tween(control, "shake")
    var original_pos := control.position
    
    var step_duration := duration / shake_count
    
    for i in shake_count:
        var offset := Vector2(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        )
        tween.tween_property(control, "position", original_pos + offset, step_duration)
    
    # 回到原位
    tween.tween_property(control, "position", original_pos, step_duration)
    
    return tween

## 脉冲动画（循环）
static func pulse(
    control: Control,
    scale_amount: float = 1.1,
    duration: float = DURATION_PULSE
) -> Tween:
    var tween := _create_tween(control, "pulse")
    
    tween.set_loops()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(control, "scale", Vector2(scale_amount, scale_amount), duration / 2)
    tween.tween_property(control, "scale", Vector2.ONE, duration / 2)
    
    return tween

## 停止脉冲动画
static func stop_pulse(control: Control) -> void:
    stop_animation(control, "pulse")
    control.scale = Vector2.ONE

## 数值变化动画
static func animate_value(
    from_value: float,
    to_value: float,
    duration: float = DURATION_NORMAL,
    callback: Callable = Callable(),
    ease_type: EaseType = EaseType.EASE_OUT
) -> Tween:
    # 使用 RefCounted 类来存储数值
    var value_wrapper = _ValueWrapper.new()
    value_wrapper.value = from_value

    var tween := _create_tween_for_object(value_wrapper, "value_animation")

    _apply_ease(tween, ease_type, Tween.TRANS_QUAD)

    if callback.is_valid():
        tween.step_finished.connect(func(step: int):
            callback.call(value_wrapper.value)
        )

    tween.tween_property(value_wrapper, "value", to_value, duration)

    return tween

## 颜色过渡动画
static func transition_color(
    control: Control,
    property: String,
    target_color: Color,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.EASE_OUT
) -> Tween:
    var tween := _create_tween(control, "color_transition")
    
    _apply_ease(tween, ease_type, Tween.TRANS_QUAD)
    tween.tween_property(control, property, target_color, duration)
    
    return tween

# ============================================
# 按钮专用动画
# ============================================

## 按钮悬停动画
static func button_hover(
    button: Control,
    hovered: bool,
    scale_amount: float = 1.05
) -> Tween:
    var tween := _create_tween(button, "button_hover")
    var target_scale := Vector2(scale_amount, scale_amount) if hovered else Vector2.ONE
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(button, "scale", target_scale, DURATION_FAST)
    
    return tween

## 按钮点击动画
static func button_click(
    button: Control,
    scale_down: float = 0.95,
    scale_up: float = 1.0
) -> Tween:
    var tween := _create_tween(button, "button_click")
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    
    # 按下
    tween.tween_property(button, "scale", Vector2(scale_down, scale_down), 0.05)
    # 弹起
    tween.tween_property(button, "scale", Vector2(scale_up, scale_up), 0.1)
    
    return tween

## 按钮禁用动画
static func button_disable(button: Control) -> Tween:
    var tween := _create_tween(button, "button_disable")
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(button, "modulate", Color(0.5, 0.5, 0.5, 0.5), DURATION_FAST)
    
    return tween

## 按钮启用动画
static func button_enable(button: Control) -> Tween:
    var tween := _create_tween(button, "button_enable")
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(button, "modulate", Color.WHITE, DURATION_FAST)
    
    return tween

# ============================================
# 进度条动画
# ============================================

## 进度条动画
static func animate_progress(
    progress_bar: ProgressBar,
    target_value: float,
    duration: float = DURATION_NORMAL,
    ease_type: EaseType = EaseType.EASE_OUT
) -> Tween:
    var tween := _create_tween(progress_bar, "progress")
    
    _apply_ease(tween, ease_type, Tween.TRANS_QUAD)
    tween.tween_property(progress_bar, "value", target_value, duration)
    
    return tween

# ============================================
# 组合动画
# ============================================

## 打开屏幕动画（淡入+缩放）
static func open_screen(
    control: Control,
    duration: float = DURATION_NORMAL
) -> Tween:
    var tween := _create_tween(control, "open_screen")
    
    control.scale = Vector2(0.9, 0.9)
    control.modulate.a = 0.0
    control.visible = true
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_parallel(true)
    tween.tween_property(control, "scale", Vector2.ONE, duration)
    tween.tween_property(control, "modulate:a", 1.0, duration)
    
    return tween

## 关闭屏幕动画（淡出+缩小）
static func close_screen(
    control: Control,
    duration: float = DURATION_NORMAL,
    hide_on_finish: bool = true
) -> Tween:
    var tween := _create_tween(control, "close_screen")
    
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_parallel(true)
    
    var scale_tween := tween.tween_property(control, "scale", Vector2(0.9, 0.9), duration)
    var fade_tween := tween.tween_property(control, "modulate:a", 0.0, duration)
    
    if hide_on_finish:
        tween.finished.connect(func(): control.visible = false)
    
    return tween

## 高亮动画
static func highlight(
    control: Control,
    duration: float = DURATION_SLOW
) -> Tween:
    var tween := _create_tween(control, "highlight")
    var original_modulate := control.modulate
    
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(control, "modulate", Color.WHITE * 1.3, duration / 2)
    tween.tween_property(control, "modulate", original_modulate, duration / 2)
    
    return tween

# ============================================
# 动画管理
# ============================================

## 停止指定控件的所有动画
static func stop_all_animations(control: Control) -> void:
    var id := _get_control_id(control)
    if _active_tweens.has(id):
        for tween in _active_tweens[id].values():
            if tween != null and tween.is_valid():
                tween.kill()
        _active_tweens.erase(id)

## 停止指定动画
static func stop_animation(control: Control, animation_name: String) -> void:
    var id := _get_control_id(control)
    if _active_tweens.has(id) and _active_tweens[id].has(animation_name):
        var tween: Tween = _active_tweens[id][animation_name]
        if tween != null and tween.is_valid():
            tween.kill()
        _active_tweens[id].erase(animation_name)

## 检查是否有动画在运行
static func is_animating(control: Control, animation_name: String = "") -> bool:
    var id := _get_control_id(control)
    if not _active_tweens.has(id):
        return false
    
    if animation_name.is_empty():
        # 检查是否有任何动画在运行
        for tween in _active_tweens[id].values():
            if tween != null and tween.is_valid() and tween.is_running():
                return true
        return false
    else:
        # 检查特定动画
        if _active_tweens[id].has(animation_name):
            var tween: Tween = _active_tweens[id][animation_name]
            return tween != null and tween.is_valid() and tween.is_running()
        return false

## 等待动画完成
static func await_animation(control: Control, animation_name: String) -> void:
    if is_animating(control, animation_name):
        var id := _get_control_id(control)
        var tween: Tween = _active_tweens[id][animation_name]
        if tween != null and tween.is_valid():
            await tween.finished

# ============================================
# 内部辅助方法
# ============================================

## 创建Tween并追踪
static func _create_tween(control: Control, animation_name: String) -> Tween:
    var id := _get_control_id(control)
    
    # 初始化追踪字典
    if not _active_tweens.has(id):
        _active_tweens[id] = {}
    
    # 停止同类型的旧动画
    if _active_tweens[id].has(animation_name):
        var old_tween: Tween = _active_tweens[id][animation_name]
        if old_tween != null and old_tween.is_valid():
            old_tween.kill()
    
    # 创建新Tween
    var tween := control.create_tween()
    tween.set_parallel(false)
    
    _active_tweens[id][animation_name] = tween
    
    # 动画完成时清理
    tween.finished.connect(func():
        if _active_tweens.has(id) and _active_tweens[id].has(animation_name):
            if _active_tweens[id][animation_name] == tween:
                _active_tweens[id].erase(animation_name)
    )
    
    return tween

## 为普通对象创建Tween
static func _create_tween_for_object(obj: Object, animation_name: String) -> Tween:
    # 创建一个临时节点来处理Tween
    var temp_node := Node.new()
    Engine.get_main_loop().root.add_child(temp_node)
    
    var tween := temp_node.create_tween()
    
    tween.finished.connect(func():
        temp_node.queue_free()
    )
    
    return tween

## 应用缓动设置
static func _apply_ease(
    tween: Tween,
    ease_type: EaseType,
    default_trans: Tween.TransitionType = Tween.TRANS_LINEAR
) -> void:
    match ease_type:
        EaseType.LINEAR:
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(Tween.TRANS_LINEAR)
        EaseType.EASE_IN:
            tween.set_ease(Tween.EASE_IN)
            tween.set_trans(default_trans)
        EaseType.EASE_OUT:
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(default_trans)
        EaseType.EASE_IN_OUT:
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(default_trans)
        EaseType.BACK_IN:
            tween.set_ease(Tween.EASE_IN)
            tween.set_trans(Tween.TRANS_BACK)
        EaseType.BACK_OUT:
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_BACK)
        EaseType.BOUNCE_IN:
            tween.set_ease(Tween.EASE_IN)
            tween.set_trans(Tween.TRANS_BOUNCE)
        EaseType.BOUNCE_OUT:
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_BOUNCE)
        EaseType.ELASTIC_IN:
            tween.set_ease(Tween.EASE_IN)
            tween.set_trans(Tween.TRANS_ELASTIC)
        EaseType.ELASTIC_OUT:
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_ELASTIC)

## 获取控件唯一ID
static func _get_control_id(control: Control) -> int:
    return control.get_instance_id()

## 获取视口大小
static func _get_viewport_size(control: Control) -> Vector2:
    var viewport := control.get_viewport()
    if viewport:
        return viewport.get_visible_rect().size
    return Vector2(1920, 1080)

## 获取预定义方向的滑入滑出
static func slide_in_from_left(control: Control, duration: float = DURATION_NORMAL) -> Tween:
    return slide_in(control, Vector2.LEFT, duration)

static func slide_in_from_right(control: Control, duration: float = DURATION_NORMAL) -> Tween:
    return slide_in(control, Vector2.RIGHT, duration)

static func slide_in_from_top(control: Control, duration: float = DURATION_NORMAL) -> Tween:
    return slide_in(control, Vector2.UP, duration)

static func slide_in_from_bottom(control: Control, duration: float = DURATION_NORMAL) -> Tween:
    return slide_in(control, Vector2.DOWN, duration)

static func slide_out_to_left(control: Control, duration: float = DURATION_NORMAL, hide_on_finish: bool = true) -> Tween:
    return slide_out(control, Vector2.LEFT, duration, EaseType.EASE_IN, hide_on_finish)

static func slide_out_to_right(control: Control, duration: float = DURATION_NORMAL, hide_on_finish: bool = true) -> Tween:
    return slide_out(control, Vector2.RIGHT, duration, EaseType.EASE_IN, hide_on_finish)

static func slide_out_to_top(control: Control, duration: float = DURATION_NORMAL, hide_on_finish: bool = true) -> Tween:
    return slide_out(control, Vector2.UP, duration, EaseType.EASE_IN, hide_on_finish)

static func slide_out_to_bottom(control: Control, duration: float = DURATION_NORMAL, hide_on_finish: bool = true) -> Tween:
    return slide_out(control, Vector2.DOWN, duration, EaseType.EASE_IN, hide_on_finish)