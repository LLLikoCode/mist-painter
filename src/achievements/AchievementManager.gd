## AchievementManager
## 成就管理器核心类
## 负责成就的加载、解锁检测、数据持久化和信号通知

class_name AchievementManager
extends Node

# ============================================
# 常量定义
# ============================================

const ACHIEVEMENTS_FILE_PATH = "res://assets/data/achievements.json"
const ACHIEVEMENTS_SAVE_KEY = "achievements"
const AUTO_SAVE_INTERVAL = 30.0

# ============================================
# 信号
# ============================================

## 成就解锁时发出
signal achievement_unlocked(achievement: AchievementData.Achievement)

## 成就进度更新时发出
signal achievement_progress_updated(achievement: AchievementData.Achievement, old_progress: int, new_progress: int)

## 成就数据加载完成时发出
signal achievements_loaded(count: int)

## 成就数据保存完成时发出
signal achievements_saved

## 成就统计更新时发出
signal stats_updated(stats: AchievementData.AchievementStats)

# ============================================
# 内部变量
# ============================================

## 单例实例
static var instance: AchievementManager = null

## 成就数据字典 { achievement_id: Achievement }
var _achievements: Dictionary = {}

## 成就定义缓存（原始JSON数据）
var _achievement_definitions: Dictionary = {}

## 是否已初始化
var _initialized: bool = false

## 自动保存定时器
var _auto_save_timer: Timer = null

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
	
	# 始终处理，即使游戏暂停
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 加载成就定义
	_load_achievement_definitions()
	
	# 从存档加载成就进度
	_load_from_save()
	
	# 初始化自动保存
	_init_auto_save()
	
	_initialized = true
	
	print("AchievementManager initialized with %d achievements" % _achievements.size())
	achievements_loaded.emit(_achievements.size())

func _exit_tree():
	if instance == self:
		# 退出前保存
		_save_to_save_manager()
		instance = null

# ============================================
# 初始化方法
# ============================================

## 从JSON文件加载成就定义
func _load_achievement_definitions() -> void:
	if not FileAccess.file_exists(ACHIEVEMENTS_FILE_PATH):
		push_warning("Achievements file not found: " + ACHIEVEMENTS_FILE_PATH)
		return
	
	var file = FileAccess.open(ACHIEVEMENTS_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open achievements file: " + ACHIEVEMENTS_FILE_PATH)
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
		var def = _achievement_definitions[achievement_id].duplicate()
		def["id"] = achievement_id
		
		# 转换类型和稀有度为枚举值
		def["type"] = _parse_type(def.get("type", "one_time"))
		def["rarity"] = _parse_rarity(def.get("rarity", "common"))
		
		var achievement = AchievementData.Achievement.new(def)
		_achievements[achievement_id] = achievement

## 从存档管理器加载成就进度
func _load_from_save() -> void:
	# 等待SaveManager可用
	if not _wait_for_save_manager():
		push_warning("SaveManager not available, achievements will not be persisted")
		return
	
	var saved_data = {}
	if SaveManager.instance:
		saved_data = SaveManager.instance.get_save_data(ACHIEVEMENTS_SAVE_KEY)
	
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

## 等待SaveManager可用
func _wait_for_save_manager() -> bool:
	# 检查SaveManager单例是否可用
	if SaveManager.instance != null:
		return true
	return false

## 初始化自动保存
func _init_auto_save() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.name = "AutoSaveTimer"
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)

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
func is_unlocked(achievement_id: String) -> bool:
	var achievement = _achievements.get(achievement_id)
	if achievement:
		return achievement.is_unlocked
	return false

## 获取成就进度
func get_progress(achievement_id: String) -> int:
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
func unlock_achievement(achievement_id: String) -> bool:
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
	
	# 立即保存
	_save_to_save_manager()
	
	return true

## 更新成就进度
func update_progress(achievement_id: String, amount: int = 1) -> bool:
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
		
		if should_unlock:
			unlock_achievement(achievement_id)
		else:
			_save_to_save_manager()
	
	return should_unlock

## 设置成就进度
func set_progress(achievement_id: String, value: int) -> bool:
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
# 持久化
# ============================================

## 保存到存档管理器
func _save_to_save_manager() -> void:
	if SaveManager.instance == null:
		return
	
	var save_data = _build_save_data()
	SaveManager.instance.set_save_data(ACHIEVEMENTS_SAVE_KEY, save_data)
	achievements_saved.emit()

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

# ============================================
# 工具方法
# ============================================

## 解析成就类型字符串为枚举
func _parse_type(type_str: String) -> int:
	match type_str.to_lower():
		"progress":
			return AchievementData.AchievementType.PROGRESS
		"one_time", "onetime":
			return AchievementData.AchievementType.ONE_TIME
		"cumulative":
			return AchievementData.AchievementType.CUMULATIVE
		"hidden":
			return AchievementData.AchievementType.HIDDEN
		_:
			return AchievementData.AchievementType.ONE_TIME

## 解析稀有度字符串为枚举
func _parse_rarity(rarity_str: String) -> int:
	match rarity_str.to_lower():
		"common":
			return AchievementData.AchievementRarity.COMMON
		"uncommon":
			return AchievementData.AchievementRarity.UNCOMMON
		"rare":
			return AchievementData.AchievementRarity.RARE
		"epic":
			return AchievementData.AchievementRarity.EPIC
		"legendary":
			return AchievementData.AchievementRarity.LEGENDARY
		_:
			return AchievementData.AchievementRarity.COMMON

## 解锁所有成就（调试用）
func unlock_all_achievements() -> void:
	for achievement in _achievements.values():
		if not achievement.is_unlocked:
			unlock_achievement(achievement.id)
	print("All achievements unlocked (debug)")

## 获取状态信息
func get_status() -> Dictionary:
	return {
		"total_achievements": _achievements.size(),
		"unlocked_count": get_unlocked_achievements().size(),
		"locked_count": get_locked_achievements().size(),
		"stats": get_stats().to_dictionary()
	}
