# main.gd - Setup semplificato
extends Node

var wave_manager: Node

func _ready():
	_setup_managers()

func _setup_managers():
	# Altri manager se necessari
	var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	add_child(indicator_manager)
