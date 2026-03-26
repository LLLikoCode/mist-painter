## AchievementManager
## 成就管理器
## 负责管理成就的加载、解锁、进度追踪和持久化

class_name AchievementManager
extends Node

# ============================================
# 常量定义
# ============================================

const ACHIEVEMENTS_FILE_PATH = "res://resources/achievements.json"
const ACHIEVEMENTS_SAVE_KEY = "achievements"

# ============================================
# 导出变量
# ============================================

@export_group("Notification Settings")
@export var notification_duration: float = 3.0
@export var notification_queue_max: int = 5

# ============================================
# 内部变量
# ============================================

## 单例实例
static var instance: AchievementManager = null

## 成就数据字典 { achievement_id: Achievement }
var _achievements: Dictionary = {}

## 成就定义缓存（原始数据）
var _achievement_definitions: Dictionary = {}

## 通知队列
var _notification_queue: Array[Dictionary] = []

## 是否正在显示通知
var _is_showing_notification: bool = false

## 成就解锁监听器（外部系统可以注册自定义解锁条件检查）
var _unlock_checkers: Dictionary = {}

## 自动保存定时器
var _auto_save_timer: Timer = null

# ============================================
# 信号
# ============================================

signal achievement_unlocked(achievement: AchievementData.Achievement)
signal achievement_progress_updated(achievement: AchievementData.Achievement, old_progress: int, new_progress: int)
signal achievement_loaded(achievement_count: int)
signal achievement_saved
signal notification_queue_updated(queue_size: int)
signal stats_updated(stats: AchievementData.AchievementStats)

# ============================================
# 生命周期
# ============================================

func _ready():
    # 设置单例
    if instance == null:
        instance = self
    else:
        queue_free()
        return
    
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 加载成就定义
    _load_achievement_definitions()
    
    # 从存档加载成就进度
    _load_from_save()
    
    # 初始化自动保存
    _init_auto_save()
    
    # 订阅事件总线
    _subscribe_to_events()
    
    print("AchievementManager initialized with %d achievements" % _achievements.size())
    achievement_loaded.emit(_achievements.size())

func _exit_tree():
    if instance == self:
        instance = null

# ============================================
# 初始化方法
# ============================================

## 加载成就定义
func _load_achievement_definitions() -> void:
    if not FileAccess.file_exists(ACHIEVEMENTS_FILE_PATH):
        push_warning("Achievements file not found: " + ACHIEVEMENTS_FILE_PATH)
        return
    
    var file = FileAccess.open(ACHIEVEMENTS_FILE_PATH, FileAccess.READ)
    if file == null:
        push_error("Failed to open achievements file")
        return
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        push_error("Failed to parse achievements JSON: " + json.get_error_message())
        return
    
    var data = json.get_data()
    if not data is Dictionary:
        push_error("Invalid achievements data format")
        return
    
    _achievement_definitions = data.get("achievements", {})
    
    # 初始化成就对象
    for achievement_id in _achievement_definitions.keys():
        var def = _achievement_definitions[achievement_id]
        def["id"] = achievement_id
        
        var achievement = AchievementData.Achievement.new(def)
        _achievements[achievement_id] = achievement

## 从存档加载成就进度
func _load_from_save() -> void:
    # 等待SaveManager可用
    if AutoLoad.save_manager == null:
        await get_tree().create_timer(0.5).timeout
        _load_from_save()
        return
    
    var saved_data = AutoLoad.save_manager.get_save_data(ACHIEVEMENTS_SAVE_KEY)
    if saved_data.is_empty():
        return
    
    # 恢复成就进度
    for achievement_id in saved_data.keys():
        if _achievements.has(achievement_id):
            var data = saved_data[achievement_id]
            var achievement = _achievements[achievement_id]
            
            achievement.is_unlocked = data.get("is_unlocked", false)
            achievement.unlocked_at = data.get("unlocked_at", "")
            achievement.current_progress = data.get("current_progress", 0)

## 初始化自动保存
func _init_auto_save() -> void:
    _auto_save_timer = Timer.new()
    _auto_save_timer.name = "AutoSaveTimer"
    _auto_save_timer.wait_time = 30.0  # 每30秒自动保存
    _auto_save_timer.autostart = true
    _auto_save_timer.timeout.connect(_on_auto_save_timeout)
    add_child(_auto_save_timer)

## 订阅事件总线
func _subscribe_to_events() -> void:
    if AutoLoad.event_bus:
        # 监听游戏事件来触发成就检查
        AutoLoad.event_bus.subscribe(EventBus.EventType.LEVEL_COMPLETED, _on_level_completed)
        AutoLoad.event_bus.subscribe(EventBus.EventType.PUZZLE_SOLVED, _on_puzzle_solved)
        AutoLoad.event_bus.subscribe(EventBus.EventType.GAME_OVER, _on_game_over)

# ============================================
# 成就查询方法
# ============================================

## 获取所有成就
func get_all_achievements() -> Array[AchievementData.Achievement]:
    var result: Array[AchievementData.Achievement] = []
    for achievement in _achievements.values():
        result.append(achievement)
    return result

## 获取已解锁成就
func get_unlocked_achievements() -> Array[AchievementData.Achievement]:
    var result: Array[AchievementData.Achievement] = []
    for achievement in _achievements.values():
        if achievement.is_unlocked:
            result.append(achievement)
    return result

## 获取未解锁成就
func get_locked_achievements() -> Array[AchievementData.Achievement]:
    var result: Array[AchievementData.Achievement] = []
    for achievement in _achievements.values():
        if not achievement.is_unlocked:
            result.append(achievement)
    return result

## 获取特定成就
func get_achievement(achievement_id: String) -> AchievementData.Achievement:
    return _achievements.get(achievement_id)

## 检查成就是否存在
func has_achievement(achievement_id: String) -> bool:
    return _achievements.has(achievement_id)

## 检查成就是否已解锁
func is_achievement_unlocked(achievement_id: String) -> bool:
    var achievement = _achievements.get(achievement_id)
    if achievement:
        return achievement.is_unlocked
    return false

## 获取成就进度
func get_achievement_progress(achievement_id: String) -> int:
    var achievement = _achievements.get(achievement_id)
    if achievement:
        return achievement.current_progress
    return 0

## 获取成就统计
func get_stats() -> AchievementData.AchievementStats:
    var stats = AchievementData.AchievementStats.new()
    
    for achievement in _achievements.values():
        stats.total_count += 1
        stats.total_points += achievement.points
        
        if achievement.is_hidden:
            stats.hidden_count += 1
        
        if achievement.is_unlocked:
            stats.unlocked_count += 1
            stats.earned_points += achievement.points
            
            if achievement.is_hidden:
                stats.hidden_unlocked_count += 1
    
    return stats

# ============================================
# 成就解锁与进度
# ============================================

## 解锁成就
func unlock_achievement(achievement_id: String, show_notification: bool = true) -> bool:
    var achievement = _achievements.get(achievement_id)
    if achievement == null:
        push_warning("Achievement not found: " + achievement_id)
        return false
    
    if achievement.is_unlocked:
        return false
    
    # 解锁成就
    achievement.unlock()
    
    print("Achievement unlocked: %s - %s" % [achievement_id, achievement.name])
    
    # 发送信号
    achievement_unlocked.emit(achievement)
    stats_updated.emit(get_stats())
    
    # 显示通知
    if show_notification:
        _queue_notification(achievement)
    
    # 触发事件
    if AutoLoad.event_bus:
        AutoLoad.event_bus.emit(EventBus.EventType.ACHIEVEMENT_UNLOCKED, {
            "achievement_id": achievement_id,
            "achievement": achievement
        })
    
    # 立即保存
    _save_to_save_manager()
    
    return true

## 更新成就进度
func update_achievement_progress(achievement_id: String, amount: int = 1) -> bool:
    var achievement = _achievements.get(achievement_id)
    if achievement == null:
        return false
    
    if achievement.is_unlocked:
        return false
    
    var old_progress = achievement.current_progress
    var should_unlock = achievement.update_progress(amount)
    var new_progress = achievement.current_progress
    
    if old_progress != new_progress:
        print("Achievement progress updated: %s (%d/%d)" % [achievement_id, new_progress, achievement.target_progress])
        achievement_progress_updated.emit(achievement, old_progress, new_progress)
        
        # 检查是否应该解锁
        if should_unlock:
            unlock_achievement(achievement_id)
        else:
            # 进度更新也保存
            _save_to_save_manager()
    
    return should_unlock

## 设置成就进度
func set_achievement_progress(achievement_id: String, value: int) -> bool:
    var achievement = _achievements.get(achievement_id)
    if achievement == null:
        return false
    
    if achievement.is_unlocked:
        return false
    
    var old_progress = achievement.current_progress
    var should_unlock = achievement.set_progress(value)
    var new_progress = achievement.current_progress
    
    if old_progress != new_progress:
        achievement_progress_updated.emit(achievement, old_progress, new_progress)
        
        if should_unlock:
            unlock_achievement(achievement_id)
        else:
            _save_to_save_manager()
    
    return should_unlock

## 批量更新进度（用于累积类成就）
func increment_stat(stat_name: String, amount: int = 1) -> void:
    # 查找与此统计相关的所有成就
    for achievement in _achievements.values():
        if achievement.is_unlocked:
            continue
        
        if achievement.condition_type == "stat" and achievement.condition_params.get("stat_name") == stat_name:
            update_achievement_progress(achievement.id, amount)

## 重置单个成就
func reset_achievement(achievement_id: String) -> void:
    var achievement = _achievements.get(achievement_id)
    if achievement == null:
        return
    
    achievement.is_unlocked = false
    achievement.unlocked_at = ""
    achievement.current_progress = 0
    
    _save_to_save_manager()
    stats_updated.emit(get_stats())

## 重置所有成就
func reset_all_achievements() -> void:
    for achievement in _achievements.values():
        achievement.is_unlocked = false
        achievement.unlocked_at = ""
        achievement.current_progress = 0
    
    _save_to_save_manager()
    stats_updated.emit(get_stats())
    print("All achievements reset")

# ============================================
# 通知系统
# ============================================

## 队列通知
func _queue_notification(achievement: AchievementData.Achievement) -> void:
    if _notification_queue.size() >= notification_queue_max:
        _notification_queue.pop_front()
    
    _notification_queue.append({
        "achievement": achievement,
        "timestamp": Time.get_ticks_msec()
    })
    
    notification_queue_updated.emit(_notification_queue.size())
    
    if not _is_showing_notification:
        _process_notification_queue()

## 处理通知队列
func _process_notification_queue() -> void:
    if _notification_queue.is_empty():
        _is_showing_notification = false
        return
    
    _is_showing_notification = true
    var notification = _notification_queue.pop_front()
    var achievement = notification["achievement"] as AchievementData.Achievement
    
    # 显示通知UI
    _show_notification_ui(achievement)
    
    notification_queue_updated.emit(_notification_queue.size())

## 显示通知UI
func _show_notification_ui(achievement: AchievementData.Achievement) -> void:
    # 创建通知弹窗
    var notification_scene = load("res://src/ui/components/AchievementNotification.tscn")
    if notification_scene == null:
        push_warning("AchievementNotification scene not found")
        return
    
    var notification = notification_scene.instantiate()
    notification.setup(achievement)
    
    # 添加到UI层
    var ui_layer = _get_ui_layer()
    if ui_layer:
        ui_layer.add_child(notification)
        notification.show_notification(notification_duration)
        
        # 通知关闭后继续处理队列
        notification.notification_closed.connect(func(): 
            await get_tree().create_timer(0.5).timeout
            _process_notification_queue()
        )

## 获取UI层
func _get_ui_layer() -> CanvasLayer:
    var tree = get_tree()
    if tree:
        var root = tree.root
        for child in root.get_children():
            if child is CanvasLayer and child.name == "UILayer":
                return child
    return null

# ============================================
# 持久化
# ============================================

## 保存到存档管理器
func _save_to_save_manager() -> void:
    if AutoLoad.save_manager == null:
        return
    
    var save_data = _build_save_data()
    AutoLoad.save_manager.set_save_data(ACHIEVEMENTS_SAVE_KEY, save_data)
    achievement_saved.emit()

## 构建保存数据
func _build_save_data() -> Dictionary:
    var save_data = {}
    
    for achievement_id in _achievements.keys():
        var achievement = _achievements[achievement_id]
        save_data[achievement_id] = {
            "is_unlocked": achievement.is_unlocked,
            "unlocked_at": achievement.unlocked_at,
            "current_progress": achievement.current_progress
        }
    
    return save_data

## 手动触发保存
func save_achievements() -> void:
    _save_to_save_manager()

# ============================================
# 事件处理
# ============================================

func _on_auto_save_timeout() -> void:
    _save_to_save_manager()

func _on_level_completed(data: Dictionary) -> void:
    var level = data.get("level", 0)
    
    # 检查关卡相关成就
    for achievement in _achievements.values():
        if achievement.is_unlocked:
            continue
        
        match achievement.condition_type:
            "level_complete":
                var target_level = achievement.condition_params.get("level", 0)
                if level >= target_level:
                    unlock_achievement(achievement.id)
            "level_complete_first":
                if level == achievement.condition_params.get("level", 0):
                    unlock_achievement(achievement.id)

func _on_puzzle_solved(data: Dictionary) -> void:
    # 更新解谜统计
    increment_stat("puzzles_solved", 1)
    
    # 检查特定谜题成就
    var puzzle_id = data.get("puzzle_id", "")
    for achievement in _achievements.values():
        if achievement.is_unlocked:
            continue
        
        if achievement.condition_type == "puzzle_solved":
            var target_puzzle = achievement.condition_params.get("puzzle_id", "")
            if target_puzzle == puzzle_id or target_puzzle == "":
                unlock_achievement(achievement.id)

func _on_game_over(data: Dictionary) -> void:
    # 检查游戏结束相关成就
    var is_victory = data.get("is_victory", false)
    
    if is_victory:
        increment_stat("games_won", 1)
    else:
        increment_stat("games_lost", 1)

# ============================================
# 调试与工具
# ============================================

## 解锁所有成就（调试用）
func unlock_all_achievements() -> void:
    for achievement in _achievements.values():
        if not achievement.is_unlocked:
            unlock_achievement(achievement.id, false)
    print("All achievements unlocked (debug)")

## 获取状态信息
func get_status() -> Dictionary:
    return {
        "total_achievements": _achievements.size(),
        "unlocked_count": get_unlocked_achievements().size(),
        "locked_count": get_locked_achievements().size(),
        "notification_queue_size": _notification_queue.size(),
        "stats": get_stats().to_dictionary()
    }

## 导出成就数据（用于备份）
func export_achievements() -> Dictionary:
    return _build_save_data()

## 导入成就数据
func import_achievements(data: Dictionary) -> void:
    for achievement_id in data.keys():
        if _achievements.has(achievement_id):
            var achievement_data = data[achievement_id]
            var achievement = _achievements[achievement_id]
            
            achievement.is_unlocked = achievement_data.get("is_unlocked", false)
            achievement.unlocked_at = achievement_data.get("unlocked_at", "")
            achievement.current_progress = achievement_data.get("current_progress", 0)
    
    _save_to_save_manager()
    stats_updated.emit(get_stats())
