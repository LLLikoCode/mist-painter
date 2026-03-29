## GameController
## 游戏主控制器
## 管理游戏的核心逻辑和流程

class_name GameController
extends Node2D

const _GameStateManagerScript := preload("res://src/core/GameStateManager.gd")

# ============================================
# 游戏状态
# ============================================

enum State {
	INITIALIZING,
	PLAYING,
	PAUSED,
	ENDING
}

var current_state: State = State.INITIALIZING

# ============================================
# 节点引用
# ============================================

@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UILayer
@onready var level_container: Node2D = $LevelContainer
@onready var player: PlayerController = $Player
@onready var mist_system: Node = $MistPaintingSystem
@onready var puzzles_container: Node2D = $Puzzles

# ============================================
# HUD引用
# ============================================

var hud: HUD = null

# ============================================
# 关卡数据
# ============================================

var current_level_scene: Node = null
var level_puzzles: Array[PuzzleController] = []

# ============================================
# 生命周期
# ============================================

func _ready():
	print("GameController initializing...")

	# 等待一帧确保所有子节点就绪
	await get_tree().process_frame

	# 初始化HUD
	_init_hud()

	# 注册系统到AutoLoad
	_register_systems()

	# 初始化游戏
	_initialize_game()

	# 订阅事件
	_subscribe_events()

	print("GameController initialized")

func _process(delta):
	match current_state:
		State.PLAYING:
			_process_playing(delta)
		State.PAUSED:
			_process_paused(delta)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_pause"):
		toggle_pause()

# ============================================
# HUD初始化
# ============================================

## 初始化HUD
func _init_hud() -> void:
	# 查找或创建HUD
	hud = get_node_or_null("UILayer/HUD")

	if hud == null:
		# 创建HUD
		hud = HUD.new()
		hud.name = "HUD"
		var ui_layer_node = get_node_or_null("UILayer")
		if ui_layer_node:
			ui_layer_node.add_child(hud)
		else:
			add_child(hud)

	# 连接暂停按钮
	if hud:
		hud.pause_pressed.connect(_on_pause_button_pressed)

	print("GameController: HUD initialized")

## 连接玩家资源到HUD
func _connect_player_stats_to_hud() -> void:
	if player and hud:
		var stats = player.get_stats()
		if stats:
			hud.connect_to_stats(stats)

			# 初始化显示
			hud.update_hp(stats.current_hp, stats.max_hp)
			hud.update_sp(stats.current_sp, stats.max_sp)
			hud.update_ink(stats.current_ink, stats.max_ink)

# ============================================
# 系统注册
# ============================================

## 注册系统到AutoLoad
func _register_systems() -> void:
	if mist_system:
		AutoLoad.register_mist_painting_system(mist_system)

	if player:
		AutoLoad.register_player_controller(player)

		# 连接玩家和迷雾系统
		if mist_system:
			player.paint_started.connect(mist_system.start_drawing)
			player.paint_ended.connect(mist_system.end_drawing)
			player.paint_moved.connect(mist_system.continue_drawing)

		# 连接玩家资源到HUD
		_connect_player_stats_to_hud()

		# 设置相机跟随玩家
		if camera:
			camera.position_smoothing_enabled = true
			camera.position_smoothing_speed = 5.0

	print("GameController: Systems registered")

# ============================================
# 游戏初始化
# ============================================

## 初始化游戏
func _initialize_game() -> void:
	# 获取当前关卡
	var current_level = 0
	if AutoLoad.game_state and AutoLoad.game_state.has_method("get_current_level"):
		current_level = AutoLoad.game_state.get_current_level()

	# 加载关卡
	await _load_level(current_level)

	# 初始化迷雾系统
	_initialize_mist_system()

	# 初始化谜题
	_initialize_puzzles()

	# 更新UI
	_update_ui()

	# 设置状态
	current_state = State.PLAYING
	var gs = AutoLoad.game_state
	if gs and gs.has_method("change_state"):
		gs.change_state(_GameStateManagerScript.GameState.PLAYING)

	# 播放BGM
	if AutoLoad.audio_manager:
		AutoLoad.audio_manager.play_bgm_path("res://assets/audio/bgm/game.ogg")

	# 发送事件
	if AutoLoad.event_bus:
		AutoLoad.event_bus.emit(EventBus.EventType.GAME_STARTED)
		AutoLoad.event_bus.emit(EventBus.EventType.LEVEL_STARTED, {"level": current_level})

## 加载关卡
func _load_level(level_id: int) -> void:
	print("Loading level: " + str(level_id))

	# 清理旧关卡
	if current_level_scene:
		current_level_scene.queue_free()
		current_level_scene = null

	level_puzzles.clear()

	# 加载新关卡场景
	var level_path = "res://scenes/Level_%02d.tscn" % (level_id + 1)

	if ResourceLoader.exists(level_path):
		var level_scene = load(level_path)
		if level_scene:
			current_level_scene = level_scene.instantiate()
			level_container.add_child(current_level_scene)

			# 设置玩家位置
			var spawn_point = current_level_scene.get_node_or_null("SpawnPoint")
			if spawn_point and player:
				player.global_position = spawn_point.global_position
				print("Player spawned at: ", player.global_position)

			# 收集关卡中的谜题
			_collect_level_puzzles()

			print("Level loaded: " + level_path)
	else:
		push_warning("Level not found: " + level_path)

## 收集关卡中的谜题
func _collect_level_puzzles() -> void:
	if current_level_scene == null:
		return

	var puzzles_node = current_level_scene.get_node_or_null("Puzzles")
	if puzzles_node:
		for child in puzzles_node.get_children():
			if child is PuzzleController:
				level_puzzles.append(child)
				# 连接谜题解决事件
				child.puzzle_solved.connect(_on_level_puzzle_solved)

	print("Collected " + str(level_puzzles.size()) + " puzzles")

## 初始化迷雾系统
func _initialize_mist_system() -> void:
	if mist_system:
		mist_system.reset_mist()
		mist_system.mist_coverage_changed.connect(_on_mist_coverage_changed)

## 初始化谜题
func _initialize_puzzles() -> void:
	for puzzle in level_puzzles:
		puzzle.unlock()

# ============================================
# 事件处理
# ============================================

func _on_mist_coverage_changed(coverage: float) -> void:
	# 更新HUD显示迷雾覆盖率
	if hud:
		hud.update_mist_coverage(coverage * 100)

func _on_level_puzzle_solved() -> void:
	# 检查是否所有谜题都已解决
	var all_solved = true
	for puzzle in level_puzzles:
		if not puzzle.is_solved():
			all_solved = false
			break

	if all_solved:
		print("All puzzles solved!")
		# 可以在这里触发关卡完成逻辑

## 暂停/继续游戏
func toggle_pause() -> void:
	if current_state == State.PLAYING:
		pause_game()
	elif current_state == State.PAUSED:
		resume_game()

## 暂停游戏
func pause_game() -> void:
	current_state = State.PAUSED
	get_tree().paused = true
	var gs = AutoLoad.game_state
	if gs and gs.has_method("change_state"):
		gs.change_state(_GameStateManagerScript.GameState.PAUSED)

	# 显示暂停菜单
	_show_pause_menu()

	if AutoLoad.event_bus:
		AutoLoad.event_bus.emit(EventBus.EventType.GAME_PAUSED)
	print("Game paused")

## 继续游戏
func resume_game() -> void:
	current_state = State.PLAYING
	get_tree().paused = false
	var gs = AutoLoad.game_state
	if gs and gs.has_method("change_state"):
		gs.change_state(_GameStateManagerScript.GameState.PLAYING)

	# 隐藏暂停菜单
	_hide_pause_menu()

	if AutoLoad.event_bus:
		AutoLoad.event_bus.emit(EventBus.EventType.GAME_RESUMED)
	print("Game resumed")

## 结束关卡
func end_level(success: bool) -> void:
	current_state = State.ENDING

	if success:
		var gs = AutoLoad.game_state
		if gs and gs.has_method("change_state"):
			gs.change_state(_GameStateManagerScript.GameState.LEVEL_COMPLETE)
		if AutoLoad.event_bus:
			var current_level = 0
			if AutoLoad.game_state and AutoLoad.game_state.has_method("get_current_level"):
				current_level = AutoLoad.game_state.get_current_level()
			AutoLoad.event_bus.emit(EventBus.EventType.LEVEL_COMPLETED, {
				"level": current_level
			})

		# 解锁下一关
		if AutoLoad.game_state and AutoLoad.game_state.has_method("get_current_level"):
			var next_level = AutoLoad.game_state.get_current_level() + 1
			if AutoLoad.game_state.has_method("set_current_level"):
				AutoLoad.game_state.set_current_level(next_level)
	else:
		var gs = AutoLoad.game_state
		if gs and gs.has_method("change_state"):
			gs.change_state(_GameStateManagerScript.GameState.GAME_OVER)
		if AutoLoad.event_bus:
			AutoLoad.event_bus.emit(EventBus.EventType.GAME_OVER)

## 重新开始当前关卡
func restart_level() -> void:
	get_tree().paused = false
	if AutoLoad.scene_manager:
		AutoLoad.scene_manager.reload_current_scene()

## 返回主菜单
func return_to_main_menu() -> void:
	get_tree().paused = false
	if AutoLoad.scene_manager:
		AutoLoad.scene_manager.change_scene_by_name("main_menu")

## 更新UI
func _update_ui() -> void:
	if hud:
		var current_level = 0
		if AutoLoad.game_state and AutoLoad.game_state.has_method("get_current_level"):
			current_level = AutoLoad.game_state.get_current_level()
		hud.update_level(current_level + 1)

## 显示暂停菜单
func _show_pause_menu() -> void:
	var pause_menu = preload("res://scenes/PauseMenu.tscn").instantiate()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)

## 隐藏暂停菜单
func _hide_pause_menu() -> void:
	var pause_menu = get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.queue_free()

## 订阅事件
func _subscribe_events() -> void:
	if AutoLoad.event_bus:
		AutoLoad.event_bus.subscribe(EventBus.EventType.PUZZLE_SOLVED, _on_puzzle_solved)

## 处理游戏中的更新
func _process_playing(delta: float) -> void:
	# Camera2D 使用内置平滑跟随，直接设置目标位置
	if camera and player:
		camera.global_position = player.global_position

## 处理暂停时的更新
func _process_paused(delta: float) -> void:
	pass

## 事件回调：谜题解决
func _on_puzzle_solved(data: Dictionary) -> void:
	print("Puzzle solved!")
	# 检查是否所有谜题都解决了
	# 如果是，结束关卡

## UI回调：暂停按钮按下
func _on_pause_button_pressed() -> void:
	toggle_pause()