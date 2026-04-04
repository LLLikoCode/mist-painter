## GameController
## 游戏主控制器
## 管理游戏的核心逻辑和流程

class_name GameController
extends Node2D

const _GameStateManagerScript := preload("res://src/core/GameStateManager.gd")
const _VisionSystemScript := preload("res://src/gameplay/VisionSystem.gd")
const _LightSystemScript := preload("res://src/gameplay/LightSystem.gd")
const _MazeRendererScript := preload("res://src/generation/MazeRenderer.gd")
const _MazeGeneratorScript := preload("res://src/generation/MazeGenerator.gd")
const _HUDScript := preload("res://src/ui/components/HUD.gd")
const _InventoryManagerScript := preload("res://src/inventory/InventoryManager.gd")
const _MapUIScript := preload("res://src/ui/components/MapUI.gd")
const _InventoryUIScript := preload("res://src/ui/components/InventoryUI.gd")
const _ItemDefinitionsScript := preload("res://src/inventory/ItemDefinitions.gd")

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
@onready var vision_system: Node2D = $VisionSystem

# ============================================
# HUD引用
# ============================================

var hud: Control = null

# ============================================
# 光源系统
# ============================================

var light_system: Node = null

# ============================================
# 迷宫生成器
# ============================================

var maze_generator: RefCounted = null
var maze_renderer: Node2D = null

# ============================================
# 关卡数据
# ============================================

var current_level_scene: Node = null
var level_puzzles: Array[PuzzleController] = []

# ============================================
# 背包与物品系统
# ============================================

var inventory: Node = null
var map_ui: Control = null
var inventory_ui: Control = null
var entrance_world_pos: Vector2 = Vector2(100, 100)  # 迷宫入口位置

# ============================================
# 生命周期
# ============================================

func _ready():
	print("GameController initializing...")

	# 等待一帧确保所有子节点就绪
	await get_tree().process_frame

	# 初始化背包系统
	_init_inventory()

	# 初始化HUD
	_init_hud()

	# 初始化视野系统
	_init_vision_system()

	# 初始化光源系统
	_init_light_system()

	# 初始化迷宫生成器
	_init_maze_generator()

	# 注册系统到AutoLoad
	_register_systems()

	# 订阅事件
	_subscribe_events()

	# 初始化游戏 (需要 await 因为是异步的)
	await _initialize_game()

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
	elif event.is_action_pressed("view_map"):
		_toggle_map()
	elif event.is_action_pressed("use_item"):
		_use_record_item()
	elif event.is_action_pressed("open_inventory"):
		_toggle_inventory()

# ============================================
# HUD初始化
# ============================================

## 初始化HUD
func _init_hud() -> void:
	# 查找或创建HUD
	var existing_hud = get_node_or_null("UILayer/HUD")

	if existing_hud == null:
		# 创建HUD
		existing_hud = _HUDScript.new()
		existing_hud.name = "HUD"
		var ui_layer_node = get_node_or_null("UILayer")
		if ui_layer_node:
			ui_layer_node.add_child(existing_hud)
		else:
			add_child(existing_hud)

	# 设置hud引用
	hud = existing_hud

	# 连接暂停按钮
	if hud:
		if hud.has_signal("pause_pressed"):
			hud.pause_pressed.connect(_on_pause_button_pressed)

	print("GameController: HUD initialized")

## 初始化视野系统
func _init_vision_system() -> void:
	# 查找或创建视野系统
	if vision_system == null:
		vision_system = get_node_or_null("VisionSystem")

	if vision_system == null:
		# 创建视野系统
		vision_system = _VisionSystemScript.new()
		vision_system.name = "VisionSystem"
		add_child(vision_system)

	print("GameController: VisionSystem initialized")

## 初始化光源系统
func _init_light_system() -> void:
	# 创建光源系统
	light_system = _LightSystemScript.new()
	light_system.name = "LightSystem"
	add_child(light_system)

	# 连接光源系统信号
	if light_system:
		light_system.vision_bonus_changed.connect(_on_light_vision_bonus_changed)
		light_system.light_changed.connect(_on_light_changed)
		light_system.light_time_changed.connect(_on_light_time_changed)
		light_system.low_light_warning.connect(_on_low_light_warning)

	print("GameController: LightSystem initialized")

## 初始化迷宫生成器
func _init_maze_generator() -> void:
	maze_generator = _MazeGeneratorScript.new()

	# 查找场景中已有的 MazeRenderer 节点
	maze_renderer = level_container.get_node_or_null("MazeRenderer")

	if maze_renderer == null:
		print("Creating new MazeRenderer...")
		maze_renderer = _MazeRendererScript.new()
		maze_renderer.name = "MazeRenderer"
		level_container.add_child(maze_renderer)
	else:
		print("Found existing MazeRenderer in scene")

	print("GameController: MazeGenerator initialized")

## 初始化背包系统
func _init_inventory() -> void:
	# 创建背包管理器
	inventory = _InventoryManagerScript.new()
	inventory.name = "InventoryManager"
	add_child(inventory)

	# 连接背包变化信号
	inventory.inventory_changed.connect(_on_inventory_changed)

	# 创建地图UI
	map_ui = _MapUIScript.create()
	map_ui.set_inventory(inventory)
	map_ui.map_closed.connect(_on_map_closed)
	ui_layer.add_child(map_ui)

	# 创建背包UI
	inventory_ui = _InventoryUIScript.create()
	inventory_ui.set_inventory(inventory)
	inventory_ui.inventory_closed.connect(_on_inventory_closed)
	inventory_ui.item_use_requested.connect(_on_item_use_requested)
	inventory_ui.open_map_requested.connect(_toggle_map)
	ui_layer.add_child(inventory_ui)

	# 给予初始物品
	_give_starting_items()

	print("GameController: Inventory initialized")

## 给予初始物品
func _give_starting_items() -> void:
	# 给玩家一些初始记录纸张
	inventory.add_item(_InventoryManagerScript.ItemType.MAP_RECORD, "地图纸张", 5)

	# 给玩家一个探险地图
	inventory.add_item(_InventoryManagerScript.ItemType.MAP, "探险地图", 1)

	# 给玩家一些食物
	inventory.add_item(_InventoryManagerScript.ItemType.FOOD, "面包", 3)

	# 给玩家一个撤离卷轴
	inventory.add_item(_InventoryManagerScript.ItemType.ESCAPE, "撤离卷轴", 1)

	print("Starting items given")

## 连接玩家资源到HUD
func _connect_player_stats_to_hud() -> void:
	if player and hud:
		var player_stats = player.get_stats()
		if player_stats and hud.has_method("connect_to_stats"):
			hud.connect_to_stats(player_stats)

			# 初始化显示
			if hud.has_method("update_hp"):
				hud.update_hp(player_stats.current_hp, player_stats.max_hp)
			if hud.has_method("update_sp"):
				hud.update_sp(player_stats.current_sp, player_stats.max_sp)
			if hud.has_method("update_ink"):
				hud.update_ink(player_stats.current_ink, player_stats.max_ink)
			if hud.has_method("update_stamina"):
				hud.update_stamina(player_stats.current_stamina, player_stats.max_stamina)
			if hud.has_method("update_fatigue_state"):
				hud.update_fatigue_state(player_stats.current_fatigue_state, player_stats.get_fatigue_state_name())

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

		# 连接玩家到视野系统
		if vision_system:
			vision_system.set_target_player(player)
			player.fatigue_state_changed.connect(_on_player_fatigue_changed)

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
	print("=== Loading level: " + str(level_id) + " ===")

	# 清理旧关卡
	if current_level_scene:
		current_level_scene.queue_free()
		current_level_scene = null

	# 清除旧迷宫
	if maze_renderer:
		maze_renderer.clear_maze()

	level_puzzles.clear()

	# 使用迷宫生成器生成关卡
	if maze_generator and maze_renderer:
		# 生成迷宫 (层级 = level_id + 1)
		var layer = level_id + 1
		var maze_data = maze_generator.generate(layer)

		print("Maze size: ", maze_data.get("width", 0), "x", maze_data.get("height", 0))
		print("Maze entrance: ", maze_data.get("entrance", Vector2i(-1, -1)))

		# 渲染迷宫
		maze_renderer.render_maze(maze_data)

		# 等待一帧让迷宫节点创建完成
		await get_tree().process_frame

		# 验证 MazeRenderer 的位置
		print("MazeRenderer global_position: ", maze_renderer.global_position)
		print("MazeRenderer position: ", maze_renderer.position)

		# 获取入口位置
		var entrance_pos = maze_renderer.get_entrance_world_position()
		print("Entrance world position: ", entrance_pos)

		# 保存入口位置用于撤离
		entrance_world_pos = entrance_pos

		# 验证迷宫渲染
		var maze_visual = maze_renderer.get_node_or_null("MazeVisual")
		if maze_visual:
			print("maze_visual found, children: ", maze_visual.get_children().size())
			if maze_visual.get_children().size() > 0:
				var first_cell = maze_visual.get_children()[0]
				print("First cell local position: ", first_cell.position)
				print("First cell global position: ", first_cell.global_position)
		else:
			print("ERROR: maze_visual not found!")

		# 设置玩家位置
		if player:
			player.global_position = entrance_pos
			print("Player global_position: ", player.global_position)

		# 设置相机位置
		if camera:
			camera.global_position = entrance_pos
			print("Camera global_position: ", camera.global_position)

		print("=== Maze generation complete ===")
	else:
		print("ERROR: maze_generator or maze_renderer is null!")
		print("maze_generator: ", maze_generator)
		print("maze_renderer: ", maze_renderer)
		# 迷宫生成失败时使用默认位置
		if player:
			player.global_position = Vector2(100, 100)
		if camera:
			camera.global_position = Vector2(100, 100)

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
	if hud and hud.has_method("update_mist_coverage"):
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
	if hud and hud.has_method("update_level"):
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
	# Camera2D跟随玩家
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

# ============================================
# 视野与光源事件处理
# ============================================

## 光源视野加成变化
func _on_light_vision_bonus_changed(bonus: float) -> void:
	if vision_system:
		vision_system.set_light_bonus(bonus)

## 光源类型变化
func _on_light_changed(type: int, name: String) -> void:
	print("Light changed to: %s" % name)
	# 更新HUD显示光源类型
	if hud and hud.has_method("update_light") and light_system:
		var status = light_system.get_light_status()
		hud.update_light(name, status.remaining_percentage * 100)

## 光源时间变化
func _on_light_time_changed(remaining: float, total: float) -> void:
	# 更新HUD显示光源剩余时间
	var percentage = remaining / total * 100 if total > 0 else 100
	if hud and hud.has_method("update_light") and light_system:
		var name = light_system.get_light_name()
		hud.update_light(name, percentage)

## 低光源警告
func _on_low_light_warning(level: int) -> void:
	if hud and hud.has_method("show_warning"):
		# 根据警告级别显示不同的视觉效果
		if level == 2:  # 红色警告
			hud.show_warning()
		print("Low light warning: level %d" % level)

## 玩家疲劳状态变化
func _on_player_fatigue_changed(state: int, state_name: String) -> void:
	# 更新视野系统的疲劳惩罚
	if vision_system and player:
		var effects = player.get_fatigue_effects()
		vision_system.set_fatigue_penalty(effects.get("vision_penalty", 0))

	# 更新光源系统对绘制的限制 (疲劳状态下光源效果可能减弱)
	if light_system and state >= 3:  # 濒死或昏迷状态
		print("Player exhausted, vision severely limited")

# ============================================
# 背包与物品系统
# ============================================

## 切换地图显示
func _toggle_map() -> void:
	if map_ui == null:
		return

	if map_ui.visible:
		map_ui.close()
	else:
		# 更新地图数据
		_update_map_data()
		map_ui.show_map()

## 更新地图数据
func _update_map_data() -> void:
	if map_ui and player:
		# 获取玩家位置（转换为迷宫坐标）
		var player_maze_pos = _world_to_maze(player.global_position)
		map_ui.set_player_position(player_maze_pos)

		# 获取入口位置
		if maze_renderer:
			var entrance = maze_renderer.current_maze.get("entrance", Vector2i(-1, -1))
			map_ui.set_entrance_position(entrance)
			var exit = maze_renderer.current_maze.get("exit", Vector2i(-1, -1))
			map_ui.set_exit_position(exit)

## 地图关闭回调
func _on_map_closed() -> void:
	pass

## 背包变化回调
func _on_inventory_changed() -> void:
	if hud and inventory:
		var record_count = inventory.get_item_count(_InventoryManagerScript.ItemType.MAP_RECORD)
		var escape_count = inventory.get_item_count(_InventoryManagerScript.ItemType.ESCAPE)
		if hud.has_method("update_items_display"):
			hud.update_items_display(record_count, escape_count)

## 切换背包界面
func _toggle_inventory() -> void:
	if inventory_ui == null:
		return

	if inventory_ui.visible:
		inventory_ui.close()
	else:
		inventory_ui.show_inventory()

## 背包关闭回调
func _on_inventory_closed() -> void:
	pass

## 物品使用请求回调
func _on_item_use_requested(slot_index: int, item) -> void:
	if inventory == null or player == null:
		return

	# 根据物品类型使用
	match item.item_type:
		_InventoryManagerScript.ItemType.MAP_RECORD:
			var player_maze_pos = _world_to_maze(player.global_position)
			var context = {"player_pos": player_maze_pos}
			inventory.use_item(slot_index, context)
			inventory_ui.close()
		_InventoryManagerScript.ItemType.ESCAPE:
			inventory.use_item(slot_index, {"escape_callback": _escape_to_entrance})
			inventory_ui.close()
		_InventoryManagerScript.ItemType.FOOD:
			var player_stats = player.get_stats()
			var context = {"player_stats": player_stats}
			inventory.use_item(slot_index, context)

## 使用记录道具
func _use_record_item() -> void:
	if inventory == null or player == null:
		return

	# 检查是否有记录道具
	var record_count = inventory.get_item_count(_InventoryManagerScript.ItemType.MAP_RECORD)
	if record_count <= 0:
		print("No record items available!")
		return

	# 获取玩家位置（转换为迷宫坐标）
	var player_maze_pos = _world_to_maze(player.global_position)

	# 使用记录道具
	var context = {
		"player_pos": player_maze_pos
	}

	# 找到记录道具并使用
	var items = inventory.get_all_items()
	for i in range(items.size()):
		if items[i] and items[i].item_type == _InventoryManagerScript.ItemType.MAP_RECORD:
			if inventory.use_item(i, context):
				print("Used record item at position: ", player_maze_pos)
				break

## 使用撤离道具
func use_escape_item() -> void:
	if inventory == null or player == null:
		return

	# 检查是否有撤离道具
	var escape_count = inventory.get_item_count(_InventoryManagerScript.ItemType.ESCAPE)
	if escape_count <= 0:
		print("No escape items available!")
		return

	# 找到撤离道具并使用
	var items = inventory.get_all_items()
	for i in range(items.size()):
		if items[i] and items[i].item_type == _InventoryManagerScript.ItemType.ESCAPE:
			if inventory.use_item(i, {"escape_callback": _escape_to_entrance}):
				print("Used escape item!")
				break

## 撤离到入口
func _escape_to_entrance() -> void:
	if player:
		player.global_position = entrance_world_pos
	if camera:
		camera.global_position = entrance_world_pos
	print("Escaped to entrance!")

## 使用食物道具
func use_food_item(item_name: String) -> bool:
	if inventory == null or player == null:
		return false

	var player_stats = player.get_stats()
	if player_stats == null:
		return false

	# 找到并使用食物
	var items = inventory.get_all_items()
	for i in range(items.size()):
		if items[i] and items[i].item_type == _InventoryManagerScript.ItemType.FOOD and items[i].item_name == item_name:
			var context = {"player_stats": player_stats}
			if inventory.use_item(i, context):
				print("Used food: ", item_name)
				return true

	return false

## 世界坐标转迷宫坐标
func _world_to_maze(world_pos: Vector2) -> Vector2i:
	if maze_renderer:
		return maze_renderer.world_to_maze(world_pos)
	# 默认每个格子50像素
	return Vector2i(int(world_pos.x / 50), int(world_pos.y / 50))

## 迷宫坐标转世界坐标
func _maze_to_world(maze_pos: Vector2i) -> Vector2:
	if maze_renderer:
		return maze_renderer.maze_to_world(maze_pos)
	# 默认每个格子50像素
	return Vector2(maze_pos.x * 50 + 25, maze_pos.y * 50 + 25)