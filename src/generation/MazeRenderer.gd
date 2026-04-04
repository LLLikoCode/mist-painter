## MazeRenderer
## 迷宫渲染器
## 将 MazeGenerator 生成的迷宫数据渲染为可见的节点

class_name MazeRenderer
extends Node2D

# ============================================
# 预加载
# ============================================

const _MazeGeneratorScript := preload("res://src/generation/MazeGenerator.gd")

# ============================================
# 导出变量
# ============================================

@export var cell_size: int = 50
@export var generate_collision: bool = true

## 颜色配置 - 使用更明亮的颜色
@export var wall_color: Color = Color(0.25, 0.2, 0.3)  # 紫灰色墙壁
@export var path_color: Color = Color(0.6, 0.55, 0.65)  # 明亮的通道
@export var room_color: Color = Color(0.65, 0.6, 0.7)
@export var entrance_color: Color = Color(0.2, 0.8, 0.4)  # 绿色入口
@export var exit_color: Color = Color(0.9, 0.3, 0.2)  # 红色出口

# ============================================
# 节点引用
# ============================================

## 迷宫可视化容器
var maze_visual: Node2D = null

## 碰撞区域容器
var collision_container: Node2D = null

## 特殊节点容器
var special_nodes_container: Node2D = null

## 当前迷宫数据
var current_maze: Dictionary = {}

## 保存的入口世界坐标（避免依赖 current_maze）
var saved_entrance_position: Vector2 = Vector2(100, 100)

# ============================================
# 信号
# ============================================

signal maze_rendered()
signal special_node_created(node_type: String, position: Vector2)

# ============================================
# 生命周期
# ============================================

func _ready():
	print("MazeRenderer _ready called")
	_create_containers()

# ============================================
# 初始化
# ============================================

## 创建容器节点
func _create_containers() -> void:
	print("MazeRenderer: Creating containers...")

	# 迷宫可视化容器 - 使用高z_index确保可见
	maze_visual = Node2D.new()
	maze_visual.name = "MazeVisual"
	maze_visual.z_index = 10
	add_child(maze_visual)

	# 碰撞容器
	collision_container = Node2D.new()
	collision_container.name = "CollisionContainer"
	collision_container.z_index = 5
	add_child(collision_container)

	# 特殊节点容器
	special_nodes_container = Node2D.new()
	special_nodes_container.name = "SpecialNodesContainer"
	special_nodes_container.z_index = 15
	add_child(special_nodes_container)

	# 创建一个测试标记，确保渲染工作
	var test_sprite = Sprite2D.new()
	test_sprite.name = "TestMarker"
	test_sprite.position = Vector2(500, 500)
	test_sprite.centered = true
	test_sprite.z_index = 100
	var test_image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
	test_image.fill(Color(1, 0, 1, 1))  # 明亮的粉红色
	test_sprite.texture = ImageTexture.create_from_image(test_image)
	maze_visual.add_child(test_sprite)
	print("MazeRenderer: Test marker created at (500, 500)")

	print("MazeRenderer: Containers created")

# ============================================
# 渲染迷宫
# ============================================

## 渲染迷宫
func render_maze(maze_data: Dictionary) -> void:
	print("MazeRenderer.render_maze called")

	# 确保容器已创建
	if maze_visual == null:
		print("MazeRenderer: maze_visual is null, creating containers...")
		_create_containers()

	# 验证容器存在
	if maze_visual == null:
		print("ERROR: Failed to create maze_visual container!")
		return

	current_maze = maze_data

	# 清除旧的迷宫
	clear_maze()

	var cells = maze_data.get("cells", [])
	var width = maze_data.get("width", 0)
	var height = maze_data.get("height", 0)

	print("MazeRenderer: Rendering maze %dx%d" % [width, height])
	print("MazeRenderer: maze_visual position: ", maze_visual.position)
	print("MazeRenderer: maze_visual z_index: ", maze_visual.z_index)

	# 渲染每个单元格
	var cell_count = 0
	for y in range(height):
		for x in range(width):
			var cell = cells[y][x]
			var cell_type = cell.get("type", _MazeGeneratorScript.CellType.WALL)

			_render_cell(x, y, cell_type)
			cell_count += 1

			# 创建碰撞 (墙壁)
			if generate_collision and cell_type == _MazeGeneratorScript.CellType.WALL:
				_create_collision_for_cell(x, y)

	# 创建特殊节点
	_create_special_nodes(maze_data)

	print("MazeRenderer: Created %d cells" % cell_count)
	print("MazeRenderer: maze_visual has %d children" % maze_visual.get_children().size())

	maze_rendered.emit()
	print("MazeRenderer: Maze rendered successfully")

## 渲染单个单元格
func _render_cell(x: int, y: int, cell_type: int) -> void:
	var color = _get_cell_color(cell_type)

	# 使用 Sprite2D 显示单元格
	var sprite = Sprite2D.new()
	sprite.name = "Cell_%d_%d" % [x, y]
	sprite.position = Vector2(x * cell_size + cell_size / 2, y * cell_size + cell_size / 2)
	sprite.centered = true
	sprite.z_index = 0

	# 创建单色纹理
	var image = Image.create(cell_size, cell_size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

	maze_visual.add_child(sprite)

	# 打印第一个单元格的信息
	if x == 0 and y == 0:
		print("First cell created: position=", sprite.position, " color=", color, " texture_size=", texture.get_size())

## 获取单元格颜色
func _get_cell_color(cell_type: int) -> Color:
	match cell_type:
		_MazeGeneratorScript.CellType.WALL:
			return wall_color
		_MazeGeneratorScript.CellType.PATH:
			return path_color
		_MazeGeneratorScript.CellType.ROOM:
			return room_color
		_MazeGeneratorScript.CellType.ENTRANCE:
			return entrance_color
		_MazeGeneratorScript.CellType.EXIT:
			return exit_color
		_MazeGeneratorScript.CellType.SECRET_DOOR:
			return path_color * 1.2
		_MazeGeneratorScript.CellType.TELEPORTER:
			return Color(0.5, 0.3, 0.7)
		_MazeGeneratorScript.CellType.TRAP:
			return Color(0.6, 0.4, 0.2)
		_:
			return wall_color

## 创建单元格碰撞
func _create_collision_for_cell(x: int, y: int) -> void:
	var collision = StaticBody2D.new()
	collision.position = Vector2(x * cell_size + cell_size / 2, y * cell_size + cell_size / 2)

	# 设置碰撞层 - 墙壁在 Environment 层 (layer 2)
	collision.collision_layer = 2  # Environment层
	collision.collision_mask = 0    # 不检测其他物体

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(cell_size, cell_size)
	shape.shape = rect

	collision.add_child(shape)
	collision_container.add_child(collision)

## 创建特殊节点
func _create_special_nodes(maze_data: Dictionary) -> void:
	# 入口
	var entrance = maze_data.get("entrance", Vector2i(-1, -1))
	if entrance.x >= 0:
		_create_entrance_node(entrance)

	# 出口
	var exit = maze_data.get("exit", Vector2i(-1, -1))
	if exit.x >= 0:
		_create_exit_node(exit)

	# 传送点
	var teleporters = maze_data.get("teleporters", [])
	for teleporter in teleporters:
		_create_teleporter_nodes(teleporter)

	# 陷阱
	var traps = maze_data.get("traps", [])
	for trap_pos in traps:
		_create_trap_node(trap_pos)

## 创建入口节点
func _create_entrance_node(pos: Vector2i) -> void:
	var local_pos = Vector2(pos.x * cell_size + cell_size / 2, pos.y * cell_size + cell_size / 2)
	var world_pos = to_global(local_pos)

	# 保存入口位置
	saved_entrance_position = world_pos
	print("Entrance saved at world position: ", saved_entrance_position)

	var node = _create_marker_node("Entrance", entrance_color, pos)
	special_nodes_container.add_child(node)
	special_node_created.emit("entrance", Vector2(pos.x * cell_size, pos.y * cell_size))
	print("Entrance created at maze pos: ", pos, " local pos: ", local_pos, " world pos: ", world_pos)

	# 创建一个更大的可见标记用于测试
	var test_marker = Sprite2D.new()
	test_marker.name = "EntranceMarker"
	test_marker.position = local_pos  # 使用局部坐标
	test_marker.centered = true
	test_marker.z_index = 100  # 确保在最上层
	var test_image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	test_image.fill(Color(1, 0.5, 0, 1))  # 明亮的橙色
	test_marker.texture = ImageTexture.create_from_image(test_image)
	special_nodes_container.add_child(test_marker)
	print("Test marker created at local: ", test_marker.position)

## 创建出口节点
func _create_exit_node(pos: Vector2i) -> void:
	var node = _create_marker_node("Exit", exit_color, pos)
	special_nodes_container.add_child(node)
	special_node_created.emit("exit", Vector2(pos.x * cell_size, pos.y * cell_size))

## 创建传送点节点
func _create_teleporter_nodes(teleporter: Dictionary) -> void:
	var from_pos = teleporter.get("from", Vector2i(-1, -1))
	var to_pos = teleporter.get("to", Vector2i(-1, -1))

	if from_pos.x >= 0:
		var node = _create_marker_node("Teleporter", Color(0.5, 0.3, 0.7), from_pos)
		node.set_meta("linked_position", to_pos)
		special_nodes_container.add_child(node)

## 创建陷阱节点
func _create_trap_node(pos: Vector2i) -> void:
	var node = _create_marker_node("Trap", Color(0.6, 0.4, 0.2), pos)
	special_nodes_container.add_child(node)

## 创建标记节点
func _create_marker_node(name: String, color: Color, pos: Vector2i) -> Node2D:
	var marker = Node2D.new()
	marker.name = name
	marker.position = Vector2(pos.x * cell_size + cell_size / 2, pos.y * cell_size + cell_size / 2)

	# 使用 Sprite2D
	var sprite = Sprite2D.new()
	var image = Image.create(int(cell_size * 0.6), int(cell_size * 0.6), false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true

	marker.add_child(sprite)

	return marker

# ============================================
# 清除迷宫
# ============================================

## 清除迷宫
func clear_maze() -> void:
	# 清除可视化
	if maze_visual:
		for child in maze_visual.get_children():
			child.queue_free()

	# 清除碰撞
	if collision_container:
		for child in collision_container.get_children():
			child.queue_free()

	# 清除特殊节点
	if special_nodes_container:
		for child in special_nodes_container.get_children():
			child.queue_free()

	# 重置数据
	current_maze = {}
	saved_entrance_position = Vector2(100, 100)
	print("MazeRenderer: Maze cleared")

	current_maze = {}

# ============================================
# 工具方法
# ============================================

## 获取世界坐标从迷宫坐标
func maze_to_world(maze_pos: Vector2i) -> Vector2:
	var local_pos = Vector2(maze_pos.x * cell_size + cell_size / 2, maze_pos.y * cell_size + cell_size / 2)
	return to_global(local_pos)

## 获取迷宫坐标从世界坐标
func world_to_maze(world_pos: Vector2) -> Vector2i:
	var local_pos = to_local(world_pos)
	return Vector2i(int(local_pos.x / cell_size), int(local_pos.y / cell_size))

## 获取入口世界坐标
func get_entrance_world_position() -> Vector2:
	# 优先使用保存的位置
	if saved_entrance_position != Vector2(100, 100):
		print("MazeRenderer: Returning saved entrance position: ", saved_entrance_position)
		return saved_entrance_position

	# 回退到从 current_maze 计算
	if current_maze.is_empty():
		print("MazeRenderer: current_maze is empty, returning default position")
		return Vector2(100, 100)

	var entrance = current_maze.get("entrance", Vector2i(-1, -1))
	if entrance.x >= 0:
		var world_pos = maze_to_world(entrance)
		print("MazeRenderer: entrance at maze pos ", entrance, " -> world pos ", world_pos)
		return world_pos

	print("MazeRenderer: no entrance found, returning default position")
	return Vector2(100, 100)

## 获取出口世界坐标
func get_exit_world_position() -> Vector2:
	if current_maze.is_empty():
		return Vector2.ZERO

	var exit = current_maze.get("exit", Vector2i(-1, -1))
	if exit.x >= 0:
		return maze_to_world(exit)

	return Vector2.ZERO

## 获取迷宫边界
func get_maze_bounds() -> Rect2:
	if current_maze.is_empty():
		return Rect2(Vector2.ZERO, Vector2(1000, 1000))

	var width = current_maze.get("width", 21)
	var height = current_maze.get("height", 21)

	return Rect2(Vector2.ZERO, Vector2(width * cell_size, height * cell_size))