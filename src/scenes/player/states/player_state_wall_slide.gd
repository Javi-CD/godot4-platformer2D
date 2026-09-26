class_name PlayerStateWallSlide
extends State


func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"wall_slide")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()

	if player.jump_buffer_timer > 0.0 and player.can_wall_jump():
		state_machine.transition_to(&"Jump", {"wall_jump": true})
		return

	if player.is_on_floor():
		if abs(player.velocity.x) > 0.1:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")
		return

	if not player.can_wall_slide():
		if player.velocity.y < 0.0:
			state_machine.transition_to(&"Jump")
		else:
			state_machine.transition_to(&"Fall")
