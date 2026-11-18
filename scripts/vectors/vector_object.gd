@tool
extends Node2D

signal vector_changed
signal origin_contacted(body: Node2D)

@export_range(0.0, 1000.0, 1.0) var arrow_length: float = 240.0:
	set(value):
		arrow_length = value
		_refresh_vector()

@export_range(-180.0, 180.0, 0.1) var angle_degrees: float = -26.5:
	set(value):
		angle_degrees = value
		_refresh_vector()

const TYPE_DISPLACEMENT := 0
const TYPE_VELOCITY := 1
const TYPE_ACCELERATION := 2
const TYPE_FORCE := 3
const TYPE_VECTOR := 4

var vector_type: int = TYPE_VECTOR

@export_group("Control")
@export var can_move: bool = true
@export var can_scale: bool = true
@export var can_rotate: bool = true

# True while this vector is part of an active addition.
var is_being_added: bool = false

@onready var hit_area: Area2D = $HitArea
@onready var hit_shape: CollisionShape2D = $HitArea/CollisionShape2D
@onready var tip_handle: Area2D = $TipHandle
@onready var origin_trigger: Area2D = $OriginTrigger

func _ready() -> void:
	# Give each vector its own shape resource.
	if hit_shape.shape != null:
		hit_shape.shape = hit_shape.shape.duplicate()

	origin_trigger.body_entered.connect(_on_origin_body_entered)
	_refresh_geometry()
	vector_changed.emit()
	
	
func _refresh_vector() -> void:
	if is_node_ready():
		_refresh_geometry()

	vector_changed.emit()


func _refresh_geometry() -> void:
	_update_tip_handle()
	_update_hit_area()


func _update_tip_handle() -> void:
	var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))
	tip_handle.position = direction * arrow_length


func _update_hit_area() -> void:
	var hit_length := maxf(arrow_length, 32.0)

	hit_area.position = Vector2.ZERO
	hit_area.rotation = deg_to_rad(angle_degrees)

	hit_shape.position = Vector2(hit_length * 0.5, 0.0)
	hit_shape.rotation = 0.0

	var rectangle := hit_shape.shape as RectangleShape2D
	if rectangle == null:
		push_warning("HitArea CollisionShape2D must use RectangleShape2D.")
		return

	rectangle.size = Vector2(hit_length, 36.0)


func get_vector_local() -> Vector2:
	var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))
	return direction * arrow_length


func get_tip_global_position() -> Vector2:
	return to_global(get_vector_local())


func get_snap_points() -> Array[Vector2]:
	return [
		global_position,
		get_tip_global_position()
	]


func set_tip_local(point: Vector2) -> void:
	if point.length() <= 1.0:
		return

	if can_scale and can_rotate:
		arrow_length = point.length()
		angle_degrees = rad_to_deg(point.angle())

	elif can_scale:
		var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))
		arrow_length = maxf(point.dot(direction), 1.0)

	elif can_rotate:
		angle_degrees = rad_to_deg(point.angle())


func notify_changed() -> void:
	vector_changed.emit()


func _on_origin_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if body is CharacterBody2D:
		origin_contacted.emit(body)
