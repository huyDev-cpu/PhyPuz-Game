@tool
class_name VectorAddition
extends Node2D

@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh()


@export_range(0.0, 20.0, 0.5) var origin_tolerance: float = 2.0:
	set(value):
		origin_tolerance = value
		_refresh()


@export_range(0.0, 1.0, 0.05) var source_opacity: float = 0.18:
	set(value):
		source_opacity = value
		_refresh()


const RESULT_WIDTH := 6.0
const HEAD_LENGTH := 24.0
const HEAD_HALF_WIDTH := 12.0
const DASH_LENGTH := 8.0
const DASH_GAP := 6.0
const INTERMEDIATE_OPACITY := 0.3

var sum_groups: Array[Dictionary] = []


func _ready() -> void:
	z_index = 5

	var field := get_parent()
	if field != null:
		field.child_entered_tree.connect(_on_field_child_entered)
		field.child_exiting_tree.connect(_on_field_child_exiting)

	call_deferred("_refresh")


func _refresh() -> void:
	if not is_node_ready():
		return

	var vectors := _get_vectors()
	_connect_to_vectors(vectors)
	sum_groups.clear()

	for vector in vectors:
		vector.is_being_added = false

	if enabled:
		var remaining: Array[VectorObject] = []

		for vector in vectors:
			# Displacement vectors use head-to-tail sequencing.
			if vector.vector_type == VectorObject.TYPE_DISPLACEMENT:
				continue

			remaining.append(vector)

		while not remaining.is_empty():
			var first: VectorObject = remaining.pop_front()
			var group_vectors: Array[VectorObject] = [first]

			for candidate in remaining.duplicate():
				if candidate.vector_type != first.vector_type:
					continue

				if (
					candidate.global_position.distance_to(first.global_position)
					<= origin_tolerance
				):
					group_vectors.append(candidate)
					remaining.erase(candidate)

			if group_vectors.size() < 2:
				continue

			for vector in group_vectors:
				vector.is_being_added = true

			sum_groups.append(_build_sum_group(group_vectors))

	_set_source_opacity(vectors)
	queue_redraw()


func _build_sum_group(vectors: Array[VectorObject]) -> Dictionary:
	var origin_global := Vector2.ZERO

	for vector in vectors:
		origin_global += vector.global_position

	origin_global /= vectors.size()

	var result_vector := Vector2.ZERO
	var construction_steps: Array[Dictionary] = []
	var intermediate_tips: Array[Vector2] = []

	for index in range(vectors.size()):
		var vector := vectors[index]
		var value := (
			vector.get_tip_global_position()
			- vector.global_position
		)

		if index > 0:
			var previous_result_tip := origin_global + result_vector
			var translated_vector_tip := origin_global + value
			var next_result_tip := origin_global + result_vector + value

			construction_steps.append({
				"previous_tip": to_local(previous_result_tip),
				"translated_tip": to_local(translated_vector_tip),
				"next_tip": to_local(next_result_tip)
			})

		result_vector += value

		if index < vectors.size() - 1:
			intermediate_tips.append(
				to_local(origin_global + result_vector)
			)

	return {
		"origin": to_local(origin_global),
		"result_tip": to_local(origin_global + result_vector),
		"steps": construction_steps,
		"intermediate_tips": intermediate_tips,
		"color": _get_vector_color(vectors[0].vector_type)
	}


func _draw() -> void:
	for group in sum_groups:
		var color: Color = group["color"]
		var guide_color := color
		guide_color.a = 0.3

		for step in group["steps"]:
			_draw_dashed_line(
				step["previous_tip"],
				step["next_tip"],
				guide_color
			)
			_draw_dashed_line(
				step["translated_tip"],
				step["next_tip"],
				guide_color
			)

		var intermediate_color := color
		intermediate_color.a = INTERMEDIATE_OPACITY

		for tip in group["intermediate_tips"]:
			_draw_resultant(
				group["origin"],
				tip,
				intermediate_color,
				RESULT_WIDTH * 0.65
			)

		_draw_resultant(
			group["origin"],
			group["result_tip"],
			color,
			RESULT_WIDTH
		)


func _get_vectors() -> Array[VectorObject]:
	var vectors: Array[VectorObject] = []
	var field := get_parent()

	if field == null:
		return vectors

	for child in field.get_children():
		if child is VectorObject:
			vectors.append(child)

	return vectors


func _connect_to_vectors(vectors: Array[VectorObject]) -> void:
	for vector in vectors:
		if not vector.vector_changed.is_connected(_on_vector_changed):
			vector.vector_changed.connect(_on_vector_changed)


func _set_source_opacity(vectors: Array[VectorObject]) -> void:
	for vector in vectors:
		var visual := vector.get_node_or_null("Visual") as CanvasItem
		if visual == null:
			continue

		var alpha := 1.0
		if vector.is_being_added:
			alpha = source_opacity

		visual.modulate = Color(1.0, 1.0, 1.0, alpha)


func _draw_resultant(
	start: Vector2,
	end: Vector2,
	color: Color,
	line_width: float = RESULT_WIDTH
) -> void:
	var result := end - start
	if result.length() <= 1.0:
		return

	var direction := result.normalized()
	var side := Vector2(-direction.y, direction.x)
	var head_length := minf(HEAD_LENGTH, result.length())
	var base := end - direction * head_length

	var left_corner := base + side * HEAD_HALF_WIDTH
	var right_corner := base - side * HEAD_HALF_WIDTH

	draw_line(start, base, color, line_width)
	draw_colored_polygon(
		PackedVector2Array([
			end,
			left_corner,
			right_corner
		]),
		color
	)


func _draw_dashed_line(
	start: Vector2,
	end: Vector2,
	color: Color
) -> void:
	var line := end - start
	var line_length := line.length()

	if line_length <= 1.0:
		return

	var direction := line / line_length
	var distance := 0.0

	while distance < line_length:
		var dash_end := minf(distance + DASH_LENGTH, line_length)

		draw_line(
			start + direction * distance,
			start + direction * dash_end,
			color,
			2.0
		)

		distance = dash_end + DASH_GAP


func _get_vector_color(vector_type: int) -> Color:
	match vector_type:
		0:
			return Color("#52D6FF")
		1:
			return Color("#63E6BE")
		2:
			return Color("#FFB84D")
		3:
			return Color("#C78BFF")

	return Color("#C4CCD7")


func _on_vector_changed() -> void:
	_refresh()


func _on_field_child_entered(child: Node) -> void:
	if child is VectorObject:
		call_deferred("_refresh")


func _on_field_child_exiting(child: Node) -> void:
	if child is VectorObject:
		if child.vector_changed.is_connected(_on_vector_changed):
			child.vector_changed.disconnect(_on_vector_changed)

		call_deferred("_refresh")
