## HUD
## 游戏界面控制器
## 显示HP、体力、物品数量等

class_name HUD
extends Control

# ============================================
# 节点引用
# ============================================

var hp_bar: ProgressBar = null
var hp_label: Label = null
var stamina_bar: ProgressBar = null
var stamina_label: Label = null
var fatigue_label: Label = null
var items_label: Label = null
var controls_label: Label = null

# 内部容器
var stats_container: VBoxContainer = null

# 当前连接的玩家资源
var stats: PlayerStats = null

# ============================================
# 配置
# ============================================

## 颜色配置
var hp_color: Color = Color(0.9, 0.25, 0.25)  # 红色
var hp_bg_color: Color = Color(0.2, 0.15, 0.15)
var stamina_color: Color = Color(0.29, 0.49, 0.35)  # 绿色
var stamina_bg_color: Color = Color(0.1, 0.15, 0.12)
var stamina_warning_color: Color = Color(0.96, 0.62, 0.04)  # 黄色

# ============================================
# 信号
# ============================================

signal pause_pressed()

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
	# 创建资源面板 (左侧)
	var resource_panel = PanelContainer.new()
	resource_panel.name = "ResourcePanel"
	resource_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	resource_panel.anchor_left = 0.0
	resource_panel.anchor_top = 0.0
	resource_panel.offset_left = 10
	resource_panel.offset_top = 10
	resource_panel.offset_right = 230
	resource_panel.offset_bottom = 200
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
	_create_stamina_bar()
	_create_items_display()
	_create_controls_hint()

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

## 创建体力条
func _create_stamina_bar() -> void:
	var container = VBoxContainer.new()
	container.name = "StaminaContainer"
	stats_container.add_child(container)

	var header = HBoxContainer.new()
	header.name = "StaminaHeader"
	container.add_child(header)

	var stamina_icon = Label.new()
	stamina_icon.text = "体力"
	stamina_icon.custom_minimum_size = Vector2(30, 20)
	header.add_child(stamina_icon)

	stamina_label = Label.new()
	stamina_label.name = "StaminaLabel"
	stamina_label.text = "100/100"
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamina_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(stamina_label)

	stamina_bar = ProgressBar.new()
	stamina_bar.name = "StaminaBar"
	stamina_bar.custom_minimum_size = Vector2(200, 16)
	stamina_bar.max_value = 100
	stamina_bar.value = 100
	stamina_bar.show_percentage = false
	container.add_child(stamina_bar)

	fatigue_label = Label.new()
	fatigue_label.name = "FatigueLabel"
	fatigue_label.text = "状态: 正常"
	fatigue_label.custom_minimum_size = Vector2(200, 20)
	container.add_child(fatigue_label)

## 创建物品显示
func _create_items_display() -> void:
	items_label = Label.new()
	items_label.name = "ItemsLabel"
	items_label.text = "记录纸张: 0 | 撤离卷轴: 0"
	items_label.custom_minimum_size = Vector2(200, 24)
	stats_container.add_child(items_label)

## 创建操作提示
func _create_controls_hint() -> void:
	controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.text = "I:背包 | M:地图 | Q:记录"
	controls_label.custom_minimum_size = Vector2(200, 24)
	controls_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	stats_container.add_child(controls_label)

# ============================================
# 样式应用
# ============================================

func _apply_styles() -> void:
	_apply_bar_style(hp_bar, hp_color, hp_bg_color)
	_apply_bar_style(stamina_bar, stamina_color, stamina_bg_color)

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

## 更新体力显示
func update_stamina(current: float, max_stamina: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current
	if stamina_label:
		stamina_label.text = "%d/%d" % [int(current), int(max_stamina)]

## 更新疲劳状态显示
func update_fatigue_state(state: int, state_name: String) -> void:
	if fatigue_label:
		fatigue_label.text = "状态: %s" % state_name

	# 根据状态改变颜色
	match state:
		0:  # 正常
			fatigue_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		1:  # 疲劳
			fatigue_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
		2:  # 精疲力竭
			fatigue_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
		3, 4:  # 濒死/昏迷
			fatigue_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

## 更新物品显示
func update_items_display(record_count: int, escape_count: int) -> void:
	if items_label:
		items_label.text = "记录纸张: %d | 撤离卷轴: %d" % [record_count, escape_count]

# ============================================
# 连接资源
# ============================================

## 连接到玩家资源
func connect_to_stats(player_stats: PlayerStats) -> void:
	stats = player_stats

	# 连接信号
	if stats:
		stats.hp_changed.connect(_on_hp_changed)
		stats.stamina_changed.connect(_on_stamina_changed)
		stats.fatigue_state_changed.connect(_on_fatigue_changed)
		stats.stats_updated.connect(_on_stats_updated)

		# 初始化显示
		update_hp(stats.current_hp, stats.max_hp)
		update_stamina(stats.current_stamina, stats.max_stamina)
		update_fatigue_state(stats.current_fatigue_state, stats.get_fatigue_state_name())

## 信号回调
func _on_hp_changed(current: float, max_hp: float) -> void:
	update_hp(current, max_hp)

func _on_stamina_changed(current: float, max_stamina: float) -> void:
	update_stamina(current, max_stamina)

func _on_fatigue_changed(state: int) -> void:
	if stats:
		update_fatigue_state(state, stats.get_fatigue_state_name())

func _on_stats_updated() -> void:
	if stats:
		update_hp(stats.current_hp, stats.max_hp)
		update_stamina(stats.current_stamina, stats.max_stamina)

## 显示警告
func show_warning() -> void:
	# 可以添加闪烁效果或其他视觉提示
	if fatigue_label:
		fatigue_label.add_theme_color_override("font_color", Color(1, 0, 0))

## 更新关卡显示
func update_level(level: int) -> void:
	# 暂时不显示关卡
	pass