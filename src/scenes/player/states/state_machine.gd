class_name StateMachine
extends Node

## Generic Finite State Machine that manages child State nodes.

signal state_changed(previous_state_name: StringName, new_state_name: StringName)

@export var initial_state: State

var current_state: State = null
var states: Dictionary = {}


func init(target_player: CharacterBody2D) -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = target_player
			child.state_machine = self
			if not child.transitioned.is_connected(_on_child_transitioned):
				child.transitioned.connect(_on_child_transitioned)

	if initial_state != null:
		current_state = initial_state
		current_state.enter()


func handle_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.handle_input(event)


func update(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func transition_to(target_state_name: StringName, msg: Dictionary = {}) -> void:
	var key := target_state_name.to_lower()
	if not states.has(key):
		push_warning("StateMachine: Attempted to transition to non-existent state '%s'" % target_state_name)
		return

	var previous_state_name: StringName = StringName(current_state.name) if current_state != null else &""

	if current_state != null:
		current_state.exit()

	current_state = states[key] as State
	current_state.enter(msg)

	emit_signal("state_changed", previous_state_name, StringName(current_state.name))


func _on_child_transitioned(state: State, new_state_name: StringName, msg: Dictionary) -> void:
	if state != current_state:
		return

	transition_to(new_state_name, msg)
