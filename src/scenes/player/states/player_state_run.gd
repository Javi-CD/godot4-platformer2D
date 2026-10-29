class_name PlayerStateRun
extends State


func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"run")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_move(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(&"Fall")
		return

	if player.jump_buffer_timer > 0.0 and player.can_ground_jump():
		state_machine.transition_to(&"Jump")
		return

	if abs(player.velocity.x) < 0.1:
		state_machine.transition_to(&"Idle")
