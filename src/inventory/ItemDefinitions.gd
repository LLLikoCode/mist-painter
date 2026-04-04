## ItemDefinitions
## 物品定义
## 定义游戏中所有物品的基础属性

class_name ItemDefinitions
extends RefCounted

# ============================================
# 物品定义数据
# ============================================

const DEFINITIONS: Dictionary = {
	# 记录道具
	"map_paper": {
		"type": InventoryManager.ItemType.MAP_RECORD,
		"name": "地图纸张",
		"description": "记录当前位置周围3x3区域到地图上",
		"max_stack": 20,
		"price": 10
	},
	"quality_paper": {
		"type": InventoryManager.ItemType.MAP_RECORD,
		"name": "优质纸张",
		"description": "记录当前位置周围5x5区域到地图上",
		"max_stack": 10,
		"price": 25,
		"radius": 2
	},

	# 地图道具
	"explorer_map": {
		"type": InventoryManager.ItemType.MAP,
		"name": "探险地图",
		"description": "查看已记录的迷宫区域",
		"max_stack": 1,
		"price": 0
	},

	# 撤离道具
	"escape_scroll": {
		"type": InventoryManager.ItemType.ESCAPE,
		"name": "撤离卷轴",
		"description": "使用后直接返回迷宫入口",
		"max_stack": 5,
		"price": 50
	},

	# 食物
	"bread": {
		"type": InventoryManager.ItemType.FOOD,
		"name": "面包",
		"description": "恢复20点体力",
		"max_stack": 10,
		"price": 5,
		"stamina_restore": 20
	},
	"meat": {
		"type": InventoryManager.ItemType.FOOD,
		"name": "肉干",
		"description": "恢复40点体力",
		"max_stack": 10,
		"price": 15,
		"stamina_restore": 40
	},
	"stew": {
		"type": InventoryManager.ItemType.FOOD,
		"name": "炖肉",
		"description": "恢复70点体力",
		"max_stack": 5,
		"price": 30,
		"stamina_restore": 70
	},

	# 财宝
	"coin": {
		"type": InventoryManager.ItemType.TREASURE,
		"name": "金币",
		"description": "常见的货币",
		"max_stack": 99,
		"value": 1
	},
	"gem": {
		"type": InventoryManager.ItemType.TREASURE,
		"name": "宝石",
		"description": "闪亮的宝石，价值较高",
		"max_stack": 20,
		"value": 50
	},
	"artifact": {
		"type": InventoryManager.ItemType.TREASURE,
		"name": "古代文物",
		"description": "珍贵的古代遗物",
		"max_stack": 5,
		"value": 200
	},

	# 钥匙
	"bronze_key": {
		"type": InventoryManager.ItemType.KEY,
		"name": "铜钥匙",
		"description": "打开铜锁",
		"max_stack": 5,
		"price": 20
	},
	"silver_key": {
		"type": InventoryManager.ItemType.KEY,
		"name": "银钥匙",
		"description": "打开银锁",
		"max_stack": 3,
		"price": 50
	},
	"gold_key": {
		"type": InventoryManager.ItemType.KEY,
		"name": "金钥匙",
		"description": "打开金锁",
		"max_stack": 1,
		"price": 150
	}
}

# ============================================
# 获取方法
# ============================================

## 获取物品定义
static func get_definition(item_id: String) -> Dictionary:
	return DEFINITIONS.get(item_id, {})

## 获取物品类型
static func get_item_type(item_id: String) -> int:
	var def = DEFINITIONS.get(item_id, {})
	return def.get("type", InventoryManager.ItemType.NONE)

## 获取物品名称
static func get_item_name(item_id: String) -> String:
	var def = DEFINITIONS.get(item_id, {})
	return def.get("name", "未知物品")

## 获取物品描述
static func get_item_description(item_id: String) -> String:
	var def = DEFINITIONS.get(item_id, {})
	return def.get("description", "")

## 获取物品价格
static func get_item_price(item_id: String) -> int:
	var def = DEFINITIONS.get(item_id, {})
	return def.get("price", 0)

## 获取物品价值（出售价格）
static func get_item_value(item_id: String) -> int:
	var def = DEFINITIONS.get(item_id, {})
	return def.get("value", def.get("price", 0) / 2)

## 获取最大堆叠数
static func get_max_stack(item_id: String) -> int:
	var def = DEFINITIONS.get(item_id, {})
	return def.get("max_stack", 1)

## 获取所有物品ID
static func get_all_item_ids() -> Array:
	return DEFINITIONS.keys()

## 创建物品实例
static func create_item(item_id: String, quantity: int = 1) -> InventoryManager.Item:
	var def = DEFINITIONS.get(item_id, {})
	if def.is_empty():
		return null

	var item = InventoryManager.Item.new(
		def.get("type", InventoryManager.ItemType.NONE),
		def.get("name", "未知物品"),
		quantity
	)
	item.max_stack = def.get("max_stack", 1)

	# 复制额外数据
	for key in def.keys():
		if key not in ["type", "name", "max_stack", "price", "description"]:
			item.data[key] = def[key]

	return item