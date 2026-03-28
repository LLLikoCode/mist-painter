## IRenderable
## 可渲染接口
## 定义可以被渲染系统渲染的对象接口

class_name IRenderable
extends RefCounted

## 渲染层级
var render_layer: int = 0

## 是否可见
var is_visible: bool = true

## 渲染优先级（同层级内排序）
var render_priority: int = 0

## 渲染边界（用于裁剪）
var render_bounds: Rect2 = Rect2()

## 获取渲染位置
func get_render_position() -> Vector2:
	return Vector2.ZERO

## 获取渲染旋转
func get_render_rotation() -> float:
	return 0.0

## 获取渲染缩放
func get_render_scale() -> Vector2:
	return Vector2.ONE

## 执行渲染
## canvas_item: 渲染目标CanvasItem
## offset: 渲染偏移
func render(canvas_item: CanvasItem, offset: Vector2 = Vector2.ZERO) -> void:
	pass

## 设置可见性
func set_visible(visible: bool) -> void:
	is_visible = visible

## 设置渲染层级
func set_render_layer(layer: int) -> void:
	render_layer = layer

## 检查是否需要渲染
func should_render(viewport_rect: Rect2) -> bool:
	if not is_visible:
		return false
	return render_bounds.intersects(viewport_rect)
