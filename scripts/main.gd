# main.gd - Script principale aggiornato con il sistema di ondate
extends Node

@onready var wave_manager: Node

func _ready() -> void:
	_setup_managers()
	_setup_wave_system()
	_start_game()

func _setup_managers():
	"""Configura tutti i manager del gioco"""
	# Aggiungi il manager per gli indicatori dei nemici
	var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	add_child(indicator_manager)
	
	# Aggiungi il manager per gli indicatori dei file di testo
	var filetext_indicator_manager = preload("res://scenes/HUD/filetext_indicator_manager.tscn").instantiate()
	add_child(filetext_indicator_manager)
	
	# Aggiungi il Wave Manager
	wave_manager = preload("res://scripts/wave_manager.gd").new()
	add_child(wave_manager)

func _setup_wave_system():
	"""Configura il sistema delle ondate"""
	if wave_manager:
		# Configura le scene dei nemici (modifica i path secondo la tua struttura)
		wave_manager.enemy_scenes = [
			preload("res://scenes/enemy_fly.tscn")  # Aggiungi altre scene nemici qui
		]
		
		# Crea punti di spawn attorno all'area di gioco
		wave_manager.setup_spawn_points_around_player(1200.0, 8)
		
		# Connetti i segnali del wave manager
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_completed.connect(_on_wave_completed)
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)
		
		print("[Main] Sistema ondate configurato")

func _start_game():
	"""Inizia il gioco"""
	# Dialogo di introduzione
	var dialogue_manager = get_node("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.start_intro_dialogue()
	
	# Attendi un po' prima di iniziare le ondate per permettere al giocatore di leggere l'intro
	await get_tree().create_timer(3.0).timeout
	
	# Inizia il sistema delle ondate
	if wave_manager:
		wave_manager.start_wave_system()

# =============================================================================
# CALLBACK DEGLI EVENTI DELLE ONDATE
# =============================================================================

func _on_wave_started(wave_number: int):
	"""Chiamata quando inizia una nuova ondata"""
	print("[Main] Ondata ", wave_number, " iniziata")
	
	# Puoi aggiungere effetti speciali, musica, ecc.
	_update_ui_for_wave(wave_number)

func _on_wave_completed(wave_number: int):
	"""Chiamata quando un'ondata viene completata"""
	print("[Main] Ondata ", wave_number, " completata")
	
	# Puoi aggiungere effetti di completamento, suoni, ecc.

func _on_all_waves_completed():
	"""Chiamata quando tutte le ondate sono completate"""
	print("[Main] Tutte le ondate completate! Gioco finito!")
	
	# Qui puoi gestire la fine del gioco, salvare punteggi, ecc.
	_handle_game_completion()

# =============================================================================
# GESTIONE UI E FEEDBACK
# =============================================================================

func _update_ui_for_wave(wave_number: int):
	"""Aggiorna l'UI per la nuova ondata"""
	# Esempio: puoi mostrare il numero dell'ondata nell'HUD
	var hud_label = get_tree().get_first_node_in_group("wave_counter")
	if hud_label:
		hud_label.text = "Ondata: " + str(wave_number) + "/" + str(wave_manager.get_total_waves())

func _handle_game_completion():
	"""Gestisce il completamento del gioco"""
	# Ferma la musica di combattimento, avvia musica di vittoria
	# Mostra schermata di vittoria
	# Salva statistiche, ecc.
	
	# Esempio: riavvia il gioco dopo un delay
	await get_tree().create_timer(5.0).timeout
	get_tree().reload_current_scene()

# =============================================================================
# FUNZIONI DI DEBUG (opzionali)
# =============================================================================

func _input(event):
	"""Gestisce input di debug"""
	if OS.is_debug_build():
		if event.is_action_pressed("debug_next_wave"):  # Definisci questo input nella mappa
			if wave_manager:
				wave_manager.force_next_wave()
		
		if event.is_action_pressed("debug_wave_info"):  # Definisci questo input nella mappa	
			if wave_manager:
				wave_manager.debug_print_wave_info()

func _process(delta: float) -> void:
	# Debug info (rimuovi in produzione)
	if OS.is_debug_build() and wave_manager:
		_update_debug_display()

func _update_debug_display():
	"""Aggiorna il display di debug"""
	# Potresti mostrare info nell'HUD per il debug
	pass
