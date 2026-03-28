## DialogBox
## 对话框组件
## 带打字机效果

class_name DialogBox
extends Panel

# 配置
@export var title: String = ""
@export var message: String = ""
@export var confirm_text: String = "确定"
@export var cancel_text: String = ""
@export var show_close_button: bool = true
@export var typewriter_effect: bool = true
@export var typewriter_speed: float = 0.05

# 回调
var on_confirm: Callable = Callable()
var on_cancel: Callable = Callable()

# 内部节点
var title_label: Label = null
var message_label: Label = null
var confirm_button: StyledButton = null
var cancel_button: StyledButton = null
var close_button: Button = null
var button_container: HBoxContainer = null

# 打字机状态
var is_typing: bool = false
var full_text: String = ""
var current_text: String = ""
var char_index: int = 0

func _ready():
    # 设置模态
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 创建布局
    _create_layout()
    
    # 应用样式
    _apply_style()
    
    # 设置内容
    _update_content()
    
    # 居中显示
    _center_dialog()

func _create_layout() -> void:
    # 设置大小和锚点
    custom_minimum_size = Vector2(400, 200)
    size = Vector2(400, 200)
    anchors_preset = Control.PRESET_CENTER
    
    # 创建主容器
    var margin = MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    add_child(margin)
    
    var vbox = VBoxContainer.new()
    vbox.name = "VBox"
    vbox.add_theme_constant_override("separation", 16)
    margin.add_child(vbox)
    
    # 创建标题行
    var title_hbox = HBoxContainer.new()
    title_hbox.name = "TitleHBox"
    vbox.add_child(title_hbox)
    
    title_label = Label.new()
    title_label.name = "TitleLabel"
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 24)
    title_hbox.add_child(title_label)
    
    # 关闭按钮
    if show_close_button:
        close_button = Button.new()
        close_button.name = "CloseButton"
        close_button.text = "×"
        close_button.custom_minimum_size = Vector2(32, 32)
        close_button.pressed.connect(_on_cancel_pressed)
        title_hbox.add_child(close_button)
    
    # 创建消息标签
    message_label = Label.new()
    message_label.name = "MessageLabel"
    message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(message_label)
    
    # 创建按钮容器
    button_container = HBoxContainer.new()
    button_container.name = "ButtonContainer"
    button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    button_container.add_theme_constant_override("separation", 16)
    vbox.add_child(button_container)
    
    # 创建取消按钮
    if cancel_text != "":
        cancel_button = StyledButton.new()
        cancel_button.name = "CancelButton"
        cancel_button.text = cancel_text
        cancel_button.button_type = StyledButton.ButtonType.SECONDARY
        cancel_button.pressed.connect(_on_cancel_pressed)
        button_container.add_child(cancel_button)
    
    # 创建确认按钮
    confirm_button = StyledButton.new()
    confirm_button.name = "ConfirmButton"
    confirm_button.text = confirm_text
    confirm_button.button_type = StyledButton.ButtonType.PRIMARY
    confirm_button.pressed.connect(_on_confirm_pressed)
    button_container.add_child(confirm_button)

func _apply_style() -> void:
    var theme_manager = UIManager.instance.theme_manager if UIManager.instance else null
    if theme_manager == null:
        return
    
    # 面板样式
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = theme_manager.get_color("surface")
    panel_style.border_color = theme_manager.get_color("border")
    panel_style.border_width_left = 2
    panel_style.border_width_right = 2
    panel_style.border_width_top = 2
    panel_style.border_width_bottom = 2
    panel_style.corner_radius_top_left = 12
    panel_style.corner_radius_top_right = 12
    panel_style.corner_radius_bottom_left = 12
    panel_style.corner_radius_bottom_right = 12
    panel_style.shadow_color = theme_manager.get_color("shadow")
    panel_style.shadow_size = 8
    add_theme_stylebox_override("panel", panel_style)
    
    # 标题样式
    title_label.add_theme_color_override("font_color", theme_manager.get_color("text"))
    
    # 消息样式
    message_label.add_theme_color_override("font_color", theme_manager.get_color("text_secondary"))
    
    # 关闭按钮样式
    if close_button:
        close_button.add_theme_color_override("font_color", theme_manager.get_color("text_secondary"))

func _update_content() -> void:
    title_label.text = title
    
    if typewriter_effect:
        full_text = message
        current_text = ""
        char_index = 0
        _start_typewriter()
    else:
        message_label.text = message

func _start_typewriter() -> void:
    is_typing = true
    _type_next_char()

func _type_next_char() -> void:
    if not is_typing:
        return
    
    if char_index < full_text.length():
        current_text += full_text[char_index]
        message_label.text = current_text
        char_index += 1
        
        await get_tree().create_timer(typewriter_speed).timeout
        _type_next_char()
    else:
        is_typing = false

func _center_dialog() -> void:
    # 等待布局完成
    await get_tree().process_frame
    
    var viewport_size = get_viewport_rect().size
    position = (viewport_size - size) / 2

func _on_confirm_pressed() -> void:
    if on_confirm.is_valid():
        on_confirm.call()
    queue_free()

func _on_cancel_pressed() -> void:
    if on_cancel.is_valid():
        on_cancel.call()
    queue_free()

## 显示对话框
func show_dialog() -> void:
    visible = true
    
    # 淡入动画
    modulate.a = 0
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)
    
    # 设置焦点到确认按钮
    if confirm_button:
        confirm_button.grab_focus()

## 跳过打字机效果
func skip_typing() -> void:
    if is_typing:
        is_typing = false
        message_label.text = full_text

func _input(event: InputEvent) -> void:
    if not visible:
        return
    
    # 点击跳过打字机
    if event is InputEventMouseButton or event is InputEventKey:
        if is_typing:
            skip_typing()
            get_viewport().set_input_as_handled()
    
    # ESC取消
    if event.is_action_pressed("ui_cancel"):
        _on_cancel_pressed()
        get_viewport().set_input_as_handled()
    
    # Enter确认
    if event.is_action_pressed("ui_accept"):
        if not is_typing:
            _on_confirm_pressed()
            get_viewport().set_input_as_handled()
