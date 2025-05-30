# main.gd - VERSIONE CORRETTA
extends Node

func _ready():
	print("Main scene ready")
	call_deferred("_setup_scene")

func _setup_scene():
	_setup_managers()
	_setup_ui()
	call_deferred("_start_game_when_ready")

func _setup_managers():
	# RIMUOVI QUESTA RIGA - GameManager deve essere autoload
	# var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	# add_child(indicator_manager)
	pass

func _setup_ui():
	var score_hud = preload("res://scenes/ui/score_hud.tscn").instantiate()
	add_child(score_hud)
	
	var death_screen = preload("res://scenes/ui/death_screen.tscn").instantiate()
	add_child(death_screen)
	
	print("UI configurata")

func _start_game_when_ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player trovato, avviando il gioco...")
		GameManager.start_game()  # Usa l'autoload
	else:
		print("Player non trovato, riprovando...")
		call_deferred("_start_game_when_ready")
