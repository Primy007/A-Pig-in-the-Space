# main.gd - VERSIONE AGGIORNATA
extends Node

var wave_manager: Node
var game_manager: Node

func _ready():
	_setup_managers()
	_setup_ui()

func _setup_managers():
	# Altri manager se necessari
	var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	add_child(indicator_manager)

func _setup_ui():
	# Aggiungi l'HUD del punteggio
	var score_hud = preload("res://scenes/UI/score_hud.tscn").instantiate()
	add_child(score_hud)
	
	# Aggiungi la schermata di morte
	var death_screen = preload("res://scenes/ui/death_screen.tscn").instantiate()
	add_child(death_screen)
