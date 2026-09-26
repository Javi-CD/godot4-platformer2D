@tool
class_name SpikedBall
extends Node2D


enum MovementMode {
	PENDULUM,
	ROTATE_360
}

@export_group("Chain Settings")
@export_range(1, 20, 1) var chain_length: int = 4:
	set(value):
		chain_length = value
		_update_chain()

@export_range(4.0, 32.0, 1.0) var link_distance: float = 8.0:
	set(value):
		link_distance = value
		_update_chain()

@export var chain_texture: Texture2D = preload("res://assets/Traps/Spiked Ball/Chain.png"):
	set(value):
		chain_texture = value
		_update_chain()

@export_group("Movement Settings")
@export var movement_mode: MovementMode = MovementMode.PENDULUM
@export_range(0.1, 10.0, 0.1) var speed: float = 2.0
@export_range(5.0, 180.0, 1.0) var max_angle_degrees: float = 65.0
@export var rotate_clockwise: bool = true

@export_group("Combat")
@export_range(1, 10, 1) var damage: int = 1

@onready var chain_container: Node2D = $ChainContainer
@onready var ball_area: Area2D = $BallArea

var _time_passed: float = 0.0


func _ready() -> void:
	_update_chain()
	if not Engine.is_editor_hint():
		if ball_area != null and not ball_area.body_entered.is_connected(_on_ball_body_entered):
			ball_area.body_entered.connect(_on_ball_body_entered)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_time_passed += delta * speed

	match movement_mode:
		MovementMode.PENDULUM:
			var angle_rad := deg_to_rad(max_angle_degrees)
			rotation = sin(_time_passed) * angle_rad

		MovementMode.ROTATE_360:
			var dir := 1.0 if rotate_clockwise else -1.0
			rotation += speed * delta * dir


func _update_chain() -> void:
	if not is_node_ready():
		return

	if chain_container == null or ball_area == null:
		return

	# clean chain_container
	for child in chain_container.get_children():
		child.queue_free()

	# create chain links
	var total_distance := 0.0

	for i in range(chain_length):
		var link_pos := Vector2(0, (i + 1) * link_distance)
		total_distance = (i + 1) * link_distance

		if chain_texture != null:
			var link_sprite := Sprite2D.new()
			link_sprite.texture = chain_texture
			link_sprite.position = link_pos
			chain_container.add_child(link_sprite)

	# ball position at the end of the chain
	ball_area.position = Vector2(0, total_distance + (link_distance * 0.5))


func _on_ball_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return

	var source_pos: Vector2 = ball_area.global_position if ball_area != null else global_position
	body.take_damage(source_pos, damage)
