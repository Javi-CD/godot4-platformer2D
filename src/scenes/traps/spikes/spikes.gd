@tool
extends Area2D


enum SpikeVariant {
	FOUR,
	SIX
}


@export var variant: SpikeVariant = SpikeVariant.FOUR:
	set = set_variant

@export_range(1, 10, 1) var damage := 1


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_4: CollisionShape2D = $Collision4
@onready var collision_6: CollisionShape2D = $Collision6


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_variant()


func set_variant(value: SpikeVariant) -> void:
	variant = value
	_update_variant()


func _update_variant() -> void:
	if not is_node_ready():
		return

	match variant:
		SpikeVariant.FOUR:
			animated_sprite.animation = "spikes_4"
			animated_sprite.frame = 0
			collision_4.disabled = false
			collision_6.disabled = true

		SpikeVariant.SIX:
			animated_sprite.animation = "spikes_6"
			animated_sprite.frame = 0
			collision_4.disabled = true
			collision_6.disabled = false


func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return

	body.take_damage(global_position, damage)
