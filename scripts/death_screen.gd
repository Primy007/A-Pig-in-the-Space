# death_screen.gd - VERSIONE CORRETTA
extends CanvasLayer

# --- REFERENCES ---
@onready var score_label = $Control/VBoxContainer/ScoreLabel
@onready var restart_button = $Control/VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button = $Control/VBoxContainer/ButtonContainer/QuitButton
@onready var background = $Control/Background
@onready var control_container = $Control

var game_manager: Node

func _ready():
	# Inizialmente nascosta
	visible = false
	
	# Assicurati che il CanvasLayer sia sopra tutto
	layer = 100
	
	# IMPORTANTE: Imposta il process mode per funzionare anche in pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Imposta anche tutti i nodi figli per funzionare in pausa
	_set_children_process_mode_always(self)
	
	# Connetti i bottoni
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Trova il GameManager (dovrebbe essere un autoload)
	call_deferred("_setup_game_manager")

func _set_children_process_mode_always(node: Node):
	"""Imposta ricorsivamente il process mode di tutti i figli"""
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_children_process_mode_always(child)

func _setup_game_manager():
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	if game_manager:
		# Connetti al segnale di morte del player
		if not game_manager.player_died.is_connected(show_death_screen):
			game_manager.player_died.connect(show_death_screen)
		print("Death screen connesso al GameManager")
	else:
		print("ERRORE: GameManager non trovato come autoload!")

func show_death_screen():
	print("Mostrando schermata di morte")
	
	# Mostra il punteggio finale
	var final_score = game_manager.get_current_score() if game_manager else 0
	if score_label:
		score_label.text = "Final Score: " + str(final_score)
	
	# Mostra la schermata
	visible = true
	
	# Pausa il gioco
	get_tree().paused = true
	
	# Assicurati che i bottoni siano focusabili
	if restart_button:
		restart_button.grab_focus()
	
	print("Schermata di morte mostrata, gioco in pausa")

func hide_death_screen():
	print("Nascondendo schermata di morte")
	visible = false
	get_tree().paused = false

func _on_restart_pressed():
	print("Restart premuto")
	
	# Prima togli la pausa
	get_tree().paused = false
	
	# Nascondi la schermata
	visible = false
	
	# Reset del GameManager
	if game_manager:
		game_manager.reset_game()
	
	# Ricarica la scena principale
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quit premuto")
	
	# Prima togli la pausa
	get_tree().paused = false
	
	# Chiudi il gioco
	get_tree().quit()

# Gestisce l'input per evitare che i controlli del gioco funzionino quando la schermata è attiva
func _input(event):
	if visible and event is InputEvent:
		# Blocca gli input quando la schermata è visibile
		get_viewport().set_input_as_handled()

# Input per test
func _unhandled_input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
