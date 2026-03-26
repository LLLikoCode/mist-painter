## AnimationManager
## 动画管理器
## 负责管理UI动画和过渡效果

class_name AnimationManager
extends Node

# 动画类型
enum AnimationType {
    FADE_IN,
    FADE_OUT,
    SLIDE_IN_LEFT,
    SLIDE_IN_RIGHT,
    SLIDE_IN_UP,
    SLIDE_IN_DOWN,
    SLIDE_OUT_LEFT,
    SLIDE_OUT_RIGHT,
    SLIDE_OUT_UP,
    SLIDE_OUT_DOWN,
    SCALE_IN,
    SCALE_OUT,
    BOUNCE_IN,
    BOUNCE_OUT,
    SHAKE
}

# 缓动函数类型
enum EaseType {
    LINEAR,
    EASE_IN,
    EASE_OUT,
    EASE_IN_OUT,
    EASE_OUT_BACK,
    EASE_IN_BACK,
    EASE_OUT_BOUNCE,
    EASE_IN_BOUNCE
}

# 默认动画时长
const DEFAULT_DURATION: float = 0.3

# 当前运行的动画
var active_tweens: Dictionary = {}

# 信号
signal animation_started(node: Node, animation_type: AnimationType)
signal animation_finished(node: Node, animation_type: AnimationType)

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    print("AnimationManager initialized")

## 播放打开动画
func play_open_animation(control: Control, animation_type: AnimationType = AnimationType.FADE_IN, 
                         duration: float = DEFAULT_DURATION) -> void:
    if control == null or not is_instance_valid(control):
        return
    
    # 确保控件可见
    control.visible = true
    control.modulate.a = 0.0
    
    match animation_type:
        AnimationType.FADE_IN:
            await _fade_in(control, duration)
        AnimationType.SLIDE_IN_LEFT:
            await _slide_in(control, Vector2.LEFT, duration)
        AnimationType.SLIDE_IN_RIGHT:
            await _slide_in(control, Vector2.RIGHT, duration)
        AnimationType.SLIDE_IN_UP:
            await _slide_in(control, Vector2.UP, duration)
        AnimationType.SLIDE_IN_DOWN:
            await _slide_in(control, Vector2.DOWN, duration)
        AnimationType.SCALE_IN:
            await _scale_in(control, duration)
        AnimationType.BOUNCE_IN:
            await _bounce_in(control, duration)
        _:
            await _fade_in(control, duration)

## 播放关闭动画
func play_close_animation(control: Control, animation_type: AnimationType = AnimationType.FADE_OUT,
                          duration: float = DEFAULT_DURATION) -> void:
    if control == null or not is_instance_valid(control):
        return
    
    match animation_type:
        AnimationType.FADE_OUT:
            await _fade_out(control, duration)
        AnimationType.SLIDE_OUT_LEFT:
            await _slide_out(control, Vector2.LEFT, duration)
        AnimationType.SLIDE_OUT_RIGHT:
            await _slide_out(control, Vector2.RIGHT, duration)
        AnimationType.SLIDE_OUT_UP:
            await _slide_out(control, Vector2.UP, duration)
        AnimationType.SLIDE_OUT_DOWN:
            await _slide_out(control, Vector2.DOWN, duration)
        AnimationType.SCALE_OUT:
            await _scale_out(control, duration)
        AnimationType.BOUNCE_OUT:
            await _bounce_out(control, duration)
        _:
            await _fade_out(control, duration)
    
    control.visible = false

## 淡入动画
func _fade_in(control: Control, duration: float) -> void:
    var tween = _create_tween(control, "fade_in")
    control.modulate.a = 0.0
    tween.tween_property(control, "modulate:a", 1.0, duration)
    await tween.finished

## 淡出动画
func _fade_out(control: Control, duration: float) -> void:
    var tween = _create_tween(control, "fade_out")
    tween.tween_property(control, "modulate:a", 0.0, duration)
    await tween.finished

## 滑入动画
func _slide_in(control: Control, direction: Vector2, duration: float) -> void:
    var viewport_size = _get_viewport_size()
    var original_position = control.position
    var offset = direction * viewport_size
    
    control.position = original_position + offset
    control.modulate.a = 1.0
    
    var tween = _create_tween(control, "slide_in")
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(control, "position", original_position, duration)
    await tween.finished

## 滑出动画
func _slide_out(control: Control, direction: Vector2, duration: float) -> void:
    var viewport_size = _get_viewport_size()
    var target_position = control.position + direction * viewport_size
    
    var tween = _create_tween(control, "slide_out")
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(control, "position", target_position, duration)
    await tween.finished

## 缩入动画
func _scale_in(control: Control, duration: float) -> void:
    control.scale = Vector2.ZERO
    control.modulate.a = 1.0
    
    var tween = _create_tween(control, "scale_in")
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(control, "scale", Vector2.ONE, duration)
    await tween.finished

## 缩出动画
func _scale_out(control: Control, duration: float) -> void:
    var tween = _create_tween(control, "scale_out")
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(control, "scale", Vector2.ZERO, duration)
    await tween.finished

## 弹入动画
func _bounce_in(control: Control, duration: float) -> void:
    control.scale = Vector2.ZERO
    control.modulate.a = 1.0
    
    var tween = _create_tween(control, "bounce_in")
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BOUNCE)
    tween.tween_property(control, "scale", Vector2.ONE, duration)
    await tween.finished

## 弹出动画
func _bounce_out(control: Control, duration: float) -> void:
    var tween = _create_tween(control, "bounce_out")
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_BOUNCE)
    tween.tween_property(control, "scale", Vector2.ZERO, duration)
    await tween.finished

## 创建Tween
func _create_tween(node: Node, animation_name: String) -> Tween:
    # 停止之前的动画
    var node_id = node.get_instance_id()
    if active_tweens.has(node_id):
        var old_tween = active_tweens[node_id]
        if old_tween != null and old_tween.is_valid():
            old_tween.kill()
    
    var tween = create_tween()
    tween.set_parallel(false)
    
    active_tweens[node_id] = tween
    
    # 动画完成时清理
    tween.finished.connect(func(): 
        if active_tweens.has(node_id) and active_tweens[node_id] == tween:
            active_tweens.erase(node_id)
    )
    
    return tween

## 获取视口大小
func _get_viewport_size() -> Vector2:
    var viewport = get_viewport()
    if viewport:
        return viewport.get_visible_rect().size
    return Vector2(1920, 1080)

## 播放按钮悬停动画
func play_button_hover(button: Button, hovered: bool) -> void:
    if button == null or not is_instance_valid(button):
        return
    
    var target_scale = Vector2(1.05, 1.05) if hovered else Vector2.ONE
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(button, "scale", target_scale, 0.15)

## 播放按钮点击动画
func play_button_click(button: Button) -> void:
    if button == null or not is_instance_valid(button):
        return
    
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    
    # 缩小
    tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
    # 恢复
    tween.tween_property(button, "scale", Vector2.ONE, 0.1)

## 播放数值变化动画
func play_value_change(label: Label, from_value: float, to_value: float, 
                       duration: float = 0.5, prefix: String = "", suffix: String = "") -> void:
    if label == null or not is_instance_valid(label):
        return
    
    var tween = create_tween()
    var obj = {"value": from_value}
    
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(obj, "value", to_value, duration)
    
    tween.step_finished.connect(func(step: int):
        label.text = prefix + str(int(obj.value)) + suffix
    )

## 播放进度条动画
func play_progress_bar(progress_bar: ProgressBar, to_value: float, duration: float = 0.5) -> void:
    if progress_bar == null or not is_instance_valid(progress_bar):
        return
    
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(progress_bar, "value", to_value, duration)

## 播放抖动动画
func play_shake(control: Control, intensity: float = 10.0, duration: float = 0.5) -> void:
    if control == null or not is_instance_valid(control):
        return
    
    var original_position = control.position
    var tween = create_tween()
    
    var steps = 10
    var step_duration = duration / steps
    
    for i in range(steps):
        var offset = Vector2(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        )
        tween.tween_property(control, "position", original_position + offset, step_duration)
    
    tween.tween_property(control, "position", original_position, step_duration)

## 播放脉冲动画
func play_pulse(control: Control, scale_amount: float = 1.1, duration: float = 1.0) -> void:
    if control == null or not is_instance_valid(control):
        return
    
    var tween = create_tween()
    tween.set_loops()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(control, "scale", Vector2(scale_amount, scale_amount), duration / 2)
    tween.tween_property(control, "scale", Vector2.ONE, duration / 2)

## 停止所有动画
func stop_all_animations() -> void:
    for tween in active_tweens.values():
        if tween != null and tween.is_valid():
            tween.kill()
    active_tweens.clear()

## 停止指定节点的动画
func stop_animation(node: Node) -> void:
    var node_id = node.get_instance_id()
    if active_tweens.has(node_id):
        var tween = active_tweens[node_id]
        if tween != null and tween.is_valid():
            tween.kill()
        active_tweens.erase(node_id)

## 检查节点是否有动画在运行
func is_animating(node: Node) -> bool:
    var node_id = node.get_instance_id()
    if active_tweens.has(node_id):
        var tween = active_tweens[node_id]
        return tween != null and tween.is_valid() and tween.is_running()
    return false
