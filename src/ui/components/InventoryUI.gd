## InventoryUI
## 背包界面
## 显示和管理玩家物品

class_name InventoryUI
extends Control

# ============================================
# 导出变量
# ============================================

@export var background_color: Color = Color(0.1, 0.1, 0.15, 0.95)

# ============================================
# 数据引用
# ============================================

var inventory: InventoryManager = null

# ============================================
# 内部节点
# ============================================

var slots_container: GridContainer = null
var item_info_label: Label = null
var use_button: Button = null
var close_button: Button = null
var selected_slot: int = -1

# ============================================
# 信号
# ============================================

signal inventory_closed()

# ============================================
# 生命周期
# ============================================

func _ready():
	_setup_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	# 按I键切换背包
	if visible and event.is_action_pressed("open_inventory"):
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
	main_panel.custom_minimum_size = Vector2(500, 450)
	center_container.add_child(main_panel)

	# 垂直布局
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_panel.add_child(vbox)

	# 标题
	var title_label = Label.new()
	title_label.text = "背包"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)

	# 物品格子容器 (4x5 = 20格)
	slots_container = GridContainer.new()
	slots_container.columns = 5
	slots_container.add_theme_constant_override("h_separation", 5)
	slots_container.add_theme_constant_override("v_separation", 5)
	vbox.add_child(slots_container)

	# 创建20个格子
	for i in range(20):
		var slot = _create_slot(i)
		slots_container.add_child(slot)

	# 物品信息
	item_info_label = Label.new()
	item_info_label.text = "选择物品查看详情"
	item_info_label.custom_minimum_size = Vector2(400, 60)
	item_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(item_info_label)

	# 按钮容器
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	# 使用按钮
	use_button = Button.new()
	use_button.text = "使用"
	use_button.disabled = true
	use_button.pressed.connect(_on_use_pressed)
	btn_hbox.add_child(use_button)

	# 关闭按钮
	close_button = Button.new()
	close_button.text = "关闭 (ESC)"
	close_button.pressed.connect(close)
	btn_hbox.add_child(close_button)

# ============================================
# 创建格子
# ============================================

func _create_slot(index: int) -> Button:
	var slot = Button.new()
	slot.name = "Slot_%d" % index
	slot.custom_minimum_size = Vector2(70, 70)
	slot.text = ""
	slot.pressed.connect(_on_slot_pressed.bind(index))
	return slot

# ============================================
# 显示背包
# ============================================

func show_inventory():
	if inventory == null:
		print("InventoryUI: No inventory reference")
		return

	visible = true
	get_tree().paused = true
	selected_slot = -1
	use_button.disabled = true
	_refresh_slots()

func close():
	visible = false
	get_tree().paused = false
	inventory_closed.emit()

func _refresh_slots():
	if inventory == null:
		return

	var items = inventory.get_all_items()
	var items_by_slot = {}

	for item in items:
		# 找到物品所在槽位
		for i in range(20):
			if inventory.slots[i] == item:
				items_by_slot[i] = item
				break

	# 更新所有格子
	for i in range(20):
		var slot = slots_container.get_child(i)
		if slot:
			var item = items_by_slot.get(i)
			if item:
				slot.text = "%s\nx%d" % [item.item_name, item.quantity]
				# 根据物品类型设置颜色
				match item.item_type:
					InventoryManager.ItemType.MAP_RECORD:
						slot.modulate = Color(0.6, 0.8, 0.6)
					InventoryManager.ItemType.ESCAPE:
						slot.modulate = Color(0.8, 0.6, 0.6)
					InventoryManager.ItemType.FOOD:
						slot.modulate = Color(0.8, 0.8, 0.6)
					InventoryManager.ItemType.TREASURE:
						slot.modulate = Color(1.0, 0.85, 0.4)
					_:
						slot.modulate = Color(1, 1, 1)
			else:
				slot.text = ""
				slot.modulate = Color(0.5, 0.5, 0.5)

# ============================================
# 交互
# ============================================

func _on_slot_pressed(index: int):
	selected_slot = index

	if inventory == null or inventory.slots[index] == null:
		item_info_label.text = "空槽位"
		use_button.disabled = true
		return

	var item = inventory.slots[index]
	item_info_label.text = "%s\n数量: %d" % [item.item_name, item.quantity]

	# 检查是否可使用
	match item.item_type:
		InventoryManager.ItemType.MAP_RECORD, InventoryManager.ItemType.ESCAPE, InventoryManager.ItemType.FOOD:
			use_button.disabled = false
		InventoryManager.ItemType.MAP:
			use_button.text = "查看地图"
			use_button.disabled = false
		_:
			use_button.disabled = true

	# 高亮选中格子
	for i in range(20):
		var slot = slots_container.get_child(i)
		if slot:
			if i == index:
				slot.modulate = Color(1.2, 1.2, 0.8)
			else:
				# 恢复原始颜色
				var orig_item = inventory.slots[i]
				if orig_item:
					match orig_item.item_type:
						InventoryManager.ItemType.MAP_RECORD:
							slot.modulate = Color(0.6, 0.8, 0.6)
						InventoryManager.ItemType.ESCAPE:
							slot.modulate = Color(0.8, 0.6, 0.6)
						InventoryManager.ItemType.FOOD:
							slot.modulate = Color(0.8, 0.8, 0.6)
						InventoryManager.ItemType.TREASURE:
							slot.modulate = Color(1.0, 0.85, 0.4)
						_:
							slot.modulate = Color(1, 1, 1)
				else:
					slot.modulate = Color(0.5, 0.5, 0.5)

func _on_use_pressed():
	if selected_slot < 0 or inventory == null:
		return

	var item = inventory.slots[selected_slot]
	if item == null:
		return

	# 地图道具特殊处理
	if item.item_type == InventoryManager.ItemType.MAP:
		close()
		# 发送信号让 GameController 打开地图
		emit_signal("open_map_requested")
		return

	# 发送使用请求信号
	emit_signal("item_use_requested", selected_slot, item)

# ============================================
# 设置数据
# ============================================

func set_inventory(inv: InventoryManager):
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(_refresh_slots)

# ============================================
# 信号
# ============================================

signal item_use_requested(slot_index: int, item)
signal open_map_requested()

# ============================================
# 静态创建方法
# ============================================

static func create() -> InventoryUI:
	var inv_ui = InventoryUI.new()
	inv_ui.name = "InventoryUI"
	return inv_ui