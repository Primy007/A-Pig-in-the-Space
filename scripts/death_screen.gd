# death_screen.gd
extends Control

# --- REFERENCES ---
@onready var score_label = $VBoxContainer/ScoreLabel
@onready var restart_button = $VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button = $VBoxContainer/ButtonContainer/QuitButton
@onready var background = $Background

var game_manager: Node

func _ready():
	# Inizialmente nascosta
	visible = false
	
	# Connetti i bottoni
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Trova il GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	# Connetti al segnale di morte del player se il GameManager esiste
	if game_manager:
		game_manager.player_died.connect(show_death_screen)

func show_death_screen():
	# Mostra il punteggio finale
	var final_score = game_manager.get_current_score() if game_manager else 0
	score_label.text = "Final Score: " + str(final_score)
	
	# Pausa il gioco
	get_tree().paused = true
	
	# Mostra la schermata
	visible = true
	
	# Effetto di fade in
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func hide_death_screen():
	visible = false
	get_tree().paused = false

func _on_restart_pressed():
	hide_death_screen()
	
	# Reset del GameManager
	if game_manager:
		game_manager.reset_game()
	
	# Ricarica la scena principale
	get_tree().reload_current_scene()

func _on_quit_pressed():
	# Torna al menu principale o chiudi il gioco
	get_tree().quit()

# Gestisce l'input per evitare che i controlli del gioco funzionino quando la schermata è attiva
func _input(event):
	if visible:
		get_viewport().set_input_as_handled()