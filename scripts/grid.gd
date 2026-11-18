extends Node2D

@export var spacing: float = 40.0

var grid_color := Color(0.35, 0.38, 0.42, 0.35)
var axis_color := Color(0.75, 0.78, 0.82, 0.9)

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)

func _draw() -> void:
	if spacing <= 0.0:
		return

	var view_top_left := to_local(Vector2.ZERO)
	var view_bottom_right := to_local(get_viewport_rect().size)

	var x := floorf(view_top_left.x / spacing) * spacing
	while x <= view_bottom_right.x:
		draw_line(Vector2(x, view_top_left.y), Vector2(x, view_bottom_right.y), grid_color)
		x += spacing

	var y := floorf(view_top_left.y / spacing) * spacing
	while y <= view_bottom_right.y:
		draw_line(Vector2(view_top_left.x, y), Vector2(view_bottom_right.x, y), grid_color)
		y += spacing

	draw_line(Vector2(view_top_left.x, 0), Vector2(view_bottom_right.x, 0), axis_color, 2.0)
	draw_line(Vector2(0, view_top_left.y), Vector2(0, view_bottom_right.y), axis_color, 2.0)
