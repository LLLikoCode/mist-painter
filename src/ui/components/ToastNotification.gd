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
