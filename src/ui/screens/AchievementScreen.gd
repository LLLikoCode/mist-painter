## AchievementScreen
## 成就列表界面
## 显示所有成就，包括已解锁和未解锁的成就

class_name AchievementScreen
extends Control

# ============================================
# 导出变量
# ============================================

@export_group("UI Settings")
@export var achievement_item_scene: PackedScene = null
@export var items_per_row: int = 3
@export var item_spacing: float = 20.0

@export_group("Animation")
@export var open_animation_duration: float = 0.3
@export var item_appear_delay: float = 0.05

# ============================================
# 内部节点引用
# ============================================

var _title_label: Label
var _back_button: Button
var _scroll_container: ScrollContainer
var _achievement_grid: GridContainer
var _stats_panel: Panel
var _total_progress_label: Label
var _unlocked_count_label: Label
var _total_points_label: Label
var _filter_dropdown: OptionButton
var _search_line_edit: LineEdit

# ============================================
# 内部变量
# ============================================

var _achievement_items: Array[Control] = []
var _current_filter: String = "all"
var _search_text: String = ""
var _is_initialized: bool = false

# ============================================
# 生命周期
# ============================================

func _ready():
    # 设置处理模式
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 构建UI
    _build_ui()
    
    # 连接信号
    _connect_signals()
    
    # 等待AchievementManager初始化
    _wait_for_achievement_manager()
    
    # 初始隐藏
    visible = false
    modulate.a = 0.0

## 等待成就管理器
func _wait_for_achievement_manager() -> void:
    if AchievementManager.instance == null:
        await get_tree().create_timer(0.5).timeout
        _wait_for_achievement_manager()
        return
    
    _is_initialized = true
    _refresh_achievements()
    _update_stats()

## 构建UI
func _build_ui() -> void:
    # 设置根节点
    anchors_preset = Control.PRESET_FULL_RECT
    
    # 背景面板
    var background = Panel.new()
    background.name = "Background"
    background.anchors_preset = Control.PRESET_FULL_RECT
    add_child(background)
    
    # 主容器
    var main_container = VBoxContainer.new()
    main_container.name = "MainContainer"
    main_container.anchors_preset = Control.PRESET_FULL_RECT
    main_container.offset_left = 40
    main_container.offset_right = -40
    main_container.offset_top = 30
    main_container.offset_bottom = -30
    main_container.add_theme_constant_override("separation", 20)
    add_child(main_container)
    
    # 标题栏
    var header_container = HBoxContainer.new()
    header_container.name = "HeaderContainer"
    header_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_container.add_child(header_container)
    
    _title_label = Label.new()
    _title_label.name = "TitleLabel"
    _title_label.text = "成就"
    _title_label.add_theme_font_size_override("font_size", 32)
    _title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_container.add_child(_title_label)
    
    # 统计面板
    _stats_panel = Panel.new()
    _stats_panel.name = "StatsPanel"
    _stats_panel.custom_minimum_size = Vector2(300, 60)
    header_container.add_child(_stats_panel)
    
    var stats_container = HBoxContainer.new()
    stats_container.name = "StatsContainer"
    stats_container.anchors_preset = Control.PRESET_FULL_RECT
    stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
    _stats_panel.add_child(stats_container)
    
    _unlocked_count_label = Label.new()
    _unlocked_count_label.name = "UnlockedCountLabel"
    _unlocked_count_label.text = "0/0"
    _unlocked_count_label.add_theme_font_size_override("font_size", 14)
    stats_container.add_child(_unlocked_count_label)
    
    var separator1 = VSeparator.new()
    stats_container.add_child(separator1)
    
    _total_progress_label = Label.new()
    _total_progress_label.name = "TotalProgressLabel"
    _total_progress_label.text = "0%"
    _total_progress_label.add_theme_font_size_override("font_size", 14)
    stats_container.add_child(_total_progress_label)
    
    var separator2 = VSeparator.new()
    stats_container.add_child(separator2)
    
    _total_points_label = Label.new()
    _total_points_label.name = "TotalPointsLabel"
    _total_points_label.text = "0 点"
    _total_points_label.add_theme_font_size_override("font_size", 14)
    stats_container.add_child(_total_points_label)
    
    # 筛选和搜索栏
    var filter_container = HBoxContainer.new()
    filter_container.name = "FilterContainer"
    filter_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_container.add_child(filter_container)
    
    _filter_dropdown = OptionButton.new()
    _filter_dropdown.name = "FilterDropdown"
    _filter_dropdown.custom_minimum_size = Vector2(150, 35)
    _filter_dropdown.add_item("全部", 0)
    _filter_dropdown.add_item("已解锁", 1)
    _filter_dropdown.add_item("未解锁", 2)
    _filter_dropdown.add_item("进度中", 3)
    _filter_dropdown.add_item("隐藏", 4)
    filter_container.add_child(_filter_dropdown)
    
    var spacer = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    filter_container.add_child(spacer)
    
    _search_line_edit = LineEdit.new()
    _search_line_edit.name = "SearchLineEdit"
    _search_line_edit.placeholder_text = "搜索成就..."
    _search_line_edit.custom_minimum_size = Vector2(200, 35)
    filter_container.add_child(_search_line_edit)
    
    # 滚动容器
    _scroll_container = ScrollContainer.new()
    _scroll_container.name = "ScrollContainer"
    _scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    main_container.add_child(_scroll_container)
    
    # 成就网格
    _achievement_grid = GridContainer.new()
    _achievement_grid.name = "AchievementGrid"
    _achievement_grid.columns = items_per_row
    _achievement_grid.add_theme_constant_override("h_separation", int(item_spacing))
    _achievement_grid.add_theme_constant_override("v_separation", int(item_spacing))
    _achievement_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll_container.add_child(_achievement_grid)
    
    # 底部按钮栏
    var button_container = HBoxContainer.new()
    button_container.name = "ButtonContainer"
    button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_container.alignment = BoxContainer.ALIGNMENT_CENTER
    main_container.add_child(button_container)
    
    _back_button = Button.new()
    _back_button.name = "BackButton"
    _back_button.text = "返回"
    _back_button.custom_minimum_size = Vector2(120, 45)
    button_container.add_child(_back_button)

## 连接信号
func _connect_signals() -> void:
    _back_button.pressed.connect(_on_back_pressed)
    _filter_dropdown.item_selected.connect(_on_filter_changed)
    _search_line_edit.text_changed.connect(_on_search_changed)
    
    # 连接成就管理器信号
    if AchievementManager.instance:
        AchievementManager.instance.achievement_unlocked.connect(_on_achievement_unlocked)
        AchievementManager.instance.achievement_progress_updated.connect(_on_achievement_progress_updated)
        AchievementManager.instance.stats_updated.connect(_on_stats_updated)

# ============================================
# 公共方法
# ============================================

## 打开界面
func open() -> void:
    visible = true
    
    # 播放打开动画
    await _play_open_animation()
    
    # 刷新显示
    if _is_initialized:
        _refresh_achievements()
        _update_stats()

## 关闭界面
func close() -> void:
    await _play_close_animation()
    visible = false

## 刷新成就列表
func refresh() -> void:
    if not _is_initialized:
        return
    _refresh_achievements()
    _update_stats()