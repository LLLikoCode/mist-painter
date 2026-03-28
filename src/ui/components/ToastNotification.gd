## ToastNotification
## 弹出通知组件
## 显示临时消息

class_name ToastNotification
extends Panel

# 配置
@export var message: String = ""
@export var duration: float = 3.0
@export var icon: Texture2D = null

# 类型
enum ToastType {
    INFO,       # 信息
    SUCCESS,    # 成功
    WARNING,    # 警告
    ERROR       # 错误
}

@export var toast_type: ToastType = ToastType.INFO

# 内部节点
var icon_texture: TextureRect = null
var message_label: Label = null
var container: HBoxContainer = null

func _ready():
    # 设置自动布局
    anchors_preset = Control.PRESET_CENTER_TOP
    anchor_left = 0.5
    anchor_right = 0.5
    offset_left = -150
    offset_right = 150
    offset_top = 50
    offset_bottom = -50

    # 构建 UI
    _build_ui()

    # 初始隐藏
    visible = false

## 构建 UI
func _build_ui() -> void:
    # 创建容器
    container = HBoxContainer.new()
    container.name = "Container"
    container.anchors_preset = Control.PRESET_FULL_RECT
    container.alignment = BoxContainer.ALIGNMENT_CENTER
    container.add_theme_constant_override("separation", 10)
    add_child(container)

    # 图标
    if icon:
        icon_texture = TextureRect.new()
        icon_texture.name = "Icon"
        icon_texture.texture = icon
        icon_texture.custom_minimum_size = Vector2(24, 24)
        icon_texture.expand_mode = 3
        container.add_child(icon_texture)

    # 消息标签
    message_label = Label.new()
    message_label.name = "MessageLabel"
    message_label.text = message
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    container.add_child(message_label)

    # 根据类型设置颜色
    _apply_type_style()

## 应用类型样式
func _apply_type_style() -> void:
    match toast_type:
        ToastType.INFO:
            modulate = Color(0.9, 0.9, 0.95)
        ToastType.SUCCESS:
            modulate = Color(0.8, 0.95, 0.8)
        ToastType.WARNING:
            modulate = Color(0.95, 0.9, 0.7)
        ToastType.ERROR:
            modulate = Color(0.95, 0.75, 0.75)

## 显示通知
func show_notification() -> void:
    visible = true

    # 淡入动画
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)

    # 设置定时器
    await get_tree().create_timer(duration).timeout

    # 淡出动画
    tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.finished.connect(queue_free)
