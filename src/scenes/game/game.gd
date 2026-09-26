class_name Game
extends Node


@export_file("*.tscn") var first_level_path: String


@onready var level_container: Node = $LevelContainer
@onready var hud: CanvasLayer = $HUD


var _current_level: Node2D = null


func _ready() -> void:
	load_level(first_level_path)


func load_level(level_path: String) -> void:
	if level_path.is_empty():
		push_warning("load_level recibió una ruta vacía.")
		return

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
