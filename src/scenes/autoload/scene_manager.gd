extends CanvasLayer


@onready var animation: AnimationPlayer = $TransitionAnimation

var player: Player = null
var last_scene_name: String = ""
var scene_dir_path: String = "res://src/scenes/"


func play_transition(on_middle_action: Callable = Callable()) -> void:
	if animation != null and animation.has_animation("transition_out"):
		animation.play("transition_out")
		await animation.animation_finished

	if on_middle_action.is_valid():
		on_middle_action.call()

	if animation != null and animation.has_animation("transition_out"):
		animation.play_backwards("transition_out")
		await animation.animation_finished


func change_scene(from: Node, to_scene_name: String) -> void:
	if from != null:
		last_scene_name = from.name
		if "player" in from and from.player != null:
			player = from.player
			if player.get_parent() != null:
				player.get_parent().remove_child(player)

	var full_path: String = ""
	if to_scene_name.begins_with("res://"):
		full_path = to_scene_name
	elif not to_scene_name.ends_with(".tscn"):
		full_path = scene_dir_path + to_scene_name + ".tscn"
	else:
		full_path = scene_dir_path + to_scene_name

	await change_scene_to_file(full_path)


func change_scene_to_file(target_path: String) -> void:
	if target_path.is_empty():
		push_warning("SceneManager: target_path está vacía.")
		return

	await play_transition(func(): get_tree().change_scene_to_file(target_path))
