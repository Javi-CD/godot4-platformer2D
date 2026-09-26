class_name MainCamera
extends Camera2D

## Camera controller that manages global screen shake effects.

static var instance: MainCamera = null

var _shake_timer := 0.0
var _shake_intensity := 0.0


func _ready() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


static func shake(intensity: float = 3.5, duration: float = 0.15) -> void:
	if instance != null:
		instance.apply_shake(intensity, duration)


func apply_shake(intensity: float, duration: float) -> void:
	_shake_intensity = max(_shake_intensity, intensity)
	_shake_timer = max(_shake_timer, duration)


func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer = max(_shake_timer - delta, 0.0)
		offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		if _shake_timer <= 0.0:
			offset = Vector2.ZERO
