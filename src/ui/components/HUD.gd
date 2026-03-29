## HUD
## 游戏界面控制器
## 显示HP/SP/墨水/迷雾覆盖率等游戏资源

class_name HUD
extends Control

# ============================================
# 节点引用
# ============================================

var hp_bar: ProgressBar = null
var hp_label: Label = null
var sp_bar: ProgressBar = null
var sp_label: Label = null
var ink_bar: ProgressBar = null
var ink_label: Label = null
var mist_coverage_label: Label = null
var level_label: Label = null
var pause_button: Button = null

# 内部容器
var stats_container: VBoxContainer = null
var top_bar: HBoxContainer = null

# ============================================
# 配置
# ============================================

## 颜色配置
var hp_color: Color = Color(0.9, 0.25, 0.25)  # 红色
var hp_bg_color: Color = Color(0.2, 0.15, 0.15)
var sp_color: Color = Color(0.3, 0.6, 0.9)    # 蓝色
var sp_bg_color: Color = Color(0.1, 0.15, 0.2)
var ink_color: Color = Color(0.4, 0.35, 0.25)  # 墨水色
var ink_bg_color: Color = Color(0.15, 0.12, 0.1)

# ============================================
# 信号
# ============================================

signal pause_pressed

# ============================================
# 生命周期
# ============================================

func _ready():
	# 设置锚点为全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 创建UI布局
	_create_layout()

	# 应用样式
	_apply_styles()

	print("HUD initialized")

# ============================================
# 布局创建
# ============================================

func _create_layout() -> void:
	# 创建顶部栏容器 - 使用锚点定位在顶部
	top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_top = 5
	top_bar.offset_bottom = 45
	top_bar.offset_left = 10
	top_bar.offset_right = -10
	add_child(top_bar)

	# 创建左侧关卡信息
	var level_container = HBoxContainer.new()
	level_container.name = "LevelContainer"
	level_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top_bar.add_child(level_container)

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "关卡: 1"
	level_label.custom_minimum_size = Vector2(100, 40)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_container.add_child(level_label)

	# 添加间隔
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# 创建暂停按钮
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "暂停"
	pause_button.custom_minimum_size = Vector2(60, 35)
	pause_button.pressed.connect(_on_pause_pressed)
	top_bar.add_child(pause_button)

	# 创建资源面板 (左侧) - 使用锚点定位
	var resource_panel = PanelContainer.new()
	resource_panel.name = "ResourcePanel"
	resource_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	resource_panel.anchor_left = 0.0
	resource_panel.anchor_top = 0.0
	resource_panel.offset_left = 10
	resource_panel.offset_top = 55
	resource_panel.offset_right = 230
	resource_panel.offset_bottom = 220
	add_child(resource_panel)

	# 资源面板背景样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	panel_style.border_color = Color(0.3, 0.3, 0.35)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	resource_panel.add_theme_stylebox_override("panel", panel_style)

	# 资源容器
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 8)
	resource_panel.add_child(stats_container)

	# 创建各个资源条
	_create_hp_bar()
	_create_sp_bar()
	_create_ink_bar()
	_create_mist_label()

## 创建HP条
func _create_hp_bar() -> void:
	var container = VBoxContainer.new()
	container.name = "HPContainer"
	stats_container.add_child(container)

	var header = HBoxContainer.new()
	header.name = "HPHeader"
	container.add_child(header)

	var hp_icon = Label.new()
	hp_icon.text = "HP"
	hp_icon.custom_minimum_size = Vector2(30, 20)
	header.add_child(hp_icon)

	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "100/100"
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.custom_minimum_size = Vector2(200, 16)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	container.add_child(hp_bar)

## 创建SP条
func _create_sp_bar() -> void:
	var container = VBoxContainer.new()
	container.name = "SPContainer"
	stats_container.add_child(container)

	var header = HBoxContainer.new()
	header.name = "SPHeader"
	container.add_child(header)

	var sp_icon = Label.new()
	sp_icon.text = "SP"
	sp_icon.custom_minimum_size = Vector2(30, 20)
	header.add_child(sp_icon)

	sp_label = Label.new()
	sp_label.name = "SPLabel"
	sp_label.text = "50/50"
	sp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp_label)

	sp_bar = ProgressBar.new()
	sp_bar.name = "SPBar"
	sp_bar.custom_minimum_size = Vector2(200, 16)
	sp_bar.max_value = 50
	sp_bar.value = 50
	sp_bar.show_percentage = false
	container.add_child(sp_bar)

## 创建墨水条
func _create_ink_bar() -> void:
	var container = VBoxContainer.new()
	container.name = "InkContainer"
	stats_container.add_child(container)

	var header = HBoxContainer.new()
	header.name = "InkHeader"
	container.add_child(header)

	var ink_icon = Label.new()
	ink_icon.text = "墨水"
	ink_icon.custom_minimum_size = Vector2(30, 20)
	header.add_child(ink_icon)

	ink_label = Label.new()
	ink_label.name = "InkLabel"
	ink_label.text = "50/100"
	ink_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ink_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(ink_label)

	ink_bar = ProgressBar.new()
	ink_bar.name = "InkBar"
	ink_bar.custom_minimum_size = Vector2(200, 16)
	ink_bar.max_value = 100
	ink_bar.value = 50
	ink_bar.show_percentage = false
	container.add_child(ink_bar)

## 创建迷雾覆盖率标签
func _create_mist_label() -> void:
	mist_coverage_label = Label.new()
	mist_coverage_label.name = "MistCoverageLabel"
	mist_coverage_label.text = "迷雾: 100%"
	mist_coverage_label.custom_minimum_size = Vector2(200, 24)
	stats_container.add_child(mist_coverage_label)

# ============================================
# 样式应用
# ============================================

func _apply_styles() -> void:
	_apply_bar_style(hp_bar, hp_color, hp_bg_color)
	_apply_bar_style(sp_bar, sp_color, sp_bg_color)
	_apply_bar_style(ink_bar, ink_color, ink_bg_color)

func _apply_bar_style(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	if bar == null:
		return

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.set_corner_radius_all(4)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(4)

	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill", fill_style)

# ============================================
# 更新方法
# ============================================

## 更新HP显示
func update_hp(current: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current

	if hp_label:
		hp_label.text = "%d/%d" % [int(current), int(max_hp)]

	# 低血量警告效果
	if hp_bar:
		var percentage = current / max_hp if max_hp > 0 else 0
		if percentage <= 0.3:
			_apply_bar_style(hp_bar, Color(1.0, 0.3, 0.2), hp_bg_color)
		else:
			_apply_bar_style(hp_bar, hp_color, hp_bg_color)

## 更新SP显示
func update_sp(current: float, max_sp: float) -> void:
	if sp_bar:
		sp_bar.max_value = max_sp
		sp_bar.value = current

	if sp_label:
		sp_label.text = "%d/%d" % [int(current), int(max_sp)]

## 更新墨水显示
func update_ink(current: float, max_ink: float) -> void:
	if ink_bar:
		ink_bar.max_value = max_ink
		ink_bar.value = current

	if ink_label:
		ink_label.text = "%d/%d" % [int(current), int(max_ink)]

## 更新迷雾覆盖率
func update_mist_coverage(coverage: float) -> void:
	if mist_coverage_label:
		mist_coverage_label.text = "迷雾: %d%%" % int(coverage)

## 更新关卡信息
func update_level(level: int) -> void:
	if level_label:
		level_label.text = "关卡: %d" % level

# ============================================
# 动画效果
# ============================================

## HP变化动画
func animate_hp_change(from: float, to: float, max_hp: float) -> void:
	if hp_bar == null:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.tween_method(
		func(value: float):
			hp_bar.value = value
			if hp_label:
				hp_label.text = "%d/%d" % [int(value), int(max_hp)],
		from, to, 0.3
	)

## 墨水变化动画
func animate_ink_change(from: float, to: float, max_ink: float) -> void:
	if ink_bar == null:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.tween_method(
		func(value: float):
			ink_bar.value = value
			if ink_label:
				ink_label.text = "%d/%d" % [int(value), int(max_ink)],
		from, to, 0.3
	)

## 显示警告效果
func show_warning() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 0.8, 0.8), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

# ============================================
# 信号处理
# ============================================

func _on_pause_pressed() -> void:
	pause_pressed.emit()

# ============================================
# 公共方法
# ============================================

## 连接到PlayerStats
func connect_to_stats(stats: PlayerStats) -> void:
	if stats == null:
		return

	# 初始化显示
	update_hp(stats.current_hp, stats.max_hp)
	update_sp(stats.current_sp, stats.max_sp)
	update_ink(stats.current_ink, stats.max_ink)

	# 连接信号
	stats.hp_changed.connect(_on_hp_changed)
	stats.sp_changed.connect(_on_sp_changed)
	stats.ink_changed.connect(_on_ink_changed)

func _on_hp_changed(current: float, max_hp: float) -> void:
	update_hp(current, max_hp)

func _on_sp_changed(current: float, max_sp: float) -> void:
	update_sp(current, max_sp)

func _on_ink_changed(current: float, max_ink: float) -> void:
	update_ink(current, max_ink)

## 断开与PlayerStats的连接
func disconnect_from_stats(stats: PlayerStats) -> void:
	if stats == null:
		return

	if stats.hp_changed.is_connected(_on_hp_changed):
		stats.hp_changed.disconnect(_on_hp_changed)
	if stats.sp_changed.is_connected(_on_sp_changed):
		stats.sp_changed.disconnect(_on_sp_changed)
	if stats.ink_changed.is_connected(_on_ink_changed):
		stats.ink_changed.disconnect(_on_ink_changed)