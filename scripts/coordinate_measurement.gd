extends Node2D

const GUIDE_COLOR := Color(0.95, 0.88, 0.55, 0.75)
const MARKER_COLOR := Color("#FFE57A")
const LABEL_COLOR := Color("#FFFFFF")
const DISPLACEMENT_COLOR := Color("#52D6FF")
const DISPLACEMENT_ARROW_WIDTH := 4.5
const DASH_LENGTH := 7.0
const DASH_GAP := 5.0

@onready var coordinate_plane: CoordinatePlane = get_parent() as CoordinatePlane

@export var show_displacement_arrow := true

var _character: CharacterBody2D
var _character_start_position := Vector2.ZERO
var _last_character_position := Vector2.ZERO
var _last_positions: Dictionary = {}
var _last_selected_ids: Array[int] = []


func _ready() -> void:
	_character = coordinate_plane.get_node_or_null("Character") as CharacterBody2D
	if is_instance_valid(_character):
		_character_start_position = coordinate_plane.to_local(_character.global_position)
		_last_character_position = _character_start_position


func _process(_delta: float) -> void:
	var redraw_needed := false
	if is_instance_valid(_character):
		var character_position := coordinate_plane.to_local(_character.global_position)
		if not character_position.is_equal_approx(_last_character_position):
			_last_character_position = character_position
			redraw_needed = true

	for index in range(coordinate_plane.selected_objects.size() - 1, -1, -1):
		if not is_instance_valid(coordinate_plane.selected_objects[index]):
			coordinate_plane.selected_objects.remove_at(index)
			redraw_needed = true

	var selected_ids: Array[int] = []
	for selected in coordinate_plane.selected_objects:
		var instance_id := selected.get_instance_id()
		selected_ids.append(instance_id)
		var point := coordinate_plane.to_local(selected.global_position)
		if (
			not _last_positions.has(instance_id)
			or not point.is_equal_approx(_last_positions[instance_id])
		):
			_last_positions[instance_id] = point
			redraw_needed = true

	if selected_ids != _last_selected_ids:
		redraw_needed = true
		for instance_id in _last_positions.keys():
			if not selected_ids.has(instance_id):
				_last_positions.erase(instance_id)
		_last_selected_ids = selected_ids

	if redraw_needed:
		queue_redraw()


func _draw() -> void:
	_draw_displacement_arrow()
	for selected in coordinate_plane.selected_objects:
		if is_instance_valid(selected):
			_draw_object_coordinates(selected)


func _draw_displacement_arrow() -> void:
	if not show_displacement_arrow:
		return
	if not is_instance_valid(_character):
		return

	var start := _character_start_position
	var end := coordinate_plane.to_local(_character.global_position)
	var displacement := end - start
	if displacement.length_squared() <= 1.0:
		return

	var direction := displacement.normalized()
	var arrow_size := 12.0
	var arrow_angle := deg_to_rad(25.0)
	draw_line(start, end, DISPLACEMENT_COLOR, DISPLACEMENT_ARROW_WIDTH, true)
	draw_line(
		end,
		end - direction.rotated(arrow_angle) * arrow_size,
		DISPLACEMENT_COLOR,
		DISPLACEMENT_ARROW_WIDTH,
		true
	)
	draw_line(
		end,
		end - direction.rotated(-arrow_angle) * arrow_size,
		DISPLACEMENT_COLOR,
		DISPLACEMENT_ARROW_WIDTH,
		true
	)


func _draw_object_coordinates(selected: Node2D) -> void:
	var point := coordinate_plane.to_local(selected.global_position)
	var x_projection := Vector2(point.x, 0.0)
	var y_projection := Vector2(0.0, point.y)

	_draw_dashed_line(point, x_projection)
	_draw_dashed_line(point, y_projection)
	draw_circle(x_projection, 3.0, GUIDE_COLOR)
	draw_circle(y_projection, 3.0, GUIDE_COLOR)
	draw_arc(point, 9.0, 0.0, TAU, 32, MARKER_COLOR, 2.0, true)
	draw_circle(point, 3.5, MARKER_COLOR)

	var spacing := 40.0
	var grid := coordinate_plane.get_node_or_null("Grid")
	if grid != null:
		spacing = float(grid.get("spacing"))

	if spacing <= 0.0:
		return

	var coordinates := Vector2(point.x / spacing, -point.y / spacing)
	draw_string(
		ThemeDB.fallback_font,
		x_projection + Vector2(8.0, -10.0),
		"x=%.1f" % coordinates.x,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		LABEL_COLOR
	)
	draw_string(
		ThemeDB.fallback_font,
		y_projection + Vector2(8.0, -10.0),
		"y=%.1f" % coordinates.y,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		LABEL_COLOR
	)


func _draw_dashed_line(start: Vector2, end: Vector2) -> void:
	var delta := end - start
	var length := delta.length()
	if length <= 1.0:
		return

	var direction := delta / length
	var distance := 0.0
	while distance < length:
		var dash_end := minf(distance + DASH_LENGTH, length)
		draw_line(
			start + direction * distance,
			start + direction * dash_end,
			GUIDE_COLOR,
			1.5,
			true
		)
		distance = dash_end + DASH_GAP
