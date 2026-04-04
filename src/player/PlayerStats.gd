## PlayerStats
## 玩家资源管理类
## 管理HP(生命值)、SP(精神值)、墨水(资源)

class_name PlayerStats
extends Node

# ============================================
# 常量定义 - 基于设计文档
# ============================================

## HP (生命值)
const DEFAULT_MAX_HP: float = 100.0
const HP_MAX_LIMIT: float = 200.0

## SP (精神值) - 用于技能
const DEFAULT_MAX_SP: float = 50.0
const SP_MAX_LIMIT: float = 100.0

## 墨水 (资源/货币) - 用于迷雾绘制
const DEFAULT_MAX_INK: float = 100.0
const DEFAULT_START_INK: float = 50.0

## 墨水消耗率 (每像素绘制消耗)
const INK_COST_PER_PIXEL: float = 0.001

## 体力 (Stamina) - 用于移动和动作
const DEFAULT_MAX_STAMINA: float = 100.0
const STAMINA_MAX_LIMIT: float = 200.0

## 疲劳状态阈值
const FATIGUE_THRESHOLD_NORMAL: float = 0.70    # 70%以上: 正常
const FATIGUE_THRESHOLD_TIRED: float = 0.40     # 40-70%: 疲劳
const FATIGUE_THRESHOLD_EXHAUSTED: float = 0.20 # 20-40%: 精疲力竭
const FATIGUE_THRESHOLD_CRITICAL: float = 0.10  # 10-20%: 濒死

# ============================================
# 导出变量
# ============================================

@export_group("HP Settings")
@export var max_hp: float = DEFAULT_MAX_HP
@export var current_hp: float = DEFAULT_MAX_HP:
	set = set_current_hp

@export_group("SP Settings")
@export var max_sp: float = DEFAULT_MAX_SP
@export var current_sp: float = DEFAULT_MAX_SP:
	set = set_current_sp

@export_group("Ink Settings")
@export var max_ink: float = DEFAULT_MAX_INK
@export var current_ink: float = DEFAULT_START_INK:
	set = set_current_ink

@export var ink_cost_multiplier: float = 1.0

@export_group("Stamina Settings")
@export var max_stamina: float = DEFAULT_MAX_STAMINA
@export var current_stamina: float = DEFAULT_MAX_STAMINA:
	set = set_current_stamina

@export var stamina_cost_multiplier: float = 1.0

# ============================================
# 状态变量
# ============================================

## 是否死亡
var is_dead: bool = false

## 是否无敌
var is_invincible: bool = false

# ============================================
# 信号
# ============================================

signal hp_changed(current: float, max_hp: float)
signal sp_changed(current: float, max_sp: float)
signal ink_changed(current: float, max_ink: float)
signal stamina_changed(current: float, max_stamina: float)
signal fatigue_state_changed(state: int)  # 0=正常, 1=疲劳, 2=精疲力竭, 3=濒死
signal hp_depleted
signal sp_depleted
signal ink_depleted
signal stamina_depleted
signal player_died
signal player_revived
signal stats_updated

# ============================================
# 生命周期
# ============================================

## 当前疲劳状态 (0=正常, 1=疲劳, 2=精疲力竭, 3=濒死)
var current_fatigue_state: int = 0

func _ready():
	current_hp = max_hp
	current_sp = max_sp
	current_stamina = max_stamina
	current_fatigue_state = _calculate_fatigue_state()
	print("PlayerStats initialized")

# ============================================
# HP (生命值) 方法
# ============================================

## 设置当前HP
func set_current_hp(value: float) -> void:
	var old_value = current_hp
	current_hp = clamp(value, 0.0, max_hp)

	if abs(current_hp - old_value) > 0.01:
		hp_changed.emit(current_hp, max_hp)
		stats_updated.emit()

		if current_hp <= 0 and old_value > 0:
			hp_depleted.emit()
			_on_hp_depleted()

## 受到伤害
func take_damage(amount: float) -> bool:
	if is_dead or is_invincible:
		return false

	var actual_damage = max(0, amount)
	set_current_hp(current_hp - actual_damage)

	print("Player took %.1f damage, HP: %.1f/%.1f" % [actual_damage, current_hp, max_hp])
	return true

## 恢复生命值
func heal(amount: float) -> void:
	if is_dead:
		return

	set_current_hp(current_hp + amount)
	print("Player healed %.1f, HP: %.1f/%.1f" % [amount, current_hp, max_hp])

## 恢复生命值百分比
func heal_percentage(percentage: float) -> void:
	heal(max_hp * percentage / 100.0)

## 设置最大HP
func set_max_hp(value: float, heal_to_full: bool = false) -> void:
	max_hp = clamp(value, 1.0, HP_MAX_LIMIT)

	if heal_to_full:
		current_hp = max_hp

	hp_changed.emit(current_hp, max_hp)

## HP耗尽处理
func _on_hp_depleted() -> void:
	is_dead = true
	player_died.emit()
	print("Player died!")

## 获取HP百分比
func get_hp_percentage() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0

## 检查是否低血量
func is_low_hp(threshold: float = 0.3) -> bool:
	return get_hp_percentage() <= threshold

# ============================================
# SP (精神值) 方法
# ============================================

## 设置当前SP
func set_current_sp(value: float) -> void:
	var old_value = current_sp
	current_sp = clamp(value, 0.0, max_sp)

	if abs(current_sp - old_value) > 0.01:
		sp_changed.emit(current_sp, max_sp)
		stats_updated.emit()

		if current_sp <= 0 and old_value > 0:
			sp_depleted.emit()

## 消耗SP
func consume_sp(amount: float) -> bool:
	if current_sp >= amount:
		set_current_sp(current_sp - amount)
		return true
	return false

## 恢复SP
func restore_sp(amount: float) -> void:
	set_current_sp(current_sp + amount)

## 恢复SP百分比
func restore_sp_percentage(percentage: float) -> void:
	restore_sp(max_sp * percentage / 100.0)

## 设置最大SP
func set_max_sp(value: float, restore_to_full: bool = false) -> void:
	max_sp = clamp(value, 1.0, SP_MAX_LIMIT)

	if restore_to_full:
		current_sp = max_sp

	sp_changed.emit(current_sp, max_sp)

## 获取SP百分比
func get_sp_percentage() -> float:
	return current_sp / max_sp if max_sp > 0 else 0.0

## 检查是否有足够SP
func has_enough_sp(amount: float) -> bool:
	return current_sp >= amount

# ============================================
# 墨水 (资源) 方法
# ============================================

## 设置当前墨水
func set_current_ink(value: float) -> void:
	var old_value = current_ink
	current_ink = clamp(value, 0.0, max_ink)

	if abs(current_ink - old_value) > 0.01:
		ink_changed.emit(current_ink, max_ink)
		stats_updated.emit()

		if current_ink <= 0 and old_value > 0:
			ink_depleted.emit()

## 消耗墨水 (用于迷雾绘制)
func consume_ink(amount: float) -> bool:
	var actual_cost = amount * ink_cost_multiplier

	if current_ink >= actual_cost:
		set_current_ink(current_ink - actual_cost)
		return true
	return false

## 恢复墨水
func restore_ink(amount: float) -> void:
	set_current_ink(current_ink + amount)

## 恢复墨水百分比
func restore_ink_percentage(percentage: float) -> void:
	restore_ink(max_ink * percentage / 100.0)

## 设置最大墨水
func set_max_ink(value: float, fill_to_full: bool = false) -> void:
	max_ink = max(1.0, value)

	if fill_to_full:
		current_ink = max_ink

	ink_changed.emit(current_ink, max_ink)

## 获取墨水百分比
func get_ink_percentage() -> float:
	return current_ink / max_ink if max_ink > 0 else 0.0

## 检查是否有足够墨水
func has_enough_ink(amount: float) -> bool:
	return current_ink >= amount * ink_cost_multiplier

## 计算绘制消耗的墨水
func calculate_drawing_cost(pixel_count: int, brush_size: float) -> float:
	return pixel_count * INK_COST_PER_PIXEL * brush_size * 0.01 * ink_cost_multiplier

## 尝试绘制消耗墨水
func try_consume_for_drawing(pixel_count: int, brush_size: float) -> bool:
	var cost = calculate_drawing_cost(pixel_count, brush_size)
	return consume_ink(cost)

# ============================================
# 体力 (Stamina) 方法
# ============================================

## 设置当前体力
func set_current_stamina(value: float) -> void:
	var old_value = current_stamina
	current_stamina = clamp(value, 0.0, max_stamina)

	if abs(current_stamina - old_value) > 0.01:
		stamina_changed.emit(current_stamina, max_stamina)
		stats_updated.emit()

		# 检查疲劳状态变化
		var new_fatigue_state = _calculate_fatigue_state()
		if new_fatigue_state != current_fatigue_state:
			current_fatigue_state = new_fatigue_state
			fatigue_state_changed.emit(current_fatigue_state)

		if current_stamina <= 0 and old_value > 0:
			stamina_depleted.emit()

## 消耗体力
func consume_stamina(amount: float) -> bool:
	var actual_cost = amount * stamina_cost_multiplier

	if current_stamina >= actual_cost:
		set_current_stamina(current_stamina - actual_cost)
		return true
	return false

## 恢复体力
func restore_stamina(amount: float) -> void:
	set_current_stamina(current_stamina + amount)

## 恢复体力百分比
func restore_stamina_percentage(percentage: float) -> void:
	restore_stamina(max_stamina * percentage / 100.0)

## 设置最大体力
func set_max_stamina(value: float, fill_to_full: bool = false) -> void:
	max_stamina = clamp(value, 1.0, STAMINA_MAX_LIMIT)

	if fill_to_full:
		current_stamina = max_stamina

	stamina_changed.emit(current_stamina, max_stamina)

## 获取体力百分比
func get_stamina_percentage() -> float:
	return current_stamina / max_stamina if max_stamina > 0 else 0.0

## 检查是否有足够体力
func has_enough_stamina(amount: float) -> bool:
	return current_stamina >= amount * stamina_cost_multiplier

## 计算疲劳状态
func _calculate_fatigue_state() -> int:
	var percentage = get_stamina_percentage()
	if percentage >= FATIGUE_THRESHOLD_NORMAL:
		return 0  # 正常
	elif percentage >= FATIGUE_THRESHOLD_TIRED:
		return 1  # 疲劳
	elif percentage >= FATIGUE_THRESHOLD_EXHAUSTED:
		return 2  # 精疲力竭
	elif percentage >= FATIGUE_THRESHOLD_CRITICAL:
		return 3  # 濒死
	else:
		return 4  # 昏迷 (体力为0)

## 获取疲劳状态名称
func get_fatigue_state_name() -> String:
	match current_fatigue_state:
		0: return "精力充沛"
		1: return "疲劳"
		2: return "精疲力竭"
		3: return "濒死"
		4: return "昏迷"
	return "未知"

## 获取疲劳状态效果
func get_fatigue_effects() -> Dictionary:
	## 返回疲劳状态的效果参数
	match current_fatigue_state:
		0: # 正常
			return {
				"speed_modifier": 1.0,
				"draw_error_modifier": 0.0,
				"vision_penalty": 0,
				"can_draw": true
			}
		1: # 疲劳 (40-70%)
			return {
				"speed_modifier": 0.9,
				"draw_error_modifier": 0.1,
				"vision_penalty": 0,
				"can_draw": true
			}
		2: # 精疲力竭 (20-40%)
			return {
				"speed_modifier": 0.75,
				"draw_error_modifier": 0.25,
				"vision_penalty": 1,
				"can_draw": true
			}
		3: # 濒死 (10-20%)
			return {
				"speed_modifier": 0.5,
				"draw_error_modifier": 0.5,
				"vision_penalty": 2,
				"can_draw": false
			}
		4: # 昏迷 (0%)
			return {
				"speed_modifier": 0.0,
				"draw_error_modifier": 1.0,
				"vision_penalty": 3,
				"can_draw": false
			}
	return {
		"speed_modifier": 1.0,
		"draw_error_modifier": 0.0,
		"vision_penalty": 0,
		"can_draw": true
	}

# ============================================
# 综合方法
# ============================================

## 重置所有资源到初始状态
func reset_stats() -> void:
	is_dead = false
	is_invincible = false

	current_hp = max_hp
	current_sp = max_sp
	current_ink = DEFAULT_START_INK
	current_stamina = max_stamina
	current_fatigue_state = 0

	hp_changed.emit(current_hp, max_hp)
	sp_changed.emit(current_sp, max_sp)
	ink_changed.emit(current_ink, max_ink)
	stamina_changed.emit(current_stamina, max_stamina)
	stats_updated.emit()

	print("PlayerStats reset")

## 完全恢复
func full_restore() -> void:
	is_dead = false
	current_hp = max_hp
	current_sp = max_sp
	current_ink = max_ink
	current_stamina = max_stamina
	current_fatigue_state = 0

	hp_changed.emit(current_hp, max_hp)
	sp_changed.emit(current_sp, max_sp)
	ink_changed.emit(current_ink, max_ink)
	stamina_changed.emit(current_stamina, max_stamina)
	stats_updated.emit()

## 休息点恢复 (设计文档: 恢复50% HP，完全恢复SP和体力)
func rest_restore() -> void:
	heal_percentage(50.0)
	current_sp = max_sp
	current_stamina = max_stamina
	current_fatigue_state = 0
	sp_changed.emit(current_sp, max_sp)
	stamina_changed.emit(current_stamina, max_stamina)
	stats_updated.emit()
	print("Player rested: HP +50%, SP and Stamina fully restored")

## 复活
func revive(restore_hp_percentage: float = 100.0) -> void:
	is_dead = false
	heal_percentage(restore_hp_percentage)
	player_revived.emit()
	print("Player revived with %.0f%% HP" % restore_hp_percentage)

## 设置无敌状态
func set_invincible(enabled: bool) -> void:
	is_invincible = enabled

# ============================================
# 存档支持
# ============================================

## 导出状态数据
func export_state() -> Dictionary:
	return {
		"max_hp": max_hp,
		"current_hp": current_hp,
		"max_sp": max_sp,
		"current_sp": current_sp,
		"max_ink": max_ink,
		"current_ink": current_ink,
		"ink_cost_multiplier": ink_cost_multiplier,
		"max_stamina": max_stamina,
		"current_stamina": current_stamina,
		"stamina_cost_multiplier": stamina_cost_multiplier,
		"current_fatigue_state": current_fatigue_state,
		"is_dead": is_dead
	}

## 导入状态数据
func import_state(data: Dictionary) -> void:
	max_hp = data.get("max_hp", DEFAULT_MAX_HP)
	current_hp = data.get("current_hp", max_hp)
	max_sp = data.get("max_sp", DEFAULT_MAX_SP)
	current_sp = data.get("current_sp", max_sp)
	max_ink = data.get("max_ink", DEFAULT_MAX_INK)
	current_ink = data.get("current_ink", DEFAULT_START_INK)
	ink_cost_multiplier = data.get("ink_cost_multiplier", 1.0)
	max_stamina = data.get("max_stamina", DEFAULT_MAX_STAMINA)
	current_stamina = data.get("current_stamina", max_stamina)
	stamina_cost_multiplier = data.get("stamina_cost_multiplier", 1.0)
	current_fatigue_state = data.get("current_fatigue_state", 0)
	is_dead = data.get("is_dead", false)

	hp_changed.emit(current_hp, max_hp)
	sp_changed.emit(current_sp, max_sp)
	ink_changed.emit(current_ink, max_ink)
	stamina_changed.emit(current_stamina, max_stamina)
	stats_updated.emit()

## 获取状态摘要
func get_status_summary() -> Dictionary:
	return {
		"hp": "%d/%d" % [int(current_hp), int(max_hp)],
		"sp": "%d/%d" % [int(current_sp), int(max_sp)],
		"ink": "%d/%d" % [int(current_ink), int(max_ink)],
		"stamina": "%d/%d" % [int(current_stamina), int(max_stamina)],
		"fatigue_state": get_fatigue_state_name(),
		"is_dead": is_dead,
		"is_invincible": is_invincible
	}