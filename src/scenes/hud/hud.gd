class_name HUD
extends CanvasLayer


signal previous_level_requested
signal restart_level_requested
signal next_level_requested


@onready var heart_display: AnimatedSprite2D = $HeartDisplay
@onready var previous_button: TextureButton = get_node_or_null("NavigationContainer/HBoxContainer/PreviousButton")
@onready var restart_button: TextureButton = get_node_or_null("NavigationContainer/HBoxContainer/RestartButton")
@onready var next_button: TextureButton = get_node_or_null("NavigationContainer/HBoxContainer/NextButton")


var _player: Node = null


func _ready() -> void:
	if previous_button != null:
		previous_button.pressed.connect(func(): emit_signal("previous_level_requested"))
	if restart_button != null:
		restart_button.pressed.connect(func(): emit_signal("restart_level_requested"))
	if next_button != null:
		next_button.pressed.connect(func(): emit_signal("next_level_requested"))

	_setup_button_animations()


func _setup_button_animations() -> void:
	var buttons: Array[TextureButton] = []
	if previous_button != null: buttons.append(previous_button)
	if restart_button != null: buttons.append(restart_button)
	if next_button != null: buttons.append(next_button)

	for button in buttons:
		_attach_click_animation(button)


func _attach_click_animation(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0
	if not button.resized.is_connected(_on_button_resized.bind(button)):
		button.resized.connect(_on_button_resized.bind(button))

	button.button_down.connect(func():
		SoundManager.play_sfx("click", 0.05)

		var tween := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(0.85, 0.85), 0.06)
		tween.parallel().tween_property(button, "modulate", Color(0.75, 0.75, 0.75), 0.06)
	)

	button.button_up.connect(func():
		var tween := button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.1)
	)


func _on_button_resized(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0


func set_player(player: Node) -> void:
	if _player != null and _player.has_signal("health_changed") and _player.health_changed.is_connected(_on_player_health_changed):
		_player.health_changed.disconnect(_on_player_health_changed)

	_player = player

	if _player == null:
		heart_display.visible = false
		return

	heart_display.visible = true

	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health_changed)
		if _player.has_method("get_current_health") and _player.has_method("get_max_health"):
			_on_player_health_changed(_player.get_current_health(), _player.get_max_health())


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	var state_index := max_health - current_health
	var animation_name := "state_%d" % state_index

	if heart_display.animation == animation_name and heart_display.is_playing():
		return

	heart_display.play(animation_name)
