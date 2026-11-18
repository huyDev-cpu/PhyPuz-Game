extends CanvasLayer
class_name EndOverlay

const STAGE_SCENES := [
	"res://scenes/Chapters/vector and displacement/part1/tutorial1.tscn",
	"res://scenes/Chapters/vector and displacement/part1/tutorial2.tscn",
	"res://scenes/Chapters/vector and displacement/part1/level1.tscn",
	"res://scenes/Chapters/vector and displacement/part2/tutorial3.tscn",
	"res://scenes/Chapters/vector and displacement/part2/level2.tscn",
]

@export var endgame_image: Texture2D
@export var connect_completion_sources := true
@export var show_motion_diagram := false
@export var next_stage_scene_path := ""

const END_DELAY_SECONDS := 0.5

var _backdrop: ColorRect
var _next_button: Button
var _completion_started := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("end_overlays")
	_build_overlay()
	visible = false
	call_deferred("_connect_completion_sources")


func show_completion() -> void:
	if _completion_started:
		return
	_completion_started = true
	await get_tree().create_timer(END_DELAY_SECONDS, true).timeout
	visible = true
	_backdrop.visible = true
	_next_button.disabled = _next_stage_path().is_empty()
	get_tree().paused = true


func _connect_source(source: Node) -> void:
	if source.has_signal("completed"):
		var callback := Callable(self, "show_completion")
		if not source.is_connected("completed", callback):
			source.connect("completed", callback)


func _connect_completion_sources() -> void:
	if not connect_completion_sources:
		return
	var level_root := get_parent()
	if level_root != null:
		var portal := level_root.find_child("PortalTarget", true, false)
		if portal != null:
			_connect_source(portal)
	for source in get_tree().get_nodes_in_group("completion_sources"):
		_connect_source(source)


func _build_overlay() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.78)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	var end_image := TextureRect.new()
	end_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	end_image.texture = endgame_image
	end_image.visible = endgame_image != null
	end_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(end_image)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	center.add_child(content)

	var heading := Label.new()
	heading.text = tr("END_COMPLETE")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 42)
	heading.visible = endgame_image == null
	content.add_child(heading)
	if show_motion_diagram:
		var diagram := load("res://scenes/end_distance_displacement_diagram.tscn") as PackedScene
		if diagram != null:
			content.add_child(diagram.instantiate())

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	content.add_child(actions)

	var replay_button := Button.new()
	replay_button.text = "↻"
	replay_button.tooltip_text = tr("END_REPLAY")
	replay_button.process_mode = Node.PROCESS_MODE_ALWAYS
	replay_button.custom_minimum_size = Vector2(72, 56)
	replay_button.add_theme_font_size_override("font_size", 30)
	replay_button.pressed.connect(_replay_stage)
	actions.add_child(replay_button)

	_next_button = Button.new()
	_next_button.text = "→"
	_next_button.tooltip_text = tr("END_NEXT")
	_next_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_next_button.custom_minimum_size = Vector2(72, 56)
	_next_button.add_theme_font_size_override("font_size", 30)
	_next_button.pressed.connect(_open_next_stage)
	actions.add_child(_next_button)


func _replay_stage() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _open_next_stage() -> void:
	var next_path := _next_stage_path()
	if next_path.is_empty():
		push_warning("EndOverlay: no next stage is configured for this scene.")
		return
	get_tree().paused = false
	var error_code := get_tree().change_scene_to_file(next_path)
	if error_code != OK:
		push_error("EndOverlay: could not open '%s': %s" % [next_path, error_string(error_code)])


func _next_stage_path() -> String:
	if not next_stage_scene_path.is_empty():
		return next_stage_scene_path
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return ""
	var current_path := current_scene.scene_file_path
	var current_index := STAGE_SCENES.find(current_path)
	if current_index < 0 or current_index >= STAGE_SCENES.size() - 1:
		return ""
	return STAGE_SCENES[current_index + 1]
