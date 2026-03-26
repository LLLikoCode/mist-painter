## UIManager
## UI系统中央管理器
## 负责管理所有UI屏幕、主题、本地化和导航

class_name UIManager
extends Node

# 单例实例
static var instance: UIManager = null

# UI屏幕枚举
enum UIScreen {
    NONE,
    MAIN_MENU,
    HUD,
    PAUSE_MENU,
    SETTINGS_MENU,
    DIALOG,
    LOADING,
    GAME_OVER,
    LEVEL_COMPLETE
}

# 当前屏幕
var current_screen: UIScreen = UIScreen.NONE
var previous_screen: UIScreen = UIScreen.NONE

# 屏幕实例引用
var screens: Dictionary = {}
var screen_instances: Dictionary = {}

# 管理器
var theme_manager: ThemeManager
var localization_manager: LocalizationManager
var navigation_manager: NavigationManager
var animation_manager: AnimationManager

# 信号
signal screen_opened(screen: UIScreen)
signal screen_closed(screen: UIScreen)
signal screen_changed(new_screen: UIScreen, old_screen: UIScreen)
signal ui_initialized()

func _ready():
    # 设置单例
    if instance == null:
        instance = self
    else:
        queue_free()
        return
    
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 初始化管理器
    _init_managers()
    
    # 注册屏幕路径
    _register_screens()
    
    print("UIManager initialized")
    ui_initialized.emit()

func _init_managers() -> void:
    ## 初始化主题管理器
    theme_manager = ThemeManager.new()
    theme_manager.name = "ThemeManager"
    add_child(theme_manager)
    
    ## 初始化本地化管理器
    localization_manager = LocalizationManager.new()
    localization_manager.name = "LocalizationManager"
    add_child(localization_manager)
    
    ## 初始化导航管理器
    navigation_manager = NavigationManager.new()
    navigation_manager.name = "NavigationManager"
    add_child(navigation_manager)
    
    ## 初始化动画管理器
    animation_manager = AnimationManager.new()
    animation_manager.name = "AnimationManager"
    add_child(animation_manager)

func _register_screens() -> void:
    ## 注册所有UI屏幕的路径
    screens[UIScreen.MAIN_MENU] = "res://src/ui/screens/MainMenu.tscn"
    screens[UIScreen.HUD] = "res://src/ui/screens/HUD.tscn"
    screens[UIScreen.PAUSE_MENU] = "res://src/ui/screens/PauseMenu.tscn"
    screens[UIScreen.SETTINGS_MENU] = "res://src/ui/screens/SettingsMenu.tscn"

## 打开指定屏幕
func open_screen(screen: UIScreen, transition: bool = true) -> void:
    if current_screen == screen:
        return
    
    previous_screen = current_screen
    current_screen = screen
    
    # 关闭之前的屏幕（如果需要）
    if previous_screen != UIScreen.NONE and previous_screen != UIScreen.HUD:
        close_screen(previous_screen, transition)
    
    # 实例化并显示新屏幕
    var screen_instance = _get_or_create_screen(screen)
    if screen_instance:
        if transition:
            await animation_manager.play_open_animation(screen_instance)
        else:
            screen_instance.visible = true
        screen_opened.emit(screen)
    
    screen_changed.emit(screen, previous_screen)
    print("UI screen opened: %s" % _get_screen_name(screen))

## 关闭指定屏幕
func close_screen(screen: UIScreen, transition: bool = true) -> void:
    if not screen_instances.has(screen):
        return
    
    var screen_instance = screen_instances[screen]
    if transition:
        await animation_manager.play_close_animation(screen_instance)
    screen_instance.visible = false
    screen_closed.emit(screen)
    
    print("UI screen closed: %s" % _get_screen_name(screen))

## 返回上一屏幕
func go_back(transition: bool = true) -> void:
    if previous_screen != UIScreen.NONE:
        await open_screen(previous_screen, transition)

## 切换屏幕可见性
func toggle_screen(screen: UIScreen, transition: bool = true) -> void:
    if screen_instances.has(screen) and screen_instances[screen].visible:
        close_screen(screen, transition)
    else:
        open_screen(screen, transition)

## 检查屏幕是否打开
func is_screen_open(screen: UIScreen) -> bool:
    return screen_instances.has(screen) and screen_instances[screen].visible

## 获取当前屏幕
func get_current_screen() -> UIScreen:
    return current_screen

## 获取屏幕实例
func get_screen_instance(screen: UIScreen) -> Control:
    if screen_instances.has(screen):
        return screen_instances[screen]
    return null

## 获取或创建屏幕实例
func _get_or_create_screen(screen: UIScreen) -> Control:
    # 如果已存在，直接返回
    if screen_instances.has(screen):
        return screen_instances[screen]
    
    # 检查路径是否注册
    if not screens.has(screen):
        push_error("Screen not registered: %s" % _get_screen_name(screen))
        return null
    
    var path = screens[screen]
    if not ResourceLoader.exists(path):
        push_error("Screen scene not found: %s" % path)
        return null
    
    # 加载并实例化
    var scene = load(path)
    var instance = scene.instantiate() as Control
    
    # 添加到UI层
    var ui_layer = _get_ui_layer()
    if ui_layer:
        ui_layer.add_child(instance)
    else:
        add_child(instance)
    
    screen_instances[screen] = instance
    return instance

## 获取UI层节点
func _get_ui_layer() -> CanvasLayer:
    var tree = get_tree()
    if tree:
        var root = tree.root
        for child in root.get_children():
            if child is CanvasLayer and child.name == "UILayer":
                return child
    return null

## 显示提示消息
func show_toast(message: String, duration: float = 3.0) -> void:
    var toast = preload("res://src/ui/components/ToastNotification.tscn").instantiate()
    toast.message = message
    toast.duration = duration
    
    var ui_layer = _get_ui_layer()
    if ui_layer:
        ui_layer.add_child(toast)
    else:
        add_child(toast)
    
    toast.show_notification()

## 显示对话框
func show_dialog(title: String, message: String, 
                 confirm_text: String = "确定", cancel_text: String = "",
                 on_confirm: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
    var dialog = preload("res://src/ui/components/DialogBox.tscn").instantiate()
    dialog.title = title
    dialog.message = message
    dialog.confirm_text = confirm_text
    dialog.cancel_text = cancel_text
    dialog.on_confirm = on_confirm
    dialog.on_cancel = on_cancel
    
    var ui_layer = _get_ui_layer()
    if ui_layer:
        ui_layer.add_child(dialog)
    else:
        add_child(dialog)
    
    dialog.show_dialog()

## 获取本地化文本
func tr(key: String) -> String:
    if localization_manager:
        return localization_manager.get_text(key)
    return key

## 应用主题到控件
func apply_theme(control: Control) -> void:
    if theme_manager:
        theme_manager.apply_theme(control)

## 设置焦点
func set_focus(control: Control) -> void:
    if navigation_manager:
        navigation_manager.set_focus(control)

## 获取屏幕名称
func _get_screen_name(screen: UIScreen) -> String:
    match screen:
        UIScreen.MAIN_MENU: return "MainMenu"
        UIScreen.HUD: return "HUD"
        UIScreen.PAUSE_MENU: return "PauseMenu"
        UIScreen.SETTINGS_MENU: return "SettingsMenu"
        UIScreen.DIALOG: return "Dialog"
        UIScreen.LOADING: return "Loading"
        UIScreen.GAME_OVER: return "GameOver"
        UIScreen.LEVEL_COMPLETE: return "LevelComplete"
        _: return "Unknown"

## 清理所有屏幕
func cleanup() -> void:
    for screen in screen_instances.values():
        if screen and is_instance_valid(screen):
            screen.queue_free()
    screen_instances.clear()
    current_screen = UIScreen.NONE
    previous_screen = UIScreen.NONE
