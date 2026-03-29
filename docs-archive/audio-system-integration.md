# 音效系统集成方案

## 概述

本文档描述音效系统（AudioManager）与迷雾绘者游戏其他系统的集成方案。

## 1. 与存档系统集成

### 1.1 存档数据中的音频设置

音频设置已包含在 `SaveData` 的 `settings` 字段中：

```gdscript
# SaveData.settings 中的音频相关字段
{
    "masterVolume": 1.0,    # 主音量 (0.0 - 1.0)
    "musicVolume": 0.8,     # 音乐音量 (0.0 - 1.0)
    "sfxVolume": 1.0,       # 音效音量 (0.0 - 1.0)
    "ambientVolume": 0.6,   # 环境音音量 (0.0 - 1.0)
    "muted": false          # 静音状态
}
```

### 1.2 集成点

#### 存档加载时

```gdscript
# SaveManager.load() 中
func load(slot_id: int) -> SaveData:
    var data = ... # 加载存档数据
    
    # 恢复音频设置
    if AudioManager.instance and data.settings:
        AudioManager.instance.set_master_volume(data.settings.masterVolume)
        AudioManager.instance.set_music_volume(data.settings.musicVolume)
        AudioManager.instance.set_sfx_volume(data.settings.sfxVolume)
        AudioManager.instance.set_ambient_volume(data.settings.ambientVolume)
        AudioManager.instance.set_mute(data.settings.muted)
```

#### 存档保存时

```gdscript
# SaveManager.save() 中
func save(slot_id: int, data: SaveData) -> void:
    # 获取当前音频设置
    if AudioManager.instance:
        var audio_settings = AudioManager.instance.get_volume_settings()
        data.settings.masterVolume = audio_settings.master
        data.settings.musicVolume = audio_settings.music
        data.settings.sfxVolume = audio_settings.sfx
        data.settings.ambientVolume = audio_settings.ambient
        data.settings.muted = audio_settings.muted
    
    # 继续保存...
```

### 1.3 配置持久化

音频设置同时保存在：
1. **存档文件中** - 随游戏进度保存
2. **独立配置文件** (`user://config.cfg`) - 全局设置，通过 `ConfigManager` 管理

优先级：存档中的设置 > 全局配置 > 默认值

## 2. 与UI系统集成

### 2.1 音量调节界面

`AudioSettingsScreen` 提供了完整的音量调节UI：

- **主音量滑块** - 控制整体音量
- **音乐音量滑块** - 控制BGM音量
- **音效音量滑块** - 控制SFX音量
- **环境音音量滑块** - 控制环境音音量
- **静音按钮** - 快速静音/取消静音
- **重置按钮** - 恢复默认音量
- **测试音效按钮** - 测试当前音效音量

### 2.2 UI组件集成

#### 在设置菜单中添加音频设置入口

```gdscript
# SettingsMenu.gd
func _ready():
    # 添加音频设置按钮
    var audio_button = UIButton.new()
    audio_button.text = tr("settings_audio")
    audio_button.pressed.connect(_on_audio_settings_pressed)
    add_child(audio_button)

func _on_audio_settings_pressed() -> void:
    UIManager.instance.open_screen(UIManager.UIScreen.SETTINGS_AUDIO)
```

#### 在UIManager中注册音频设置屏幕

```gdscript
# UIManager.gd - _register_screens() 方法中
func _register_screens() -> void:
    screens[UIScreen.SETTINGS_MENU] = "res://src/ui/screens/SettingsMenu.tscn"
    screens[UIScreen.SETTINGS_AUDIO] = "res://src/audio/AudioSettingsScreen.tscn"  # 新增
```

### 2.3 UI音效反馈

所有UI交互都应播放音效：

```gdscript
# UIButton.gd 示例
func _on_pressed() -> void:
    if AudioManager.instance:
        AudioManager.instance.play_ui_sfx("click")
    # 执行按钮逻辑...

func _on_hover() -> void:
    if AudioManager.instance:
        AudioManager.instance.play_ui_sfx("hover")
```

### 2.4 实时预览

音量调节时实时应用：

```gdscript
# AudioSettingsScreen.gd
func _on_sfx_volume_changed(value: float) -> void:
    var volume = value / 100.0
    if AudioManager.instance:
        AudioManager.instance.set_sfx_volume(volume)
    # 播放测试音效让用户听到变化
    AudioManager.instance.play_ui_sfx("test")
```

## 3. 与游戏事件系统集成

### 3.1 EventBus 音频事件

AudioManager 监听以下事件：

```gdscript
# EventBus.EventType 中定义的音频相关事件
enum EventType {
    MUSIC_CHANGED,    # 音乐切换
    SFX_PLAYED,       # 音效播放
    AUDIO_MUTED,      # 静音切换
}
```

### 3.2 游戏事件触发音效

```gdscript
# 示例：玩家移动时播放脚步声
func _on_player_moved(data: Dictionary) -> void:
    var surface = data.get("surface", "stone")
    if AudioManager.instance:
        AudioManager.instance.play_footstep_sfx(surface)

# 示例：获得物品时播放音效
func _on_item_acquired(data: Dictionary) -> void:
    if AudioManager.instance:
        AudioManager.instance.play_item_get_sfx()
    
    # 同时显示UI提示
    UIManager.instance.show_toast(tr("item_acquired"))

# 示例：谜题完成时播放音效
func _on_puzzle_solved(data: Dictionary) -> void:
    if AudioManager.instance:
        AudioManager.instance.play_puzzle_complete_sfx()
```

### 3.3 场景切换时的音乐切换

```gdscript
# SceneManager.gd
func change_scene(scene_path: String) -> void:
    # 根据场景类型切换BGM
    match _get_scene_type(scene_path):
        SceneType.MAIN_MENU:
            AudioManager.instance.play_bgm_path("res://assets/audio/bgm/menu.ogg")
        SceneType.EXPLORATION:
            AudioManager.instance.play_bgm_path("res://assets/audio/bgm/exploration.ogg", true)
        SceneType.COMBAT:
            AudioManager.instance.play_bgm_path("res://assets/audio/bgm/combat.ogg", true)
        SceneType.PUZZLE:
            AudioManager.instance.play_bgm_path("res://assets/audio/bgm/puzzle.ogg", true)
    
    # 执行场景切换...
```

## 4. 与游戏状态系统集成

### 4.1 暂停状态

```gdscript
# GameStateManager.gd
func set_paused(paused: bool) -> void:
    _paused = paused
    
    if AudioManager.instance:
        if paused:
            # 暂停时降低BGM音量
            AudioManager.instance.pause_bgm()
            # 或者淡出BGM
            # AudioManager.instance.stop_bgm(true)
        else:
            AudioManager.instance.resume_bgm()
```

### 4.2 游戏结束状态

```gdscript
# GameStateManager.gd - 游戏结束时
func _on_game_over() -> void:
    if AudioManager.instance:
        # 停止当前BGM
        AudioManager.instance.stop_bgm(true)
        # 播放游戏结束音乐
        AudioManager.instance.play_bgm_path("res://assets/audio/bgm/game_over.ogg")
```

## 5. 资源管理集成

### 5.1 音频资源路径规范

```
assets/
└── audio/
    ├── bgm/              # 背景音乐
    │   ├── menu.ogg
    │   ├── exploration.ogg
    │   ├── combat.ogg
    │   ├── puzzle.ogg
    │   └── game_over.ogg
    ├── sfx/              # 音效
    │   ├── ui/           # UI音效
    │   │   ├── click.ogg
    │   │   ├── hover.ogg
    │   │   ├── confirm.ogg
    │   │   ├── cancel.ogg
    │   │   └── error.ogg
    │   └── game/         # 游戏音效
    │       ├── footstep_stone.ogg
    │       ├── footstep_grass.ogg
    │       ├── item_get.ogg
    │       ├── draw.ogg
    │       ├── erase.ogg
    │       ├── mist_clear.ogg
    │       ├── puzzle_complete.ogg
    │       └── layer_change.ogg
    └── ambient/          # 环境音
        ├── cave.ogg
        ├── wind.ogg
        └── water.ogg
```

### 5.2 预加载策略

```gdscript
# 在场景加载时预加载常用音效
func _ready():
    # 预加载UI音效
    AudioManager.instance.preload_sfx_batch([
        "res://assets/audio/sfx/ui/click.ogg",
        "res://assets/audio/sfx/ui/confirm.ogg",
        "res://assets/audio/sfx/ui/cancel.ogg",
    ])
```

## 6. Godot音频总线配置

### 6.1 推荐的总线设置

在 Godot 编辑器中配置音频总线：

```
Master (主总线)
├── Music (音乐总线)
├── SFX (音效总线)
└── Ambient (环境音总线)
```

### 6.2 总线效果器（可选）

可以为不同总线添加效果器：

- **Music**: 低通滤波器（暂停时）
- **SFX**: 轻微压缩器
- **Ambient**: 混响效果

## 7. 性能优化建议

### 7.1 音效缓存

AudioManager 内置 LRU 缓存机制：

```gdscript
# 自动缓存最近使用的50个音效
const MAX_SFX_CACHE_SIZE = 50
```

### 7.2 播放器池

使用对象池避免频繁创建销毁：

```gdscript
# 16个SFX播放器循环使用
const MAX_SFX_CHANNELS = 16
```

### 7.3 懒加载

音效按需加载，首次使用时缓存：

```gdscript
# 首次播放时加载并缓存
var stream = _load_sfx(path)  # 自动缓存
```

## 8. 调试与监控

### 8.1 调试信息

```gdscript
# 获取音频系统状态
var status = AudioManager.instance.get_status()
print("BGM Playing: ", status.bgm_playing)
print("Active SFX: ", status.active_sfx_count)
print("SFX Cache: ", status.sfx_cache_size)
```

### 8.2 调试快捷键

```gdscript
# _input 中添加调试快捷键
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_mute"):
        AudioManager.instance.toggle_mute()
    if event.is_action_pressed("debug_stop_sfx"):
        AudioManager.instance.stop_all_sfx()
```

## 9. 平台适配

### 9.1 移动端适配

```gdscript
# 检测平台并调整
func _ready():
    if OS.get_name() in ["Android", "iOS"]:
        # 移动端减少同时播放的音效数
        MAX_SFX_CHANNELS = 8
        # 降低默认音量
        DEFAULT_MASTER_VOLUME = 0.8
```

---

## 10. 使用示例

### 10.1 基本使用

```gdscript
# 播放背景音乐
AudioManager.instance.play_bgm_path("res://assets/audio/bgm/menu.ogg")

# 播放音效
AudioManager.instance.play_sfx_path("res://assets/audio/sfx/ui/click.ogg")

# 调节音量
AudioManager.instance.set_master_volume(0.8)
AudioManager.instance.set_sfx_volume(0.5)

# 静音
AudioManager.instance.toggle_mute()
```

### 10.2 在场景中自动播放BGM

```gdscript
# ExplorationScene.gd
extends Node2D

@export var bgm_stream: AudioStream

func _ready():
    if bgm_stream and AudioManager.instance:
        AudioManager.instance.play_bgm(bgm_stream, true)
```

### 10.3 触发式音效

```gdscript
# Door.gd - 门交互时播放音效
extends Area2D

func interact():
    # 播放开门音效
    AudioManager.instance.play_sfx_path("res://assets/audio/sfx/game/door_open.ogg")
    # 执行开门动画...
```

### 10.4 3D音效（位置音效）

```gdscript
# 如果需要3D音效，使用AudioStreamPlayer3D
var player = AudioStreamPlayer3D.new()
player.stream = preload("res://assets/audio/sfx/game/ambient.ogg")
player.position = global_position
add_child(player)
player.play()
```