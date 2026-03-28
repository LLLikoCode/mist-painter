## ConfigManager
## 配置管理器
## 负责管理游戏设置、用户偏好和持久化配置

class_name ConfigManager
extends Node

const CONFIG_FILE_PATH = "user://config.cfg"
const DEFAULT_SECTION = "settings"

# 单例实例
static var instance: ConfigManager = null

# 默认配置值
const DEFAULT_CONFIG = {
    # 显示设置
    "display_fullscreen": false,
    "display_resolution": Vector2i(1280, 720),
    "display_vsync": true,
    "display_fps_limit": 60,
    "display_show_fps": false,
    
    # 音频设置
    "audio_master_volume": 1.0,
    "audio_music_volume": 0.8,
    "audio_sfx_volume": 1.0,
    "audio_muted": false,
    
    # 游戏设置
    "game_language": "zh_CN",
    "game_difficulty": 1,  # 0=简单, 1=普通, 2=困难
    "game_hints_enabled": true,
    "game_tutorial_shown": false,
    
    # 控制设置
    "control_mouse_sensitivity": 1.0,
    "control_invert_y": false,
    "control_vibration": true,
    
    # 辅助功能
    "accessibility_subtitles": true,
    "accessibility_colorblind_mode": 0,  # 0=关闭, 1=红绿色盲, 2=蓝黄色盲
    "accessibility_text_size": 1.0
}

# 配置数据
var config: ConfigFile = ConfigFile.new()
var current_config: Dictionary = {}

# 信号
signal config_loaded()
signal config_saved()
signal setting_changed(key: String, value: Variant)
signal settings_reset()

func _ready():
    # 设置单例
    if instance == null:
        instance = self
    else:
        queue_free()
        return

    process_mode = Node.PROCESS_MODE_ALWAYS

    # 加载配置
    load_config()

    print("ConfigManager initialized")

func _exit_tree():
    if instance == self:
        instance = null

## 加载配置
func load_config() -> bool:
    # 先设置默认值
    _set_defaults()
    
    # 尝试从文件加载
    var err = config.load(CONFIG_FILE_PATH)
    
    if err == OK:
        # 读取所有配置值
        _load_from_config_file()
        print("Config loaded from: " + CONFIG_FILE_PATH)
    else:
        print("Config file not found, using defaults")
        save_config()  # 创建默认配置文件
    
    config_loaded.emit()
    return true

## 保存配置
func save_config() -> bool:
    # 将当前配置写入文件
    for key in current_config.keys():
        config.set_value(DEFAULT_SECTION, key, current_config[key])
    
    var err = config.save(CONFIG_FILE_PATH)
    
    if err == OK:
        print("Config saved to: " + CONFIG_FILE_PATH)
        config_saved.emit()
        return true
    else:
        push_error("Failed to save config: " + str(err))
        return false

## 获取配置值
func get_setting(key: String, default_value: Variant = null) -> Variant:
    if current_config.has(key):
        return current_config[key]
    elif DEFAULT_CONFIG.has(key):
        return DEFAULT_CONFIG[key]
    return default_value

## 设置配置值
func set_setting(key: String, value: Variant) -> void:
    var old_value = current_config.get(key)
    
    if old_value != value:
        current_config[key] = value
        setting_changed.emit(key, value)
        
        if key.begins_with("audio_"):
            _apply_audio_setting(key, value)
        elif key.begins_with("display_"):
            _apply_display_setting(key, value)

## 批量设置配置
func set_settings(settings: Dictionary) -> void:
    for key in settings.keys():
        set_setting(key, settings[key])

## 重置为默认值
func reset_to_defaults() -> void:
    current_config = DEFAULT_CONFIG.duplicate()
    _apply_all_settings()
    save_config()
    settings_reset.emit()
    print("Config reset to defaults")

## 重置单个设置
func reset_setting(key: String) -> void:
    if DEFAULT_CONFIG.has(key):
        set_setting(key, DEFAULT_CONFIG[key])

## 检查配置项是否存在
func has_setting(key: String) -> bool:
    return current_config.has(key) or DEFAULT_CONFIG.has(key)

## 删除配置项
func remove_setting(key: String) -> void:
    if current_config.has(key):
        current_config.erase(key)
        config.erase_section_key(DEFAULT_SECTION, key)

## 获取所有配置
func get_all_settings() -> Dictionary:
    return current_config.duplicate()

## 获取显示相关配置
func get_display_settings() -> Dictionary:
    return {
        "fullscreen": get_setting("display_fullscreen"),
        "resolution": get_setting("display_resolution"),
        "vsync": get_setting("display_vsync"),
        "fps_limit": get_setting("display_fps_limit"),
        "show_fps": get_setting("display_show_fps")
    }

## 获取音频相关配置
func get_audio_settings() -> Dictionary:
    return {
        "master_volume": get_setting("audio_master_volume"),
        "music_volume": get_setting("audio_music_volume"),
        "sfx_volume": get_setting("audio_sfx_volume"),
        "muted": get_setting("audio_muted")
    }

## 获取游戏相关配置
func get_game_settings() -> Dictionary:
    return {
        "language": get_setting("game_language"),
        "difficulty": get_setting("game_difficulty"),
        "hints_enabled": get_setting("game_hints_enabled"),
        "tutorial_shown": get_setting("game_tutorial_shown")
    }

## 应用音频设置
func apply_audio_settings() -> void:
    var audio_settings = get_audio_settings()
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
        linear_to_db(audio_settings.master_volume))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 
        linear_to_db(audio_settings.music_volume))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), 
        linear_to_db(audio_settings.sfx_volume))
    AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), audio_settings.muted)

## 应用显示设置
func apply_display_settings() -> void:
    var display_settings = get_display_settings()
    
    # 全屏设置
    if display_settings.fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        DisplayServer.window_set_size(display_settings.resolution)
    
    # VSync设置
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if display_settings.vsync 
        else DisplayServer.VSYNC_DISABLED)

## 私有：设置默认值
func _set_defaults() -> void:
    current_config = DEFAULT_CONFIG.duplicate()

## 私有：从配置文件加载
func _load_from_config_file() -> void:
    for key in DEFAULT_CONFIG.keys():
        var value = config.get_value(DEFAULT_SECTION, key, DEFAULT_CONFIG[key])
        current_config[key] = value

## 私有：应用单个音频设置
func _apply_audio_setting(key: String, value: Variant) -> void:
    match key:
        "audio_master_volume":
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
        "audio_music_volume":
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
        "audio_sfx_volume":
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
        "audio_muted":
            AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value)

## 私有：应用单个显示设置
func _apply_display_setting(key: String, value: Variant) -> void:
    match key:
        "display_fullscreen":
            if value:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
            else:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        "display_resolution":
            if not get_setting("display_fullscreen"):
                DisplayServer.window_set_size(value)
        "display_vsync":
            DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value 
                else DisplayServer.VSYNC_DISABLED)

## 私有：应用所有设置
func _apply_all_settings() -> void:
    apply_display_settings()
    apply_audio_settings()

## 辅助函数：线性音量转分贝
func linear_to_db(linear: float) -> float:
    if linear <= 0:
        return -80.0
    return 20.0 * log(linear) / log(10)
