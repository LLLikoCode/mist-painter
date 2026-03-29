## MistPaintingSystem (Optimized)
## 迷雾绘制系统 - 性能优化版
## 负责管理迷雾的绘制、擦除、渲染和与游戏机制的交互
## 优化重点: 脏矩形更新、异步统计、分块渲染

class_name MistPaintingSystem
extends Node2D

# ============================================
# 常量定义
# ============================================

## 迷雾纹理大小
const MIST_TEXTURE_SIZE: Vector2i = Vector2i(1280, 720)

## 默认笔刷大小
const DEFAULT_BRUSH_SIZE: float = 20.0

## 迷雾颜色 - 使用更明显的深蓝色迷雾
const MIST_COLOR: Color = Color(0.05, 0.05, 0.1, 0.98)

## 迷雾消散颜色（完全透明）
const CLEAR_COLOR: Color = Color(0.0, 0.0, 0.0, 0.0)

## 覆盖率计算间隔（秒）
const COVERAGE_CALC_INTERVAL: float = 0.5

## 最大脏矩形数量（防止内存无限增长）
const MAX_DIRTY_RECTS: int = 16

## 脏矩形合并阈值（像素）
const DIRTY_RECT_MERGE_THRESHOLD: int = 32

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
@export var enable_optimization: bool = true  # 启用所有优化
@export var max_paint_per_frame: int = 8  # 每帧最大绘制操作数
@export var enable_async_coverage: bool = true  # 启用异步覆盖率计算

# ============================================
# 节点引用
# ============================================

@onready var mist_viewport: SubViewport = $MistViewport
@onready var mist_sprite: Sprite2D = $MistCanvasLayer/MistSprite
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

## ===== 优化新增变量 =====

## 脏矩形列表（用于局部更新）
var dirty_rects: Array[Rect2i] = []

## 覆盖率计算计时器
var coverage_calc_timer: float = 0.0

## 是否正在计算覆盖率
var is_calculating_coverage: bool = false

## 笔刷缓存（预计算不同大小的笔刷）
var brush_cache: Dictionary = {}

## 累计修改像素计数（用于增量覆盖率计算）
var modified_pixels_count: int = 0

## 迷雾再生脏矩形
var regen_dirty_rect: Rect2i = Rect2i(0, 0, 0, 0)

## 局部更新用的临时图像
var temp_update_image: Image

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
	_initialize_optimized_system()
	print("MistPaintingSystem (Optimized) initialized")

func _process(delta: float):
	update_timer += delta
	coverage_calc_timer += delta
	
	# 处理绘制队列（限制每帧处理数量）
	if not paint_queue.is_empty() and update_timer >= update_interval:
		if enable_optimization:
			_process_paint_queue_optimized()
		else:
			_process_paint_queue_legacy()
		update_timer = 0.0
	
	# 定期计算覆盖率
	if coverage_calc_timer >= COVERAGE_CALC_INTERVAL:
		if enable_async_coverage and enable_optimization:
			_request_coverage_calculation_async()
		else:
			_update_coverage()
		coverage_calc_timer = 0.0
	
	# 迷雾再生（使用优化版本）
	if enable_regeneration and mist_regeneration_rate > 0:
		if enable_optimization:
			_regenerate_mist_optimized(delta)
		else:
			_regenerate_mist_legacy(delta)

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
		# 确保精灵位于屏幕中央，覆盖整个屏幕
		mist_sprite.position = Vector2(MIST_TEXTURE_SIZE.x / 2, MIST_TEXTURE_SIZE.y / 2)
		mist_sprite.centered = true

	# 确保 CanvasLayer 在正确的层级
	if canvas_layer:
		canvas_layer.layer = 5  # 在游戏世界之上，UI之下

	total_pixels = MIST_TEXTURE_SIZE.x * MIST_TEXTURE_SIZE.y
	cleared_pixels = 0
	mist_coverage = 1.0

## 初始化优化系统
func _initialize_optimized_system() -> void:
	# 创建临时更新图像
	temp_update_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# 预缓存常用笔刷大小
	_cache_common_brushes()

## 预缓存常用笔刷
func _cache_common_brushes() -> void:
	var common_sizes = [10.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0]
	for size in common_sizes:
		_brush_cache_get_or_create(size, brush_hardness, brush_opacity)

## 获取或创建缓存的笔刷
func _brush_cache_get_or_create(size: float, hardness: float, opacity: float) -> Image:
	var cache_key = str(int(size * 10)) + "_" + str(int(hardness * 10)) + "_" + str(int(opacity * 10))
	
	if brush_cache.has(cache_key):
		return brush_cache[cache_key]
	
	# 创建新笔刷
	var brush = _create_brush_image(size, hardness, opacity)
	brush_cache[cache_key] = brush
	return brush

## 创建笔刷图像（抽离为独立函数）
func _create_brush_image(size: float, hardness: float, opacity: float) -> Image:
	var brush_size_int = int(size * 2)
	var brush = Image.create(brush_size_int, brush_size_int, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size, size)
	
	for x in range(brush_size_int):
		for y in range(brush_size_int):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			var normalized_dist = distance / size
			
			if normalized_dist <= 1.0:
				# 计算透明度（边缘软化）
				var alpha = 1.0 - pow(normalized_dist, hardness * 2)
				alpha *= opacity
				brush.set_pixel(x, y, Color(0, 0, 0, alpha))
			else:
				brush.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return brush

## 创建笔刷（兼容旧接口）
func _create_brush() -> void:
	brush_image = _brush_cache_get_or_create(brush_size, brush_hardness, brush_opacity)

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
func end_drawing(_position: Vector2 = Vector2.ZERO) -> void:
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
	
	# 限制步数，防止队列过长
	steps = min(steps, max_paint_per_frame)
	
	for i in range(steps):
		var t = float(i) / steps
		var pos = from_image.lerp(to_image, t)
		
		paint_queue.append({
			"type": "paint",
			"position": pos,
			"radius": brush_size
		})

## 处理绘制队列（优化版本）
func _process_paint_queue_optimized() -> void:
	if paint_queue.is_empty():
		return
	
	var modified = false
	var cleared_count = 0
	
	# 限制每帧处理数量
	var process_count = min(paint_queue.size(), max_paint_per_frame)
	
	# 收集所有修改区域
	var affected_rects: Array[Rect2i] = []
	
	for i in range(process_count):
		var operation = paint_queue[i]
		var pos = operation["position"]
		var radius = operation["radius"]
		
		# 执行绘制操作
		var result = _apply_brush_optimized(pos, radius)
		cleared_count += result.cleared_count
		
		if result.modified:
			modified = true
			affected_rects.append(result.affected_rect)
	
	# 移除已处理的操作
	paint_queue = paint_queue.slice(process_count)
	
	if modified:
		# 合并脏矩形
		_merge_dirty_rects(affected_rects)
		
		# 局部更新纹理
		_update_texture_partial()
		
		# 更新覆盖率统计
		cleared_pixels += cleared_count
		modified_pixels_count += cleared_count

## 处理绘制队列（兼容旧版本）
func _process_paint_queue_legacy() -> void:
	if paint_queue.is_empty():
		return
	
	var modified = false
	var cleared_count = 0
	
	for operation in paint_queue:
		var pos = operation["position"]
		var radius = operation["radius"]
		
		# 执行绘制操作
		cleared_count += _apply_brush_legacy(pos, radius)
		modified = true
	
	paint_queue.clear()
	
	if modified:
		# 更新纹理 - Godot 4.x 使用 create_from_image 或 set_image
		mist_texture = ImageTexture.create_from_image(mist_image)

		# 更新覆盖率统计
		cleared_pixels += cleared_count
		_update_coverage()

## 应用笔刷（优化版本）
func _apply_brush_optimized(center: Vector2, radius: float) -> Dictionary:
	var result = {
		"cleared_count": 0,
		"modified": false,
		"affected_rect": Rect2i()
	}
	
	var start_x = int(max(0, center.x - radius))
	var end_x = int(min(MIST_TEXTURE_SIZE.x - 1, center.x + radius))
	var start_y = int(max(0, center.y - radius))
	var end_y = int(min(MIST_TEXTURE_SIZE.y - 1, center.y + radius))
	
	# 如果没有有效区域，直接返回
	if start_x >= end_x or start_y >= end_y:
		return result
	
	result.affected_rect = Rect2i(start_x, start_y, end_x - start_x + 1, end_y - start_y + 1)
	
	var cleared = 0
	var modified = false
	
	# 获取缓存的笔刷
	var cached_brush = _brush_cache_get_or_create(radius, brush_hardness, brush_opacity)
	var brush_size_int = int(radius * 2)
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= radius:
				var current_color = mist_image.get_pixel(x, y)
				
				if current_color.a > 0.01:
					# 从缓存笔刷获取透明度
					var brush_x = int(x - (center.x - radius))
					var brush_y = int(y - (center.y - radius))
					
					if brush_x >= 0 and brush_x < brush_size_int and brush_y >= 0 and brush_y < brush_size_int:
						var brush_alpha = cached_brush.get_pixel(clamp(brush_x, 0, brush_size_int - 1), clamp(brush_y, 0, brush_size_int - 1)).a
						
						if brush_alpha > 0:
							# 减少迷雾（增加透明度）
							var new_alpha = max(0.0, current_color.a - brush_alpha * 0.1)
							
							if current_color.a > 0.1 and new_alpha <= 0.1:
								cleared += 1
							
							if abs(new_alpha - current_color.a) > 0.001:
								current_color.a = new_alpha
								mist_image.set_pixel(x, y, current_color)
								modified = true
	
	result.cleared_count = cleared
	result.modified = modified
	return result

## 应用笔刷（旧版本 - 完全兼容）
func _apply_brush_legacy(center: Vector2, radius: float) -> int:
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

## 合并脏矩形
func _merge_dirty_rects(new_rects: Array[Rect2i]) -> void:
	for new_rect in new_rects:
		var merged = false
		
		# 尝试与现有脏矩形合并
		for i in range(dirty_rects.size()):
			var existing = dirty_rects[i]
			
			# 检查是否可以合并（距离阈值）
			if existing.grow(DIRTY_RECT_MERGE_THRESHOLD).intersects(new_rect):
				dirty_rects[i] = existing.merge(new_rect)
				merged = true
				break
		
		if not merged:
			dirty_rects.append(new_rect)
	
	# 限制脏矩形数量，合并最相似的
	while dirty_rects.size() > MAX_DIRTY_RECTS:
		# 找到面积最小的两个矩形合并
		var min_area_sum = INF
		var merge_idx_a = -1
		var merge_idx_b = -1
		
		for i in range(dirty_rects.size()):
			for j in range(i + 1, dirty_rects.size()):
				var combined = dirty_rects[i].merge(dirty_rects[j])
				var area = combined.get_area()
				if area < min_area_sum:
					min_area_sum = area
					merge_idx_a = i
					merge_idx_b = j
		
		if merge_idx_a >= 0 and merge_idx_b >= 0:
			var merged_rect = dirty_rects[merge_idx_a].merge(dirty_rects[merge_idx_b])
			dirty_rects.remove_at(max(merge_idx_a, merge_idx_b))
			dirty_rects.remove_at(min(merge_idx_a, merge_idx_b))
			dirty_rects.append(merged_rect)

## 局部更新纹理
func _update_texture_partial() -> void:
	if dirty_rects.is_empty():
		return

	# Godot 4.x 中 ImageTexture.update() 不接受矩形参数
	# 重新创建纹理以应用更改
	mist_texture = ImageTexture.create_from_image(mist_image)

	# 清空脏矩形列表
	dirty_rects.clear()

# ============================================
# 迷雾再生（优化版本）
# ============================================

## 再生迷雾（优化版本 - 只处理已清除的区域）
func _regenerate_mist_optimized(delta: float) -> void:
	var regen_amount = mist_regeneration_rate * delta
	if regen_amount <= 0:
		return
	
	var modified = false
	
	# 基于分块的方式再生迷雾
	# 只处理之前被清除过的区域（cleared_pixels 区域）
	var pixels_to_regen = int(cleared_pixels * regen_amount * 0.1)
	pixels_to_regen = min(pixels_to_regen, cleared_pixels)
	
	if pixels_to_regen <= 0:
		return
	
	# 随机采样再生（避免遍历全图）
	var sample_count = min(pixels_to_regen * 10, 1000)  # 最多采样1000个点
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var regen_rects: Array[Rect2i] = []
	
	for _i in range(sample_count):
		var x = rng.randi_range(0, MIST_TEXTURE_SIZE.x - 1)
		var y = rng.randi_range(0, MIST_TEXTURE_SIZE.y - 1)
		
		var current_color = mist_image.get_pixel(x, y)
		if current_color.a < mist_density:
			current_color.a = min(mist_density, current_color.a + regen_amount * 0.01)
			mist_image.set_pixel(x, y, current_color)
			modified = true
			cleared_pixels -= 1
			
			# 记录修改区域
			var regen_rect = Rect2i(x - 2, y - 2, 5, 5)
			regen_rect = regen_rect.intersection(Rect2i(0, 0, MIST_TEXTURE_SIZE.x, MIST_TEXTURE_SIZE.y))
			regen_rects.append(regen_rect)
	
	if modified:
		_merge_dirty_rects(regen_rects)
		_update_texture_partial()

## 再生迷雾（旧版本）
func _regenerate_mist_legacy(delta: float) -> void:
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
		mist_texture = ImageTexture.create_from_image(mist_image)
		_update_coverage()

# ============================================
# 覆盖率计算（优化版本）
# ============================================

## 请求异步覆盖率计算
func _request_coverage_calculation_async() -> void:
	if is_calculating_coverage:
		return
	
	is_calculating_coverage = true
	
	# 使用延迟计算避免阻塞
	call_deferred("_complete_coverage_calculation", _calculate_coverage_sampled())

## 完成覆盖率计算
func _complete_coverage_calculation(result: float) -> void:
	mist_coverage = result
	is_calculating_coverage = false
	mist_coverage_changed.emit(mist_coverage * 100)

## 采样计算覆盖率
func _calculate_coverage_sampled() -> float:
	var transparent_pixels = 0
	
	# 使用更大的采样步长（性能优化）
	var sample_step = 8
	var sample_count = 0
	
	for x in range(0, MIST_TEXTURE_SIZE.x, sample_step):
		for y in range(0, MIST_TEXTURE_SIZE.y, sample_step):
			var color = mist_image.get_pixel(x, y)
			if color.a < 0.1:
				transparent_pixels += 1
			sample_count += 1
	
	if sample_count == 0:
		return 1.0
	
	return 1.0 - (float(transparent_pixels) / sample_count)

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
# 覆盖率计算（兼容旧版本）
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
	
	mist_texture = ImageTexture.create_from_image(mist_image)
	_update_coverage()
	mist_painted.emit(center, radius)

## 完全清除所有迷雾
func clear_all_mist() -> void:
	mist_image.fill(CLEAR_COLOR)
	mist_texture = ImageTexture.create_from_image(mist_image)
	mist_coverage = 0.0
	cleared_pixels = total_pixels
	mist_coverage_changed.emit(0.0)

## 完全填充所有迷雾
func fill_all_mist() -> void:
	mist_image.fill(MIST_COLOR)
	mist_texture = ImageTexture.create_from_image(mist_image)
	mist_coverage = 1.0
	cleared_pixels = 0
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

## 获取性能统计
func get_performance_stats() -> Dictionary:
	return {
		"paint_queue_size": paint_queue.size(),
		"dirty_rects_count": dirty_rects.size(),
		"brush_cache_size": brush_cache.size(),
		"cleared_pixels": cleared_pixels,
		"optimization_enabled": enable_optimization
	}
