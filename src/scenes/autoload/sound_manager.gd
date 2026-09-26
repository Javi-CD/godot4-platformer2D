extends Node


@export var sfx_dict: Dictionary = {
	"click": preload("res://assets/Sounds/Click.wav"),
	"cancel": preload("res://assets/Sounds/Cancel.wav"),
	"pause": preload("res://assets/Sounds/Pause.wav"),
	"jump": preload("res://assets/Sounds/Jump.wav"),
	"hurt": preload("res://assets/Sounds/Hurt.wav"),
	"trampoline": preload("res://assets/Sounds/Trampoline.wav"),
	"bump": preload("res://assets/Sounds/Bump.wav"),
	"fruit_collect": preload("res://assets/Sounds/fruit_collect.wav"),
	"level_complete": preload("res://assets/Sounds/level_complete.wav"),
	"steps": preload("res://assets/Sounds/steps.wav"),
}

@export var default_bgm: AudioStream = preload("res://assets/Sounds/Music/time_for_adventure.mp3")

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	play_music()


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


func play_music(stream: AudioStream = null) -> void:
	var music_to_play: AudioStream = stream if stream != null else default_bgm
	if music_to_play == null:
		return

	if music_to_play is AudioStreamMP3:
		music_to_play.loop = true

	if music_player.playing and music_player.stream == music_to_play:
		return

	music_player.stream = music_to_play
	music_player.play()


func stop_music() -> void:
	music_player.stop()
