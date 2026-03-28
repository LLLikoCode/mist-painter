## MistPaintingSystem
## 迷雾绘制系统
## 负责管理迷雾的绘制、擦除、渲染和与游戏机制的交互

class_name MistPaintingSystem
extends Node2D

# ============================================
# 常量定义
# ============================================

## 迷雾纹理大小
const MIST_TEXTURE_SIZE: Vector2i = Vector2i(1280, 720)

## 默认笔刷大小
const DEFAULT_BRUSH_SIZE: float = 20.0

## 迷雾颜色
const MIST_COLOR: Color = Color(0.1, 0.1, 0.15, 0.95)

## 迷雾消散颜色（完全透明）
const CLEAR_COLOR: Color = Color(0.0, 0.0, 0.0, 0.0)

# ============================================
# 导出变量
# ============================================

@export_group("Brush Settings")
@export var brush_size: float = DEFAULT_BRUSH_SIZE
@export var brush_hardness: float = 0.5
@export var brush_opacity: float = 1.0

@export_group("Mist Settings")
@export var mist_density: float = 0.95
@export var mist_regeneration_rate: float = 0.0  # 迷雾再生速率（每秒）
@export var enable_regeneration: bool = false

@export_group("Performance")
@export var update_interval: float = 0.016  # 约60fps
@export var use_sub_viewport: bool = true

# ============================================
# 节点引用
# ============================================

@onready var mist_viewport: SubViewport = $MistViewport
@onready var mist_sprite: Sprite2D = $MistSprite
@onready var canvas_layer: CanvasLayer = $MistCanvasLayer

# ============================================
# 内部变量
# ============================================

## 迷雾纹理
var mist_texture: ImageTexture

## 迷雾图像
var mist_image: Image

## 是否正在绘制
var is_drawing: bool = false

## 上次绘制位置
var last_paint_position: Vector2 = Vector2.ZERO

## 更新计时器
var update_timer: float = 0.0

## 笔刷图像缓存
var brush_image: Image

## 绘制操作队列
var paint_queue: Array[Dictionary] = []

## 迷雾覆盖百分比
var mist_coverage: float = 1.0

## 迷雾区域统计
var cleared_pixels: int = 0
var total_pixels: int = 0

# ============================================
# 信号
# ============================================

signal mist_painted(position: Vector2, radius: float)
signal mist_cleared(position: Vector2, radius: float)
signal mist_coverage_changed(coverage_percent: float)
signal drawing_started
signal drawing_ended

# ============================================
# 生命周期
# ============================================

func _ready():
    _initialize_mist()
    _create_brush()
    print("MistPaintingSystem initialized")

func _process(delta: float):
    update_timer += delta
    
    # 处理绘制队列
    if not paint_queue.is_empty() and update_timer >= update_interval:
        _process_paint_queue()
        update_timer = 0.0
    
    # 迷雾再生
    if enable_regeneration and mist_regeneration_rate > 0:
        _regenerate_mist(delta)

# ============================================
# 初始化
# ============================================

## 初始化迷雾
func _initialize_mist() -> void:
    # 创建迷雾图像
    mist_image = Image.create(MIST_TEXTURE_SIZE.x, MIST_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
    mist_image.fill(MIST_COLOR)
    
    # 创建纹理
    mist_texture = ImageTexture.create_from_image(mist_image)
    
    # 设置精灵
    if mist_sprite:
        mist_sprite.texture = mist_texture
        mist_sprite.position = Vector2(MIST_TEXTURE_SIZE.x / 2, MIST_TEXTURE_SIZE.y / 2)
    
    total_pixels = MIST_TEXTURE_SIZE.x * MIST_TEXTURE_SIZE.y
    cleared_pixels = 0
    mist_coverage = 1.0

## 创建笔刷
func _create_brush() -> void:
    var brush_size_int = int(brush_size * 2)
    brush_image = Image.create(brush_size_int, brush_size_int, false, Image.FORMAT_RGBA8)
    
    var center = Vector2(brush_size, brush_size)
    
    for x in range(brush_size_int):
        for y in range(brush_size_int):
            var pos = Vector2(x, y)
            var distance = pos.distance_to(center)
            var normalized_dist = distance / brush_size
            
            if normalized_dist <= 1.0:
                # 计算透明度（边缘软化）
                var alpha = 1.0 - pow(normalized_dist, brush_hardness * 2)
                alpha *= brush_opacity
                
                # 设置笔刷像素
                brush_image.set_pixel(x, y, Color(0, 0, 0, alpha))
            else:
                brush_image.set_pixel(x, y, Color(0, 0, 0, 0))

# ============================================
# 绘制操作
# ============================================

## 开始绘制
func start_drawing(position: Vector2) -> void:
    is_drawing = true
    last_paint_position = position
    
    # 立即绘制第一个点
    _paint_at(position)
    
    drawing_started.emit()

## 继续绘制（拖动）
func continue_drawing(position: Vector2) -> void:
    if not is_drawing:
        return
    
    # 插值绘制（在两点之间绘制连线）
    _paint_line(last_paint_position, position)
    last_paint_position = position

## 结束绘制
func end_drawing() -> void:
    is_drawing = false
    drawing_ended.emit()

## 在指定位置绘制
func _paint_at(position: Vector2) -> void:
    # 转换到图像坐标
    var image_pos = _world_to_image(position)
    
    # 添加到绘制队列
    paint_queue.append({
        "type": "paint",
        "position": image_pos,
        "radius": brush_size
    })

## 绘制连线
func _paint_line(from: Vector2, to: Vector2) -> void:
    var from_image = _world_to_image(from)
    var to_image = _world_to_image(to)
    
    var distance = from_image.distance_to(to_image)
    var steps = int(distance / (brush_size * 0.5)) + 1
    
    for i in range(steps):
        var t = float(i) / steps
        var pos = from_image.lerp(to_image, t)
        
        paint_queue.append({
            "type": "paint",
            "position": pos,
            "radius": brush_size
        })

## 处理绘制队列
func _process_paint_queue() -> void:
    if paint_queue.is_empty():
        return
    
    var modified = false
    var cleared_count = 0
    
    for operation in paint_queue:
        var pos = operation["position"]
        var radius = operation["radius"]
        
        # 执行绘制操作
        cleared_count += _apply_brush(pos, radius)
        modified = true
    
    paint_queue.clear()
    
    if modified:
        # 更新纹理
        mist_texture.update(mist_image)
        
        # 更新覆盖率统计
        cleared_pixels += cleared_count
        _update_coverage()

## 应用笔刷
func _apply_brush(center: Vector2, radius: float) -> int:
    var cleared = 0
    var brush_radius = int(radius)
    
    var start_x = int(max(0, center.x - radius))
    var end_x = int(min(MIST_TEXTURE_SIZE.x - 1, center.x + radius))
    var start_y = int(max(0, center.y - radius))
    var end_y = int(min(MIST_TEXTURE_SIZE.y - 1, center.y + radius))
    
    for x in range(start_x, end_x + 1):
        for y in range(start_y, end_y + 1):
            var pos = Vector2(x, y)
            var distance = pos.distance_to(center)
            
            if distance <= radius:
                var current_color = mist_image.get_pixel(x, y)
                
                if current_color.a > 0:
                    # 计算笔刷透明度
                    var normalized_dist = distance / radius
                    var brush_alpha = 1.0 - pow(normalized_dist, brush_hardness * 2)
                    
                    # 减少迷雾（增加透明度）
                    var new_alpha = max(0, current_color.a - brush_alpha * brush_opacity * 0.1)
                    
                    if current_color.a > 0.1 and new_alpha <= 0.1:
                        cleared += 1
                    
                    current_color.a = new_alpha
                    mist_image.set_pixel(x, y, current_color)
    
    return cleared

# ============================================
# 迷雾再生
# ============================================

## 再生迷雾
func _regenerate_mist(delta: float) -> void:
    var regen_amount = mist_regeneration_rate * delta
    if regen_amount <= 0:
        return
    
    var modified = false
    
    for x in range(MIST_TEXTURE_SIZE.x):
        for y in range(MIST_TEXTURE_SIZE.y):
            var current_color = mist_image.get_pixel(x, y)
            if current_color.a < mist_density:
                current_color.a = min(mist_density, current_color.a + regen_amount * 0.01)
                mist_image.set_pixel(x, y, current_color)
                modified = true
    
    if modified:
        mist_texture.update(mist_image)
        _update_coverage()

# ============================================
# 坐标转换
# ============================================

## 世界坐标转图像坐标
func _world_to_image(world_pos: Vector2) -> Vector2:
    # 假设世界坐标与屏幕坐标1:1对应
    return world_pos

## 图像坐标转世界坐标
func _image_to_world(image_pos: Vector2) -> Vector2:
    return image_pos

# ============================================
# 覆盖率计算
# ============================================

## 更新覆盖率
func _update_coverage() -> void:
    var transparent_pixels = 0
    
    # 采样计算（性能优化）
    var sample_step = 4  # 每4个像素采样一次
    
    for x in range(0, MIST_TEXTURE_SIZE.x, sample_step):
        for y in range(0, MIST_TEXTURE_SIZE.y, sample_step):
            var color = mist_image.get_pixel(x, y)
            if color.a < 0.1:
                transparent_pixels += 1
    
    var sampled_pixels = (MIST_TEXTURE_SIZE.x / sample_step) * (MIST_TEXTURE_SIZE.y / sample_step)
    mist_coverage = 1.0 - (float(transparent_pixels) / sampled_pixels)
    
    mist_coverage_changed.emit(mist_coverage * 100)

# ============================================
# 公共方法 - 迷雾控制
# ============================================

## 清除指定圆形区域的迷雾
func clear_mist_circle(center: Vector2, radius: float) -> void:
    var image_center = _world_to_image(center)
    
    paint_queue.append({
        "type": "clear",
        "position": image_center,
        "radius": radius
    })

## 填充指定圆形区域的迷雾
func fill_mist_circle(center: Vector2, radius: float) -> void:
    var image_center = _world_to_image(center)
    var image_radius = int(radius)
    
    var start_x = int(max(0, image_center.x - radius))
    var end_x = int(min(MIST_TEXTURE_SIZE.x - 1, image_center.x + radius))
    var start_y = int(max(0, image_center.y - radius))
    var end_y = int(min(MIST_TEXTURE_SIZE.y - 1, image_center.y + radius))
    
    for x in range(start_x, end_x + 1):
        for y in range(start_y, end_y + 1):
            var pos = Vector2(x, y)
            if pos.distance_to(image_center) <= radius:
                mist_image.set_pixel(x, y, MIST_COLOR)
    
    mist_texture.update(mist_image)
    _update_coverage()
    mist_painted.emit(center, radius)

## 完全清除所有迷雾
func clear_all_mist() -> void:
    mist_image.fill(CLEAR_COLOR)
    mist_texture.update(mist_image)
    mist_coverage = 0.0
    mist_coverage_changed.emit(0.0)

## 完全填充所有迷雾
func fill_all_mist() -> void:
    mist_image.fill(MIST_COLOR)
    mist_texture.update(mist_image)
    mist_coverage = 1.0
    mist_coverage_changed.emit(100.0)

## 重置迷雾
func reset_mist() -> void:
    fill_all_mist()

# ============================================
# 公共方法 - 笔刷设置
# ============================================

## 设置笔刷大小
func set_brush_size(size: float) -> void:
    brush_size = clamp(size, 5.0, 100.0)
    _create_brush()

## 设置笔刷硬度
func set_brush_hardness(hardness: float) -> void:
    brush_hardness = clamp(hardness, 0.0, 1.0)
    _create_brush()

## 设置笔刷透明度
func set_brush_opacity(opacity: float) -> void:
    brush_opacity = clamp(opacity, 0.0, 1.0)
    _create_brush()

# ============================================
# 公共方法 - 查询
# ============================================

## 获取指定位置的迷雾密度
func get_mist_density_at(position: Vector2) -> float:
    var image_pos = _world_to_image(position)
    
    if image_pos.x < 0 or image_pos.x >= MIST_TEXTURE_SIZE.x:
        return 0.0
    if image_pos.y < 0 or image_pos.y >= MIST_TEXTURE_SIZE.y:
        return 0.0
    
    return mist_image.get_pixel(int(image_pos.x), int(image_pos.y)).a

## 检查位置是否可见（迷雾密度低）
func is_position_visible(position: Vector2, threshold: float = 0.3) -> bool:
    return get_mist_density_at(position) < threshold

## 获取当前迷雾覆盖率
func get_mist_coverage() -> float:
    return mist_coverage

## 获取迷雾覆盖率百分比
func get_mist_coverage_percent() -> float:
    return mist_coverage * 100.0

# ============================================
# 公共方法 - 保存/加载
# ============================================

## 导出迷雾数据（用于存档）
func export_mist_data() -> PackedByteArray:
    return mist_image.save_png_to_buffer()

## 导入迷雾数据（从存档加载）
func import_mist_data(data: PackedByteArray) -> bool:
    var image = Image.new()
    var error = image.load_png_from_buffer(data)
    
    if error == OK:
        mist_image = image
        mist_texture = ImageTexture.create_from_image(mist_image)
        if mist_sprite:
            mist_sprite.texture = mist_texture
        _update_coverage()
        return true
    
    return false

## 保存迷雾图像到文件
func save_mist_to_file(path: String) -> bool:
    var error = mist_image.save_png(path)
    return error == OK
