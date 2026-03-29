## PuzzleController
## 谜题控制器
## 负责管理谜题的状态、逻辑、验证和与玩家的交互

class_name PuzzleController
extends Node2D

# ============================================
# 枚举定义
# ============================================

## 谜题类型
enum PuzzleType {
	SWITCH,         # 开关谜题
	SEQUENCE,       # 序列谜题
	PATH_DRAWING,   # 路径绘制
	SYMBOL_MATCH,   # 符号匹配
	LIGHT_MIRROR,   # 光线反射
	PRESSURE_PLATE, # 压力板
	COMBINATION     # 组合谜题
}

## 谜题状态
enum PuzzleState {
	LOCKED,         # 锁定
	ACTIVE,         # 激活中
	SOLVED,         # 已解决
	FAILED,         # 失败
	UNLOCKED        # 已解锁（待激活）
}

# ============================================
# 导出变量
# ============================================

@export_group("Basic Settings")
@export var puzzle_id: String = ""
@export var puzzle_name: String = "未命名谜题"
@export var puzzle_type: PuzzleType = PuzzleType.SWITCH
@export var difficulty: int = 1

@export_group("Interaction")
@export var requires_mist_clearance: bool = false
@export var mist_clearance_radius: float = 100.0
@export var time_limit: float = 0.0
@export var max_attempts: int = 0

@export_group("Visual")
@export var hint_text: String = ""
@export var show_hint_on_fail: bool = true
@export var glow_when_active: bool = true

# ============================================
# 节点引用
# ============================================

@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null
@onready var visual_node: Node2D = $Visual if has_node("Visual") else null
@onready var hint_label: Label = $HintLabel if has_node("HintLabel") else null

# ============================================
# 状态变量
# ============================================

var current_state: PuzzleState = PuzzleState.LOCKED
var attempt_count: int = 0
var puzzle_timer: float = 0.0
var is_timing: bool = false
var puzzle_data: Dictionary = {}
var solution: Dictionary = {}
var current_input: Dictionary = {}
var connected_puzzles: Array[PuzzleController] = []
var required_puzzles: Array[PuzzleController] = []

# ============================================
# 信号
# ============================================

signal puzzle_activated
signal puzzle_solved
signal puzzle_failed
signal puzzle_reset
signal puzzle_unlocked
signal hint_requested
signal state_changed(new_state: PuzzleState, old_state: PuzzleState)
signal progress_updated(progress: float)

# ============================================
# 生命周期
# ============================================

func _ready():
	if interaction_area:
		interaction_area.collision_layer = 4  # Interactables 层
		interaction_area.collision_mask = 1   # Player 层
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	else:
		push_warning("PuzzleController '%s' has no InteractionArea node" % puzzle_name)

	_initialize_puzzle()
	print("PuzzleController initialized: %s" % puzzle_id)

func _process(delta: float):
	if is_timing and current_state == PuzzleState.ACTIVE:
		puzzle_timer += delta
		if time_limit > 0 and puzzle_timer >= time_limit:
			_on_time_expired()

# ============================================
# 初始化
# ============================================

func _initialize_puzzle() -> void:
	if puzzle_id == "":
		puzzle_id = "puzzle_%d_%d" % [get_instance_id(), Time.get_ticks_msec()]
	
	match puzzle_type:
		PuzzleType.SWITCH:
			puzzle_data = {"switches": [], "target_states": []}
		PuzzleType.SEQUENCE:
			puzzle_data = {"sequence": [], "player_sequence": [], "max_length": 5}
		PuzzleType.PATH_DRAWING:
			puzzle_data = {"start_point": Vector2.ZERO, "end_point": Vector2.ZERO, "waypoints": [], "tolerance": 30.0}
		PuzzleType.SYMBOL_MATCH:
			puzzle_data = {"symbols": [], "matches_required": 3}
		PuzzleType.LIGHT_MIRROR:
			puzzle_data = {"mirrors": [], "light_source": Vector2.ZERO, "target": Vector2.ZERO}
		PuzzleType.PRESSURE_PLATE:
			puzzle_data = {"plates": [], "activation_order": [], "current_order": []}
		PuzzleType.COMBINATION:
			puzzle_data = {"sub_puzzles": [], "solved_count": 0}
	
	_check_dependencies()

# ============================================
# 状态管理
# ============================================

func set_state(new_state: PuzzleState) -> void:
	if current_state == new_state:
		return
	
	var old_state = current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)
	
	match new_state:
		PuzzleState.ACTIVE:
			is_timing = true
		PuzzleState.SOLVED:
			is_timing = false
			_notify_connected_puzzles()
			AutoLoad.event_bus.emit(EventBus.EventType.PUZZLE_SOLVED, {"puzzle_id": puzzle_id})
		PuzzleState.FAILED:
			is_timing = false
			if show_hint_on_fail and hint_text != "":
				_show_hint()
			AutoLoad.event_bus.emit(EventBus.EventType.PUZZLE_FAILED, {"puzzle_id": puzzle_id})

func unlock() -> void:
	if current_state == PuzzleState.LOCKED:
		set_state(PuzzleState.UNLOCKED)
		puzzle_unlocked.emit()

func activate() -> void:
	if current_state == PuzzleState.LOCKED:
		unlock()
	if current_state == PuzzleState.UNLOCKED or current_state == PuzzleState.FAILED:
		set_state(PuzzleState.ACTIVE)
		puzzle_activated.emit()

## 解决谜题
func solve_puzzle() -> void:
	if current_state == PuzzleState.SOLVED:
		return

	set_state(PuzzleState.SOLVED)
	puzzle_solved.emit()
	print("Puzzle solved: %s" % puzzle_name)

	# 通知连接的谜题
	_notify_connected_puzzles()

	# 更新视觉
	_update_visual_for_solved()

## 更新视觉效果（解决状态）
func _update_visual_for_solved() -> void:
	if visual_node:
		# 改变颜色表示解决
		if visual_node is ColorRect:
			visual_node.color = Color(0.2, 0.8, 0.4, 1)

	if hint_label:
		hint_label.text = "完成!"
		hint_label.visible = false

func reset_puzzle() -> void:
	attempt_count = 0
	puzzle_timer = 0.0
	is_timing = false
	current_input.clear()
	_reset_puzzle_data()
	set_state(PuzzleState.UNLOCKED)
	puzzle_reset.emit()

func _reset_puzzle_data() -> void:
	match puzzle_type:
		PuzzleType.SEQUENCE:
			puzzle_data["player_sequence"] = []
		PuzzleType.PRESSURE_PLATE:
			puzzle_data["current_order"] = []
		PuzzleType.PATH_DRAWING:
			puzzle_data["drawn_path"] = []

# ============================================
# 谜题逻辑
# ============================================

func check_solution() -> bool:
	var is_correct = false
	
	match puzzle_type:
		PuzzleType.SWITCH:
			is_correct = _check_switch_solution()
		PuzzleType.SEQUENCE:
			is_correct = _check_sequence_solution()
		PuzzleType.PATH_DRAWING:
			is_correct = _check_path_solution()
		PuzzleType.PRESSURE_PLATE:
			is_correct = _check_pressure_solution()
		PuzzleType.COMBINATION:
			is_correct = _check_combination_solution()
		_:
			is_correct = true
	
	if is_correct:
		set_state(PuzzleState.SOLVED)
		puzzle_solved.emit()
	else:
		attempt_count += 1
		if max_attempts > 0 and attempt_count >= max_attempts:
			set_state(PuzzleState.FAILED)
			puzzle_failed.emit()
		else:
			current_input.clear()
			_reset_puzzle_data()
			progress_updated.emit(0.0)
	
	return is_correct

func _check_switch_solution() -> bool:
	var switches = puzzle_data.get("switches", [])
	var target = puzzle_data.get("target_states", [])
	for i in range(min(switches.size(), target.size())):
		if switches[i] != target[i]:
			return false
	return true

func _check_sequence_solution() -> bool:
	return puzzle_data.get("player_sequence", []) == puzzle_data.get("sequence", [])

func _check_path_solution() -> bool:
	var waypoints = puzzle_data.get("waypoints", [])
	var drawn_path = puzzle_data.get("drawn_path", [])
	var tolerance = puzzle_data.get("tolerance", 30.0)
	
	if drawn_path.size() < waypoints.size():
		return false
	
	for i in range(waypoints.size()):
		var closest_dist = INF
		for point in drawn_path:
			closest_dist = min(closest_dist, point.distance_to(waypoints[i]))
		if closest_dist > tolerance:
			return false
	return true

func _check_pressure_solution() -> bool:
	return puzzle_data.get("current_order", []) == puzzle_data.get("activation_order", [])

func _check_combination_solution() -> bool:
	var sub_puzzles = puzzle_data.get("sub_puzzles", [])
	var solved = puzzle_data.get("solved_count", 0)
	return solved >= sub_puzzles.size()

func _on_time_expired() -> void:
	set_state(PuzzleState.FAILED)
	puzzle_failed.emit()

# ============================================
# 输入处理
# ============================================

func receive_input(input_data: Dictionary) -> void:
	if current_state != PuzzleState.ACTIVE:
		return
	
	current_input = input_data
	
	match puzzle_type:
		PuzzleType.SWITCH:
			_handle_switch_input(input_data)
		PuzzleType.SEQUENCE:
			_handle_sequence_input(input_data)
		PuzzleType.PATH_DRAWING:
			_handle_path_input(input_data)
		PuzzleType.PRESSURE_PLATE:
			_handle_pressure_input(input_data)
	
	_update_progress()

func _handle_switch_input(input_data: Dictionary) -> void:
	var switch_index = input_data.get("switch_index", 0)
	var switches = puzzle_data.get("switches", [])
	if switch_index < switches.size():
		switches[switch_index] = not switches[switch_index]
		check_solution()

func _handle_sequence_input(input_data: Dictionary) -> void:
	var value = input_data.get("value", 0)
	var player_seq: Array = puzzle_data.get("player_sequence", [])
	var target_seq: Array = puzzle_data.get("sequence", [])

	player_seq.append(value)
	puzzle_data["player_sequence"] = player_seq  # 确保更新回puzzle_data

	if player_seq.size() >= target_seq.size():
		check_solution()
	else:
		for i in range(player_seq.size()):
			if player_seq[i] != target_seq[i]:
				attempt_count += 1
				current_input.clear()
				_reset_puzzle_data()
				return

func _handle_path_input(input_data: Dictionary) -> void:
	var point = input_data.get("point", Vector2.ZERO)
	var drawn_path: Array = puzzle_data.get("drawn_path", [])
	drawn_path.append(point)
	puzzle_data["drawn_path"] = drawn_path  # 确保更新回puzzle_data

func _handle_pressure_input(input_data: Dictionary) -> void:
	var plate_id = input_data.get("plate_id", "")
	var current_order: Array = puzzle_data.get("current_order", [])
	var target: Array = puzzle_data.get("activation_order", [])

	current_order.append(plate_id)
	puzzle_data["current_order"] = current_order  # 确保更新回puzzle_data

	if current_order.size() <= target.size():
		var index = current_order.size() - 1
		if current_order[index] != target[index]:
			attempt_count += 1
			current_input.clear()
			_reset_puzzle_data()
			return

	if current_order.size() >= target.size():
		check_solution()

func _update_progress() -> void:
	var progress = 0.0
	match puzzle_type:
		PuzzleType.SEQUENCE:
			var player_seq = puzzle_data.get("player_sequence", [])
			var target = puzzle_data.get("sequence", [])
			if target.size() > 0:
				progress = float(player_seq.size()) / target.size()
		PuzzleType.PRESSURE_PLATE:
			var current = puzzle_data.get("current_order", [])
			var target = puzzle_data.get("activation_order", [])
			if target.size() > 0:
				progress = float(current.size()) / target.size()
	progress_updated.emit(progress)

# ============================================
# 依赖和连接
# ============================================

func _check_dependencies() -> void:
	if required_puzzles.is_empty():
		unlock()
		return
	for puzzle in required_puzzles:
		if puzzle.current_state != PuzzleState.SOLVED:
			return
	unlock()

func add_required_puzzle(puzzle: PuzzleController) -> void:
	if puzzle not in required_puzzles:
		required_puzzles.append(puzzle)
		puzzle.puzzle_solved.connect(_check_dependencies)

func add_connected_puzzle(puzzle: PuzzleController) -> void:
	if puzzle not in connected_puzzles:
		connected_puzzles.append(puzzle)

func _notify_connected_puzzles() -> void:
	for puzzle in connected_puzzles:
		if puzzle.has_method("on_connected_puzzle_solved"):
			puzzle.on_connected_puzzle_solved(self)

func on_connected_puzzle_solved(_solved_puzzle: PuzzleController) -> void:
	pass

# ============================================
# 交互
# ============================================

func _on_player_entered(body: Node) -> void:
	if body is PlayerController:
		if current_state == PuzzleState.UNLOCKED or current_state == PuzzleState.ACTIVE:
			# 压力板类型自动解决
			if puzzle_type == PuzzleType.PRESSURE_PLATE:
				solve_puzzle()
		# 显示提示
		if hint_label and not hint_text.is_empty():
			hint_label.text = hint_text
			hint_label.visible = true

func _on_player_exited(body: Node) -> void:
	if body is PlayerController:
		# 隐藏提示
		if hint_label:
			hint_label.visible = false

func interact(player: Node) -> void:
	if current_state == PuzzleState.LOCKED:
		return
	if current_state == PuzzleState.UNLOCKED or current_state == PuzzleState.FAILED:
		activate()
		return
	if current_state == PuzzleState.ACTIVE:
		_handle_interaction(player)

func _handle_interaction(player: Node) -> void:
	pass

func can_interact() -> bool:
	return current_state != PuzzleState.LOCKED and current_state != PuzzleState.SOLVED

func show_interaction_hint() -> void:
	pass

func hide_interaction_hint() -> void:
	pass

# ============================================
# 视觉
# ============================================

func _show_hint() -> void:
	if hint_label:
		hint_label.text = hint_text
		hint_label.visible = true

# ============================================
# 公共方法
# ============================================

func get_current_state() -> PuzzleState:
	return current_state

func get_attempt_count() -> int:
	return attempt_count

func get_elapsed_time() -> float:
	return puzzle_timer

func is_solved() -> bool:
	return current_state == PuzzleState.SOLVED

func get_progress() -> float:
	match puzzle_type:
		PuzzleType.SEQUENCE:
			var player_seq = puzzle_data.get("player_sequence", [])
			var target = puzzle_data.get("sequence", [])
			if target.size() > 0:
				return float(player_seq.size()) / target.size()
	return 1.0 if is_solved() else 0.0

func export_state() -> Dictionary:
	return {
		"puzzle_id": puzzle_id,
		"state": current_state,
		"attempts": attempt_count,
		"time": puzzle_timer,
		"progress": get_progress()
	}

func import_state(data: Dictionary) -> void:
	attempt_count = data.get("attempts", 0)
	puzzle_timer = data.get("time", 0.0)
	set_state(data.get("state", PuzzleState.LOCKED))

func set_puzzle_data(data: Dictionary) -> void:
	puzzle_data = data

func get_puzzle_data() -> Dictionary:
	return puzzle_data
