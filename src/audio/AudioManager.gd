## AudioManager
## 音效管理器
## 负责管理背景音乐(BGM)、音效(SFX)的播放、音量控制和淡入淡出效果

class_name AudioManager
extends Node

# ============================================
# 常量定义
# ============================================

## 音频总线名称
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"
const BUS_AMBIENT = "Ambient"

## 默认音量值
const DEFAULT_MASTER_VOLUME = 1.0
const DEFAULT_MUSIC_VOLUME = 0.8
const DEFAULT_SFX_VOLUME = 1.0
const DEFAULT_AMBIENT_VOLUME = 0.6

## 淡入淡出默认时长
const DEFAULT_FADE_DURATION = 1.0
const DEFAULT_CROSSFADE_DURATION = 2.0

## 最大同时播放音效数
const MAX_SFX_CHANNELS = 16

## 音效缓存最大数量
const MAX_SFX_CACHE_SIZE = 50

# ============================================
# 导出变量
# ============================================

@export_group("Volume Settings")
@export var master_volume: float = DEFAULT_MASTER_VOLUME:
	set = set_master_volume
@export var music_volume: float = DEFAULT_MUSIC_VOLUME:
	set = set_music_volume
@export var sfx_volume: float = DEFAULT_SFX_VOLUME:
	set = set_sfx_volume
@export var ambient_volume: float = DEFAULT_AMBIENT_VOLUME:
	set = set_ambient_volume

@export_group("Fade Settings")
@export var fade_duration: float = DEFAULT_FADE_DURATION
@export var crossfade_duration: float = DEFAULT_CROSSFADE_DURATION

# ============================================
# 内部变量
# ============================================

## 单例实例
static var instance: AudioManager = null

## BGM播放器
var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween
var _current_bgm: AudioStream = null
var _pending_bgm: AudioStream = null

## 环境音播放器
var _ambient_player: AudioStreamPlayer
var _ambient_tween: Tween

## SFX播放器池
var _sfx_players: Array[AudioStreamPlayer] = []
var _available_sfx_players: Array[AudioStreamPlayer] = []

## 音效缓存
var _sfx_cache: Dictionary = {}  # { path: AudioStream }
var _cache_access_order: Array[String] = []  # LRU缓存访问顺序

## 静音状态
var _is_muted: bool = false
var _pre_mute_volumes: Dictionary = {}

## 音频总线索引
var _bus_indices: Dictionary = {}

## 播放中的音效
var _playing_sfx: Dictionary = {}  # { player: { stream, start_time } }

# ============================================
# 信号
# ============================================

signal bgm_started(stream: AudioStream)
signal bgm_stopped
signal bgm_changed(old_stream: AudioStream, new_stream: AudioStream)
signal sfx_played(stream: AudioStream, player: AudioStreamPlayer)
signal volume_changed(bus_name: String, volume: float)
signal mute_changed(is_muted: bool)
signal fade_completed(type: String)

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
	
	# 初始化音频总线索引
	_init_bus_indices()
	
	# 初始化BGM播放器
	_init_bgm_player()
	
	# 初始化环境音播放器
	_init_ambient_player()
	
	# 初始化SFX播放器池
	_init_sfx_pool()
	
	# 从配置加载音量设置
	_load_volume_settings()
	
	print("AudioManager initialized")

func _exit_tree():
	if instance == self:
		instance = null

# ============================================
# 初始化方法
# ============================================

## 初始化音频总线索引
func _init_bus_indices() -> void:
	_bus_indices[BUS_MASTER] = AudioServer.get_bus_index(BUS_MASTER)
	_bus_indices[BUS_MUSIC] = AudioServer.get_bus_index(BUS_MUSIC)
	_bus_indices[BUS_SFX] = AudioServer.get_bus_index(BUS_SFX)
	_bus_indices[BUS_AMBIENT] = AudioServer.get_bus_index(BUS_AMBIENT)

## 初始化BGM播放器
func _init_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = BUS_MUSIC
	add_child(_bgm_player)
	
	_bgm_player.finished.connect(_on_bgm_finished)

## 初始化环境音播放器
func _init_ambient_player() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)

## 初始化SFX播放器池
func _init_sfx_pool() -> void:
	for i in range(MAX_SFX_CHANNELS):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = BUS_SFX
		add_child(player)
		
		_sfx_players.append(player)
		_available_sfx_players.append(player)
		
		player.finished.connect(_on_sfx_finished.bind(player))

## 从配置加载音量设置
func _load_volume_settings() -> void:
	if ConfigManager.instance:
		master_volume = ConfigManager.instance.get_setting("audio_master_volume", DEFAULT_MASTER_VOLUME)
		music_volume = ConfigManager.instance.get_setting("audio_music_volume", DEFAULT_MUSIC_VOLUME)
		sfx_volume = ConfigManager.instance.get_setting("audio_sfx_volume", DEFAULT_SFX_VOLUME)
		_is_muted = ConfigManager.instance.get_setting("audio_muted", false)
		
		_apply_volumes()

# ============================================
# BGM 控制
# ============================================

## 播放背景音乐
func play_bgm(stream: AudioStream, fade_in: bool = true, loop: bool = true) -> void:
	if stream == null:
		return
	
	# 如果正在播放相同的音乐，不重复播放
	if _current_bgm == stream and _bgm_player.playing:
		return
	
	var old_bgm = _current_bgm
	_current_bgm = stream
	_pending_bgm = stream
	
	# 设置循环
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop
	
	if fade_in and _bgm_player.playing:
		# 交叉淡入淡出
		_crossfade_to(stream)
	else:
		# 直接播放
		_bgm_player.stream = stream
		_bgm_player.volume_db = linear_to_db(music_volume) if not fade_in else -80.0
		_bgm_player.play()
		
		if fade_in:
			_fade_bgm_in()
	
	bgm_changed.emit(old_bgm, stream)
	bgm_started.emit(stream)

## 播放背景音乐（通过路径）
func play_bgm_path(path: String, fade_in: bool = true, loop: bool = true) -> void:
	var stream = load(path) as AudioStream
	if stream:
		play_bgm(stream, fade_in, loop)
	else:
		push_error("Failed to load BGM: %s" % path)

## 停止背景音乐
func stop_bgm(fade_out: bool = true) -> void:
	if not _bgm_player.playing:
		return
	
	if fade_out:
		_fade_bgm_out(true)
	else:
		_bgm_player.stop()
		_current_bgm = null
		bgm_stopped.emit()

## 暂停背景音乐
func pause_bgm() -> void:
	if _bgm_player.playing:
		_bgm_player.stream_paused = true

## 恢复背景音乐
func resume_bgm() -> void:
	if _bgm_player.stream_paused:
		_bgm_player.stream_paused = false

## 获取当前BGM
func get_current_bgm() -> AudioStream:
	return _current_bgm

## BGM淡入
func _fade_bgm_in(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	
	_bgm_tween = create_tween()
	_bgm_tween.set_ease(Tween.EASE_OUT)
	_bgm_tween.set_trans(Tween.TRANS_QUAD)
	
	var target_volume = linear_to_db(music_volume if not _is_muted else 0.0)
	_bgm_tween.tween_method(_set_bgm_volume_db, -80.0, target_volume, duration)
	_bgm_tween.finished.connect(func(): fade_completed.emit("bgm_in"), CONNECT_ONE_SHOT)

## BGM淡出
func _fade_bgm_out(stop_after: bool = false, duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	
	_bgm_tween = create_tween()
	_bgm_tween.set_ease(Tween.EASE_IN)
	_bgm_tween.set_trans(Tween.TRANS_QUAD)
	
	var current_volume = _bgm_player.volume_db
	_bgm_tween.tween_method(_set_bgm_volume_db, current_volume, -80.0, duration)
	
	if stop_after:
		_bgm_tween.finished.connect(func():
			_bgm_player.stop()
			_current_bgm = null
			bgm_stopped.emit()
			fade_completed.emit("bgm_out")
		, CONNECT_ONE_SHOT)
	else:
		_bgm_tween.finished.connect(func(): fade_completed.emit("bgm_out"), CONNECT_ONE_SHOT)

## 交叉淡入淡出
func _crossfade_to(new_stream: AudioStream, duration: float = -1.0) -> void:
	if duration < 0:
		duration = crossfade_duration
	
	# 创建临时播放器用于旧音乐
	var old_player = AudioStreamPlayer.new()
	old_player.stream = _bgm_player.stream
	old_player.volume_db = _bgm_player.volume_db
	old_player.bus = BUS_MUSIC
	old_player.play(_bgm_player.get_playback_position())
	add_child(old_player)
	
	# 设置新音乐
	_bgm_player.stream = new_stream
	_bgm_player.volume_db = -80.0
	_bgm_player.play()
	
	# 淡出旧音乐
	var old_tween = create_tween()
	old_tween.set_ease(Tween.EASE_IN)
	old_tween.set_trans(Tween.TRANS_QUAD)
	old_tween.tween_method(func(v): old_player.volume_db = v, old_player.volume_db, -80.0, duration)
	old_tween.finished.connect(func(): old_player.queue_free(), CONNECT_ONE_SHOT)
	
	# 淡入新音乐
	_fade_bgm_in(duration)

## 设置BGM音量（dB）
func _set_bgm_volume_db(volume_db: float) -> void:
	_bgm_player.volume_db = volume_db

## BGM播放完成回调
func _on_bgm_finished() -> void:
	if _current_bgm is AudioStreamOggVorbis or _current_bgm is AudioStreamMP3:
		if _current_bgm.loop:
			_bgm_player.play()
		else:
			bgm_stopped.emit()

# ============================================
# SFX 控制
# ============================================

## 播放音效
func play_sfx(stream: AudioStream, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	
	if _is_muted:
		return null
	
	# 获取可用播放器
	var player = _get_available_sfx_player()
	if player == null:
		# 如果没有可用播放器，尝试找一个音量最小的替换
		player = _find_quietest_sfx_player()
		if player == null:
			return null
	
	# 设置音效参数
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.pitch_scale = pitch_scale
	
	# 播放
	player.play()
	
	# 记录播放信息
	_playing_sfx[player] = {
		"stream": stream,
		"start_time": Time.get_ticks_msec()
	}
	
	sfx_played.emit(stream, player)
	return player

## 播放音效（通过路径）
func play_sfx_path(path: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	var stream = _load_sfx(path)
	if stream:
		return play_sfx(stream, volume_scale, pitch_scale)
	return null

## 预加载音效
func preload_sfx(path: String) -> void:
	_load_sfx(path)

## 批量预加载音效
func preload_sfx_batch(paths: Array[String]) -> void:
	for path in paths:
		preload_sfx(path)

## 加载音效（带缓存）
func _load_sfx(path: String) -> AudioStream:
	# 检查缓存
	if _sfx_cache.has(path):
		# 更新LRU顺序
		_update_cache_lru(path)
		return _sfx_cache[path]
	
	# 加载资源
	var stream = load(path) as AudioStream
	if stream:
		# 添加到缓存
		_add_to_cache(path, stream)
		return stream
	else:
		push_error("Failed to load SFX: %s" % path)
		return null

## 添加到缓存
func _add_to_cache(path: String, stream: AudioStream) -> void:
	# 检查缓存是否已满
	if _sfx_cache.size() >= MAX_SFX_CACHE_SIZE:
		# 移除最久未使用的
		var oldest = _cache_access_order.pop_front()
		_sfx_cache.erase(oldest)
	
	_sfx_cache[path] = stream
	_cache_access_order.append(path)

## 更新缓存LRU顺序
func _update_cache_lru(path: String) -> void:
	var index = _cache_access_order.find(path)
	if index >= 0:
		_cache_access_order.remove_at(index)
		_cache_access_order.append(path)

## 清除音效缓存
func clear_sfx_cache() -> void:
	_sfx_cache.clear()
	_cache_access_order.clear()

## 获取可用SFX播放器
func _get_available_sfx_player() -> AudioStreamPlayer:
	if _available_sfx_players.size() > 0:
		return _available_sfx_players.pop_back()
	return null

## 找到音量最小的SFX播放器（用于替换）
func _find_quietest_sfx_player() -> AudioStreamPlayer:
	var quietest: AudioStreamPlayer = null
	var min_volume = INF
	
	for player in _sfx_players:
		if player.playing and player.volume_db < min_volume:
			min_volume = player.volume_db
			quietest = player
	
	return quietest

## SFX播放完成回调
func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_playing_sfx.erase(player)
	_available_sfx_players.append(player)

## 停止所有音效
func stop_all_sfx() -> void:
	for player in _sfx_players:
		if player.playing:
			player.stop()
	
	_playing_sfx.clear()
	_available_sfx_players.clear()
	_available_sfx_players.append_array(_sfx_players)

# ============================================
# 环境音控制
# ============================================

## 播放环境音
func play_ambient(stream: AudioStream, fade_in: bool = true, loop: bool = true) -> void:
	if stream == null:
		return
	
	# 设置循环
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop
	
	_ambient_player.stream = stream
	
	if fade_in:
		_ambient_player.volume_db = -80.0
		_ambient_player.play()
		_fade_ambient_in()
	else:
		_ambient_player.volume_db = linear_to_db(ambient_volume)
		_ambient_player.play()

## 停止环境音
func stop_ambient(fade_out: bool = true) -> void:
	if not _ambient_player.playing:
		return
	
	if fade_out:
		_fade_ambient_out(true)
	else:
		_ambient_player.stop()

## 环境音淡入
func _fade_ambient_in(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	
	_ambient_tween = create_tween()
	_ambient_tween.set_ease(Tween.EASE_OUT)
	_ambient_tween.set_trans(Tween.TRANS_QUAD)
	
	var target_volume = linear_to_db(ambient_volume if not _is_muted else 0.0)
	_ambient_tween.tween_method(func(v): _ambient_player.volume_db = v, -80.0, target_volume, duration)

## 环境音淡出
func _fade_ambient_out(stop_after: bool = false, duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	
	_ambient_tween = create_tween()
	_ambient_tween.set_ease(Tween.EASE_IN)
	_ambient_tween.set_trans(Tween.TRANS_QUAD)
	
	var current_volume = _ambient_player.volume_db
	_ambient_tween.tween_method(func(v): _ambient_player.volume_db = v, current_volume, -80.0, duration)
	
	if stop_after:
		_ambient_tween.finished.connect(func(): _ambient_player.stop(), CONNECT_ONE_SHOT)

# ============================================
# 音量控制
# ============================================

## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_MASTER, master_volume)
	volume_changed.emit(BUS_MASTER, master_volume)
	_save_volume_settings()

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	volume_changed.emit(BUS_MUSIC, music_volume)
	_save_volume_settings()

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	volume_changed.emit(BUS_SFX, sfx_volume)
	_save_volume_settings()

## 设置环境音音量
func set_ambient_volume(volume: float) -> void:
	ambient_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_AMBIENT, ambient_volume)
	volume_changed.emit(BUS_AMBIENT, ambient_volume)
	_save_volume_settings()

## 应用总线音量
func _apply_bus_volume(bus_name: String, volume: float) -> void:
	if _is_muted and bus_name == BUS_MASTER:
		volume = 0.0
	
	var bus_idx = _bus_indices.get(bus_name, -1)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))

## 应用所有音量
func _apply_volumes() -> void:
	_apply_bus_volume(BUS_MASTER, master_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_apply_bus_volume(BUS_AMBIENT, ambient_volume)
	
	# 设置静音状态
	AudioServer.set_bus_mute(_bus_indices[BUS_MASTER], _is_muted)

## 保存音量设置
func _save_volume_settings() -> void:
	if ConfigManager.instance:
		ConfigManager.instance.set_setting("audio_master_volume", master_volume)
		ConfigManager.instance.set_setting("audio_music_volume", music_volume)
		ConfigManager.instance.set_setting("audio_sfx_volume", sfx_volume)
		ConfigManager.instance.set_setting("audio_muted", _is_muted)

# ============================================
# 静音控制
# ============================================

## 切换静音
func toggle_mute() -> bool:
	set_mute(not _is_muted)
	return _is_muted

## 设置静音状态
func set_mute(muted: bool) -> void:
	if _is_muted == muted:
		return
	
	_is_muted = muted
	
	if muted:
		# 保存当前音量并静音
		_pre_mute_volumes = {
			BUS_MASTER: master_volume,
		}
		AudioServer.set_bus_mute(_bus_indices[BUS_MASTER], true)
	else:
		# 恢复音量
		AudioServer.set_bus_mute(_bus_indices[BUS_MASTER], false)
	
	mute_changed.emit(_is_muted)
	_save_volume_settings()

## 获取静音状态
func is_muted() -> bool:
	return _is_muted

# ============================================
# 便捷方法
# ============================================

## 播放UI音效
func play_ui_sfx(sfx_name: String) -> AudioStreamPlayer:
	var path = "res://assets/audio/sfx/ui/%s.ogg" % sfx_name
	return play_sfx_path(path)

## 播放交互音效
func play_interact_sfx() -> AudioStreamPlayer:
	return play_ui_sfx("click")

## 播放确认音效
func play_confirm_sfx() -> AudioStreamPlayer:
	return play_ui_sfx("confirm")

## 播放取消音效
func play_cancel_sfx() -> AudioStreamPlayer:
	return play_ui_sfx("cancel")

## 播放错误音效
func play_error_sfx() -> AudioStreamPlayer:
	return play_ui_sfx("error")

## 播放获得物品音效
func play_item_get_sfx() -> AudioStreamPlayer:
	return play_sfx_path("res://assets/audio/sfx/game/item_get.ogg")

## 播放步行的音效
func play_footstep_sfx(surface: String = "stone") -> AudioStreamPlayer:
	var path = "res://assets/audio/sfx/game/footstep_%s.ogg" % surface
	return play_sfx_path(path, 0.7, randf_range(0.9, 1.1))

## 播放绘图音效
func play_draw_sfx() -> AudioStreamPlayer:
	return play_sfx_path("res://assets/audio/sfx/game/draw.ogg", 0.8, randf_range(0.95, 1.05))

## 播放擦除音效
func play_erase_sfx() -> AudioStreamPlayer:
	return play_sfx_path("res://assets/audio/sfx/game/erase.ogg", 0.8)

## 播放迷雾消散音效
func play_mist_clear_sfx() -> AudioStreamPlayer:
	return play_sfx_path("res://assets/audio/sfx/game/mist_clear.ogg")

## 播放谜题完成音效
func play_puzzle_complete_sfx() -> AudioStreamPlayer:
	return play_sfx_path("res://assets/audio/sfx/game/puzzle_complete.ogg")

## 播放层级切换音效
func play_layer_change_sfx() -> AudioStreamPlayer:
	return play_sfx_path("res://assets/audio/sfx/game/layer_change.ogg")

# ============================================
# 工具函数
# ============================================

## 线性音量转分贝
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

## 分贝转线性音量
func db_to_linear(db: float) -> float:
	if db <= -80.0:
		return 0.0
	return pow(10.0, db / 20.0)

## 获取当前音量设置
func get_volume_settings() -> Dictionary:
	return {
		"master": master_volume,
		"music": music_volume,
		"sfx": sfx_volume,
		"ambient": ambient_volume,
		"muted": _is_muted
	}

## 设置音量（批量）
func set_volume_settings(settings: Dictionary) -> void:
	if settings.has("master"):
		set_master_volume(settings.master)
	if settings.has("music"):
		set_music_volume(settings.music)
	if settings.has("sfx"):
		set_sfx_volume(settings.sfx)
	if settings.has("ambient"):
		set_ambient_volume(settings.ambient)

## 重置为默认音量
func reset_to_default_volumes() -> void:
	set_master_volume(DEFAULT_MASTER_VOLUME)
	set_music_volume(DEFAULT_MUSIC_VOLUME)
	set_sfx_volume(DEFAULT_SFX_VOLUME)
	set_ambient_volume(DEFAULT_AMBIENT_VOLUME)
	set_mute(false)

## 获取状态信息
func get_status() -> Dictionary:
	return {
		"bgm_playing": _bgm_player.playing if _bgm_player else false,
		"current_bgm": _current_bgm.resource_path if _current_bgm else null,
		"ambient_playing": _ambient_player.playing if _ambient_player else false,
		"active_sfx_count": _playing_sfx.size(),
		"available_sfx_channels": _available_sfx_players.size(),
		"sfx_cache_size": _sfx_cache.size(),
		"is_muted": _is_muted
	}
