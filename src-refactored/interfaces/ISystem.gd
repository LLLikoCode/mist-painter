## ISystem
## 系统接口
## 定义所有子系统必须实现的基础接口

class_name ISystem
extends RefCounted

## 系统名称
var system_name: String = "BaseSystem"

## 系统是否已初始化
var is_initialized: bool = false

## 系统是否已启用
var is_enabled: bool = true

## 初始化系统
## 返回是否初始化成功
func initialize(context: SystemContext) -> bool:
	is_initialized = true
	return true

## 系统更新（每帧调用）
## delta: 帧间隔时间
func update(delta: float) -> void:
	pass

## 固定频率更新（物理更新）
## delta: 固定时间间隔
func fixed_update(delta: float) -> void:
	pass

## 系统销毁清理
func shutdown() -> void:
	is_initialized = false

## 暂停系统
func pause() -> void:
	is_enabled = false

## 恢复系统
func resume() -> void:
	is_enabled = true

## 获取系统状态
func get_status() -> Dictionary:
	return {
		"name": system_name,
		"initialized": is_initialized,
		"enabled": is_enabled
	}
