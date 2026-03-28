## UIPanel
## 羊皮纸风格面板组件
## 支持标题栏、阴影效果、边框样式

class_name UIPanel
extends PanelContainer

# ============================================
# 枚举定义
# ============================================

## 面板样式变体
enum PanelVariant {
    DEFAULT,    ## 默认样式 - 羊皮纸中色
    LIGHT,      ## 浅色 - 羊皮纸浅色
    DARK,       ## 深色 - 羊皮纸深色
    AGED,       ## 旧色 - 羊皮纸旧色
    TRANSPARENT ## 透明 - 半透明背景
}

## 边框样式
enum BorderStyle {
    NONE,       ## 无边框
    THIN,       ## 细边框
    MEDIUM,     ## 中等边框
    THICK,      ## 粗边框
    DECORATIVE  ## 装饰边框
}

# ============================================
# 导出变量
# ============================================

@export_group("Panel Settings")
@export var panel_variant: PanelVariant = PanelVariant.DEFAULT:
    set = set_panel_variant

@export var border_style: BorderStyle = BorderStyle.MEDIUM:
    set = set_border_style

@export_group("Title Settings")
@export var show_title: bool = false:
    set = set_show_title

@export var title_text: String = "":
    set = set_title_text

@export var title_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

@export_group("Content Settings")
@export var content_margin: int = 16:
    set = set_content_margin

@export_group("Effects")
@export var enable_shadow: bool = true:
    set = set_enable_shadow

@export var shadow_color: Color = UITheme.SHADOW
@export var shadow_size: int = 8
@export var shadow_offset: Vector2 = Vector2(4, 4)

@export var enable_corner_decoration: bool = false

# ============================================
# 内部变量
# ============================================

var _title_label: UILabel
var _title_container: PanelContainer
var _content_container: MarginContainer
var _main_vbox: VBoxContainer

var _panel_style: StyleBoxFlat
var _title_style: StyleBoxFlat

# ============================================
# 生命周期
# ============================================

func _ready():
    # 构建UI结构
    _build_ui()
    
    # 应用样式
    _build_styles()
    _apply_styles()

func _build_ui() -> void:
    # 创建主垂直布局
    _main_vbox = VBoxContainer.new()
    _main_vbox.name = "MainVBox"
    add_child(_main_vbox)
    
    # 创建标题容器
    _title_container = PanelContainer.new()
    _title_container.name = "TitleContainer"
    _title_container.visible = show_title
    _main_vbox.add_child(_title_container)
    
    # 创建标题标签
    _title_label = UILabel.new()
    _title_label.name = "TitleLabel"
    _title_label.text_style = UILabel.TextStyle.TITLE
    _title_label.horizontal_alignment = title_alignment
    _title_container.add_child(_title_label)
    
    # 创建内容容器（带边距）
    _content_container = MarginContainer.new()
    _content_container.name = "ContentContainer"
    _main_vbox.add_child(_content_container)
    
    # 设置内容边距
    _update_content_margin()
    
    # 将原有子节点移动到内容容器
    _reparent_children()

func _reparent_children() -> void:
    # 获取所有非UI构建的子节点
    var children_to_move := []
    for child in get_children():
        if child != _main_vbox:
            children_to_move.append(child)
    
    # 移动到内容容器
    for child in children_to_move:
        remove_child(child)
        _content_container.add_child(child)

# ============================================
# 样式构建
# ============================================

func _build_styles() -> void:
    # 获取背景颜色
    var bg_color := _get_background_color()
    var border_color := UITheme.INK_BROWN
    var border_width := _get_border_width()
    var corner_radius := UITheme.RADIUS_MEDIUM
    
    # 构建面板样式
    _panel_style = StyleBoxFlat.new()
    _panel_style.bg_color = bg_color
    _panel_style.border_color = border_color
    _panel_style.border_width_left = border_width
    _panel_style.border_width_right = border_width
    _panel_style.border_width_top = border_width
    _panel_style.border_width_bottom = border_width
    _panel_style.corner_radius_top_left = corner_radius
    _panel_style.corner_radius_top_right = corner_radius
    _panel_style.corner_radius_bottom_left = corner_radius
    _panel_style.corner_radius_bottom_right = corner_radius
    
    # 应用阴影
    if enable_shadow:
        _panel_style.shadow_color = shadow_color
        _panel_style.shadow_size = shadow_size
        _panel_style.shadow_offset = shadow_offset
    
    # 构建标题样式
    var title_bg_color := UITheme.darken(bg_color, 0.05)
    _title_style = StyleBoxFlat.new()
    _title_style.bg_color = title_bg_color
    _title_style.border_color = border_color
    _title_style.border_width_left = border_width
    _title_style.border_width_right = border_width
    _title_style.border_width_top = border_width
    _title_style.border_width_bottom = border_width
    _title_style.corner_radius_top_left = corner_radius
    _title_style.corner_radius_top_right = corner_radius
    _title_style.corner_radius_bottom_left = 0
    _title_style.corner_radius_bottom_right = 0

func _get_background_color() -> Color:
    match panel_variant:
        PanelVariant.LIGHT:
            return UITheme.PAPER_LIGHT
        PanelVariant.DARK:
            return UITheme.PAPER_DARK
        PanelVariant.AGED:
            return UITheme.PAPER_AGED
        PanelVariant.TRANSPARENT:
            return UITheme.with_alpha(UITheme.PAPER_MEDIUM, 0.85)
        _:
            return UITheme.PAPER_MEDIUM

func _get_border_width() -> int:
    match border_style:
        BorderStyle.NONE:
            return 0
        BorderStyle.THIN:
            return 1
        BorderStyle.MEDIUM:
            return 2
        BorderStyle.THICK:
            return 3
        BorderStyle.DECORATIVE:
            return 2
        _:
            return 2

func _apply_styles() -> void:
    # 应用面板样式
    add_theme_stylebox_override("panel", _panel_style)
    
    # 应用标题样式
    if _title_container != null:
        _title_container.add_theme_stylebox_override("panel", _title_style)
    
    # 更新标题文本
    if _title_label != null:
        _title_label.text = title_text

func _update_content_margin() -> void:
    if _content_container != null:
        _content_container.add_theme_constant_override("margin_left", content_margin)
        _content_container.add_theme_constant_override("margin_right", content_margin)
        _content_container.add_theme_constant_override("margin_top", content_margin)
        _content_container.add_theme_constant_override("margin_bottom", content_margin)

# ============================================
# 公共方法
# ============================================

## 设置面板变体
func set_panel_variant(variant: PanelVariant) -> void:
    panel_variant = variant
    if is_node_ready():
        _build_styles()
        _apply_styles()

## 设置边框样式
func set_border_style(style: BorderStyle) -> void:
    border_style = style
    if is_node_ready():
        _build_styles()
        _apply_styles()

## 设置是否显示标题
func set_show_title(show: bool) -> void:
    show_title = show
    if _title_container != null:
        _title_container.visible = show

## 设置标题文本
func set_title_text(text: String) -> void:
    title_text = text
    if _title_label != null:
        _title_label.text = text

## 设置内容边距
func set_content_margin(margin: int) -> void:
    content_margin = margin
    if is_node_ready():
        _update_content_margin()

## 设置是否启用阴影
func set_enable_shadow(enable: bool) -> void:
    enable_shadow = enable
    if is_node_ready():
        _build_styles()
        _apply_styles()

## 获取内容容器（用于添加子节点）
func get_content_container() -> Container:
    return _content_container

## 添加子节点到内容区域
func add_content(child: Node) -> void:
    if _content_container != null:
        _content_container.add_child(child)
    else:
        add_child(child)

## 移除内容区域的所有子节点
func clear_content() -> void:
    if _content_container != null:
        for child in _content_container.get_children():
            child.queue_free()
