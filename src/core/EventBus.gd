## EventBus
## 全局事件总线
## 用于解耦系统间的通信，提供类型安全的事件系统

class_name EventBus
extends Node

# 预定义的事件类型
enum EventType {
	# 游戏状态事件
	GAME_STARTED,
	GAME_PAUSED,
	GAME_RESUMED,
	GAME_OVER,
	LEVEL_STARTED,
	LEVEL_COMPLETED,
	
	# 玩家事件
	PLAYER_MOVED,
	PLAYER_INTERACTED,
	PLAYER_DAMAGED,
	PLAYER_HEALED,
	
	# 解谜事件
	PUZZLE_STARTED,
	PUZZLE_SOLVED,
	PUZZLE_FAILED,
	HINT_REQUESTED,
	
	# UI事件
	UI_OPENED,
	UI_CLOSED,
	DIALOG_STARTED,
	DIALOG_ENDED,
	
	# 音频事件
	MUSIC_CHANGED,
	SFX_PLAYED,
	AUDIO_MUTED,
	
	# 系统事件
	SETTINGS_CHANGED,
	SAVE_COMPLETED,
	LOAD_COMPLETED,
	ACHIEVEMENT_UNLOCKED
}

# 事件监听器存储
# 格式: { event_type: [Callable, Callable, ...] }
var _listeners: Dictionary = {}

# 一次性监听器
var _one_shot_listeners: Dictionary = {}

# 事件队列（用于延迟处理）
var _event_queue: Array[Dictionary] = []
var _processing_queue: bool = false

# 调试模式
var debug_mode: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("EventBus initialized")

func _process(_delta):
	# 处理事件队列
	if not _event_queue.is_empty() and not _processing_queue:
		_process_event_queue()

## 订阅事件
func subscribe(event_type: EventType, callback: Callable) -> void:
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	
	# 检查是否已订阅
	if not _listeners[event_type].has(callback):
		_listeners[event_type].append(callback)
		
		if debug_mode:
			print("EventBus: Subscribed to %s" % _get_event_name(event_type))

## 订阅事件（一次性）
func subscribe_once(event_type: EventType, callback: Callable) -> void:
	if not _one_shot_listeners.has(event_type):
		_one_shot_listeners[event_type] = []
	
	if not _one_shot_listeners[event_type].has(callback):
		_one_shot_listeners[event_type].append(callback)

## 取消订阅
func unsubscribe(event_type: EventType, callback: Callable) -> void:
	if _listeners.has(event_type):
		_listeners[event_type].erase(callback)
		
		if debug_mode:
			print("EventBus: Unsubscribed from %s" % _get_event_name(event_type))

## 发布事件（立即执行）
func emit(event_type: EventType, data: Dictionary = {}) -> void:
	if debug_mode:
		print("EventBus: Emitting %s" % _get_event_name(event_type))
	
	# 执行普通监听器
	if _listeners.has(event_type):
		for callback in _listeners[event_type]:
			if callback.is_valid():
				callback.call(data)
	
	# 执行一次性监听器
	if _one_shot_listeners.has(event_type):
		for callback in _one_shot_listeners[event_type]:
			if callback.is_valid():
				callback.call(data)
		_one_shot_listeners.erase(event_type)

## 发布事件（延迟执行，下一帧处理）
func emit_deferred(event_type: EventType, data: Dictionary = {}) -> void:
	_event_queue.append({
		"type": event_type,
		"data": data
	})

## 清空所有监听器
func clear_all_listeners() -> void:
	_listeners.clear()
	_one_shot_listeners.clear()
	_event_queue.clear()
	print("EventBus: All listeners cleared")

## 清空特定事件的所有监听器
func clear_event_listeners(event_type: EventType) -> void:
	if _listeners.has(event_type):
		_listeners.erase(event_type)
	if _one_shot_listeners.has(event_type):
		_one_shot_listeners.erase(event_type)

## 获取事件的监听器数量
func get_listener_count(event_type: EventType) -> int:
	var count = 0
	if _listeners.has(event_type):
		count += _listeners[event_type].size()
	if _one_shot_listeners.has(event_type):
		count += _one_shot_listeners[event_type].size()
	return count

## 检查是否有监听器
func has_listeners(event_type: EventType) -> bool:
	return get_listener_count(event_type) > 0

## 设置调试模式
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	print("EventBus: Debug mode %s" % ("enabled" if enabled else "disabled"))

## 私有：处理事件队列
func _process_event_queue() -> void:
	_processing_queue = true
	
	while not _event_queue.is_empty():
		var event = _event_queue.pop_front()
		emit(event.type, event.data)
	
	_processing_queue = false

## 私有：获取事件名称
func _get_event_name(event_type: EventType) -> String:
	match event_type:
		EventType.GAME_STARTED: return "GAME_STARTED"
		EventType.GAME_PAUSED: return "GAME_PAUSED"
		EventType.GAME_RESUMED: return "GAME_RESUMED"
		EventType.GAME_OVER: return "GAME_OVER"
		EventType.LEVEL_STARTED: return "LEVEL_STARTED"
		EventType.LEVEL_COMPLETED: return "LEVEL_COMPLETED"
		EventType.PLAYER_MOVED: return "PLAYER_MOVED"
		EventType.PLAYER_INTERACTED: return "PLAYER_INTERACTED"
		EventType.PLAYER_DAMAGED: return "PLAYER_DAMAGED"
		EventType.PLAYER_HEALED: return "PLAYER_HEALED"
		EventType.PUZZLE_STARTED: return "PUZZLE_STARTED"
		EventType.PUZZLE_SOLVED: return "PUZZLE_SOLVED"
		EventType.PUZZLE_FAILED: return "PUZZLE_FAILED"
		EventType.HINT_REQUESTED: return "HINT_REQUESTED"
		EventType.UI_OPENED: return "UI_OPENED"
		EventType.UI_CLOSED: return "UI_CLOSED"
		EventType.DIALOG_STARTED: return "DIALOG_STARTED"
		EventType.DIALOG_ENDED: return "DIALOG_ENDED"
		EventType.MUSIC_CHANGED: return "MUSIC_CHANGED"
		EventType.SFX_PLAYED: return "SFX_PLAYED"
		EventType.AUDIO_MUTED: return "AUDIO_MUTED"
		EventType.SETTINGS_CHANGED: return "SETTINGS_CHANGED"
		EventType.SAVE_COMPLETED: return "SAVE_COMPLETED"
		EventType.LOAD_COMPLETED: return "LOAD_COMPLETED"
		EventType.ACHIEVEMENT_UNLOCKED: return "ACHIEVEMENT_UNLOCKED"
		_: return "UNKNOWN"
