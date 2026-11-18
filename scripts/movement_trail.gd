class_name MovementTrail
extends Node2D

const POINT_SPACING := 6.0
const LINE_WIDTH := 3.5
const LINE_COLOR := Color(1.0, 1.0, 1.0, 0.42)

var points := PackedVector2Array()


func add_global_position(global_point: Vector2) -> void:
	var point := to_local(global_point)
	if points.is_empty():
		points.append(point)
		queue_redraw()
		return

	var last_point := points[-1]
	var offset := point - last_point
	var distance := offset.length()
	if distance < POINT_SPACING:
		return

	var direction := offset / distance
	while distance >= POINT_SPACING:
		last_point += direction * POINT_SPACING
		points.append(last_point)
		distance -= POINT_SPACING

	queue_redraw()


func _draw() -> void:
	# Alternate short, fixed-space segments for a stable dashed trajectory.
	for index in range(0, points.size() - 1, 2):
		draw_line(
			points[index],
			points[index + 1],
			LINE_COLOR,
			LINE_WIDTH,
			true
		)
