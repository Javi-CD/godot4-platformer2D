class_name WinnerText
extends Node2D


@export var spacing: float = 10.0
@export var wave_amplitude: float = 4.0
@export var wave_frequency: float = 4.0
@export var wave_offset: float = 0.5
@export var text_scale: Vector2 = Vector2(2.5, 2.5)

@onready var letters_container: Node2D = $LettersContainer

var _time: float = 0.0
var _letter_nodes: Array[Sprite2D] = []
var _base_positions: Array[Vector2] = []

const LETTER_REGIONS: Dictionary = {
	"W": Rect2(16, 20, 8, 10),
	"I": Rect2(64, 0, 8, 10),
	"N": Rect2(24, 10, 8, 10),
	"E": Rect2(32, 0, 8, 10),
	"R": Rect2(56, 10, 8, 10),
}


func _ready() -> void:
	scale = text_scale
	_setup_letters()


func _setup_letters() -> void:
	_letter_nodes.clear()
	_base_positions.clear()

	if letters_container == null:
		return

	for child in letters_container.get_children():
		if child is Sprite2D:
			_letter_nodes.append(child)

	var count: int = _letter_nodes.size()
	if count == 0:
		return

	var total_width: float = (count - 1) * spacing
	var start_x: float = - total_width / 2.0

	for i in range(count):
		var letter_sprite: Sprite2D = _letter_nodes[i]
		var char_name: String = _extract_char_from_name(letter_sprite.name)

		if not (letter_sprite.texture is AtlasTexture):
			if LETTER_REGIONS.has(char_name):
				letter_sprite.region_enabled = true
				letter_sprite.region_rect = LETTER_REGIONS[char_name]
		else:
			letter_sprite.region_enabled = false

		var base_pos := Vector2(start_x + i * spacing, 0.0)
		letter_sprite.position = base_pos
		_base_positions.append(base_pos)


func _extract_char_from_name(node_name: String) -> String:
	var parts := node_name.split("_")
	if parts.size() > 1:
		var raw_char: String = parts[1]
		if raw_char.length() > 0:
			return raw_char.left(1).to_upper()
	return ""


func _process(delta: float) -> void:
	_time += delta
	var count: int = _letter_nodes.size()
	for i in range(count):
		var base_pos: Vector2 = _base_positions[i]
		var y_offset: float = sin(_time * wave_frequency + i * wave_offset) * wave_amplitude
		_letter_nodes[i].position = Vector2(base_pos.x, base_pos.y + y_offset)
