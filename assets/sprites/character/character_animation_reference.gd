# 迷雾绘者 (Mist Painter) - 角色动画配置参考
# 此文件提供Godot 4.x中角色动画的配置示例
# 可直接复制到项目中使用或作为参考

extends CharacterBody2D

# 动画参数
const ANIM_FPS_IDLE = 4       # 待机动画帧率
const ANIM_FPS_WALK = 12      # 行走动画帧率
const ANIM_FPS_INTERACT = 8   # 交互动画帧率

# Sprite尺寸
const FRAME_WIDTH = 32
const FRAME_HEIGHT = 48

# 动画帧数
const IDLE_FRAMES = 4
const WALK_FRAMES = 8
const INTERACT_FRAMES = 4

# 节点引用
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	_setup_animations()
	play_animation("idle")

func _setup_animations():
	"""设置角色动画"""
	
	# 创建SpriteFrames资源
	var sprite_frames = SpriteFrames.new()
	
	# ========== 待机动画 ==========
	var idle_frames = []
	for i in range(IDLE_FRAMES):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = preload("res://assets/sprites/character/character_idle.png")
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		idle_frames.append(atlas_texture)
	
	sprite_frames.add_animation("idle")
	for frame in idle_frames:
		sprite_frames.add_frame("idle", frame)
	sprite_frames.set_animation_speed("idle", ANIM_FPS_IDLE)
	sprite_frames.set_animation_loop("idle", true)
	
	# ========== 行走动画 ==========
	var walk_frames = []
	for i in range(WALK_FRAMES):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = preload("res://assets/sprites/character/character_walk.png")
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		walk_frames.append(atlas_texture)
	
	sprite_frames.add_animation("walk")
	for frame in walk_frames:
		sprite_frames.add_frame("walk", frame)
	sprite_frames.set_animation_speed("walk", ANIM_FPS_WALK)
	sprite_frames.set_animation_loop("walk", true)
	
	# ========== 交互动画 ==========
	var interact_frames = []
	for i in range(INTERACT_FRAMES):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = preload("res://assets/sprites/character/character_interact.png")
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		interact_frames.append(atlas_texture)
	
	sprite_frames.add_animation("interact")
	for frame in interact_frames:
		sprite_frames.add_frame("interact", frame)
	sprite_frames.set_animation_speed("interact", ANIM_FPS_INTERACT)
	sprite_frames.set_animation_loop("interact", false)
	
	# 应用SpriteFrames
	sprite.sprite_frames = sprite_frames

func play_animation(anim_name: String):
	"""播放指定动画"""
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func play_idle():
	"""播放待机动画"""
	play_animation("idle")

func play_walk():
	"""播放行走动画"""
	play_animation("walk")

func play_interact():
	"""播放交互动画"""
	play_animation("interact")
	# 等待动画完成后返回待机
	await sprite.animation_finished
	play_idle()

# ========== 使用完整Sprite Sheet的替代方案 ==========
# 如果使用 character_sprite_sheet.png (包含所有动画)

func _setup_animations_from_sheet():
	"""从完整Sprite Sheet设置动画"""
	
	var sprite_frames = SpriteFrames.new()
	var full_sheet = preload("res://assets/sprites/character/character_sprite_sheet.png")
	
	# 待机动画: 帧 0-3
	sprite_frames.add_animation("idle")
	for i in range(4):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = full_sheet
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		sprite_frames.add_frame("idle", atlas_texture)
	sprite_frames.set_animation_speed("idle", ANIM_FPS_IDLE)
	
	# 行走动画: 帧 4-11
	sprite_frames.add_animation("walk")
	for i in range(4, 12):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = full_sheet
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		sprite_frames.add_frame("walk", atlas_texture)
	sprite_frames.set_animation_speed("walk", ANIM_FPS_WALK)
	
	# 交互动画: 帧 12-15
	sprite_frames.add_animation("interact")
	for i in range(12, 16):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = full_sheet
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		sprite_frames.add_frame("interact", atlas_texture)
	sprite_frames.set_animation_speed("interact", ANIM_FPS_INTERACT)
	sprite_frames.set_animation_loop("interact", false)
	
	sprite.sprite_frames = sprite_frames

# ========== 场景树配置示例 ==========
#
# Player (CharacterBody2D)
# ├── CollisionShape2D
# │   └── shape: RectangleShape2D (32×48)
# └── AnimatedSprite2D
#     └── 使用上述代码配置动画
#
# ========== 输入处理示例 ==========

func _physics_process(delta):
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_dir != Vector2.ZERO:
		velocity = input_dir * 100  # 移动速度
		play_walk()
		
		# 根据移动方向翻转精灵
		if input_dir.x < 0:
			sprite.flip_h = true
		elif input_dir.x > 0:
			sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
		play_idle()
	
	move_and_slide()

func _input(event):
	# 交互按键
	if event.is_action_pressed("interact"):
		play_interact()
