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
signal hp_depleted
signal sp_depleted
signal ink_depleted
signal player_died
signal player_revived
signal stats_updated

# ============================================
# 生命周期
# ============================================

func _ready():
	current_hp = max_hp
	current_sp = max_sp
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
# 综合方法
# ============================================

## 重置所有资源到初始状态
func reset_stats() -> void:
	is_dead = false
	is_invincible = false

	current_hp = max_hp
	current_sp = max_sp
	current_ink = DEFAULT_START_INK

	hp_changed.emit(current_hp, max_hp)
	sp_changed.emit(current_sp, max_sp)
	ink_changed.emit(current_ink, max_ink)
	stats_updated.emit()

	print("PlayerStats reset")

## 完全恢复
func full_restore() -> void:
	is_dead = false
	current_hp = max_hp
	current_sp = max_sp
	current_ink = max_ink

	hp_changed.emit(current_hp, max_hp)
	sp_changed.emit(current_sp, max_sp)
	ink_changed.emit(current_ink, max_ink)
	stats_updated.emit()

## 休息点恢复 (设计文档: 恢复50% HP，完全恢复SP)
func rest_restore() -> void:
	heal_percentage(50.0)
	current_sp = max_sp
	sp_changed.emit(current_sp, max_sp)
	stats_updated.emit()
	print("Player rested: HP +50%, SP fully restored")

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
	is_dead = data.get("is_dead", false)

	hp_changed.emit(current_hp, max_hp)
	sp_changed.emit(current_sp, max_sp)
	ink_changed.emit(current_ink, max_ink)
	stats_updated.emit()

## 获取状态摘要
func get_status_summary() -> Dictionary:
	return {
		"hp": "%d/%d" % [int(current_hp), int(max_hp)],
		"sp": "%d/%d" % [int(current_sp), int(max_sp)],
		"ink": "%d/%d" % [int(current_ink), int(max_ink)],
		"is_dead": is_dead,
		"is_invincible": is_invincible
	}