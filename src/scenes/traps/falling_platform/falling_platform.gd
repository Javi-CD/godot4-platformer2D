class_name FallingPlatform
extends AnimatableBody2D


enum PlatformState {
	IDLE,
	TRIGGERED,
	FALLING
}

@export_group("Timing & Delays")
@export_range(0.1, 3.0, 0.05) var trigger_delay := 0.6
@export_range(0.5, 10.0, 0.5) var reset_time := 3.0

@export_group("Vibration & Weight Dip")
@export_range(0.0, 5.0, 0.1) var shake_intensity := 1.8
@export_range(0.0, 10.0, 0.5) var dip_distance := 3.0
@export_range(5.0, 40.0, 1.0) var dip_speed := 20.0

@export_group("Physics & Movement")
@export var fall_speed := 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_detector_area: Area2D = $PlayerDetectorArea

var _state := PlatformState.IDLE
var _initial_position := Vector2.ZERO
var _trigger_timer := 0.0
var _reset_timer := 0.0

var _target_dip_y := 0.0
var _current_dip_y := 0.0


func _ready() -> void:
	_initial_position = global_position
	player_detector_area.body_entered.connect(_on_player_entered)
	player_detector_area.body_exited.connect(_on_player_exited)
	_reset_to_idle()


func _physics_process(delta: float) -> void:
	match _state:
		PlatformState.IDLE, PlatformState.TRIGGERED:
			_process_dip_and_vibration(delta)

		PlatformState.FALLING:
			_process_fall(delta)


func _process_dip_and_vibration(delta: float) -> void:
	# Smoothly interpolate vertical dip offset
	_current_dip_y = move_toward(_current_dip_y, _target_dip_y, dip_speed * delta)
	global_position.y = _initial_position.y + _current_dip_y

	if _state == PlatformState.TRIGGERED:
		_trigger_timer = max(_trigger_timer - delta, 0.0)

		# Apply vibration offset to sprite if intensity is above 0
		if shake_intensity > 0.0:
			var offset_x := randf_range(-shake_intensity, shake_intensity)
			var offset_y := randf_range(-shake_intensity, shake_intensity)
			animated_sprite.offset = Vector2(offset_x, offset_y)
		else:
			animated_sprite.offset = Vector2.ZERO

		if _trigger_timer <= 0.0:
			_start_falling()


func _process_fall(delta: float) -> void:
	global_position.y += fall_speed * delta
	_reset_timer = max(_reset_timer - delta, 0.0)

	if _reset_timer <= 0.0:
		_reset_to_idle()


func _on_player_entered(body: Node2D) -> void:
	if not _is_player(body):
		return

	_target_dip_y = dip_distance

	if _state == PlatformState.IDLE:
		_trigger_platform()


func _on_player_exited(body: Node2D) -> void:
	if not _is_player(body):
		return

	# When player leaves, spring back up unless it is already falling
	if _state != PlatformState.FALLING:
		_target_dip_y = 0.0


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _trigger_platform() -> void:
	_state = PlatformState.TRIGGERED
	_trigger_timer = trigger_delay


func _start_falling() -> void:
	_state = PlatformState.FALLING
	_reset_timer = reset_time
	_target_dip_y = 0.0
	_current_dip_y = 0.0

	animated_sprite.offset = Vector2.ZERO
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("off")

	collision_shape.set_deferred("disabled", true)


func _reset_to_idle() -> void:
	_state = PlatformState.IDLE
	_target_dip_y = 0.0
	_current_dip_y = 0.0
	global_position = _initial_position

	animated_sprite.offset = Vector2.ZERO
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("on")

	collision_shape.set_deferred("disabled", false)
