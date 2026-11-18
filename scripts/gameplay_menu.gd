extends CanvasLayer

const LEVELS := [
	{
		"title": "Part 1 · Tutorial 1",
		"scene": "res://scenes/Chapters/vector and displacement/part1/tutorial1.tscn"
	},
	{
		"title": "Part 1 · Tutorial 2",
		"scene": "res://scenes/Chapters/vector and displacement/part1/tutorial2.tscn"
	},
	{
		"title": "Part 1 · Level 1",
		"scene": "res://scenes/Chapters/vector and displacement/part1/level1.tscn"
	},
	{
		"title": "Part 2 · Tutorial 3",
		"scene": "res://scenes/Chapters/vector and displacement/part2/tutorial3.tscn"
	},
	{
		"title": "Part 2 · Level 2",
		"scene": "res://scenes/Chapters/vector and displacement/part2/level2.tscn"
	}
]

@export var show_play_button := false

var _level_popup: PanelContainer
var _play_button: Button
var is_playing := false


func _ready() -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("gameplay_controller")

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var levels_button := Button.new()
	levels_button.position = Vector2(32, 32)
	levels_button.text = "Stages"
	levels_button.custom_minimum_size = Vector2(112, 48)
	levels_button.pressed.connect(_toggle_level_popup)
	root.add_child(levels_button)
	if show_play_button:
		_play_button = Button.new()
		_play_button.position = Vector2(160, 32)
		_play_button.text = "Play"
		_play_button.custom_minimum_size = Vector2(112, 48)
		_play_button.pressed.connect(_on_play_pressed)
		root.add_child(_play_button)

	_level_popup = PanelContainer.new()
	_level_popup.position = Vector2(32, 88)
	_level_popup.visible = false
	_level_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_level_popup.custom_minimum_size = Vector2(300, 112)
	root.add_child(_level_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	_level_popup.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var title := Label.new()
	title.text = "SELECT STAGE"
	title.add_theme_font_size_override("font_size", 14)
	content.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(272, 64)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	scroll.add_child(level_row)

	for level in LEVELS:
		var level_button := Button.new()
		var is_locked: bool = level.get("locked", false)
		level_button.text = "%s - Locked" % level["title"] if is_locked else level["title"]
		level_button.custom_minimum_size = Vector2(168, 52)
		level_button.disabled = is_locked
		if is_locked:
			level_button.tooltip_text = "This level is locked"
		else:
			level_button.pressed.connect(_open_level.bind(level["scene"]))
		level_row.add_child(level_button)


func _toggle_level_popup() -> void:
	_level_popup.visible = not _level_popup.visible


func _open_level(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


func _on_play_pressed() -> void:
	if is_playing:
		get_tree().reload_current_scene()
		return

	is_playing = true
	_play_button.text = "Reset"
	_prepare_vectors_for_play()


func _prepare_vectors_for_play() -> void:
	var world := get_parent()
	var coordinate_plane := world.get_node_or_null("CoordinatePlane")
	if coordinate_plane == null:
		return

	var character := coordinate_plane.get_node_or_null("Character") as CharacterBody2D
	var field := coordinate_plane.get_node_or_null("VectorField") as VectorField
	if character == null or field == null:
		return

	var vectors: Array[VectorObject] = []
	for child in field.get_children():
		if not child is VectorObject:
			continue

		var vector := child as VectorObject
		vector.lock_for_play()
		vectors.append(vector)

	var playable_vectors: Array[VectorObject] = []
	var unlinked_displacements: Array[VectorObject] = []
	var chain_position := character.global_position
	for vector in vectors:
		if vector.vector_type == VectorObject.TYPE_DISPLACEMENT:
			unlinked_displacements.append(vector)

	while not unlinked_displacements.is_empty():
		var next_vector: VectorObject
		var nearest_distance := field.snap_distance
		for candidate in unlinked_displacements:
			var distance := candidate.global_position.distance_to(chain_position)
			if distance <= nearest_distance:
				nearest_distance = distance
				next_vector = candidate

		if next_vector == null:
			break

		next_vector.global_position = chain_position
		next_vector.notify_changed()
		playable_vectors.append(next_vector)
		unlinked_displacements.erase(next_vector)
		chain_position = next_vector.get_tip_global_position()

	for vector in vectors:
		if (
			vector.vector_type == VectorObject.TYPE_DISPLACEMENT
			or not vector.has_method("activate_for")
		):
			continue

		if vector.global_position.distance_to(character.global_position) > field.snap_distance:
			continue

		vector.global_position = character.global_position
		vector.notify_changed()
		playable_vectors.append(vector)

	for vector in vectors:
		if not playable_vectors.has(vector):
			vector.is_playable_in_current_run = false
			vector.fade_out_after_play(0.8)
		else:
			vector.is_playable_in_current_run = true
			if vector.vector_type != VectorObject.TYPE_DISPLACEMENT:
				vector.call("activate_for", character)

	for vector in playable_vectors:
		if vector.vector_type == VectorObject.TYPE_DISPLACEMENT:
			vector.call("activate_for", character)
			break
