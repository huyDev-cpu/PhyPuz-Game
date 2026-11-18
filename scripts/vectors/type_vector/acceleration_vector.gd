@tool
extends VectorObject


func _init() -> void:
	vector_type = VectorObject.TYPE_ACCELERATION


func _ready() -> void:
	super._ready()
	if not origin_contacted.is_connected(_on_origin_contacted):
		origin_contacted.connect(_on_origin_contacted)


func activate_for(body: Node2D) -> void:
	_on_origin_contacted(body)


func _on_origin_contacted(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	if is_being_traversed or is_being_applied:
		return

	if body.has_method("apply_acceleration"):
		body.call("apply_acceleration", self)
