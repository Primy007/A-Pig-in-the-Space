# wave_manager.gd - Sistema ondate con sequenza corretta
extends Node

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_completed()

# Stati del gioco
enum GameState {
	TUTORIAL,
	WAITING_FOR_WAVE,
	WAVE_ACTIVE,
	WAVE_COMPLETED,
	WAITING_FOR_FILE,
	READING_FILE,
	GAME_COMPLETED
}

var current_state: GameState = GameState.TUTORIAL
var current_wave: int = 0
var enemies_alive: int = 0
var enemy_scenes: Array = []
var player: Node

# Configurazione ondate [nemici, spawn_delay, messaggio_complimenti]
var waves_config: Array = [
	[3, 2.0, "Prima ondata superata! Ottimo inizio pilota!"],
	[5, 1.5, "Seconda ondata completata! Stai migliorando!"],
	[4, 1.0, "Terza ondata conclusa! Combattimento eccellente!"],
	[7, 1.0, "Quarta ondata terminata! Quasi alla fine!"],
	[6, 0.8, "Missione completata! Sei un vero asso!"]
]

# Spawn
var spawn_distance: float = 800.0
var spawn_timer: Timer

func _ready():
	add_to_group("wave_manager")
	player = get_tree().get_first_node_in_group("player")
	_setup_timer()
	_start_tutorial()

func _setup_timer():
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer)

# =============== API PUBBLICA ===============
func set_enemy_scenes(scenes: Array):
	enemy_scenes = scenes

func set_spawn_distance(distance: float):
	spawn_distance = distance

# =============== SEQUENZA PRINCIPALE ===============
func _start_tutorial():
	current_state = GameState.TUTORIAL
	_show_tutorial_message()
	
	# Dopo 4 secondi inizia la prima ondata
	await get_tree().create_timer(4.0).timeout
	_prepare_next_wave()

func _show_tutorial_message():
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		textbox.add_system_message("=== MISSIONE INIZIATA ===")
		textbox.add_dialogue("Pilota, preparati al combattimento!", textbox.SpeakerType.CAPTAIN)
		textbox.add_dialogue("Elimina tutti i nemici e raccogli i file dati.", textbox.SpeakerType.CAPTAIN)
		textbox.add_dialogue("Buona fortuna!", textbox.SpeakerType.CAPTAIN)

func _prepare_next_wave():
	if current_wave >= waves_config.size():
		_complete_all_waves()
		return
	
	current_state = GameState.WAITING_FOR_WAVE
	
	# Messaggio pre-ondata
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		textbox.add_system_message("Preparati... Ondata " + str(current_wave + 1) + " in arrivo!")
	
	# Attesa prima dell'ondata
	await get_tree().create_timer(2.0).timeout
	_start_wave()

func _start_wave():
	if current_wave >= waves_config.size():
		return
		
	current_state = GameState.WAVE_ACTIVE
	var config = waves_config[current_wave]
	var enemy_count = config[0]
	var spawn_delay = config[1]
	
	enemies_alive = 0
	wave_started.emit(current_wave + 1)
	
	print("[WaveManager] Iniziando ondata ", current_wave + 1, " con ", enemy_count, " nemici")
	
	# Inizia spawn nemici
	_spawn_enemies(enemy_count, spawn_delay)

func _spawn_enemies(count: int, delay: float):
	if enemy_scenes.is_empty():
		push_error("Nessuna scena nemico configurata!")
		return
	
	# Spawna primo nemico subito
	_spawn_single_enemy()
	count -= 1
	
	# Spawna gli altri con delay
	if count > 0:
		spawn_timer.wait_time = delay
		spawn_timer.set_meta("remaining_enemies", count)
		spawn_timer.set_meta("spawn_delay", delay)
		spawn_timer.start()

func _spawn_single_enemy():
	if not player or enemy_scenes.is_empty():
		return
	
	# Posizione casuale attorno al player (lontana)
	var angle = randf() * TAU
	var distance = spawn_distance + randf_range(-100, 200)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Crea nemico
	var enemy = enemy_scenes.pick_random().instantiate()
	enemy.global_position = spawn_pos
	
	# Connetti morte nemico
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_died)
	
	get_tree().current_scene.add_child(enemy)
	enemies_alive += 1
	
	print("[WaveManager] Nemico spawnato. Vivi: ", enemies_alive)

func _on_spawn_timer():
	var remaining = spawn_timer.get_meta("remaining_enemies", 0)
	var delay = spawn_timer.get_meta("spawn_delay", 1.0)
	
	_spawn_single_enemy()
	remaining -= 1
	
	if remaining > 0:
		spawn_timer.set_meta("remaining_enemies", remaining)
		spawn_timer.start()

func _on_enemy_died():
	enemies_alive -= 1
	print("[WaveManager] Nemico morto. Rimanenti: ", enemies_alive)
	
	if enemies_alive <= 0 and current_state == GameState.WAVE_ACTIVE:
		_wave_finished()

func _wave_finished():
	current_state = GameState.WAVE_COMPLETED
	var config = waves_config[current_wave]
	var congratulations = config[2]
	
	wave_completed.emit(current_wave + 1)
	
	# Messaggio di complimenti
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		textbox.add_dialogue(congratulations, textbox.SpeakerType.CAPTAIN)
	
	# Attesa poi spawna file
	await get_tree().create_timer(1.5).timeout
	_spawn_filetext()

func _spawn_filetext():
	current_state = GameState.WAITING_FOR_FILE
	
	if not player:
		return
	
	# Posizione lontana casuale
	var angle = randf() * TAU  
	var distance = spawn_distance * 0.7  # Un po' più vicino dei nemici
	var file_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Crea filetext
	var filetext = preload("res://scenes/filetext.tscn").instantiate()
	filetext.global_position = file_pos
	filetext.text_content = "Dati ondata " + str(current_wave + 1) + " acquisiti."
	
	# Connetti raccolta file
	filetext.file_collected.connect(_on_file_collected)
	
	get_tree().current_scene.add_child(filetext)
	
	print("[WaveManager] File spawned per ondata ", current_wave + 1)

func _on_file_collected(content: String):
	if current_state != GameState.WAITING_FOR_FILE:
		return
		
	current_state = GameState.READING_FILE
	print("[WaveManager] File raccolto: ", content)
	
	# Aspetta che finisca la lettura del textbox
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		# Aspetta che il textbox finisca tutti i dialoghi
		while textbox.is_displaying():
			await get_tree().process_frame
		
		# Attesa extra per essere sicuri
		await get_tree().create_timer(1.0).timeout
	
	# Passa all'ondata successiva
	current_wave += 1
	_prepare_next_wave()

func _complete_all_waves():
	current_state = GameState.GAME_COMPLETED
	all_waves_completed.emit()
	
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		textbox.add_system_message("=== MISSIONE COMPLETATA ===")
		textbox.add_dialogue("Eccezionale pilota! Tutte le ondate superate!", textbox.SpeakerType.CAPTAIN)
		textbox.add_dialogue("Il settore è ora sicuro grazie a te!", textbox.SpeakerType.CAPTAIN)
	
	print("[WaveManager] Tutte le ondate completate!")

# =============== UTILITY ===============
func get_current_wave() -> int:
	return current_wave + 1

func get_total_waves() -> int:
	return waves_config.size()

func get_enemies_alive() -> int:
	return enemies_alive

func get_current_state() -> GameState:
	return current_state

# Debug
func force_next_wave():
	_clear_all_enemies()
	current_wave += 1
	_prepare_next_wave()

func _clear_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	enemies_alive = 0
