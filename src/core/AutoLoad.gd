## AutoLoad
## 自动加载单例
## 作为所有全局管理器的入口点

extends Node

# ============================================
# 全局管理器引用
# ============================================

## 核心系统
var game_state: GameStateManager
var scene_manager: SceneManager
var event_bus: EventBus
var config_manager: ConfigManager

## 游戏系统（由GameInitializer创建）
var save_manager: SaveManager = null
var achievement_manager: AchievementManager = null
var audio_manager: AudioManager = null
var game_initializer: Node = null

## 游戏玩法系统（运行时设置）
var mist_painting_system: Node = null
var player_controller: Node = null

# ============================================
# 生命周期
# ============================================

func _ready():
	print("AutoLoad initializing...")
	
	# 初始化核心管理器
	_init_core_managers()
	
	print("AutoLoad initialized successfully")

# ============================================
# 初始化
# ============================================

## 初始化核心管理器
func _init_core_managers() -> void:
	# 创建并添加GameStateManager
	game_state = GameStateManager.new()
	game_state.name = "GameStateManager"
	add_child(game_state)
	
	# 创建并添加SceneManager
	scene_manager = SceneManager.new()
	scene_manager.name = "SceneManager"
	add_child(scene_manager)
	
	# 创建并添加EventBus
	event_bus = EventBus.new()
	event_bus.name = "EventBus"
	add_child(event_bus)
	
	# 创建并添加ConfigManager
	config_manager = ConfigManager.new()
	config_manager.name = "ConfigManager"
	add_child(config_manager)

# ============================================
# 快捷访问方法 - 核心系统
# ============================================

func get_game_state() -> GameStateManager:
	return game_state

func get_scene_manager() -> SceneManager:
	return scene_manager

func get_event_bus() -> EventBus:
	return event_bus

func get_config() -> ConfigManager:
	return config_manager

# ============================================
# 快捷访问方法 - 游戏系统
# ============================================

func get_save_manager() -> SaveManager:
	return save_manager

func get_achievement_manager() -> AchievementManager:
	return achievement_manager

func get_audio_manager() -> AudioManager:
	return audio_manager

func get_game_initializer() -> Node:
	return game_initializer

# ============================================
# 快捷访问方法 - 玩法系统
# ============================================

func get_mist_painting_system() -> Node:
	return mist_painting_system

func get_player_controller() -> Node:
	return player_controller

# ============================================
# 系统注册（由GameInitializer调用）
# ============================================

## 注册存档管理器
func register_save_manager(manager: SaveManager) -> void:
	save_manager = manager

## 注册成就管理器
func register_achievement_manager(manager: AchievementManager) -> void:
	achievement_manager = manager

## 注册音频管理器
func register_audio_manager(manager: AudioManager) -> void:
	audio_manager = manager

## 注册游戏初始化器
func register_game_initializer(initializer: Node) -> void:
	game_initializer = initializer

## 注册迷雾绘制系统
func register_mist_painting_system(system: Node) -> void:
	mist_painting_system = system

## 注册玩家控制器
func register_player_controller(player: Node) -> void:
	player_controller = player

# ============================================
# 工具方法
# ============================================

## 检查是否所有系统都已就绪
func are_all_systems_ready() -> bool:
	return game_state != null and \
		   scene_manager != null and \
		   event_bus != null and \
		   config_manager != null and \
		   save_manager != null and \
		   achievement_manager != null and \
		   audio_manager != null

## 获取系统状态报告
func get_system_status() -> Dictionary:
	return {
		"core_systems": {
			"game_state": game_state != null,
			"scene_manager": scene_manager != null,
			"event_bus": event_bus != null,
			"config_manager": config_manager != null
		},
		"game_systems": {
			"save_manager": save_manager != null,
			"achievement_manager": achievement_manager != null,
			"audio_manager": audio_manager != null
		},
		"gameplay_systems": {
			"mist_painting": mist_painting_system != null,
			"player_controller": player_controller != null
		},
		"all_ready": are_all_systems_ready()
	}
