## SystemContext
## 系统上下文
## 提供依赖注入容器，管理所有子系统的引用和生命周期

class_name SystemContext
extends RefCounted

## 单例实例
static var instance: SystemContext = null

## 系统注册表
var _systems: Dictionary = {}

## 系统依赖图
var _dependencies: Dictionary = {}

## 初始化顺序缓存
var _init_order: Array[String] = []

## 是否已初始化
var _initialized: bool = false

## 获取单例
static func get_instance() -> SystemContext:
	if instance == null:
		instance = SystemContext.new()
	return instance

## 注册系统
## system_name: 系统名称
## system_class: 系统类（必须是ISystem的子类）
## dependencies: 依赖的系统名称列表
func register_system(system_name: String, system_class: GDScript, dependencies: Array[String] = []) -> ISystem:
	if _systems.has(system_name):
		push_warning("System already registered: %s" % system_name)
		return _systems[system_name]
	
	# 创建系统实例
	var system = system_class.new() as ISystem
	if system == null:
		push_error("Failed to create system instance: %s" % system_name)
		return null
	
	system.system_name = system_name
	_systems[system_name] = system
	_dependencies[system_name] = dependencies.duplicate()
	
	print("SystemContext: Registered system '%s' with %d dependencies" % [system_name, dependencies.size()])
	return system

## 获取系统
func get_system(system_name: String) -> ISystem:
	return _systems.get(system_name)

## 检查系统是否已注册
func has_system(system_name: String) -> bool:
	return _systems.has(system_name)

## 初始化所有系统（按依赖顺序）
func initialize_all_systems() -> bool:
	if _initialized:
		return true
	
	# 计算初始化顺序
	_calculate_init_order()
	
	# 按顺序初始化
	for system_name in _init_order:
		var system = _systems[system_name] as ISystem
		if system == null:
			push_error("System not found: %s" % system_name)
			return false
		
		print("SystemContext: Initializing system '%s'..." % system_name)
		if not system.initialize(self):
			push_error("Failed to initialize system: %s" % system_name)
			return false
	
	_initialized = true
	print("SystemContext: All systems initialized successfully")
	return true

## 更新所有系统
func update_all_systems(delta: float) -> void:
	for system in _systems.values():
		if system.is_initialized and system.is_enabled:
			system.update(delta)

## 固定更新所有系统
func fixed_update_all_systems(delta: float) -> void:
	for system in _systems.values():
		if system.is_initialized and system.is_enabled:
			system.fixed_update(delta)

## 关闭所有系统（逆序）
func shutdown_all_systems() -> void:
	# 按初始化逆序关闭
	var shutdown_order = _init_order.duplicate()
	shutdown_order.reverse()
	
	for system_name in shutdown_order:
		var system = _systems[system_name] as ISystem
		if system != null and system.is_initialized:
			print("SystemContext: Shutting down system '%s'..." % system_name)
			system.shutdown()
	
	_systems.clear()
	_dependencies.clear()
	_init_order.clear()
	_initialized = false
	
	print("SystemContext: All systems shut down")

## 暂停所有系统
func pause_all_systems() -> void:
	for system in _systems.values():
		system.pause()

## 恢复所有系统
func resume_all_systems() -> void:
	for system in _systems.values():
		system.resume()

## 计算初始化顺序（拓扑排序）
func _calculate_init_order() -> void:
	_init_order.clear()
	
	var visited: Dictionary = {}
	var temp_mark: Dictionary = {}
	
	for system_name in _systems.keys():
		if not visited.has(system_name):
			_visit_system(system_name, visited, temp_mark)
	
	print("SystemContext: Calculated initialization order: %s" % str(_init_order))

## 深度优先搜索访问系统
func _visit_system(system_name: String, visited: Dictionary, temp_mark: Dictionary) -> void:
	if temp_mark.has(system_name):
		push_error("Circular dependency detected: %s" % system_name)
		return
	
	if visited.has(system_name):
		return
	
	temp_mark[system_name] = true
	
	# 先访问依赖
	var deps = _dependencies.get(system_name, []) as Array[String]
	for dep in deps:
		if _systems.has(dep):
			_visit_system(dep, visited, temp_mark)
	
	temp_mark.erase(system_name)
	visited[system_name] = true
	_init_order.append(system_name)

## 获取系统状态报告
func get_status_report() -> Dictionary:
	var report = {
		"initialized": _initialized,
		"system_count": _systems.size(),
		"systems": {}
	}
	
	for system_name in _systems.keys():
		var system = _systems[system_name] as ISystem
		report.systems[system_name] = system.get_status()
	
	return report
