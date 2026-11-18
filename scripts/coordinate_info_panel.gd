extends CanvasLayer

const PANEL_BACKGROUND := Color("#292E33")
const PANEL_BORDER := Color("#454D55")
const TEXT_COLOR := Color("#EEF1F4")
const INPUT_BACKGROUND := Color("#F3F5F7")
const INPUT_TEXT_COLOR := Color("#20262D")

@onready var coordinate_plane: CoordinatePlane = (
	get_parent().get_node("CoordinatePlane") as CoordinatePlane
)

var _panel: PanelContainer
var _type_icon: ColorRect
var _type_label: Label
var _origin_x: SpinBox
var _origin_y: SpinBox
var _length: SpinBox
var _angle: SpinBox
var _tip_x: SpinBox
var _tip_y: SpinBox
var _current_vector: VectorObject
var _is_syncing_fields := false
var _editing_field: SpinBox


func _ready() -> void:
	_build_panel()


func _process(_delta: float) -> void:
	_current_vector = _get_selected_vector()
	_panel.visible = _current_vector != null
	if _current_vector == null:
		return

	var spacing := _get_grid_spacing()
	var origin := coordinate_plane.to_local(_current_vector.global_position)
	var tip := coordinate_plane.to_local(_current_vector.get_tip_global_position())
	var delta := tip - origin
	var origin_coordinates := Vector2(origin.x / spacing, -origin.y / spacing)
	var tip_coordinates := Vector2(tip.x / spacing, -tip.y / spacing)
	var length := delta.length() / spacing
	var angle := rad_to_deg(atan2(-delta.y, delta.x))

	_type_label.text = _get_type_name(_current_vector.vector_type)
	_type_label.add_theme_color_override(
		"font_color",
		_get_vector_color(_current_vector.vector_type)
	)
	_type_icon.color = _get_vector_color(_current_vector.vector_type)
	_length.suffix = _get_length_unit(_current_vector.vector_type)

	_is_syncing_fields = true
	_sync_field(_origin_x, origin_coordinates.x)
	_sync_field(_origin_y, origin_coordinates.y)
	_sync_field(_length, length)
	_sync_field(_angle, angle)
	_sync_field(_tip_x, tip_coordinates.x)
	_sync_field(_tip_y, tip_coordinates.y)
	_is_syncing_fields = false


func _sync_field(field: SpinBox, value: float) -> void:
	if field != _editing_field:
		field.value = value


func _build_panel() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -316.0
	_panel.offset_top = -214.0
	_panel.offset_right = -24.0
	_panel.offset_bottom = -24.0
	_panel.custom_minimum_size = Vector2(292.0, 190.0)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BACKGROUND
	panel_style.border_color = PANEL_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(8.0)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	_panel.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	content.add_child(header)

	_type_icon = ColorRect.new()
	_type_icon.custom_minimum_size = Vector2(12.0, 12.0)
	_type_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_type_icon)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 16)
	header.add_child(_type_label)

	var details := GridContainer.new()
	details.columns = 2
	details.add_theme_constant_override("h_separation", 8)
	details.add_theme_constant_override("v_separation", 1)
	content.add_child(details)

	_origin_x = _create_numeric_input(-1000.0, 1000.0, 0.1, 88.0)
	_origin_x.value_changed.connect(_on_origin_x_changed)
	_origin_y = _create_numeric_input(-1000.0, 1000.0, 0.1, 88.0)
	_origin_y.value_changed.connect(_on_origin_y_changed)
	_add_coordinate_row(details, "Origin", _origin_x, _origin_y)

	_length = _add_numeric_row(details, "Length", 0.0, 25.0, 0.1)
	_length.value_changed.connect(_on_length_changed)
	_angle = _add_numeric_row(details, "Angle", -180.0, 180.0, 0.1)
	_angle.value_changed.connect(_on_angle_changed)

	_tip_x = _create_numeric_input(-1000.0, 1000.0, 0.1, 88.0)
	_tip_x.value_changed.connect(_on_tip_x_changed)
	_tip_y = _create_numeric_input(-1000.0, 1000.0, 0.1, 88.0)
	_tip_y.value_changed.connect(_on_tip_y_changed)
	_add_coordinate_row(details, "Tip", _tip_x, _tip_y)

	var units_hint := Label.new()
	units_hint.text = "Coordinates in meters  ·  angle in degrees"
	units_hint.add_theme_color_override("font_color", Color("#B9C1C8"))
	units_hint.add_theme_font_size_override("font_size", 11)
	content.add_child(units_hint)


func _add_coordinate_row(
	container: GridContainer,
	title: String,
	x_input: SpinBox,
	y_input: SpinBox
) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	container.add_child(title_label)

	var coordinates := HBoxContainer.new()
	coordinates.add_theme_constant_override("separation", 3)
	container.add_child(coordinates)

	var x_label := Label.new()
	x_label.text = "X"
	x_label.add_theme_color_override("font_color", TEXT_COLOR)
	coordinates.add_child(x_label)
	coordinates.add_child(x_input)

	var y_label := Label.new()
	y_label.text = "Y"
	y_label.add_theme_color_override("font_color", TEXT_COLOR)
	coordinates.add_child(y_label)
	coordinates.add_child(y_input)


func _add_numeric_row(
	container: GridContainer,
	title: String,
	minimum: float,
	maximum: float,
	step: float
) -> SpinBox:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	container.add_child(title_label)

	var input := _create_numeric_input(minimum, maximum, step, 88.0)
	container.add_child(input)
	return input


func _create_numeric_input(
	minimum: float,
	maximum: float,
	step: float,
	width: float
) -> SpinBox:
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.step = step
	input.custom_minimum_size = Vector2(width, 24.0)
	input.add_theme_constant_override("buttons_width", 0)
	input.add_theme_constant_override("set_min_buttons_width_from_icons", 0)
	input.add_theme_font_size_override("font_size", 14)
	input.add_theme_color_override("font_color", INPUT_TEXT_COLOR)
	input.add_theme_color_override("font_selected_color", INPUT_TEXT_COLOR)
	var line_edit := input.get_line_edit()
	line_edit.add_theme_color_override("font_color", INPUT_TEXT_COLOR)
	line_edit.add_theme_stylebox_override(
		"normal",
		_create_input_style()
	)
	line_edit.add_theme_stylebox_override(
		"focus",
		_create_input_style()
	)
	line_edit.focus_entered.connect(_on_field_focus_entered.bind(input))
	line_edit.focus_exited.connect(_on_field_focus_exited.bind(input))
	for child in input.find_children("*", "BaseButton", true, false):
		var button := child as BaseButton
		if button != null:
			button.visible = false
	return input


func _create_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INPUT_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2.0)
	return style


func _on_origin_x_changed(value: float) -> void:
	if _is_syncing_fields or not is_instance_valid(_current_vector):
		return
	var origin := Vector2(value * _get_grid_spacing(), -_origin_y.value * _get_grid_spacing())
	_current_vector.global_position = coordinate_plane.to_global(origin)
	_current_vector.notify_changed()


func _on_origin_y_changed(value: float) -> void:
	if _is_syncing_fields or not is_instance_valid(_current_vector):
		return
	var origin := Vector2(_origin_x.value * _get_grid_spacing(), -value * _get_grid_spacing())
	_current_vector.global_position = coordinate_plane.to_global(origin)
	_current_vector.notify_changed()


func _on_length_changed(value: float) -> void:
	if _is_syncing_fields or not is_instance_valid(_current_vector):
		return
	_current_vector.arrow_length = value * _get_grid_spacing()


func _on_angle_changed(value: float) -> void:
	if _is_syncing_fields or not is_instance_valid(_current_vector):
		return
	_current_vector.angle_degrees = -value


func _on_tip_x_changed(value: float) -> void:
	_set_tip_from_fields(value, _tip_y.value)


func _on_tip_y_changed(value: float) -> void:
	_set_tip_from_fields(_tip_x.value, value)


func _on_field_focus_entered(field: SpinBox) -> void:
	_editing_field = field


func _on_field_focus_exited(field: SpinBox) -> void:
	if _editing_field == field:
		_editing_field = null


func _set_tip_from_fields(x_value: float, y_value: float) -> void:
	if _is_syncing_fields or not is_instance_valid(_current_vector):
		return
	var spacing := _get_grid_spacing()
	var tip_in_plane := Vector2(x_value * spacing, -y_value * spacing)
	var tip_global := coordinate_plane.to_global(tip_in_plane)
	_current_vector.set_tip_local(_current_vector.to_local(tip_global))


func _get_selected_vector() -> VectorObject:
	for index in range(coordinate_plane.selected_objects.size() - 1, -1, -1):
		var selected := coordinate_plane.selected_objects[index]
		if is_instance_valid(selected) and selected is VectorObject:
			return selected as VectorObject
	return null


func _get_grid_spacing() -> float:
	var grid := coordinate_plane.get_node_or_null("Grid")
	if grid == null:
		return 40.0
	return maxf(float(grid.get("spacing")), 1.0)


func _get_type_name(vector_type: int) -> String:
	match vector_type:
		VectorObject.TYPE_DISPLACEMENT:
			return "Displacement"
		VectorObject.TYPE_VELOCITY:
			return "Velocity"
		VectorObject.TYPE_ACCELERATION:
			return "Acceleration"
		VectorObject.TYPE_FORCE:
			return "Force"
		VectorObject.TYPE_VECTOR:
			return "Vector"
	return "Vector"


func _get_length_unit(vector_type: int) -> String:
	match vector_type:
		VectorObject.TYPE_VELOCITY:
			return " m/s"
		VectorObject.TYPE_ACCELERATION:
			return " m/s²"
		VectorObject.TYPE_FORCE:
			return " N"
	return " m"


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
	return Color("#C4CCD7")
