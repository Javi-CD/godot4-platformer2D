extends Node2D


signal level_completed(next_level_path: String)


@export_file("*.tscn") var next_level_path: String


@onready var player: Node = $Player
@onready var exit_flag: Node = $ExitFlag
@onready var collectables_container: Node = $Collectables


var _total_fruits := 0
var _collected_fruits := 0
var _is_completed := false
var _fruits: Array = []
var _is_waiting_for_player_exit := false


func _ready() -> void:
	_setup_fruits()
	_update_exit_state()

	if exit_flag.has_signal("player_entered"):
		exit_flag.player_entered.connect(_on_flag_entered)
	else:
		push_warning("ExitFlag no tiene la señal 'player_entered'")

	if player.has_signal("respawned"):
		player.respawned.connect(_on_player_respawned)
	else:
		push_warning("Player no tiene la señal 'respawned'")

	if player.has_signal("level_exit_finished"):
		player.level_exit_finished.connect(_on_player_level_exit_finished)
	else:
		push_warning("Player no tiene la señal 'level_exit_finished'")


func get_player() -> Node:
	return player


func _setup_fruits() -> void:
	_total_fruits = 0
	_collected_fruits = 0
	_fruits.clear()

	_fruits = _find_fruits(collectables_container)

	for fruit in _fruits:
		_total_fruits += 1
		fruit.collected.connect(_on_fruit_collected)


func _find_fruits(root: Node) -> Array:
	var fruits: Array = []

	for child in root.get_children():
		if child.has_signal("collected"):
			fruits.append(child)

		fruits.append_array(_find_fruits(child))

	return fruits


func _on_fruit_collected(_fruit_type: StringName) -> void:
	_collected_fruits += 1
	_update_exit_state()


func _update_exit_state() -> void:
	var all_fruits_collected := _collected_fruits >= _total_fruits and _total_fruits > 0

	if not exit_flag.has_method("set_unlocked"):
		return

	if not all_fruits_collected:
		exit_flag.set_unlocked(false)
		return

	var unlocked_animation: StringName = &"game"

	if next_level_path.is_empty():
		unlocked_animation = &"winner"

	exit_flag.set_unlocked(true, unlocked_animation)


func _on_flag_entered() -> void:
	if _is_completed:
		return

	if _collected_fruits < _total_fruits:
		return

	_is_completed = true
	_is_waiting_for_player_exit = true

	if player.has_method("start_level_exit"):
		player.start_level_exit()


func _on_player_level_exit_finished() -> void:
	if not _is_waiting_for_player_exit:
		return

	_is_waiting_for_player_exit = false

	if next_level_path.is_empty():
		print("Nivel final completado.")
		return

	emit_signal("level_completed", next_level_path)


func _on_player_respawned() -> void:
	_reset_level_collectables()
	_collected_fruits = 0
	_is_completed = false
	_is_waiting_for_player_exit = false
	_update_exit_state()


func _reset_level_collectables() -> void:
	for fruit in _fruits:
		if fruit.has_method("reset_fruit"):
			fruit.reset_fruit()
