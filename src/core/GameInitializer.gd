## GameInitializer
## 游戏初始化器
## 负责整合所有核心系统，管理游戏启动流程和系统依赖

class_name GameInitializer
extends Node

# ============================================
# 常量定义
# ============================================

const INITIALIZATION_TIMEOUT: float = 10.0
const SYSTEM_CHECK_INTERVAL: float = 0.1

# ============================================
# 系统引用
# ============================================

## 核心系统
var game_state_manager: GameStateManager
var scene_manager: SceneManager
var event_bus: EventBus
var config_manager: ConfigManager

## 游戏系统
var save_manager: SaveManager
var achievement_manager: AchievementManager
var audio_manager: AudioManager

## 游戏玩法系统
var mist_painting_system: MistPaintingSystem
var player_controller: PlayerController

# ============================================
# 状态变量
# ============================================

## 初始化状态
enum InitState {
    NOT_STARTED,
    INITIALIZING,
    CORE_SYSTEMS_READY,
    GAME_SYSTEMS_READY,
    GAMEPLAY_SYSTEMS_READY,
    COMPLETE,
    FAILED
}

var current_init_state: InitState = InitState.NOT_STARTED
var initialization_progress: float = 0.0
var initialization_error: String = ""

## 系统就绪状态
var systems_ready: Dictionary = {
    "core": false,
    "save": false,
    "achievement": false,
    "audio": false,
    "gameplay": false
}

# ============================================
# 信号
# ============================================

signal initialization_started
signal initialization_progress_updated(progress: float, stage: String)
signal initialization_completed
signal initialization_failed(error: String)
signal core_systems_ready
signal all_systems_ready

# ============================================
# 生命周期
# ============================================

func _ready():
    print("GameInitializer: Starting initialization...")
    
    # 延迟初始化以确保场景树准备就绪
    await get_tree().create_timer(0.1).timeout
    
    # 开始初始化流程
    _start_initialization()

func _process(delta: float):
    # 可以在这里添加初始化进度监控
    pass

# ============================================
# 初始化流程
# ============================================

## 开始初始化
func _start_initialization() -> void:
    current_init_state = InitState.INITIALIZING
    initialization_started.emit()
    
    # 执行初始化步骤
    await _initialize_core_systems()
    await _initialize_game_systems()
    await _initialize_gameplay_systems()
    await _finalize_initialization()

## 初始化核心系统
func _initialize_core_systems() -> void:
    print("GameInitializer: Initializing core systems...")
    _update_progress(0.1, "核心系统")
    
    # 核心系统已经在AutoLoad中初始化
    # 这里只需要获取引用
    if AutoLoad.game_state:
        game_state_manager = AutoLoad.game_state
    else:
        _fail_initialization("GameStateManager not found in AutoLoad")
        return
    
    if AutoLoad.scene_manager:
        scene_manager = AutoLoad.scene_manager
    else:
        _fail_initialization("SceneManager not found in AutoLoad")
        return
    
    if AutoLoad.event_bus:
        event_bus = AutoLoad.event_bus
    else:
        _fail_initialization("EventBus not found in AutoLoad")
        return
    
    if AutoLoad.config_manager:
        config_manager = AutoLoad.config_manager
    else:
        _fail_initialization("ConfigManager not found in AutoLoad")
        return
    
    # 订阅核心事件
    _subscribe_core_events()
    
    systems_ready["core"] = true
    current_init_state = InitState.CORE_SYSTEMS_READY
    core_systems_ready.emit()
    
    await get_tree().create_timer(0.1).timeout

## 初始化游戏系统
func _initialize_game_systems() -> void:
    print("GameInitializer: Initializing game systems...")
    _update_progress(0.3, "游戏系统")
    
    # 初始化存档系统
    await _init_save_manager()
    
    # 初始化成就系统
    await _init_achievement_manager()
    
    # 初始化音频系统
    await _init_audio_manager()
    
    systems_ready["game"] = true
    current_init_state = InitState.GAME_SYSTEMS_READY
    
    await get_tree().create_timer(0.1).timeout

## 初始化存档管理器
func _init_save_manager() -> void:
    print("GameInitializer: Initializing SaveManager...")
    _update_progress(0.35, "存档系统")
    
    save_manager = SaveManager.new()
    save_manager.name = "SaveManager"
    add_child(save_manager)
    
    # 等待存档系统初始化
    await get_tree().create_timer(0.1).timeout
    
    systems_ready["save"] = true
    print("GameInitializer: SaveManager initialized")

## 初始化成就管理器
func _init_achievement_manager() -> void:
    print("GameInitializer: Initializing AchievementManager...")
    _update_progress(0.45, "成就系统")
    
    achievement_manager = AchievementManager.new()
    achievement_manager.name = "AchievementManager"
    add_child(achievement_manager)
    
    await get_tree().create_timer(0.1).timeout
    
    systems_ready["achievement"] = true
    print("GameInitializer: AchievementManager initialized")

## 初始化音频管理器
func _init_audio_manager() -> void:
    print("GameInitializer: Initializing AudioManager...")
    _update_progress(0.55, "音频系统")
    
    audio_manager = AudioManager.new()
    audio_manager.name = "AudioManager"
    add_child(audio_manager)
    
    # 应用配置中的音量设置
    if config_manager:
        audio_manager.set_master_volume(config_manager.get_setting("audio_master_volume", 1.0))
        audio_manager.set_music_volume(config_manager.get_setting("audio_music_volume", 0.8))
        audio_manager.set_sfx_volume(config_manager.get_setting("audio_sfx_volume", 1.0))
    
    await get_tree().create_timer(0.1).timeout
    
    systems_ready["audio"] = true
    print("GameInitializer: AudioManager initialized")

## 初始化游戏玩法系统
func _initialize_gameplay_systems() -> void:
    print("GameInitializer: Initializing gameplay systems...")
    _update_progress(0.7, "玩法系统")
    
    # 游戏玩法系统会在场景加载时创建
    # 这里只需要确保引用可以被设置
    
    systems_ready["gameplay"] = true
    current_init_state = InitState.GAMEPLAY_SYSTEMS_READY
    
    await get_tree().create_timer(0.1).timeout

## 完成初始化
func _finalize_initialization() -> void:
    print("GameInitializer: Finalizing initialization...")
    _update_progress(0.9, "系统整合")
    
    # 验证所有系统
    if not _verify_all_systems():
        return
    
    # 设置全局引用
    _setup_global_references()
    
    # 订阅所有系统事件
    _subscribe_all_events()
    
    # 应用保存的设置
    _apply_saved_settings()
    
    _update_progress(1.0, "完成")
    current_init_state = InitState.COMPLETE
    
    print("GameInitializer: Initialization complete!")
    initialization_completed.emit()
    all_systems_ready.emit()

# ============================================
# 系统验证
# ============================================

## 验证所有系统
func _verify_all_systems() -> bool:
    var required_systems = [
        ["GameStateManager", game_state_manager],
        ["SceneManager", scene_manager],
        ["EventBus", event_bus],
        ["ConfigManager", config_manager],
        ["SaveManager", save_manager],
        ["AchievementManager", achievement_manager],
        ["AudioManager", audio_manager]
    ]
    
    for system_info in required_systems:
        var name = system_info[0]
        var system = system_info[1]
        
        if system == null:
            _fail_initialization("Required system not initialized: " + name)
            return false
    
    return true

## 设置全局引用
func _setup_global_references() -> void:
    # 将系统引用添加到AutoLoad以便全局访问
    AutoLoad.set_meta("save_manager", save_manager)
    AutoLoad.set_meta("achievement_manager", achievement_manager)
    AutoLoad.set_meta("audio_manager", audio_manager)
    AutoLoad.set_meta("game_initializer", self)

# ============================================
# 事件订阅
# ============================================

## 订阅核心事件
func _subscribe_core_events() -> void:
    if event_bus:
        event_bus.subscribe(EventBus.EventType.GAME_STARTED, _on_game_started)
        event_bus.subscribe(EventBus.EventType.GAME_PAUSED, _on_game_paused)
        event_bus.subscribe(EventBus.EventType.GAME_RESUMED, _on_game_resumed)
        event_bus.subscribe(EventBus.EventType.SETTINGS_CHANGED, _on_settings_changed)

## 订阅所有系统事件
func _subscribe_all_events() -> void:
    # 存档事件
    if save_manager:
        save_manager.save_completed.connect(_on_save_completed)
        save_manager.load_completed.connect(_on_load_completed)
    
    # 成就事件
    if achievement_manager:
        achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)

# ============================================
# 设置应用
# ============================================

## 应用保存的设置
func _apply_saved_settings() -> void:
    if config_manager:
        # 应用显示设置
        config_manager.apply_display_settings()
        
        # 应用音频设置
        if audio_manager:
            audio_manager.set_master_volume(config_manager.get_setting("audio_master_volume", 1.0))
            audio_manager.set_music_volume(config_manager.get_setting("audio_music_volume", 0.8))
            audio_manager.set_sfx_volume(config_manager.get_setting("audio_sfx_volume", 1.0))

# ============================================
# 事件回调
# ============================================

func _on_game_started(data: Dictionary) -> void:
    print("GameInitializer: Game started")

func _on_game_paused(data: Dictionary) -> void:
    if audio_manager:
        audio_manager.pause_bgm()

func _on_game_resumed(data: Dictionary) -> void:
    if audio_manager:
        audio_manager.resume_bgm()

func _on_settings_changed(data: Dictionary) -> void:
    _apply_saved_settings()

func _on_save_completed(slot: int) -> void:
    print("GameInitializer: Game saved to slot " + str(slot))

func _on_load_completed(slot: int) -> void:
    print("GameInitializer: Game loaded from slot " + str(slot))
    _apply_saved_settings()

func _on_achievement_unlocked(achievement) -> void:
    print("GameInitializer: Achievement unlocked - " + achievement.name)

# ============================================
# 进度更新
# ============================================

func _update_progress(progress: float, stage: String) -> void:
    initialization_progress = progress
    initialization_progress_updated.emit(progress, stage)

## 初始化失败
func _fail_initialization(error: String) -> void:
    initialization_error = error
    current_init_state = InitState.FAILED
    push_error("GameInitializer: " + error)
    initialization_failed.emit(error)

# ============================================
# 公共方法 - 系统访问
# ============================================

## 获取存档管理器
func get_save_manager() -> SaveManager:
    return save_manager

## 获取成就管理器
func get_achievement_manager() -> AchievementManager:
    return achievement_manager

## 获取音频管理器
func get_audio_manager() -> AudioManager:
    return audio_manager

## 获取初始化状态
func get_init_state() -> InitState:
    return current_init_state

## 获取初始化进度
func get_init_progress() -> float:
    return initialization_progress

## 是否初始化完成
func is_initialized() -> bool:
    return current_init_state == InitState.COMPLETE

## 等待初始化完成
func wait_for_initialization() -> bool:
    while current_init_state != InitState.COMPLETE and current_init_state != InitState.FAILED:
        await get_tree().process_frame
    return current_init_state == InitState.COMPLETE

# ============================================
# 公共方法 - 游戏流程
# ============================================

## 开始新游戏
func start_new_game() -> void:
    if not is_initialized():
        push_warning("GameInitializer: Cannot start game, initialization not complete")
        return
    
    print("GameInitializer: Starting new game...")
    
    # 重置游戏状态
    game_state_manager.reset_stats()
    game_state_manager.set_current_level(0)
    
    # 播放开始音效
    if audio_manager:
        audio_manager.play_confirm_sfx()
    
    # 切换到游戏场景
    scene_manager.change_scene_by_name("game")

## 继续游戏
func continue_game() -> void:
    if not is_initialized():
        push_warning("GameInitializer: Cannot continue game, initialization not complete")
        return
    
    print("GameInitializer: Continuing game...")
    
    # 加载存档
    if save_manager and save_manager.has_save(0):
        save_manager.load_game(0)
    
    # 切换到游戏场景
    scene_manager.change_scene_by_name("game")

## 返回主菜单
func return_to_main_menu() -> void:
    if audio_manager:
        audio_manager.play_cancel_sfx()
    
    scene_manager.change_scene_by_name("main_menu")

## 退出游戏
func quit_game() -> void:
    print("GameInitializer: Quitting game...")
    
    # 自动保存
    if save_manager:
        save_manager.auto_save()
    
    # 保存配置
    if config_manager:
        config_manager.save_config()
    
    # 退出
    get_tree().quit()

# ============================================
# 公共方法 - 系统注册
# ============================================

## 注册迷雾绘制系统
func register_mist_painting_system(system: MistPaintingSystem) -> void:
    mist_painting_system = system
    print("GameInitializer: MistPaintingSystem registered")

## 注册玩家控制器
func register_player_controller(player: PlayerController) -> void:
    player_controller = player
    
    # 连接玩家事件到迷雾系统
    if mist_painting_system:
        player.paint_started.connect(mist_painting_system.start_drawing)
        player.paint_ended.connect(mist_painting_system.end_drawing)
        player.paint_moved.connect(mist_painting_system.continue_drawing)
    
    print("GameInitializer: PlayerController registered")

## 获取迷雾绘制系统
func get_mist_painting_system() -> MistPaintingSystem:
    return mist_painting_system

## 获取玩家控制器
func get_player_controller() -> PlayerController:
    return player_controller
