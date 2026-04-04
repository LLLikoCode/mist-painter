## InventoryManager
## 背包管理系统
## 管理玩家携带的物品，固定20格容量

class_name InventoryManager
extends Node

# ============================================
# 常量定义
# ============================================

## 背包最大容量
const MAX_SLOTS: int = 20

## 物品类型枚举
enum ItemType {
	NONE = 0,
	MAP_RECORD = 1,    # 记录道具
	MAP = 2,           # 地图道具
	ESCAPE = 3,        # 撤离道具
	FOOD = 4,          # 食物（恢复体力）
	TREASURE = 5,      # 财宝
	KEY = 6,           # 钥匙
	OTHER = 99         # 其他
}

# ============================================
# 数据结构
# ============================================

## 物品数据结构
class Item:
	var item_type: int = ItemType.NONE
	var item_name: String = ""
	var quantity: int = 1
	var max_stack: int = 10
	var data: Dictionary = {}  # 额外数据

	func _init(type: int, name: String, qty: int = 1):
		item_type = type
		item_name = name
		quantity = qty

# ============================================
# 状态变量
# ============================================

## 背包槽位
var slots: Array[Item] = []

## 当前使用的地图道具（记录的数据存储在这里）
var recorded_areas: Array[Vector2i] = []

# ============================================
# 信号
# ============================================

signal inventory_changed()
signal item_added(item_type: int, item_name: String, quantity: int)
signal item_removed(item_type: int, item_name: String, quantity: int)
signal item_used(item_type: int, item_name: String)
signal inventory_full()

# ============================================
# 生命周期
# ============================================

func _ready():
	# 初始化空槽位
	for i in range(MAX_SLOTS):
		slots.append(null)
	print("InventoryManager initialized with %d slots" % MAX_SLOTS)

# ============================================
# 物品操作
# ============================================

## 添加物品
func add_item(item_type: int, item_name: String, quantity: int = 1) -> bool:
	# 首先尝试堆叠到现有物品
	if _can_stack(item_type, item_name):
		for slot in slots:
			if slot and slot.item_type == item_type and slot.item_name == item_name:
				if slot.quantity + quantity <= slot.max_stack:
					slot.quantity += quantity
					item_added.emit(item_type, item_name, quantity)
					inventory_changed.emit()
					return true
				else:
					# 堆叠超过上限，先填满这个槽位
					var space = slot.max_stack - slot.quantity
					slot.quantity = slot.max_stack
					quantity -= space
					item_added.emit(item_type, item_name, space)

	# 寻找空槽位
	for i in range(MAX_SLOTS):
		if slots[i] == null:
			slots[i] = Item.new(item_type, item_name, min(quantity, _get_max_stack(item_type)))
			item_added.emit(item_type, item_name, min(quantity, _get_max_stack(item_type)))
			inventory_changed.emit()
			return true

	# 背包已满
	inventory_full.emit()
	return false

## 移除物品
func remove_item(item_type: int, item_name: String, quantity: int = 1) -> bool:
	for i in range(MAX_SLOTS):
		if slots[i] and slots[i].item_type == item_type and slots[i].item_name == item_name:
			if slots[i].quantity >= quantity:
				slots[i].quantity -= quantity
				item_removed.emit(item_type, item_name, quantity)

				if slots[i].quantity <= 0:
					slots[i] = null

				inventory_changed.emit()
				return true

	return false

## 使用物品
func use_item(slot_index: int, context: Dictionary = {}) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false

	var item = slots[slot_index]
	if item == null:
		return false

	# 根据物品类型执行不同效果
	var result = _execute_item_effect(item, context)

	if result:
		item_used.emit(item.item_type, item.item_name)

		# 消耗品使用后减少数量
		if _is_consumable(item.item_type):
			item.quantity -= 1
			if item.quantity <= 0:
				slots[slot_index] = null

		inventory_changed.emit()
		return true

	return false

## 获取物品数量
func get_item_count(item_type: int, item_name: String = "") -> int:
	var count = 0
	for slot in slots:
		if slot and slot.item_type == item_type:
			if item_name.is_empty() or slot.item_name == item_name:
				count += slot.quantity
	return count

## 获取所有物品
func get_all_items() -> Array[Item]:
	var items: Array[Item] = []
	for slot in slots:
		if slot:
			items.append(slot)
	return items

## 清空背包
func clear_inventory():
	for i in range(MAX_SLOTS):
		slots[i] = null
	inventory_changed.emit()
	print("Inventory cleared")

## 获取已使用槽位数
func get_used_slots() -> int:
	var count = 0
	for slot in slots:
		if slot:
			count += 1
	return count

## 获取剩余空间
func get_free_slots() -> int:
	return MAX_SLOTS - get_used_slots()

# ============================================
# 记录系统
# ============================================

## 记录区域（由记录道具调用）
func record_area(center_pos: Vector2i, radius: int = 1) -> int:
	var recorded_count = 0

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos = Vector2i(center_pos.x + dx, center_pos.y + dy)
			if not recorded_areas.has(pos):
				recorded_areas.append(pos)
				recorded_count += 1

	print("Recorded %d new cells, total recorded: %d" % [recorded_count, recorded_areas.size()])
	return recorded_count

## 获取已记录的区域
func get_recorded_areas() -> Array[Vector2i]:
	return recorded_areas

## 清除记录
func clear_records():
	recorded_areas.clear()
	print("Map records cleared")

## 检查位置是否已记录
func is_area_recorded(pos: Vector2i) -> bool:
	return recorded_areas.has(pos)

# ============================================
# 内部方法
# ============================================

func _can_stack(item_type: int, item_name: String) -> bool:
	match item_type:
		ItemType.MAP_RECORD, ItemType.FOOD, ItemType.TREASURE:
			return true
		_:
			return false

func _get_max_stack(item_type: int) -> int:
	match item_type:
		ItemType.MAP_RECORD:
			return 20
		ItemType.FOOD:
			return 10
		ItemType.TREASURE:
			return 99
		_:
			return 1

func _is_consumable(item_type: int) -> bool:
	match item_type:
		ItemType.MAP_RECORD, ItemType.ESCAPE, ItemType.FOOD:
			return true
		_:
			return false

func _execute_item_effect(item: Item, context: Dictionary) -> bool:
	match item.item_type:
		ItemType.MAP_RECORD:
			# 记录道具：记录玩家当前位置周围的区域
			if context.has("player_pos"):
				var player_pos: Vector2i = context["player_pos"]
				record_area(player_pos)
				return true
			return false

		ItemType.ESCAPE:
			# 撤离道具：返回入口
			if context.has("escape_callback"):
				context["escape_callback"].call()
				return true
			return false

		ItemType.FOOD:
			# 食物：恢复体力
			if context.has("player_stats"):
				var stats = context["player_stats"]
				var restore_amount = item.data.get("stamina_restore", 30)
				if stats.has_method("restore_stamina"):
					stats.restore_stamina(restore_amount)
					return true
			return false

		ItemType.MAP:
			# 地图道具：显示已记录区域（由UI处理）
			return true

		_:
			return false

# ============================================
# 序列化
# ============================================

## 获取保存数据
func get_save_data() -> Dictionary:
	var items_data = []
	for i in range(MAX_SLOTS):
		if slots[i]:
			items_data.append({
				"slot": i,
				"type": slots[i].item_type,
				"name": slots[i].item_name,
				"quantity": slots[i].quantity,
				"data": slots[i].data
			})

	return {
		"items": items_data,
		"recorded_areas": recorded_areas
	}

## 加载保存数据
func load_save_data(data: Dictionary) -> void:
	# 清空现有数据
	clear_inventory()
	recorded_areas.clear()

	# 加载物品
	var items_data = data.get("items", [])
	for item_data in items_data:
		var slot_index = item_data.get("slot", -1)
		if slot_index >= 0 and slot_index < MAX_SLOTS:
			var item = Item.new(
				item_data.get("type", ItemType.NONE),
				item_data.get("name", ""),
				item_data.get("quantity", 1)
			)
			item.data = item_data.get("data", {})
			slots[slot_index] = item

	# 加载记录区域
	var areas = data.get("recorded_areas", [])
	for area in areas:
		recorded_areas.append(Vector2i(area.x, area.y))

	inventory_changed.emit()
	print("Inventory loaded: %d items, %d recorded areas" % [get_used_slots(), recorded_areas.size()])