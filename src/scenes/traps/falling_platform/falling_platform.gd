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

@export_group("Animation & Slowdown")
@export_range(0.05, 1.0, 0.05) var min_animation_speed_scale := 0.15

@export_group("Vibration & Movement")
@export_range(0.5, 5.0, 0.1) var shake_intensity := 1.8
@export var fall_speed := 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_detector_area: Area2D = $PlayerDetectorArea

var _state := PlatformState.IDLE
var _initial_position := Vector2.ZERO
var _trigger_timer := 0.0
var _reset_timer := 0.0


func _ready() -> void:
	_initial_position = global_position
	player_detector_area.body_entered.connect(_on_player_entered)
	_reset_to_idle()


func _physics_process(delta: float) -> void:
	match _state:
		PlatformState.TRIGGERED:
			_process_vibration_and_slowdown(delta)

		PlatformState.FALLING:
			_process_fall(delta)


func _process_vibration_and_slowdown(delta: float) -> void:
	_trigger_timer = max(_trigger_timer - delta, 0.0)

	# Progress from 1.0 (just stepped on) to 0.0 (about to fall)
	var progress: float = _trigger_timer / trigger_delay if trigger_delay > 0.0 else 0.0

	# Reduces the animation speed progressively (from 1.0 to min_animation_speed_scale)
	animated_sprite.speed_scale = lerp(min_animation_speed_scale, 1.0, progress)

	# Applies the vibration to the sprite
	var current_shake: float = lerp(shake_intensity, 0.5, progress)
	var offset_x := randf_range(-current_shake, current_shake)
	var offset_y := randf_range(-current_shake, current_shake)
	animated_sprite.offset = Vector2(offset_x, offset_y)

	if _trigger_timer <= 0.0:
		_start_falling()


func _process_fall(delta: float) -> void:
	global_position.y += fall_speed * delta
	_reset_timer = max(_reset_timer - delta, 0.0)

	if _reset_timer <= 0.0:
		_reset_to_idle()


func _on_player_entered(body: Node2D) -> void:
	if _state != PlatformState.IDLE:
		return

	if not body.is_in_group("player") and not body.has_method("take_damage"):
		return

	_trigger_platform()


func _trigger_platform() -> void:
	_state = PlatformState.TRIGGERED
	_trigger_timer = trigger_delay


func _start_falling() -> void:
	_state = PlatformState.FALLING
	_reset_timer = reset_time

	# Disables the vibration and turns off the motors ("off") before falling
	animated_sprite.offset = Vector2.ZERO
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("off")

	# Disables the physical collision so the player falls
	collision_shape.set_deferred("disabled", true)


func _reset_to_idle() -> void:
	_state = PlatformState.IDLE
	global_position = _initial_position

	# Restarts with the "on" animation at normal speed
	animated_sprite.offset = Vector2.ZERO
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("on")

	collision_shape.set_deferred("disabled", false)
