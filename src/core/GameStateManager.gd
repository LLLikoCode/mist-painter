## GameStateManager
## 游戏状态管理器
## 负责管理游戏的全局状态，包括游戏模式、关卡进度等

class_name GameStateManager
extends Node

# 游戏状态枚举
enum GameState {
    NONE,           # 无状态
    BOOT,           # 启动中
    MAIN_MENU,      # 主菜单
    PLAYING,        # 游戏中
    PAUSED,         # 暂停
    GAME_OVER,      # 游戏结束
    LEVEL_COMPLETE, # 关卡完成
    CREDITS         #  credits
}

# 游戏模式枚举
enum GameMode {
    STORY,      # 故事模式
    FREE_PLAY,  # 自由模式
    TUTORIAL    # 教程模式
}

# 当前状态
var current_state: GameState = GameState.BOOT
var previous_state: GameState = GameState.NONE

# 当前游戏模式
var current_mode: GameMode = GameMode.STORY

# 当前关卡
var current_level: int = 0
var max_unlocked_level: int = 0

# 游戏统计数据
var game_stats: Dictionary = {
    "total_play_time": 0.0,
    "levels_completed": 0,
    "puzzles_solved": 0,
    "mist_used": 0
}

# 信号
signal state_changed(new_state: GameState, old_state: GameState)
signal mode_changed(new_mode: GameMode, old_mode: GameMode)
signal level_changed(new_level: int)

func _ready():
    # 确保此节点持久化
    process_mode = Node.PROCESS_MODE_ALWAYS
    print("GameStateManager initialized")

## 切换游戏状态
func change_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    
    previous_state = current_state
    current_state = new_state
    
    print("Game state changed: %s -> %s" % [_get_state_name(previous_state), _get_state_name(current_state)])
    state_changed.emit(current_state, previous_state)

## 返回上一状态
func return_to_previous_state() -> void:
    if previous_state != GameState.NONE:
        change_state(previous_state)

## 获取当前状态
func get_current_state() -> GameState:
    return current_state

## 检查当前状态
func is_in_state(state: GameState) -> bool:
    return current_state == state

## 设置游戏模式
func set_game_mode(mode: GameMode) -> void:
    if current_mode == mode:
        return
    
    var old_mode = current_mode
    current_mode = mode
    
    print("Game mode changed: %s -> %s" % [_get_mode_name(old_mode), _get_mode_name(current_mode)])
    mode_changed.emit(current_mode, old_mode)

## 获取当前游戏模式
func get_game_mode() -> GameMode:
    return current_mode

## 设置当前关卡
func set_current_level(level: int) -> void:
    current_level = level
    if level > max_unlocked_level:
        max_unlocked_level = level
    level_changed.emit(current_level)

## 获取当前关卡
func get_current_level() -> int:
    return current_level

## 更新统计数据
func update_stat(stat_name: String, value: Variant) -> void:
    if game_stats.has(stat_name):
        game_stats[stat_name] = value

## 增加统计数据
func increment_stat(stat_name: String, amount: Variant = 1) -> void:
    if game_stats.has(stat_name):
        game_stats[stat_name] = game_stats[stat_name] + amount

## 获取统计数据
func get_stat(stat_name: String) -> Variant:
    return game_stats.get(stat_name, 0)

## 获取所有统计数据
func get_all_stats() -> Dictionary:
    return game_stats.duplicate()

## 重置统计数据
func reset_stats() -> void:
    for key in game_stats.keys():
        game_stats[key] = 0

## 状态名称辅助函数
func _get_state_name(state: GameState) -> String:
    match state:
        GameState.NONE: return "NONE"
        GameState.BOOT: return "BOOT"
        GameState.MAIN_MENU: return "MAIN_MENU"
        GameState.PLAYING: return "PLAYING"
        GameState.PAUSED: return "PAUSED"
        GameState.GAME_OVER: return "GAME_OVER"
        GameState.LEVEL_COMPLETE: return "LEVEL_COMPLETE"
        GameState.CREDITS: return "CREDITS"
        _: return "UNKNOWN"

## 模式名称辅助函数
func _get_mode_name(mode: GameMode) -> String:
    match mode:
        GameMode.STORY: return "STORY"
        GameMode.FREE_PLAY: return "FREE_PLAY"
        GameMode.TUTORIAL: return "TUTORIAL"
        _: return "UNKNOWN"
