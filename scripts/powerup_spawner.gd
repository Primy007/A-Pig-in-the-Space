extends Node2D

class_name PowerUpSpawner

# Array delle scene di power-up disponibili
@export var powerup_scenes: Array[PackedScene] = []
# Tempo base tra spawn automatici
@export var base_spawn_time: float = 15.0  # Più lungo per non sovraffollare
# Variazione casuale del tempo di spawn
@export var spawn_time_variance: float = 5.0
# Distanza dal player per lo spawn
@export var spawn_distance: float = 800.0
# Numero massimo di power-up contemporanei (solo per spawn automatico)
@export var max_auto_powerups: int = 2
# Abilita/disabilita spawn automatico
@export var enable_auto_spawn: bool = false

# Timer per lo spawn automatico
@onready var spawn_timer: Timer = Timer.new()
# Array per tracciare solo i power-up spawned automaticamente
var auto_spawned_powerups: Array = []
# Riferimento al player
var player: CharacterBody2D

func _ready():
	# Trova il player
	player = get_tree().get_first_node_in_group("player")
	
	# Inizializza spawn automatico solo se abilitato
	if enable_auto_spawn:
		add_child(spawn_timer)
		spawn_timer.wait_time = _get_random_spawn_time()
		spawn_timer.timeout.connect(_spawn_random_powerup)
		spawn_timer.start()

func _get_random_spawn_time() -> float:
	return base_spawn_time + randf_range(-spawn_time_variance, spawn_time_variance)

func _spawn_random_powerup():
	# Solo per spawn automatico, non interferisce con i drop dei nemici
	if auto_spawned_powerups.size() >= max_auto_powerups:
		_reset_timer()
		return
	
	if powerup_scenes.is_empty():
		_reset_timer()
		return
		
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if !is_instance_valid(player):
			_reset_timer()
			return
	
	# Spawn automatico
	var random_scene = powerup_scenes.pick_random()
	var powerup = random_scene.instantiate()
	var spawn_position = _get_random_spawn_position()
	powerup.global_position = spawn_position
	
	get_tree().current_scene.add_child(powerup)
	auto_spawned_powerups.append(powerup)
	
	# Traccia solo quelli spawned automaticamente
	powerup.tree_exited.connect(func(): _on_auto_powerup_destroyed(powerup))
	
	_reset_timer()

func _get_random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance * 0.5, spawn_distance)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player.global_position + offset

func _on_auto_powerup_destroyed(powerup):
	if auto_spawned_powerups.has(powerup):
		auto_spawned_powerups.erase(powerup)

func _reset_timer():
	if enable_auto_spawn:
		spawn_timer.wait_time = _get_random_spawn_time()
		spawn_timer.start()

# Funzione per abilitare/disabilitare spawn automatico durante il gioco
func toggle_auto_spawn(enabled: bool):
	enable_auto_spawn = enabled
	if enabled and spawn_timer.is_stopped():
		_reset_timer()
	elif !enabled:
		spawn_timer.stop()

# Pulisce solo i power-up spawned automaticamente
func clear_auto_powerups():
	for powerup in auto_spawned_powerups:
		if is_instance_valid(powerup):
			powerup.queue_free()
	auto_spawned_powerups.clear()
