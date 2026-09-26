@tool
extends Area2D


signal collected(fruit_type: StringName)


enum FruitType {
	APPLE,
	BANANA,
	KIWI
}


@export var fruit_type: FruitType = FruitType.APPLE:
	set = set_fruit_type


@onready var fruit_sprite: AnimatedSprite2D = $FruitSprite
@onready var collect_effect_sprite: AnimatedSprite2D = $CollectEffectSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


var _is_collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collect_effect_sprite.visible = false
	_update_fruit_visual()

	if collect_effect_sprite.sprite_frames != null:
		collect_effect_sprite.animation_finished.connect(_on_collect_effect_finished)


func set_fruit_type(value: FruitType) -> void:
	fruit_type = value
	_update_fruit_visual()


func _update_fruit_visual() -> void:
	if not is_node_ready():
		return

	match fruit_type:
		FruitType.APPLE:
			fruit_sprite.play("apple")
		FruitType.BANANA:
			fruit_sprite.play("banana")
		FruitType.KIWI:
			fruit_sprite.play("kiwi")


func _on_body_entered(body: Node) -> void:
	if _is_collected:
		return

	if not body.is_in_group("player"):
		return

	_collect()


func _collect() -> void:
	_is_collected = true
	collision_shape.disabled = true

	fruit_sprite.visible = false
	collect_effect_sprite.visible = true
	collect_effect_sprite.play("collected")

	emit_signal("collected", _get_fruit_name())


func reset_fruit() -> void:
	_is_collected = false
	collision_shape.disabled = false

	collect_effect_sprite.visible = false
	fruit_sprite.visible = true
	_update_fruit_visual()


func _on_collect_effect_finished() -> void:
	if collect_effect_sprite.animation != "collected":
		return

	collect_effect_sprite.visible = false


func _get_fruit_name() -> StringName:
	match fruit_type:
		FruitType.APPLE:
			return &"apple"
		FruitType.BANANA:
			return &"banana"
		FruitType.KIWI:
			return &"kiwi"

	return &"unknown"
