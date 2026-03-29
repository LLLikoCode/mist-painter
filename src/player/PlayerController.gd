## PlayerController
## 玩家角色控制器
## 负责处理玩家的移动、动画、交互和迷雾绘制输入

class_name PlayerController
extends CharacterBody2D

# ============================================
# 常量定义
# ============================================

## 移动速度
const MOVE_SPEED: float = 150.0
const SPRINT_SPEED: float = 250.0

## 加速度/减速度
const ACCELERATION: float = 800.0
const FRICTION: float = 1000.0

## 动画参数
const ANIM_IDLE_THRESHOLD: float = 10.0

## 墨水消耗率 (每次绘制消耗)
const INK_COST_PER_DRAW: float = 0.5

# ============================================
# 导出变量
# ============================================

@export_group("Movement")
@export var move_speed: float = MOVE_SPEED
@export var sprint_speed: float = SPRINT_SPEED
@export var acceleration: float = ACCELERATION
@export var friction: float = FRICTION

@export_group("Interaction")
@export var interaction_radius: float = 50.0
@export var interaction_cooldown: float = 0.3

@export_group("Mist Painting")
@export var can_paint_mist: bool = true
@export var paint_cooldown: float = 0.1
@export var ink_cost_multiplier: float = 1.0

# ============================================
# 节点引用
# ============================================

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ============================================
# 资源系统
# ============================================

## 玩家资源管理
var stats: PlayerStats = null

# ============================================
# 状态变量
# ============================================

## 当前移动方向
var current_direction: Vector2 = Vector2.ZERO

## 当前朝向 (用于动画)
var facing_direction: String = "down"  # down, up, left, right

## 是否正在冲刺
var is_sprinting: bool = false

## 是否正在绘制迷雾
var is_painting: bool = false

## 交互冷却计时器
var interaction_timer: float = 0.0

## 绘制冷却计时器
var paint_timer: float = 0.0

## 当前可交互对象
var current_interactable: Node = null

# ============================================
# 信号
# ============================================

signal moved(position: Vector2, velocity: Vector2)
signal direction_changed(new_direction: String)
signal interaction_started(target: Node)
signal paint_started(position: Vector2)
signal paint_ended(position: Vector2)
signal paint_moved(position: Vector2)
signal ink_consumed(amount: float)
signal player_died

# ============================================
# 生命周期
# ============================================

func _ready():
	# 初始化资源系统
	_init_stats()

	# 确保碰撞层设置正确
	collision_layer = 1  # Player层
	collision_mask = 2   # Environment 层

	# 设置交互区域
	if interaction_area:
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = 4  # Interactables层
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)

	# 初始化动画
	_update_animation("idle")

	print("PlayerController initialized")

## 初始化资源系统
func _init_stats() -> void:
	stats = PlayerStats.new()
	stats.name = "PlayerStats"
	add_child(stats)

	# 连接资源信号
	stats.player_died.connect(_on_player_died)
	stats.ink_depleted.connect(_on_ink_depleted)

func _physics_process(delta: float):
	# 更新计时器
	_update_timers(delta)

	# 处理输入
	_handle_input(delta)

	# 应用移动
	_apply_movement(delta)

	# 更新动画
	_update_animation_based_on_velocity()

func _process(_delta: float):
	# 处理迷雾绘制输入
	_handle_paint_input()

func _input(event: InputEvent):
	# 处理交互输入
	if event.is_action_pressed("interact") and interaction_timer <= 0:
		_try_interact()

# ============================================
# 资源系统方法
# ============================================

## 获取玩家资源
func get_stats() -> PlayerStats:
	return stats

## 受到伤害
func take_damage(amount: float) -> void:
	if stats and not stats.is_dead:
		stats.take_damage(amount)

## 恢复生命值
func heal(amount: float) -> void:
	if stats:
		stats.heal(amount)

## 消耗墨水
func consume_ink(amount: float) -> bool:
	if stats:
		return stats.consume_ink(amount * ink_cost_multiplier)
	return false

## 恢复墨水
func restore_ink(amount: float) -> void:
	if stats:
		stats.restore_ink(amount)

## 检查墨水是否足够
func has_enough_ink(amount: float) -> bool:
	if stats:
		return stats.has_enough_ink(amount)
	return false

## 获取当前墨水量
func get_current_ink() -> float:
	if stats:
		return stats.current_ink
	return 0.0

## 玩家死亡处理
func _on_player_died() -> void:
	player_died.emit()
	disable_movement()
	disable_painting()
	print("Player died!")

## 墨水耗尽处理
func _on_ink_depleted() -> void:
	# 墨水耗尽时停止绘制
	if is_painting:
		is_painting = false
		paint_ended.emit(global_position)

# ============================================
# 输入处理
# ============================================

## 处理移动输入
func _handle_input(_delta: float) -> void:
	# 获取输入方向
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")

	# 归一化对角线移动
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()

	current_direction = input_direction

	# 检测冲刺
	is_sprinting = Input.is_action_pressed("sprint")

## 处理迷雾绘制输入
func _handle_paint_input() -> void:
	if not can_paint_mist:
		return

	# 检查是否死亡
	if stats and stats.is_dead:
		return

	var is_paint_pressed = Input.is_action_pressed("paint_mist")

	# 获取鼠标在世界中的位置（用于迷雾绘制）
	var mouse_world_pos = get_global_mouse_position()

	if is_paint_pressed and paint_timer <= 0:
		# 检查墨水是否足够
		if not has_enough_ink(INK_COST_PER_DRAW):
			# 墨水不足，无法绘制
			if is_painting:
				is_painting = false
				paint_ended.emit(mouse_world_pos)
			return

		if not is_painting:
			is_painting = true
			paint_started.emit(mouse_world_pos)
		else:
			paint_moved.emit(mouse_world_pos)

		# 消耗墨水
		if consume_ink(INK_COST_PER_DRAW):
			ink_consumed.emit(INK_COST_PER_DRAW * ink_cost_multiplier)

		paint_timer = paint_cooldown
	elif not is_paint_pressed and is_painting:
		is_painting = false
		paint_ended.emit(mouse_world_pos)

# ============================================
# 移动处理
# ============================================

## 应用移动
func _apply_movement(delta: float) -> void:
	var target_speed = sprint_speed if is_sprinting else move_speed

	if current_direction != Vector2.ZERO:
		# 加速
		velocity = velocity.move_toward(current_direction * target_speed, acceleration * delta)
	else:
		# 减速
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# 移动并滑动
	move_and_slide()

	# 发送移动信号
	if velocity.length() > ANIM_IDLE_THRESHOLD:
		moved.emit(global_position, velocity)

## 根据速度更新动画
func _update_animation_based_on_velocity() -> void:
	# 确定朝向
	if velocity.length() > ANIM_IDLE_THRESHOLD:
		var new_facing = _get_facing_from_velocity(velocity)
		if new_facing != facing_direction:
			facing_direction = new_facing
			direction_changed.emit(facing_direction)

		_update_animation("walk")
	else:
		_update_animation("idle")

## 根据速度获取朝向
func _get_facing_from_velocity(vel: Vector2) -> String:
	if abs(vel.x) > abs(vel.y):
		return "right" if vel.x > 0 else "left"
	else:
		return "down" if vel.y > 0 else "up"

## 更新动画
func _update_animation(anim_state: String) -> void:
	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	var anim_name = anim_state + "_" + facing_direction

	# 检查动画是否存在
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	else:
		# 回退到默认动画
		var fallback = anim_state + "_down"
		if sprite.sprite_frames.has_animation(fallback):
			if sprite.animation != fallback:
				sprite.play(fallback)

# ============================================
# 交互处理
# ============================================

## 尝试交互
func _try_interact() -> void:
	if current_interactable == null:
		return

	interaction_timer = interaction_cooldown

	# 调用交互对象的方法
	if current_interactable.has_method("interact"):
		current_interactable.interact(self)
		interaction_started.emit(current_interactable)

		# 播放交互动画
		_play_interact_animation()

## 播放交互动画
func _play_interact_animation() -> void:
	# 可以添加短暂的交互动画
	pass

## 交互区域进入
func _on_interaction_area_entered(area: Area2D) -> void:
	if area.has_method("can_interact") and area.can_interact():
		current_interactable = area
		# 可以在这里显示交互提示UI
		if area.has_method("show_interaction_hint"):
			area.show_interaction_hint()

## 交互区域退出
func _on_interaction_area_exited(area: Area2D) -> void:
	if area == current_interactable:
		if area.has_method("hide_interaction_hint"):
			area.hide_interaction_hint()
		current_interactable = null

# ============================================
# 计时器更新
# ============================================

func _update_timers(delta: float) -> void:
	if interaction_timer > 0:
		interaction_timer -= delta

	if paint_timer > 0:
		paint_timer -= delta

# ============================================
# 公共方法
# ============================================

## 设置位置（带安全检测）
func set_player_position(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO

## 获取当前朝向
func get_facing_direction() -> String:
	return facing_direction

## 获取朝向向量
func get_facing_vector() -> Vector2:
	match facing_direction:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN

## 禁用移动
func disable_movement() -> void:
	set_physics_process(false)

## 启用移动
func enable_movement() -> void:
	set_physics_process(true)

## 禁用迷雾绘制
func disable_painting() -> void:
	can_paint_mist = false
	if is_painting:
		is_painting = false
		paint_ended.emit(global_position)

## 启用迷雾绘制
func enable_painting() -> void:
	can_paint_mist = true

## 是否正在移动
func is_moving() -> bool:
	return velocity.length() > ANIM_IDLE_THRESHOLD

## 是否正在绘制
func is_painting_mist() -> bool:
	return is_painting

## 获取当前速度
func get_current_speed() -> float:
	return velocity.length()