extends Area2D
class_name PortalTarget

signal completed

const GLOW_COLOR := Color("#52D6FF", 0.12)
const OUTER_COLOR := Color("#52D6FF", 0.9)
const INNER_COLOR := Color("#8D79FF", 0.82)
const PARTICLE_COLOR := Color("#C8F7FF")
const CENTER_COLOR := Color("#FFF2B3")

@export_range(24.0, 100.0, 1.0)
var completion_radius: float = 72.0

var _animation_time := 0.0
var _is_complete := false


func _ready() -> void:
	add_to_group("completion_sources")


func _process(delta: float) -> void:
	_animation_time += delta
	queue_redraw()
	if _is_complete:
		return

	var character := get_parent().get_node_or_null("Character") as CharacterBody2D
	if character == null:
		return

	if character.global_position.distance_to(global_position) <= completion_radius:
		_is_complete = true
		completed.emit()
		for overlay in get_tree().get_nodes_in_group("end_overlays"):
			if overlay.has_method("show_completion"):
				overlay.call("show_completion")
		print("Complete")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 68.0, GLOW_COLOR)
	draw_arc(Vector2.ZERO, 58.0, 0.0, TAU, 64, OUTER_COLOR, 3.0, true)

	draw_set_transform(
		Vector2.ZERO,
		_animation_time * 0.55,
		Vector2(0.68, 1.0)
	)
	draw_arc(Vector2.ZERO, 49.0, 0.2, TAU - 0.35, 64, INNER_COLOR, 4.0, true)
	draw_set_transform(
		Vector2.ZERO,
		-_animation_time * 0.8,
		Vector2(0.43, 0.82)
	)
	draw_arc(Vector2.ZERO, 39.0, 0.0, TAU, 64, OUTER_COLOR, 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for index in range(10):
		var angle := _animation_time * 1.15 + TAU * float(index) / 10.0
		var particle_radius := 24.0 + 7.0 * sin(_animation_time * 2.0 + index)
		var particle_position := Vector2.RIGHT.rotated(angle) * particle_radius
		draw_circle(particle_position, 2.0, PARTICLE_COLOR)

	draw_line(Vector2(-8.0, 0.0), Vector2(8.0, 0.0), CENTER_COLOR, 2.0, true)
	draw_line(Vector2(0.0, -8.0), Vector2(0.0, 8.0), CENTER_COLOR, 2.0, true)
	draw_circle(Vector2.ZERO, 3.0, CENTER_COLOR)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-30.0, 84.0),
		tr("PORTAL_LABEL"),
		HORIZONTAL_ALIGNMENT_CENTER,
		60.0,
		12,
		PARTICLE_COLOR
	)
