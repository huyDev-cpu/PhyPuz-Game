extends Control

const PATH_COLOR := Color("#E7E9EF")
const DASH_LENGTH := 10.0
const DASH_GAP := 8.0

@onready var distance_label: Label = $DistanceLabel
@onready var displacement_label: Label = $DisplacementLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(580, 230)
	_update_translated_labels()
	var vector := get_node_or_null("DisplacementVector") as VectorObject
	if vector != null:
		vector.lock_for_play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_translated_labels()


func _update_translated_labels() -> void:
	distance_label.text = tr("END_DISTANCE")
	displacement_label.text = tr("END_DISPLACEMENT")


func _draw() -> void:
	var path := PackedVector2Array([
		Vector2(80, 165),
		Vector2(500, 165),
		Vector2(80, 40),
		Vector2(500, 40),
	])
	for index in range(path.size() - 1):
		_draw_dashed_segment(path[index], path[index + 1])
	draw_circle(path[0], 5.0, Color("#E7E9EF"))
	draw_circle(path[-1], 5.0, Color("#E7E9EF"))
	_draw_pointer(Vector2(430, 42), Vector2(400, 73))
	_draw_pointer(Vector2(450, 177), Vector2(450, 165))


func _draw_dashed_segment(start: Vector2, finish: Vector2) -> void:
	var offset := finish - start
	var length := offset.length()
	if length <= 0.0:
		return
	var direction := offset / length
	var distance := 0.0
	while distance < length:
		var dash_end := minf(distance + DASH_LENGTH, length)
		draw_line(
			start + direction * distance,
			start + direction * dash_end,
			PATH_COLOR,
			3.0,
			true
		)
		distance = dash_end + DASH_GAP


func _draw_pointer(start: Vector2, tip: Vector2) -> void:
	var direction := (tip - start).normalized()
	draw_line(start, tip, PATH_COLOR, 2.0, true)
	draw_line(tip, tip - direction.rotated(0.55) * 9.0, PATH_COLOR, 2.0, true)
	draw_line(tip, tip - direction.rotated(-0.55) * 9.0, PATH_COLOR, 2.0, true)
