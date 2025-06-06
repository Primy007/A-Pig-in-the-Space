# main.gd - VERSIONE CORRETTA CON INDICATORI
extends Node

func _ready():
	print("Main scene ready")
	call_deferred("_setup_scene")
	$AudioStreamPlayer.play()

func _setup_scene():
	_setup_managers()
	_setup_ui()
	call_deferred("_start_game_when_ready")

func _setup_managers():
	# Aggiungi i manager degli indicatori
	_setup_indicator_managers()

func _setup_indicator_managers():
	# Manager per indicatori nemici
	var enemy_indicator_manager = preload("res://scenes/hud/enemy_indicator_manager.tscn")
	if enemy_indicator_manager:
		var enemy_manager_instance = enemy_indicator_manager.instantiate()
		add_child(enemy_manager_instance)
		print("Enemy indicator manager aggiunto")
	
	# Manager per indicatori file di testo
	var filetext_indicator_manager = preload("res://scenes/hud/filetext_indicator_manager.tscn")
	if filetext_indicator_manager:
		var filetext_manager_instance = filetext_indicator_manager.instantiate()
		add_child(filetext_manager_instance)
		print("Filetext indicator manager aggiunto")

func _setup_ui():
	var score_hud = preload("res://scenes/ui/score_hud.tscn").instantiate()
	add_child(score_hud)
	
	# AGGIUNGI QUESTA PARTE
	var wave_hud = preload("res://scenes/ui/wave_hud.tscn").instantiate()
	add_child(wave_hud)
	
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
