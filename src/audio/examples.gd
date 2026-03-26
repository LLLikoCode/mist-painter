## AudioManager 使用示例
## 展示如何在游戏中使用音效系统

class_name AudioExamples
extends Node

# ============================================
# 示例 1: 基础BGM播放
# ============================================

## 在主菜单播放BGM
func example_main_menu_bgm():
    # 播放菜单BGM，带淡入效果
    AudioManager.instance.play_bgm_path(
        "res://assets/audio/bgm/menu.ogg",
        true,   # 淡入
        true    # 循环
    )

## 停止BGM
func example_stop_bgm():
    # 淡出停止
    AudioManager.instance.stop_bgm(true)

## 切换BGM（交叉淡入淡出）
func example_switch_bgm():
    # 直接播放新BGM，会自动进行交叉淡入淡出
    AudioManager.instance.play_bgm_path(
        "res://assets/audio/bgm/combat.ogg",
        true    # 使用淡入淡出
    )

# ============================================
# 示例 2: 音效播放
# ============================================

## 播放UI音效
func example_ui_sfx():
    # 播放按钮点击音效
    AudioManager.instance.play_ui_sfx("click")
    
    # 播放确认音效
    AudioManager.instance.play_confirm_sfx()
    
    # 播放取消音效
    AudioManager.instance.play_cancel_sfx()
    
    # 播放错误音效
    AudioManager.instance.play_error_sfx()

## 播放游戏音效
func example_game_sfx():
    # 播放获得物品音效
    AudioManager.instance.play_item_get_sfx()
    
    # 播放脚步声（不同地面材质）
    AudioManager.instance.play_footstep_sfx("stone")   # 石头地面
    AudioManager.instance.play_footstep_sfx("grass")   # 草地
    AudioManager.instance.play_footstep_sfx("wood")    # 木板
    
    # 播放绘图音效
    AudioManager.instance.play_draw_sfx()
    
    # 播放擦除音效
    AudioManager.instance.play_erase_sfx()
    
    # 播放迷雾消散音效
    AudioManager.instance.play_mist_clear_sfx()
    
    # 播放谜题完成音效
    AudioManager.instance.play_puzzle_complete_sfx()

## 自定义音效播放
func example_custom_sfx():
    # 加载并播放自定义音效
    var stream = load("res://assets/audio/sfx/custom/my_sound.ogg")
    
    # 基础播放
    AudioManager.instance.play_sfx(stream)
    
    # 带音量缩放播放（50%音量）
    AudioManager.instance.play_sfx(stream, 0.5)
    
    # 带音调变化播放（升高半音）
    AudioManager.instance.play_sfx(stream, 1.0, 1.059)

## 通过路径播放音效
func example_sfx_by_path():
    AudioManager.instance.play_sfx_path(
        "res://assets/audio/sfx/game/explosion.ogg",
        0.8,    # 80%音量
        0.95    # 音调略微降低
    )

# ============================================
# 示例 3: 音量控制
# ============================================

## 设置音量
func example_set_volume():
    # 设置主音量（0.0 - 1.0）
    AudioManager.instance.set_master_volume(0.8)
    
    # 设置音乐音量
    AudioManager.instance.set_music_volume(0.6)
    
    # 设置音效音量
    AudioManager.instance.set_sfx_volume(1.0)
    
    # 设置环境音音量
    AudioManager.instance.set_ambient_volume(0.5)

## 批量设置音量
func example_set_volume_batch():
    AudioManager.instance.set_volume_settings({
        "master": 0.8,
        "music": 0.6,
        "sfx": 1.0,
        "ambient": 0.5
    })

## 获取当前音量
func example_get_volume():
    var settings = AudioManager.instance.get_volume_settings()
    print("Master: ", settings.master)
    print("Music: ", settings.music)
    print("SFX: ", settings.sfx)
    print("Ambient: ", settings.ambient)
    print("Muted: ", settings.muted)

## 静音控制
func example_mute():
    # 切换静音状态
    var is_muted = AudioManager.instance.toggle_mute()
    print("Muted: ", is_muted)
    
    # 直接设置静音
    AudioManager.instance.set_mute(true)
    
    # 取消静音
    AudioManager.instance.set_mute(false)
    
    # 检查静音状态
    if AudioManager.instance.is_muted():
        print("当前处于静音状态")

## 重置为默认音量
func example_reset_volume():
    AudioManager.instance.reset_to_default_volumes()

# ============================================
# 示例 4: 环境音
# ============================================

## 播放环境音
func example_ambient():
    # 播放洞穴环境音
    AudioManager.instance.play_ambient(
        preload("res://assets/audio/ambient/cave.ogg"),
        true,   # 淡入
        true    # 循环
    )
    
    # 停止环境音
    AudioManager.instance.stop_ambient(true)  # 淡出

# ============================================
# 示例 5: 音效预加载
# ============================================

## 预加载单个音效
func example_preload_single():
    AudioManager.instance.preload_sfx(
        "res://assets/audio/sfx/ui/click.ogg"
    )

## 批量预加载音效
func example_preload_batch():
    AudioManager.instance.preload_sfx_batch([
        "res://assets/audio/sfx/ui/click.ogg",
        "res://assets/audio/sfx/ui/confirm.ogg",
        "res://assets/audio/sfx/ui/cancel.ogg",
        "res://assets/audio/sfx/ui/error.ogg",
    ])

## 清除音效缓存
func example_clear_cache():
    AudioManager.instance.clear_sfx_cache()

# ============================================
# 示例 6: 信号监听
# ============================================

## 监听音量变化
func example_listen_volume_changes():
    # 连接音量变化信号
    AudioManager.instance.volume_changed.connect(
        func(bus_name: String, volume: float):
            print("音量变化 - 总线: ", bus_name, ", 音量: ", volume)
    )

## 监听BGM变化
func example_listen_bgm_changes():
    # BGM开始播放
    AudioManager.instance.bgm_started.connect(
        func(stream: AudioStream):
            print("BGM开始播放: ", stream.resource_path)
    )
    
    # BGM停止
    AudioManager.instance.bgm_stopped.connect(
        func():
            print("BGM已停止")
    )
    
    # BGM切换
    AudioManager.instance.bgm_changed.connect(
        func(old_stream: AudioStream, new_stream: AudioStream):
            print("BGM切换: ", old_stream, " -> ", new_stream)
    )

## 监听静音变化
func example_listen_mute():
    AudioManager.instance.mute_changed.connect(
        func(is_muted: bool):
            print("静音状态: ", is_muted)
    )

# ============================================
# 示例 7: 在UI组件中使用
# ============================================

## 带音效的按钮
class SoundButton extends Button:
    func _ready():
        pressed.connect(_on_pressed)
        mouse_entered.connect(_on_hover)
    
    func _on_pressed():
        if AudioManager.instance:
            AudioManager.instance.play_ui_sfx("click")
    
    func _on_hover():
        if AudioManager.instance:
            AudioManager.instance.play_ui_sfx("hover")

## 音量滑块
class VolumeSlider extends HSlider:
    func _ready():
        min_value = 0
        max_value = 100
        value_changed.connect(_on_value_changed)
    
    func _on_value_changed(new_value: float):
        if AudioManager.instance:
            var volume = new_value / 100.0
            AudioManager.instance.set_master_volume(volume)
            # 播放测试音效
            AudioManager.instance.play_ui_sfx("test")

# ============================================
# 示例 8: 在游戏场景中使用
# ============================================

## 场景BGM自动播放
class GameScene extends Node2D:
    @export var bgm_stream: AudioStream
    @export var ambient_stream: AudioStream
    
    func _ready():
        # 播放场景BGM
        if bgm_stream and AudioManager.instance:
            AudioManager.instance.play_bgm(bgm_stream, true)
        
        # 播放环境音
        if ambient_stream and AudioManager.instance:
            AudioManager.instance.play_ambient(ambient_stream, true)

## 可交互对象音效
class InteractableObject extends Area2D:
    @export var interact_sfx: AudioStream
    
    func interact():
        # 播放交互音效
        if interact_sfx and AudioManager.instance:
            AudioManager.instance.play_sfx(interact_sfx)
        
        # 执行交互逻辑...

## 玩家移动音效
class Player extends CharacterBody2D:
    var _last_step_time: int = 0
    var _step_interval: int = 400  # 毫秒
    
    func _physics_process(delta):
        if velocity.length() > 0:
            _play_footstep()
    
    func _play_footstep():
        var current_time = Time.get_ticks_msec()
        if current_time - _last_step_time > _step_interval:
            _last_step_time = current_time
            if AudioManager.instance:
                AudioManager.instance.play_footstep_sfx("stone")

# ============================================
# 示例 9: 与存档系统集成
# ============================================

## 保存时记录音频设置
func example_save_with_audio():
    var save_data = {
        "player": { ... },
        "settings": {
            # 从AudioManager获取当前设置
            "masterVolume": AudioManager.instance.master_volume,
            "musicVolume": AudioManager.instance.music_volume,
            "sfxVolume": AudioManager.instance.sfx_volume,
            "ambientVolume": AudioManager.instance.ambient_volume,
            "muted": AudioManager.instance.is_muted()
        }
    }
    # 保存save_data...

## 加载时恢复音频设置
func example_load_with_audio(save_data: Dictionary):
    if save_data.has("settings"):
        var audio_settings = save_data.settings
        
        if audio_settings.has("masterVolume"):
            AudioManager.instance.set_master_volume(audio_settings.masterVolume)
        if audio_settings.has("musicVolume"):
            AudioManager.instance.set_music_volume(audio_settings.musicVolume)
        if audio_settings.has("sfxVolume"):
            AudioManager.instance.set_sfx_volume(audio_settings.sfxVolume)
        if audio_settings.has("ambientVolume"):
            AudioManager.instance.set_ambient_volume(audio_settings.ambientVolume)
        if audio_settings.has("muted"):
            AudioManager.instance.set_mute(audio_settings.muted)

# ============================================
# 示例 10: 调试与监控
# ============================================

## 获取音频系统状态
func example_get_status():
    var status = AudioManager.instance.get_status()
    
    print("=== 音频系统状态 ===")
    print("BGM播放中: ", status.bgm_playing)
    print("当前BGM: ", status.current_bgm)
    print("环境音播放中: ", status.ambient_playing)
    print("活跃音效数: ", status.active_sfx_count)
    print("可用音效通道: ", status.available_sfx_channels)
    print("音效缓存大小: ", status.sfx_cache_size)
    print("静音状态: ", status.is_muted)

## 停止所有音效（调试用）
func example_stop_all_sfx():
    AudioManager.instance.stop_all_sfx()

## 快速静音切换（调试用）
func example_debug_mute():
    var is_muted = AudioManager.instance.toggle_mute()
    print("静音状态: ", is_muted)