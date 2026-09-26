class_name PlayerStateFall
extends State


func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"fall")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_variable_jump()

	if not player.is_wall_jump_locked():
		player.handle_move(delta)

	player.move_and_slide()

	if player.is_on_floor():
		if abs(player.velocity.x) > 0.1:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")
		return

	if player.can_wall_slide():
		state_machine.transition_to(&"WallSlide")
		return

	if player.jump_buffer_timer > 0.0:
		if player.can_ground_jump():
			state_machine.transition_to(&"Jump")
			return
		elif player.can_wall_jump():
			state_machine.transition_to(&"Jump", {"wall_jump": true})
			return
		elif player.can_double_jump():
			state_machine.transition_to(&"Jump", {"double_jump": true})
			return
