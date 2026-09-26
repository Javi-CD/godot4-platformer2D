extends CharacterBody2D


enum MovementMode {
	PING_PONG,
	LOOP
}


@export var max_speed := 140.0
@export var acceleration := 900.0
@export var slow_down_distance := 24.0

@export var movement_mode := MovementMode.PING_PONG

@export var use_point_delay := false
@export_range(0.0, 5.0, 0.05) var point_delay := 0.35

@export_range(1, 10, 1) var damage := 1

@export var use_blink := true
@export_range(0.5, 10.0, 0.1) var blink_interval_min := 2.0
@export_range(0.5, 10.0, 0.1) var blink_interval_max := 4.5


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var path: Node2D = $Path


var _points: Array[Vector2] = []
var _current_index := 0
var _direction := 1

var _delay_timer := 0.0
var _blink_timer := 0.0
var _current_speed := 0.0

var _travel_direction := Vector2.ZERO
var _is_playing_hit_animation := false


func _ready() -> void:
	_collect_points()

	if _points.size() > 0:
		global_position = _points[0]
		_current_index = _get_next_point_index()

	sprite.animation_finished.connect(_on_sprite_animation_finished)
	_reset_blink_timer()
	_play_idle()


func _physics_process(delta: float) -> void:
	_update_blink_timer(delta)

	if _points.size() < 2:
		return

	if _is_playing_hit_animation:
		return

	if _delay_timer > 0.0:
		_delay_timer = max(_delay_timer - delta, 0.0)
		return

	var target := _points[_current_index]
	var to_target := target - global_position
	var distance_to_target := to_target.length()

	if distance_to_target <= 1.0:
		global_position = target
		_arrive_at_point()
		return

	var move_direction := to_target.normalized()
	_travel_direction = move_direction

	var desired_speed := max_speed

	# Desaceleración cerca del objetivo para que el movimiento se vea menos rígido.
	if slow_down_distance > 0.0 and distance_to_target < slow_down_distance:
		var ratio := distance_to_target / slow_down_distance
		desired_speed *= clamp(ratio, 0.25, 1.0)

	_current_speed = move_toward(_current_speed, desired_speed, acceleration * delta)

	var desired_motion := move_direction * _current_speed * delta
	var allowed_motion := _resolve_player_push(desired_motion)

	if allowed_motion == Vector2.ZERO:
		_current_speed = 0.0
		return

	var collision := move_and_collide(allowed_motion)

	if collision != null:
		# Aquí solo deberíamos estar chocando con el mundo, no con el jugador.
		_current_speed = 0.0
		_play_hit_animation_from_direction(_travel_direction)
		_advance_point()
		_start_point_delay_if_needed()
		return

	if global_position.distance_to(target) <= 1.0:
		global_position = target
		_arrive_at_point()


func _collect_points() -> void:
	_points.clear()

	var markers := []

	for child in path.get_children():
		if child is Marker2D:
			markers.append(child)

	markers.sort_custom(func(a, b): return a.name < b.name)

	for marker in markers:
		_points.append(marker.global_position)


func _arrive_at_point() -> void:
	_current_speed = 0.0
	_play_hit_animation_from_direction(_travel_direction)
	_advance_point()
	_start_point_delay_if_needed()


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

	return 1


func _start_point_delay_if_needed() -> void:
	if use_point_delay and point_delay > 0.0:
		_delay_timer = point_delay


func _play_hit_animation_from_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var animation_name := "idle"

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0.0:
			animation_name = "right_hit"
		else:
			animation_name = "left_hit"
	else:
		if direction.y > 0.0:
			animation_name = "bottom_hit"
		else:
			animation_name = "top_hit"

	_is_playing_hit_animation = true
	sprite.play(animation_name)


func _update_blink_timer(delta: float) -> void:
	if not use_blink:
		return

	if _is_playing_hit_animation:
		return

	_blink_timer = max(_blink_timer - delta, 0.0)

	if _blink_timer > 0.0:
		return

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("blink"):
		sprite.play("blink")
		_reset_blink_timer()


func _reset_blink_timer() -> void:
	if not use_blink:
		_blink_timer = 9999.0
		return

	var min_value = min(blink_interval_min, blink_interval_max)
	var max_value = max(blink_interval_min, blink_interval_max)
	_blink_timer = randf_range(min_value, max_value)


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "blink":
		if not _is_playing_hit_animation:
			_play_idle()
		return

	if sprite.animation.ends_with("_hit"):
		_is_playing_hit_animation = false
		_play_idle()


func _play_idle() -> void:
	if _is_playing_hit_animation:
		return

	if sprite.animation == "idle" and sprite.is_playing():
		return

	sprite.play("idle")


func _resolve_player_push(desired_motion: Vector2) -> Vector2:
	if desired_motion == Vector2.ZERO:
		return Vector2.ZERO

	var bodies := player_detector.get_overlapping_bodies()

	if bodies.is_empty():
		return desired_motion

	for body in bodies:
		if not body.is_in_group("player"):
			continue

		if body.has_method("is_invulnerable") and body.is_invulnerable():
			# Aunque esté invulnerable, si no puede moverse no queremos atravesarlo.
			pass

		# Si el jugador ya no puede seguir moviéndose en la dirección del empuje,
		# se considera aplastamiento y la roca no avanza más este frame.
		if body.has_method("can_be_pushed") and not body.can_be_pushed(desired_motion):
			if body.has_method("take_damage"):
				body.take_damage(global_position, damage)
			return Vector2.ZERO

		# Si puede moverse, primero movemos al jugador
		# y luego dejamos avanzar a la roca.
		if body.has_method("apply_push"):
			body.apply_push(desired_motion)
		else:
			body.global_position += desired_motion

	return desired_motion
