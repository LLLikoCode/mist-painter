## MistBar
## 迷雾值条组件
## 游戏核心资源显示

class_name MistBar
extends Control

# 配置
@export var max_mist: float = 100.0
@export var current_mist: float = 100.0
@export var show_icon: bool = true
@export var show_text: bool = true
@export var animate_changes: bool = true
@export var bar_color: Color = Color(0.4, 0.7, 0.9)  # 迷雾蓝
@export var bar_bg_color: Color = Color(0.15, 0.2, 0.3)
@export var glow_effect: bool = true

# 内部节点
var icon_texture: TextureRect = null
var progress_bar: ProgressBar = null
var mist_label: Label = null
var container: HBoxContainer = null
var glow_panel: Panel = null

func _ready():
    # 设置最小尺寸
    custom_minimum_size = Vector2(200, 32)
    
    # 创建布局
    _create_layout()
    
    # 应用样式
    _apply_style()
    
    # 更新显示
    _update_display()

func _create_layout() -> void:
    # 创建发光效果背景（可选）
    if glow_effect:
        glow_panel = Panel.new()
        glow_panel.name = "GlowPanel"
        glow_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        glow_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
        add_child(glow_panel)
    
    # 创建主容器
    container = HBoxContainer.new()
    container.name = "Container"
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(container)
    
    # 创建图标
    if show_icon:
        icon_texture = TextureRect.new()
        icon_texture.name = "Icon"
        icon_texture.custom_minimum_size = Vector2(24, 24)
        icon_texture.expand_mode = TextureRect.EXPAND_FIT_SIZE
        icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        # TODO: 加载迷雾图标
        # icon_texture.texture = load("res://assets/ui/icons/mist.png")
        container.add_child(icon_texture)
    
    # 创建进度条
    progress_bar = ProgressBar.new()
    progress_bar.name = "ProgressBar"
    progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    progress_bar.max_value = max_mist
    progress_bar.value = current_mist
    progress_bar.show_percentage = false
    container.add_child(progress_bar)
    
    # 创建数值标签
    if show_text:
        mist_label = Label.new()
        mist_label.name = "MistLabel"
        mist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        mist_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        mist_label.custom_minimum_size = Vector2(80, 0)
        container.add_child(mist_label)

func _apply_style() -> void:
    if progress_bar == null:
        return
    
    var theme_manager = UIManager.instance.theme_manager if UIManager.instance else null
    
    # 进度条背景
    var bg_style = StyleBoxFlat.new()
    bg_style.bg_color = bar_bg_color
    bg_style.corner_radius_top_left = 4
    bg_style.corner_radius_top_right = 4
    bg_style.corner_radius_bottom_left = 4
    bg_style.corner_radius_bottom_right = 4
    
    # 进度条填充 - 使用渐变效果
    var fill_style = StyleBoxFlat.new()
    fill_style.bg_color = bar_color
    fill_style.corner_radius_top_left = 4
    fill_style.corner_radius_top_right = 4
    fill_style.corner_radius_bottom_left = 4
    fill_style.corner_radius_bottom_right = 4
    
    progress_bar.add_theme_stylebox_override("background", bg_style)
    progress_bar.add_theme_stylebox_override("fill", fill_style)
    
    # 设置标签样式
    if mist_label and theme_manager:
        mist_label.add_theme_color_override("font_color", theme_manager.get_color("text"))
    
    # 设置发光效果
    if glow_panel:
        var glow_style = StyleBoxFlat.new()
        glow_style.bg_color = bar_color
        glow_style.bg_color.a = 0.1
        glow_style.corner_radius_top_left = 8
        glow_style.corner_radius_top_right = 8
        glow_style.corner_radius_bottom_left = 8
        glow_style.corner_radius_bottom_right = 8
        glow_panel.add_theme_stylebox_override("panel", glow_style)

func _update_display() -> void:
    if progress_bar:
        progress_bar.max_value = max_mist
        progress_bar.value = current_mist
    
    if mist_label:
        mist_label.text = "%d / %d" % [int(current_mist), int(max_mist)]
    
    # 更新发光效果强度
    _update_glow()

func _update_glow() -> void:
    if glow_panel == null:
        return
    
    var percentage = current_mist / max_mist if max_mist > 0 else 0.0
    var glow_style = glow_panel.get_theme_stylebox("panel") as StyleBoxFlat
    if glow_style:
        glow_style.bg_color.a = 0.05 + percentage * 0.15

## 设置迷雾值
func set_mist(mist: float, animate: bool = true) -> void:
    var old_mist = current_mist
    current_mist = clamp(mist, 0, max_mist)
    
    if animate and animate_changes:
        _animate_mist_change(old_mist, current_mist)
    else:
        _update_display()

func _animate_mist_change(from_value: float, to_value: float) -> void:
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    
    var obj = {"value": from_value}
    tween.tween_property(obj, "value", to_value, 0.3)
    
    tween.step_finished.connect(func(step: int):
        current_mist = obj.value
        _update_display()
    )
    
    await tween.finished
    current_mist = to_value
    _update_display()

## 设置最大迷雾值
func set_max_mist(max_m: float) -> void:
    max_mist = max_m
    current_mist = clamp(current_mist, 0, max_mist)
    _update_display()

## 获取当前迷雾值
func get_mist() -> float:
    return current_mist

## 获取最大迷雾值
func get_max_mist() -> float:
    return max_mist

## 获取迷雾百分比
func get_mist_percentage() -> float:
    return current_mist / max_mist if max_mist > 0 else 0.0

## 消耗迷雾
func consume(amount: float) -> bool:
    if current_mist >= amount:
        set_mist(current_mist - amount)
        return true
    return false

## 恢复迷雾
func restore(amount: float) -> void:
    set_mist(current_mist + amount)

## 检查迷雾是否充足
func has_enough_mist(amount: float) -> bool:
    return current_mist >= amount
