class_name PlayerStateHurt
extends State


func enter(msg: Dictionary = {}) -> void:
	var source_position: Vector2 = msg.get("source_position", Vector2.ZERO)
	player.enter_hurt_state(source_position)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_hurt_friction(delta)
	player.move_and_slide()

	if player.hurt_timer <= 0.0:
		if player.is_on_floor():
			if abs(player.velocity.x) > 0.1:
				state_machine.transition_to(&"Run")
			else:
				state_machine.transition_to(&"Idle")
		else:
			state_machine.transition_to(&"Fall")
