# game_manager.gd - VERSIONE OTTIMIZZATA E BILANCIATA
extends Node

func _init():
	print("GameManager autoload inizializzato")
	name = "GameManager"

# --- SPAWN SETTINGS ---
@export var enemy_scene: PackedScene
@export var min_spawn_distance: float = 1200.0  # Aumentato per spawn più lontano
@export var max_spawn_distance: float = 2000.0  # Molto più lontano
@export var spawn_margin: float = 200.0

# --- WAVE SYSTEM BILANCIATO ---
var current_wave: int = 1
var enemies_in_current_wave: int = 0
var enemies_spawned_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var wave_active: bool = false
var wave_preparation_time: float = 3.0

# Configurazione progressive BILANCIATE delle ondate
var base_enemies_per_wave: int = 3
var enemies_increase_per_wave: int = 1  # Ridotto da 2 a 1 per progressione graduale
var max_concurrent_enemies: int = 8     # Ridotto per migliori performance
var spawn_interval_base: float = 1.5    # Aumentato leggermente
var spawn_interval_reduction: float = 0.03  # Ridotta per evitare spawn troppo rapido

# --- SCORE SYSTEM ---
var current_score: int = 0
var points_per_enemy: int = 100
var wave_completion_bonus: int = 500

# --- GAME STATE ---
var game_active: bool = false

# --- REFERENCES ---
var spawn_timer: Timer
var wave_timer: Timer
var player: CharacterBody2D
var score_label: Label
var wave_label: Label

# --- SIGNALS ---
signal score_changed(new_score: int)
signal player_died
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

func _ready():
	print("GameManager ready (Autoload)")
	
	# Carica la scena del nemico
	if not enemy_scene:
		var enemy_path = "res://scenes/enemy_fly.tscn"
		if ResourceLoader.exists(enemy_path):
			enemy_scene = load(enemy_path)
			print("Enemy scene caricata: ", enemy_scene != null)
		else:
			print("ERRORE: File enemy_fly.tscn non trovato in ", enemy_path)
	
	_setup_timers()
	_connect_signals()
	call_deferred("_delayed_start")

func _delayed_start():
	print("GameManager _delayed_start chiamato")
	if get_tree() and get_tree().current_scene:
		print("Scena corrente disponibile: ", get_tree().current_scene.name)
	else:
		print("ERRORE: Scena corrente non disponibile")

func _setup_timers():
	# Timer per spawn nemici
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.autostart = false
	add_child(spawn_timer)
	
	# Timer per preparazione ondata
	wave_timer = Timer.new()
	wave_timer.timeout.connect(_start_next_wave)
	wave_timer.autostart = false
	add_child(wave_timer)

func _connect_signals():
	score_changed.connect(_on_score_changed)
	wave_started.connect(_on_wave_started)
	wave_completed.connect(_on_wave_completed)

func start_game():
	print("Avviando il gioco")
	game_active = true
	current_score = 0
	current_wave = 1
	enemies_killed_this_wave = 0
	enemies_spawned_this_wave = 0
	
	score_changed.emit(current_score)
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERRORE: Player non trovato nel gruppo 'player'!")
		return
	
	print("Player trovato: ", player.name)
	_start_wave(current_wave)

func stop_game():
	print("Fermando il gioco")
	game_active = false
	wave_active = false
	if spawn_timer:
		spawn_timer.stop()
	if wave_timer:
		wave_timer.stop()

func _start_wave(wave_number: int):
	print("Iniziando ondata ", wave_number)
	current_wave = wave_number
	wave_active = true
	enemies_spawned_this_wave = 0
	enemies_killed_this_wave = 0
	
	# FORMULA BILANCIATA: progressione graduale
	# Ondata 1: 3, Ondata 2: 4, Ondata 3: 5, ecc.
	enemies_in_current_wave = base_enemies_per_wave + (enemies_increase_per_wave * (wave_number - 1))
	enemies_in_current_wave = min(enemies_in_current_wave, max_concurrent_enemies)
	
	# Calcola intervallo di spawn per questa ondata
	var current_spawn_interval = spawn_interval_base - (spawn_interval_reduction * (wave_number - 1))
	current_spawn_interval = max(current_spawn_interval, 0.5)  # Minimo 0.5 secondi per evitare spam
	
	spawn_timer.wait_time = current_spawn_interval
	spawn_timer.start()
	
	wave_started.emit(wave_number)
	print("Ondata ", wave_number, " - Nemici: ", enemies_in_current_wave, " - Intervallo: ", current_spawn_interval)

func _spawn_enemy():
	if not game_active or not wave_active:
		spawn_timer.stop()
		return
		
	# CONTROLLO FISSO: Se abbiamo spawnato tutti i nemici dell'ondata, ferma il timer
	if enemies_spawned_this_wave >= enemies_in_current_wave:
		spawn_timer.stop()
		print("Spawn completato per ondata ", current_wave, ": ", enemies_spawned_this_wave, "/", enemies_in_current_wave)
		return
	
	# Controllo nemici vivi per performance
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_concurrent_enemies:
		print("Troppi nemici vivi (", current_enemies.size(), "), aspettando...")
		return
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("Player non trovato per spawn nemico")
			return
	
	if not enemy_scene:
		print("Enemy scene non disponibile")
		return
	
	var spawn_position = _get_random_spawn_position()
	if spawn_position == Vector2.ZERO:
		print("Posizione spawn non valida")
		return
	
	var enemy = enemy_scene.instantiate()
	if not enemy:
		print("Errore nell'istanziare il nemico")
		return
		
	enemy.global_position = spawn_position
	
	# Connetti il segnale di morte del nemico
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
	
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.call_deferred("add_child", enemy)
		enemies_spawned_this_wave += 1
		print("Nemico ", enemies_spawned_this_wave, "/", enemies_in_current_wave, " spawnato nell'ondata ", current_wave)
	else:
		print("ERRORE: Scena corrente non trovata per spawn")
		enemy.queue_free()

func _on_enemy_died():
	enemies_killed_this_wave += 1
	print("Nemico ucciso: ", enemies_killed_this_wave, "/", enemies_in_current_wave, " (Ondata ", current_wave, ")")
	
	# CONTROLLO CORRETTO: L'ondata è completata solo quando:
	# 1. Tutti i nemici sono stati spawnati
	# 2. NON ci sono più nemici vivi nella scena
	if enemies_spawned_this_wave >= enemies_in_current_wave:
		# Controlla se ci sono ancora nemici vivi
		var alive_enemies = get_tree().get_nodes_in_group("enemies")
		print("Nemici ancora vivi: ", alive_enemies.size())
		
		if alive_enemies.size() == 0:
			_complete_wave()

func _complete_wave():
	print("Ondata ", current_wave, " completata! (Tutti i nemici eliminati)")
	wave_active = false
	spawn_timer.stop()
	
	# Bonus punteggio per completamento ondata
	add_score(wave_completion_bonus)
	
	wave_completed.emit(current_wave)
	
	# Avvia IMMEDIATAMENTE la prossima ondata (senza timer di attesa)
	call_deferred("_start_next_wave")

func _prepare_next_wave():
	print("Preparando ondata ", current_wave + 1)
	
	# Avvia il timer per la prossima ondata
	wave_timer.wait_time = wave_preparation_time
	wave_timer.start()
	
	# Emetti segnale per UI
	preparing_next_wave.emit(wave_preparation_time)

func _start_next_wave():
	current_wave += 1
	print("Iniziando immediatamente ondata ", current_wave)
	_start_wave(current_wave)

func _get_random_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var player_pos = player.global_position
	var attempts = 30  # Più tentativi per posizioni migliori
	
	for i in attempts:
		var angle = randf() * 2 * PI
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		
		if _is_valid_spawn_position(spawn_pos):
			return spawn_pos
	
	# Fallback: spawn garantito molto lontano
	print("Usando posizione spawn di fallback")
	return player_pos + Vector2(min_spawn_distance, 0).rotated(randf() * 2 * PI)

func _is_valid_spawn_position(pos: Vector2) -> bool:
	if not player:
		return false
	
	var distance_to_player = pos.distance_to(player.global_position)
	return distance_to_player >= min_spawn_distance and distance_to_player <= max_spawn_distance

func add_score(points: int):
	if not game_active:
		return
	current_score += points
	score_changed.emit(current_score)

func get_current_score() -> int:
	return current_score

func get_current_wave() -> int:
	return current_wave

func get_wave_progress() -> Dictionary:
	return {
		"current_wave": current_wave,
		"enemies_killed": enemies_killed_this_wave,
		"enemies_total": enemies_in_current_wave,
		"enemies_spawned": enemies_spawned_this_wave,
		"wave_active": wave_active
	}

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: " + str(new_score)

func _on_wave_started(wave_number: int):
	if wave_label:
		wave_label.text = "Wave: " + str(wave_number)

func _on_wave_completed(wave_number: int):
	print("UI: Ondata ", wave_number, " completata!")

func on_player_died():
	print("Player morto - fermando il gioco")
	stop_game()
	player_died.emit()
	print("Segnale player_died emesso")

func reset_game():
	print("Resettando il gioco")
	stop_game()
	
	current_score = 0
	current_wave = 1
	enemies_killed_this_wave = 0
	enemies_spawned_this_wave = 0
	wave_active = false
	
	score_changed.emit(current_score)
	
	# Rimuovi tutti i nemici esistenti
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Rimuovi tutti i proiettili
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	# Rimuovi tutti i power-up
	var powerups = get_tree().get_nodes_in_group("powerups")
	for powerup in powerups:
		if is_instance_valid(powerup):
			powerup.queue_free()

func set_score_label(label: Label):
	score_label = label
	if score_label:
		score_label.text = "Score: " + str(current_score)

func set_wave_label(label: Label):
	wave_label = label
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)
