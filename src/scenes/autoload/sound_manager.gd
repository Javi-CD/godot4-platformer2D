class_name SoundManager
extends Node


@export var sfx_dict: Dictionary = {
	"click": preload("res://assets/Sounds/Click.wav"),
	"cancel": preload("res://assets/Sounds/Cancel.wav"),
	"pause": preload("res://assets/Sounds/Pause.wav"),
	"jump": preload("res://assets/Sounds/Jump.wav"),
	"hurt": preload("res://assets/Sounds/Hurt.wav"),
	"trampoline": preload("res://assets/Sounds/Trampoline.wav"),
}

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer


func play_sfx(sound_name: String, pitch_range: float = 0.0) -> void:
	if not sfx_dict.has(sound_name):
		push_warning("SoundManager: Sonido '%s' no encontrado." % sound_name)
		return

	var stream: AudioStream = sfx_dict[sound_name]
	if stream == null:
		return

	sfx_player.stream = stream

	if pitch_range > 0.0:
		sfx_player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	else:
		sfx_player.pitch_scale = 1.0

	sfx_player.play()
