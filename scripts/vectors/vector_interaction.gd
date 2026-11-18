extends Node

@onready var vector: VectorObject = get_parent() as VectorObject
@onready var field: VectorField = vector.get_parent() as VectorField
@onready var visual: VectorVisual = $"../Visual"

@onready var hit_area: Area2D = $"../HitArea"
@onready var tip_handle: Area2D = $"../TipHandle"

var is_dragging_body := false
var is_dragging_tip := false
var is_body_hovered := false
var is_tip_hovered := false

var body_drag_offset := Vector2.ZERO
var tip_drag_offset := Vector2.ZERO

func _ready() -> void:
	set_process_input(true)

	hit_area.input_pickable = true
	tip_handle.input_pickable = true

	# Mouse input events need an Area2D collision layer.
	if hit_area.collision_layer == 0:
		hit_area.collision_layer = 1
	if tip_handle.collision_layer == 0:
		tip_handle.collision_layer = 1

	hit_area.input_event.connect(_on_hit_area_input_event)
	hit_area.mouse_entered.connect(_on_body_mouse_entered)
	hit_area.mouse_exited.connect(_on_body_mouse_exited)

	tip_handle.input_event.connect(_on_tip_handle_input_event)
	tip_handle.mouse_entered.connect(_on_tip_mouse_entered)
	tip_handle.mouse_exited.connect(_on_tip_mouse_exited)

func _on_body_mouse_entered() -> void:
	is_body_hovered = true
	_update_visual_state()


func _on_body_mouse_exited() -> void:
	is_body_hovered = false
	_update_visual_state()


func _on_tip_mouse_entered() -> void:
	is_tip_hovered = true
	_update_visual_state()


func _on_tip_mouse_exited() -> void:
	is_tip_hovered = false
	_update_visual_state()


func _on_hit_area_input_event(
	viewport: Viewport,
	event: InputEvent,
	_shape_index: int
) -> void:
	if not vector.can_move:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_dragging_body = true
			is_dragging_tip = false

			body_drag_offset = (
				vector.global_position
				- vector.get_global_mouse_position()
			)

			_update_visual_state()
			viewport.set_input_as_handled()


func _on_tip_handle_input_event(
	viewport: Viewport,
	event: InputEvent,
	_shape_index: int
) -> void:
	if not vector.can_scale and not vector.can_rotate:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_dragging_tip = true
			is_dragging_body = false

			tip_drag_offset = (
				vector.to_local(vector.get_global_mouse_position())
				- vector.get_vector_local()
			)

			_update_visual_state()
			viewport.set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _is_simulation_playing():
		if is_dragging_body or is_dragging_tip:
			lock_for_play()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging_body = false
			is_dragging_tip = false
			_update_visual_state()
			return

	if event is InputEventMouseMotion:
		if is_dragging_body and vector.can_move:
			var proposed_origin := (
				vector.get_global_mouse_position()
				+ body_drag_offset
			)

			vector.global_position = field.snap_moving_vector(
				vector,
				proposed_origin
			)
			vector.notify_changed()

		elif is_dragging_tip:
			var point_local := (
				vector.to_local(vector.get_global_mouse_position())
				+ tip_drag_offset
			)

			point_local = field.snap_moving_tip(vector, point_local)
			vector.set_tip_local(point_local)


func _update_visual_state() -> void:
	visual.set_interaction_state(
		is_body_hovered,
		is_tip_hovered,
		is_dragging_body,
		is_dragging_tip
	)


func lock_for_play() -> void:
	is_dragging_body = false
	is_dragging_tip = false
	is_body_hovered = false
	is_tip_hovered = false
	_update_visual_state()


func _is_simulation_playing() -> bool:
	var controller := get_tree().get_first_node_in_group("gameplay_controller")
	return controller != null and bool(controller.get("is_playing"))
