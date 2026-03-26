## SaveManager
## 存档管理器
## 负责游戏的保存和加载功能

class_name SaveManager
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const MAX_SAVE_SLOTS = 3

# 当前存档数据
var current_save_data: Dictionary = {}
var current_slot: int = -1

# 信号
signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_deleted(slot: int)
signal save_data_changed()

func _ready():
    # 确保存档目录存在
    _ensure_save_dir()
    print("SaveManager initialized")

## 确保存档目录存在
func _ensure_save_dir() -> void:
    var dir = DirAccess.open("user://")
    if dir:
        if not dir.dir_exists("saves"):
            dir.make_dir("saves")

## 保存游戏
func save_game(slot: int = 0, save_name: String = "") -> bool:
    if slot < 0 or slot >= MAX_SAVE_SLOTS:
        push_error("Invalid save slot: " + str(slot))
        return false
    
    # 构建存档数据
    var save_data = _build_save_data()
    
    if save_name != "":
        save_data["save_name"] = save_name
    
    # 序列化并保存
    var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file == null:
        push_error("Failed to open save file: " + file_path)
        return false
    
    # 使用JSON序列化
    var json_string = JSON.stringify(save_data)
    file.store_string(json_string)
    file.close()
    
    current_slot = slot
    current_save_data = save_data
    
    print("Game saved to slot " + str(slot))
    save_completed.emit(slot)
    
    return true

## 加载游戏
func load_game(slot: int = 0) -> bool:
    if slot < 0 or slot >= MAX_SAVE_SLOTS:
        push_error("Invalid save slot: " + str(slot))
        return false
    
    var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    
    if not FileAccess.file_exists(file_path):
        print("Save file not found: " + file_path)
        return false
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_error("Failed to open save file: " + file_path)
        return false
    
    var json_string = file.get_as_text()
    file.close()
    
    # 解析JSON
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        push_error("Failed to parse save file: " + json.get_error_message())
        return false
    
    current_save_data = json.get_data()
    current_slot = slot
    
    # 应用存档数据
    _apply_save_data(current_save_data)
    
    print("Game loaded from slot " + str(slot))
    load_completed.emit(slot)
    
    return true

## 删除存档
func delete_save(slot: int) -> bool:
    if slot < 0 or slot >= MAX_SAVE_SLOTS:
        return false
    
    var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    
    if FileAccess.file_exists(file_path):
        var dir = DirAccess.open(SAVE_DIR)
        if dir:
            dir.remove(file_path)
            print("Save deleted from slot " + str(slot))
            save_deleted.emit(slot)
            return true
    
    return false

## 检查存档是否存在
func has_save(slot: int) -> bool:
    if slot < 0 or slot >= MAX_SAVE_SLOTS:
        return false
    
    var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    return FileAccess.file_exists(file_path)

## 获取存档信息
func get_save_info(slot: int) -> Dictionary:
    if not has_save(slot):
        return {}
    
    var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    var file = FileAccess.open(file_path, FileAccess.READ)
    
    if file == null:
        return {}
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        return {}
    
    var data = json.get_data()
    
    return {
        "slot": slot,
        "save_name": data.get("save_name", "存档 " + str(slot + 1)),
        "level": data.get("level", 0),
        "play_time": data.get("play_time", 0),
        "timestamp": data.get("timestamp", "")
    }

## 获取所有存档信息
func get_all_save_info() -> Array[Dictionary]:
    var saves: Array[Dictionary] = []
    
    for i in range(MAX_SAVE_SLOTS):
        saves.append(get_save_info(i))
    
    return saves

## 快速保存（自动选择槽位）
func quick_save() -> bool:
    return save_game(0, "快速存档")

## 快速加载
func quick_load() -> bool:
    return load_game(0)

## 自动保存
func auto_save() -> bool:
    return save_game(MAX_SAVE_SLOTS - 1, "自动存档")

## 构建存档数据
func _build_save_data() -> Dictionary:
    var save_data = {
        "version": ProjectSettings.get_setting("application/config/version"),
        "timestamp": Time.get_datetime_string_from_system(),
        "level": AutoLoad.game_state.get_current_level(),
        "play_time": AutoLoad.game_state.get_stat("total_play_time"),
        "game_stats": AutoLoad.game_state.get_all_stats(),
        "settings": AutoLoad.config_manager.get_all_settings()
    }
    
    return save_data

## 应用存档数据
func _apply_save_data(data: Dictionary) -> void:
    # 恢复关卡
    var level = data.get("level", 0)
    AutoLoad.game_state.set_current_level(level)
    
    # 恢复统计数据
    var stats = data.get("game_stats", {})
    for key in stats.keys():
        AutoLoad.game_state.update_stat(key, stats[key])
    
    # 恢复设置
    var settings = data.get("settings", {})
    AutoLoad.config_manager.set_settings(settings)
    
    save_data_changed.emit()

## 导出存档（用于备份）
func export_save(slot: int, export_path: String) -> bool:
    if not has_save(slot):
        return false
    
    var source_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    var file = FileAccess.open(source_path, FileAccess.READ)
    
    if file == null:
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var export_file = FileAccess.open(export_path, FileAccess.WRITE)
    if export_file == null:
        return false
    
    export_file.store_string(content)
    export_file.close()
    
    return true

## 导入存档
func import_save(import_path: String, slot: int) -> bool:
    if not FileAccess.file_exists(import_path):
        return false
    
    var file = FileAccess.open(import_path, FileAccess.READ)
    if file == null:
        return false
    
    var content = file.get_as_text()
    file.close()
    
    # 验证JSON格式
    var json = JSON.new()
    if json.parse(content) != OK:
        return false
    
    var target_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
    var target_file = FileAccess.open(target_path, FileAccess.WRITE)
    
    if target_file == null:
        return false
    
    target_file.store_string(content)
    target_file.close()
    
    return true
