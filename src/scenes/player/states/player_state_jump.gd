class_name PlayerStateJump
extends State


func enter(msg: Dictionary = {}) -> void:
	if msg.get("double_jump", false):
		player.perform_double_jump()
		player.play_animation(&"double_jump")
	elif msg.get("wall_jump", false):
		player.perform_wall_jump()
		player.play_animation(&"jump")
	else:
		player.perform_ground_jump()
		player.play_animation(&"jump")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_variable_jump()

	if not player.is_wall_jump_locked():
		player.handle_move(delta)

	player.move_and_slide()

	if player.can_wall_slide():
		state_machine.transition_to(&"WallSlide")
		return

	if player.jump_buffer_timer > 0.0 and player.can_double_jump():
		state_machine.transition_to(&"Jump", {"double_jump": true})
		return

	if player.velocity.y >= 0.0:
		state_machine.transition_to(&"Fall")
		return

	if player.is_on_floor():
		if abs(player.velocity.x) > 0.1:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")
