class_name ExitFlag
extends Area2D


signal player_entered


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


var _is_unlocked := false
var _unlocked_animation: StringName = &"game"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()


func set_unlocked(value: bool, animation_name: StringName = &"game") -> void:
	_is_unlocked = value
	_unlocked_animation = animation_name
	_update_visual()


func _update_visual() -> void:
	if _is_unlocked:
		_play_animation(_unlocked_animation)
	else:
		_play_animation(&"idle")


func _on_body_entered(body: Node) -> void:
	if not _is_unlocked:
		return

	if not body.is_in_group("player"):
		return

	emit_signal("player_entered")


func _play_animation(animation_name: StringName) -> void:
	if sprite.animation == animation_name and sprite.is_playing():
		return

	sprite.play(animation_name)


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "game":
		sprite.play("loop")
