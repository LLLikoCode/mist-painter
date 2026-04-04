## LightSystem
## 光源管理系统
## 管理玩家携带的光源，影响视野范围

class_name LightSystem
extends Node

# ============================================
# 常量定义 - 基于设计文档
# ============================================

## 光源类型
enum LightType {
	TORCH,        # 火把: +2格, 10分钟
	LANTERN,      # 提灯: +3格, 30分钟
	GLOWSTONE,    # 荧光石: +1格, 永久
	MAGIC_ORB,    # 魔法光球: +4格, 5分钟
	SUN_SCROLL    # 阳光卷轴: 全屏, 1分钟
}

## 光源属性配置
const LIGHT_CONFIGS: Dictionary = {
	LightType.TORCH: {
		"vision_bonus": 2.0,
		"duration": 600.0,  # 10分钟 = 600秒
		"name": "火把",
		"flicker": false,  # 暂时禁用闪烁
		"consumable": true
	},
	LightType.LANTERN: {
		"vision_bonus": 3.0,
		"duration": 1800.0,  # 30分钟 = 1800秒
		"name": "提灯",
		"flicker": false,
		"consumable": true
	},
	LightType.GLOWSTONE: {
		"vision_bonus": 1.0,
		"duration": -1.0,  # 永久
		"name": "荧光石",
		"flicker": false,
		"consumable": false
	},
	LightType.MAGIC_ORB: {
		"vision_bonus": 4.0,
		"duration": 300.0,  # 5分钟 = 300秒
		"name": "魔法光球",
		"flicker": false,
		"consumable": true,
		"sp_cost": 20.0
	},
	LightType.SUN_SCROLL: {
		"vision_bonus": 999.0,  # 全屏
		"duration": 60.0,  # 1分钟
		"name": "阳光卷轴",
		"flicker": false,
		"consumable": true,
		"one_time": true
	}
}

# ============================================
# 状态变量
# ============================================

## 当前激活的光源
var active_light_type: LightType = LightType.TORCH

## 光源剩余时间
var remaining_time: float = 600.0

## 光源是否激活
var is_light_active: bool = true

## 是否闪烁 (火把效果)
var is_flickering: bool = false

## 当前视野加成
var current_vision_bonus: float = 2.0

## 拥有的光源库存
var light_inventory: Dictionary = {
	LightType.TORCH: 3,
	LightType.LANTERN: 0,
	LightType.GLOWSTONE: 0,
	LightType.MAGIC_ORB: 0,
	LightType.SUN_SCROLL: 0
}

# ============================================
# 信号
# ============================================

signal light_changed(type: LightType, name: String)
signal light_time_changed(remaining: float, total: float)
signal light_depleted
signal light_activated
signal light_deactivated
signal vision_bonus_changed(bonus: float)
signal low_light_warning(level: int)  # 1=黄色警告, 2=红色警告

# ============================================
# 生命周期
# ============================================

func _ready():
	# 初始化默认光源 (火把)
	activate_light(LightType.TORCH)
	print("LightSystem initialized")

func _process(delta: float):
	if not is_light_active:
		return

	# 更新光源时间
	_update_light_time(delta)

# ============================================
# 光源管理
# ============================================

## 激活光源
func activate_light(type: LightType) -> bool:
	# 检查是否有此光源
	if light_inventory.get(type, 0) <= 0 and type != LightType.GLOWSTONE:
		print("No light of this type available")
		return false

	var config = LIGHT_CONFIGS.get(type, {})

	# 设置光源属性
	active_light_type = type
	current_vision_bonus = config.get("vision_bonus", 0.0)
	remaining_time = config.get("duration", -1.0)
	is_flickering = config.get("flicker", false)
	is_light_active = true

	# 一次性光源消耗库存
	if config.get("one_time", false):
		light_inventory[type] -= 1

	light_changed.emit(type, config.get("name", "未知"))
	light_activated.emit()
	vision_bonus_changed.emit(current_vision_bonus)

	print("Activated light: %s, vision bonus: %.1f" % [config.get("name", "未知"), current_vision_bonus])
	return true

## 关闭光源
func deactivate_light() -> void:
	is_light_active = false
	current_vision_bonus = 0.0

	light_deactivated.emit()
	vision_bonus_changed.emit(0.0)

	print("Light deactivated")

## 切换光源开关
func toggle_light() -> void:
	if is_light_active:
		deactivate_light()
	else:
		activate_light(active_light_type)

## 切换到下一个光源
func switch_to_next_light() -> bool:
	# 找到下一个可用的光源
	var types = [LightType.TORCH, LightType.LANTERN, LightType.GLOWSTONE, LightType.MAGIC_ORB, LightType.SUN_SCROLL]
	var current_index = types.find(active_light_type)

	for i in range(1, types.size()):
		var next_index = (current_index + i) % types.size()
		var next_type = types[next_index]

		if light_inventory.get(next_type, 0) > 0 or next_type == LightType.GLOWSTONE:
			return activate_light(next_type)

	return false

## 更新光源时间
func _update_light_time(delta: float) -> void:
	# 永久光源不消耗时间
	if remaining_time < 0:
		return

	remaining_time -= delta

	# 发送时间变化信号
	var total_time = LIGHT_CONFIGS.get(active_light_type, {}).get("duration", 600.0)
	light_time_changed.emit(remaining_time, total_time)

	# 低光源警告
	if remaining_time <= total_time * 0.1:
		low_light_warning.emit(2)  # 红色警告
	elif remaining_time <= total_time * 0.3:
		low_light_warning.emit(1)  # 黄色警告

	# 光源耗尽
	if remaining_time <= 0:
		_on_light_depleted()

## 光源耗尽处理
func _on_light_depleted() -> void:
	is_light_active = false
	current_vision_bonus = 0.0

	light_depleted.emit()
	vision_bonus_changed.emit(0.0)

	print("Light depleted!")

	# 尝试自动切换到下一个光源
	switch_to_next_light()

# ============================================
# 光源获取与管理
# ============================================

## 添加光源到库存
func add_light(type: LightType, count: int = 1) -> void:
	light_inventory[type] = light_inventory.get(type, 0) + count
	print("Added %d %s(s) to inventory" % [count, LIGHT_CONFIGS[type]["name"]])

## 使用光源
func use_light(type: LightType) -> bool:
	if light_inventory.get(type, 0) <= 0:
		return false

	return activate_light(type)

## 补充光源燃料
func refuel_light(amount: float) -> void:
	if active_light_type == LightType.TORCH:
		remaining_time += amount * 60.0  # amount表示分钟数
	elif active_light_type == LightType.LANTERN:
		remaining_time += amount * 60.0

	var max_time = LIGHT_CONFIGS.get(active_light_type, {}).get("duration", 600.0)
	remaining_time = min(remaining_time, max_time)

	print("Refueled light, remaining time: %.1f seconds" % remaining_time)

## 检查是否有光源
func has_light(type: LightType) -> bool:
	return light_inventory.get(type, 0) > 0

## 获取光源库存数量
func get_light_count(type: LightType) -> int:
	return light_inventory.get(type, 0)

# ============================================
# 状态获取
# ============================================

## 获取当前视野加成
func get_vision_bonus() -> float:
	return current_vision_bonus if is_light_active else 0.0

## 获取光源名称
func get_light_name() -> String:
	return LIGHT_CONFIGS.get(active_light_type, {}).get("name", "未知")

## 获取光源状态摘要
func get_light_status() -> Dictionary:
	var config = LIGHT_CONFIGS.get(active_light_type, {})
	var percentage = remaining_time / config.get("duration", 600.0) if config.get("duration", 600.0) > 0 else 1.0

	return {
		"type": active_light_type,
		"name": config.get("name", "未知"),
		"is_active": is_light_active,
		"vision_bonus": current_vision_bonus,
		"remaining_time": remaining_time,
		"remaining_percentage": percentage,
		"is_flickering": is_flickering,
		"inventory": light_inventory
	}

# ============================================
# 存档支持
# ============================================

## 导出状态
func export_state() -> Dictionary:
	return {
		"active_light_type": active_light_type,
		"remaining_time": remaining_time,
		"is_light_active": is_light_active,
		"light_inventory": light_inventory
	}

## 导入状态
func import_state(data: Dictionary) -> void:
	active_light_type = data.get("active_light_type", LightType.TORCH)
	remaining_time = data.get("remaining_time", 600.0)
	is_light_active = data.get("is_light_active", true)
	light_inventory = data.get("light_inventory", light_inventory)

	var config = LIGHT_CONFIGS.get(active_light_type, {})
	current_vision_bonus = config.get("vision_bonus", 2.0)
	is_flickering = config.get("flicker", false)

	light_changed.emit(active_light_type, config.get("name", "未知"))
	vision_bonus_changed.emit(current_vision_bonus)

# ============================================
# 重置
# ============================================

## 重置光源系统
func reset_light_system() -> void:
	light_inventory = {
		LightType.TORCH: 3,
		LightType.LANTERN: 0,
		LightType.GLOWSTONE: 0,
		LightType.MAGIC_ORB: 0,
		LightType.SUN_SCROLL: 0
	}

	activate_light(LightType.TORCH)
	print("LightSystem reset")