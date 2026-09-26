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

# Horizontal movement tuning
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

# Health and respawn tuning
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

# State machine reference
var state_machine: StateMachine = null

# Runtime state variables
var current_health := MAX_HEALTH
var respawn_position := Vector2.ZERO

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var air_jumps_used := 0
var performed_double_jump := false

var hurt_timer := 0.0
var invulnerability_timer := 0.0
var wall_jump_lock_timer := 0.0

var input_direction := 0.0
var jump_pressed := false
var jump_released := false

var current_spawn_mode := &"respawn"


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

	respawn_position = global_position
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	_emit_health_changed()

	_setup_state_machine()


func _setup_state_machine() -> void:
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)

	var idle_state: State = PlayerStateIdle.new()
	idle_state.name = "Idle"
	state_machine.add_child(idle_state)

	var run_state: State = PlayerStateRun.new()
	run_state.name = "Run"
	state_machine.add_child(run_state)

	var jump_state: State = PlayerStateJump.new()
	jump_state.name = "Jump"
	state_machine.add_child(jump_state)

	var fall_state: State = PlayerStateFall.new()
	fall_state.name = "Fall"
	state_machine.add_child(fall_state)

	var wall_slide_state: State = PlayerStateWallSlide.new()
	wall_slide_state.name = "WallSlide"
	state_machine.add_child(wall_slide_state)

	var hurt_state: State = PlayerStateHurt.new()
	hurt_state.name = "Hurt"
	state_machine.add_child(hurt_state)

	var respawn_state: State = PlayerStateRespawn.new()
	respawn_state.name = "Respawn"
	state_machine.add_child(respawn_state)

	state_machine.initial_state = idle_state
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	_read_input()
	_update_timers(delta)
	_update_jump_buffer(delta)
	_update_coyote_time(delta)
	_refresh_air_jumps()

	state_machine.physics_update(delta)

	_update_invulnerability_feedback()
	_update_run_dust()
	_update_wall_slide_dust()


func _read_input() -> void:
	input_direction = Input.get_axis("left", "right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")


func _update_timers(delta: float) -> void:
	if hurt_timer > 0.0:
		hurt_timer = max(hurt_timer - delta, 0.0)

	if invulnerability_timer > 0.0:
		invulnerability_timer = max(invulnerability_timer - delta, 0.0)
		if invulnerability_timer == 0.0:
			_reset_invulnerability_feedback()

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer = max(wall_jump_lock_timer - delta, 0.0)


func _update_jump_buffer(delta: float) -> void:
	if jump_pressed:
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)


func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)


func _refresh_air_jumps() -> void:
	if is_on_floor():
		air_jumps_used = 0
		performed_double_jump = false


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	if state_machine.current_state != null and state_machine.current_state.name == "Respawn":
		return

	var gravity := get_gravity()
	var gravity_multiplier := 1.0

	if velocity.y > 0.0:
		gravity_multiplier = FALL_GRAVITY_MULTIPLIER

	velocity += gravity * gravity_multiplier * delta

	if can_wall_slide():
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	else:
		velocity.y = min(velocity.y, MAX_FALL_SPEED)


func handle_move(delta: float) -> void:
	if input_direction != 0.0:
		velocity.x = move_toward(velocity.x, input_direction * SPEED_MOVE, ACCELERATION * delta)
		sprite.flip_h = input_direction < 0.0
	else:
		apply_friction(delta)


func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func apply_hurt_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func handle_variable_jump() -> void:
	if jump_released and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER


func can_ground_jump() -> bool:
	return coyote_timer > 0.0


func can_double_jump() -> bool:
	return not is_on_floor() and air_jumps_used < MAX_AIR_JUMPS and not can_wall_slide()


func can_wall_jump() -> bool:
	return can_wall_slide()


func can_wall_slide() -> bool:
	if is_wall_jump_locked():
		return false

	if is_on_floor():
		return false

	if not is_on_wall():
		return false

	if velocity.y <= 0.0:
		return false

	if input_direction == 0.0:
		return false

	var wall_direction := _get_wall_direction()
	return input_direction == wall_direction


func is_wall_jump_locked() -> bool:
	return wall_jump_lock_timer > 0.0


func perform_ground_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	performed_double_jump = false
	_emit_jump_dust()


func perform_double_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	air_jumps_used += 1
	performed_double_jump = true


func perform_wall_jump() -> void:
	var wall_normal := get_wall_normal()
	var jump_dir := wall_normal.x

	velocity.x = jump_dir * WALL_JUMP_HORIZONTAL_VELOCITY
	velocity.y = WALL_JUMP_VERTICAL_VELOCITY

	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	performed_double_jump = false
	air_jumps_used = 0
	wall_jump_lock_timer = WALL_JUMP_LOCK_TIME

	sprite.flip_h = jump_dir < 0.0


func play_animation(animation_name: StringName) -> void:
	if sprite.animation == animation_name and sprite.is_playing():
		return

	sprite.play(animation_name)


func _get_wall_direction() -> float:
	var wall_normal := get_wall_normal()
	return -wall_normal.x


func _update_invulnerability_feedback() -> void:
	if not is_invulnerable():
		return

	var time := Time.get_ticks_msec() / 1000.0
	var pulse := (sin(time * INVULNERABILITY_FLASH_SPEED) + 1.0) * 0.5
	var alpha: float = lerp(INVULNERABILITY_MIN_ALPHA, 1.0, pulse)

	sprite.modulate.a = alpha


func _reset_invulnerability_feedback() -> void:
	sprite.modulate.a = 1.0


func is_invulnerable() -> bool:
	return invulnerability_timer > 0.0


func get_current_health() -> int:
	return current_health


func get_max_health() -> int:
	return MAX_HEALTH


func take_damage(source_position: Vector2, amount: int = 1) -> void:
	if is_invulnerable():
		return

	if amount <= 0:
		return

	current_health = max(current_health - amount, 0)
	_emit_health_changed()

	if current_health <= 0:
		state_machine.transition_to(&"Respawn", {"mode": &"respawn"})
		return

	state_machine.transition_to(&"Hurt", {"source_position": source_position})


func heal(amount: int = 1) -> void:
	if amount <= 0:
		return

	current_health = min(current_health + amount, MAX_HEALTH)
	_emit_health_changed()


func set_respawn_point(new_respawn_position: Vector2) -> void:
	respawn_position = new_respawn_position


func start_level_spawn() -> void:
	state_machine.transition_to(&"Respawn", {"mode": &"level_spawn"})


func start_level_exit() -> void:
	state_machine.transition_to(&"Respawn", {"mode": &"level_exit"})


func start_respawn_internal() -> void:
	current_spawn_mode = &"respawn"
	global_position = respawn_position
	velocity = Vector2.ZERO
	current_health = MAX_HEALTH

	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	air_jumps_used = 0
	performed_double_jump = false

	hurt_timer = 0.0
	invulnerability_timer = RESPAWN_INVULNERABILITY_DURATION
	wall_jump_lock_timer = 0.0

	collision_shape.disabled = true
	sprite.visible = true

	_emit_health_changed()
	play_animation(&"respawn")


func start_level_spawn_internal() -> void:
	current_spawn_mode = &"level_spawn"
	velocity = Vector2.ZERO

	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	wall_jump_lock_timer = 0.0

	invulnerability_timer = LEVEL_SPAWN_INVULNERABILITY_DURATION
	collision_shape.disabled = true
	sprite.visible = true

	play_animation(&"respawn")


func start_level_exit_internal() -> void:
	current_spawn_mode = &"level_exit"
	velocity = Vector2.ZERO

	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	wall_jump_lock_timer = 0.0

	collision_shape.disabled = true
	play_animation(&"desappearing")


func _finish_respawn() -> void:
	collision_shape.disabled = false
	state_machine.transition_to(&"Idle")
	emit_signal("respawned")


func _finish_level_spawn() -> void:
	collision_shape.disabled = false
	state_machine.transition_to(&"Idle")


func enter_hurt_state(source_position: Vector2) -> void:
	var hit_direction: float = sign(global_position.x - source_position.x)
	if hit_direction == 0.0:
		hit_direction = 1.0

	hurt_timer = HURT_DURATION
	invulnerability_timer = INVULNERABILITY_DURATION

	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	wall_jump_lock_timer = 0.0

	velocity.x = hit_direction * HURT_KNOCKBACK_X
	velocity.y = HURT_KNOCKBACK_Y

	sprite.flip_h = hit_direction < 0.0
	play_animation(&"hurt")


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "respawn":
		if current_spawn_mode == &"respawn":
			_finish_respawn()
			return
		elif current_spawn_mode == &"level_spawn":
			_finish_level_spawn()
			return

	if sprite.animation == "desappearing" and current_spawn_mode == &"level_exit":
		emit_signal("level_exit_finished")


func _emit_health_changed() -> void:
	emit_signal("health_changed", current_health, MAX_HEALTH)


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

	var is_in_active_movement_state: bool = state_machine != null and state_machine.current_state != null and (
		state_machine.current_state.name == "Run"
	)
	var is_moving_on_floor: bool = is_on_floor() and abs(velocity.x) > 10.0 and is_in_active_movement_state

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

	if state_machine == null or state_machine.current_state == null or state_machine.current_state.name != "WallSlide":
		if wall_dust_effect.emitting:
			wall_dust_effect.emitting = false
		return

	var wall_direction: float = _get_wall_direction()

	if wall_direction < 0.0:
		wall_dust_effect.global_position = dust_spawn_wall_left.global_position
		wall_dust_effect.direction = Vector2.LEFT
	else:
		wall_dust_effect.global_position = dust_spawn_wall_right.global_position
		wall_dust_effect.direction = Vector2.RIGHT

	if not wall_dust_effect.emitting:
		wall_dust_effect.emitting = true


func _emit_jump_dust() -> void:
	if jump_dust_effect == null:
		return

	jump_dust_effect.global_position = dust_spawn_floor.global_position
	jump_dust_effect.restart()
	jump_dust_effect.emitting = true
