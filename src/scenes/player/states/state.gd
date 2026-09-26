class_name State
extends Node

## Base class for all states in the Finite State Machine (FSM).
## Each state manages its own lifecycle: enter, exit, input handling, and physics updates.

signal transitioned(state: State, new_state_name: StringName, msg: Dictionary)

var player: Player = null
var state_machine: StateMachine = null


func enter(_msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
