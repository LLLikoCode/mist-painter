## EventBus (Refactored)
## 全局事件总线 - 重构版
## 提供类型安全、高性能的发布-订阅事件系统

class_name EventBus
extends RefCounted

## 单例实例
static var instance: EventBus = null

## 获取单例
static func get_instance() -> EventBus:
	if instance == null:
		instance = EventBus.new()
	return instance

# ============================================
# 事件类型定义
# ============================================

enum EventType {
	# 游戏生命周期事件
	GAME_STARTED,
	GAME_PAUSED,
	GAME_RESUMED,
	GAME_OVER,
	GAME_QUIT,
	
	# 关卡事件
	LEVEL_STARTED,
	LEVEL_COMPLETED,
	LEVEL_FAILED,
	LEVEL_RESTARTED,
	
	# 玩家事件
	PLAYER_MOVED,
	PLAYER_INTERACTED,
	PLAYER_DAMAGED,
	PLAYER_HEALED,
	PLAYER_SPAWNED,
	PLAYER_DESPAWNED,
	
	# 迷雾系统事件
	MIST_PAINT_STARTED,
	MIST_PAINT_ENDED,
	MIST_PAINT_MOVED,
	MIST_CLEARED,
	MIST_COVERAGE_CHANGED,
	
	# 谜题事件
	PUZZLE_STARTED,
	PUZZLE_SOLVED,
	PUZZLE_FAILED,
	PUZZLE_RESET,
	HINT_REQUESTED,
	HINT_SHOWN,
	
	# UI事件
	UI_OPENED,
	UI_CLOSED,
	UI_FOCUSED,
	UI_UNFOCUSED,
	DIALOG_STARTED,
	DIALOG_ENDED,
	MENU_OPENED,
	MENU_CLOSED,
	
	# 音频事件
	MUSIC_STARTED,
	MUSIC_STOPPED,
	MUSIC_CHANGED,
	SFX_PLAYED,
	AUDIO_MUTED,
	AUDIO_UNMUTED,
	
	# 存档事件
	SAVE_STARTED,
	SAVE_COMPLETED,
	SAVE_FAILED,
	LOAD_STARTED,
	LOAD_COMPLETED,
	LOAD_FAILED,
	
	# 成就事件
	ACHIEVEMENT_UNLOCKED,
	ACHIEVEMENT_PROGRESS,
	
	# 系统事件
	SETTINGS_CHANGED,
	CONFIG_SAVED,
	CONFIG_LOADED,
	
	# 实体事件
	ENTITY_CREATED,
	ENTITY_DESTROYED,
	ENTITY_UPDATED,
	
	# 自定义事件（用于扩展）
	CUSTOM_1,
	CUSTOM_2,
	CUSTOM_3,
	CUSTOM_4,
	CUSTOM_5
}

# ============================================
# 数据结构
# ============================================

## 事件监听器
class EventListener:
	extends RefCounted
	
	var callback: Callable
	var priority: int
	var once: bool
	
	func _init(cb: Callable, prio: int = 0, one_shot: bool = false):
		callback = cb
		priority = prio
		once = one_shot

## 事件数据
class EventData:
	extends RefCounted
	
	var type: EventType
	var data: Dictionary
	var timestamp: int
	var sender: Object
	
	func _init(evt_type: EventType, evt_data: Dictionary = {}, evt_sender: Object = null):
		type = evt_type
		data = evt_data
		timestamp = Time.get_ticks_msec()
		sender = evt_sender

# ============================================
# 成员变量
# ============================================

## 监听器存储: { EventType: [EventListener, ...] }
var _listeners: Dictionary = {}

## 事件队列（用于延迟处理）
var _event_queue: Array[EventData] = []

## 是否正在处理队列
var _processing_queue: bool = false

## 调试模式
var debug_mode: bool = false

## 事件统计
var _event_stats: Dictionary = {}

## 最大队列大小（防止内存溢出）
const MAX_QUEUE_SIZE: int = 1000

## 每帧最大处理事件数
var max_events_per_frame: int = 100

# ============================================
# 生命周期
# ============================================

func _init():
	print("EventBus initialized")

# ============================================
# 订阅方法
# ============================================

## 订阅事件
func subscribe(event_type: EventType, callback: Callable, priority: int = 0) -> int:
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	
	var listener = EventListener.new(callback, priority, false)
	var listeners = _listeners[event_type] as Array
	
	# 按优先级插入
	var insert_idx = listeners.size()
	for i in range(listeners.size()):
		var existing = listeners[i] as EventListener
		if existing.priority > priority:
			insert_idx = i
			break
	
	listeners.insert(insert_idx, listener)
	
	if debug_mode:
		print("EventBus: Subscribed to %s (priority: %d)" % [get_event_name(event_type), priority])
	
	return insert_idx

## 订阅事件（一次性）
func subscribe_once(event_type: EventType, callback: Callable, priority: int = 0) -> int:
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	
	var listener = EventListener.new(callback, priority, true)
	var listeners = _listeners[event_type] as Array
	listeners.append(listener)
	
	if debug_mode:
		print("EventBus: Subscribed once to %s" % get_event_name(event_type))
	
	return listeners.size() - 1

## 取消订阅
func unsubscribe(event_type: EventType, callback: Callable) -> bool:
	if not _listeners.has(event_type):
		return false
	
	var listeners = _listeners[event_type] as Array
	for i in range(listeners.size() - 1, -1, -1):
		var listener = listeners[i] as EventListener
		if listener.callback == callback:
			listeners.remove_at(i)
			if debug_mode:
				print("EventBus: Unsubscribed from %s" % get_event_name(event_type))
			return true
	
	return false

## 取消订阅（通过ID）
func unsubscribe_by_id(event_type: EventType, id: int) -> bool:
	if not _listeners.has(event_type):
		return false
	
	var listeners = _listeners[event_type] as Array
	if id >= 0 and id < listeners.size():
		listeners.remove_at(id)
		return true
	return false

# ============================================
# 发布方法
# ============================================

## 发布事件（立即执行）
func emit(event_type: EventType, data: Dictionary = {}, sender: Object = null) -> void:
	_update_stats(event_type)
	
	if debug_mode:
		print("EventBus: Emitting %s" % get_event_name(event_type))
	
	if not _listeners.has(event_type):
		return
	
	var listeners = _listeners[event_type] as Array
	var to_remove: Array[int] = []
	
	for i in range(listeners.size()):
		var listener = listeners[i] as EventListener
		
		# 执行回调
		if listener.callback.is_valid():
			listener.callback.call(data)
		
		# 标记一次性监听器
		if listener.once:
			to_remove.append(i)
	
	# 移除一次性监听器（从后往前移除）
	for i in range(to_remove.size() - 1, -1, -1):
		listeners.remove_at(to_remove[i])

## 发布事件（延迟执行，下一帧处理）
func emit_deferred(event_type: EventType, data: Dictionary = {}, sender: Object = null) -> void:
	if _event_queue.size() >= MAX_QUEUE_SIZE:
		push_warning("EventBus: Event queue overflow, dropping oldest event")
		_event_queue.pop_front()
	
	var event_data = EventData.new(event_type, data, sender)
	_event_queue.append(event_data)

## 批量发布事件
func emit_batch(events: Array[Dictionary]) -> void:
	for event in events:
		if event.has("type"):
			var data = event.get("data", {})
			var sender = event.get("sender", null)
			emit(event.type, data, sender)

# ============================================
# 队列处理
# ============================================

## 处理事件队列（应在主循环中调用）
func process_queue() -> void:
	if _processing_queue or _event_queue.is_empty():
		return
	
	_processing_queue = true
	
	var processed = 0
	while not _event_queue.is_empty() and processed < max_events_per_frame:
		var event = _event_queue.pop_front() as EventData
		emit(event.type, event.data, event.sender)
		processed += 1
	
	_processing_queue = false

# ============================================
# 管理方法
# ============================================

## 清空所有监听器
func clear_all_listeners() -> void:
	_listeners.clear()
	_event_queue.clear()
	if debug_mode:
		print("EventBus: All listeners cleared")

## 清空特定事件的所有监听器
func clear_event_listeners(event_type: EventType) -> void:
	if _listeners.has(event_type):
		_listeners.erase(event_type)

## 获取事件的监听器数量
func get_listener_count(event_type: EventType) -> int:
	if _listeners.has(event_type):
		return (_listeners[event_type] as Array).size()
	return 0

## 检查是否有监听器
func has_listeners(event_type: EventType) -> bool:
	return get_listener_count(event_type) > 0

## 设置调试模式
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	print("EventBus: Debug mode %s" % ("enabled" if enabled else "disabled"))

## 获取事件名称
func get_event_name(event_type: EventType) -> String:
	match event_type:
		EventType.GAME_STARTED: