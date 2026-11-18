extends CharacterBody2D

@export_range(0.1, 2.0, 0.1)
var fade_duration: float = 0.5

@export var allow_setup_drag := true

var _is_displacing := false
var _velocity_vectors: Array[VectorObject] = []
var _acceleration_vectors: Array[VectorObject] = []
var _acceleration_velocity := Vector2.ZERO
var _is_setup_dragging := false
var _setup_drag_offset := Vector2.ZERO

@onready var movement_trail: MovementTrail = get_parent().get_node("MovementTrail")


func _physics_process(delta: float) -> void:
	if _is_setup_dragging:
		velocity = Vector2.ZERO
		return

	if not _is_simulation_playing() or _is_displacing:
		velocity = Vector2.ZERO
		return

	var combined_velocity := Vector2.ZERO
	combined_velocity += _get_attached_vector_sum(_velocity_vectors)
	var combined_acceleration := _get_attached_vector_sum(_acceleration_vectors)
	_acceleration_velocity += combined_acceleration * delta

	if (
		_velocity_vectors.is_empty()
		and _acceleration_vectors.is_empty()
		and _acceleration_velocity.is_zero_approx()
	):
		velocity = Vector2.ZERO
		return

	velocity = combined_velocity + _acceleration_velocity
	move_and_slide()

	_update_attached_vectors()
	_record_trail_position()


func _input(event: InputEvent) -> void:
	if not allow_setup_drag or _is_simulation_playing():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_begin_setup_drag(get_global_mouse_position())
		else:
			_is_setup_dragging = false
	elif event is InputEventScreenTouch:
		var touch_position := _screen_to_world(event.position)
		if event.pressed:
			_try_begin_setup_drag(touch_position)
		else:
			_is_setup_dragging = false
	elif event is InputEventMouseMotion and _is_setup_dragging:
		_update_setup_drag(get_global_mouse_position())
	elif event is InputEventScreenDrag and _is_setup_dragging:
		_update_setup_drag(_screen_to_world(event.position))


func _try_begin_setup_drag(world_position: Vector2) -> void:
	if not allow_setup_drag:
		return

	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = collision_layer
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for hit in get_world_2d().direct_space_state.intersect_point(query, 16):
		if hit["collider"] == self:
			_is_setup_dragging = true
			_setup_drag_offset = global_position - world_position
			movement_trail.add_global_position(global_position)
			return


func _update_setup_drag(world_position: Vector2) -> void:
	global_position = world_position + _setup_drag_offset
	_record_trail_position()


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func apply_velocity(vector: VectorObject) -> void:
	if not _is_simulation_playing():
		return
	if vector.vector_type != VectorObject.TYPE_VELOCITY:
		return
	if vector.is_being_applied or _velocity_vectors.has(vector):
		return

	vector.global_position = global_position
	vector.can_move = false
	_velocity_vectors.append(vector)
	vector.notify_changed()
	_record_trail_position()


func apply_acceleration(vector: VectorObject) -> void:
	if not _is_simulation_playing():
		return
	if vector.vector_type != VectorObject.TYPE_ACCELERATION:
		return
	if vector.is_being_applied or _acceleration_vectors.has(vector):
		return

	vector.global_position = global_position
	vector.can_move = false
	_acceleration_vectors.append(vector)
	vector.notify_changed()


func _get_attached_vector_sum(vectors: Array[VectorObject]) -> Vector2:
	var total := Vector2.ZERO
	for index in range(vectors.size() - 1, -1, -1):
		var vector := vectors[index]
		if not is_instance_valid(vector):
			vectors.remove_at(index)
			continue

		vector.global_position = global_position
		total += vector.get_tip_global_position() - vector.global_position
	return total


func _update_attached_vectors() -> void:
	for vector in _velocity_vectors + _acceleration_vectors:
		if is_instance_valid(vector):
			vector.global_position = global_position
			vector.notify_changed()


func _record_trail_position() -> void:
	if is_instance_valid(movement_trail):
		movement_trail.add_global_position(global_position)


func _is_simulation_playing() -> bool:
	var controller := get_tree().get_first_node_in_group("gameplay_controller")
	return controller != null and bool(controller.get("is_playing"))


func apply_displacement(vector: VectorObject) -> void:
	if not _is_simulation_playing():
		return
	if _is_displacing:
		return

	if vector.vector_type != VectorObject.TYPE_DISPLACEMENT:
		return
	if vector.global_position.distance_to(global_position) > 1.0:
		return

	if vector.is_being_traversed or vector.is_being_applied:
		return

	_is_displacing = true

	var origin := vector.global_position
	var destination := vector.get_tip_global_position()

	var original_modulate := modulate
	var invisible_modulate := original_modulate
	invisible_modulate.a = 0.0

	var original_collision_layer := collision_layer
	var original_collision_mask := collision_mask

	vector.is_being_applied = true
	vector.can_move = false
	vector.can_scale = false
	vector.can_rotate = false
	vector.notify_changed()

	collision_layer = 0
	collision_mask = 0

	# Wait until the next physics frame before repositioning the body.
	await get_tree().physics_frame
	global_position = origin
	_record_trail_position()

	# Fade out over 0.5 seconds.
	var fade_out := create_tween()
	fade_out.tween_property(
		self,
		"modulate",
		invisible_modulate,
		fade_duration
	)
	await fade_out.finished

	# Displacement changes position instantly; it does not simulate travel.
	await get_tree().physics_frame
	global_position = destination
	_record_trail_position()

	vector.is_being_applied = false
	vector.is_being_traversed = true
	vector.notify_changed()

	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	# Fade in over 0.5 seconds at the destination.
	var fade_in := create_tween()
	fade_in.tween_property(
		self,
		"modulate",
		original_modulate,
		fade_duration
	)
	await fade_in.finished

	_is_displacing = false

	await get_tree().physics_frame
	_try_start_next_displacement()


func _try_start_next_displacement() -> void:
	var world := get_parent()
	if world == null:
		return

	var field := world.get_node_or_null("VectorField")
	if field == null:
		return

	var vector_field := field as VectorField
	if vector_field == null:
		return

	# Continue only from a truly joined endpoint; setup snapping aligns the points.
	const CONNECTION_TOLERANCE := 1.0

	for child in field.get_children():
		if not child is VectorObject:
			continue

		var vector := child as VectorObject

		if vector.vector_type != VectorObject.TYPE_DISPLACEMENT:
			continue

		if not vector.is_playable_in_current_run:
			continue

		if vector.is_being_traversed or vector.is_being_applied:
			continue

		if vector.global_position.distance_to(global_position) > CONNECTION_TOLERANCE:
			continue

		if vector.has_method("activate_for"):
			vector.call("activate_for", self)
			return
