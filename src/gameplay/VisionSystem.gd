## VisionSystem
## 视野限制系统
## 使用 Shader + SCREEN_UV

class_name VisionSystem
extends Node2D

const BASE_VISION_RADIUS: float = 3.0
const CELL_SIZE: float = 50.0

@export_group("Vision Settings")
@export var base_vision_radius: float = BASE_VISION_RADIUS
@export var enable_vision_limit: bool = true

var current_vision_radius: float = BASE_VISION_RADIUS * CELL_SIZE
var light_bonus: float = 0.0
var fatigue_penalty: int = 0

var darkness_layer: CanvasLayer = null
var darkness_rect: ColorRect = null
var target_player: PlayerController = null

func _ready():
	if enable_vision_limit:
		_create_vision_mask()
	print("VisionSystem initialized")

func _process(delta: float):
	if not enable_vision_limit:
		return
	_update_vision()

func _create_vision_mask() -> void:
	# CanvasLayer 跟随相机
	darkness_layer = CanvasLayer.new()
	darkness_layer.name = "DarknessLayer"
	darkness_layer.layer = 100
	darkness_layer.follow_viewport_enabled = true
	add_child(darkness_layer)

	# ColorRect 覆盖屏幕
	darkness_rect = ColorRect.new()
	darkness_rect.name = "DarknessRect"
	darkness_rect.color = Color(0, 0, 0, 1)
	darkness_rect.z_index = 100

	# 设置锚点全屏（在CanvasLayer中需要直接设置size）
	darkness_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Shader 使用 SCREEN_UV 和屏幕坐标
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform vec2 player_screen_pos;  // 玩家在屏幕上的位置（像素）
uniform float vision_radius;
uniform vec2 screen_size;  // 实际屏幕尺寸

void fragment() {
	// SCREEN_UV 是屏幕坐标的UV (0-1范围)
	vec2 pixel_pos = SCREEN_UV * screen_size;

	float dist = length(pixel_pos - player_screen_pos);
	float inner = vision_radius - 50.0;

	if (dist < inner) {
		// 视野内完全透明
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else if (dist < vision_radius) {
		// 渐变边缘
		float alpha = (dist - inner) / 50.0;
		COLOR = vec4(0.0, 0.0, 0.0, clamp(alpha, 0.0, 1.0));
	} else {
		// 视野外完全黑色
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
"""

	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	darkness_rect.material = shader_mat

	darkness_layer.add_child(darkness_rect)
	print("Vision mask created")

func _update_vision() -> void:
	var total_radius = base_vision_radius * CELL_SIZE
	total_radius += light_bonus * CELL_SIZE
	total_radius -= fatigue_penalty * CELL_SIZE
	total_radius = max(CELL_SIZE * 1.5, total_radius)
	current_vision_radius = total_radius

	if darkness_rect and darkness_rect.material:
		var shader_mat = darkness_rect.material as ShaderMaterial
		if shader_mat:
			var screen_size = get_viewport().get_visible_rect().size
			var player_screen_pos = screen_size / 2  # 默认屏幕中心

			if target_player:
				var camera = get_viewport().get_camera_2d()
				if camera:
					var player_world = target_player.global_position
					var camera_world = camera.global_position
					# 玩家屏幕位置 = 屏幕中心 + (玩家-相机偏移)
					player_screen_pos = screen_size / 2 + (player_world - camera_world)
					# 每秒打印一次调试信息
					if Engine.get_frames_drawn() % 60 == 0:
						print("Vision: screen_size=", screen_size, " player_screen=", player_screen_pos, " radius=", current_vision_radius)

			shader_mat.set_shader_parameter("player_screen_pos", player_screen_pos)
			shader_mat.set_shader_parameter("vision_radius", current_vision_radius)
			shader_mat.set_shader_parameter("screen_size", screen_size)

			# 更新屏幕尺寸uniform（通过重新设置shader代码中的screen_size）
			# 注意：SCREEN_UV自动使用实际屏幕尺寸，这里只需要传入正确的player_screen_pos

func set_target_player(player: PlayerController) -> void:
	target_player = player
	if target_player:
		print("VisionSystem: Target player set")

func set_light_bonus(bonus: float) -> void:
	light_bonus = bonus

func set_fatigue_penalty(penalty: int) -> void:
	fatigue_penalty = penalty

func get_vision_radius() -> float:
	return current_vision_radius

func get_vision_radius_cells() -> float:
	return current_vision_radius / CELL_SIZE

func set_vision_enabled(enabled: bool) -> void:
	enable_vision_limit = enabled
	if darkness_layer:
		darkness_layer.visible = enabled

func reset_vision() -> void:
	light_bonus = 0.0
	fatigue_penalty = 0
	current_vision_radius = base_vision_radius * CELL_SIZE
	print("VisionSystem reset")