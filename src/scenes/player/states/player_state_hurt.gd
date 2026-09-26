class_name PlayerStateHurt
extends State


func enter(msg: Dictionary = {}) -> void:
	var source_position: Vector2 = msg.get("source_position", Vector2.ZERO)
	player.enter_death_state(source_position)


func physics_update(delta: float) -> void:
	player.update_death_state(delta)
