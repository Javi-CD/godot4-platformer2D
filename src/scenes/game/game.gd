class_name Game
extends Node


@export_file("*.tscn") var first_level_path: String
@export var level_sequence: Array[PackedScene] = []


@onready var level_container: Node = $LevelContainer
@onready var hud: CanvasLayer = $HUD


var _current_level: Node2D = null
var _current_level_path: String = ""
var _previous_level_path: String = ""
var _current_level_index: int = -1


func _ready() -> void:
	_connect_hud_signals()
	load_level(first_level_path)


func _connect_hud_signals() -> void:
	if hud == null:
		return

	if hud.has_signal("previous_level_requested"):
		hud.previous_level_requested.connect(_on_previous_level_requested)
	if hud.has_signal("restart_level_requested"):
		hud.restart_level_requested.connect(_on_restart_level_requested)
	if hud.has_signal("next_level_requested"):
		hud.next_level_requested.connect(_on_next_level_requested)


func load_level(level_path: String) -> void:
	if level_path.is_empty():
		push_warning("load_level recibió una ruta vacía.")
		return

	if _current_level_path != level_path:
		_previous_level_path = _current_level_path

	_current_level_path = level_path
	_update_current_level_index()

	if _current_level != null:
		_current_level.queue_free()
		_current_level = null

	var level_scene := load(level_path) as PackedScene
	if level_scene == null:
		push_warning("No se pudo cargar la escena: " + level_path)
		return

	var instantiated := level_scene.instantiate() as Node2D
	if instantiated == null:
		push_warning("La escena cargada no se pudo instanciar correctamente: " + level_path)
		return

	_current_level = instantiated
	level_container.add_child(_current_level)

	if _current_level.has_signal("level_completed"):
		_current_level.level_completed.connect(_on_level_completed)

	_assign_level_player_to_hud()
	_start_player_level_spawn()


func _update_current_level_index() -> void:
	_current_level_index = -1
	for i in range(level_sequence.size()):
		if level_sequence[i] != null and level_sequence[i].resource_path == _current_level_path:
			_current_level_index = i
			break


func _assign_level_player_to_hud() -> void:
	if _current_level == null:
		if hud.has_method("set_player"):
			hud.set_player(null)
		return

	var player: Node = null
	if _current_level.has_method("get_player"):
		player = _current_level.get_player()
	else:
		player = _current_level.get_node_or_null("Player")

	if hud.has_method("set_player"):
		hud.set_player(player)


func _start_player_level_spawn() -> void:
	if _current_level == null:
		return

	var player: Node = null
	if _current_level.has_method("get_player"):
		player = _current_level.get_player()
	else:
		player = _current_level.get_node_or_null("Player")

	if player != null and player.has_method("start_level_spawn"):
		player.start_level_spawn()


func _on_level_completed(next_level_path: String) -> void:
	load_level(next_level_path)


func _on_restart_level_requested() -> void:
	if not _current_level_path.is_empty():
		load_level(_current_level_path)


func _on_previous_level_requested() -> void:
	if _current_level_index > 0 and _current_level_index < level_sequence.size():
		var prev_scene := level_sequence[_current_level_index - 1]
		if prev_scene != null:
			load_level(prev_scene.resource_path)
			return

	if not _previous_level_path.is_empty():
		load_level(_previous_level_path)


func _on_next_level_requested() -> void:
	if _current_level_index >= 0 and _current_level_index < level_sequence.size() - 1:
		var next_scene := level_sequence[_current_level_index + 1]
		if next_scene != null:
			load_level(next_scene.resource_path)
			return

	if _current_level != null and "next_level_path" in _current_level:
		var next_path: String = _current_level.next_level_path
		if not next_path.is_empty():
			load_level(next_path)
