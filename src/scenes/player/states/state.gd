class_name State
extends Node

## Base class for all states in the Finite State Machine (FSM).

@warning_ignore("unused_signal")
signal transitioned(state: State, new_state_name: StringName, msg: Dictionary)

var player: CharacterBody2D = null
var state_machine: Node = null


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
