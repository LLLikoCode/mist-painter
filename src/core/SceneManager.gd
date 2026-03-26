## SceneManager
## 场景管理器
## 负责管理场景的加载、切换和过渡效果

class_name SceneManager
extends Node

# 场景路径配置
const SCENE_PATHS = {
    "main_menu": "res://scenes/MainMenu.tscn",
    "game": "res://scenes/Game.tscn",
    "pause_menu": "res://scenes/PauseMenu.tscn",
    "loading": "res://scenes/LoadingScreen.tscn"
}

# 过渡效果类型
enum TransitionType {
    FADE,       # 淡入淡出
    WIPE,       # 擦除
    DISSOLVE,   # 溶解
    SLIDE_LEFT, # 向左滑动
    SLIDE_RIGHT,# 向右滑动
    SLIDE_UP,   # 向上滑动
    SLIDE_DOWN, # 向下滑动
    NONE        # 无过渡
}

# 当前场景
var current_scene: Node = null
var current_scene_path: String = ""

# 场景栈（用于返回功能）
var scene_stack: Array[String] = []
var max_stack_size: int = 10

# 过渡中标志
var is_transitioning: bool = false

# 预加载的场景缓存
var scene_cache: Dictionary = {}
var max_cache_size: int = 5

# 信号
signal scene_loaded(scene_path: String)
signal scene_changed(old_scene: String, new_scene: String)
signal transition_started(transition_type: TransitionType)
signal transition_finished()
signal loading_progress(progress: float)

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 获取当前场景
    var root = get_tree().root
    current_scene = root.get_child(root.get_child_count() - 1)
    if current_scene:
        current_scene_path = current_scene.scene_file_path
    
    print("SceneManager initialized")

## 切换到指定场景
func change_scene(scene_path: String, transition: TransitionType = TransitionType.FADE, 
                  push_to_stack: bool = true) -> void:
    if is_transitioning:
        print("Scene transition already in progress")
        return
    
    if not ResourceLoader.exists(scene_path):
        push_error("Scene not found: " + scene_path)
        return
    
    is_transitioning = true
    transition_started.emit(transition)
    
    # 将当前场景压入栈
    if push_to_stack and current_scene_path != "":
        _push_scene_to_stack(current_scene_path)
    
    var old_scene = current_scene_path
    
    # 执行过渡效果
    await _play_transition_out(transition)
    
    # 加载新场景
    await _load_scene(scene_path)
    
    # 执行进入过渡
    await _play_transition_in(transition)
    
    is_transitioning = false
    transition_finished.emit()
    scene_changed.emit(old_scene, scene_path)

## 切换到场景（通过名称）
func change_scene_by_name(scene_name: String, transition: TransitionType = TransitionType.FADE) -> void:
    if SCENE_PATHS.has(scene_name):
        await change_scene(SCENE_PATHS[scene_name], transition)
    else:
        push_error("Unknown scene name: " + scene_name)

## 返回上一场景
func go_back(transition: TransitionType = TransitionType.FADE) -> bool:
    if scene_stack.is_empty():
        print("Scene stack is empty, cannot go back")
        return false
    
    var previous_scene = scene_stack.pop_back()
    await change_scene(previous_scene, transition, false)
    return true

## 重新加载当前场景
func reload_current_scene(transition: TransitionType = TransitionType.FADE) -> void:
    if current_scene_path != "":
        await change_scene(current_scene_path, transition, false)

## 预加载场景到缓存
func preload_scene(scene_path: String) -> void:
    if scene_cache.has(scene_path):
        return
    
    if scene_cache.size() >= max_cache_size:
        # 移除最早缓存的场景
        var oldest_key = scene_cache.keys()[0]
        scene_cache.erase(oldest_key)
    
    var scene = load(scene_path)
    if scene:
        scene_cache[scene_path] = scene
        print("Scene preloaded: " + scene_path)

## 清除场景缓存
func clear_scene_cache() -> void:
    scene_cache.clear()
    print("Scene cache cleared")

## 获取当前场景
func get_current_scene() -> Node:
    return current_scene

## 获取当前场景路径
func get_current_scene_path() -> String:
    return current_scene_path

## 检查是否正在过渡
func is_in_transition() -> bool:
    return is_transitioning

## 私有：加载场景
func _load_scene(scene_path: String) -> void:
    # 检查缓存
    var scene_resource = null
    if scene_cache.has(scene_path):
        scene_resource = scene_cache[scene_path]
        print("Scene loaded from cache: " + scene_path)
    else:
        # 异步加载
        ResourceLoader.load_threaded_request(scene_path)
        
        while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            var progress = ResourceLoader.load_threaded_get_status(scene_path)
            loading_progress.emit(progress)
            await get_tree().process_frame
        
        scene_resource = ResourceLoader.load_threaded_get(scene_path)
        print("Scene loaded: " + scene_path)
    
    if scene_resource == null:
        push_error("Failed to load scene: " + scene_path)
        return
    
    # 移除旧场景
    if current_scene:
        current_scene.queue_free()
    
    # 实例化新场景
    current_scene = scene_resource.instantiate()
    current_scene_path = scene_path
    
    # 添加到场景树
    get_tree().root.add_child(current_scene)
    get_tree().current_scene = current_scene
    
    scene_loaded.emit(scene_path)

## 私有：播放退出过渡
func _play_transition_out(transition: TransitionType) -> void:
    match transition:
        TransitionType.FADE:
            await _fade_out()
        TransitionType.SLIDE_LEFT:
            await _slide_out(Vector2.LEFT)
        TransitionType.SLIDE_RIGHT:
            await _slide_out(Vector2.RIGHT)
        TransitionType.SLIDE_UP:
            await _slide_out(Vector2.UP)
        TransitionType.SLIDE_DOWN:
            await _slide_out(Vector2.DOWN)
        TransitionType.NONE:
            pass
        _:
            await _fade_out()

## 私有：播放入过渡
func _play_transition_in(transition: TransitionType) -> void:
    match transition:
        TransitionType.FADE:
            await _fade_in()
        TransitionType.SLIDE_LEFT:
            await _slide_in(Vector2.RIGHT)
        TransitionType.SLIDE_RIGHT:
            await _slide_in(Vector2.LEFT)
        TransitionType.SLIDE_UP:
            await _slide_in(Vector2.DOWN)
        TransitionType.SLIDE_DOWN:
            await _slide_in(Vector2.UP)
        TransitionType.NONE:
            pass
        _:
            await _fade_in()

## 私有：淡入淡出效果
func _fade_out() -> void:
    # 创建过渡层
    var overlay = ColorRect.new()
    overlay.color = Color.BLACK
    overlay.size = get_viewport().get_visible_rect().size
    overlay.modulate.a = 0
    get_tree().root.add_child(overlay)
    
    # 淡出动画
    var tween = create_tween()
    tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
    await tween.finished
    
    overlay.queue_free()

func _fade_in() -> void:
    var overlay = ColorRect.new()
    overlay.color = Color.BLACK
    overlay.size = get_viewport().get_visible_rect().size
    get_tree().root.add_child(overlay)
    
    # 淡入动画
    var tween = create_tween()
    tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
    await tween.finished
    
    overlay.queue_free()

## 私有：滑动效果
func _slide_out(direction: Vector2) -> void:
    if current_scene == null:
        return
    
    var viewport_size = get_viewport().get_visible_rect().size
    var target_position = current_scene.position + direction * viewport_size
    
    var tween = create_tween()
    tween.tween_property(current_scene, "position", target_position, 0.3)
    await tween.finished

func _slide_in(direction: Vector2) -> void:
    if current_scene == null:
        return
    
    var viewport_size = get_viewport().get_visible_rect().size
    var original_position = current_scene.position
    current_scene.position = original_position + direction * viewport_size
    
    var tween = create_tween()
    tween.tween_property(current_scene, "position", original_position, 0.3)
    await tween.finished

## 私有：管理场景栈
func _push_scene_to_stack(scene_path: String) -> void:
    scene_stack.append(scene_path)
    if scene_stack.size() > max