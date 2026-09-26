class_name PlayerStateRespawn
extends State


func enter(msg: Dictionary = {}) -> void:
	var mode: StringName = msg.get("mode", &"respawn")
	if mode == &"level_spawn":
		player.start_level_spawn_internal()
	elif mode == &"level_exit":
		player.start_level_exit_internal()
	else:
		player.start_respawn_internal()


func physics_update(_delta: float) -> void:
	# Velocity is zero during respawn/spawn/exit animations
	pass
