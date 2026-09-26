extends CanvasLayer


@onready var heart_display: AnimatedSprite2D = $HeartDisplay


var _player: Node = null


func set_player(player: Node) -> void:
	if _player != null and _player.health_changed.is_connected(_on_player_health_changed):
		_player.health_changed.disconnect(_on_player_health_changed)

	_player = player

	if _player == null:
		heart_display.visible = false
		return

	heart_display.visible = true

	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(_player.get_current_health(), _player.get_max_health())


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	var state_index := max_health - current_health
	var animation_name := "state_%d" % state_index

	if heart_display.animation == animation_name and heart_display.is_playing():
		return

	heart_display.play(animation_name)
