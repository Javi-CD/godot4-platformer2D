class_name HUD
extends CanvasLayer


signal previous_level_requested
signal restart_level_requested
signal next_level_requested


@onready var previous_button: TextureButton = get_node_or_null("NavigationContainer/HBoxContainer/PreviousButton")
@onready var restart_button: TextureButton = get_node_or_null("NavigationContainer/HBoxContainer/RestartButton")
@onready var next_button: TextureButton = get_node_or_null("NavigationContainer/HBoxContainer/NextButton")


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
