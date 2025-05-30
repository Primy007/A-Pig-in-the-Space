# main.gd - VERSIONE CORRETTA
extends Node

func _ready():
	print("Main scene ready")
	
	# Assicurati che tutto sia pronto prima di inizializzare
	call_deferred("_setup_scene")

func _setup_scene():
	_setup_managers()
	_setup_ui()
	
	# Avvia il gioco dopo che tutto è stato configurato
	call_deferred("_start_game_when_ready")

func _setup_managers():
	# Altri manager se necessari (es. indicator_manager)
	var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	add_child(indicator_manager)

func _setup_ui():
	# Aggiungi l'HUD del punteggio
	var score_hud = preload("res://scenes/UI/score_hud.tscn").instantiate()
	add_child(score_hud)
	
	# Aggiungi la schermata di morte COME ULTIMO ELEMENTO
	var death_screen = preload("res://scenes/ui/death_screen.tscn").instantiate()
	add_child(death_screen)
	
	print("UI configurata")

func _start_game_when_ready():
	# Assicurati che il player sia nel gruppo
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player trovato, avviando il gioco...")
		# Il GameManager è ora un autoload, quindi è sempre disponibile
		GameManager.start_game()
	else:
		print("Player non trovato, riprovando...")
		# Riprova tra un frame
		call_deferred("_start_game_when_ready")
