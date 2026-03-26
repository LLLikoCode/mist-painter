## AudioSettingsScreen
## 音频设置界面
## 提供音量调节、静音切换等音频设置功能

class_name AudioSettingsScreen
extends Control

# ============================================
# 导出变量
# ============================================

@export_group("UI References")
@export var master_slider: UISlider
@export var music_slider: UISlider
@export var sfx_slider: UISlider
@export var ambient_slider: UISlider
@export var mute_button: UIButton
@export var reset_button: UIButton
@export var back_button: UIButton
@export var test_sfx_button: UIButton

@export_group("Labels")
@export var master_value_label: Label
@export var music_value_label: Label
@export var sfx_value_label: Label
@export var ambient_value_label: Label

# ============================================
# 内部变量
# ============================================

var _is_initializing: bool = false

# ============================================
# 生命周期
# ============================================

func _ready():
    _is_initializing = true
    
    # 初始化UI组件
    _init_sliders()
    _init_buttons()
    
    # 加载当前设置
    _load_settings()
    
    # 连接信号
    _connect_signals()
    
    _is_initializing = false
    
    print("AudioSettingsScreen initialized")

func _enter_tree():
    # 确保AudioManager已初始化
    if AudioManager.instance == null:
        push_warning("AudioManager not initialized")

# ============================================
# 初始化方法
# ============================================

func _init_sliders() -> void:
    # 主音量滑块
    if master_slider:
        master_slider.min_value = 0
        master_slider.max_value = 100
        master_slider.step = 1
        master_slider.set_volume_mode()
        master_slider.value_label_format = "%d%%"
    
    # 音乐音量滑块
    if music_slider:
        music_slider.min_value = 0
        music_slider.max_value = 100
        music_slider.step = 1
        music_slider.set_volume_mode()
        music_slider.value_label_format = "%d%%"
    
    # 音效音量滑块
    if sfx_slider:
        sfx_slider.min_value = 0
        sfx_slider.max_value = 100
        sfx_slider.step = 1
        sfx_slider.set_volume_mode()
        sfx_slider.value_label_format = "%d%%"
    
    # 环境音音量滑块
    if ambient_slider:
        ambient_slider.min_value = 0
        ambient_slider.max_value = 100
        ambient_slider.step = 1
        ambient_slider.set_volume_mode()
        ambient_slider.value_label_format = "%d%%"

func _init_buttons() -> void:
    # 静音按钮
    if mute_button:
        mute_button.text = tr("audio_mute")
        mute_button.toggle_mode = true
    
    # 重置按钮
    if reset_button:
        reset_button.text = tr("audio_reset")
    
    # 返回按钮
    if back_button:
        back_button.text = tr("common_back")
    
    # 测试音效按钮
    if test_sfx_button:
        test_sfx_button.text = tr("audio_test_sfx")

func _connect_signals() -> void:
    # 滑块信号
    if master_slider:
        master_slider.value_changed.connect(_on_master_volume_changed)
    
    if music_slider:
        music_slider.value_changed.connect(_on_music_volume_changed)
    
    if sfx_slider:
        sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    
    if ambient_slider:
        ambient_slider.value_changed.connect(_on_ambient_volume_changed)
    
    # 按钮信号
    if mute_button:
        mute_button.toggled.connect(_on_mute_toggled)
    
    if reset_button:
        reset_button.pressed.connect(_on_reset_pressed)
    
    if back_button:
        back_button.pressed.connect(_on_back_pressed)
    
    if test_sfx_button:
        test_sfx_button.pressed.connect(_on_test_sfx_pressed)
    
    # AudioManager信号
    if AudioManager.instance:
        AudioManager.instance.volume_changed.connect(_on_volume_changed_externally)
        AudioManager.instance.mute_changed.connect(_on_mute_changed_externally)

# ============================================
# 设置加载与保存
# ============================================

func _load_settings() -> void:
    if AudioManager.instance == null:
        return
    
    var settings = AudioManager.instance.get_volume_settings()
    
    # 设置滑块值
    if master_slider:
        master_slider.value = settings.master * 100
        _update_value_label(master_value_label, settings.master)
    
    if music_slider:
        music_slider.value = settings.music * 100
        _update_value_label(music_value_label, settings.music)
    
    if sfx_slider:
        sfx_slider.value = settings.sfx * 100
        _update_value_label(sfx_value_label, settings.sfx)
    
    if ambient_slider:
        ambient_slider.value = settings.ambient * 100
        _update_value_label(ambient_value_label, settings.ambient)
    
    # 设置静音按钮
    if mute_button:
        mute_button.set_pressed_no_signal(settings.muted)
        _update_mute_button_text(settings.muted)

func _update_value_label(label: Label, volume: float) -> void:
    if label:
        label.text = "%d%%" % int(volume * 100)

func _update_mute_button_text(is_muted: bool) -> void:
    if mute_button:
        mute_button.text = tr("audio_unmute") if is_muted else tr("audio_mute")

# ============================================
# 信号处理
# ============================================

func _on_master_volume_changed(value: float) -> void:
    if _is_initializing:
        return
    
    var volume = value / 100.0
    if AudioManager.instance:
        AudioManager.instance.set_master_volume(volume)
    
    _update_value_label(master_value_label, volume)

func _on_music_volume_changed(value: float) -> void:
    if _is_initializing:
        return
    
    var volume = value / 100.0
    if AudioManager.instance:
        AudioManager.instance.set_music_volume(volume)
    
    _update_value_label(music_value_label, volume)

func _on_sfx_volume_changed(value: float) -> void:
    if _is_initializing:
        return
    
    var volume = value / 100.0
    if AudioManager.instance:
        AudioManager.instance.set_sfx_volume(volume)
    
    _update_value_label(sfx_value_label, volume)

func _on_ambient_volume_changed(value: float) -> void:
    if _is_initializing:
        return
    
    var volume = value / 100.0
    if AudioManager.instance:
        AudioManager.instance.set_ambient_volume(volume)
    
    _update_value_label(ambient_value_label, volume)

func _on_mute_toggled(pressed: bool) -> void:
    if AudioManager.instance:
        AudioManager.instance.set_mute(pressed)
    
    _update_mute_button_text(pressed)

func _on_reset_pressed() -> void:
    if AudioManager.instance:
        AudioManager.instance.reset_to_default_volumes()
        _load_settings()
    
    # 播放确认音效
    if AudioManager.instance:
        AudioManager.instance.play_confirm_sfx()

func _on_back_pressed() -> void:
    # 保存设置并返回
    _save_and_exit()

func _on_test_sfx_pressed() -> void:
    if AudioManager.instance:
        AudioManager.instance.play_ui_sfx("test")

func _on_volume_changed_externally(bus_name: String, volume: float) -> void:
    # 外部音量变化时更新UI
    match bus_name:
        "Master":
            if master_slider and not master_slider.has_focus():
                master_slider.value = volume * 100
            _update_value_label(master_value_label, volume)
        "Music":
            if music_slider and not music_slider.has_focus():
                music_slider.value = volume * 100
            _update_value_label(music_value_label, volume)
        "SFX":
            if sfx_slider and not sfx_slider.has_focus():
                sfx_slider.value = volume * 100
            _update_value_label(sfx_value_label, volume)
        "Ambient":
            if ambient_slider and not ambient_slider.has_focus():
                ambient_slider.value = volume * 100
            _update_value_label(ambient_value_label, volume)

func _on_mute_changed_externally(is_muted: bool) -> void:
    # 外部静音状态变化时更新UI
    if mute_button:
        mute_button.set_pressed_no_signal(is_muted)
        _update_mute_button_text(is_muted)

# ============================================
# 保存与退出
# ============================================

func _save_and_exit() -> void:
    # 设置会自动保存到ConfigManager，这里只需要返回
    if UIManager.instance:
        UIManager.instance.go_back()

# ============================================
# 输入处理
# ============================================

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _save_and_exit()
        get_viewport().set_input_as_handled()

# ============================================
# 公共方法
# ============================================

## 刷新设置显示
func refresh() -> void:
    _load_settings()

## 应用设置
func apply_settings() -> void:
    # 设置已经实时应用，这里可以添加额外的确认逻辑
    if AudioManager.instance:
        AudioManager.instance._save_volume_settings()
