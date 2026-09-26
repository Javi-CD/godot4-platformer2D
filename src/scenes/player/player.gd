class_name Player
extends CharacterBody2D


signal health_changed(current_health: int, max_health: int)
signal respawned
signal level_exit_finished

@onready var sprite: AnimatedSprite2D = $PlayerAnimatedSprite
@onready var collision_shape: CollisionShape2D = $PlayerColliision
@onready var dust_spawn_floor: Marker2D = $DustSpawnFloor
@onready var dust_effect: CPUParticles2D = $DustEffect
@onready var dust_spawn_wall_left: Marker2D = $DustSpawnWallLeft
@onready var dust_spawn_wall_right: Marker2D = $DustSpawnWallRight
@onready var wall_dust_effect: CPUParticles2D = $WallDustEffect
@onready var jump_dust_effect: CPUParticles2D = $JumpDustEffect

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	DOUBLE_JUMP,
	FALL,
	WALL_SLIDE,
	HURT,
	RESPAWNING,
	LEVEL_SPAWNING,
	LEVEL_EXITING
}


# Horizontal movement
const SPEED_MOVE := 200.0
const ACCELERATION := 800.0
const FRICTION := 1000.0

# Ground and air jump tuning
const JUMP_VELOCITY := -300.0
const JUMP_BUFFER_TIME := 0.1
const JUMP_CUT_MULTIPLIER := 0.5
const MAX_AIR_JUMPS := 1

# Wall jump tuning
const WALL_JUMP_HORIZONTAL_VELOCITY := 220.0
const WALL_JUMP_VERTICAL_VELOCITY := -280.0
const WALL_JUMP_LOCK_TIME := 0.15
const WALL_SLIDE_SPEED := 60.0

# Fall tuning
const FALL_GRAVITY_MULTIPLIER := 1.5
const MAX_FALL_SPEED := 500.0

# Jump forgiveness
const COYOTE_TIME := 0.1

# Health and respawn
const MAX_HEALTH := 4
const RESPAWN_INVULNERABILITY_DURATION := 1.0
const LEVEL_SPAWN_INVULNERABILITY_DURATION := 0.5

# Hurt tuning
const HURT_DURATION := 0.35
const INVULNERABILITY_DURATION := 0.6
const HURT_KNOCKBACK_X := 230.0
const HURT_KNOCKBACK_Y := -190.0

# Invulnerability visual feedback
const INVULNERABILITY_FLASH_SPEED := 18.0
const INVULNERABILITY_MIN_ALPHA := 0.45

# Runtime state
var _state := PlayerState.IDLE
var _current_health := MAX_HEALTH
var _respawn_position := Vector2.ZERO

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _air_jumps_used := 0
var _performed_double_jump := false

# Hurt and recovery
var _hurt_timer := 0.0
var _invulnerability_timer := 0.0

# Wall jump control
var _wall_jump_lock_timer := 0.0

# Cached input
var _input_direction := 0.0
var _jump_pressed := false
var _jump_released := false

func _ready() -> void:
	dust_effect.emitting = false
	dust_effect.one_shot = false
	dust_effect.local_coords = false
	
	wall_dust_effect.emitting = false
	wall_dust_effect.one_shot = false
	wall_dust_effect.local_coords = false
	
	jump_dust_effect.emitting = false
	jump_dust_effect.one_shot = true
	jump_dust_effect.local_coords = false
	
	_respawn_position = global_position
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	_emit_health_changed()


func _physics_process(delta: float) -> void:
	_read_input()
	_update_timers(delta)
	_update_jump_buffer(delta)
	_update_coyote_time(delta)
	_refresh_air_jumps()

	_apply_gravity(delta)
	_process_action_state(delta)

	move_and_slide()

	_update_state()
	_update_animations()
	_update_invulnerability_feedback()
	_update_run_dust()
	_update_wall_slide_dust()


func _read_input() -> void:
	_input_direction = Input.get_axis("left", "right")
	_jump_pressed = Input.is_action_just_pressed("jump")
	_jump_released = Input.is_action_just_released("jump")


func _process_action_state(delta: float) -> void:
	if _is_control_locked():
		if _state == PlayerState.HURT:
			_apply_hurt_friction(delta)
		return

	_handle_jump()
	_handle_variable_jump()

	if not _is_wall_jump_locked():
		_handle_move(delta)


func _update_timers(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = max(_hurt_timer - delta, 0.0)

		if _hurt_timer == 0.0 and _state == PlayerState.HURT:
			_exit_hurt_state()

	if _invulnerability_timer > 0.0:
		_invulnerability_timer = max(_invulnerability_timer - delta, 0.0)

		if _invulnerability_timer == 0.0:
			_reset_invulnerability_feedback()

	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer = max(_wall_jump_lock_timer - delta, 0.0)


func _update_jump_buffer(delta: float) -> void:
	if _jump_pressed:
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)


func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)


func _refresh_air_jumps() -> void:
	if is_on_floor():
		_air_jumps_used = 0
		_performed_double_jump = false


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	if _state == PlayerState.RESPAWNING \
		or _state == PlayerState.LEVEL_SPAWNING \
		or _state == PlayerState.LEVEL_EXITING:
		return

	var gravity := get_gravity()
	var gravity_multiplier := 1.0

	if velocity.y > 0.0:
		gravity_multiplier = FALL_GRAVITY_MULTIPLIER

	velocity += gravity * gravity_multiplier * delta

	if _can_wall_slide():
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	else:
		velocity.y = min(velocity.y, MAX_FALL_SPEED)


func _handle_jump() -> void:
	if _jump_buffer_timer <= 0.0:
		return

	if _can_wall_jump():
		_perform_wall_jump()
		return

	if _can_ground_jump():
		_perform_ground_jump()
		return

	if _can_double_jump():
		_perform_double_jump()


func _handle_variable_jump() -> void:
	if _jump_released and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER


func _handle_move(delta: float) -> void:
	if _input_direction != 0.0:
		velocity.x = move_toward(
			velocity.x,
			_input_direction * SPEED_MOVE,
			ACCELERATION * delta
		)
		sprite.flip_h = _input_direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func _apply_hurt_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func _can_ground_jump() -> bool:
	return _coyote_timer > 0.0


func _can_double_jump() -> bool:
	return not is_on_floor() and _air_jumps_used < MAX_AIR_JUMPS and not _can_wall_slide()


func _can_wall_jump() -> bool:
	return _can_wall_slide()


func _perform_ground_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_performed_double_jump = false

	_emit_jump_dust()


func _perform_double_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_air_jumps_used += 1
	_performed_double_jump = true


func _perform_wall_jump() -> void:
	var wall_normal := get_wall_normal()
	var jump_direction := wall_normal.x

	velocity.x = jump_direction * WALL_JUMP_HORIZONTAL_VELOCITY
	velocity.y = WALL_JUMP_VERTICAL_VELOCITY

	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_performed_double_jump = false
	_air_jumps_used = 0
	_wall_jump_lock_timer = WALL_JUMP_LOCK_TIME

	sprite.flip_h = jump_direction < 0.0


func _update_state() -> void:
	if _is_priority_state():
		return

	if _can_wall_slide():
		_state = PlayerState.WALL_SLIDE
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			if _performed_double_jump:
				_state = PlayerState.DOUBLE_JUMP
			else:
				_state = PlayerState.JUMP
		else:
			_state = PlayerState.FALL
		return

	if abs(velocity.x) > 0.1:
		_state = PlayerState.RUN
	else:
		_state = PlayerState.IDLE


func _update_animations() -> void:
	match _state:
		PlayerState.IDLE:
			_play_animation("idle")
		PlayerState.RUN:
			_play_animation("run")
		PlayerState.JUMP:
			_play_animation("jump")
		PlayerState.DOUBLE_JUMP:
			_play_animation("double_jump")
		PlayerState.FALL:
			_play_animation("fall")
		PlayerState.WALL_SLIDE:
			_play_animation("wall_slide")
		PlayerState.HURT:
			_play_animation("hurt")
		PlayerState.RESPAWNING, PlayerState.LEVEL_SPAWNING:
			_play_animation("respawn")
		PlayerState.LEVEL_EXITING:
			_play_animation("desappearing")


func _play_animation(animation_name: StringName) -> void:
	if sprite.animation == animation_name and sprite.is_playing():
		return

	sprite.play(animation_name)


func _can_wall_slide() -> bool:
	if _is_wall_jump_locked():
		return false

	if is_on_floor():
		return false

	if not is_on_wall():
		return false

	if velocity.y <= 0.0:
		return false

	if _input_direction == 0.0:
		return false

	var wall_direction := _get_wall_direction()
	return _input_direction == wall_direction


func _get_wall_direction() -> float:
	var wall_normal := get_wall_normal()
	return -wall_normal.x


func _update_invulnerability_feedback() -> void:
	if not is_invulnerable():
		return

	var time := Time.get_ticks_msec() / 1000.0
	var pulse := (sin(time * INVULNERABILITY_FLASH_SPEED) + 1.0) * 0.5
	var alpha = lerp(INVULNERABILITY_MIN_ALPHA, 1.0, pulse)

	sprite.modulate.a = alpha


func _reset_invulnerability_feedback() -> void:
	sprite.modulate.a = 1.0


func _is_control_locked() -> bool:
	return _state == PlayerState.HURT \
		or _state == PlayerState.RESPAWNING \
		or _state == PlayerState.LEVEL_SPAWNING \
		or _state == PlayerState.LEVEL_EXITING


func _is_wall_jump_locked() -> bool:
	return _wall_jump_lock_timer > 0.0


func _is_priority_state() -> bool:
	return _state == PlayerState.HURT \
		or _state == PlayerState.RESPAWNING \
		or _state == PlayerState.LEVEL_SPAWNING \
		or _state == PlayerState.LEVEL_EXITING


func _exit_hurt_state() -> void:
	_state = PlayerState.IDLE


func is_invulnerable() -> bool:
	return _invulnerability_timer > 0.0


func get_current_health() -> int:
	return _current_health


func get_max_health() -> int:
	return MAX_HEALTH


func take_damage(source_position: Vector2, amount: int = 1) -> void:
	if is_invulnerable():
		return

	if amount <= 0:
		return

	_current_health = max(_current_health - amount, 0)
	_emit_health_changed()

	if _current_health <= 0:
		_start_respawn()
		return

	_enter_hurt_state(source_position)


func heal(amount: int = 1) -> void:
	if amount <= 0:
		return

	_current_health = min(_current_health + amount, MAX_HEALTH)
	_emit_health_changed()


func set_respawn_point(new_respawn_position: Vector2) -> void:
	_respawn_position = new_respawn_position


func start_level_spawn() -> void:
	_state = PlayerState.LEVEL_SPAWNING
	velocity = Vector2.ZERO

	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_wall_jump_lock_timer = 0.0

	_invulnerability_timer = LEVEL_SPAWN_INVULNERABILITY_DURATION
	collision_shape.disabled = true
	sprite.visible = true

	_play_animation("respawn")


func start_level_exit() -> void:
	if _state == PlayerState.LEVEL_EXITING:
		return

	_state = PlayerState.LEVEL_EXITING
	velocity = Vector2.ZERO

	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_wall_jump_lock_timer = 0.0

	collision_shape.disabled = true
	_play_animation("desappearing")


func _start_respawn() -> void:
	global_position = _respawn_position
	velocity = Vector2.ZERO

	_state = PlayerState.RESPAWNING
	_current_health = MAX_HEALTH

	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_air_jumps_used = 0
	_performed_double_jump = false

	_hurt_timer = 0.0
	_invulnerability_timer = RESPAWN_INVULNERABILITY_DURATION
	_wall_jump_lock_timer = 0.0

	collision_shape.disabled = true
	sprite.visible = true

	_emit_health_changed()
	_play_animation("respawn")


func _finish_respawn() -> void:
	collision_shape.disabled = false
	_state = PlayerState.IDLE
	_play_animation("idle")
	emit_signal("respawned")


func _finish_level_spawn() -> void:
	collision_shape.disabled = false
	_state = PlayerState.IDLE
	_play_animation("idle")


func _enter_hurt_state(source_position: Vector2) -> void:
	var hit_direction = sign(global_position.x - source_position.x)

	if hit_direction == 0.0:
		hit_direction = 1.0

	_state = PlayerState.HURT
	_hurt_timer = HURT_DURATION
	_invulnerability_timer = INVULNERABILITY_DURATION

	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_wall_jump_lock_timer = 0.0

	velocity.x = hit_direction * HURT_KNOCKBACK_X
	velocity.y = HURT_KNOCKBACK_Y

	sprite.flip_h = hit_direction < 0.0
	_play_animation("hurt")


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "respawn":
		if _state == PlayerState.RESPAWNING:
			_finish_respawn()
			return

		if _state == PlayerState.LEVEL_SPAWNING:
			_finish_level_spawn()
			return

	if sprite.animation == "desappearing" and _state == PlayerState.LEVEL_EXITING:
		emit_signal("level_exit_finished")


func _emit_health_changed() -> void:
	emit_signal("health_changed", _current_health, MAX_HEALTH)


func is_blocked_in_direction(direction: Vector2) -> bool:
	if direction.x > 0.0 and is_on_wall():
		return get_wall_normal().x < 0.0

	if direction.x < 0.0 and is_on_wall():
		return get_wall_normal().x > 0.0

	if direction.y > 0.0 and is_on_floor():
		return true

	if direction.y < 0.0 and is_on_ceiling():
		return true

	return false


func can_be_pushed(push_motion: Vector2) -> bool:
	if push_motion == Vector2.ZERO:
		return true

	return not test_move(global_transform, push_motion)


func apply_push(push_motion: Vector2) -> void:
	if push_motion == Vector2.ZERO:
		return

	global_position += push_motion


func _update_run_dust() -> void:
	if dust_effect == null:
		return

	var is_moving_on_floor = is_on_floor() and abs(velocity.x) > 10.0 and not _is_control_locked()

	if not is_moving_on_floor:
		if dust_effect.emitting:
			dust_effect.emitting = false
		
		return

	dust_effect.global_position = dust_spawn_floor.global_position

	if velocity.x > 0.0:
		dust_effect.direction = Vector2.LEFT
	else:
		dust_effect.direction = Vector2.RIGHT

	if not dust_effect.emitting:
		dust_effect.emitting = true


func _update_wall_slide_dust() -> void:
	if wall_dust_effect == null:
		return

	if _state != PlayerState.WALL_SLIDE:
		if wall_dust_effect.emitting:
			wall_dust_effect.emitting = false
		return

	# _get_wall_direction() devuelve la dirección hacia la pared:
	# -1 = pared a la izquierda
	#  1 = pared a la derecha
	var wall_direction := _get_wall_direction()

	if wall_direction < 0.0:
		wall_dust_effect.global_position = dust_spawn_wall_left.global_position

		# Emite desde la pared izquierda.
		# Si quieres que salga alejándose de la pared, usa Vector2.RIGHT.
		wall_dust_effect.direction = Vector2.LEFT
	else:
		wall_dust_effect.global_position = dust_spawn_wall_right.global_position

		# Emite desde la pared derecha.
		# Si quieres que salga alejándose de la pared, usa Vector2.LEFT.
		wall_dust_effect.direction = Vector2.RIGHT

	if not wall_dust_effect.emitting:
		wall_dust_effect.emitting = true


func _emit_jump_dust() -> void:
	if jump_dust_effect == null:
		return

	jump_dust_effect.global_position = dust_spawn_floor.global_position

	# Reinicia la emisión para que el efecto pueda dispararse cada vez que salta.
	jump_dust_effect.restart()
	jump_dust_effect.emitting = true
