## AchievementNotification
## 成就解锁通知弹窗
## 显示在屏幕角落的成就解锁通知

class_name AchievementNotification
extends PanelContainer

# ============================================
# 导出变量
# ============================================

@export_group("Animation Settings")
@export var slide_in_duration: float = 0.5
@export var slide_out_duration: float = 0.3
@export var display_duration: float = 3.0

@export_group("Layout")
@export var notification_position: Vector2 = Vector2(20, 20)
@export var notification_width: float = 350.0

# ============================================
# 内部节点引用
# ============================================

var _icon_texture: TextureRect
var _title_label: Label
var _name_label: Label
var _description_label: Label
var _rarity_panel: Panel
var _points_label: Label
var _progress_bar: ProgressBar

# ============================================
# 内部变量
# ============================================

var _achievement: AchievementData.Achievement = null
var _display_timer: Timer = null
var _is_showing: bool = false

# ============================================
# 信号
# ============================================

signal notification_closed
signal notification_clicked(achievement: AchievementData.Achievement)

# ============================================
# 生命周期
# ============================================

func _ready():
    # 设置初始状态
    visible = false
    modulate.a = 0.0
    
    # 设置布局
    _setup_layout()
    
    # 创建定时器
    _display_timer = Timer.new()
    _display_timer.name = "DisplayTimer"
    _display_timer.one_shot = true
    _display_timer.timeout.connect(_on_display_timeout)
    add_child(_display_timer)
    
    # 设置鼠标交互
    mouse_filter = Control.MOUSE_FILTER_STOP
    gui_input.connect(_on_gui_input)

## 设置布局
func _setup_layout() -> void:
    # 设置面板样式
    custom_minimum_size = Vector2(notification_width, 100)
    size = Vector2(notification_width, 100)
    
    # 设置位置（屏幕右上角）
    anchors_preset = Control.PRESET_TOP_RIGHT
    anchor_left = 1.0
    anchor_right = 1.0
    anchor_top = 0.0
    anchor_bottom = 0.0
    offset_left = -notification_width - notification_position.x
    offset_right = -notification_position.x
    offset_top = notification_position.y
    offset_bottom = notification_position.y + 100
    
    # 创建内部布局
    var main_container = HBoxContainer.new()
    main_container.name = "MainContainer"
    main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_container.add_theme_constant_override("separation", 10)
    add_child(main_container)
    
    # 图标区域
    var icon_container = CenterContainer.new()
    icon_container.name = "IconContainer"
    icon_container.custom_minimum_size = Vector2(64, 64)
    main_container.add_child(icon_container)
    
    _icon_texture = TextureRect.new()
    _icon_texture.name = "IconTexture"
    _icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _icon_texture.expand_mode = 3
    _icon_texture.custom_minimum_size = Vector2(56, 56)
    icon_container.add_child(_icon_texture)
    
    # 内容区域
    var content_container = VBoxContainer.new()
    content_container.name = "ContentContainer"
    content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_container.add_theme_constant_override("separation", 4)
    main_container.add_child(content_container)
    
    # 标题行
    var title_container = HBoxContainer.new()
    title_container.name = "TitleContainer"
    title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_container.add_child(title_container)
    
    _title_label = Label.new()
    _title_label.name = "TitleLabel"
    _title_label.text = "成就解锁！"
    _title_label.add_theme_font_size_override("font_size", 12)
    _title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
    title_container.add_child(_title_label)
    
    # 稀有度指示器
    _rarity_panel = Panel.new()
    _rarity_panel.name = "RarityPanel"
    _rarity_panel.custom_minimum_size = Vector2(12, 12)
    _rarity_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
    title_container.add_child(_rarity_panel)
    
    # 成就名称
    _name_label = Label.new()
    _name_label.name = "NameLabel"
    _name_label.text = ""
    _name_label.add_theme_font_size_override("font_size", 16)
    _name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
    content_container.add_child(_name_label)
    
    # 成就描述
    _description_label = Label.new()
    _description_label.name = "DescriptionLabel"
    _description_label.text = ""
    _description_label.add_theme_font_size_override("font_size", 12)
    _description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _description_label.custom_minimum_size = Vector2(0, 30)
    content_container.add_child(_description_label)
    
    # 底部信息行
    var bottom_container = HBoxContainer.new()
    bottom_container.name = "BottomContainer"
    bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_container.add_child(bottom_container)
    
    _points_label = Label.new()
    _points_label.name = "PointsLabel"
    _points_label.text = ""
    _points_label.add_theme_font_size_override("font_size", 11)
    _points_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    bottom_container.add_child(_points_label)
    
    # 进度条（仅用于进度类成就）
    _progress_bar = ProgressBar.new()
    _progress_bar.name = "ProgressBar"
    _progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _progress_bar.visible = false
    bottom_container.add_child(_progress_bar)

# ============================================
# 公共方法
# ============================================

## 设置成就数据
func setup(achievement: AchievementData.Achievement) -> void:
    _achievement = achievement
    
    if achievement == null:
        return
    
    # 设置图标
    _load_icon(achievement.get_display_icon_path())
    
    # 设置名称
    _name_label.text = achievement.name
    
    # 设置描述
    _description_label.text = achievement.get_display_description()
    
    # 设置稀有度颜色
    _rarity_panel.modulate = achievement.get_rarity_color()
    
    # 设置点数
    _points_label.text = "+%d 点" % achievement.points
    
    # 设置进度条（如果是进度类成就）
    if achievement.type == AchievementData.AchievementType.PROGRESS or \
       achievement.type == AchievementData.AchievementType.CUMULATIVE:
        _progress_bar.visible = true
        _progress_bar.value = achievement.get_progress_percent() * 100
        _progress_bar.tooltip_text = "进度: %d/%d" % [achievement.current_progress, achievement.target_progress]
    else:
        _progress_bar.visible = false

## 显示通知
func show_notification(duration: float = -1.0) -> void:
    if duration < 0:
        duration = display_duration
    
    _is_showing = true
    visible = true
    
    # 播放滑入动画
    await _play_slide_in_animation()
    
    # 启动显示定时器
    _display_timer.wait_time = duration
    _display_timer.start()

## 立即关闭通知
func close_notification() -> void:
    if not _is_showing:
        return
    
    _display_timer.stop()
    _play_slide_out_animation()

# ============================================
# 动画
# ============================================

## 滑入动画
func _play_slide_in_animation() -> void:
    var start_pos = Vector2(size.x + 50, position.y)
    var end_pos = position
    
    position = start_pos
    modulate.a = 1.0
    
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "position", end_pos, slide_in_duration)
    
    await tween.finished

## 滑出动画
func _play_slide_out_animation() -> void:
    var end_pos = Vector2(size.x + 50, position.y)
    
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "position", end_pos, slide_out_duration)
    tween.parallel().tween_property(self, "modulate:a", 0.0, slide_out_duration)
    
    await tween.finished
    
    _is_showing = false
    visible = false
    notification_closed.emit()
    queue_free()

# ============================================
# 事件处理
# ============================================

func _on_display_timeout() -> void:
    _play_slide_out_animation()

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            # 点击通知可以跳转到成就列表
            notification_clicked.emit(_achievement)
            close_notification()

## 加载图标
func _load_icon(icon_path: String) -> void:
    if icon_path.is_empty():
        # 使用默认图标
        _icon_texture.texture = _get_default_icon()
        return
    
    if ResourceLoader.exists(icon_path):
        var texture = load(icon_path) as Texture2D
        if texture:
            _icon_texture.texture = texture
        else:
            _icon_texture.texture = _get_default_icon()
    else:
        _icon_texture.texture = _get_default_icon()

## 获取默认图标
func _get_default_icon() -> Texture2D:
    # 返回一个默认的成就图标，可以是内置图标或空白纹理
    # 这里返回null，让TextureRect显示为空
    return null

# ============================================
# 样式设置
# ============================================

## 应用主题（可由外部调用）
func apply_theme(theme_data: Dictionary) -> void:
    if theme_data.has("background_color"):
        var style = get_theme_stylebox("panel").duplicate()
        if style is StyleBoxFlat:
            style.bg_color = theme_data.background_color
            add_theme_stylebox_override("panel", style)
    
    if theme_data.has("title_color"):
        _title_label.add_theme_color_override("font_color", theme_data.title_color)
    
    if theme_data.has("name_color"):
        _name_label.add_theme_color_override("font_color", theme_data.name_color)
    
    if theme_data.has("description_color"):
        _description_label.add_theme_color_override("font_color", theme_data.description_color)
