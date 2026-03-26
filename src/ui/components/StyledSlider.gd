## StyledSlider
## 样式化滑块组件
## 支持数值显示、步进调节

class_name StyledSlider
extends HSlider

# 显示模式
enum DisplayMode {
    NONE,       # 不显示数值
    PERCENTAGE, # 显示百分比
    VALUE,      # 显示数值
    CUSTOM      # 自定义格式
}

# 配置
@export var display_mode: DisplayMode = DisplayMode.PERCENTAGE
@export var show_value_label: bool = true
@export var value_label_format: String = "%d"
@export var min_value_display: float = 0.0
@export var max_value_display: float = 100.0
@export var step_size: float = 1.0

# 数值标签
var value_label: Label = null

func _ready():
    # 设置步进
    step = step_size
    
