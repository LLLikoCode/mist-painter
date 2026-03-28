## IUpdatable
## 可更新接口
## 定义需要每帧更新的对象接口

class_name IUpdatable
extends RefCounted

## 更新优先级（数值越小优先级越高）
var update_priority: int = 0

## 是否启用更新
var update_enabled: bool = true

## 更新频率（每N帧更新一次，1表示每帧都更新）
var update_frequency: int = 1

## 内部计数器
var _update_counter: int = 0

## 执行更新
## delta: 帧间隔时间
## 返回是否执行了更新
func do_update(delta: float) -> bool:
	if not update_enabled:
		return false
	
	_update_counter += 1
	if _update_counter >= update_frequency:
		_update_counter = 0
		update(delta)
		return true
	return false

## 实际更新逻辑（子类实现）
## delta: 帧间隔时间
func update(delta: float) -> void:
	pass

## 设置更新频率
func set_update_frequency(frequency: int) -> void:
	update_frequency = max(1, frequency)

## 设置更新启用状态
func set_update_enabled(enabled: bool) -> void:
	update_enabled = enabled
