@tool
class_name VectorVisual
extends Node2D

const SHAFT_WIDTH := 7.0
const HEAD_LENGTH := 24.0
const HEAD_HALF_WIDTH := 12.0

const OUTLINE_COLOR := Color("ffffffff")
const CONTROL_ICON_MODULATE := Color(0.875, 0.875, 0.875, 0.29)

const MOVE_ICON_OFFSET := 44.0
const CONTROL_ICON_FORWARD_OFFSET := 52.0
const ROTATE_ICON_TANGENT_OFFSET_DEGREES := 90.0

const LABEL_SIZE := Vector2(72.0, 42.0)
const LABEL_OFFSET := 34.0
const LABEL_FONT_SIZE := 26

@onready var vector: VectorObject = get_parent() as VectorObject

@onready var move_icon: Sprite2D = $MoveIcon
@onready var scale_icon: Sprite2D = $ScaleIcon
@onready var rotate_icon: Sprite2D = $RotateIcon
@onready var type_label: Label = $TypeLabel

var is_body_hovered := false
var is_tip_hovered := false
var is_dragging_body := false
var is_dragging_tip := false


func _ready() -> void:
	if not vector.vector_changed.is_connected(_on_vector_changed):
		vector.vector_changed.connect(_on_vector_changed)

	move_icon.centered = true
	scale_icon.centered = true
	rotate_icon.centered = true

	move_icon.z_index = 2
	scale_icon.z_index = 2
	rotate_icon.z_index = 3

	move_icon.modulate = CONTROL_ICON_MODULATE
	scale_icon.modulate = CONTROL_ICON_MODULATE
	rotate_icon.modulate = CONTROL_ICON_MODULATE

	type_label.size = LABEL_SIZE
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_update_visuals()


func set_interaction_state(
	body_hovered: bool,
	tip_hovered: bool,
	dragging_body: bool,
	dragging_tip: bool
) -> void:
	is_body_hovered = body_hovered
	is_tip_hovered = tip_hovered
	is_dragging_body = dragging_body
	is_dragging_tip = dragging_tip

	_update_visuals()


func _on_vector_changed() -> void:
	_update_visuals()


func _update_visuals() -> void:
	if not is_node_ready():
		return

	_update_icons()
	_update_type_label()
	queue_redraw()


func _draw() -> void:
	if vector.arrow_length <= 0.0:
		return

	var direction := Vector2.RIGHT.rotated(
		deg_to_rad(vector.angle_degrees)
	)
	var side := Vector2(-direction.y, direction.x)
	var tip := direction * vector.arrow_length

	var vector_color := _get_vector_color(vector.vector_type)

	# The character's movement trail already shows the traversed displacement.
	if vector.is_being_traversed:
		return

	var base := direction * maxf(
		vector.arrow_length - HEAD_LENGTH,
		0.0
	)

	var left_corner := base + side * HEAD_HALF_WIDTH
	var right_corner := base - side * HEAD_HALF_WIDTH

	var highlighted := (
		is_body_hovered
		or is_tip_hovered
		or is_dragging_body
		or is_dragging_tip
	)

	if highlighted:
		draw_line(
			Vector2.ZERO,
			base,
			OUTLINE_COLOR,
			SHAFT_WIDTH + 3.0,
			true
		)

		draw_polyline(
			PackedVector2Array([
				tip,
				left_corner,
				right_corner,
				tip
			]),
			OUTLINE_COLOR,
			2.5,
			true
		)

	draw_line(Vector2.ZERO, base, vector_color, SHAFT_WIDTH)

	draw_colored_polygon(
		PackedVector2Array([
			tip,
			left_corner,
			right_corner
		]),
		vector_color
	)

	if vector.vector_type != VectorObject.TYPE_VECTOR:
		_draw_vector_mark(vector_color)


func _draw_vector_mark(color: Color) -> void:
	var mark_center := type_label.position + type_label.size * 0.5
	var mark_y := type_label.position.y + 4.0
	var mark_start := Vector2(mark_center.x - 10.0, mark_y)
	var mark_end := Vector2(mark_center.x + 10.0, mark_y)

	draw_line(mark_start, mark_end, color, 2.0, true)
	draw_line(
		mark_end,
		mark_end + Vector2(-5.0, -3.0),
		color,
		2.0,
		true
	)
	draw_line(
		mark_end,
		mark_end + Vector2(-5.0, 3.0),
		color,
		2.0,
		true
	)


func _update_icons() -> void:
	var angle := deg_to_rad(vector.angle_degrees)
	var direction := Vector2.RIGHT.rotated(angle)
	var normal := Vector2(-direction.y, direction.x)

	var hovering_body := is_body_hovered and not is_tip_hovered
	var dragging_body := is_dragging_body and not is_dragging_tip
	var controlling_tip := is_tip_hovered or is_dragging_tip

	move_icon.position = (
		direction * (vector.arrow_length * 0.5)
		+ normal * MOVE_ICON_OFFSET
	)
	move_icon.visible = (
		not vector.is_being_traversed
		and vector.can_move
		and (hovering_body or dragging_body)
	)

	var control_icon_position := (
		direction
		* (vector.arrow_length + CONTROL_ICON_FORWARD_OFFSET)
	)

	scale_icon.position = control_icon_position
	scale_icon.rotation = angle - PI / 2.0
	scale_icon.visible = (
		not vector.is_being_traversed
		and vector.can_scale
		and controlling_tip
	)

	rotate_icon.position = control_icon_position
	rotate_icon.rotation = (
		angle + deg_to_rad(ROTATE_ICON_TANGENT_OFFSET_DEGREES)
	)
	rotate_icon.visible = (
		not vector.is_being_traversed
		and vector.can_rotate
		and controlling_tip
	)


func _update_type_label() -> void:
	var label_text := _get_type_label_text()

	type_label.text = label_text
	type_label.visible = (
		not vector.is_being_traversed
		and not label_text.is_empty()
	)
	type_label.add_theme_color_override(
		"font_color",
		_get_vector_color(vector.vector_type)
	)

	var direction := Vector2.RIGHT.rotated(
		deg_to_rad(vector.angle_degrees)
	)
	var normal := Vector2(-direction.y, direction.x)

	var label_center := (
		direction * vector.arrow_length
		- normal * LABEL_OFFSET
	)

	type_label.position = label_center - LABEL_SIZE * 0.5


func _get_type_label_text() -> String:
	match vector.vector_type:
		VectorObject.TYPE_DISPLACEMENT:
			return "d"
		VectorObject.TYPE_VELOCITY:
			return "v"
		VectorObject.TYPE_ACCELERATION:
			return "a"
		VectorObject.TYPE_FORCE:
			return "F"
		VectorObject.TYPE_VECTOR:
			return ""

	return ""


func _get_vector_color(vector_type: int) -> Color:
	match vector_type:
		VectorObject.TYPE_DISPLACEMENT:
			return Color("#52D6FF")
		VectorObject.TYPE_VELOCITY:
			return Color("#63E6BE")
		VectorObject.TYPE_ACCELERATION:
			return Color("#FFB84D")
		VectorObject.TYPE_FORCE:
			return Color("#C78BFF")
		VectorObject.TYPE_VECTOR:
			return Color("#C4CCD7")

	return Color("#C4CCD7")
