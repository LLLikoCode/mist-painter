## MazeGenerator
## 迷宫生成器
## 使用递归回溯算法生成迷宫，支持房间插入和特殊地形

class_name MazeGenerator
extends RefCounted

# ============================================
# 常量定义 - 基于设计文档
# ============================================

## 迷宫单元格类型
enum CellType {
	WALL = 0,       # 墙壁
	PATH = 1,       # 通道
	ROOM = 2,       # 房间
	ENTRANCE = 3,   # 入口
	EXIT = 4,       # 出口
	SECRET_DOOR = 7,# 隐藏门
	TELEPORTER = 8, # 传送点
	TRAP = 9,       # 陷阱
}

## 房间类型
enum RoomType {
	STORAGE,     # 储藏室 3x3
	TREASURE,    # 宝藏室 4x4
	ALTAR,       # 祭坛 5x5
	LIBRARY,     # 图书馆 6x4
	TRAP_ROOM,   # 陷阱房 4x4
	SAFE_ROOM,   # 安全屋 4x4
	BOSS_ROOM,   # Boss房 7x7
}

## 层级配置
const LAYER_CONFIGS: Dictionary = {
	1: {"name": "表层遗迹", "size": 21, "memory_decay": 1800, "dynamic": false},
	2: {"name": "古代回廊", "size": 31, "memory_decay": 1200, "dynamic": true},
	3: {"name": "迷失深渊", "size": 41, "memory_decay": 600, "dynamic": true},
	4: {"name": "混沌核心", "size": 51, "memory_decay": 300, "dynamic": true},
}

## 房间尺寸配置
const ROOM_SIZES: Dictionary = {
	RoomType.STORAGE: Vector2i(3, 3),
	RoomType.TREASURE: Vector2i(4, 4),
	RoomType.ALTAR: Vector2i(5, 5),
	RoomType.LIBRARY: Vector2i(6, 4),
	RoomType.TRAP_ROOM: Vector2i(4, 4),
	RoomType.SAFE_ROOM: Vector2i(4, 4),
	RoomType.BOSS_ROOM: Vector2i(7, 7),
}

# ============================================
# 状态变量
# ============================================

## 随机数生成器
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## 当前迷宫数据
var maze_data: Dictionary = {}

## 当前层级
var current_layer: int = 1

# ============================================
# 信号
# ============================================

signal maze_generated(maze_data: Dictionary)
signal room_placed(room_type: int, position: Vector2i)

# ============================================
# 公共方法
# ============================================

## 生成迷宫
func generate(layer: int = 1, seed_value: String = "") -> Dictionary:
	# 设置随机种子
	if seed_value.is_empty():
		rng.randomize()
	else:
		rng.seed = hash(seed_value)

	current_layer = layer
	var config = LAYER_CONFIGS.get(layer, LAYER_CONFIGS[1])
	var size = config.get("size", 21)

	# 确保奇数尺寸
	var width = size if size % 2 == 1 else size + 1
	var height = width

	print("MazeGenerator: Generating layer %d maze (%dx%d)" % [layer, width, height])

	# 初始化迷宫
	maze_data = _init_maze(width, height, layer)

	# 递归回溯生成迷宫
	_recursive_backtrack(maze_data)

	# 插入房间
	_insert_rooms(maze_data)

	# 设置入口和出口
	_set_entrance_exit(maze_data)

	# 添加特殊地形
	_add_special_terrain(maze_data)

	# 保存种子
	maze_data["seed"] = seed_value if not seed_value.is_empty() else str(rng.seed)

	maze_generated.emit(maze_data)

	print("MazeGenerator: Maze generated successfully")
	return maze_data

## 从种子生成迷宫
func generate_from_seed(layer: int, seed_value: String) -> Dictionary:
	return generate(layer, seed_value)

# ============================================
# 初始化迷宫
# ============================================

## 初始化迷宫数据结构
func _init_maze(width: int, height: int, layer: int) -> Dictionary:
	var cells = []

	for y in range(height):
		var row = []
		for x in range(width):
			row.append({
				"x": x,
				"y": y,
				"type": CellType.WALL,
				"discovered": false,
				"visible": false
			})
		cells.append(row)

	return {
		"width": width,
		"height": height,
		"layer": layer,
		"cells": cells,
		"rooms": [],
		"entrance": Vector2i(-1, -1),
		"exit": Vector2i(-1, -1),
		"teleporters": [],
		"traps": [],
		"secret_doors": [],
	}

# ============================================
# 递归回溯算法
# ============================================

## 递归回溯生成迷宫
func _recursive_backtrack(maze: Dictionary) -> void:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 起始点 (1, 1) - 必须是奇数坐标
	var stack = []
	var start = Vector2i(1, 1)
	stack.append(start)
	cells[start.y][start.x]["type"] = CellType.PATH

	while stack.size() > 0:
		var current = stack.back()
		var neighbors = _get_unvisited_neighbors(maze, current)

		if neighbors.size() > 0:
			# 随机选择一个邻居
			var next = neighbors[rng.randi() % neighbors.size()]

			# 打通之间的墙壁
			var wall = Vector2i((current.x + next.x) / 2, (current.y + next.y) / 2)
			cells[wall.y][wall.x]["type"] = CellType.PATH

			# 标记邻居为通路
			cells[next.y][next.x]["type"] = CellType.PATH

			# 邻居压入栈
			stack.append(next)
		else:
			# 回溯
			stack.pop_back()

## 获取未访问的邻居
func _get_unvisited_neighbors(maze: Dictionary, pos: Vector2i) -> Array:
	var neighbors = []
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 四个方向，间隔2格
	var directions = [
		Vector2i(0, -2),  # 上
		Vector2i(0, 2),   # 下
		Vector2i(-2, 0),  # 左
		Vector2i(2, 0),   # 右
	]

	for dir in directions:
		var nx = pos.x + dir.x
		var ny = pos.y + dir.y

		# 检查边界
		if nx > 0 and nx < width - 1 and ny > 0 and ny < height - 1:
			# 检查是否未访问
			if cells[ny][nx]["type"] == CellType.WALL:
				neighbors.append(Vector2i(nx, ny))

	return neighbors

# ============================================
# 房间插入
# ============================================

## 插入房间
func _insert_rooms(maze: Dictionary) -> void:
	var width = maze["width"]
	var height = maze["height"]
	var layer = maze["layer"]

	# 根据迷宫大小确定房间数量
	var room_count = _calculate_room_count(width, layer)

	for i in range(room_count):
		var room_type = _select_room_type(layer)
		var room_size = ROOM_SIZES.get(room_type, Vector2i(3, 3))

		# 尝试放置房间
		var placed = _try_place_room(maze, room_type, room_size)
		if placed:
			room_placed.emit(room_type, placed["position"])

## 计算房间数量
func _calculate_room_count(maze_size: int, layer: int) -> int:
	# 基于迷宫大小和层级计算房间数量
	var base_count = maze_size / 10
	var layer_bonus = layer - 1
	return base_count + layer_bonus

## 选择房间类型
func _select_room_type(layer: int) -> int:
	var weights = {
		RoomType.STORAGE: 40,
		RoomType.TREASURE: 25,
		RoomType.SAFE_ROOM: 20,
		RoomType.TRAP_ROOM: 15,
	}

	# 高层级添加更多特殊房间
	if layer >= 2:
		weights[RoomType.ALTAR] = 10
		weights[RoomType.LIBRARY] = 5

	if layer >= 3:
		weights[RoomType.BOSS_ROOM] = 1

	# 加权随机选择
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight

	var roll = rng.randi() % total_weight
	var cumulative = 0

	for room_type in weights:
		cumulative += weights[room_type]
		if roll < cumulative:
			return room_type

	return RoomType.STORAGE

## 尝试放置房间
func _try_place_room(maze: Dictionary, room_type: int, room_size: Vector2i) -> Dictionary:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 确保房间在奇数坐标上
	var max_attempts = 50

	for attempt in range(max_attempts):
		# 房间位置 (必须是奇数坐标)
		var room_x = (rng.randi() % ((width - room_size.x - 2) / 2)) * 2 + 1
		var room_y = (rng.randi() % ((height - room_size.y - 2) / 2)) * 2 + 1

		# 检查是否与其他房间重叠
		if _can_place_room(maze, room_x, room_y, room_size):
			# 放置房间
			for y in range(room_y, room_y + room_size.y):
				for x in range(room_x, room_x + room_size.x):
					cells[y][x]["type"] = CellType.ROOM

			# 记录房间
			var room_data = {
				"type": room_type,
				"position": Vector2i(room_x, room_y),
				"size": room_size
			}
			maze["rooms"].append(room_data)

			# 连接房间到迷宫
			_connect_room_to_maze(maze, room_x, room_y, room_size)

			return room_data

	return {}

## 检查是否可以放置房间
func _can_place_room(maze: Dictionary, x: int, y: int, size: Vector2i) -> bool:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 检查边界
	if x + size.x >= width - 1 or y + size.y >= height - 1:
		return false

	# 检查是否与现有房间或通路重叠
	for dy in range(y - 1, y + size.y + 1):
		for dx in range(x - 1, x + size.x + 1):
			if dx < 0 or dx >= width or dy < 0 or dy >= height:
				continue
			if cells[dy][dx]["type"] != CellType.WALL:
				return false

	return true

## 连接房间到迷宫
func _connect_room_to_maze(maze: Dictionary, room_x: int, room_y: int, room_size: Vector2i) -> void:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 找到房间周围的通路
	var connections = []

	# 检查四个边
	for y in range(room_y, room_y + room_size.y):
		# 左边
		if room_x > 1 and cells[y][room_x - 2]["type"] == CellType.PATH:
			connections.append(Vector2i(room_x - 1, y))
		# 右边
		if room_x + room_size.x + 1 < width and cells[y][room_x + room_size.x + 1]["type"] == CellType.PATH:
			connections.append(Vector2i(room_x + room_size.x, y))

	for x in range(room_x, room_x + room_size.x):
		# 上边
		if room_y > 1 and cells[room_y - 2][x]["type"] == CellType.PATH:
			connections.append(Vector2i(x, room_y - 1))
		# 下边
		if room_y + room_size.y + 1 < height and cells[room_y + room_size.y + 1][x]["type"] == CellType.PATH:
			connections.append(Vector2i(x, room_y + room_size.y))

	# 随机选择一个连接点打通
	if connections.size() > 0:
		var connection = connections[rng.randi() % connections.size()]
		cells[connection.y][connection.x]["type"] = CellType.PATH

# ============================================
# 入口和出口
# ============================================

## 设置入口和出口
func _set_entrance_exit(maze: Dictionary) -> void:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 找到最远的两个点作为入口和出口
	var path_points = []

	for y in range(height):
		for x in range(width):
			if cells[y][x]["type"] == CellType.PATH or cells[y][x]["type"] == CellType.ROOM:
				path_points.append(Vector2i(x, y))

	if path_points.size() < 2:
		return

	# 入口：左上区域
	var entrance = _find_farthest_point(path_points, Vector2i(1, 1))
	cells[entrance.y][entrance.x]["type"] = CellType.ENTRANCE
	maze["entrance"] = entrance

	# 出口：右下区域
	var exit = _find_farthest_point(path_points, Vector2i(width - 2, height - 2))
	cells[exit.y][exit.x]["type"] = CellType.EXIT
	maze["exit"] = exit

## 找到距离某点最远的路径点
func _find_farthest_point(points: Array, target: Vector2i) -> Vector2i:
	var max_dist = -1
	var farthest = points[0]

	for point in points:
		var dist = abs(point.x - target.x) + abs(point.y - target.y)
		if dist > max_dist:
			max_dist = dist
			farthest = point

	return farthest

# ============================================
# 特殊地形
# ============================================

## 添加特殊地形
func _add_special_terrain(maze: Dictionary) -> void:
	var layer = maze["layer"]

	# 根据层级添加特殊地形
	if layer >= 2:
		_add_secret_doors(maze)
		_add_traps(maze)

	if layer >= 3:
		_add_teleporters(maze)

## 添加隐藏门
func _add_secret_doors(maze: Dictionary) -> void:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 找到可以放置隐藏门的墙壁
	var candidates = []

	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if cells[y][x]["type"] == CellType.WALL:
				# 检查是否两侧都是通路
				var horizontal = cells[y][x - 1]["type"] in [CellType.PATH, CellType.ROOM] and \
						cells[y][x + 1]["type"] in [CellType.PATH, CellType.ROOM]
				var vertical = cells[y - 1][x]["type"] in [CellType.PATH, CellType.ROOM] and \
						cells[y + 1][x]["type"] in [CellType.PATH, CellType.ROOM]

				if horizontal or vertical:
					candidates.append(Vector2i(x, y))

	# 随机选择一些作为隐藏门
	var secret_count = max(1, candidates.size() / 20)
	for i in range(min(secret_count, candidates.size())):
		var idx = rng.randi() % candidates.size()
		var pos = candidates[idx]
		cells[pos.y][pos.x]["type"] = CellType.SECRET_DOOR
		maze["secret_doors"].append(pos)
		candidates.remove_at(idx)

		if candidates.is_empty():
			break

## 添加陷阱
func _add_traps(maze: Dictionary) -> void:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 找到可以放置陷阱的通路
	var candidates = []

	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if cells[y][x]["type"] == CellType.PATH:
				# 不要在入口或出口附近放置陷阱
				var entrance = maze["entrance"]
				var exit = maze["exit"]
				var dist_to_entrance = abs(x - entrance.x) + abs(y - entrance.y)
				var dist_to_exit = abs(x - exit.x) + abs(y - exit.y)

				if dist_to_entrance > 3 and dist_to_exit > 3:
					candidates.append(Vector2i(x, y))

	# 随机选择一些作为陷阱
	var trap_count = max(1, candidates.size() / 25)
	for i in range(min(trap_count, candidates.size())):
		var idx = rng.randi() % candidates.size()
		var pos = candidates[idx]
		cells[pos.y][pos.x]["type"] = CellType.TRAP
		maze["traps"].append(pos)
		candidates.remove_at(idx)

		if candidates.is_empty():
			break

## 添加传送点
func _add_teleporters(maze: Dictionary) -> void:
	var cells = maze["cells"]
	var width = maze["width"]
	var height = maze["height"]

	# 找到可以放置传送点的通路
	var candidates = []

	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if cells[y][x]["type"] == CellType.PATH:
				candidates.append(Vector2i(x, y))

	# 创建成对的传送点
	var teleporter_count = 2  # 一对传送点
	if candidates.size() < teleporter_count * 2:
		return

	for i in range(teleporter_count):
		# 选择第一个传送点
		var idx1 = rng.randi() % candidates.size()
		var pos1 = candidates[idx1]
		candidates.remove_at(idx1)

		# 选择第二个传送点（距离较远的）
		var idx2 = rng.randi() % candidates.size()
		var pos2 = candidates[idx2]
		candidates.remove_at(idx2)

		# 设置传送点
		cells[pos1.y][pos1.x]["type"] = CellType.TELEPORTER
		cells[pos2.y][pos2.x]["type"] = CellType.TELEPORTER

		# 记录传送点对
		maze["teleporters"].append({"from": pos1, "to": pos2})

# ============================================
# 工具方法
# ============================================

## 获取迷宫单元格
func get_cell(maze: Dictionary, x: int, y: int) -> Dictionary:
	var cells = maze.get("cells", [])
	if y >= 0 and y < cells.size() and x >= 0 and x < cells[y].size():
		return cells[y][x]
	return {}

## 检查是否是通路
func is_walkable(maze: Dictionary, x: int, y: int) -> bool:
	var cell = get_cell(maze, x, y)
	var cell_type = cell.get("type", CellType.WALL)
	return cell_type != CellType.WALL

## 获取迷宫尺寸
func get_maze_size(layer: int) -> int:
	var config = LAYER_CONFIGS.get(layer, LAYER_CONFIGS[1])
	return config.get("size", 21)

## 获取层级配置
func get_layer_config(layer: int) -> Dictionary:
	return LAYER_CONFIGS.get(layer, LAYER_CONFIGS[1])

## 导出迷宫为字符串（调试用）
func export_maze_to_string(maze: Dictionary) -> String:
	var result = ""
	var cells = maze["cells"]

	for row in cells:
		var line = ""
		for cell in row:
			match cell["type"]:
				CellType.WALL: line += "#"
				CellType.PATH: line += "."
				CellType.ROOM: line += "R"
				CellType.ENTRANCE: line += "S"
				CellType.EXIT: line += "E"
				CellType.SECRET_DOOR: line += "?"
				CellType.TELEPORTER: line += "T"
				CellType.TRAP: line += "X"
				_: line += "?"
		result += line + "\n"

	return result