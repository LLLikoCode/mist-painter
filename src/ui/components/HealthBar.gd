## HealthBar
## 生命值条组件
## 带图标和数值显示

class_name HealthBar
extends Control

# 配置
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var show_icon: bool = true
@export var show_text: bool = true
@export var animate_changes: bool = true
@export var bar_color: Color = Color(0.9, 0.2, 0.2)
@export var bar_bg_color: Color = Color(0.2, 0.2, 0.25)

# 内部节点
var icon_texture: TextureRect = null
var progress_bar: ProgressBar = null
var health_label: Label = null
var container: HBoxContainer = null

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
        # TODO: 加载生命值图标
        # icon_texture.texture = load("res://assets/ui/icons/health.png")
        container.add_child(icon_texture)
    
    # 创建进度条
    progress_bar = ProgressBar.new()
    progress_bar.name = "ProgressBar"
    progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    progress_bar.max_value = max_health
    progress_bar.value = current_health
    progress_bar.show_percentage = false
    container.add_child(progress_bar)
    
    # 创建数值标签
    if show_text:
        health_label = Label.new()
        health_label.name = "HealthLabel"
        health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        health_label.custom_minimum_size = Vector2(80, 0)
        container.add_child(health_label)

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
    
    # 进度条填充
    var fill_style = StyleBoxFlat.new()
    fill_style.bg_color = bar_color
    fill_style.corner_radius_top_left = 4
    fill_style.corner_radius_top_right = 4
    fill_style.corner_radius_bottom_left = 4
    fill_style.corner_radius_bottom_right = 4
    
    progress_bar.add_theme_stylebox_override("background", bg_style)
    progress_bar.add_theme_stylebox_override("fill", fill_style)
    
    # 设置标签样式
    if health_label and theme_manager:
        health_label.add_theme_color_override("font_color", theme_manager.get_color("text"))

func _update_display() -> void:
    if progress_bar:
        progress_bar.max_value = max_health
        progress_bar.value = current_health
    
    if health_label:
        health_label.text = "%d / %d" % [int(current_health), int(max_health)]

## 设置生命值
func set_health(health: float, animate: bool = true) -> void:
    var old_health = current_health
    current_health = clamp(health, 0, max_health)
    
    if animate and animate_changes:
        _animate_health_change(old_health, current_health)
    else:
        _update_display()

func _animate_health_change(from_value: float, to_value: float) -> void:
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    
    var obj = {"value": from_value}
    tween.tween_property(obj, "value", to_value, 0.3)
    
    tween.step_finished.connect(func(step: int):
        current_health = obj.value
        _update_display()
    )
    
    await tween.finished
    current_health = to_value
    _update_display()

## 设置最大生命值
func set_max_health(max_hp: float) -> void:
    max_health = max_hp
    current_health = clamp(current_health, 0, max_health)
    _update_display()

## 获取当前生命值
func get_health() -> float:
    return current_health

## 获取最大生命值
func get_max_health() -> float:
    return max_health

## 获取生命值百分比
func get_health_percentage() -> float:
    return current_health / max_health if max_health > 0 else 0.0

## 受到伤害
func take_damage(amount: float) -> void:
    set_health(current_health - amount)

## 恢复生命
func heal(amount: float) -> void:
    set_health(current_health + amount)
