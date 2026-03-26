## NavigationManager
## 导航管理器
## 负责处理焦点导航、输入映射和UI交互

class_name NavigationManager
extends Node

# 导航模式
enum NavigationMode {
    MOUSE,      # 鼠标导航
    KEYBOARD,   # 键盘导航
    GAMEPAD     # 手柄导航
}

# 当前导航模式
var current_mode: NavigationMode = NavigationMode.MOUSE

# 焦点栈
var focus_stack: Array[Control] = []
var max_stack_size: int = 20

# 输入动作映射
const INPUT_ACTIONS = {
    "ui_up": ["ui_up", "ui_focus_prev"],
    "ui_down": ["ui_down", "ui_focus_next"],
    "ui_left": ["ui_left"],
    "ui_right": ["ui_right"],
    "ui_accept": ["ui_accept", "ui_select"],
    "ui_cancel": ["ui_cancel"],
    "ui_pause": ["ui_pause", "ui_menu"]
}

# 信号
signal navigation_mode_changed(mode: NavigationMode)
signal focus_changed(control: Control)
signal input_received(action: String)

# 手柄死区
var joystick_deadzone: float = 0.2

# 导航冷却时间（防止过快切换）
var navigation_cooldown: float = 0.15
var last_navigation_time: float = 0.0

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 设置输入映射
    _setup_input_map()
    
    print("NavigationManager initialized")

func _setup_input_map() -> void:
    # 确保基本UI动作已映射
    if not InputMap.has_action("ui_pause"):
        InputMap.add_action("ui_pause")
        var escape_event = InputEventKey.new()
        escape_event.keycode = KEY_ESCAPE
        InputMap.action_add_event("ui_pause", escape_event)

func _process(delta: float):
    # 检测输入设备变化
    _detect_input_device()
    
    # 处理导航输入
    _handle_navigation_input()

func _detect_input_device() -> void:
    var new_mode = current_mode
    
    # 检测鼠标移动
    if Input.get_last_mouse_velocity().length() > 0:
        new_mode = NavigationMode.MOUSE
    
    # 检测键盘输入
    for key in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_ESCAPE]:
        if Input.is_key_just_pressed(key):
            new_mode = NavigationMode.KEYBOARD
            break
    
    # 检测手柄输入
    for joy in range(8):  # 检查8个手柄
        if Input.is_joy_button_pressed(joy, JOY_BUTTON_A) or \
           Input.is_joy_button_pressed(joy, JOY_BUTTON_B) or \
           abs(Input.get_joy_axis(joy, JOY_AXIS_LEFT_X)) > joystick_deadzone or \
           abs(Input.get_joy_axis(joy, JOY_AXIS_LEFT_Y)) > joystick_deadzone:
            new_mode = NavigationMode.GAMEPAD
            break
    
    # 更新导航模式
    if new_mode != current_mode:
        current_mode = new_mode
        navigation_mode_changed.emit(current_mode)
        
        # 手柄模式下自动设置焦点
        if current_mode == NavigationMode.GAMEPAD:
            _auto_focus_first_control()

func _handle_navigation_input() -> void:
    var current_time = Time.get_time_dict_from_system()["second"]
    
    # 检查冷却时间
    if current_time - last_navigation_time < navigation_cooldown:
        return
    
    var direction = Vector2.ZERO
    
    # 键盘导航
    if Input.is_action_just_pressed("ui_up"):
        direction.y = -1
    elif Input.is_action_just_pressed("ui_down"):
        direction.y = 1
    elif Input.is_action_just_pressed("ui_left"):
        direction.x = -1
    elif Input.is_action_just_pressed("ui_right"):
        direction.x = 1
    
    # 手柄摇杆导航
    if current_mode == NavigationMode.GAMEPAD:
        for joy in range(8):
            var joy_x = Input.get_joy_axis(joy, JOY_AXIS_LEFT_X)
            var joy_y = Input.get_joy_axis(joy, JOY_AXIS_LEFT_Y)
            
            if abs(joy_x) > joystick_deadzone:
                direction.x = sign(joy_x)
            if abs(joy_y) > joystick_deadzone:
                direction.y = sign(joy_y)
    
    # 执行导航
    if direction != Vector2.ZERO:
        _navigate(direction)
        last_navigation_time = current_time

## 设置焦点到指定控件
func set_focus(control: Control) -> void:
    if control == null or not is_instance_valid(control):
        return
    
    if not control.focus_mode == Control.FOCUS_ALL:
        return
    
    # 将当前焦点控件压入栈
    var current_focus = get_viewport().gui_get_focus_owner()
    if current_focus != null and current_focus != control:
        _push_focus_to_stack(current_focus)
    
    # 设置新焦点
    control.grab_focus()
    focus_changed.emit(control)

## 获取当前焦点控件
func get_current_focus() -> Control:
    return get_viewport().gui_get_focus_owner()

## 导航到下一个控件
func _navigate(direction: Vector2) -> void:
    var current_focus = get_viewport().gui_get_focus_owner()
    if current_focus == null:
        _auto_focus_first_control()
        return
    
    # 使用Godot内置的导航
    var next_control: Control = null
    
    if direction.y < 0:
        next_control = current_focus.find_prev_valid_focus()
    elif direction.y > 0:
        next_control = current_focus.find_next_valid_focus()
    elif direction.x < 0:
        next_control = current_focus.find_prev_valid_focus()
    elif direction.x > 0:
        next_control = current_focus.find_next_valid_focus()
    
    if next_control != null and next_control != current_focus:
        set_focus(next_control)

## 自动聚焦第一个可交互控件
func _auto_focus_first_control() -> void:
    var root = get_tree().root
    var first_focusable = _find_first_focusable_control(root)
    if first_focusable != null:
        set_focus(first_focusable)

## 查找第一个可聚焦控件
func _find_first_focusable_control(node: Node) -> Control:
    if node is Control and node.focus_mode == Control.FOCUS_ALL and node.visible:
        return node
    
    for child in node.get_children():
        var result = _find_first_focusable_control(child)
        if result != null:
            return result
    
    return null

## 将焦点压入栈
func _push_focus_to_stack(control: Control) -> void:
    focus_stack.append(control)
    if focus_stack.size() > max_stack_size:
        focus_stack.pop_front()

## 返回上一个焦点
func pop_focus() -> void:
    if focus_stack.is_empty():
        return
    
    var previous_focus = focus_stack.pop_back()
    if previous_focus != null and is_instance_valid(previous_focus):
        set_focus(previous_focus)

## 清空焦点栈
func clear_focus_stack() -> void:
    focus_stack.clear()

## 设置手柄死区
func set_joystick_deadzone(deadzone: float) -> void:
    joystick_deadzone = clamp(deadzone, 0.0, 1.0)

## 获取当前导航模式
func get_navigation_mode() -> NavigationMode:
    return current_mode

## 检查是否为手柄模式
func is_gamepad_mode() -> bool:
    return current_mode == NavigationMode.GAMEPAD

## 注册自定义导航路径
func register_navigation_path(from_control: Control, direction: Vector2, to_control: Control) -> void:
    if direction.y < 0:
        from_control.focus_neighbor_top = to_control.get_path()
    elif direction.y > 0:
        from_control.focus_neighbor_bottom = to_control.get_path()
    elif direction.x < 0:
        from_control.focus_neighbor_left = to_control.get_path()
    elif direction.x > 0:
        from_control.focus_neighbor_right = to_control.get_path()

## 清除导航路径
func clear_navigation_paths(control: Control) -> void:
    control.focus_neighbor_top = NodePath()
    control.focus_neighbor_bottom = NodePath()
    control.focus_neighbor_left = NodePath()
    control.focus_neighbor_right = NodePath()

## 启用/禁用导航
func set_navigation_enabled(enabled: bool) -> void:
    set_process(enabled)
