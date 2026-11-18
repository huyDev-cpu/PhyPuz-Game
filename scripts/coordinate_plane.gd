extends Node2D
class_name CoordinatePlane

var selected_objects: Array[Node2D] = []


func _ready() -> void:
	var grid := get_node_or_null("Grid") as Node2D
	if grid != null:
		grid.queue_redraw()
