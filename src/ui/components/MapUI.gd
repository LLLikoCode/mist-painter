## MapUI
## 地图界面
## 显示玩家已记录的迷宫区域

class_name MapUI
extends Control

# ============================================
# 导出变量
# ============================================

@export var cell_size: int = 16
@export var background_color: Color = Color(0.1, 0.1, 0.15, 0.95)
@export var recorded_color: Color = Color(0.5, 0.45, 0.55)
@export var player_color: Color = Color(0.2, 0.8, 0.4)
@export var entrance_color: Color = Color(1.0, 0.6, 0.2)
@export var exit_color: Color = Color(0.9, 0.3, 0.2)
@export var unexplored_color: Color = Color(0.15, 0.12, 0.18)

# ============================================
# 数据引用
# ============================================

var inventory: InventoryManager = null
var player_pos: Vector2i = Vector2i.ZERO
var entrance_pos: Vector2i = Vector2i(-1, -1)
var exit_pos: Vector2i = Vector2i(-1, -1)

# ============================================
# 内部节点
# ============================================

var map_texture: TextureRect = null
var stats_label: Label = null

# ============================================
# 信号
# ============================================

signal map_closed()

# ============================================
# 生命周期
# ============================================

func _ready():
	_setup_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _input(event: InputEvent):
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("paint_mist")):
		close()
		get_viewport().set_input_as_handled()
	# 按M键切换地图
	if visible and event.is_action_pressed("view_map"):
		close()
		get_viewport().set_input_as_handled()

# ============================================
# UI设置
# ============================================

func _setup_ui():
	# 设置为全屏覆盖
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = background_color
	add_child(bg)

	# 居中容器
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	# 主面板
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(450, 400)
	center_container.add_child(main_panel)

	# 垂直布局
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_panel.add_child(vbox)

	# 标题
	var title_label = Label.new()
	title_label.text = "探险地图"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)

	# 地图显示区域
	map_texture = TextureRect.new()
	map_texture.custom_minimum_size = Vector2(400, 300)
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	vbox.add_child(map_texture)

	# 统计信息
	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.text = "尚未记录任何区域"
	vbox.add_child(stats_label)

	# 按钮容器
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	# 关闭按钮
	var close_btn = Button.new()
	close_btn.text = "关闭 (ESC)"
	close_btn.pressed.connect(close)
	btn_hbox.add_child(close_btn)

# ============================================
# 显示地图
# ============================================

func show_map():
	if inventory == null:
		print("MapUI: No inventory reference")
		return

	visible = true
	get_tree().paused = true
	_draw_map()

func close():
	visible = false
	get_tree().paused = false
	map_closed.emit()

func _draw_map():
	var recorded = inventory.get_recorded_areas()

	if recorded.is_empty():
		if stats_label:
			stats_label.text = "尚未记录任何区域"
		return

	# 计算边界
	var min_x = recorded[0].x
	var max_x = recorded[0].x
	var min_y = recorded[0].y
	var max_y = recorded[0].y

	for pos in recorded:
		min_x = mini(min_x, pos.x)
		max_x = maxi(max_x, pos.x)
		min_y = mini(min_y, pos.y)
		max_y = maxi(max_y, pos.y)

	# 确保玩家位置也在范围内
	min_x = mini(min_x, player_pos.x)
	max_x = maxi(max_x, player_pos.x)
	min_y = mini(min_y, player_pos.y)
	max_y = maxi(max_y, player_pos.y)

	# 创建图像
	var width = max_x - min_x + 1
	var height = max_y - min_y + 1
	var image = Image.create(width * cell_size, height * cell_size, false, Image.FORMAT_RGBA8)
	image.fill(unexplored_color)

	# 绘制已记录区域
	for pos in recorded:
		var local_x = (pos.x - min_x) * cell_size
		var local_y = (pos.y - min_y) * cell_size
		_fill_rect(image, local_x, local_y, cell_size, cell_size, recorded_color)

	# 绘制入口
	if entrance_pos.x >= 0:
		var local_x = (entrance_pos.x - min_x) * cell_size
		var local_y = (entrance_pos.y - min_y) * cell_size
		_fill_rect(image, local_x, local_y, cell_size, cell_size, entrance_color)

	# 绘制出口
	if exit_pos.x >= 0:
		var local_x = (exit_pos.x - min_x) * cell_size
		var local_y = (exit_pos.y - min_y) * cell_size
		_fill_rect(image, local_x, local_y, cell_size, cell_size, exit_color)

	# 绘制玩家位置
	var player_local_x = (player_pos.x - min_x) * cell_size
	var player_local_y = (player_pos.y - min_y) * cell_size
	_fill_rect(image, player_local_x, player_local_y, cell_size, cell_size, player_color)

	# 应用到纹理
	var texture = ImageTexture.create_from_image(image)
	map_texture.texture = texture

	# 更新统计信息
	if stats_label:
		stats_label.text = "已记录 %d 格区域" % recorded.size()

func _fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color):
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				image.set_pixel(px, py, color)

# ============================================
# 设置数据
# ============================================

func set_inventory(inv: InventoryManager):
	inventory = inv

func set_player_position(pos: Vector2i):
	player_pos = pos

func set_entrance_position(pos: Vector2i):
	entrance_pos = pos

func set_exit_position(pos: Vector2i):
	exit_pos = pos

# ============================================
# 静态创建方法
# ============================================

static func create() -> MapUI:
	var map_ui = MapUI.new()
	map_ui.name = "MapUI"
	return map_ui