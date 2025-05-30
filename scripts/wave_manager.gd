# wave_manager.gd - Sistema di gestione delle ondate di nemici
extends Node

# Segnali
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal enemy_spawned(enemy)

# Configurazione delle ondate
@export var wave_configurations: Array[WaveConfig] = []
@export var spawn_points: Array[Marker2D] = []
@export var enemy_scenes: Array[PackedScene] = []

# Stato corrente
var current_wave: int = 0
var enemies_alive: int = 0
var wave_active: bool = false
var waiting_for_filetext: bool = false
var spawn_timer: Timer

# Riferimenti
@onready var player = get_tree().get_first_node_in_group("player")

# Classe per configurare le ondate
class WaveConfig:
	var wave_number: int
	var enemy_count: int
	var enemy_types: Array[int] = []  # Indici degli enemy_scenes
	var spawn_delay: float = 1.0  # Tempo tra uno spawn e l'altro
	var simultaneous_spawns: int = 1  # Quanti nemici spawnare insieme
	var filetext_content: String = ""  # Contenuto del file di testo per questa ondata
	
	func _init(p_wave: int, p_count: int, p_types: Array[int], p_delay: float = 1.0, 
			   p_simultaneous: int = 1, p_filetext: String = ""):
		wave_number = p_wave
		enemy_count = p_count
		enemy_types = p_types
		spawn_delay = p_delay
		simultaneous_spawns = p_simultaneous
		filetext_content = p_filetext

func _ready():
	_setup_wave_manager()
	_setup_default_waves()
	_connect_signals()

func _setup_wave_manager():
	"""Configura il wave manager"""
	add_to_group("wave_manager")
	
	# Crea il timer per lo spawn
	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	print("[WaveManager] Sistema inizializzato")

func _setup_default_waves():
	"""Configura le ondate predefinite (da personalizzare)"""
	if wave_configurations.is_empty():
		wave_configurations = [
			WaveConfig.new(1, 3, [0], 2.0, 1, "Prima ondata completata! Preparati per la prossima."),
			WaveConfig.new(2, 5, [0], 1.5, 1, "Seconda ondata superata! I nemici stanno diventando più numerosi."),
			WaveConfig.new(3, 4, [0], 1.0, 2, "Terza ondata conclusa! Ottimo lavoro pilota!"),
			WaveConfig.new(4, 8, [0], 1.0, 2, "Quarta ondata completata! Siamo quasi alla fine."),
			WaveConfig.new(5, 6, [0], 0.8, 3, "Tutte le ondate completate! Missione riuscita!")
		]

func _connect_signals():
	"""Connette i segnali necessari"""
	# Connetti ai file di testo quando vengono raccolti
	_connect_to_filetexts()

func _connect_to_filetexts():
	"""Connette ai file di testo esistenti"""
	var filetexts = get_tree().get_nodes_in_group("filetext")
	for filetext in filetexts:
		if filetext.has_signal("file_collected"):
			if not filetext.file_collected.is_connected(_on_filetext_collected):
				filetext.file_collected.connect(_on_filetext_collected)

# =============================================================================
# FUNZIONI PUBBLICHE
# =============================================================================

func start_wave_system():
	"""Inizia il sistema delle ondate"""
	if wave_configurations.is_empty():
		print("[WaveManager] Errore: Nessuna configurazione ondata trovata")
		return
	
	current_wave = 0
	_start_next_wave()

func force_next_wave():
	"""Forza l'inizio della prossima ondata (per testing)"""
	_clear_all_enemies()
	_start_next_wave()

func get_current_wave() -> int:
	"""Ritorna il numero dell'ondata corrente"""
	return current_wave + 1

func get_total_waves() -> int:
	"""Ritorna il numero totale di ondate"""
	return wave_configurations.size()

func get_enemies_alive() -> int:
	"""Ritorna il numero di nemici ancora vivi"""
	return enemies_alive

func is_wave_active() -> bool:
	"""Controlla se c'è un'ondata attiva"""
	return wave_active

# =============================================================================
# FUNZIONI INTERNE - Gestione ondate
# =============================================================================

func _start_next_wave():
	"""Inizia la prossima ondata"""
	if current_wave >= wave_configurations.size():
		_complete_all_waves()
		return
	
	var wave_config = wave_configurations[current_wave]
	wave_active = true
	waiting_for_filetext = false
	
	print("[WaveManager] Iniziando ondata ", wave_config.wave_number)
	
	# Notifica l'inizio dell'ondata
	wave_started.emit(wave_config.wave_number)
	
	# Mostra dialogo di inizio ondata
	_show_wave_start_dialogue(wave_config)
	
	# Inizia lo spawn dei nemici
	_spawn_wave_enemies(wave_config)

func _spawn_wave_enemies(wave_config: WaveConfig):
	"""Spawna i nemici per l'ondata corrente"""
	var enemies_to_spawn = wave_config.enemy_count
	var spawn_delay = wave_config.spawn_delay
	
	_spawn_enemies_batch(wave_config, enemies_to_spawn, spawn_delay)

func _spawn_enemies_batch(wave_config: WaveConfig, remaining_enemies: int, delay: float):
	"""Spawna un batch di nemici"""
	if remaining_enemies <= 0:
		return
	
	# Spawna nemici simultanei
	var to_spawn_now = min(wave_config.simultaneous_spawns, remaining_enemies)
	
	for i in range(to_spawn_now):
		_spawn_single_enemy(wave_config)
	
	remaining_enemies -= to_spawn_now
	
	# Se ci sono altri nemici da spawnare, programma il prossimo batch
	if remaining_enemies > 0:
		spawn_timer.wait_time = delay
		spawn_timer.timeout.connect(_spawn_enemies_batch.bind(wave_config, remaining_enemies, delay), CONNECT_ONE_SHOT)
		spawn_timer.start()

func _spawn_single_enemy(wave_config: WaveConfig):
	"""Spawna un singolo nemico"""
	if enemy_scenes.is_empty() or spawn_points.is_empty():
		print("[WaveManager] Errore: Mancano scene nemici o punti di spawn")
		return
	
	# Scegli tipo di nemico casuale dalla configurazione
	var enemy_type_index = wave_config.enemy_types.pick_random()
	if enemy_type_index >= enemy_scenes.size():
		enemy_type_index = 0
	
	# Scegli punto di spawn casuale
	var spawn_point = spawn_points.pick_random()
	
	# Crea il nemico
	var enemy = enemy_scenes[enemy_type_index].instantiate()
	enemy.global_position = spawn_point.global_position
	
	# Connetti alla morte del nemico
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	
	# Aggiungi alla scena
	get_tree().current_scene.add_child(enemy)
	
	enemies_alive += 1
	enemy_spawned.emit(enemy)
	
	print("[WaveManager] Nemico spawnato. Nemici vivi: ", enemies_alive)

func _complete_current_wave():
	"""Completa l'ondata corrente"""
	if not wave_active:
		return
	
	wave_active = false
	waiting_for_filetext = true
	
	var wave_config = wave_configurations[current_wave]
	
	print("[WaveManager] Ondata ", wave_config.wave_number, " completata")
	wave_completed.emit(wave_config.wave_number)
	
	# Spawna il file di testo per questa ondata
	_spawn_filetext_for_wave(wave_config)
	
	# Mostra dialogo di completamento ondata
	_show_wave_complete_dialogue(wave_config)

func _complete_all_waves():
	"""Completa tutte le ondate"""
	wave_active = false
	waiting_for_filetext = false
	
	print("[WaveManager] Tutte le ondate completate!")
	all_waves_completed.emit()
	
	# Mostra dialogo finale
	var dialogue_manager = get_node("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.start_mission_complete_dialogue()

# =============================================================================
# SPAWN FILE DI TESTO
# =============================================================================

func _spawn_filetext_for_wave(wave_config: WaveConfig):
	"""Spawna un file di testo per l'ondata completata"""
	var filetext_scene = preload("res://scenes/filetext.tscn")  # Modifica il path
	var filetext = filetext_scene.instantiate()
	
	# Imposta il contenuto del file
	filetext.text_content = wave_config.filetext_content
	
	# Posiziona il file vicino al player (ma non troppo vicino)
	if player:
		var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
		filetext.global_position = player.global_position + offset
	
	# Connetti il segnale
	if not filetext.file_collected.is_connected(_on_filetext_collected):
		filetext.file_collected.connect(_on_filetext_collected)
	
	get_tree().current_scene.add_child(filetext)
	print("[WaveManager] File di testo spawnato per ondata ", wave_config.wave_number)

# =============================================================================
# DIALOGHI
# =============================================================================

func _show_wave_start_dialogue(wave_config: WaveConfig):
	"""Mostra il dialogo di inizio ondata"""
	var dialogue_manager = get_node("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.start_enemy_encounter_dialogue()
		
		# Messaggio specifico per l'ondata
		var textbox = get_tree().get_first_node_in_group("textbox")
		if textbox:
			textbox.add_system_message("Ondata " + str(wave_config.wave_number) + " iniziata!")

func _show_wave_complete_dialogue(wave_config: WaveConfig):
	"""Mostra il dialogo di completamento ondata"""
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		textbox.add_system_message("Ondata " + str(wave_config.wave_number) + " completata!")
		textbox.add_dialogue("Cerca il file di dati per procedere all'ondata successiva.", textbox.SpeakerType.CAPTAIN)

# =============================================================================
# CALLBACK E GESTIONE EVENTI
# =============================================================================

func _on_enemy_died(enemy):
	"""Chiamata quando un nemico muore"""
	enemies_alive -= 1
	print("[WaveManager] Nemico morto. Nemici rimanenti: ", enemies_alive)
	
	# Se non ci sono più nemici, completa l'ondata
	if enemies_alive <= 0 and wave_active:
		_complete_current_wave()

func _on_filetext_collected(content: String):
	"""Chiamata quando un file di testo viene raccolto"""
	if waiting_for_filetext:
		print("[WaveManager] File di testo raccolto, avanzando alla prossima ondata")
		current_wave += 1
		
		# Piccolo delay prima di iniziare la prossima ondata
		await get_tree().create_timer(2.0).timeout
		_start_next_wave()

func _on_spawn_timer_timeout():
	"""Callback del timer di spawn"""
	# Gestito tramite bind nel timer
	pass

# =============================================================================
# UTILITY
# =============================================================================

func _clear_all_enemies():
	"""Rimuove tutti i nemici dalla scena"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	enemies_alive = 0

func add_spawn_point(position: Vector2):
	"""Aggiunge un punto di spawn"""
	var marker = Marker2D.new()
	marker.global_position = position
	add_child(marker)
	spawn_points.append(marker)

func setup_spawn_points_around_player(radius: float = 1000.0, count: int = 8):
	"""Crea punti di spawn in cerchio attorno all'area di gioco"""
	spawn_points.clear()
	
	for i in range(count):
		var angle = (2.0 * PI * i) / count
		var pos = Vector2(cos(angle), sin(angle)) * radius
		add_spawn_point(pos)
	
	print("[WaveManager] Creati ", count, " punti di spawn")

# =============================================================================
# FUNZIONI DI DEBUG
# =============================================================================

func debug_print_wave_info():
	"""Stampa informazioni di debug sulle ondate"""
	print("[WaveManager] === INFO ONDATE ===")
	print("Ondata corrente: ", current_wave + 1, "/", wave_configurations.size())
	print("Nemici vivi: ", enemies_alive)
	print("Ondata attiva: ", wave_active)
	print("In attesa di file: ", waiting_for_filetext)
