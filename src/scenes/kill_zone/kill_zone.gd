class_name KillZone
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position, 999)
	else:
		body.queue_free()
