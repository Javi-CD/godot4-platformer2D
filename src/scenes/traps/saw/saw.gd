class_name Saw
extends Node2D


enum MovementMode {
	PING_PONG,
	LOOP
}


@export var speed := 120.0
@export var movement_mode := MovementMode.PING_PONG

@export var use_point_delay := false
@export_range(0.0, 5.0, 0.05) var point_delay := 0.5


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var path: Node2D = $Path


var _points: Array[Vector2] = []
var _current_index := 0
var _direction := 1
var _delay_timer := 0.0


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	_collect_points()

	if _points.size() > 0:
		global_position = _points[0]
		_current_index = _get_next_point_index()


func _physics_process(delta: float) -> void:
	if _points.size() < 2:
		return

	if _delay_timer > 0.0:
		_delay_timer = max(_delay_timer - delta, 0.0)
		return

	var target := _points[_current_index]
	global_position = global_position.move_toward(target, speed * delta)

	if global_position.distance_to(target) < 2.0:
		global_position = target

		if use_point_delay and point_delay > 0.0:
			_delay_timer = point_delay

		_advance_point()


func _collect_points() -> void:
	_points.clear()

	var markers := []

	for child in path.get_children():
		if child is Marker2D:
			markers.append(child)

	markers.sort_custom(func(a, b): return a.name < b.name)

	for marker in markers:
		_points.append(marker.global_position)


func _advance_point() -> void:
	match movement_mode:
		MovementMode.PING_PONG:
			_current_index += _direction

			if _current_index >= _points.size() or _current_index < 0:
				_direction *= -1
				_current_index += _direction * 2

		MovementMode.LOOP:
			_current_index += 1

			if _current_index >= _points.size():
				_current_index = 0


func _get_next_point_index() -> int:
	if _points.size() < 2:
		return 0

	match movement_mode:
		MovementMode.PING_PONG:
			return 1

		MovementMode.LOOP:
			return 1

	return 1


func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return

	body.take_damage(global_position)
