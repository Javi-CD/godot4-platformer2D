class_name StartPoint
extends StaticBody2D


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger_area: Area2D = $TriggerArea

var _has_triggered: bool = false


func _ready() -> void:
	if trigger_area != null:
		trigger_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _has_triggered:
		return

	if body is Player or body.has_method("take_damage"):
		_has_triggered = true
		if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("moving"):
			sprite.play("moving")
		SoundManager.play_sfx("bump")
		MainCamera.shake(3.5, 0.15)
