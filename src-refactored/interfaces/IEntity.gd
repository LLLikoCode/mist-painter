## IEntity
## 实体接口
## 定义游戏中所有实体必须实现的基础接口

class_name IEntity
extends RefCounted

## 实体唯一ID
var entity_id: String = ""

## 实体类型
var entity_type: String = "base"

## 实体是否激活
var is_active: bool = true

## 实体是否已销毁
var is_destroyed: bool = false

## 初始化实体
## data: 初始化数据
func initialize(data: Dictionary = {}) -> void:
	if entity_id == "":
		entity_id = _generate_id()

## 实体更新
## delta: 帧间隔时间
func update(delta: float) -> void:
	pass

## 实体销毁
func destroy() -> void:
	is_destroyed = true
	is_active = false

## 设置实体激活状态
func set_active(active: bool) -> void:
	is_active = active

## 检查实体是否有效
func is_valid() -> bool:
	return not is_destroyed and is_active

## 获取实体状态
func get_state() -> Dictionary:
	return {
		"id": entity_id,
		"type": entity_type,
		"active": is_active,
		"destroyed": is_destroyed
	}

## 生成唯一ID
func _generate_id() -> String:
	return "%s_%d_%d" % [entity_type, Time.get_ticks_msec(), randi()]
