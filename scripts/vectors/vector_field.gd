class_name VectorField
extends Node2D

@export_range(4.0, 64.0, 1.0) var snap_distance: float = 24.0
@export_range(0.0, 4.0, 0.5) var snap_path_tolerance: float = 1.5


func snap_moving_vector(
	vector: VectorObject,
	proposed_origin: Vector2
) -> Vector2:
	var tip_offset := (
		vector.get_tip_global_position() - vector.global_position
	)
	var moving_points: Array[Vector2] = [
		proposed_origin,
		proposed_origin + tip_offset
	]

	var best_origin := proposed_origin
	var best_distance := snap_distance
	var character := get_parent().get_node_or_null("Character") as CharacterBody2D
	if character != null:
		var character_distance := proposed_origin.distance_to(character.global_position)
		if character_distance <= best_distance:
			best_distance = character_distance
			best_origin = character.global_position

	for other in _get_vectors(vector):
		var stationary_points: Array[Vector2] = [
			other.global_position,
			other.get_tip_global_position()
		]

		for moving_index in range(2):
			for stationary_index in range(2):
				# Do not snap tip-to-tip.
				if moving_index == 1 and stationary_index == 1:
					continue

				var distance := moving_points[moving_index].distance_to(
					stationary_points[stationary_index]
				)

				if distance <= best_distance:
					best_distance = distance
					best_origin = (
						proposed_origin
						+ stationary_points[stationary_index]
						- moving_points[moving_index]
					)

	return best_origin


func snap_moving_tip(
	vector: VectorObject,
	pointer_local: Vector2
) -> Vector2:
	var pointer_global := vector.to_global(pointer_local)
	var best_local := pointer_local
	var best_distance := snap_distance
	var direction := vector.get_vector_local().normalized()

	for other in _get_vectors(vector):
		# A dragged tip can snap only to another vector's origin.
		var target_global := other.global_position
		var distance := pointer_global.distance_to(target_global)

		if distance > best_distance:
			continue

		var target_local := vector.to_local(target_global)
		var snapped_local := target_local
		var valid_target := false

		if vector.can_scale and vector.can_rotate:
			valid_target = true

		elif vector.can_scale:
			var projected_length := target_local.dot(direction)
			var projected_point := direction * projected_length

			valid_target = (
				projected_length > 0.0
				and projected_point.distance_to(target_local)
				<= snap_path_tolerance
			)
			snapped_local = projected_point

		elif vector.can_rotate:
			var target_radius := target_local.length()

			valid_target = (
				target_radius > 0.0
				and absf(target_radius - vector.arrow_length)
				<= snap_path_tolerance
			)

			if valid_target:
				snapped_local = target_local.normalized() * vector.arrow_length

		if valid_target:
			best_distance = distance
			best_local = snapped_local

	return best_local


func _get_vectors(except_vector: VectorObject) -> Array[VectorObject]:
	var vectors: Array[VectorObject] = []

	for child in get_children():
		if child is VectorObject and child != except_vector:
			vectors.append(child)

	return vectors
